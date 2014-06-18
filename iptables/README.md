This file is used to setup restrictions on SSH via IPTables on hosts. It appends rules that only allow access via SSH from the Inviqa offices and front door.

Usage:

```
curl https://raw.githubusercontent.com/inviqa/SysAdmin/feature/iptables-ssh/iptables/ssh.sh | sudo bash
```
Wiill create the rules.

Once you are happy that these are working correctly, save the rules:
```
iptables-save > /etc/syscinfig/iptables
```
