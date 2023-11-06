# EVT Tech Challenge
Mark Rumsey's solution for EVT Recruiting's 2023 technical challenge

## Requirements

### Docker (if building from Dockerfile)

How to install: https://docs.docker.com/engine/install/

### Terraform

How to install: https://developer.hashicorp.com/terraform/downloads

### Azure CLI

How to install: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

### Ansible [core 2.15.5]

How to install: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Run Webserver

1. Install requirements locally OR run ```docker build -t evt-tech-challenge . && docker run -it evt-tech-challenge``` 

2. ```cd ./src/``` or ```cd /app/``` in docker container

3. Login to Microsoft Azure account with ```az login```

4. Choose the Azure subscription you want to use to run the webserver (subscription id is in the "id" field)

5. Build and run webserver with ```./runserver SUBSCRIPTION_ID```

6. When build script is finished, it will output the address to access the webserver in a web browser. If warned by web browser, go to advanced settings and continue to site.

7. When finished, run ```./cleanup.sh``` to delete Azure resources and logout

## Solution Details

Docker - I chose to use Docker because it allows for the webserver build to be easily reproducible by users on any system.

Azure - I chose Azure because it has all of the resources necessary to host a webserver on a public IP address. I decided to use it over other cloud service providers like AWS because I have the most experience using it for creating VMs due to its free resources for students.

Terraform - When I decided that I would use Azure to run the webserver, I knew that I would also want to use Terraform. This is because there are many different Azure services required, and Terraform offers an easy way to keep track all of them and provision them with a single command.

Ansible - Because the newly created Linux VM on Azure required many package installations and configuration changes to set up the webserver, I decided to use Ansible in order to manage this. I decided that this was a better choice than a programming language because Ansible provides a level of status updating and idempotence in its execution that would be difficult to replicate with a simple script. Ansible would also help with the scalability of my webserver. If I decided to add additional servers, Ansible could configure all of them at once. I chose Ansible specifically over config management competitors like Puppet, Chef, or Salt because I have had prior experience and training in Ansible during my summer internship with EVT in 2022.

Nginx - I chose nginx for my webserver because of the builtin features it offers for a basic HTTP server, like SSL support for connecting to the server on a secure port with https. When doing research on which webserver to use, I read that nginx was faster and more efficient than competitors like Apache. While those improvements may not be noticeable on a small-scale webserver like this, they would add up on one with multiple servers and high traffic.