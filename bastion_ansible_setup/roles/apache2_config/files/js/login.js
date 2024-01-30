function validate() {
    const password = document.getElementById("passwd").value;
    const username = document.getElementById("uname").value;
    if (username=="kalibh" && password=="password") {
        window.location = "account.html";
        console.log("Cfhyae")
    } else {
        return false , '';
    };
};