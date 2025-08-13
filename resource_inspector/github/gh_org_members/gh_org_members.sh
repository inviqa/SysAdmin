#!/bin/bash

# Check if organization name is provided
if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <organization>"
  exit 1
fi

org="$1"

# Get the list of members
members=$(gh api "orgs/${org}/members" --jq '.[].login')

# Check if there are any members
if [[ -z "${members}" ]]; then
  echo "No members found for organization: ${org}"
  exit 0
fi

# Loop through each member and get their details
echo "Fetching details for members of organization: ${org}"
for member in ${member}s; do
  echo "Details for ${member}:"
  email=$(gh api "users/${member}" --jq '.email // "Email not public"')
  echo "Email: ${email}"
done
