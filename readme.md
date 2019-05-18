# vlab
An automation framework and web portal for provisioning virtual lab/test/dev environments on an environment with ONTAP and vSphere.

## Requires: 
- Powershell 5.1
- PowerCLI Core
- nonde.js
- nodemon
- express
- Myrtille

## Installation
Install Powershell 5.1.

Install PowerCLI

Install Node.JS

Install nodemon
```
  npm install nodemon -g
```  
Clone the repo to a local directory, i.e. C:\vlab

Install express into that directory:
```
cd C:\vlab
npm install express -save
```
Install Myrtille

Retreive the hash value for the nested lab password from the myrtille instance by using a URL.  i.e.:
https://server/myrtille/GetHash.aspx?password=password

Copy the settings.cfg.sample file to settings.cfg, and customize it as required.

Start a powershell menu
```
cd C:\vlab
.\start-vlabmenu.ps1
```
In the admin menu, set credentials to save credentials for vcenter and 

start the web service:
```
nodemon vlab-node.js
```
