debug = require('debug')('crane:control')
Bacon = require 'baconjs'
openCraneSocket = require './open-crane-socket'

###
Creates a continuous output signal for the crane from individual speed change events

craneControlBox :: () -> {
  in: Bus { a, e, h }
  out: Stream { a, e, h }
}
###
craneControlBox = ->
  neutral = { a: 0, e: 0, h: 0 }
  incomingSpeed = new Bacon.Bus
  currentSpeed = incomingSpeed
    .toProperty(neutral)
    .filter((axes) -> axes.a? and axes.e? and axes.h?)

  activeStatus = currentSpeed.map((axes) ->
    !(axes.a is axes.e is axes.h is 0)
  ).skipDuplicates()

  speedUpdateToSend = activeStatus.flatMapLatest (active) ->
    if active
      debug "Controls active: sampling current input"
      currentSpeed.sample(1000)
    else
      debug "Controls inactive"
      Bacon.once neutral

  {
    in: incomingSpeed
    out: speedUpdateToSend.map(craneSpeedMessage)
  }

###
craneSpeedMessage :: (a: hoist, e: trolley, h: bridge) -> String
###
craneSpeedMessage = do ->
  curtail = (v) -> ~~Math.max(-255, Math.min(255, v))
  ({ a, e, h }) ->
    "T;#{curtail a};#{curtail e};#{curtail h};"

###
craneSpeedController :: () -> { setSpeed, stop, disconnect }
###
module.exports = ->
  socket = openCraneSocket()
  control = craneControlBox()
  stopSendingUpdates = control.out.onValue socket.send

  disconnect = ->
    stopSendingUpdates()
    socket.close()

  setSpeed = (axes) ->
    debug axes
    control.in.push axes

  stop = ->
    socket.send craneSpeedMessage { a: 0, e: 0, h: 0 }
    disconnect()

  return {
    setSpeed
    disconnect
    stop
  }
