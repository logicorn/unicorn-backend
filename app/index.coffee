app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)

server.listen(process.env.PORT)

app.get '/', (req, res) ->
  res.sendFile "#{__dirname}/static/test.html"

io.on 'connection', (socket) ->
  socket.emit 'yo', hello: 'doge'

  socket.on "ping", (data) ->
    console.log "pong", data
