## Lampstack Ansible Details<br>
For [lampstack-ansible](lampstack-ansible):<br>
- On the webpage, [index.php](lampstack-ansible/roles/apache2_config/files/index.php) will take priority over [index.html](lampstack-ansible/roles/apache2_config/files/index.html) unless index.php doesn't exist.
- The database configuration can be found in this [task](lampstack-ansible/roles/mariadb_config/tasks/main.yaml)<br>
- Default logins User:Password (Both of these should be changed after setup): <br>
    - root : root<br>
    - admin : password<br>

Default database is called **github_stats** and the default table is **table1** which looks like below:<br>

| Field      | Type         | Null | Key | Default |
|------------|--------------|------|-----|---------|
| username   | varchar(255) | YES  | UNI | NULL    |
| no_commits | int(11)      | YES  |     | NULL    |

- Two services will run with **always-restart** and **on boot**: **github_scrape** and **update_db**<br>
**github_scrape**:<br>
  - This service's script is stored in */home/github_scrape/github_scrape.sh*<br>
  - It runs a GitHub Rest Api get request every 30 seconds that will get the contributor data from the SCD-Openstack-Utils Repo<br>
  - That data is stored in */home/github_scrape/SCD_Openstack_Utils_commits*<br>
  - A GitHub Api Token is required for the script to run due to rate limiting.<br>
  - You can enter your token in the **curl** in this [file](lampstack-ansible/roles/github_scrape_config/files/github_scrape.sh)<br>

- **update_db**:<br>
  - This service's script is also stored in */home/github_scrape/update_db.sh*<br>
  - It runs every 30 seconds as long as github_scrape.service is running.<br>
  - It will update the above table with info from the *SCD_Openstack_Utils_commits* file.<br>
  - If entries already exist in the table they will be updated with whatever values are in the info file.<br> 

The above two services are run by a user called **github_scrape**. This user is in the sudoers file with NOPASSWD.<br>

### Deploy a Lampstack service on a Private Network in Openstack
The aim of this repo is to deploy a Lampstack service as automated as possible for L&D.
The scripts will: 
  - Create a private network in Openstack.
  - Provision a web serving VM(s) using PHP to deliver content from a SQL database.
  - Provision a database serving VM using MariaDB and SSL certificates to communicate.
  - Run a Python script as a service to update the database with info from the Github Rest API.

## Setup Instructions:
# Prerequisites:
  - Download a **clouds.yaml** from the Horizon interface on Openstack.
  - Create a VM on the internal network with the **clouds.yaml** in the path */home/<fed_id>/.config/clouds.yaml*
  - Run the installation commands on the VM in the internal network.

# Setup Infrastructure
  1. Clone this repo: `{git clone https://github.com/khalford/myWebApp.git}`
  1. Change directory to the git repo: `{cd myWebApp}`
  1. Run **setup.sh** with root privileges: `{sudo bash setup.sh}`
  1. Now you need to activate the virtual environment created by the setup script: `{source ansible-venv/bin/activate}`
  1. Edit the variables in **vars.tfvars**. All of these variables are mandatory. There is a description of each variables in variables.tf if you don't know what they are.
  1. Now you need to initialise the directory with Terraform: `{terraform init}`
  1. Next to plan the Terraform provisioning. Here we use the flag *-var-file=* to specify our input variables and *-out=plan* to save the plan to a file: `{terraform plan -out plan -var-file=./vars.tfvars}`
  1. Finally, apply the plan: `{terraform apply plan}`
  
# Setup Ansible Configuration
Now you have the infrastructure setup, you need to run Ansible to configure all of the VMs. To do this we ssh into our Bastion Host and run Ansible from there.
  1. SSH into the Bastion Host through the Load Balancer. In the previous setup you would have seen a debug statement in the console. This tells you what the user and ip you have specified is: `{ssh <fed_id>@<floating_ip> -p 2222}`
  1. This VM should already be setup with all requirements. Just run the Ansible Playbook: `{ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-openstack.yaml play.yaml}`
Provided no errors occured, go to the floating ip in your browser and you should see the webpage!