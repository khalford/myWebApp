This repository contains a collection of Ansible scripts I have written for L&D.<br>
Everything here is configured for my personal use, so odds are they will not run straight away on your machine.<br>
The Playbooks require a `cloud.yaml` file in `~/.config/openstack` (on your ansible host) to provide ansible with the correct credentials. <br>
<br>
## Lampstack Ansible Details<br>
For [lampstack-ansible](lampstack-ansible):<br>
- The database configuration can be found in this [task](lampstack-ansible/roles/mariadb_config/tasks/main.yaml)<br>
- Default logins (Both of these should be changed after setup): <br>
    - User: root Password: root<br>
    - User: Admin Password: password<br>

Default database is called **github_stats** and the default table is **table1** which looks like below:<br>

| Field      | Type         | Null | Key | Default | Extra          |
|------------|--------------|------|-----|---------|----------------|
| id         | int          | NO   | PRI | NULL    | auto_increment |
| username   | varchar(255) | YES  |     | NULL    |                |
| no_commits | int          | YES  |     | NULL    |                |