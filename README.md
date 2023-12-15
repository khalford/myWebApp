This repository contains a collection of Ansible scripts I have written for L&D.<br>
Everything here is configured for my personal use, so odds are they will not run straight away on your machine.<br>
The Playbooks require a `cloud.yaml` file in `~/.config/openstack` (on your ansible host) to provide ansible with the correct credentials. <br>
<br>
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