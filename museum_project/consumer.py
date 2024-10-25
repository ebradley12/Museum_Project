# pylint: disable=broad-exception-caught
# pylint: disable=redefined-outer-name
# pylint: disable=invalid-name

"""Import libraries"""
import logging
from confluent_kafka import Consumer
from dotenv import dotenv_values

TOPIC = 'lmnh'
MESSAGE_LIMIT = 100000

logging.basicConfig(
    format='%(asctime)s - %(levelname)s:%(message)s', level=logging.DEBUG)


def configure_consumer():
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
    return Consumer(kafka_config)


def get_messages(consumer, MESSAGE_LIMIT):
    """Log messages."""
    consumer.subscribe([TOPIC])
    count = 0

    while count < MESSAGE_LIMIT:
        message = consumer.poll(timeout=1.0)

        if message is None:
            logging.debug("No message received.")
        elif message.error():
            logging.error("ERROR: %s", message.error())
        else:
            logging.info("Message received: %s",
                         message.value().decode('utf-8'))
            count += 1

    logging.info("Message limit (%s) reached.", MESSAGE_LIMIT)


if __name__ == "__main__":
    logging.info("Starting Kafka consumer script.")
    consumer = configure_consumer()

    try:
        get_messages(consumer, MESSAGE_LIMIT)
    except Exception as e:
        logging.error("Error while consuming messages: %s", e)
    finally:
        consumer.close()
        logging.info("Kafka consumer closed.")
