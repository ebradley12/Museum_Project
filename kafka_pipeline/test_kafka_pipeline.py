import unittest
from unittest.mock import patch, MagicMock
from datetime import datetime
import json
from kafka_pipeline import configure_database, validate_message, process_messages


@patch('kafka_pipeline.psycopg2.connect')
def test_configure_database_success(mock_connect):
    """Test that the database connection is established successfully."""
    mock_connect.return_value = MagicMock()
    conn = configure_database()
    assert conn is not None
    mock_connect.assert_called_once()


def test_validate_message_valid():
    """Test valid message validation."""
    message = json.dumps({
        'val': 3,
        'at': "2024-10-22T11:53:40.358939+01:00",
        'site': '1'
    })
    is_valid, reason = validate_message(message)
    assert is_valid
    assert reason == "Valid"


def test_validate_message_invalid_time():
    """Test valid message validation."""
    message = json.dumps({
        'val': 3,
        'at': "2024-10-22T19:53:40.358939+01:00",
        'site': '1'
    })
    is_valid, reason = validate_message(message)
    assert not is_valid
    assert reason == "Outside of valid kiosk interaction time (8:45 AM - 6:15 PM)"


def test_validate_message_invalid_val():
    """Test invalid message validation due to invalid 'val'."""
    message = json.dumps({
        'val': 20,
        'at': "2024-10-22T11:53:40.358939+01:00",
        'site': '1'
    })
    is_valid, reason = validate_message(message)
    assert not is_valid
    assert reason == "Invalid 'val' value"


def test_validate_message_missing_key():
    """Test invalid message due to missing 'site' key."""
    message = json.dumps({
        'val': 3,
        'at': datetime.now().isoformat(),
    })
    is_valid, reason = validate_message(message)
    assert not is_valid
    assert reason == "Missing 'site' key"


def test_validate_message_invalid_type():
    """Test invalid message validation due to invalid 'type'."""
    message = json.dumps({
        'val': -1,
        'type': 2,
        'at': "2024-10-22T11:53:40.358939+01:00",
        'site': '1'
    })
    is_valid, reason = validate_message(message)
    assert not is_valid
    assert reason == "Invalid 'type' value when 'val' is -1 (must be 0 or 1)"
