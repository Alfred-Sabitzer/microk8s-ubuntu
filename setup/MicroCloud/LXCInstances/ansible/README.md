# Ansible Master Image

Aim is to generate the ansible master image.
Here are all the necessary settings included.

````bash
pd="/home/alfred/VSCode/microk8s-ubuntu/setup/MicroCloud/InstanceGenerator"
python3 ${pd}/instancegenerator.py \
    --project=default \
    --profile=infrastructure \
    --image="alpine" \
    --template_dir=${pd}/template \
    --name=ansible
````

Set the Directory right for starting the correct python.

# Extraction of tar-file

````bash
tar -xf config.tar.xz 
````

This will extract all files and create the necessary directory structure.

````bash
ansible:~$ tree
.
├── README.md
├── config
│   ├── README.md
│   ├── alpine.yaml
│   ├── ansible.cfg
│   ├── filter_plugins
│   ├── inventories
│   │   ├── README.md
│   │   ├── infrastructure
│   │   │   ├── README.md
│   │   │   ├── group_vars
│   │   │   │   └── README.md
│   │   │   ├── host_vars
│   │   │   │   └── README.md
│   │   │   └── hosts
│   │   └── production
│   │       ├── README.md
│   │       ├── group_vars
│   │       │   └── README.md
│   │       ├── host_vars
│   │       │   └── README.md
│   │       └── hosts
│   ├── kubernetes.yaml
│   ├── library
│   │   └── README.md
│   ├── module_utils
│   │   └── README.md
│   ├── roles
│   │   └── README.md
│   ├── site.yaml
│   └── ubuntu.yaml
└── config.tar.xz

12 directories, 20 files
````

# Init-Files

Ansible itself shoud be organized well. Configuration should be set up according to https://docs.ansible.com/ansible/latest/reference_appendices/config.html 

# Directory Structure

As an idea for the structure see https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html

We will use the following schema

````bash
inventories/
   production/
      hosts               # inventory file for production servers
      group_vars/
         group1.yml       # here we assign variables to particular groups
         group2.yml
      host_vars/
         hostname1.yml    # here we assign variables to particular systems
         hostname2.yml

   staging/
      hosts               # inventory file for staging environment
      group_vars/
         group1.yml       # here we assign variables to particular groups
         group2.yml
      host_vars/
         stagehost1.yml   # here we assign variables to particular systems
         stagehost2.yml

library/
module_utils/
filter_plugins/

site.yml
webservers.yml
dbservers.yml

roles/
    common/
    webtier/
    monitoring/
    fooapp/
````
#

Ansible modules can be found on https://docs.ansible.com/ansible/latest/module_plugin_guide/index.html

Templates can be found on https://github.com/devopshobbies/ansible-templates/tree/master

A list of all Modules is on https://docs.ansible.com/ansible/2.9/modules/list_of_all_modules.html

A cheat-list for the command usage is on https://docs.ansible.com/ansible/latest/command_guide/cheatsheet.html 


````bash
ansible:~# ansible
usage: ansible [-h] [--version] [-v] [-b] [--become-method BECOME_METHOD] [--become-user BECOME_USER] [-K | --become-password-file BECOME_PASSWORD_FILE] [-i INVENTORY] [--list-hosts] [-l SUBSET] [--flush-cache]
               [-P POLL_INTERVAL] [-B SECONDS] [-o] [-t TREE] [--private-key PRIVATE_KEY_FILE] [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT] [--ssh-common-args SSH_COMMON_ARGS] [--sftp-extra-args SFTP_EXTRA_ARGS]
               [--scp-extra-args SCP_EXTRA_ARGS] [--ssh-extra-args SSH_EXTRA_ARGS] [-k | --connection-password-file CONNECTION_PASSWORD_FILE] [-C] [-D] [-e EXTRA_VARS] [--vault-id VAULT_IDS]
               [-J | --vault-password-file VAULT_PASSWORD_FILES] [-f FORKS] [-M MODULE_PATH] [--playbook-dir BASEDIR] [--task-timeout TASK_TIMEOUT] [-a MODULE_ARGS] [-m MODULE_NAME]
               pattern
ansible: error: the following arguments are required: pattern
 
usage: ansible [-h] [--version] [-v] [-b] [--become-method BECOME_METHOD] [--become-user BECOME_USER] [-K | --become-password-file BECOME_PASSWORD_FILE] [-i INVENTORY] [--list-hosts] [-l SUBSET] [--flush-cache]
               [-P POLL_INTERVAL] [-B SECONDS] [-o] [-t TREE] [--private-key PRIVATE_KEY_FILE] [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT] [--ssh-common-args SSH_COMMON_ARGS] [--sftp-extra-args SFTP_EXTRA_ARGS]
               [--scp-extra-args SCP_EXTRA_ARGS] [--ssh-extra-args SSH_EXTRA_ARGS] [-k | --connection-password-file CONNECTION_PASSWORD_FILE] [-C] [-D] [-e EXTRA_VARS] [--vault-id VAULT_IDS]
               [-J | --vault-password-file VAULT_PASSWORD_FILES] [-f FORKS] [-M MODULE_PATH] [--playbook-dir BASEDIR] [--task-timeout TASK_TIMEOUT] [-a MODULE_ARGS] [-m MODULE_NAME]
               pattern

Define and run a single task 'playbook' against a set of hosts

positional arguments:
  pattern               host pattern

options:
  --become-password-file BECOME_PASSWORD_FILE, --become-pass-file BECOME_PASSWORD_FILE
                        Become password file
  --connection-password-file CONNECTION_PASSWORD_FILE, --conn-pass-file CONNECTION_PASSWORD_FILE
                        Connection password file
  --flush-cache         clear the fact cache for every host in inventory
  --list-hosts          outputs a list of matching hosts; does not execute anything else
  --playbook-dir BASEDIR
                        Since this tool does not use playbooks, use this as a substitute playbook directory. This sets the relative path for many features including roles/ group_vars/ etc.
  --task-timeout TASK_TIMEOUT
                        set task timeout limit in seconds, must be positive integer.
  --vault-id VAULT_IDS  the vault identity to use. This argument may be specified multiple times.
  --vault-password-file VAULT_PASSWORD_FILES, --vault-pass-file VAULT_PASSWORD_FILES
                        vault password file
  --version             show program's version number, config file location, configured module search path, module location, executable location and exit
  -B SECONDS, --background SECONDS
                        run asynchronously, failing after X seconds (default=N/A)
  -C, --check           don't make any changes; instead, try to predict some of the changes that may occur
  -D, --diff            when changing (small) files and templates, show the differences in those files; works great with --check
  -J, --ask-vault-password, --ask-vault-pass
                        ask for vault password
  -K, --ask-become-pass
                        ask for privilege escalation password
  -M MODULE_PATH, --module-path MODULE_PATH
                        prepend colon-separated path(s) to module library (default={{ ANSIBLE_HOME ~ "/plugins/modules:/usr/share/ansible/plugins/modules" }}). This argument may be specified multiple times.
  -P POLL_INTERVAL, --poll POLL_INTERVAL
                        set the poll interval if using -B (default=15)
  -a MODULE_ARGS, --args MODULE_ARGS
                        The action's options in space separated k=v format: -a 'opt1=val1 opt2=val2' or a json string: -a '{"opt1": "val1", "opt2": "val2"}'
  -e EXTRA_VARS, --extra-vars EXTRA_VARS
                        set additional variables as key=value or YAML/JSON, if filename prepend with @. This argument may be specified multiple times.
  -f FORKS, --forks FORKS
                        specify number of parallel processes to use (default=5)
  -h, --help            show this help message and exit
  -i INVENTORY, --inventory INVENTORY, --inventory-file INVENTORY
                        specify inventory host path or comma separated host list. This argument may be specified multiple times.
  -k, --ask-pass        ask for connection password
  -l SUBSET, --limit SUBSET
                        further limit selected hosts to an additional pattern
  -m MODULE_NAME, --module-name MODULE_NAME
                        Name of the action to execute (default=command)
  -o, --one-line        condense output
  -t TREE, --tree TREE  log output to this directory
  -v, --verbose         Causes Ansible to print more debug messages. Adding multiple -v will increase the verbosity, the builtin plugins currently evaluate up to -vvvvvv. A reasonable level to start is -vvv, connection
                        debugging might require -vvvv. This argument may be specified multiple times.

Privilege Escalation Options:
  control how and which user you become as on target hosts

  --become-method BECOME_METHOD
                        privilege escalation method to use (default=sudo), use `ansible-doc -t become -l` to list valid choices.
  --become-user BECOME_USER
                        run operations as this user (default=root)
  -b, --become          run operations with become (does not imply password prompting)

Connection Options:
  control as whom and how to connect to hosts

  --private-key PRIVATE_KEY_FILE, --key-file PRIVATE_KEY_FILE
                        use this file to authenticate the connection
  --scp-extra-args SCP_EXTRA_ARGS
                        specify extra arguments to pass to scp only (e.g. -l)
  --sftp-extra-args SFTP_EXTRA_ARGS
                        specify extra arguments to pass to sftp only (e.g. -f, -l)
  --ssh-common-args SSH_COMMON_ARGS
                        specify common arguments to pass to sftp/scp/ssh (e.g. ProxyCommand)
  --ssh-extra-args SSH_EXTRA_ARGS
                        specify extra arguments to pass to ssh only (e.g. -R)
  -T TIMEOUT, --timeout TIMEOUT
                        override the connection timeout in seconds (default depends on connection)
  -c CONNECTION, --connection CONNECTION
                        connection type to use (default=ssh)
  -u REMOTE_USER, --user REMOTE_USER
                        connect as this user (default=None)

Some actions do not make sense in Ad-Hoc (include, meta, etc)
ansible:~# 
````
