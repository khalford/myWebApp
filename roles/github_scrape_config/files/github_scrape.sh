#!/bin/bash

while true
do
  # Get data
  curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: Bearer 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" "https://api.github.com/repos/stfc/SCD-Openstack-Utils/contributors?per_page-100" | grep 'contributions\|login\|html_url\|avatar_url' | paste -d "" - - - - > /home/github_scrape/SCD_Openstack_Utils_commits

  # Format data
  sed -i 's/"//g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/login: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/contributions: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/html_url: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/avatar_url: //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/ //g' /home/github_scrape/SCD_Openstack_Utils_commits
  sed -i 's/,/, /g' /home/github_scrape/SCD_Openstack_Utils_commits

  # Get data
  curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: Bearer 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" "https://api.github.com/repos/stfc/st2-cloud-pack/contributors?per_page-100" | grep 'contributions\|login\|html_url\|avatar_url' | paste -d "" - - - - > /home/github_scrape/st2_cloud_pack_commits

  # Format data
  sed -i 's/"//g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/login: //g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/contributions: //g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/html_url: //g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/avatar_url: //g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/ //g' /home/github_scrape/st2_cloud_pack_commits
  sed -i 's/,/, /g' /home/github_scrape/st2_cloud_pack_commits

  # Run every 30 seconds
  sleep 30
done