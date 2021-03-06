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
-- Unfinished exploratory work based on the Eliza-script.txt file.  Use
-- at your own risk.
--
-- ********************************************************************

local keywords =
{
  {  phrase = "can you"		, idx =   1 , run =  3 } ,
  {  phrase = "can i"		, idx =   4 , run =  2 } ,
  {  phrase = "you are"		, idx =   6 , run =  4 } ,
  {  phrase = "you're"		, idx =   6 , run =  4 } ,
  {  phrase = "i don't"		, idx =  10 , run =  4 } ,
  {  phrase = "i feel"		, idx =  14 , run =  3 } ,
  {  phrase = "why don't you"	, idx =  17 , run =  3 } ,
  {  phrase = "why can't i"	, idx =  20 , run =  2 } ,
  {  phrase = "are you"		, idx =  22 , run =  3 } ,
  {  phrase = "i can't"		, idx =  25 , run =  3 } ,
  {  phrase = "i am"		, idx =  28 , run =  4 } ,
  {  phrase = "i'm"		, idx =  28 , run =  4 } ,
  {  phrase = "you"		, idx =  32 , run =  3 } ,
  {  phrase = "i want"		, idx =  35 , run =  5 } ,
  {  phrase = "what"		, idx =  40 , run =  9 } ,
  {  phrase = "how"		, idx =  40 , run =  9 } ,
  {  phrase = "who"		, idx =  40 , run =  9 } ,
  {  phrase = "where"		, idx =  40 , run =  9 } ,
  {  phrase = "when"		, idx =  40 , run =  9 } ,
  {  phrase = "why"		, idx =  40 , run =  9 } ,
  {  phrase = "name"		, idx =  49 , run =  2 } ,
  {  phrase = "cause"		, idx =  51 , run =  4 } ,
  {  phrase = "sorry"		, idx =  55 , run =  4 } ,
  {  phrase = "dream"		, idx =  59 , run =  4 } ,
  {  phrase = "hello"		, idx =  63 , run =  1 } ,
  {  phrase = "hi"		, idx =  63 , run =  1 } ,
  {  phrase = "maybe"		, idx =  64 , run =  5 } ,
  {  phrase = "no"		, idx =  69 , run =  5 } ,
  {  phrase = "your"		, idx =  74 , run =  2 } ,
  {  phrase = "always"		, idx =  76 , run =  4 } ,
  {  phrase = "think"		, idx =  80 , run =  3 } ,
  {  phrase = "alike"		, idx =  83 , run =  7 } ,
  {  phrase = "yes"		, idx =  90 , run =  3 } ,
  {  phrase = "friend"		, idx =  93 , run =  6 } ,
  {  phrase = "computer"	, idx =  99 , run =  7 } ,
  {  phrase = ""		, idx = 106 , run =  6 } ,
}

--[[
conj = Cs((
	     W" are "  / " am "
	   + W" were " / " was "
	   + W" you "  / " I "
	   + W" your " / " my "
	   + W" I've " / " you've "
	   + W" I'm "  / " you're "
	   + W" me "   / " you "
	   + C(1)
	  )^1)
]]

local replies =
{
  "Don't you believe that i can*",
  "Perhaps you would like me to be able to*",
  "You want me to be able to*",
  "Perhaps you don't want to*",
  "Do you want to be able to*",
  "What makes you think i am*",
  "Does it please you believe i am *",
  "Perhaps you would like to be*",
  "Do you sometimes wish you were*",
  "Don't you really*",
  "Why don't you*",
  "Do you wish to be able to*",
  "Does that trouble you?",
  "Tell me more about such feelings.",
  "Do you often feel*",
  "Do you enjoy feeling*",
  "Do you really believe i don't*",
  "Perhaps in good time i will*",
  "Do you want me to*",
  "Do you think you should be able to*",
  "Why can't you*",
  "Why are you interested in whether or not i am*",
  "Would you prefer if i were not*",
  "Perhaps in your fantasies i am*",
  "How do you know you can't*",
  "Have you tried?",
  "Perhaps you can now*",
  "Did you come to me because you are*",
  "How long have you been*",
  "Do you believe it is normal to be*",
  "Do you enjoy being*",
  "We were discussing you-- not me.",
  "Oh, i*",
  "You're not really talking about me, are you?",
  "What would it mean to you if you got*",
  "Why do you want*",
  "Suppose you soon got*",
  "What if you never got*",
  "I sometimes also want*",
  "Why do you ask?",
  "Does that question interest you?",
  "What answer would please you the most?",
  "What do you think?",
  "Are such questions on your mind often?",
  "What is it that you really want to know?",
  "Have you asked anyone else?",
  "Have you asked such questions before?",
  "What else comes to mind when you ask that?",
  "Names don't interest me.",
  "I don't care about names-- please go on.",
  "Is that the real reason?",
  "Don't any other reasons come to mind?",
  "Does that reason explain anything else?",
  "What other reasons might there be?",
  "Please don't apologize!",
  "Apologies are not necessary.",
  "What feelings do you have when you apologize.",
  "Don't be so defensive!",
  "What does that dream suggest to you?",
  "Do you dream often?",
  "What persons appear in your dreams?",
  "Are you disturbed by your dreams?",
  "How do you do ... please state your problem.",
  "You don't seem quite certain.",
  "Why the uncertain tone?",
  "Can't you be more positive?",
  "You aren't sure?",
  "Don't you know?",
  "Are you saying no just to be negative?",
  "You are being a bit negative.",
  "Why not?",
  "Are you sure?",
  "Why no?",
  "Why are you concerned about my*",
  "What about your own*",
  "Can you think of a specific example?",
  "When?",
  "What are you thinking of?",
  "Really, always?",
  "Do you really think so?",
  "But you are not sure you*",
  "Do you doubt you*",
  "In what way?",
  "What resemblance do you see?",
  "What does the similarity suggest to you?",
  "Can you think of a specific example?",
  "Could there really be some connection?",
  "How?",
  "You seem quite positive.",
  "Are you sure?",
  "I see.",
  "I understand.",
  "Why do you bring up the topic of friends?",
  "Do your friends worry you?",
  "Do your friends pick on you?",
  "Are you sure you have any friends?",
  "Do you impose on your friends?",
  "Perhaps your love for friends worries you.",
  "Do computers worry you?",
  "Are you talking about me in particular?",
  "Are you frightened by machines?",
  "Why do you mention computers?",
  "What do you think machines have to do with your problem?",
  "Don't you think computers can help people?",
  "What is it about machines that worries you?",
  "Say, do you have any psychological problems?",
  "What does that suggest to you?",
  "I see.",
  "I'm not sure i understand you fully.",
  "Come come elucidate your thoughts.",
  "Can you elaborate on that?",
  "That is quite interesting.",
}

for _,item in ipairs(keywords) do
  print(string.format("  [%q] =\n  {",item.phrase,item.idx,item.run))
  for i = item.idx , item.idx + item.run - 1 do
    print(string.format("    %q,",replies[i]))
  end
  print("  },\n")
end
