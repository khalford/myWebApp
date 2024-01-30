function search(){
    const search_string = document.getElementById('search-string').value;
    const owner = search_string.split('/')[0];
    const repo = search_string.split('/')[1];
    const http = new XMLHttpRequest();
    const url = `https://api.github.com/repos/${owner}/${repo}/contributors`;
    http.open('GET', url);
    http.send();
    http.onreadystatechange = function(){
        if(this.readyState==4 && this.status==200){
            var status_text = document.getElementById("search-status")
            status_text.innerText = ""
            const text_data = http.responseText;
            const json_data = JSON.parse(text_data);
            display(json_data)
        } else if (this.readyState==4 && this.status==404){
            var status_text = document.getElementById("search-status")
            status_text.innerText = "Repo was not found. Check for typos and that the Repo stil exists."
        }
    };
};

function remove_old_results(){
    const old_results = document.querySelectorAll('.commit-entry-search')
    for (i=0; i < old_results.length; i++){
        old_results[i].remove()
    }
}

function display(json_data){
    remove_old_results()
    const list = document.getElementById("results");
    for (let i =0; i < json_data.length; i++ ) {
        let obj = json_data[i];
        var item = document.createElement('li');
        item.className = 'commit-entry-search'
        item.innerHTML = `<img height='15' width='15' src='${obj.avatar_url}'/><a class='commit-item' href='${obj.profile_url}'>${obj.login}</a> commits: ${obj.contributions}`;
        list.appendChild(item);
    };
};