#!/bin/bash

# Loop through all lines in commit file and update sql table
while true; do

    while read line; do
            commiter=$( awk -F', ' '{ print $1 }' <<< $line)
            no_commits=$( awk -F', ' '{ print $2 }' <<< $line)
            sudo mysql -e "INSERT INTO github_stats.table1 (username, no_commits) VALUES ('${commiter}', '${no_commits}') ON DUPLICATE KEY UPDATE username='${commiter}', no_commits='${no_commits}';"
    done < /home/github_scrape/SCD_Openstack_Utils_commits
    sleep 30
done