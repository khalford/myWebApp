#!/bin/python3

# Loop through all lines in commit file and update sql table
while true; do

    while read line1; do
            commiter=$( awk -F', ' '{ print $1 }' <<< $line1)
            avatar_url=$( awk -F', ' '{ print $2 }' <<< $line1)
            html_url=$( awk -F', ' '{ print $3 }' <<< $line1)
            no_commits=$( awk -F', ' '{ print $4 }' <<< $line1)
            sudo mysql -e "INSERT INTO github_stats.scd_table (username, avatar_url, html_url, no_commits) VALUES ('${commiter}','${avatar_url}', '${html_url}', '${no_commits}') ON DUPLICATE KEY UPDATE username='${commiter}', no_commits='${no_commits}';"
    done < /home/github_scrape/SCD_Openstack_Utils_commits

    while read line2; do
            commiter=$( awk -F', ' '{ print $1 }' <<< $line2)
            avatar_url=$( awk -F', ' '{ print $2 }' <<< $line2)
            html_url=$( awk -F', ' '{ print $3 }' <<< $line2)
            no_commits=$( awk -F', ' '{ print $4 }' <<< $line2)
            sudo mysql -e "INSERT INTO github_stats.st2_table (username, avatar_url, html_url, no_commits) VALUES ('${commiter}','${avatar_url}', '${html_url}', '${no_commits}') ON DUPLICATE KEY UPDATE username='${commiter}', no_commits='${no_commits}';"
    done < /home/github_scrape/st2_cloud_pack_commits

    sleep 30
done