# prerequisites
configure ~/.ssh/config file with the following
```
Host frontdoor frontdoor2.inviqa.com
      HostName frontdoor2.inviqa.com
      ControlPath ~/.ssh/frontdoor.ctl
```

# Config File
```
#### ~/.socksproxyrc
SERVICE_ENABLE='on';
SUDO_ENABLE=true;
VERBOSE=true;
SOCKSPROXY_REMOTE_SERVER='frontdoor';
SOCKSPROXY_LOCAL_SERVER='localhost';
SOCKSPROXY_PORT='8080';
NETWORK_SERVICE='Wi-Fi';
####

```
# Usage

```bash
# uses the config files defaults
./socksproxy [ --enable | --disable ]

# this will override any config file parameters
./socksproxy --verbose --sudo [ --enable | --disable ] --remote server_name --local server_name --port port_number --network service
```
# TODO
- [ ] add a 'Usage' print if no parameter is passed on
- [ ] add installation instructions
- [ ] add menu icon enabler
