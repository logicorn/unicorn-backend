dgram = require 'dgram'

app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(process.env.PORT)

app.get '/', (req, res) ->
  res.sendFile "#{__dirname}/static/test.html"

connectCrane = ->
  socket = dgram.createSocket 'udp4'

  send: (message) ->
    console.log "Crane control message: #{message}"
    envelope = new Buffer message
    socket.send envelope, 0, envelope.length, process.env.CRANE_PORT, process.env.CRANE_IP, (err) ->
      if err?
        console.log "Error when sending message: #{err}"
        socket.close()

  close: ->
    socket.close()

# (hoist, trolley, bridge) -> string
craneSpeedMessage = do ->
  curtail = (v) -> Math.max(-255, Math.min(255, v))
  (a, e, h) ->
    "T;#{curtail a};#{curtail e};#{curtail h};"

goSlowMessage = (e, h) ->
  acual_e = e * 100
  acual_h = h * 100
  craneSpeedMessage 0, acual_e, acual_h

io.on 'connection', (socket) ->
  crane = connectCrane()
  console.log "Connected over socket"

  socket.on "hello", ->
    console.log "Got handshake"
    socket.emit "connected", {}

  socket.on "disconnect", ->
    console.log "Lost connection"

  socket.on "move", ({x, y}) ->
    crane.send goSlowMessage x, y
