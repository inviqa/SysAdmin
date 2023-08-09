#!/bin/bash

# Source the DigitalOcean API key from an environment variable
# shellcheck disable=SC2154
API_KEY="${DIGITAL_OCEAN_API_KEY}"
if [[ -z "${API_KEY}" ]]; then
  echo "API Key is not provided. Please set the DIGITAL_OCEAN_API_KEY environment variable."
  exit 1
fi

# Function to get DigitalOcean resources
get_do_resources() {
  local resource_type="${1}"
  local data
  data=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${API_KEY}" "https://api.digitalocean.com/v2/${resource_type}" 2>/dev/null) || { echo "Error retrieving ${resource_type}"; return 1; }
  echo "${data}" # Return the data
}

# Function to process resource
process_resource() {
  local region="${1}"
  local resource_type="${2}"
  local id="${3}"
  local name="${4}"
  local created_at="${5}"

  # Ensure dates are correctly formatted for the date command
  if [[ -n "${DEBUG}" ]]; then
    echo "Processing resource ID: ${id}" >&2
  fi

  if [[ -z "${id}" ]]; then
    if [[ -n "${DEBUG}" ]]; then
      echo "No ID found for resource. Skipping..." >&2
    fi
    return
  fi

  if [[ -z "${created_at}" ]]; then
    if [[ -n "${DEBUG}" ]]; then
      echo "Error processing date for resource ID ${id}" >&2
    fi
    return
  fi
  
  one_year_in_seconds=$((365 * 24 * 60 * 60))
  today_unix=$(date -u "+%s")
  created_at_unix=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${created_at//\"}" "+%s" 2>/dev/null || date -ju -f "%Y-%m-%d %H:%M:%S" "${created_at//\"}" "+%s"  2>/dev/null )
  age_in_years=$(( (today_unix - created_at_unix) / one_year_in_seconds ))
  
  if (( age_in_years < (1) )); then
    color='\033[0;32m' # Green
  elif (( age_in_years < (2) )); then
    color='\033[0;34m' # Blue
  elif (( age_in_years < (3) )); then
    color='\033[0;33m' # Yellow
  else
    color='\033[0;31m' # Red
  fi

  echo -e "${region},${color}${created_at},${age_in_years}\033[0m,${resource_type},${id},${name}" # End color formatting
}


# Function to iterate over resource types
iterate_resource_types() {
  local resource_types=("droplets" "volumes" "images" "snapshots" "domains")
  
  echo -e '"region","created_at","age_in_years","resource_type","id","name"' # print CVS header

  for resource_type in "${resource_types[@]}"; do
    if [[ -n "${DEBUG}" ]]; then
      echo "Processing ${resource_type} ...." >&2
    fi
    local region=''

    if ! data=$(get_do_resources "${resource_type}"); then
      if [[ -n "${DEBUG}" ]]; then
        echo "Error retrieving ${resource_type}. Skipping..." >&2
      fi
      continue
    fi
    case ${resource_type} in
      "droplets" | "volumes")
          resources=$(echo "${data}" | jq -r --arg resource_type "${resource_type}" '.[$resource_type][] | [.id, .name, .created_at, .region.slug] | @csv' | sort -t',' -k3,3 || true)
          ;;
      "images" | "snapshots" | "domains")
          resources=$(echo "${data}" | jq -r --arg resource_type "${resource_type}" '.[$resource_type][] | [.id, .name, .created_at, .regions[0]] | @csv' | sort -t',' -k3,3 || true)
          ;;
      *)
        if [[ -n "${DEBUG}" ]]; then
          echo "Invalid resource type: ${resource_type}. Skipping..." >&2
          continue
        fi
          ;;
    esac
    if [[ -z "${resources}" ]]; then
      if [[ -n "${DEBUG}" ]]; then
        echo "No resources found for ${resource_type}. Skipping..." >&2
      fi
      continue
    fi
    while IFS=, read -r id name created_at region; do
      process_resource "${region}" "\"${resource_type}\"" "${id}" "${name}" "${created_at}"
    done <<< "${resources}"
  done
}

# Display help message
display_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -h, --help              Display this help message"
  echo "  -v, --verbose           Enable debug mode (verbose output)"
  echo
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      display_help
      exit 0
      ;;
    -v|--verbose)
      DEBUG=true
      shift
      ;;
    *)
      echo "Error: Invalid option: $1"
      display_help
      exit 1
      ;;
  esac
done
# Call the main function
iterate_resource_types
