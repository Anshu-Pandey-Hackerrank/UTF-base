#!/bin/bash

sudo apt-get install -y jq #HRW
# brew install jq #mac

if command -v jq &> /dev/null; then
    echo "jq has been successfully installed."
else
    echo "Failed to install jq. Please install jq manually using sudo apt-get install -y jq"
fi

bash test/cleanup.sh
bash test/config/curl.sh
bash test/scoring.sh

