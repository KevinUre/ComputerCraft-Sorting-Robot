chargeLoc = {x=186,y=37,z=186,f=1}
pickupLoc = {x=189,y=36,z=187,f=3}
miscLoc = {x=171,y=34,z=187,f=1}
flightLevel = 36
rotsenID = 18 --RednetAPI
dbID = 16 --RednetAPI
dbchnl = 1491 --ModemAPI
retchnl = 1480 --ModemAPI
rotsenchnl = 1492 --ModemAPI
outchnl = 1493 --ModemAPI
maxFuel = 1000
minFuel = 100

function rednetCom(pid, msg)
  wlog("sending "..msg.." to "..pid)
  while true do
    rednet.send(pid,msg)
    sid, msg2 = rednet.receive(1)
    if sid == pid then
      return msg2, true
    end
    wlog("retrying...")
  end
  return nil, false
end

function changeFacing(newHeading)
  wlog("changing heading to: "..tostring(newHeading))
  --modem.transmit(rotsenchnl,retchnl,"getFacing") --ModemAPI
  --local e,s,f,rf,msg,d = os.pullEvent("modem_message") --ModemAPI
  msg = rednetCom(rotsenID,"getFacing") --RednetAPI
  local oldHead = tonumber(msg)
  local newHead = tonumber(newHeading)
  local res = oldHead - newHead
  local curHead = oldHead
  local direction = "turnRight"
  if res == 1 or res == (-3) or res == (-2) then
    direction = "turnLeft"
  end
  while curHead ~= newHead do
    --modem.transmit(rotsenchnl,retchnl,direction) --ModemAPI
    --e,s,f,rf,msg,d = os.pullEvent("modem_message") --ModemAPI
    msg = rednetCom(rotsenID,direction) --RednetAPI
    local act = true
    if tonumber(msg) == curHead then
      act = false
    end
    if direction == "turnRight" and act then
      turtle.turnRight()
    elseif act then
      turtle.turnLeft()
    end
    curHead = tonumber(msg)
  end
end

function moveToLocation(dest)
  wlog("Beging moving:"..textutils.serialize(dest))
  local Cx,Cy,Cz = gps.locate()
  --stay still if already there
  if Cx == dest.x and Cy == dest.y and Cz == dest.z then
    return
  end
  -- goto flight level
  wlog("go to altitude")
  if Cy < flightLevel then
    while Cy < flightLevel do
      if turtle.up() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  elseif Cy > flightLevel then
    while Cy > flightLevel do
      if turtle.down() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  end
  -- Move X
  wlog("Move E/W")
  if dest.x < Cx then
    changeFacing(1)
  elseif dest.x > Cx then
    changeFacing(3)
  end
  if dest.x ~= Cx then
    while dest.x ~= Cx do
      if turtle.forward() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  end
  -- Move Z
  wlog("Move N/S")
  if dest.z < Cz then
    changeFacing(2)
  elseif dest.z > Cz then
    changeFacing(0)
  end
  if dest.z ~= Cz then
    while dest.z ~= Cz do
      if turtle.forward() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  end
  --goto final Y
  wlog("go to final altitude")
  if Cy < dest.y then
    while Cy < dest.y do
      if turtle.up() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  elseif Cy > dest.y then
    while Cy > dest.y do
      if turtle.down() then
        Cx,Cy,Cz = gps.locate()
      end
    end
  end
  --achieve final facing
  changeFacing(dest.f)
  --you have arrived
  wlog("arrived at destnation")
end

function travelDistance(p1, p2)
  local dist = math.abs(p1.x-p2.x)
  dist = dist + math.abs(p1.z-p2.z)
  dist = dist + math.abs(p1.y - flightLevel)
  dist = dist + math.abs(p2.y - flightLevel)
  return dist
end

function deliverItem()
  wlog("beginning delivery")
  local iid = getItemID()
  local dest = getItemLocation(iid)
  if dest.y == (-1) then
    return false
  end
  moveToLocation(dest)
  return turtle.drop()
end

function restockInventory()
  wlog("restocking")
  turtle.select(1)
  for i=1,16,1 do
    if not turtle.suck() then
      break
    end
  end
  turtle.select(1)
  if not checkInventory() then
    return false
  end
  return true
end

function checkInventory()
  wlog("checking Inventory for next item")
  for i=1,16,1 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      return true
    end
  end
  wlog("no items in inventory")
  return false
end

function getItemLocation(item)
  wlog("getting location for "..tostring(item))
  --local temp = {x=175,y=34,z=188,f=0}
  tempstr = "lookup;"..tostring(item)
  wlog("  message to be sent: "..tempstr)
  msg = rednetCom(dbID,tempstr) --rednetAPI
  if msg == nil then
    wlog("chest not found, returning misc")
    return miscLoc
  else
    return textutils.unserialize(msg)
  end
end

function getItemID()
  wlog("getting selected block id")
  local temp = analyzer.getBlockId()
  temp = temp..":"..analyzer.getBlockMetadata()
  return temp
end

function mainLoop()
  wlog("beginning work")
  while true do
    if turtle.getFuelLevel() < minFuel then
      wlog("refueling")
      moveToLocation(chargeLoc)
      while turtle.getFuelLevel() < maxFuel do
        wlog("Fuel Level: "..tostring(turtle.getFuelLevel()))
        os.sleep(5)
      end
    elseif checkInventory() then
      wlog("beginning delivery run")
      if not deliverItem() then
        wlog("Chest Full")
        break
      end
    else
      wlog("moving to restock")
      moveToLocation(pickupLoc)
      if not restockInventory() then
        wlog("no items to process")
        sleep(5)
      end
    end
  end
end

function wlog(msg)
  if logging then
    print(msg)
    logfile = fs.open("log","a")
    logfile.writeLine(msg)
    logfile.close()
  end
end

logging = false
args={...}
for k,v in ipairs(args) do
  logging=true
  break
end

--modem = peripheral.wrap("right") --ModemAPI
--modem.open(retchnl) --ModemAPI
rednet.open("right") --RednetAPI
analyzer = peripheral.wrap("left")
mainLoop()
