dgram = require 'dgram'

app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(process.env.PORT)

app.get '/', (req, res) ->
  res.sendFile "#{__dirname}/static/test.html"

connectCrane = ->
  socket = dgram.createSocket 'udp4'

  # (string) -> Promise
  send: (message) ->
    new Promise (resolve, reject) ->
      envelope = new Buffer message
      socket.send envelope, 0, envelope.length, process.env.CRANE_PORT, process.env.CRANE_IP, (err) ->
        if err?
          reject new Error "UDP message send failure: #{err}"
        else
          resolve()

  disconnect: ->
    socket.close()

# (a: hoist, e: trolley, h: bridge) -> string
craneSpeedMessage = do ->
  curtail = (v) -> Math.max(-255, Math.min(255, v))
  ({ a, e, h }) ->
    "T;#{curtail a};#{curtail e};#{curtail h};"

goSlowMessage = (e, h) ->
  craneSpeedMessage {
    a: 0
    e: e*100
    h: h*100
  }

io.on 'connection', (socket) ->
  crane = connectCrane()
  console.log "Connected to controller over websocket"

  socket.on "hello", ->
    console.log "Got controller handshake"
    socket.emit "connected", {}

  socket.on "disconnect", ->
    console.log "Lost connection to controller"
    crane.disconnect()

  socket.on "stop", ->
    console.log "Emergency stop!"
    crane.send { a: 0, e: 0, h: 0 }
    crane.disconnect()

  socket.on "speed", ({ a, e, h }) ->
    crane.send craneSpeedMessage { a, e, h }
