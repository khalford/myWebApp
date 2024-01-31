#!/usr/bin/env python3 

from typing import List, Dict
from time import sleep
from requests import get
from pymysql import connect

def get_data(TOKEN: str, url: str) -> List[Dict]:
    headers = {'Authorization': 'token ' + TOKEN}
    response = get(url, headers=headers)
    return response.json()

def prune_data(data: List[Dict]) -> List[Dict]:
    data_to_store = []
    for dict in data:
        new_dict = {
            "username": dict["login"],
            "contributions": dict["contributions"],
            "profile": dict["url"],
            "avatar": dict["avatar_url"],
            }
        data_to_store.append(new_dict)
    return data_to_store

def update_table(
        host: str, database: str, table: str, data: List[Dict], user: str, password: str
        ):
    with connect(host=host, user=user, password=password) as cnx:
        cursor = cnx.cursor()
        for item in data:
            QUERY = f'INSERT INTO {database}.{table} (username, avatar_url, html_url, no_commits) VALUES ("{item["username"]}","{item["avatar"]}", "{item["profile"]}", "{item["contributions"]}") ON DUPLICATE KEY UPDATE username="{item["username"]}", no_commits="{item["contributions"]}";'
            cursor.execute(QUERY)
        cnx.commit()

def repo_func(TOKEN: str, host: str, user: str, password: str, url: str, database: str, table: str):
    response = get_data(TOKEN, url)
    pruned_response = prune_data(response)
    update_table(host=host, database=database, table=table, data=pruned_response, user=user, password=password)


if __name__ == "__main__":
    TOKEN = "<YOUR_TOKEN>"
    host = "localhost"
    # Create repo maps here and add to the list
    SCD_Openstack_Utils = {
        "url": "https://api.github.com/repos/stfc/SCD-Openstack-Utils/contributors?per_page-100",
        "database": "github_stats",
        "table": "scd_table",
    }
    st2_cloud_pack = {
        "url": "https://api.github.com/repos/stfc/st2-cloud-pack/contributors?per_page-100",
        "database": "github_stats",
        "table": "st2_table",
    }
    repos = [SCD_Openstack_Utils, st2_cloud_pack]
    while True:
        for repo in repos:
            repo_func(TOKEN, host, "root", "root", **repo)
        sleep(60)
        