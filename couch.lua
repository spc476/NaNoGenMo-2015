#!/usr/bin/env lua

local errno   = require "org.conman.errno"
local fsys    = require "org.conman.fsys"
local process = require "org.conman.process"
local signal  = require "org.conman.signal"
local dump    = require "org.conman.table".dump

signal.catch('int')  
signal.catch('child')
fsys.chdir("/tmp/racter")
io.open("IV.C","w"):close()

etor = fsys.pipe(true)
rtoe = fsys.pipe(true)

elizaid = process.fork()
if elizaid == 0 then
  fsys.dup(rtoe.read,fsys.STDIN)
  fsys.dup(etor.write,fsys.STDOUT)
  
  etor.read:close()
  etor.write:close()
  rtoe.read:close()
  rtoe.write:close()

  process.exec("/usr/local/bin/lua",
    { "/home/spc/writings/nanogenmo/2015/eliza.lua" }
  )
  process.exit(1)
else
  print("ELIZA",elizaid)
end

racterid = process.fork()
if racterid == 0 then
  fsys.dup(etor.read,fsys.STDIN)
  fsys.dup(rtoe.write,fsys.STDOUT)
  
  etor.read:close()
  etor.write:close()
  rtoe.read:close()
  rtoe.write:close()
  
  process.exec("/home/spc/writings/nanogenmo/2015/C/msdos",{ "RACTER.EXE" })
  process.exit(1)
else
  print("RACTER",racterid)
end

while true do
  process.pause()
  if signal.caught('int') then
    break
  end
  
  if signal.caught('child') then
    local info,err = process.wait()
    dump("info",info)
    if info.pid == racterid then
      signal.raise('term',elizaid)
    else
      signal.raise('term',racterid)
    end
    info,err = process.wait()
    dump("info",info)
    os.exit()
  end
end  

signal.raise('term',racterid)
info,err = process.wait()
dump("info",info)
signal.raise('term',elizaid)
info,err = process.wait()
dump("info",info)
