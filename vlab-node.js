var http = require('http');

http.createServer(
  function (req, res) {

    var url = require('url').parse(req.url)
    let pathName = url.pathname

    // Main 
    if (pathName === '/') { 
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Menu');
      res.write('<hr>');
      res.write('<a href="/catalog">vLab Catalog</a><br>');
      res.write('<a href="/instances">vLab Instances</a><br>');
      res.write('<a href="/admin">vLab Administration</a><br>');
      res.end('<hr>'+req.url);  
    } 
    // Catalog
    else if (pathName === '/catalog') { 
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Catalog');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlabcatalog-html.ps1")]);
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.end('<hr>'+req.url);
      });
      child.stdin.end();
    }
    // Instances
    else if (pathName === '/instances') { 
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Instances');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlabs-html.ps1")]);
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.end('<hr>'+req.url);
      });
      child.stdin.end();
    } 
    // Admin Menu
    else if (pathName === '/admin') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Menu');
      res.write('<hr>');
      res.write('<a href="/config">Configuration Settings</a><br>');
      //res.write('<a href="/instances">vLab Instances</a><br>');
      res.end('<hr>'+req.url); 
    }
    // Item Detail
    else if (pathName === '/item') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Item');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlab-html.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<hr>');
          res.write('<a href="/provision?'+url.query+'">[Provision]</a>');
          res.end('<br>');
      });
      child.stdin.end();     
    } 
    // Instance Detail
    else if (pathName === '/instance') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Instance');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlab-html.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<hr>');
          res.write('<a href="/start?'+url.query+'">[Start]</a> ');
          res.write('<a href="/stop?'+url.query+'">[Stop]</a> ');
          res.write('<a href="/kill?'+url.query+'">[Kill]</a> ');
          res.write('<a href="/destroy?'+url.query+'">[Destroy]</a> ');
          res.end('<br>');
      });
      child.stdin.end();       
    } 
    // Admin Settings
    else if (pathName === '/config') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Configuration');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlabsettings-html.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.end('<hr>'+req.url);
      });
      child.stdin.end();     
    } 
    // Provision
    else if (pathName === '/provision') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Provisioning...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./new-vlab.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write("<br>"+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = window.history.back();</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // start
    else if (pathName === '/start') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Starting...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./start-vlab.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write("<br>"+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = window.history.back();</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // stop
    else if (pathName === '/stop') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Stopping...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./stop-vlab.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write("<br>"+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = window.history.back();</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // kill
    else if (pathName === '/kill') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Stopping...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./stop-vlab.ps1"),url.query,"-kill"]);
      child.stdout.on("data",function(data){res.write("<br>"+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = window.history.back();</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // destroy
    else if (pathName === '/destroy') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('Destroying vLab...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./remove-vlab.ps1"),url.query]);
      child.stdout.on("data",function(data){res.write("<br>"+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = "/instances";</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // Catch all
    else {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write('vLab Menu');
      res.write('<hr>');
      res.write('<a href="/catalog">vLab Catalog</a>');
      res.end('<hr>'+req.url);  
    }
  }
).listen(8080);


 //end input