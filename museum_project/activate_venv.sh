activate_venv () {
    python3 -m venv .venv
    source ./.venv/bin/activate
}

# creates a venv if not creates, otherwise enable it
activate () {
    if [[ $1 = "new" ]]; then
        echo "Deleting and reactivating virtual environment..."
        deactivate 2>/dev/null
        rm -rf .venv
        activate_venv
    elif [ -d ".venv" ]; then
        echo "Activating existing virtual environment..."
        source ./.venv/bin/activate
    else
        echo "Making venv and enabling"
        activate_venv
    fi
}

activate

