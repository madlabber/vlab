# vlab

Requires Powershell 5.1
Requires PowerCLI Core
Requires nonde.js
Requires nodemon
Requires express
Requires Myrtille

cd C:\vlab
npm install express -save
npm install nodemon -g

Start a powershell menu
cd C:\vlab
.\start-vlabmenu.ps1

in the admin menu, set credentials

start the web service:
nodemon vlab-node.js
