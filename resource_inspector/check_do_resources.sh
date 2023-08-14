#!/bin/bash

# Source the DigitalOcean API key from an environment variable
# shellcheck disable=SC2154
API_KEY="${DIGITAL_OCEAN_API_KEY}"
INVOICE_CSV=""
if [[ -z "${API_KEY}" ]]; then
  echo "API Key is not provided. Please set the DIGITAL_OCEAN_API_KEY environment variable."
  exit 1
fi

# Function to get DigitalOcean resources
get_do_resources() {
  local resource_type="${1}"
  local api_token="${API_KEY}"
  local data
  data=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${api_token}" "https://api.digitalocean.com/v2/${resource_type}" 2>/dev/null) || { echo "Error retrieving ${resource_type}"; return 1; }
  echo "${data}" # Return the data
}

get_latest_invoice_csv() {
  # Declare variables
  local invoice_id
  local csv_content

  # Assign invoice ID
  invoice_id=$(curl -s -X GET \
    -H "Content-Type: text/csv" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_API_KEY}" \
    "https://api.digitalocean.com/v2/customers/my/invoices" | grep -E -o '"invoice_uuid":[^,]+' | awk -F: '{print $2}' | sort -rn | head -n1 || true)

  # Debug echo
  if [[ -n ${DEBUG} ]]; then
    echo "Invoice ID: ${invoice_id}" >&2
  fi

  # Check if invoice ID is empty
  if [[ -z ${invoice_id} ]]; then
    echo "ERROR: Failed to retrieve invoice ID. Please check your API key and try again." >&2
    return 1
  fi

  # API call to retrieve CSV output
  csv_content=$(curl -s -X GET \
    -H "Content-Type: text/csv" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_API_KEY}" \
    "https://api.digitalocean.com/v2/customers/my/invoices/${invoice_id//\"}/csv")

  # Debug echo
  if [[ -n ${DEBUG} ]]; then
    echo "CSV Content:" >&2
    echo "${csv_content}" | head -n 3 >&2
  fi

  # Output the CSV content variable
  echo "${csv_content}"
}

find_resource_usd_cost() {
  # Declare variables
  local csv_content="${1}"
  local resource_name="${2}"
  local matching_line
  local usd_value

  # Find line with matching resource name in description field
  matching_line=$(echo "${csv_content}" | awk -F, -v resource="${resource_name}" 'tolower($3) ~ tolower(resource) {print}')

  # Debug echo
  if [[ -n ${DEBUG} ]]; then
    echo "Matching Line:" >&2
    echo "${matching_line}" >&2
  fi

  # Check if line is empty
  if [[ -n ${DEBUG} && -z ${matching_line} ]]; then
    echo "ERROR: Resource not found in the invoice CSV." >&2
    return 1
  fi

  # Extract value from USD field
  usd_value=$(echo "${matching_line}" | awk -F, '{print $7}')

  # Debug echo
  if [[ -n ${DEBUG} ]]; then
    echo "USD Value: ${usd_value}" >&2
  fi

  # Print the USD cost
  echo "${usd_value}"
}
# Function to process resource
process_resource() {
  local region="${1}"
  local resource_type="${2}"
  local id="${3}"
  local name="${4}"
  local created_at="${5}"
  local monthly_cost

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
  monthly_cost=$(find_resource_usd_cost "${INVOICE_CSV}" "${name//\"}")
  echo -e "${region},${color}${created_at},${age_in_years}\033[0m,${resource_type},${id},${name},${monthly_cost}" # End color formatting
}

# Function to iterate over resource types
iterate_resource_types() {
  local resource_types=("droplets" "volumes" "images" "snapshots" "domains")
  local specified_resource="${1:-}"  # New parameter to specify resource



  echo -e '"region","created_at","age_in_years","resource_type","id","name","monthly_cost"' # print CSV header

  for resource_type in "${resource_types[@]}"; do
    # Skip resource types that don't match the specified resource (if provided)
    if [[ -n "${specified_resource}" && "${resource_type}" != "${specified_resource}" ]]; then
      continue
    elif [[ -n "${DEBUG}" ]]; then
      echo "Specified resource ${specified_resource}" >&2
    fi
    if [[ -n "${DEBUG}" ]]; then
      echo "Processing resource ${resource_type} ...." >&2
    fi
    local region=''

    if ! data=$(get_do_resources "${resource_type}"); then
      if [[ -n "${DEBUG}" ]]; then
        echo "Error retrieving ${resource_type}. Skipping..." >&2
      fi
      continue
    fi
    case ${resource_type} in
      "droplets" | "volumes" | "kubernetes/clusters")
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
  echo "  -h, --help                           Display this help message"
  echo "  -r, --resource-type <type>           Check only a resource type (droplets|volumes|images|snapshots|domains|kubernetes_clusters)"
  echo "  -v, --verbose                        Enable debug mode (verbose output)"
  echo
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      display_help
      exit 0
      ;;
    -r|--resource-type)
      SPECIFIED_RESOURCE="${2}"
      shift 2
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
INVOICE_CSV=$(get_latest_invoice_csv)
iterate_resource_types "${SPECIFIED_RESOURCE}"
