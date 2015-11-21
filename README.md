# build-machine

Ansible playbooks to make a VM with all my things in it.

Usage:

``` bash
ansible-galaxy install -r roles.txt
ansible-playbook -i '[machine],' provision.yml
ansible-playbook -i '[machine],' user.yml
```
The weird `-i '[machine],'` notation makes sure that `ansible-playbook` knows you're specifying a list (of length one, in this case) on the command line rather than an inventory file.

