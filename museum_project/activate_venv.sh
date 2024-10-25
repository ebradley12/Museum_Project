activate_venv () {
    python3 -m venv .venv
    if [ -f ./.venv/bin/activate ]; then
        echo "Activating new virtual environment..."
        source ./.venv/bin/activate
    else
        echo "Error: Failed to create virtual environment."
        exit 1
    fi
}

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
        echo "Creating and activating new venv..."
        activate_venv
    fi
}

activate
