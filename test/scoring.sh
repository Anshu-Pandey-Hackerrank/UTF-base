#!/bin/bash

source test/config/config.sh

expected_json=$(cat "$expected_json_path")
received_json=$(cat "$received_json_path")

# Function to recursively compare nested objects
function compare_objects {
  local obj1="$1"
  local obj2="$2"
  local keys=$(jq -c 'keys_unsorted | .[]' <<< "$obj1")

  for key in $keys; do
    local val1=$(jq -c ".$key" <<< "$obj1")
    local val2=$(jq -c ".$key" <<< "$obj2")
    local flag=0

    if [ "$val1" != "$val2" ]; then
      ((failed++))
      flag=1
      failed_details+=("$test_suite_name: $expected_name - Failed"$'\n'"Mismatch in key: $key"$'\n'"Expected: $val1"$'\n'"Received: $val2"$'')
      return 1
    fi
  done
  return $flag
}

passed=0
failed=0

total_test_suites=$(echo "$expected_json" | jq '. | length')

for ((suite = 0; suite < total_test_suites; suite++)); do
  test_suite_name=$(echo "$expected_json" | jq -r ".[$suite].testsuite_name")
  total_test_cases=$(echo "$expected_json" | jq ".[$suite].tests | length")

  for ((i = 0; i < total_test_cases; i++)); do
    expected_name=$(echo "$expected_json" | jq -r ".[$suite].tests[$i].name")
    expected_data=$(echo "$expected_json" | jq -c ".[$suite].tests[$i].expected_response")

    received_testcase=$(echo "$received_json" | jq ".[$suite].tests[$i] | select(.name == \"$expected_name\")")

    if [ -n "$received_testcase" ]; then
      received_data=$(echo "$received_testcase" | jq -c ".received_response")

      compare_objects "$expected_data" "$received_data"
      flag=$?

      if [ $flag -eq 0 ]; then 
        ((passed++))
        passed_details+=("$test_suite_name: $expected_name - Passed")
      fi
    else
      # Handle the case where the test case is not found in received_output.json
      ((failed++))
      failed_details+=("$test_suite_name: $expected_name - Failed"$'\n'"Expected: $expected_data"$'\n'"Received: null"$'\n')
    fi
  done
done

total=$((passed + failed))
if [ $total -eq 0 ]; then
  score=0
else
  score=$(jq -n "$passed / $total * 100" | xargs printf "%.2f")
fi

echo ""

echo "Passed Test Cases:"
for ((i = 0; i < passed; i++)); do
  echo "* ${passed_details[$i]}"
done

echo ""

echo "Failed Test Cases:"
for ((i = 0; i < failed; i++)); do
  echo "* ${failed_details[$i]}"
done

echo ""

echo "FS_SCORE: $score%"