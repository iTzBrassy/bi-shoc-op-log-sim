var fs = require('fs');
var obj = JSON.parse(fs.readFileSync('config.json', 'utf8'));

// Sleep for a specified number of milliseconds
function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

// Log our messages
function logMessage(process, msg) {
  if (msg !== undefined)
    console.error('[' + obj.user + '][' + obj.role + '][' + process + '] ' + msg);
  else
    console.error('[' + obj.user + '][' + obj.role + '][' + process + ']');
}

async function start() {
  // If there is a wait to login the first time
  if (obj.firstLoginInterval !== undefined) {
    await sleep(Math.random() * obj.firstLoginInterval);
  }
  logMessage("login(1)");
  obj.loggedIn = true;    // Set logged in to true

  
  // Run non-stop
  while (true) {
    // Wait to run our commands
    await sleep(Math.random() * obj.interval);

    console.log(" ------------- Looping -----------------");
    
    // If the User isn't logged in then deal with that
    // If we have a defined probablity of Logging in, then go ahead and check to see if they log back in
    if (!obj.loggedIn && ((obj.loginOdds !== undefined && obj.loginOdds > Math.random()) || 
                          obj.loginOdds === undefined)){
      logMessage('login');
    
      // If this user is defined as being able to logout, then do that
    } else if (obj.logoutOdds !== undefined && obj.loginOdds > Math.random()) { 
      obj.loggedIn = false;
      logMessage('logout')
    
      // Our or else process messages
    } else { 
      let n = Math.floor(obj.process.length * Math.random());
      let p = obj.process[n]
      
console.log(p + ": obj." + p + " === " + obj.p);
      
      if (!obj[p].started){
        obj[p].started = true;
      } else {
        obj[p].started = false;
      }
      
      logMessage(p, obj[p].started);
    }
  }
}

// Before we start our application, create all of our process (if they don't already exist)
for (let i = 0; i++; i < obj.process.length) {
  if (obj[obj.process[i]] === undefined)
    obj[obj.process[i]] = {};
  obj[obj.process[i]].started = false;
}
  

start();