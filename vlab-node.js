const express = require('express');
const app=express();
const port = 8080

var fs = require('fs');
var path = require('path');
var navbar = '<center><table><tr><td><center><b><h2 style="margin:0;padding:0;"">Homelab On Demand</h2></b></center></td></tr><tr><td><center><a href="/">Home</a> | <a href="/catalog">Catalog</a> | <a href="/instances">Instances</a> | <a href="/admin">Admin</a></center></td></tr></table></center><hr>';

app.get('/', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./show-dashboard-html.ps1"); 
    var pgtitle = "";
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<head><meta http-equiv="refresh" content="60" /><meta name="viewport" content="width=device-width, initial-scale=1"></head>');
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){ res.end('<br><hr>:<hr>') });
    child.stdin.end();
}));

app.get('/catalog', (
  function (req,res){
    console.log(''+req.url);
    var psscript = require.resolve("./show-vlabcatalog-html.ps1");   
    var pgtitle = "Lab Catalog";      

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<head><meta name="viewport" content="width=device-width, initial-scale=1"></head>');
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){ res.end('<br><hr>:<hr>') });
    child.stdin.end();
}));

app.get('/instances', (
  function (req,res){
    var psscript = require.resolve("./show-vlabs-html.ps1");   
    var pgtitle = "Lab Instances";      

    console.log(''+req.url);    
    var url = require('url').parse(req.url)
    let pathName = url.pathname
    
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<head><meta http-equiv="refresh" content="60" /><meta name="viewport" content="width=device-width, initial-scale=1"></head>');
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){ res.end('<br><hr>:<hr>') });
    child.stdin.end();
}));

app.get('/admin', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./show-adminmenu-html.ps1"); 
    var pgtitle = "Lab Administration";
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){ res.end('<br><hr>:<hr>') });
    child.stdin.end();
}));

app.get('/item', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./show-vlab-html.ps1"); 
    var pgtitle = "Lab Details";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      res.write('<hr>');
      res.write('<form method="post" action="/provision?'+url.query+'">');
      res.write('<button type="submit">Provision</button><hr>');
      res.write('</form>');
      res.end(' ');
    });
    child.stdin.end();     
}));

app.get('/instance', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./show-vlab-html.ps1"); 
    var pgtitle = "Lab Instance";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write('<head><meta http-equiv="refresh" content="60" /><meta name="viewport" content="width=device-width, initial-scale=1"></head>');
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      res.write('<hr>');
      res.write('<form method="post" action="/start?'+url.query+'">');
      res.write('<button type="submit">Start</button> ');
      res.write('<button type="submit" formaction="/stop?'+url.query+'">Stop</button> ');          
      res.write('<button type="submit" formaction="/kill?'+url.query+'">Kill</button> ');  
      res.write('<button type="submit" formaction="/destroy?'+url.query+'">Destroy</button> '); 
      res.write('<hr>');
      res.write('</form>');
      res.end(' ');
    });
    child.stdin.end();       
}));

app.get('/config', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./show-vlabsettings-html.ps1"); 
    var pgtitle = "Configuration Settings";
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+':</b><hr><br>');

    console.log(":: "+psscript);
    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){res.write(""+data)});
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){ res.end('<br><hr>:<hr>') });
    child.stdin.end(); 
}));

app.post('/provision', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./new-vlab.ps1"); 
    var pgtitle = "Provisioning instance...";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+'</b><hr><br>');

    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){
      var strData = ''+data;
      if (strData.trim() != '') {res.write(""+data+" <br>")}
    });
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      console.log("Script finished");
      res.write('<script type="text/javascript">javascript:window.location=document.referrer;</script>');
      res.end('Done.');
    });
    child.stdin.end(); 
}));

app.all('/start', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./start-vlab.ps1"); 
    var pgtitle = "Starting instance...";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+'</b><hr><br>');

    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){
      var strData = ''+data;
      if (strData.trim() != '') {res.write(""+data+" <br>")}
    });
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      console.log("Script finished");
      //res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
      res.write('<script type="text/javascript">javascript:window.location=document.referrer;</script>');
      res.end('Done.');
    });
    child.stdin.end(); 
}));

app.post('/stop', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./stop-vlab.ps1"); 
    var pgtitle = "Stopping instance...";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+'</b><hr><br>');

    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){
      var strData = ''+data;
      if (strData.trim() != '') {res.write(""+data+" <br>")}
    });
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      console.log("Script finished");
     // res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
      res.write('<script type="text/javascript">javascript:window.location=document.referrer;</script>');
      res.end('Done.');
    });
    child.stdin.end(); 
}));

app.post('/kill', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./stop-vlab.ps1"); 
    var pgtitle = "Killing instance...";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+'</b><hr><br>');

    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query,"-kill"],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){
      var strData = ''+data;
      if (strData.trim() != '') {res.write(""+data+" <br>")}
    });
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      console.log("Script finished");
      //res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
      res.write('<script type="text/javascript">javascript:window.location=document.referrer;</script>');
      res.end('Done.');
    });
    child.stdin.end(); 
}));

app.post('/destroy', (
  function (req, res) { 
    console.log(''+req.url);  
    var psscript = require.resolve("./remove-vlab.ps1"); 
    var pgtitle = "Destroying instance...";
    var url = require('url').parse(req.url)
    res.on('error', function(data){console.log(""+data)});

    res.writeHead(200, {'Content-Type': 'text/html'});
    res.write(''+navbar);
    res.write('<b>'+pgtitle+'</b><hr><br>');

    var spawn = require("child_process").spawn,child;
    child = spawn("powershell.exe",[psscript,url.query],{ cwd: process.cwd(), detached: false });
    child.stdout.on("data",function(data){
      var strData = ''+data;
      if (strData.trim() != '') {res.write(""+data+" <br>")}
    });
    child.stderr.on("data",function(data){console.log(""+data)});
    child.on("exit",function(){
      console.log("Script finished");
      res.write('<script type="text/javascript">window.location = "/instances";</script>');
      res.end('Done.');
    });
    child.stdin.end(); 
}));

app.use(express.static('cmdb'));
app.use(express.static('html'));

app.listen(port, () => console.log(`listening on port ${port}!`))

console.log("This is pid " + process.pid);
console.log("process.cwd:"+process.cwd());
console.log("process.argv:"+process.argv);

// Gather data at startup
setTimeout(function () { 
  var psscript = require.resolve("./get-vlabstats.ps1"); 

  console.log(":: "+psscript);
  var spawn = require("child_process").spawn,child;
  child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: true });
}, 1000);

// Poll for fresh state info
setInterval(function () { 
  var psscript = require.resolve("./get-vlabstats.ps1"); 

  console.log(":: "+psscript);
  var spawn = require("child_process").spawn,child;
  child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: true });
}, 60000);