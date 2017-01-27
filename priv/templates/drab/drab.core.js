Drab.on_connect(function(resp, drab) {
  // prevent reassigning messages
  if (!drab.already_connected) {
    drab.channel.on("onload", (message) => {
      // reply from onload is not expected
    })

    // exec is synchronous, returns the result
    drab.channel.on("execjs", (message) => {
      let query_output = [
        message.sender,
        eval(message.js)
      ]
      drab.channel.push("execjs", {ok: query_output})
    })

    // broadcast does not return a meesage
    drab.channel.on("broadcastjs", (message) => {
      eval(message.js)
    })

    // console.log
    drab.channel.on("console", (message) => {
      console.log(message.log)
    })
  }

  // initialize onload on server side, just once
  if (!drab.onload_launched) {
    drab.channel.push("onload", { drab_session_token: Drab.drab_session_token })
    drab.onload_launched = true
  }

  // launch server-side onconnect callback - every time it is connected
  drab.channel.push("onconnect", { drab_session_token: Drab.drab_session_token })
})
