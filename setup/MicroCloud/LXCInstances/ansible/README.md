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

Ansible itself shoud be organized well. Configuration should be set up according to https://docs.ansible.com/ansible/latest/reference_appendices/config.html 

As an idea for the structure see https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html

Ansible modules can be found on https://docs.ansible.com/ansible/latest/module_plugin_guide/index.html

Templates can be found on https://github.com/devopshobbies/ansible-templates/tree/master

A list of all Modules is on https://docs.ansible.com/ansible/2.9/modules/list_of_all_modules.html

A cheat-list for the command usage is on https://docs.ansible.com/ansible/latest/command_guide/cheatsheet.html 