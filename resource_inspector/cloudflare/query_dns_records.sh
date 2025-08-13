#!/usr/bin/env bash

# Check if cfcli is installed
if ! command -v cfcli &> /dev/null; then
  echo "cfcli could not be found. Please install it using the following command:"
  echo "npm install -g cloudflare-cli"
  exit 1
fi

# Check if domain is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN=$1

# # Fetch the zone ID for the domain
# ZONE_ID=$(cfcli -f json -d  "${DOMAIN}" list | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name==$DOMAIN) | .name')

# if [[ -z "${ZONE_ID}" ]]; then
#   echo "Zone ID not found for domain: ${DOMAIN}"
#   exit 1
# fi

# Fetch DNS records for the zone
DNS_RECORDS=$(cfcli  -f json -d "${DOMAIN}" ls )

# Check if DNS records are found
if [[ -z "${DNS_RECORDS}" ]]; then
  echo "No DNS records found for domain: ${DOMAIN}"
  exit 1
fi

# Parse and display DNS records
echo "DNS record Type, DNS Record name, DNS Record value"
echo "${DNS_RECORDS}" | jq -r '.[] | "\(.type), \(.content), \(.name)"'