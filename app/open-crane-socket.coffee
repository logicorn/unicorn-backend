dgram = require 'dgram'
Promise = require 'bluebird'

###
Open a socket connection to the crane

openCraneSocket :: () -> { send, close }
###
module.exports = ->
  socket = dgram.createSocket 'udp4'

  # Send a crane control message
  # (message: String) -> Promise
  send = (message) ->
    new Promise (resolve, reject) ->
      envelope = new Buffer message
      socket.send envelope, 0, envelope.length, process.env.CRANE_PORT, process.env.CRANE_IP, (err) ->
        if err?
          reject new Error "UDP message send failure: #{err}"
        else
          resolve()

  close = ->
    socket.close()

  {
    send, close
  }