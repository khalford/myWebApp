function http_request() {
    const token = ""
    var id = Math.floor(Math.random() * 1000000000);
    // id = '491438292'
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
            display(json_data)
        } else if (this.readyState==4 && this.status==404) {
            http_request()
        };
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

http_request()