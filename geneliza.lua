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
-- Unfinished exploratory code to parse Eliza-script.txt.  Use at your
-- own risk.
-- 
-- ********************************************************************

local lpeg = require "lpeg"



local SP          = (P" " + P"\t")^1
local H,CMD do
  local pattern = Cf((
        R("AZ","az") / function(c) return P(c:lower()) + P(c:upper()) end
      + P(1)         / function(c) return P(c) end
    )^0
    , function(a,b) return a * b end
  )
  
  H = function(text)
    return pattern:match(text)
  end
  
  CMD = function(text)
    return SP^-1 * pattern:match(text) * SP
  end
end

local END_OF_LINE = P"\n"
local word        = C(R"!~"^1)
local words       = Cs((SP / " " + C(R"!~"))^1)

local initial = (H"initial:" * SP * words * END_OF_LINE * Carg(1))
              / function(data,acc)
                  acc.initial = data
                end

local final = (CMD"final:" * words * END_OF_LINE * Carg(1))
            / function(data,acc)
                acc.final = data
              end

local quit = (CMD"quit:" * word * END_OF_LINE * Carg(1))
           / function(bye,acc)
               acc.quit = acc.quit + H(bye) / bye
             end

local pre = (CMD"pre:" * word * SP * words * END_OF_LINE * Carg(1))
          / function(src,target,acc)
              acc.pre = acc.pre + H(src) / target
            end

local post = (CMD"post:" * word * SP * words * END_OF_LINE * Carg(1))
           / function(src,target,acc)
               acc.post = acc.post + H(src) / target
             end

local synon = (CMD"synon:" * word * Ct((SP * word)^1) * END_OF_LINE * Carg(1))
            / function(word,list,acc)
                acc.synonym[word] = P(false)
                for _,syn in ipairs(list) do
                  acc.synonnym[word] = acc.synonym[word] + H(syn)
                end
              end

local reasmb do
  
  -- Whether or not you can (2) depends on you more than me.
  -- { "Whether or not you can " , 2 , " depends on you more than me." }
  --
  -- What other reasons might there be ?
  -- { "What other reasons might there be?" }
  --
  
  local paren  = P"(" * (R"09"^1 / tonumber) * P")"
               + P"(" * C(R(" '","*/",":~") * R(" '","*~")^0) * P")"
  local text   = C(R(" '","*~")^0)
  local goto   = P"goto" * SP * word
  local phrase = Ct((" ?" / "?" + number + text)^1)
  
  reasbm       = (CMD"reasmb:" * (goto + phrase) * END_OF_LINE * Carg(1))
               / function(choice,acc)
                   if type(choice) == 'table' then
                   else
                   end
                 end
end

local decomp do
  local save = (P"$" * Carg(1))
             / function(acc)
                 acc.save = true
               end
  local all  = P"*" 
             / function() 
                 return P(1)^0
               end
  local text = R(" )","+~")^0 
             / function(c)
                 return -P(c) * P(c)
               end  
  local breakdown = save^-1 * (all + text)^1
  
  decomp = (CMD"decomp:" * breakdown * END_OF_LINE * Carg(1))
end
