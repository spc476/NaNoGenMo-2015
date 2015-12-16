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

local syslog  = require "org.conman.syslog"
local errno   = require "org.conman.errno"
local fsys    = require "org.conman.fsys"
local process = require "org.conman.process"
local signal  = require "org.conman.signal"
local dump    = require "org.conman.table".dump

-- ********************************************************************

local readracter
do
  local lpeg = require "lpeg"
  local Cs   = lpeg.Cs
  local C    = lpeg.C
  local S    = lpeg.S
  
  local cleanup = Cs((S" \t\r\n"^1 / " " + C(1))^0)
  
  readracter = function(fpin,input)
    local c,err = fpin:read(1)
    if c == '>' then
      return cleanup:match(input)
    elseif c then
      return readracter(fpin,input .. c)
    elseif not c then
      error(err)
    end
  end
end

-- ********************************************************************

local racterid
local elizaid

local function wait_racter()
  local info,err = process.wait(racterid)
  dump("racter",info)
end

local function wait_eliza()
  local info,err = process.wait(elizaid)
  dump("eliza",info)
end

local function stop_racter()
  signal.raise('terminate',racterid)
  wait_racter()
end

local function stop_eliza()
  signal.raise('terminate',elizaid)
  wait_eliza()
end

-- ********************************************************************

signal.ignore('pipe')

signal.catch('int',function()
  stop_racter()
  stop_eliza()
  os.exit(1)
end)

signal.catch('child',function()
  local info,err = process.wait()
  dump("info",info)
  if info.pid == racterid then
    stop_eliza()
  else
    stop_racter()
  end
  os.exit(1)
end)

local to_racter   = fsys.pipe(true)
local from_racter = fsys.pipe(true)

to_racter.read:setvbuf('no')
to_racter.write:setvbuf('no')
from_racter.read:setvbuf('no')
from_racter.write:setvbuf('no')

local to_eliza = fsys.pipe(true)
local from_eliza = fsys.pipe(true)

to_eliza.read:setvbuf('no')
to_eliza.write:setvbuf('no')
from_eliza.read:setvbuf('no')
from_eliza.write:setvbuf('no')

racterid = process.fork()
if racterid == 0 then
  signal.default('int')
  signal.default('child')
  fsys.chdir("/tmp/racter")
  io.open("IV.C","w"):close()
  local stdout = io.open("/tmp/racter.stderr","w")
  
  fsys.dup(to_racter.read,fsys.STDIN)
  fsys.dup(from_racter.write,fsys.STDOUT)
  fsys.dup(stdout,fsys.STDERR)
  
  stdout:close()
  to_racter.read:close()
  to_racter.write:close()
  from_racter.read:close()
  from_racter.write:close()
  
  to_eliza.read:close()
  to_eliza.write:close()
  from_eliza.read:close()
  from_eliza.write:close()
  
  process.exec("/home/spc/writings/nanogenmo/2015/C/msdos",{ "RACTER.EXE" })
  process.exit(1)
else
  print("RACTER",racterid)
end

elizaid = process.fork()
if elizaid == 0 then
  signal.default('int')
  signal.default('child')
  fsys.dup(to_eliza.read,fsys.STDIN)
  fsys.dup(from_eliza.write,fsys.STDOUT)

  to_racter.read:close()
  to_racter.write:close()
  from_racter.read:close()
  from_racter.write:close()
  
  to_eliza.read:close()
  to_eliza.write:close()
  from_eliza.read:close()
  from_eliza.write:close()
  
  process.exec("/usr/local/bin/lua",{ "eliza.lua" })
  process.exit(1)
else
  print("ELIZA",elizaid)
end

local racter_talk = readracter(from_racter.read,"")
local eliza_talk

io.stdout:write(">>",racter_talk,"\n")
to_racter.write:write("Eliza\n")
racter_talk = readracter(from_racter.read,"")
racter_talk = racter_talk:sub(6,-1)
io.stdout:write(">>",racter_talk,"\n")

function mainloop()
  local eliza_talk = from_eliza.read:read("*l")
  io.stdout:write("<<",eliza_talk,"\n")
  
  to_racter.write:write(eliza_talk .. "\n")
  racter_talk = readracter(from_racter.read,"")
  if racter_talk == "" then return 'what' end
  racter_talk = racter_talk:sub(#eliza_talk + 1,-1)
  io.stdout:write(">>",racter_talk,"\n")
  to_eliza.write:write(racter_talk,"\n")
  return mainloop()
end

okay,why = pcall(mainloop)
print("]",okay,why)
stop_racter()
stop_eliza()
