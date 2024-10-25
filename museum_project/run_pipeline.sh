run_pipeline() {
    echo "Running Kafka pipeline..."
    python3 kafka_pipeline.py
    if [ $? -ne 0 ]; then
        echo "Error: Failed to run the Kafka pipeline."
        exit 1
    fi
}

run_pipeline