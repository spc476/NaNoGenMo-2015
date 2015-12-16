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
-- ********************************************************************

             require "org.conman.math".randomseed()
local lpeg = require "lpeg"
local Cf   = lpeg.Cf
local Cc   = lpeg.Cc
local Cp   = lpeg.Cp
local Cs   = lpeg.Cs
local C    = lpeg.C 
local P    = lpeg.P
local R    = lpeg.R
local S    = lpeg.S

-- *************************************************************************

local keyword_reply =
{
  ["can you"] =
  {
    "Don't you believe that i can*",
    "Perhaps you would like me to be able to*",
    "You want me to be able to*",
  },

  ["can i"] =
  {
    "Perhaps you don't want to*",
    "Do you want to be able to*",
  },

  ["you are"] =
  {
    "What makes you think i am*",
    "Does it please you believe i am *",
    "Perhaps you would like to be*",
    "Do you sometimes wish you were*",
  },

  ["you're"] =
  {
    "What makes you think i am*",
    "Does it please you believe i am *",
    "Perhaps you would like to be*",
    "Do you sometimes wish you were*",
  },

  ["i don't"] =
  {
    "Don't you really*",
    "Why don't you*",
    "Do you wish to be able to*",
    "Does that trouble you?",
  },

  ["i feel"] =
  {
    "Tell me more about such feelings.",
    "Do you often feel*",
    "Do you enjoy feeling*",
  },

  ["why don't you"] =
  {
    "Do you really believe i don't*",
    "Perhaps in good time i will*",
    "Do you want me to*",
  },

  ["why can't i"] =
  {
    "Do you think you should be able to*",
    "Why can't you*",
  },

  ["are you"] =
  {
    "Why are you interested in whether or not i am*",
    "Would you prefer if i were not*",
    "Perhaps in your fantasies i am*",
  },

  ["i can't"] =
  {
    "How do you know you can't*",
    "Have you tried?",
    "Perhaps you can now*",
  },

  ["i am"] =
  {
    "Did you come to me because you are*",
    "How long have you been*",
    "Do you believe it is normal to be*",
    "Do you enjoy being*",
  },

  ["i'm"] =
  {
    "Did you come to me because you are*",
    "How long have you been*",
    "Do you believe it is normal to be*",
    "Do you enjoy being*",
  },

  ["you"] =
  {
    "We were discussing you-- not me.",
    "Oh, i*",
    "You're not really talking about me, are you?",
  },

  ["i want"] =
  {
    "What would it mean to you if you got*",
    "Why do you want*",
    "Suppose you soon got*",
    "What if you never got*",
    "I sometimes also want*",
  },

  ["what"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["how"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["who"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["where"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["when"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["why"] =
  {
    "Why do you ask?",
    "Does that question interest you?",
    "What answer would please you the most?",
    "What do you think?",
    "Are such questions on your mind often?",
    "What is it that you really want to know?",
    "Have you asked anyone else?",
    "Have you asked such questions before?",
    "What else comes to mind when you ask that?",
  },

  ["name"] =
  {
    "Names don't interest me.",
    "I don't care about names-- please go on.",
  },

  ["cause"] =
  {
    "Is that the real reason?",
    "Don't any other reasons come to mind?",
    "Does that reason explain anything else?",
    "What other reasons might there be?",
  },

  ["sorry"] =
  {
    "Please don't apologize!",
    "Apologies are not necessary.",
    "What feelings do you have when you apologize.",
    "Don't be so defensive!",
  },

  ["dream"] =
  {
    "What does that dream suggest to you?",
    "Do you dream often?",
    "What persons appear in your dreams?",
    "Are you disturbed by your dreams?",
  },

  ["hello"] =
  {
    "How do you do ... please state your problem.",
  },

  ["hi"] =
  {
    "How do you do ... please state your problem.",
  },

  ["maybe"] =
  {
    "You don't seem quite certain.",
    "Why the uncertain tone?",
    "Can't you be more positive?",
    "You aren't sure?",
    "Don't you know?",
  },

  ["no"] =
  {
    "Are you saying no just to be negative?",
    "You are being a bit negative.",
    "Why not?",
    "Are you sure?",
    "Why no?",
  },

  ["your"] =
  {
    "Why are you concerned about my*",
    "What about your own*",
  },

  ["always"] =
  {
    "Can you think of a specific example?",
    "When?",
    "What are you thinking of?",
    "Really, always?",
  },

  ["think"] =
  {
    "Do you really think so?",
    "But you are not sure you*",
    "Do you doubt you*",
  },

  ["alike"] =
  {
    "In what way?",
    "What resemblance do you see?",
    "What does the similarity suggest to you?",
    "Can you think of a specific example?",
    "Could there really be some connection?",
    "How?",
    "You seem quite positive.",
  },

  ["yes"] =
  {
    "Are you sure?",
    "I see.",
    "I understand.",
  },

  ["friend"] =
  {
    "Why do you bring up the topic of friends?",
    "Do your friends worry you?",
    "Do your friends pick on you?",
    "Are you sure you have any friends?",
    "Do you impose on your friends?",
    "Perhaps your love for friends worries you.",
  },

  ["computer"] =
  {
    "Do computers worry you?",
    "Are you talking about me in particular?",
    "Are you frightened by machines?",
    "Why do you mention computers?",
    "What do you think machines have to do with your problem?",
    "Don't you think computers can help people?",
    "What is it about machines that worries you?",
  },

  [""] =
  {
    "Say, do you have any psychological problems?",
    "What does that suggest to you?",
    "I see.",
    "I'm not sure i understand you fully.",
    "Come come elucidate your thoughts.",
    "Can you elaborate on that?",
  },
}

-- ***********************************************************************

local nonalpha = R(" @","[`","{~")

local mkpattern,subpattern do
  local pattern = Cf(
	(
	    R("AZ","az") / function(c) return P(c:lower()) + P(c:upper()) end
	  + C(1)  / function(c) return P(c) end
	)^0
	, function(a,b) return a * b end
  )
  
  mkpattern = function(text)
    return pattern:match(text) / text
  end
  
  subpattern = function(text)
    return pattern:match(text) * nonalpha^-1
  end
end

local keyword = P(false)
for kw in pairs(keyword_reply) do
  if kw ~= "" then
    keyword = keyword + mkpattern(kw)
  end
end


local parse    = (P(1) - (keyword * nonalpha))^0 * keyword * C(P(1)^0) * Cp()
               + Cc("","") * Cp()

local conj = Cs((
	     subpattern " are"  / " am "
	   + subpattern " were" / " was "
	   + subpattern " you"  / " me "
	   + subpattern " your" / " my "
	   + subpattern " I've" / " you've "
	   + subpattern " I'm"  / " you're "
	   + subpattern " me"   / " you "
	   + subpattern " I"    / " you "	-- added spc
	   + (S".?!" * P(-1))   / ""		-- added spc, remove ending punctuation
	   + C(1)
	  )^1)

local trim = Cs((
		  S"\1\32"^1 / " "
		  + C(1)
		)^1)

io.stdin:setvbuf('no')
io.stdout:setvbuf('no')

print("What's your problem?")

for line in io.lines() do
  line = trim:match(line)
  local key,rest = parse:match(line)
  local answers  = keyword_reply[key]
  local answer   = answers[math.random(#answers)]
  
  if answer:match("%*$") then
    answer = string.format("%s%s?",answer:sub(1,-2),conj:match(rest))
  end
  
  print(answer)
end
