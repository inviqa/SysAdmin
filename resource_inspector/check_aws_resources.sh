#!/bin/bash

# Function to get AWS resources
get_aws_resources() {
  local resource_type="${1}"
  local region="${2}"
  local data
  if [[ -n "${DEBUG}" ]]; then
      echo "Processing ${resource_type} ...." >&2
  fi 
  case ${resource_type} in
      "instances")
          #shellcheck disable=SC2016
          query='Reservations[].Instances[].{id: InstanceId, name: Tags[?Key==`Name`].Value | [0], created_at: LaunchTime}'
          ;;
      "volumes")
          #shellcheck disable=SC2016
          query='Volumes[].{id: VolumeId, name: Tags[?Key==`Name`].Value | [0], created_at: CreateTime}'
          ;;
      "images")
          query="Images[].{id: ImageId, name: Name, created_at: CreationDate}"
          ;;
      "snapshots")
          query="Snapshots[].{id: SnapshotId, name: Description, created_at: StartTime}"
          ;;
      *)
        if [[ -n "${DEBUG}" ]]; then
          echo "Invalid resource type: ${resource_type}. Skipping..." >&2
          return
        fi
          ;;
  esac 
  data=$(aws ec2 "describe-${resource_type}" --region "${region}" --query "${query}" --filters "Name=owner-id,Values=${AWS_CALLER_IDENTITY}" --output json 2>/dev/null);
  echo "${data}" # Return the data
}

# Function to process resource
process_resource() {
  local region="${1}"
  local resource_type="${2}"
  local id="${3}"
  local name="${4}"
  local created_at="${5}"

  if [[ -z "${id}" ]]; then
    if [[ -n "${DEBUG}" ]]; then
      echo "No ID found for resource ${resource_type}. Skipping..."
    fi
    return
  else
    if [[ -n "${DEBUG}" ]]; then
      echo "Processing resource ID: ${id}" >&2
    fi
  fi

  if [[ -z "${created_at}" ]]; then
    if [[ -n "${DEBUG}" ]]; then
      echo "Error processing date for resource ID ${id}" >&2
      return
    fi
  fi

  one_year_in_seconds=$((365 * 24 * 60 * 60))
  today_unix=$(date -u "+%s")

  if [[ ${#created_at} -ge 7 && ${created_at} =~ .*(\+[0-9]{2}:[0-9]{2}|-{1}[0-9]{2}:[0-9]{2})$ ]]; then
      # remove timezone from date string for macOS compatibility
      created_at="${created_at:0:$((${#created_at}-7))}"
      created_at="${created_at}Z"
  fi

  created_at_unix=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${created_at//\"}" "+%s" 2>/dev/null || date -ju -f "%Y-%m-%d %H:%M:%S" "${created_at}" "+%s"  2>/dev/null )
  age_in_years=$(( (today_unix - created_at_unix) / one_year_in_seconds ))

  if (( age_in_years < 1 )); then
    color='\033[0;32m' # Green
  elif (( age_in_years < 2 )); then
    color='\033[0;34m' # Blue
  elif (( age_in_years < 3 )); then
    color='\033[0;33m' # Yellow
  else
    color='\033[0;31m' # Red
  fi

  echo -e "${region},${color}${created_at},${age_in_years}\033[0m,${resource_type},${id},${name}" # End color formatting}
}
# Function to iterate over resource types and regions
iterate_resource_types() {
  local resource_types=("instances" "volumes" "images" "snapshots")
  local regions=()
  if [[ -n "${REGION}" ]]; then
    regions+=("${REGION}")
  else
    #shellcheck disable=2207
    regions=($(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)) || { echo "Error retrieving regions. Exiting..."; exit 1;}
  fi

  echo -e '"region","created_at","age_in_years","resource_type","id","name"' # print CVS header
  
  for region in "${regions[@]}"; do
    if [[ -n "${DEBUG}" ]]; then
        echo "Processing ${region} ...." >&2
    fi 
    for resource_type in "${resource_types[@]}"; do
      if ! data=$(get_aws_resources "${resource_type}" "${region}"); then
        if [[ -n "${DEBUG}" ]]; then
          echo "Error retrieving ${resource_type} in region ${region}. Skipping..." >&2
        fi
        continue
      fi
      resources=$(echo "${data}" | jq -r '.[]| [.id, .name, .created_at] | @csv' | sort -t',' -k3,3 || true)

      if [[ ${#resources[@]} -eq 0 ]]; then
          echo "No resources found for ${resource_type} in region ${region}. Skipping..."
          continue
      fi
      
    while IFS=, read -r id name created_at; do
      process_resource "\"${region}\"" "\"${resource_type}\"" "${id}" "${name}" "${created_at}"
    done <<< "${resources}"
  done
done

}


# Display help message
display_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -h, --help              Display this help message"
  echo "  -v, --verbose           Enable debug mode (verbose output)"
  echo "  -p, --profile PROFILE   Specify the AWS profile to use (default profile is used if not specified)"
  echo "  -r, --region REGION     Specify the region to search (search in all regions by default)"
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
    -p|--profile)
      shift
      if [[ -n $1 ]]; then
        AWS_PROFILE=$1
      else
        echo "Error: Profile name not specified"
        exit 1
      fi
      shift
      ;;
    -r|--region)
      shift
      if [[ -n $1 ]]; then
        REGION=$1
      else
        echo "Error: Region not specified"
        exit 1
      fi
      shift
      ;;
    *)
      echo "Error: Invalid option: $1"
      display_help
      exit 1
      ;;
  esac
done

# Check if the AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
  echo "AWS CLI is not installed. Please install AWS CLI and configure it."
  exit 1
fi

# Check AWS CLI connectivity
if ! aws sts get-caller-identity &> /dev/null; then
  echo "AWS CLI failed to connect to AWS services. Please check your credentials and connectivity."
  exit 1
fi

# Call the main function
export AWS_PROFILE=${AWS_PROFILE:-default}
export AWS_CALLER_IDENTITY
AWS_CALLER_IDENTITY="$(aws sts get-caller-identity --query Account --output text)"
if [[ -n "${DEBUG}" ]]; then
  echo "AWS Caller ID: ${AWS_CALLER_IDENTITY}" >&2
fi
iterate_resource_types