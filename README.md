# Deploy a Lampstack service on a Private Network in Openstack
The aim of this repo is to deploy a Lampstack service as automated as possible for L&D.
The scripts will: 
  - Create a private network in Openstack.
  - Provision a web serving VM(s) using PHP to deliver content from a SQL database.
  - Provision a database serving VM using MariaDB and SSL certificates to communicate.
  - Run a Python script as a service to update the database with info from the Github Rest API.

# Setup Instructions:
## Prerequisites:
  - Download a **clouds.yaml** from the Horizon interface on Openstack.
  - Create a VM on the internal network with:
    - The **clouds.yaml** in the path */home/<fed_id>/.config/clouds.yaml*. Ensure you write your password into the file.
    - This VM must also be of an Ubuntu image.
    - You need a Public/Private Key pair on this VM and in Openstack which does **NOT** have a passphrase.
  - Run the installation commands on the VM in the internal network.

### Setup Infrastructure
  1. Clone this repo: `git clone https://github.com/khalford/myWebApp.git`
  1. Change directory to the git repo: `cd myWebApp`
  1. Run **setup.sh** with root privileges: `sudo bash setup.sh`
  1. Now you need to activate the virtual environment created by the setup script: `source ansible-venv/bin/activate`
  1. Edit the variables in **vars.tfvars**. All of these variables are mandatory. There is a description of each variable in **variables.tf** if you don't know what they are or how to find them.
  1. Now you need to initialise the directory with Terraform: `terraform init`
  1. Next to plan the Terraform provisioning. Here we use the flag **-var-file=** to specify our input variables and **-out=plan** to save the plan to a file: `terraform plan -out plan -var-file=./vars.tfvars`
  1. Finally, apply the plan: `terraform apply plan`
  
### Setup Ansible Configuration
Now you have the infrastructure setup, you need to run Ansible to configure all of the VMs. To do this we ssh into our Bastion Host and run Ansible from there.
  1. SSH into the Bastion Host through the Load Balancer. In the previous setup you would have seen a debug statement in the console. This tells you what the user and ip you have specified is: `ssh <fed_id>@<floating_ip> -p 2222`
  1. This VM should already be setup with all requirements. Just run the Ansible Playbook: `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-openstack.yaml play.yaml`
Provided no errors occured, go to the floating ip in your browser and you should see the webpage!