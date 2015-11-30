#!/usr/bin/env lua
-- ***************************************************************
--
-- Copyright 2015 by Sean Conner.  All Rights Reserved.
-- 
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or (at your
-- option) any later version.
-- 
-- This library is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
-- License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with this library; if not, see <http://www.gnu.org/licenses/>.
--
-- Comments, questions and criticisms can be sent to: sean@conman.org
--
-- ====================================================================
--
-- This program runs both Eliza and Racter.  You'll need to install the
-- packages from https://github.com/spc476/lua-conmanorg to run this.
--
-- There may be other things you need to change to run this successfully.
--
-- You have been warned.
--
-- ********************************************************************
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
