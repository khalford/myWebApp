<!DOCTYPE html>
<html lang="en">
    <head>
        <title>STFC GitHub Stats</title>
        <meta charset="utf-8" name="viewport" content="width=device-width, inital-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    </head>
    <body>
        <div class="container p-5">
            <?php
            try {
                $db = new PDO("mysql:host=localhost;dbname=github_stats", root, "root");
                echo "<h2>Most Commits SCD-Openstack-Utils</h2><ol>";
                foreach($db->query("SELECT username,no_commits FROM table1") as $row) {
                        echo "<li>".$row['username']."'s ".'commits: '.$row['no_commits']."</li>";
                }
                echo "</ol>";
                } catch (PDOException $e) {
                    print "Error!: " . $e->getMessage() . "<br/>";
                    die();
            }?>
        </div>
    </body>
</html>