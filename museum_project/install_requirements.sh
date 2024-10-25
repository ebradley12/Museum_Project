install_requirements() {
    if [ -f requirements.txt ]; then
    echo "Installing dependencies from requirements.txt..."
    pip3 install -r requirements.txt
else
    echo "Requirements.txt doesn't exist."
    exit 1
fi
}

install_requirements