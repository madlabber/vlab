var Service = require('node-windows').Service;
     // Create a new service object
     // npm install -g node-windows
     var svc = new Service({
          name:'vlab-service',
          description: 'vLAB Web Service',
          script: 'C:\\vlab\\vlab-node.js'
     });

     // Listen for the "install" event, which indicates the
     // process is available as a service.

     svc.on('install',function(){
                svc.start();
     });

     svc.install();