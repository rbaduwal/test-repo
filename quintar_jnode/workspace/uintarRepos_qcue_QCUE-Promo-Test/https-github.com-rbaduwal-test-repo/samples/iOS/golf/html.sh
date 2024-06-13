#!/bin/sh
NOW=$(date +"%d-%B-%Y")
touch pga-sandbox-index.html
cat > pga-sandbox-index.html << EOF
<!DOCTYPE html>
<html>
<head>
   <meta charset="UTF-8">
   <title>Quintar Apps</title>
</head>
<body>

<header>
<style>
h1 {text-align: center;}
</style>
        <img class="header-img" src ="https://quintarpub.blob.core.windows.net/appbuilds/IOS/Images/quintar.ico" alt="W3Schools" width="100" height="100" href="https://www.javapedia.net"/>
        <h1>Quintar Golf Sandbox IOS App </h1>
    </header>
</body>

<p style="text-align:center" > Click on the image to download the App<p>

<style>
img {
  display: block;
  margin-left: auto;
  margin-right: auto;
}
</style>
<a href="itms-services://?action=download-manifest&url=$2">             
  <img  src="https://quintarpub.blob.core.windows.net/appbuilds/IOS/Images/appstore.png" alt="W3Schools" width="50" height="50" >
</a>

<p><b>Version : $1</b> </p>

<p><b>Created On : $NOW</b> </p>

</body>
</html>

EOF
