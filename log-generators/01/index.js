var fs = require('fs');
var obj = JSON.parse(fs.readFileSync('config.json', 'utf8'));

const log4js = require("log4js");

log4js.configure({
  appenders: { console: { type: "console" } },
  categories: { default: { appenders: ["console"], level: "info" } },
});

var logger = log4js.getLogger();

// Sleep for a specified number of milliseconds
function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

// Log our messages
function logMessage(process, msg) {
  let json = {
    user: obj.user,
    role: obj.role,
    process: process,
    message: msg 
  };
  
  logger.info(JSON.stringify(json));
}

async function start() {
  // If there is a wait to login the first time
  if (obj.firstLoginInterval !== undefined) {
    await sleep((obj.minFirstLoginInterval !== undefined) ? (obj.minFirstLoginInterval + Math.random() * obj.firstLoginInterval) :
                                                            (Math.random() * obj.firstLoginInterval));
  }
  logMessage("login");
  obj.loggedIn = true;    // Set logged in to true

  
  // Run non-stop
  while (true) {
    // Wait to run our commands
    await sleep((obj.minInterval !== undefined) ? (obj.minInterval + Math.random() * obj.interval) :
                                                  (Math.random() * obj.interval));
    
    // If the User isn't logged in then deal with that
    // If we have a defined probablity of Logging in, then go ahead and check to see if they log back in
    if (!obj.loggedIn && ((obj.loginOdds !== undefined && obj.loginOdds > Math.random()) || 
                          obj.loginOdds === undefined)){
      logMessage('login');
    
      // If this user is defined as being able to logout, then do that
    } else if (obj.logoutOdds !== undefined && obj.loginOdds > Math.random()) {
      // Check to see if we have any processes still running before logging out (I'm pretty sure this will break the graph)
      for (let i=0; i < obj.process.length; i++) {
        let p = obj.process[i];
        if (obj[p].started === true){
          obj[p].started = false;
          logMessage(p, obj[p].started ? 'Start': 'Stop');
          
          // Wait the minimum time and then keep killing processes
          await sleep((obj.minInterval !== undefined) ? (obj.minInterval + Math.random() * obj.interval) :
                                                        (Math.random() * obj.interval));
        }
      }
      
      obj.loggedIn = false;
      logMessage('logout')
        
      // Our or else process messages
    } else { 
      let n = Math.floor(obj.process.length * Math.random());
      let p = obj.process[n]
      
      
      if (!obj[p].started){
        obj[p].started = true;
      } else {
        obj[p].started = false;
      }
      
      logMessage(p, obj[p].started ? 'Start': 'Stop');
    }
  }
}


// Before we start our application, create all of our process (if they don't already exist)
for (let i = 0; i < obj.process.length; i++) {
  if (obj[obj.process[i]] === undefined)
    obj[obj.process[i]] = {};
  obj[obj.process[i]].started = false;
}


start();