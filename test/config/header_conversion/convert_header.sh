#!/bin/bash

source test/config/header_conversion/header_map.sh

camelcase_to_header() {
    local input="$1"
    if [ -n "${header_conversions[$input]}" ]; then
        echo "${header_conversions[$input]}"
    else
        # Convert camelCase to header format
        header=$(echo "$input" | sed -E 's/([A-Z])/-\1/g' | tr '[:upper:]' '[:lower:]')
        # Remove leading hyphen, if any
        header=${header#-}
        echo "$header"
    fi
}

camelCaseWord="contentType"
header=$(camelcase_to_header "$camelCaseWord")
