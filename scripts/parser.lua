require('lpeg')
require('re')
require('object')
require('utils')

collider = {}
errpos = 0

local function debug_out(text, pos, cap)
   return true
end

local function looking_for(thing)
   return lpeg.P(function(text, pos, cap)
                    print(thing .. ' at pos:' .. pos .. '?  ' .. "'" .. trim(string.sub(text, pos, string.len(text))) .. "'")
                    errpos = pos
                    return true
                 end)
end

ERR_POS = lpeg.P(debug_out)

defs = {}
for i,v in ipairs({'NOUN', 'VERB', 'ADVERB', 'PREPOSITION', 'CONJUNCTION', 'ARTICLE', 'ADJECTIVE', 'PRONOUN', 'STRING', 'SENTENCE', 'END_OF_SENTENCE', 'COMMAND', 'END_OF_LINE', 'NOUN_PHRASE', 'NOUN_GROUP'}) do
   defs[v .. '_POS'] = looking_for(v)
end

grammar = re.compile([[
                         input <- {:sentences: (sentence -> {} (end_of_sentence %s sentence -> {})*) -> {} end_of_sentence? end_of_line:} -> {}
                         end_of_line <- %END_OF_LINE_POS %nl
                         noun <- %NOUN_POS ('dirk' / 'sword' / 'box')
                         verb <- %VERB_POS ('hit' / 'kick' / 'get' / 'cuddle' / 'pick up')
                         adverb <- %ADVERB_POS ('quickly' / 'quietly' / 'loudly')
                         preposition <- %PREPOSITION_POS ('with' / 'in' / 'on')
                         conjunction <- %CONJUNCTION_POS ('and' / 'then')
                         article <- %ARTICLE_POS ('the' / 'a' / 'that')
                         adjective <- %ADJECTIVE_POS ('big' / 'small' / 'purple' / 'my')
                         pronoun <- %PRONOUN_POS ('him' / 'her' / 'Bob')
                         string <- %STRING_POS '".*"'
                         sentence <- %SENTENCE_POS {:commands: (command -> {} ((%s {:conjunction: conjunction :} %s command) -> {})*) -> {} :}
                         end_of_sentence <- %END_OF_SENTENCE_POS '.'
                         command <- %COMMAND_POS (({:adverbs1: (adverb %s)* :} {:verb: verb:} {:adverbs2: (%s adverb)* :}
                                                   (%s {:phrase1: noun_phrase :} {:adverbs3: (%s adverb)* :}
                                                    (%s {:preposition: preposition:} %s {:phrase2: noun_phrase :} {:adverbs4: (%s adverb)* :})?
                                                   )?) /
                                                  ({:adverbs1: (adverb %s)* :} {:preposition: preposition:} %s {:phrase1: noun_phrase :} {:adverbs2: (%s adverb)* :} %s {:verb: verb:} {:adverbs3: (%s adverb)* :} %s {:phrase2: noun_phrase :} {:adverbs4: (%s adverb)* :}))

                         noun_phrase <- %NOUN_PHRASE_POS {:groups: (noun_group -> {} (%s ({:preposition: preposition:} %s noun_group) -> {})*) -> {}:} -> {}
                         noun_group <- %NOUN_GROUP_POS (({:article: article:} %s)? ([0-9]* %s)? {:adjectives:({adjective} %s)* -> {}:} ({:noun: noun:} / {:pronoun: pronoun:} / {:string: string:}))
                      ]], defs)


functions = {}
functions['get thing'] = function (player, verb, subject, object) print('You pick up the ' .. subject.name) end
functions['get dirk'] = function (player, verb, subject, object) print('You pick up the dirk and examine its edge.  Sharp.') end

for i, v in ipairs({'thing', 'weapon', 'sword', 'dirk', 'box', 'verb', 'get'}) do
   there_is_a(v)
end

for i, v in ipairs({{'weapon', 'thing'}, {'sword', 'weapon'}, {'dirk', 'weapon'}, {'box', 'thing'}, {'get', 'verb'}}) do
   is_a_kind_of(v[1], v[2])
end

function no_function(player, verb, object)
   print('I don\'t know how to ' .. verb .. ' the ' .. object)
end

function get_function(a, b, c)
   for ia, va in ipairs(get_all_parents(a)) do
      for ib, vb in ipairs(get_all_parents(b)) do
         print(va, vb)
         local f = functions[va .. ' ' .. vb]
         if f then
            return f
         end
      end
   end
   return no_function
end

function get_objects_from_phrase(phrase)
   local group = phrase.groups[1]
   return group.noun or group.pronoun or group.string
end

function parse(text)
   match = grammar:match(text .. "\n")
   printTable(match)

   for _, sentence in ipairs(match.sentences) do
      for _, command in ipairs(sentence.commands) do
         local verb = command.verb
         local subject, object
         if command.phrase1 then subject = get_objects_from_phrase(command.phrase1) end
         if command.phrase2 then object = get_objects_from_phrase(command.phrase2) end
         print(verb, subject, object)
         get_function(verb, subject, object)('You', collider[verb], subject and collider[subject])
      end
   end
end