<!DOCTYPE html>
<html lang="en">
    <head>
        <title>STFC GitHub Stats</title>
        <meta charset="utf-8" name="viewport" content="width=device-width, inital-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    </head>
    <body>
        <div class="container p-3">
            <p><a class="link-offset-2 link-underline link-underline-opacity-0" href="st2-cloud-pack.php">st2-cloud-pack</a></p>
        </div>
        <div class="container p-5">
            <?php
            try {
                $db = new PDO('mysql:host=ip;dbname=github_stats', 'admin', array(
                    PDO::MYSQL_ATTR_SSL_KEY    =>'/home/oxg98278/client.key',
                    PDO::MYSQL_ATTR_SSL_CERT=>'/home/oxg98278/client.crt',
                    PDO::MYSQL_ATTR_SSL_CA    =>'/home/oxg98278/ca.crt'
                    )
                );
                echo "<h2>Most Commits SCD-Openstack-Utils</h2><ol>";
                foreach($db->query("SELECT username, avatar_url, html_url, no_commits FROM scd_table") as $row) {
                        echo "<li><img height='15' width='15' src=".$row['avatar_url']."/><a class='link-offset-2 link-underline link-underline-opacity-0' href=".$row['html_url'].">".$row['username']."'s </a>".'commits: '.$row['no_commits']."</li>";
                }
                echo "</ol>";
                } catch (PDOException $e) {
                    print "Error!: " . $e->getMessage() . "<br/>";
                    die();
            }?>
        </div>
    </body>
</html>