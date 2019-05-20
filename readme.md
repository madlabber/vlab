# vlab
An automation framework and web portal for provisioning virtual lab/test/dev environments on top of VMware vSphere and NetApp ONTAP9.

## Requires: 
- Powershell 5.1
- PowerCLI Core
- node.js
- nodemon
- express
- Myrtille

## Installation
1. Install Powershell 5.1.
2. Install PowerCLI
3. Install Node.JS
4. Install nodemon
```
  npm install nodemon -g
```  
5. Clone the repo to a local directory, i.e. C:\vlab
6. Install express into that directory:
```
cd C:\vlab
npm install express -save
```
7. Install Myrtille
8. Retreive the hash value for the nested lab password from the myrtille instance by using a URL.  i.e.:
https://server/myrtille/GetHash.aspx?password=password
9. Copy the settings.cfg.sample file to settings.cfg, and customize it as required.
10. Start the powershell menu
```
cd C:\vlab
.\start-vlabmenu.ps1
```
11. In the admin menu, set credentials to save credentials for vcenter and 
12. start the web service:
```
nodemon vlab-node.js
```
