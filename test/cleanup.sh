#!/bin/bash

source test/config/config.sh
PROJECT_PATH="project/"

# brew install lsof #mac
sudo apt install lsof -y #HRW
command -v lsof &> /dev/null || { echo "lsof command not found. Please install it."; exit 1; }

if lsof -i :$PORT -t &> /dev/null; then
    pid=$(lsof -i :$PORT -t)
    
    if [ -n "$pid" ]; then
        kill $pid
        echo "Process with PID $pid on port $PORT has been terminated."
    else
        echo "Failed to extract the process ID for port $PORT."
    fi
else
    echo "No process found running on port $PORT."
fi


# JUNIT File Check
JUNIT_PATH="./"
echo "Deleting junit.xml file"
rm -f "$JUNIT_PATH/junit.xml"

# Install and run the Node.js application in the "project" directory
if [ -d "$PROJECT_PATH" ]; then
    echo "Installing and running Application in the project directory..."
    cd "$PROJECT_PATH" || exit 1
    chmod +x "../test/config/install.sh"  
    "../test/config/install.sh" 
    chmod +x "../test/config/run.sh"  
    "../test/config/run.sh" &
    sleep 10
else
    echo "project directory not found at path: $PROJECT_PATH"
fi

echo "Cleanup complete!"
