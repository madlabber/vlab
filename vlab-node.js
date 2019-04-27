var http = require('http');
var fs = require('fs');
var path = require('path');

var mimeTypes = {
  "html": "text/html",
  "mp3":"audio/mpeg",
  "mp4":"video/mp4",
  "jpeg": "image/jpeg",
  "jpg": "image/jpeg",
  "png": "image/png",
  "js": "text/javascript",
  "css": "text/css",
  "ico": "image/x-icon"};

http.createServer(
  function (req, res) {

    var url = require('url').parse(req.url)
    let pathName = url.pathname

    var navbar = '<center><table><tr><td><center><b><font size=5>Homelab On Demand</font></b></center></td></tr><tr><td><center><a href="/">Home</a> | <a href="/catalog">Catalog</a> | <a href="/instances">Instances</a> | <a href="/admin">Admin</a></center></td></tr></table></center><hr>';

    res.on('error', function(data){console.log(""+data)});

    console.log(''+req.url);
    // Main 
    if (pathName === '/') { 
      var psscript = require.resolve("./show-dashboard-html.ps1");   
         
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>:</b><hr>');

      console.log("spawning "+psscript);
      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){ res.end('<br><hr>:<hr>') });
      child.stdin.end();
    }
    // Catalog
    else if (pathName === '/catalog') { 
      var psscript = require.resolve("./show-vlabcatalog-html.ps1");   
         
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Catalog:</b><hr>');

      console.log("spawning "+psscript);
      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){ res.end('<br><hr>:<hr>') });
      child.stdin.end();
    }
    // Instances
    else if (pathName === '/instances') { 
      var psscript = require.resolve("./show-vlabs-html.ps1");   
         
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Instances:</b><hr>');

      console.log("spawning "+psscript);
      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){ res.end('<br><hr>:<hr>') });
      child.stdin.end();
    } 
    // Admin Menu
    else if (pathName === '/admin') {
      var psscript = require.resolve("./show-adminmenu-html.ps1"); 

      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Administration:</b><hr><br>');

      console.log("spawning "+psscript);
      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[psscript],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){ res.end('<br><hr>:<hr>') });
      child.stdin.end();
    }
    // Item Detail
    else if (pathName === '/item') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Details:</b><hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlab-html.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<hr>');
          res.write('<form method="post" action="/provision?'+url.query+'">');
          res.write('<button type="submit">Provision</button><hr>');
          res.write('</form>');
          res.end(' ');
      });
      child.stdin.end();     
    } 
    // Instance Detail
    else if (pathName === '/instance') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Instance:</b><hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlab-html.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
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
    } 
    // Admin Settings
    else if (pathName === '/config') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Configuration Settings</b><hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./show-vlabsettings-html.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){res.write(""+data)});
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.end('<br><hr>:<hr>');
      });
      child.stdin.end();     
    } 
    // Provision
    else if (pathName === '/provision') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('<b>Lab Provisioning...</b><hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./new-vlab.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){
        var strData = ''+data;
        if (strData.trim() != '') {res.write(""+data+" <br>")}
      });
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">javascript:window.location.href(history.go(-1));</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // start
    else if (pathName === '/start') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('Starting instance...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./start-vlab.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){
        var strData = ''+data;
        if (strData.trim() != '') {res.write(""+data+" <br>")}
      });
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // stop
    else if (pathName === '/stop') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('Stopping instance...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./stop-vlab.ps1"),url.query],{ cwd: process.cwd(), detached: false });
      child.stdout.on("data",function(data){
        var strData = ''+data;
        if (strData.trim() != '') {res.write(""+data+" <br>")}
      });
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // kill
    else if (pathName === '/kill') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('Killing instance...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./stop-vlab.ps1"),url.query,"-kill"]);
      child.stdout.on("data",function(data){
        var strData = ''+data;
        if (strData.trim() != '') {res.write(""+data+" <br>")}
      });
      child.stderr.on("data",function(data){console.log(""+data)});
      child.on("exit",function(){
          console.log("Script finished");
          res.write('<script type="text/javascript">window.location = "/instance?'+url.query+'";</script>');
          res.end('Done.');
      });
      child.stdin.end();     
    } 
    // destroy
    else if (pathName === '/destroy') {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.write(''+navbar);
      res.write('Destroying instance...');
      res.write('<hr>');

      var spawn = require("child_process").spawn,child;
      child = spawn("powershell.exe",[require.resolve("./remove-vlab.ps1"),url.query],{ cwd: process.cwd(), detached: false });
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
    } 
    // Otherwise serve a file
    else {     
      console.log(pathName);
      var filename = path.join(process.cwd(), pathName);
      console.log(filename);
      fs.exists(filename, function(exists) {
        if(!exists) {
          console.log("404: "+req.url);
          res.writeHead(404, {"Content-Type":"text/html"});
          res.write(''+navbar);
          res.write("It doesn't look like anything to me.");
          res.write('<hr>');
          res.write('<a href="/">Take me Home</a>');
          res.write('<hr>'+req.url);  
          res.end();
          //return;
        }
        else {
        var mimeType = mimeTypes[path.extname(filename).split(".")[1]];
        res.writeHead(200, {'Content-Type':mimeType});

        var fileStream = fs.createReadStream(filename);
        fileStream.pipe(res);
        }
      });
    }
  }
).listen(8080);

// timer based restart to use the latest version
console.log("This is pid " + process.pid);
//console.log("process.argv.shift:"+process.argv.shift());
console.log("process.cwd:"+process.cwd());
console.log("process.argv:"+process.argv);
// setTimeout(function () {
//     process.on("exit", function () {
//         require("child_process").spawn(process.argv.shift(), process.argv, {
//             cwd: process.cwd(),
//             detached : true,
//         });
//     });
//     process.exit();
// }, 60000);


 //end input