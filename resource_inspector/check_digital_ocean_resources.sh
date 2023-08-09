#!/bin/bash

# Source the DigitalOcean API key from an environment variable
# shellcheck disable=SC2154
API_KEY="${DIGITAL_OCEAN_API_KEY}"

# Function to get DigitalOcean resources
get_do_resources() {
  local resource_type="${1}"
  local data
  data=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${API_KEY}" "https://api.digitalocean.com/v2/${resource_type}" 2>/dev/null) || { echo "Error retrieving ${resource_type}"; return 1; }
  echo "${data}" # Return the data
}

# Function to process resource
process_resource() {
  local resource_type="${1//\"}"
  local id="${2//\"}"
  local name="${3//\"}"
  local created_at="${4//\"}"

  # Ensure dates are correctly formatted for the date command
  if [[ -n "${DEBUG}" ]]; then
    echo "Processing resource ID: ${id} created_at: ${created_at}" # Debug line
  fi

  if [[ -z "${id}" ]]; then
    echo "No ID found for resource. Skipping..."
    return
  fi

  if [[ -z "${created_at}" ]]; then
    echo "Error processing date for resource ID ${id}" >&2
    return
  fi
  
  one_year_in_seconds=$((365 * 24 * 60 * 60))
  today_unix=$(date -u "+%s")
  created_at_unix=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${created_at}" "+%s" 2>/dev/null || date -ju -f "%Y-%m-%d %H:%M:%S" "${created_at}" "+%s"  2>/dev/null )
  date_diff=$(( (today_unix - created_at_unix) / one_year_in_seconds ))
  
  if (( date_diff < (1) )); then
    color='\033[0;32m' # Green
  elif (( date_diff < (2) )); then
    color='\033[0;34m' # Blue
  elif (( date_diff < (3) )); then
    color='\033[0;33m' # Yellow
  else
    color='\033[0;31m' # Red
  fi

  echo -e "${color}${resource_type}: ${id} ${name} ${created_at}\033[0m" # End color formatting
}


# Function to iterate over resource types
iterate_resource_types() {
  local resource_types=("droplets" "volumes" "images" "snapshots" "domains")

  for resource_type in "${resource_types[@]}"; do
    if [[ -n "${DEBUG}" ]]; then
      echo "Processing ${resource_type} ...."
    fi
    if ! data=$(get_do_resources "${resource_type}"); then
      echo "Error retrieving ${resource_type}. Skipping..."
      continue
    fi
    resources=$(echo "${data}" | jq -r --arg resource_type "${resource_type}" '.[$resource_type][] | [.id, .name, .created_at] | @csv' | sort -t',' -k3,3 || true)
    if [[ -z "${resources}" ]]; then
      echo "No resources found for ${resource_type}. Skipping..."
      continue
    fi

    while IFS=, read -r id name created_at; do
      process_resource "${resource_type}" "${id}" "${name}" "${created_at}"
    done <<< "${resources}"
  done
}


# Check if the DEBUG flag is set
if [[ $* == *-v* ]]; then
  DEBUG=true
fi

# Call the main function
iterate_resource_types
