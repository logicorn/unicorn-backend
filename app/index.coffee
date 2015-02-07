craneSpeedController = require './crane-speed-controller'

app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(process.env.PORT)

app.get '/', (req, res) ->
  res.sendFile "#{__dirname}/static/test.html"

io.on 'connection', (socket) ->
  crane = craneSpeedController()
  console.log "Connected to controller over websocket"

  socket.on "hello", ->
    console.log "Got controller handshake"
    socket.emit "connected", {}

  socket.on "disconnect", ->
    console.log "Lost connection to controller"
    crane.disconnect()

  socket.on "stop", ->
    console.log "Emergency stop!"
    crane.stop()

  socket.on "speed", ({ a, e, h }) ->
    crane.setSpeed { a, e, h }
