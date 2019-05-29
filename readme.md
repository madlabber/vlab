# vlab
An automation framework and web portal for provisioning virtual lab/test/dev environments on top of VMware vSphere and NetApp ONTAP9.

## Requires: 
- Powershell 5.1
- NetApp Powershell Toolkit (PSTK)
- PowerCLI Core
- node.js
- nodemon
- express
- Myrtille

## Installation
1. Install Powershell 5.1.
2. Install NetApp Powershell Toolkit
3. Clone the repo to a local directory, i.e. C:\vlab
4. Run the ./install.ps1 script
5. Edit the settings.cfg file to reflect your environment
6. start the web service:
```
nodemon vlab-node.js
```
7. Open a browser to access the portal
```
http://<server-address>:8081
```
