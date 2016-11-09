# Usage
Create an inventory file, i.e.:
```
[project_name]
production.client.com
uat.client.com
qa.client.com
1.2.3.4
1.2.3.5
1.2.3.6
```

Then run the command specifying the list of users you want to remove (exepet your own user!!!)
```
ansible-playbook --ask-become-pass -i inventory remove_jc_from_server.yml -e '{"users_list": [user1, user2, user3]}'
```
the script will as you to provide your JC user password to ba allowed to run sudo commands.

Alternatively you can run the command without specifying the list of users. This will prevent the deletion of any user.
```
ansible-playbook --ask-become-pass -i inventory remove_jc_from_server.yml
```

If you are in posses of the `root` password you can create an inventory file as follow and omit the `--ask-become-pass` password
```
[project_name]
production.client.com   ansible_user=root   ansible_ssh_pass=password_for_this_server
uat.client.com          ansible_user=root   ansible_ssh_pass=password_for_this_server
qa.client.com           ansible_user=root   ansible_ssh_pass=password_for_this_server
....
....
```
then run the command where you can specify in the userlist also your own JC user:
```
ansible-playbook -i inventory remove_jc_from_server.yml -e '{"users_list": [user1, user2, user3]}'
```
