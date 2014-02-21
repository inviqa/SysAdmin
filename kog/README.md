#SSH's Keymaster Of Gozer
Kog aims to be a simple decentralised system to distribute and revoke SSH2 RSA Public Keys from any accissible server.
Kog is based on capistrano

#TODO
- retrive keys from an LDAP database
- retrive keys from GitHub Organization
- retrieve keys from locally stored public files
- keep 'n' backups of the authorized_keys
- wipe all the previous authorized_keys
- detect when an authorized_keys file on the server differs from the previously deployed version (so that we may want to spot any tentative of intrusion, this could be special funcion to run automatically and maybe used with NAGIOS to send alerts if a new unknown keys is detected
