require('lpeg')
require('log')
require('utils')

local errpos = 0
local looking_for_at = {}
local function looking_for(thing)
   return lpeg.P(function(text, pos, cap)
                    DEBUG(thing .. ' at pos:' .. pos .. '?  ' .. "'" .. rtrim(string.sub(text, pos, string.len(text))) .. "'")
                    if pos > errpos then errpos = pos end
                    looking_for_at[pos] = looking_for_at[pos] or {}
                    for _, v in ipairs(looking_for_at[pos]) do
                       if v == thing:lower() then
                          return true
                       end
                    end
                    table.insert(looking_for_at[pos], thing:lower())
                    return true
                 end)
end

local function is_noun(text, pos, cap)
   return cap == 'dirk', cap
end

local function is_verb(text, pos, cap)
   return cap == 'hit', cap
end

local function is_adverb(text, pos, cap)
   return cap == 'quickly', cap
end

local function is_adjective(text, pos, cap)
   return cap == 'sharp', cap
end

local function is_pronoun(text, pos, cap)
   return cap == 'bob', cap
end

local function is_in(...)
   local words = ...
   return function(text, pos, cap)
      for _, v in ipairs(words) do
         if cap == v then return true, v end
      end
      return false
          end
end

local P = lpeg.P -- Simple pattern
local S = lpeg.S -- Set
local R = lpeg.R -- Range

local C = lpeg.C -- Simple capture
local Cb = lpeg.Cb -- Capture back-reference
local Cg = lpeg.Cg -- Group capture
local Ct = lpeg.Ct -- Table capture
local Cmt = lpeg.Cmt -- Match-time function capture

local sentence_end = S'.;'
local line_end = P(-1)
local sep = S' ,'

local word = (R'AZ' + R'az')^1 / string.lower

local function word_that(f)
   return Cmt(word, f)
end

local function token(name, patt)
   return sep^0 * sentence_end^0 * looking_for(name:upper()) * patt * (#sep + #sentence_end + line_end)
end

local noun = token('NOUN', word_that(is_noun))
local verb = token('VERB', word_that(is_verb))
local adverb = token('ADVERB', word_that(is_adverb))
local adverbs = Ct(adverb^0)
local adjective = token('ADJECTIVE', word_that(is_adjective))
local pronoun = token('PRONOUN', word_that(is_pronoun))

local function quoted(quote_char)
   local quote = P(quote_char)
   return quote * C((1 - quote)^0) * quote
end
local quoted_string = token('STRING', quoted('"') + quoted("'") + quoted('`'))

local article = token('ARTICLE', word_that(is_in({'a', 'the'})))
local conjunction = token('CONJUNCTION', word_that(is_in({'and', 'then'})))
local number = token('NUMBER', R'09'^1 / tonumber)
local preposition = token('PREPOSITION', word_that(is_in({'in', 'on', 'except', 'and'})))

local noun_group = Cg(article, 'article')^-1 * Cg(number, 'number')^-1 * Cg(Ct(adjective^0), 'adjectives') * (Cg(noun, 'noun') + Cg(pronoun, 'pronoun') + Cg(quoted_string, 'string'))
local noun_phrase = Ct(Cg(Ct(Ct(noun_group) * (Ct(Cg(preposition, 'preposition') * noun_group))^0), 'groups'))
local command = Cg(adverbs, 'adverbs1') * Cg(verb, 'verb') * Cg(adverbs, 'adverbs2') * (Cg(noun_phrase, 'subject') * Cg(adverbs, 'adverbs3') * (Cg(preposition, 'preposition') * Cg(noun_phrase, 'object') * Cg(adverbs, 'adverbs4'))^-1)^-1
   + adverbs * Cg(preposition, 'preposition') * Cg(noun_phrase, 'object') * adverbs * Cg(verb, 'verb') * adverbs * Cg(noun_phrase, 'subject') * adverbs
local sentence = Ct(Cg(Ct(Ct(command) * (Ct(Cg(conjunction, 'conjunction') * command))^0), 'commands'))

local input = Ct(Cg(Ct(Cg(sentence) * (sentence_end * Cg(sentence))^0 * sentence_end^0 * line_end), 'sentences'))

function parse(text)
   match = input:match(text)
   local msg = ''
   if not match then
      msg = 'Huh?  I ran into trouble about here: ' .. text:sub(0, errpos - 1) .. '>>>' .. text:sub(errpos)
      msg = msg .. "\n" .. 'I would\'ve liked to have found one of these: ' .. table.concat(looking_for_at[errpos], ', ')
   else
      printTable(match, DEBUG)
   end
   return match, msg
end
