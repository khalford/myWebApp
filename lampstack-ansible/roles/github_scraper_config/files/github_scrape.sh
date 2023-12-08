#!/bin/bash

while true
do
  # Get data frp,
  curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/stfc/SCD-Openstack-Utils/contributors?per_page-100" | grep 'contributions\|login' | paste -d "" - - > /home/github_scrape/SCD_Openstack_Utils_commits

  # Format data
  sed -i 's/"//g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/login: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/contributions: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/ //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/,/, /g' /home/github_scrape/SCD_Openstack_Utils_commits

  # Run every 30 seconds
  sleep 30
done