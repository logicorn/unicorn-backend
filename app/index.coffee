dgram = require 'dgram'

app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(process.env.PORT)

app.get '/', (req, res) ->
  res.sendFile "#{__dirname}/static/test.html"

connectCrane = ->
  socket = dgram.createSocket 'udp4'
  socket.setBroadcast true

  send: (message) ->
    console.log "Crane control message: #{message}"
    socket.send(message, 0, message.length, process.env.CRANE_PORT, process.env.CRANE_IP)

# (hoist, trolley, bridge) -> string
craneSpeedMessage = (a, e, h) ->
  "T;#{a};#{e};#{h}"

goSlowMessage = (e, h) ->
  acual_e = e * 20
  acual_h = h * 20
  craneSpeedMessage 0, acual_e, acual_h

io.on 'connection', (socket) ->
  crane = null
  console.log "Connected over socket"

  socket.on "hello", ->
    crane = connectCrane()
    console.log "Got handshake"
    socket.emit "connected", {}

  socket.on "disconnect", ->
    console.log "Lost connection"

  socket.on "move", ({x, y}) ->
    crane.send goSlowMessage x, y
