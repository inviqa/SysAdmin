
# Config File
```
~/.socksproxyrc
---
SERVICE_ENABLE='on';
SUDO_ENABLE=true;
VERBOSE=true;
SOCKSPROXY_REMOTE_SERVER='frontdoor';
SOCKSPROXY_LOCAL_SERVER='localhost';
SOCKSPROXY_PORT='8080';
NETWORK_SERVICE='Wi-Fi';
---

```
# Usage
```bash
./socksproxy --verbose --sudo [ --enable | --disable ] --remote server_name --local server_name --port port_number --network service
```
