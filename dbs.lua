itemDBLoc = "disk/items"
chestDBLoc = "disk/chests"
modemSide = "left"
findKeyword = "lookup"
addItemKeyword = "addItem"
addChestKeyword = "addChest"
--USE: keyword;data
  --lookup;blockID:Meta returns location table as string, dont worry about tools
  --addItem;table returns bool
  --addChest;location returns ID as string

function mainLoop()
  while true do
    sid, msg = rednet.receive()
    wlog("---Received "..msg.."from "..sid.."---")
    substrs = split(msg,";")
    wlog(textutils.serialize(substrs))
    if substrs[1] == findKeyword then
      wlog("performing Lookup on "..substrs[2])
      cid = getChestfromItemID(substrs[2])
      if cid == nil then
        wlog(substrs[2].." not found")
        rednet.send(sid,nil)
        print(os.time().."> Lookup Served (not found)")
      else
        loc = getLocationfromChestID(cid)
        wlog(substrs[2].." found in "..cid)
        rednet.send(sid,textutils.serialize(loc))
        print(os.time().."> Lookup Served")
      end
    elseif split(msg,";")[1] == addItemKeyword then
      wlog("performing AddItem on "..substrs[2])
      tempItem = textutils.unserialize(substrs[2])
      exists = getChestfromItemID(tempItem.ID)
      wlog("###"..tempItem.ID.." exists? "..tostring(exists))
      if exists ~= nil or exists == (-1) then
        wlog("Item exists")
        rednet.send(sid,false)
        print(os.time().."> Add Item Rejected")
      else
        addItem(tempItem)
        wlog("Item added")
        rednet.send(sid,true)
        print(os.time().."> Add Item Served")
      end
    elseif substrs[1] == addChestKeyword then
      wlog("performing AddChest on "..substrs[2])
      temploc = textutils.unserialize(substrs[2])
      res, ID = findChest(temploc)
      if res then
        wlog("chest already exists: "..tostring(ID))
        rednet.send(sid,ID)
        print(os.time().."> Add Chest Rejected")
      else
        ID = addChest(temploc)
        wlog("chest created with ID: "..tostring(ID))
        rednet.send(sid,ID)
        print(os.time().."> Add Chest Served")
      end
    end
  end
end

function addItem(item)
  wlog("writing new line")
  wlog(textutils.serialize(item))
  file = fs.open(itemDBLoc,"a")
  file.writeLine(textutils.serialize(item))
  file.close()
end

function addChest(loc)
  wlog("iterating existing chests")
  file = fs.open(chestDBLoc,"r")
  nextNum = 1
  while true do
    line = file.readLine()
    if line == nil or line:len() == 0 then
      break
    end
    nextNum = nextNum + 1
  end
  file.close()
  wlog("generating JSON for new chest with ID: "..nextNum)
  newchest = {ID=nextNum,Location=loc}
  wlog("writing new chest to DB")
  file = fs.open(chestDBLoc,"a")
  file.writeLine(textutils.serialize(newchest))
  file.close()
  return nextNum
end

function findChest(loc)
  found = false
  cid = nil
  file = fs.open(chestDBLoc,"r")
  wlog("iterating chests for cid")
  while true do
    line = file.readLine()
    if line == nil or line:len() == 0 then
      break
    end
    temp = textutils.unserialize(line)
    if temp.Location.x == loc.x and temp.Location.y == loc.y and temp.Location.z == loc.z and temp.Location.z == loc.z then
      cid = temp.ID
      found = true
      break
    end
  end
  file.close()
  wlog("Chest found?: "..tostring(found))
  return found, cid
end

function getLocationfromChestID(cid)
  loc = nil
  wlog("iterating chests for location")
  wlog("Looking for: "..tostring(cid))
  file = fs.open(chestDBLoc,"r")
	while true do
    line = file.readLine()
    wlog("Line: "..tostring(line))
    if line == nil or line:len() == 0 then
      wlog("line was nil")
      break
    end
    temp = textutils.unserialize(line)
    if tostring(temp.ID) == cid then
      wlog("chest found with ID: "..tostring(cid))
      loc = temp.Location
      break
    end
  end
  file.close()
  if loc == nil then
    wlog("chest NOT found with ID: "..tostring(cid))
  end
  wlog(textutils.serialize(loc))
  return loc
end

function getChestfromItemID(iid)
  chest = nil
  bType = "block"
  wlog("iterating items for cid")
  file = fs.open(itemDBLoc,"r")
  while true do
    line = file.readLine()
    wlog("Line: "..tostring(line))
    if line == nil or line:len() == 0 then
      wlog("line was nil")
      break
    end
    --wlog("line not nil")
    temp = textutils.unserialize(line)
    tempid = temp.ID
    if (split(tempid,":")[2] == "X") then
      bType = "tool"
    end
    if bType == "tool" then
      if split(tempid,":")[1] == split(iid,":")[1] then
        wlog("item "..tostring(iid).." as "..tostring(tempid).." in "..tostring(temp.Chest))
        chest = tostring(temp.Chest)
        break
      end
    else 
      if tempid == iid then
        wlog("item "..tostring(iid).." as "..tostring(tempid).." in "..tostring(temp.Chest))
        chest = tostring(temp.Chest)
        break
      end
    end
  end --while loop
  file.close()
  wlog("###chest: "..tostring(chest))
  return chest
end

function split(str, delim)
  --wlog("  split called")
  --wlog("    str: "..tostring(str))
  --wlog("    delim: "..tostring(delim))
  pattern = "(.+)"..delim.."(.+)"
  return {str:match(pattern)}
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
shell.run("delete log")
rednet.open(modemSide)
mainLoop()
--ITEM
  --Name=string
  --Chest=CID
  --ID=string (ID:Meta)
--Chest
  --ID=CID
  --Location
    --X
    --Y
    --Z
    --F
