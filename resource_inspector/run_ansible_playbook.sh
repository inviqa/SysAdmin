#!/bin/bash

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Ansible is not installed. Please install Ansible before running this script."
    exit 1
fi

# Run the Ansible playbook
ansible-playbook get_droplet_creation_date.yml
