# Requirements
Install Tugboat, the command-line interface to DigitalOcean https://github.com/pearkes/tugboat

# Inventory
Use `cerae_inventory.sh` makes use of tugboat to generate an inventory of IPs of all your DO droplets to be used with the Ansible playbook included in this project.

The Ansible playbook installs the `DO-Agent` in all the droplets of inventory given that you connect as root or that your use has sudo capabilities.

The playbook can be extended to run more operations on the droplets

# command to run, will ask for sudo_password
ansible-playbook playbook.yml -i inventory  --ssh-extra-args='-o StrictHostKeyChecking=no' -K
