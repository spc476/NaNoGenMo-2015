
local lpeg = require "lpeg"
local Cf   = lpeg.Cf
local Cs   = lpeg.Cs
local C    = lpeg.C
local S    = lpeg.S
local R    = lpeg.R
local P    = lpeg.P

local H,W do
  local pattern = Cf((
      R("AZ","az") / function(c) return P(c:lower()) + P(c:upper()) end
    + P(1)         / function(c) return P(c) end
    )^0
    , function(a,b) return a * b end
  )
  
  H = function(text)
    return pattern:match(text)
  end
  
  local function set(word,weight,acc)
    table.insert(acc,{ word = word , weight = weight })
    return word
  end
  
  W = function(text,weight)
    weight = weight or 1
    return (H(text) / text * Cc(weight) * Carg(1)) / set
  end         
end

-- ************************************************************************
-- Step 2 (we skip step 1)---pre-substitution phase.  The word on the left
-- is swapped for the word on the right.  Addtions should be made with
-- longer words appearing before shorter ones if there is a common prefix
-- between the words.
-- ************************************************************************

local pre_words = H"dont"      / "don't"
                + H"cant"      / "can't"
                + H"certainly" / "yes"
                + H"computers" / "computer"
                + H"dreams"    / "dream"
                + H"dreamt"    / "dreamed"
                + H"how"       / "what"
                + H"i'm"       / "I am"
                + H"maybe"     / "perhaps"
                + H"recollect" / "remember"
                + H"same"      / "alike"
                + H"were"      / "was"
                + H"when"      / "what"
                + H"wont"      / "won't"
                + H"you're"    / "you are"

local space     = S" \t\n"^1 / " "
local nonalpha  = C(R("!@","[`","{~"))
local pre_list  = pre_words * (space + nonalpha)^-1
local other     = pre_list + nonalpha + space + C(P(1) - pre_list)
local pre       = Cs(other^1)

print(pre:match "dont foobar cant")
print(pre:match "foobar wont cant")
print(pre:match "dont you forget about me")
print(pre:match "when certainly\tyou're    computers")

