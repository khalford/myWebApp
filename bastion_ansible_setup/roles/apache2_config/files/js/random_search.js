function http_request() {
    remove_old_results()
    var id = Math.floor(Math.random() * 1000000000);
    const url = `https://api.github.com/repositories/${id}/contributors`;
    console.log(url)
    const http = new XMLHttpRequest();
    http.open('GET', url);
    http.setRequestHeader('Authorization', 'Bearer ' + token);
    http.send();
    http.onreadystatechange = function(){
        if (this.readyState==4 && this.status==200) {
            const text_data = http.responseText;
            const json_data = JSON.parse(text_data);
            repo_data = get_repo_data(id)
            display(json_data)
        } else if (this.readyState==4 && this.status==404) {
            http_request()
        };
    };
};

function get_repo_data(id) {
    const url = `https://api.github.com/repositories/${id}`;
    const http = new XMLHttpRequest();
    http.open('GET', url);
    http.setRequestHeader('Authorization', 'Bearer ' + token);
    http.send();
    http.onreadystatechange = function(){
        if (this.readyState==4 && this.status==200) {
            const text_data = http.responseText;
            const json_data = JSON.parse(text_data);
            display_repo_name(json_data)
        } else if (this.readyState==4 && this.status==404) {
            throw new Error("Tried to find repo data but failed. Should not have failed.")
        };
    };
    
}

function remove_old_results(){
    const old_results = document.querySelectorAll('.commit-entry-search')
    for (i=0; i < old_results.length; i++){
        old_results[i].remove()
    }
    const repo_name = document.getElementById("repo-name")
    if (!repo_name) {
        return
    } else {
        repo_name.remove()
    }
}

function display(json_data){
    const list = document.getElementById("results");
    for (let i =0; i < json_data.length; i++ ) {
        let obj = json_data[i];
        var item = document.createElement('li');
        item.className = 'commit-entry-search'
        item.innerHTML = `<img height='15' width='15' src='${obj.avatar_url}'/><a class='commit-item' href='${obj.html_url}'>${obj.login}</a> commits: ${obj.contributions}`;
        list.appendChild(item);
    };
};

function display_repo_name(repo_data){
    const results_div = document.getElementById("search-results")
    const results_list = document.getElementById("results")
    var repo_name = document.createElement('p')
    repo_name.id = "repo-name"
    repo_name.innerHTML = `<a href='https://github.com/${repo_data.full_name}'>${repo_data.full_name}</a>`
    results_div.insertBefore(repo_name, results_list)
}

const token = ""
http_request()