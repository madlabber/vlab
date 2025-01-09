# vlab
An automation framework and web portal for provisioning virtual lab/test/dev environments on top of VMware vSphere and NetApp ONTAP.

## Requires: 
- Powershell 5.1

## Installs:
- NetApp Powershell Toolkit (PSTK)
- PowerCLI Core
- node.js
- nodemon
- express
- Myrtille

## Installation
1. Install Powershell 5.1.
2. Clone the repo to a local directory, i.e. C:\vlab
3. Edit the settings.cfg file to reflect your environment
4. Run the ./install.ps1 script
5. Run ./startup.ps1
6. Open a browser to access the portal
```
http://<server-address>:8081
```

## Notes
The web service runs on port 8081 by default.  Allow this port through the windows firewall to enable access to the portal over the network.  

AD delegation may be needed if the host is AD joined.

