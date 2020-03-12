myFacing=0
isTools=false

rednet.open("right")
dbID = 16 --RednetAPI
analyzer = peripheral.wrap("left")

function doWork()
  --find chest size =27
  --add chest to db, getting ID back
  wlog("pinging GPS")
  Cx,Cy,Cz = gps.locate()
  wlog("Location: "..tostring(Cx)..","..tostring(Cy)..","..tostring(Cz))
  chestLoc = {x=Cx,y=Cy,z=Cz,f=myFacing}
  chestmsg = "addChest;"..textutils.serialize(chestLoc)
  cid = rednetCom(chestmsg)
  wlog("Chest ID: "..cid)
  for i=1,27,1 do
    iid = analyzer.getBlockIdAt(i)
    if iid ~= "error_no_item" then
      imeta = analyzer.getBlockMetadataAt(i)
      if isTools then
        imeta = "X"
      end
      temp = tostring(iid)..":"..tostring(imeta)
      wlog("Item at "..tostring(i).." is "..temp)
      json = {ID=temp,Chest=cid}
      msg = "addItem;"..textutils.serialize(json)
      suc = rednetCom(msg)
      wlog("response from Database: "..tostring(suc))
    end
  end
end

function wlog(msg)
  print(msg)
  logfile.writeLine(msg)
end

function rednetCom(msg)
  wlog("sending "..msg.." to "..dbID)
  while true do
    rednet.send(dbID,msg)
    sid, msg2 = rednet.receive(1)
    if sid == dbID then
      return msg2, true
    end
    wlog("retrying...")
  end
  return nil, false
end

shell.run("delete log")
logfile = fs.open("log","w")
doWork()
logfile.close()
