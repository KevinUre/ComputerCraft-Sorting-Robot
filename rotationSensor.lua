rednet.open("right")
compass = peripheral.wrap("left")

function mainLoop()
  while true do
    --e,s,f,rf,msg,d = os.pullEvent("modem_message")
    sid, msg = rednet.receive()
    print (os.time()..">received message: "..msg)
    if msg == "turnLeft" then
      turtle.turnLeft()
      rednet.send(sid,compass.getFacing())
    elseif msg == "turnRight" then
      turtle.turnRight()
      rednet.send(sid,compass.getFacing())
    elseif msg == "getFacing" then
      rednet.send(sid,compass.getFacing())
    end
  end
end

mainLoop()