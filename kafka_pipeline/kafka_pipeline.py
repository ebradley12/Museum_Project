# pylint: disable=broad-exception-caught
# pylint: disable=too-many-locals
# pylint: disable=redefined-outer-name
"""Import libraries and modules."""
from datetime import datetime, time
import logging
import json
import argparse
import psycopg2
import psycopg2.extras
from confluent_kafka import Consumer
from dotenv import dotenv_values

VALID_VALS = [-1, 0, 1, 2, 3, 4]
VALID_TYPES = [0, 1]
VALID_SITES = ["0", "1", "2", "3", "4", "5"]
VALID_START_TIME = time(8, 45)
VALID_END_TIME = time(18, 15)


def configure_consumer(topic: str) -> Consumer:
    """Create and configure a Kafka consumer."""
    config = dotenv_values(".env.prod")
    kafka_config = {
        'bootstrap.servers': config["BOOTSTRAP_SERVERS"],
        'security.protocol': config["SECURITY_PROTOCOL"],
        'sasl.mechanisms': config["SASL_MECHANISM"],
        'sasl.username': config["USERNAME"],
        'sasl.password': config["PASSWORD"],
        'group.id': config["GROUP_ID"],
        'auto.offset.reset': 'earliest',
        'fetch.min.bytes': 1,
        'fetch.wait.max.ms': 100,
    }
    logging.info("Kafka consumer configured.")
    consumer = Consumer(kafka_config)
    consumer.subscribe([topic])
    return consumer


def configure_database():
    """Establishes and returns a connection to the PostgreSQL database."""
    config = dotenv_values(".env.prod")
    try:
        conn = psycopg2.connect(
            database=config['DB_NAME'],
            user=config['DB_USERNAME'],
            password=config['DB_PASSWORD'],
            host=config['DB_HOST'],
            port=config['DB_PORT']
        )
        logging.info("Database connection established.")
        return conn
    except Exception as e:
        logging.error("Error connecting to the database: %s", str(e))
        raise


def get_cursor(conn):
    """Returns a cursor for the provided connection."""
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)


def get_foreign_key(cursor, table: str, column: str, value: int, id_type: str) -> int:
    """Get the foreign key from the specified table and column based on the given value."""
    try:
        cursor.execute(f"""SELECT {id_type} FROM {
                       table} WHERE {column} = %s;""", (value,))
        result = cursor.fetchone()
        if result:
            return result[id_type]
        return None
    except psycopg2.DatabaseError as e:
        logging.error("Error fetching foreign key from %s: %s", table, str(e))
        cursor.connection.rollback()
        return None


def insert_interaction(cursor, table: str, exhibition_id: int, interaction_id: int, event_at: str):
    """Insert a request or rating interaction into the database."""

    column_name = 'request_id' if table == 'request_interaction' else 'rating_id'
    query = f"""INSERT INTO {table} (exhibition_id, {
        column_name}, event_at) VALUES (%s, %s, %s);"""
    try:
        cursor.execute(query, (exhibition_id, interaction_id, event_at))
        logging.debug("Inserted %s interaction: exhibition_id=%s, %s=%s",
                      column_name, exhibition_id, column_name, interaction_id)
    except Exception as e:
        logging.error("Error inserting interaction into %s: %s", table, e)


def log_invalid_message(log_file: str, message: str, reason: str):
    """Log invalid messages to a file or to the console."""
    if log_file:
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(f"Invalid message: {message} - Reason: {reason}\n")
    else:
        logging.warning("Invalid message: %s - Reason: %s", message, reason)


def validate_message(message: str) -> tuple[bool, str]:
    """Validate message structure and return a tuple of (is_valid, reason)."""
    data = json.loads(message)

    required_keys = ['val', 'at', 'site']
    for key in required_keys:
        if key not in data:
            return False, f"Missing '{key}' key"

    val = data.get("val")
    if val not in VALID_VALS:
        return False, "Invalid 'val' value"

    if val == -1:
        if 'type' not in data or data['type'] is None:
            return False, "Missing or null 'type' when 'val' is -1"
        if data['type'] not in VALID_TYPES:
            return False, "Invalid 'type' value when 'val' is -1 (must be 0 or 1)"

    at = data.get("at")
    try:
        timestamp = datetime.fromisoformat(at)
        if not VALID_START_TIME <= timestamp.time() <= VALID_END_TIME:
            return False, "Outside of valid kiosk interaction time (8:45 AM - 6:15 PM)"

    except ValueError as e:
        return False, f"Invalid timestamp format: {e}"

    site = data.get("site")
    if site not in VALID_SITES:
        return False, "Exhibition not part of the project"

    return True, "Valid"


def process_messages(consumer: Consumer, connection, cursor, message_limit=None, log_file=None):
    """Get messages, validate, and log invalid ones."""
    count = 0
    processed_count = 0
    invalid_count = 0

    logging.info("Starting to process messages.")
    try:
        while message_limit is None or processed_count < message_limit:
            message = consumer.poll(timeout=1.0)

            if message is None:
                logging.debug("No message received.")
                continue

            if message.error():
                logging.error("ERROR: %s", message.error())
                continue

            try:
                decoded_message = message.value().decode('utf-8')
            except Exception as e:
                logging.error("Message decoding error: %s", e)
                continue

            is_valid, reason = validate_message(decoded_message)

            if not is_valid:
                invalid_count += 1
                log_invalid_message(log_file, decoded_message, reason)
            else:
                logging.info("Valid message: %s", decoded_message)
                data = json.loads(decoded_message)
                event_at = data.get('at')
                exhibition_id = int(data.get('site'))

                if data.get('val') == -1:
                    request_id = get_foreign_key(
                        cursor, 'request', 'request_value', data.get('type'), 'request_id')
                    if request_id:
                        insert_interaction(
                            cursor, 'request_interaction', exhibition_id, request_id, event_at)
                else:
                    rating_id = get_foreign_key(
                        cursor, 'rating', 'rating_value', data.get('val'), 'rating_id')
                    if rating_id:
                        insert_interaction(
                            cursor, 'rating_interaction', exhibition_id, rating_id, event_at)

                count += 1
                processed_count += 1

            if processed_count % 10 == 0:
                connection.commit()
                logging.info("Committed 10 messages to the database.")

            if message_limit and processed_count >= message_limit:
                break

        connection.commit()
        logging.info(f"Final commit. Processed {processed_count} messages.")

    except Exception as e:
        logging.error("Error processing messages: %s", e)
        connection.rollback()
    finally:
        cursor.close()
        logging.info("Cursor closed.")


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Kafka ETL Pipeline")
    parser.add_argument(
        '--logfile', help="Log file for invalid messages (optional)")
    parser.add_argument('--limit', type=int, default=10000,
                        help="Limit of messages to process (optional)")
    parser.add_argument('--topic', type=str, default='lmnh',
                        help="Kafka topic to subscribe to (default 'lmnh')")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()

    logging.basicConfig(
        format='%(asctime)s - %(levelname)s:%(message)s', level=logging.DEBUG)

    logging.info("Starting Kafka ETL pipeline script.")

    try:
        consumer = configure_consumer(args.topic)
        db_connection = configure_database()
        cursor = get_cursor(db_connection)
        process_messages(consumer, db_connection, cursor, message_limit=args.limit,
                         log_file=args.logfile)
    except Exception as e:
        logging.error("Error during pipeline execution: %s", e)
    finally:
        consumer.close()
        db_connection.close()
        logging.info("Kafka consumer and database connection closed.")
