#!/bin/bash

source test/config/config.sh
source test/config/header_conversion/convert_header.sh

json_data=$(cat "$expected_json_path")

response_directory="test/config"

counter=0
all_responses=()

while [ $counter -lt $(echo "$json_data" | jq length) ]; do
  testsuite=$(echo "$json_data" | jq -c ".[$counter]")
  testsuite_name=$(echo "$testsuite" | jq -r '.testsuite_name')

  test_counter=0
  testsuite_responses=()

  while [ $test_counter -lt $(echo "$testsuite" | jq -c '.tests | length') ]; do
    test=$(echo "$testsuite" | jq -c ".tests[$test_counter]")
    type=$(echo "$test" | jq -r '.type')
    endpoint=$(echo "$test" | jq -r '.endpoint')
    header_key=$(echo "$test" | jq -r '.headers | keys_unsorted[0]')
    header_value=$(echo "$test" | jq -r ".headers[\"$header_key\"]")
    req_data=$(echo "$test" | jq -r '.req_data')
    test_name=$(echo "$test" | jq -r '.name')

    converted_header_key=$(camelcase_to_header "$header_key")

    curl_command="curl -sS -w '\n%{http_code}' -X $type 'http://localhost:$PORT$endpoint' -H '$converted_header_key: $header_value'"


    if [ "$header_value" == "application/json" ]; then
      req_data_json=$(echo "$req_data" | jq -c .) 
      # req_data_json=$(echo "$req_data" | jq -r to_entries | jq -r 'map("\(.key)=\(.value|tostring)") | join("&")')
      curl_command="$curl_command --data-raw '$req_data_json'"
    else
      req_data_urlencoded=$(echo "$req_data" | jq -r to_entries | jq -r 'map("\(.key)=\(.value|tostring)") | join("&")')
      # req_data_urlencoded=$(echo "$req_data" | jq -r to_entries | awk -F '"' '{printf "%s=%s&", $4, $8}' | sed 's/&$//')
      curl_command="$curl_command --data-raw '$req_data_urlencoded'"
    fi


    response=$(eval "$curl_command" 2>&1)
    response_body=$(echo "$response" | sed '$d')
    http_status_code=$(echo "$response" | tail -n 1)

if [ $? -eq 0 ]; then
  echo "Curl request for $test_name in testsuite $testsuite_name successful."

  # Check if the response contains <title>Error</title>
  if [[ $response == *"<title>Error</title>"* ]]; then
    # echo "Error: HTML error page detected for $test_name in testsuite $testsuite_name."
    test_response="{\"name\":\"$test_name\", \"received_response\":{\"status\":$http_status_code, \"data\":{\"message\":\"failed response\"}}}"
  elif [[ $response == *"<!doctype html>"* || $response == *"<!DOCTYPE html>"* ]]; then 
    # echo "Error: HTML error page detected for $test_name in testsuite $testsuite_name."
    test_response="{\"name\":\"$test_name\", \"received_response\":{\"status\":$http_status_code, \"data\":{\"message\":\"failed response\"}}}"
  else
     expected_data_empty=$(echo "$test" | jq -r '.expected_response.data == {}')
      if [ "$expected_data_empty" == "true" ]; then
        # If "data" is empty in the expected response, include an empty "data" object in the actual response
        test_response="{\"name\":\"$test_name\", \"received_response\":{\"status\":$http_status_code, \"data\":{}}}"
      else
         # If <title>Error</title> is not found, include the actual response
       test_response="{\"name\":\"$test_name\", \"received_response\":{\"status\":$http_status_code, \"data\": $response_body }}"
  fi
 fi
else
  echo "Error: Curl request for $test_name in testsuite $testsuite_name failed."
  test_response="{\"name\":\"$test_name\", \"received_response\":{\"status\":$http_status_code, \"data\":{\"message\":\"Curl request failed\"}}}"
fi

    testsuite_responses+=("$test_response")
    ((test_counter++))
  done

  all_responses+=("{\"testsuite_name\":\"$testsuite_name\", \"tests\":[$(IFS=,; echo "${testsuite_responses[*]}")] }")
  ((counter++))
done

response_file="$response_directory/received_response.json"
echo "${all_responses[@]}" | jq -s '.' > "$response_file"

echo "Responses saved to $response_file"
