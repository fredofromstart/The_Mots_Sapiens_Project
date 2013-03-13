#!/usr/bin/ruby

#####################
# MIT License (MIT)
#
# Copyright (c) 2013 Frédéric Lemire 
#
# a.k.a. Fred Mir (on Facebook, Google+, and Wordpress among other places)
# email : fredofromstart@gmail.com
# blog  : http://fredofromstart.wordpress.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this 
# software and associated documentation files (the "Software"), to deal in the Software 
# without restriction, including without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to the following 
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies 
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.


#################################
# Notes about the version 0.0.1 
#
# This script is a first attempt at building a wish machine such as described in the 
# document What is the Mots Sapiens Project ? (README.md) that you can find, along with 
# this very script, at this GitHub repository : 
#
#    https://github.com/fredofromstart/The_Mots_Sapiens_Project.git
#
# To install a Ruby interpretor on your computer, so as to be able to run the script, 
# I recommand this site : http://www.ruby-lang.org/en/downloads/ — I chose the second 
# installation option.
#
# This software can be used individually — with a little filtering — to learn about which users 
# one ~could~ have good reasons to communicate with.
#
# Please understand that this script has been written in haste and is far from being complete.  
# First of all, even though it's written in an object oriented language, no class has been 
# implemented. Also, even though it works with small numbers of wish lists, it is dubious 
# that it can manage with significantly more ; real database operations are probably 
# required here ; for now, the operations are managed through mere arrays… ; moreover, 
# user accounts have to be taken care of — the obvious space-time considerations are also
# yet to be coded altogether (geographic distance between users, their range, schedules, 
# itineraries and availabilities).
#
# Other things to know about this script : As funny as it may seem, the languages in which 
# the wishes are written are not taken into account ; that should be the case, probably, in 
# future versions to better disambiguate some cases.
#
# Note on the use of the word 'map' in the code. A 'map' is in fact a set of links.
#
# For testing purposes, and in order to reduce internet access, some data have been inserted 
# within the script. To switch to testing mode, just set the following USE_LOCAL_DATA variable to true :

USE_LOCAL_DATA = false 

# (Set to true during testing phase, to spare internet time ; set to false to load from the web.)
#
# Special thanks to : Peter Sangura Sitati, with whom the idea sprouted ; Bernard Michaud who 
# helped me brainstorming and to make the code run on Windows ; Daniel S. Gravel, who proofread  
# the presentation text in English.


######################################################################################
# Here is what the present version of the ~Tramice 721~ is already able to achieve :
#
# [x] reads the wish lists on the web (listed here : http://motsapiensproject.wikia.com/wiki/Volios)
#
# [x] collects synonyms (imagine dew drops made of ~polyformulated~ ideas joining by emergence)
#
# [x] identifies possible homonyms and disambiguate the elements accordingly
#
# [x] locates possibly erroneous synonyms and correct them
#
# [ ] does the previous two automatically
#
# [x] finds parts of wishes that should be synonyms and create new elements with them
#
# [x] reassembles those parts in all the possibles ways, permuting, for every wish, every combinations 
#     of synonymous parts, and checks whether or not it finds wishes that are satisfying answers to each other
#
# [ ] refreshes data about the current state of the volios and informs, at a frequency specified on his or
#     her volio, the current user by email of all other wishers whose wishes are correct answers
#     to his or hers, with appropriate details (server needed)


##############################################
# Global variables are all starting with a $

$users      = []
$wish_lists = []
$categories     = []
$lexicon        = []
$lexicon_infos  = []

           #  {  'k' => index,      \  Key
           #     'w' => true/false, \  Does this lexeme correspond to a whole, undivided wish ?
           #     'o' => false,      \  Is this lexeme optional ?
           #     '+' => 1,          \  Frequency
           #     '~' => [],         \  Synonyms
           #     'e' => []          }  Keys of corresponding element (there will be many for homonyms).

$elements             = []

           #  {  'k' => $elements.length,  \
           #     '~' => synonyms,          \
           #     '#' => map,               \
           #     '@' => total_strength,    \
           #     '%' => complete           }
           #
           #  May also contain keys : 'HOMONYMY MAP', 'SUPERCEDED by', 
           
$ambivalent_synonyms  = []

           #  {  'k' => e['k'],                \
           #     'a' => a,                     \
           #     'b' => b,                     \
           #    '~a' => all_mapped_to_a,       \
           #    '~b' => all_mapped_to_b,       \
           #    '#a' => map_a,                 \
           #    '#b' => map_b,                 \
           #    '@a' => mapped_to_a_strength,  \
           #    '@b' => mapped_to_b_strength   }
            
$suspected_homonyms   = []

           # It is an array of arrays of :
           #
           #  { 'k' => e['k'],           \
           #    'l' => tested_lexeme,    \
           #    '~' => synonyms,         \
           #    '#' => subset,           \
           #    '@' => total_strength,   \
           #    '%' => complete          }
		                     
$homonyms             = []
          
           #  { 'l' => l,            \
           #    'h' => $lexicon[l],  \
           #    'x' => k,            \
           #    'e' => []            }
           
$unresolved_homonyms  = []

# $languages  = []  # Will we be able to emerge them ? Shall we have to ask the wishers to freely use ISO 639 code for language ? Parallel lexicons ??

$matches    = []  # That will be our matching wishes !!

$THRESHOLD_FOR_WEAKNESS = 0.6
$NOTABLY                = 3 # times (or more), in a comparison.


#######################
# Utilitary Functions 

# This function returns true if the received element is not a homonymy map or superceded by another one. Returns false otherwise.
#
def skip_element( element )

  skip = false
  
  if element.has_key? 'HOMONYMY MAP' \
  or element.has_key? 'SUPERCEDED by' then
    skip = true
  end
  
  return skip
  
end


# This method adds an element for lexemes that don't have one.
#
def form_elements_with_isolated_lexemes()

  $lexicon_infos.each_with_index do |lexeme_infos, l|
  
    if lexeme_infos['e'] == [] then
    
      lexeme_infos['e'] = [$elements.length]
      
      $elements << {  'k' => $elements.length,         \
                      '~' => lexeme_infos['~'] | [l],  \
                      '#' => [],                       \
                      '@' => 0,                        \
                      '%' => 0.0                       }      
    end
  end
end


# This method keeps in memory the condition for resolving a homonymy ambiguity.
#
def take_note_to_resolve_homonym_for( lexeme, should_match )

  $unresolved_homonyms |= [ { 'l' => lexeme,        
                              '~' => should_match } ]

end


# This method tries to resolve homonymy ambiguities.
#
def resolve_homonyms( )

  $unresolved_homonyms.reverse.each_with_index do |ambiguity, i|
    l = ambiguity['l']
    $lexicon_infos[l]['e'].each do |e|
      if e['~'] & ambiguity['~'] != [] then       # Do our synonyms intersect with any of the elements' synonyms ?      
        add_synonyms( ambiguity['~'], e['k'] )    # If so, add them under it.
        $unresolved_homonyms.delete_at( i )       # And delete the ambiguity note.
      end
    end
  end

end

            
# This method adds a lexeme to $lexicon and $lexicon_infos.
#
def add_lexeme( lexeme, whole )

  in_lexicon = $lexicon.index( lexeme )

# Is it there ?

  if in_lexicon then  # Count it.   
            
    $lexicon_infos[in_lexicon]['+'] += 1                

  else                # Otherwise, create it.            
    
    in_lexicon = $lexicon.length
                 $lexicon << lexeme
    
    $lexicon_infos << {  'k' => in_lexicon,  # This is actually the lexeme's index inside $lexicon_infos.
                         'w' => whole,       # This flag is set to true if a lexeme corresponds to a whole wish.
                         'o' => false,       # This flag is set to true when a lexeme is thought optional.
                         '+' => 1,           # Usage counter.
                         '~' => [],          # Synonyms.
                         'e' => [],          # Key of the corresponding $elements.
                         '<' => []           # Will contain found sub-lexemes.
                      }
  end    
    
  return in_lexicon

end
        

# This method adds synonyms to the $lexicon_infos and adjusts $elements accordingly
#
def add_synonyms( lexeme_indices, known_element )

  all_synonyms   = []
  all_elements   = known_element   # Will be [] if not known.
  element_in_all = []

  lexeme_indices.each do |l|
    $lexicon_infos[l]['+'] += 1                   # We first take census of the lexeme frequency
    all_synonyms |= [l] + $lexicon_infos[l]['~']  # and gather, if any, the synonyms of our synonyms.
  end

  lexeme_indices.each do |l|
    $lexicon_infos[l]['~'] = all_synonyms - [l]
  end
  
  if all_elements == [] then

    lexeme_indices.each do |l|
      if $lexicon_infos[l]['e'].length == 1 then
        all_elements |= $lexicon_infos[l]['e']      # We also collect all the elements (if any) related to our lexemes.
        element_in_all = element_in_all & $lexicon_infos[l]['e']
      end
    end  
   
    if element_in_all != [] then                    # If there is one element common to all the given synonyms then
      all_elements = element_in_all                 # choose this one.
    end
  
    lexeme_indices.each do |l|
      if $lexicon_infos[l]['e'].length > 1 then     # If we have more than one element, there is a homonymy to resolve.
        unresolved_homonym = true
        $lexicon_infos[l]['e'].each do |e|
          if e['~'] & all_synonyms != [] then       # Do our synonyms intersect with any of the elements' synonyms ?
            all_elements = [e]                      # If yes, let's take the first one and leave it at that for now.
            unresolved_homonym = false
            break
          end                                       # Otherwise, take a note for later.
        end
        if unresolved_homonym then take_note_to_resolve_homonym_for( l, lexeme_indices ) end
      end
    end
  end

  all_maps = []
  
  case 

  when all_elements.length == 0
  
    element_index = $elements.length              # We will soon create a new one if element_index == $elements.length
  
  when all_elements.length == 1
  
    element_index = all_elements[0]    
    
  when all_elements.length >= 2     # When synonyms correspond to many elements, fusion them into a new one and markoff (but keep) the old elements.
  
    element_index = $elements.length
    all_elements.each do |e|
      all_maps |= $elements[e]['#']
    end
    lexeme_indices.each do |l|
      $lexicon_infos[l]['e'] -= all_elements
    end
    all_elements.each do |e|
      $elements[e]['SUPERCEDED by'] = element_index
    end
  end
  
  lexeme_indices.each do |l|
    $lexicon_infos[l]['e'] |= [element_index]
  end
  
  if element_index == $elements.length then
  
    $elements << {  'k' => element_index,        #
                    '~' => all_synonyms,         #
                    '#' => all_maps,             # 
                    '@' => 0,                    # Strength.
                    '%' => 0.0                   # Completeness.
                  }  
  else

    $elements[element_index]['~'] |= all_synonyms
    
  end
  
  all_synonyms.each_with_index do |s1, i1|
    all_synonyms.each_with_index do |s2, i2|
      if i2 >= i1 then
        next
      end
      pair = $elements[element_index]['#'].find {|pair| (pair['-'] - [s1]) - [s2] == []}

      if pair then 
        pair['@'] += 1
      else
        $elements[element_index]['#'] |= [{'-' => [s1, s2], '@' => 1}]
      end
      
      $elements[element_index]['@'] += 1
    end
  end
  
  $elements[element_index]['%'] = completeness( $elements[element_index]['#'].length, $elements[element_index]['~'].length )
  
  return element_index
  
end
            
            
# This method, apart from the obvious, also populates the global $lexicon
# and $lexicon_infos Arrays. The latter contains synonyms' statistics.
#
def split_into_synonyms( part )
  if part.include? ' // ' then
    synonyms = part.split(/\s+\/\/\s+/)
  else
    synonyms = part
  end

  synonyms_indexes = []
  Array(synonyms).each do |lexeme|
    matching_lexeme = $lexicon.index( lexeme )
    if matching_lexeme then
    
      $lexicon_infos[matching_lexeme]['+'] += 1
      synonyms_indexes << matching_lexeme
      
    else
      lexeme.gsub!( /\s*\,\s*/, ' , ' )   # We trim the lexemes for easier processing. We will need the reverse for rendering.
=begin    
      lexeme.gsub!( /\s*\;\s*/, ' ; ' )
      lexeme.gsub!( /\s*\:\s*/, ' : ' )
      lexeme.concat!( ' ' )
      lexeme.gsub!( /\s*\.\s+/, ' . ' )
      lexeme.chomp!
      lexeme.gsub!( /\s*\"\s*/, ' " ' )
      lexeme.gsub!( /\s*\?\s*/, ' ? ' )
      lexeme.gsub!( /\s*\!\s*/, ' ! ' )
      lexeme.gsub!( /\s*\%\s*/, ' % ' )
      lexeme.gsub!( /\s*\#\s*/, ' # ' )
      lexeme.gsub!( /\s*\(\s*/, ' ( ' )
      lexeme.gsub!( /\s*\)\s*/, ' ) ' )
      lexeme.gsub!( /\s*\~\s*/, ' ~ ' )
      lexeme.gsub!( /\s*\—\s*/, ' — ' )
      lexeme.gsub!( /\s*\-\-\s*/, ' -- ' )
=end
      $lexicon << lexeme
      
      index = $lexicon.length - 1
      
      $lexicon_infos << {   'k' => index,    # The lexeme's ID, actually its index.
                            'w' => true,     # 'w' for whole. This is a whole wish.
                            'o' => false,    # Will be set to true if discovered optional.
                            '+' => 1,        # Frequency.
                            '~' => [],       # Indices of synonymous lexemes.
                            'e' => [],       # Will contain all elements 'homonymous' to this lexeme.
                            '<' => []        # Will contain found sub-lexemes.
                        }
                            
      synonyms_indexes << index
    end
  end
  
# Connects each synonym with each other (not with itself).
  
  synonyms_indexes.each do |s|
    $lexicon_infos[s]['~'].concat( synonyms_indexes - [s] )
  end
  return synonyms_indexes
end


# This method takes a number_of_connections in a set and the set's cardinality
# and returns the percentage x represents compared to all the possible connections in that set.
#
def completeness( number_of_connections, cardinality )

  return number_of_connections.to_f / (((cardinality.to_f ** 2) - cardinality.to_f) / 2)
  
end


###############################################################################################
if USE_LOCAL_DATA then # Let's use pre-loaded data to spare internet time during testing phase

$users = \
[{"name"=>"Fictitious_Character_1", "infos"=>[[[37, 38], [39]], [[40, 41], [42]], [[43], [44, 45]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fictitious_Character_1"}, {"name"=>"Fictitious_Character_2", "infos"=>[[[91, 37], [92]], [[93, 40, 94], [95]], [[96, 97], [98, 99]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fictitious_Character_2"}, {"name"=>"Fictitious_Character_3?action=edit&amp;redlink=1", "infos"=>[], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fictitious_Character_3?action=edit&amp;redlink=1"}, {"name"=>"Fictitious_Character_4", "infos"=>[[[37, 38], [122]], [[126], [127, 128]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fictitious_Character_4"}, {"name"=>"Fictitious_Character_5", "infos"=>[[[153], [154]], [[155, 156], [157]], [[158], [159]], [[160, 161], [162]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fictitious_Character_5"}, {"name"=>"Fred_Mir_//_fredofromstart_//_Fr%C3%A9d%C3%A9ric_Lemire", "infos"=>[[[218], [219]], [[155, 156], [220]], [[221, 38, 40], [222, 223]], [[40, 224], [225]], [[160, 226], [227]], [[43, 228, 229], [230, 231]], [[232, 233], [234]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Fred_Mir_//_fredofromstart_//_Fr%C3%A9d%C3%A9ric_Lemire"}, {"name"=>"Julie_Martineau_//_Terrebaleine", "infos"=>[[[304], [305]], [[155, 156], [306]], [[221, 38, 40], [307]], [[160, 226], [308]], [[43, 228, 229], [309, 310]], [[311, 312], [313]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Julie_Martineau_//_Terrebaleine"}, {"name"=>"Katia_Proulx", "infos"=>[[[221, 38], [325]], [[326, 327], [328, 329]], [[330, 226], [331]]], "volio"=>"http://motsapiensproject.wikia.com/wiki/Volio_-_Katia_Proulx"}]

$wish_lists = \
[{"list"=>[{"wish"=>[46, 47], "category"=>1, "rest"=>nil, "type"=>:demand}, {"wish"=>[48, 49, 50], "category"=>2, "rest"=>[51, 52], "type"=>:demand}, {"wish"=>[53, 54], "category"=>3, "rest"=>nil, "type"=>:interest}, {"wish"=>[55, 56], "category"=>3, "rest"=>[57, 58], "type"=>:offer}, {"wish"=>[59, 60], "category"=>4, "rest"=>nil, "type"=>:offer}, {"wish"=>[61, 62], "category"=>4, "rest"=>nil, "type"=>:offer}, {"wish"=>[63, 64], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[65, 66], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[67], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[68, 69], "category"=>6, "rest"=>nil, "type"=>:offer}, {"wish"=>[70, 71, 72], "category"=>6, "rest"=>nil, "type"=>:offer}, {"wish"=>[73, 74], "category"=>7, "rest"=>[75, 76, 77, 78, 79, 80], "type"=>:demand}, {"wish"=>[81, 82], "category"=>7, "rest"=>nil, "type"=>:interest}, {"wish"=>[83, 84], "category"=>8, "rest"=>nil, "type"=>:demand}, {"wish"=>[85, 86, 87], "category"=>8, "rest"=>nil, "type"=>:interest}, {"wish"=>[88, 89], "category"=>9, "rest"=>nil, "type"=>:demand}, {"wish"=>[90], "category"=>9, "rest"=>nil, "type"=>:interest}], "user"=>0}, {"list"=>[{"wish"=>[67], "category"=>11, "rest"=>nil, "type"=>:interest}, {"wish"=>[100], "category"=>11, "rest"=>nil, "type"=>:interest}, {"wish"=>[101, 102, 103], "category"=>11, "rest"=>nil, "type"=>:interest}, {"wish"=>[104, 105], "category"=>12, "rest"=>nil, "type"=>:demand}, {"wish"=>[75, 76], "category"=>12, "rest"=>nil, "type"=>:interest}, {"wish"=>[106, 107], "category"=>13, "rest"=>nil, "type"=>:interest}, {"wish"=>[108, 109], "category"=>13, "rest"=>nil, "type"=>:interest}, {"wish"=>[110, 111], "category"=>13, "rest"=>nil, "type"=>:interest}, {"wish"=>[112, 113], "category"=>14, "rest"=>nil, "type"=>:offer}, {"wish"=>[114, 115, 116], "category"=>14, "rest"=>[117, 118, 119, 120, 121], "type"=>:offer}], "user"=>1}, {"list"=>[], "user"=>2}, {"list"=>[{"wish"=>[123, 124, 125], "category"=>0, "rest"=>nil, "type"=>:interest}, {"wish"=>[129], "category"=>15, "rest"=>nil, "type"=>:offer}, {"wish"=>[130, 131], "category"=>2, "rest"=>nil, "type"=>:interest}, {"wish"=>[132, 133], "category"=>6, "rest"=>nil, "type"=>:offer}, {"wish"=>[134, 135], "category"=>6, "rest"=>nil, "type"=>:offer}, {"wish"=>[136, 137], "category"=>6, "rest"=>nil, "type"=>:offer}, {"wish"=>[138, 139], "category"=>4, "rest"=>nil, "type"=>:offer}, {"wish"=>[61, 62], "category"=>4, "rest"=>nil, "type"=>:offer}, {"wish"=>[140, 141], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[142, 143], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[144, 145], "category"=>5, "rest"=>nil, "type"=>:interest}, {"wish"=>[146, 147], "category"=>16, "rest"=>[148], "type"=>:demand}, {"wish"=>[149, 150], "category"=>16, "rest"=>[151, 152], "type"=>:offer}], "user"=>3}, {"list"=>[{"wish"=>[163, 164], "category"=>17, "rest"=>nil, "type"=>:interest}, {"wish"=>[165, 166], "category"=>17, "rest"=>nil, "type"=>:interest}, {"wish"=>[167, 168], "category"=>17, "rest"=>nil, "type"=>:interest}, {"wish"=>[169, 170], "category"=>18, "rest"=>nil, "type"=>:offer}, {"wish"=>[171, 172], "category"=>18, "rest"=>nil, "type"=>:offer}, {"wish"=>[173, 174], "category"=>19, "rest"=>[175, 176], "type"=>:demand}, {"wish"=>[177, 178, 179, 180], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[181], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[182, 145], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[183, 184], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[185, 186, 187], "category"=>21, "rest"=>nil, "type"=>:interest}, {"wish"=>[188, 189, 190], "category"=>21, "rest"=>[191, 68], "type"=>:demand}, {"wish"=>[192, 193], "category"=>21, "rest"=>nil, "type"=>:demand}, {"wish"=>[194, 195, 196, 197], "category"=>21, "rest"=>nil, "type"=>:interest}, {"wish"=>[198, 199], "category"=>21, "rest"=>nil, "type"=>:interest}, {"wish"=>[200, 201], "category"=>21, "rest"=>[202, 203, 204, 205], "type"=>:demand}, {"wish"=>[206, 207], "category"=>21, "rest"=>nil, "type"=>:interest}, {"wish"=>[208, 209], "category"=>21, "rest"=>nil, "type"=>:interest}, {"wish"=>[210, 211], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[212, 213], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[214, 215], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[216, 217], "category"=>22, "rest"=>nil, "type"=>:demand}], "user"=>4}, {"list"=>[{"wish"=>[56, 55, 235], "category"=>23, "rest"=>[236, 237, 238, 239, 240, 241, 242], "type"=>:offer}, {"wish"=>[243, 244, 245, 246], "category"=>23, "rest"=>nil, "type"=>:offer}, {"wish"=>[247, 248], "category"=>23, "rest"=>[249, 250], "type"=>:offer}, {"wish"=>[251, 252], "category"=>23, "rest"=>nil, "type"=>:offer}, {"wish"=>[253, 254], "category"=>19, "rest"=>[255, 60, 256, 133, 257, 258, 259, 260, 261, 262, 263], "type"=>:demand}, {"wish"=>[264, 265], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[266, 267], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[268, 269], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[270], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[271, 272, 273], "category"=>24, "rest"=>nil, "type"=>:demand}, {"wish"=>[188, 189, 190], "category"=>24, "rest"=>[191, 68], "type"=>:demand}, {"wish"=>[61, 62], "category"=>24, "rest"=>nil, "type"=>:demand}, {"wish"=>[274, 275], "category"=>24, "rest"=>nil, "type"=>:demand}, {"wish"=>[276, 277], "category"=>24, "rest"=>nil, "type"=>:demand}, {"wish"=>[200, 201], "category"=>24, "rest"=>[202, 203, 204, 205], "type"=>:demand}, {"wish"=>[278, 279], "category"=>24, "rest"=>[65], "type"=>:demand}, {"wish"=>[280, 281, 282], "category"=>24, "rest"=>nil, "type"=>:demand}, {"wish"=>[283, 284], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[285, 286], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[287, 288], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[289, 290, 291], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[292, 293], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[294, 295], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[296, 297], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[298, 299, 300, 301, 302, 303], "category"=>25, "rest"=>nil, "type"=>:interest}], "user"=>5}, {"list"=>[{"wish"=>[56, 55, 235], "category"=>23, "rest"=>nil, "type"=>:offer}, {"wish"=>[314, 315], "category"=>23, "rest"=>nil, "type"=>:offer}, {"wish"=>[243, 244, 245, 316], "category"=>23, "rest"=>nil, "type"=>:offer}, {"wish"=>[247, 248], "category"=>23, "rest"=>[249, 250], "type"=>:offer}, {"wish"=>[317, 318], "category"=>19, "rest"=>nil, "type"=>:interest}, {"wish"=>[314, 315], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[63], "category"=>20, "rest"=>nil, "type"=>:interest}, {"wish"=>[319, 320], "category"=>24, "rest"=>nil, "type"=>:interest}, {"wish"=>[321, 322], "category"=>24, "rest"=>nil, "type"=>:interest}, {"wish"=>[283, 284], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[285, 286], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[323, 324], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[289, 290], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[292, 293], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[294, 295], "category"=>22, "rest"=>nil, "type"=>:demand}, {"wish"=>[296, 297], "category"=>22, "rest"=>nil, "type"=>:demand}], "user"=>6}, {"list"=>[{"wish"=>[332, 333], "category"=>26, "rest"=>[334], "type"=>:demand}, {"wish"=>[335, 336], "category"=>26, "rest"=>nil, "type"=>:interest}, {"wish"=>[337, 338], "category"=>26, "rest"=>nil, "type"=>:interest}, {"wish"=>[339, 340], "category"=>26, "rest"=>nil, "type"=>:interest}, {"wish"=>[341, 342], "category"=>26, "rest"=>nil, "type"=>:interest}, {"wish"=>[343], "category"=>26, "rest"=>nil, "type"=>:demand}, {"wish"=>[344], "category"=>26, "rest"=>nil, "type"=>:demand}, {"wish"=>[345, 346], "category"=>26, "rest"=>nil, "type"=>:interest}, {"wish"=>[347, 348], "category"=>26, "rest"=>nil, "type"=>:demand}, {"wish"=>[349, 350], "category"=>26, "rest"=>nil, "type"=>:demand}, {"wish"=>[351, 352], "category"=>26, "rest"=>nil, "type"=>:demand}, {"wish"=>[353], "category"=>27, "rest"=>nil, "type"=>:offer}, {"wish"=>[354], "category"=>27, "rest"=>nil, "type"=>:offer}], "user"=>7}]

$categories = \
["Infos", "Patentes", "Recherch\303\251 // Wanted", "Talents", "\303\200 donner", "Int\303\251r\303\252ts // Interests", "Offres", "Relations", "Int\303\251r\303\252ts", "R\303\252ve", "Informations", "Hobbies", "Recherch\303\251 :", "Ressources", "Services", "Annonces // Ads", "Souhaits", "Int\303\251r\303\252ts // Domaines d'int\303\251r\303\252t", "Savoir-faire, Exp\303\251rience", "Projets // Projects", "Int\303\251r\303\252ts, Hobbies", "D\303\251sirs", "Liste d'\303\251picerie // Grocery List", "Ressources, Talents, Savoirs, Savoir-faire, Exp\303\251rience, Offres", "Besoins, Manques, Souhaits, D\303\251sirs", "Universal needs (this is but a sketch) // Besoins universels (ceci n'est qu'une esquisse)", "Souhaits // Wishes", "Offres // Offers"]

$lexicon = \
["Infos", "Patentes", "Recherch\303\251", "Wanted", "Talents", "\303\200 donner", "Int\303\251r\303\252ts", "Interests", "Offres", "Relations", "R\303\252ve", "Informations", "Hobbies", "Recherch\303\251 :", "Ressources", "Services", "Annonces", "Ads", "Souhaits", "Domaines d'int\303\251r\303\252t", "Savoir-faire , Exp\303\251rience", "Projets", "Projects", "Int\303\251r\303\252ts , Hobbies", "D\303\251sirs", "Liste d'\303\251picerie", "Grocery List", "Ressources , Talents , Savoirs , Savoir-faire , Exp\303\251rience , Offres", "Int\303\251r\303\252ts , Hobbies", "Besoins , Manques , Souhaits , D\303\251sirs", "Universal needs (this is but a sketch)", "Besoins universels (ceci n'est qu'une esquisse)", "Ressources , Talents , Savoirs , Savoir-faire , Exp\303\251rience , Offres", "Int\303\251r\303\252ts , Hobbies", "Besoins , Manques , Souhaits , D\303\251sirs", "Wishes", "Offers", "pseudo", "name", "Fictitious Character 1", "nombre", "number", "1111111", "alimentation", "locale , biologique", "local , organic", "un iPhone", "a iPhone", "to find a second-hand pick-up truck", "trouver un camion pick-up usag\303\251", "obtenir une semi-remorque", "to sell an old pick-up", "vendre une vieille semi-remorque", "musique", "music", "illustration", "dessin", "trouver quelqu'un qui a du talent en dessin", "to find someone who draws well", "vieilles bicyclettes", "vieux v\303\251los", "un casse-noix", "a nutcracker", "nature", "naturaleza", "jouer au Go", "to play Go", "badminton", "donner des massages", "faire des massages", "faire du travail manuel", "travail manuel", "travaux manuels", "tomber en amour avec une femme", "to fall in love with a woman", "tomber en amour avec un homme", "to fall in love with a man", "tomber en amour avec un artiste", "to fall in love with an artist", "tomber en amour avec un philosophe", "to fall in love with a philosopher", "trouver des collaborateurs pour un projet informatique", "to find collaborators for a computer science project", "femmes", "women", "home improvement", "r\303\251novation", "r\303\251nover des maisons", "visiter Los Angeles", "to visit Los Angeles", "aller en France", "identifiant", "Normand-27", "num\303\251ro", "matricule", "727", "orientation sexuelle", "sexual orientation", "homo", "gay", "scrabble", "prendre des marches", "me promener", "to walk", "t\303\251l\303\251scope", "telescope", "un pick-up", "a pick-up", "acc\303\250s \303\240 Internet", "Internet access", "graines", "seeds", "enseigner le badminton", "to teach badminton", "garder des enfants", "to take care of children", "babysit", "faire garder mes enfants", "a babysitter for my kids", "a babysitter for my children", "faire garder mon enfant", "trouver un(e) babysitter", "Fictitious Character 4", "j'ai quatre enfants", "j'ai 4 enfants", "I have 4 children", "particularit\303\251", "je suis gaucher", "I am left-handed", "vendre un camion pick-up de seconde main", "une bo\303\256te \303\240 musique", "a music-box", "pi\303\250ces de v\303\251los", "bike parts", "massoth\303\251rapie", "des massages", "un voilier de seconde main", "un voilier usag\303\251", "vieilles choses", "vieux trucs", "jouer au hockey", "to play hockey", "hockey sur glace", "hockey", "la g\303\251ologie", "geology", "rencontrer l'\303\242me s\305\223ur", "to meet my soulmate\302\240", "femme *", "enseigner la g\303\251ologie", "to teach geology", "apprendre la g\303\251ologie", "to learn geology", "lattitude , longitude", "46.812201 , -71.210831", "rayon d'action", "range", "5 km", "nom complet", "Ydrasm\303\274l Mandriakititis", "email", "adresse \303\251lectronique", "ydrasman@gmail.com", "croissance personnelle", "d\303\251veloppement de la personne", "to build houses to build homes", "construire des maisons", "traduction", "translation", "couture", "sewing", "enseigner le dessin", "to teach drawing", "\303\251crire un roman", "to write a novel", "silence et tranquillit\303\251", "silence and tranquility", "lecture et \303\251criture", "reading and writing", "lire et \303\251crire", "to read and to write", "Space Gatherings", "g\303\251ologie", "tomber en amour", "to fall in love", "visiter la Belgique", "to visit Belgium", "aller en Belgique", "recevoir un massage", "me faire donner un massage", "to receive a massage", "to give massages", "obtenir un casse-noix", "to obtain a nutcracker", "to go to France", "travelling to France", "to visit France", "visiter la France", "me faire des amis", "to make new friends", "apprendre une permaculture qui fonctionnerait au Qu\303\251bec", "to learn about a permaculture that would work in Quebec", "enseigner la permaculture", "to teach permaculture", "encyclop\303\251die de la permaculture", "encyclopedia of permaculture", "trouver des gens avec qui jouer au hockey", "to find people with whom to play hockey", "trouver quelqu'un qui s'y connait m\303\251canique", "to find someone who knows mechanics", "radish", "radis", "tomates", "tomatoes", "haricots", "green or yellow beans", "graines de citrouille", "pumpkin seeds", "lattitude , longitude", "46.812209 , -71.210801", "2 km", "nom", "Fred Mir", "Fr\303\251d\303\251ric Lemire", "nombro", "je ne suis pas un num\303\251ro", "courriel", "fredofromstart@gmail.com", "di\303\250te", "diet", "v\303\251g\303\251tarienne , locale , biologique", "vegetarian , local , organic", "home page", "page personnelle", "http://fredofromstart.wordpress.com/about/", "drawing", "faire illustrer un texte s\303\251rieux avec des illustrations humoristiques", "obtenir des illustrations humoristiques pour accompagner un texte autrement s\303\251rieux", "illustrations humoristiques", "funny illustrations", "illustrations", "cartoons", "bande(s) dessin\303\251e(s)", "orthographe fran\303\247aise", "\303\251crire sans fautes en fran\303\247ais", "r\303\251vision de texte en fran\303\247ais", "spell checking in French", "traduire de l'anglais au fran\303\247ais", "translate from English to French", "traduction de l'anglais au fran\303\247ais", "translation from English to French", "inventer des jeux de mots , des acronymes", "invent wordplays , acronyms", "construire une roulotte l\303\251g\303\250re pour v\303\251lo \303\251lectrique", "to build a light caravan for electrical bike", "astrofoil", "old bikes", "morceaux de v\303\251lo", "grosse toile", "coarse canvas", "matelas de mousse", "foam mattress", "construire une roulotte l\303\251g\303\250re", "build a light caravan", "rassemblements de la famille Arc-en-ciel", "Rainbow Gatherings", "d\303\251bats philosophiques", "philosophical debates", "programming", "programmation", "Ruby", "un bean-bag", "a bean-bag", "un sac de f\303\250ves (pour s'asseoir)", "un m\303\251langeur", "a mixer", "lampe de luminoth\303\251rapie", "luminotherapy lamp", "trouver des gens avec qui jouer au Go", "to find people with whom to play Go", "trouver quelqu'un qui s'y connait en code source libre", "trouver quelqu'un qui s'y connait en logiciel libre", "to find someone who is knowledgeable about open source software", "local fruit", "fruits locaux", "persil local", "local parsley", "tomates , concombres , courgettes , radis , haricots", "tomatoes , cucumbers , zucchinis , radishes , green or yellow beans", "graines de tournesol", "sunflower seeds", "granos de girasol", "farine de ma\303\257s", "maize flour", "basilic", "basil", "miel", "honey", "air", "to breathe", "de l'air", "respirer", "oxygen", "de l'oxyg\303\250ne", "lattitude , longitude", "45.45N 04.50E", "infini", "Julie Martineau", "terrebaleine@gmail.com", "v\303\251g\303\251tarienne , locale , biologique", "vegetarian , local , organic", "professional page", "page professionnelle", "www.ecritoire.net", "\303\251criture", "writing", "proofreading in French", "cr\303\251ation d'une communaut\303\251 en ligne pour les auteurs auto-publi\303\251s et/ou publi\303\251s en format \303\251lectronique", "creating an online community of authors interested in self-publishing and publishing ebooks", "cr\303\251er un r\303\251seau d'auteurs", "building an author's network", "d\303\251couvrir et visiter des communaut\303\251s explorant des alternatives sociales", "discovering and visiting communities exploring social alternatives", "tomates , concombres , c\303\251leri , radis , haricots", "tomatoes , cucumbers , celery , radishes , green or yellow beans", "Katia Proulx", "sexe", "gender", "f\303\251minin", "female", "adresse courrielle", "Firmament_de_Paix@yahoo.ca", "un mari pour toute la vie", "un \303\251poux pour toute la vie", "une femme pour toute la vie", "des amis pour aller se promener sur les plaines", "friends with whom to go walk on the Plains", "faire des pique-nique", "aller pique-niquer", "des amis pour aller patiner \303\240 la place d'Youville", "aller patiner sur la place d'Youville en bonne compagnie", "faire des randonn\303\251es de v\303\251lo \303\240 plusieurs", "se promener \303\240 bicyclette \303\240 plusieurs", "cercles de lecture", "soir\303\251es de po\303\251sie", "r\303\252ves", "dreams", "prendre des cours de danse", "suivre des cours de danse", "ateliers de reliure", "cours pour apprendre \303\240 faire des livres", "faire partie d'une chorale", "chanter dans une chorale", "ateliers d'art", "faire des tresses fran\303\247aises"]

$lexicon_infos = \
[{"+"=>6, "k"=>0, "w"=>true, "o"=>false, "e"=>[0], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>1, "w"=>true, "o"=>false, "e"=>[1], "<"=>[], "~"=>[]}, {"+"=>2, "k"=>2, "w"=>true, "o"=>false, "e"=>[2], "<"=>[], "~"=>[3]}, {"+"=>2, "k"=>3, "w"=>true, "o"=>false, "e"=>[2], "<"=>[], "~"=>[2]}, {"+"=>1, "k"=>4, "w"=>true, "o"=>false, "e"=>[3], "<"=>[], "~"=>[]}, {"+"=>2, "k"=>5, "w"=>true, "o"=>false, "e"=>[4], "<"=>[], "~"=>[]}, {"+"=>4, "k"=>6, "w"=>true, "o"=>false, "e"=>[5], "<"=>[], "~"=>[7, 19]}, {"+"=>2, "k"=>7, "w"=>true, "o"=>false, "e"=>[5], "<"=>[], "~"=>[6]}, {"+"=>3, "k"=>8, "w"=>true, "o"=>false, "e"=>[6], "<"=>[], "~"=>[36]}, {"+"=>1, "k"=>9, "w"=>true, "o"=>false, "e"=>[7], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>10, "w"=>true, "o"=>false, "e"=>[8], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>11, "w"=>true, "o"=>false, "e"=>[9], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>12, "w"=>true, "o"=>false, "e"=>[10], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>13, "w"=>true, "o"=>false, "e"=>[11], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>14, "w"=>true, "o"=>false, "e"=>[12], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>15, "w"=>true, "o"=>false, "e"=>[13], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>16, "w"=>true, "o"=>false, "e"=>[14], "<"=>[], "~"=>[17]}, {"+"=>1, "k"=>17, "w"=>true, "o"=>false, "e"=>[14], "<"=>[], "~"=>[16]}, {"+"=>2, "k"=>18, "w"=>true, "o"=>false, "e"=>[15], "<"=>[], "~"=>[35]}, {"+"=>1, "k"=>19, "w"=>true, "o"=>false, "e"=>[5], "<"=>[], "~"=>[6]}, {"+"=>1, "k"=>20, "w"=>true, "o"=>false, "e"=>[16], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>21, "w"=>true, "o"=>false, "e"=>[17], "<"=>[], "~"=>[22]}, {"+"=>3, "k"=>22, "w"=>true, "o"=>false, "e"=>[17], "<"=>[], "~"=>[21]}, {"+"=>1, "k"=>23, "w"=>true, "o"=>false, "e"=>[18], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>24, "w"=>true, "o"=>false, "e"=>[19], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>25, "w"=>true, "o"=>false, "e"=>[20], "<"=>[], "~"=>[26]}, {"+"=>3, "k"=>26, "w"=>true, "o"=>false, "e"=>[20], "<"=>[], "~"=>[25]}, {"+"=>1, "k"=>27, "w"=>true, "o"=>false, "e"=>[21], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>28, "w"=>true, "o"=>false, "e"=>[22], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>29, "w"=>true, "o"=>false, "e"=>[23], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>30, "w"=>true, "o"=>false, "e"=>[24], "<"=>[], "~"=>[31]}, {"+"=>1, "k"=>31, "w"=>true, "o"=>false, "e"=>[24], "<"=>[], "~"=>[30]}, {"+"=>1, "k"=>32, "w"=>true, "o"=>false, "e"=>[25], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>33, "w"=>true, "o"=>false, "e"=>[26], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>34, "w"=>true, "o"=>false, "e"=>[27], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>35, "w"=>true, "o"=>false, "e"=>[15], "<"=>[], "~"=>[18]}, {"+"=>1, "k"=>36, "w"=>true, "o"=>false, "e"=>[6], "<"=>[], "~"=>[8]}, {"+"=>3, "k"=>37, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[38, 91]}, {"+"=>5, "k"=>38, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[37, 221, 40]}, {"+"=>1, "k"=>39, "w"=>true, "o"=>false, "e"=>[29], "<"=>[], "~"=>[]}, {"+"=>5, "k"=>40, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[41, 93, 94, 221, 38, 224]}, {"+"=>1, "k"=>41, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[40]}, {"+"=>1, "k"=>42, "w"=>true, "o"=>false, "e"=>[30], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>43, "w"=>true, "o"=>false, "e"=>[31], "<"=>[], "~"=>[228, 229]}, {"+"=>1, "k"=>44, "w"=>true, "o"=>false, "e"=>[32], "<"=>[], "~"=>[45]}, {"+"=>1, "k"=>45, "w"=>true, "o"=>false, "e"=>[32], "<"=>[], "~"=>[44]}, {"+"=>1, "k"=>46, "w"=>true, "o"=>false, "e"=>[33], "<"=>[], "~"=>[47]}, {"+"=>1, "k"=>47, "w"=>true, "o"=>false, "e"=>[33], "<"=>[], "~"=>[46]}, {"+"=>1, "k"=>48, "w"=>true, "o"=>false, "e"=>[34], "<"=>[], "~"=>[49, 50]}, {"+"=>1, "k"=>49, "w"=>true, "o"=>false, "e"=>[34], "<"=>[], "~"=>[48, 50]}, {"+"=>1, "k"=>50, "w"=>true, "o"=>false, "e"=>[34], "<"=>[], "~"=>[48, 49]}, {"+"=>1, "k"=>51, "w"=>true, "o"=>false, "e"=>[35], "<"=>[], "~"=>[52]}, {"+"=>1, "k"=>52, "w"=>true, "o"=>false, "e"=>[35], "<"=>[], "~"=>[51]}, {"+"=>1, "k"=>53, "w"=>true, "o"=>false, "e"=>[36], "<"=>[], "~"=>[54]}, {"+"=>1, "k"=>54, "w"=>true, "o"=>false, "e"=>[36], "<"=>[], "~"=>[53]}, {"+"=>3, "k"=>55, "w"=>true, "o"=>false, "e"=>[37], "<"=>[], "~"=>[56, 235]}, {"+"=>3, "k"=>56, "w"=>true, "o"=>false, "e"=>[37], "<"=>[], "~"=>[55, 235]}, {"+"=>1, "k"=>57, "w"=>true, "o"=>false, "e"=>[38], "<"=>[], "~"=>[58]}, {"+"=>1, "k"=>58, "w"=>true, "o"=>false, "e"=>[38], "<"=>[], "~"=>[57]}, {"+"=>1, "k"=>59, "w"=>true, "o"=>false, "e"=>[39], "<"=>[], "~"=>[60]}, {"+"=>2, "k"=>60, "w"=>true, "o"=>false, "e"=>[39], "<"=>[], "~"=>[59, 256]}, {"+"=>3, "k"=>61, "w"=>true, "o"=>false, "e"=>[40], "<"=>[], "~"=>[62]}, {"+"=>3, "k"=>62, "w"=>true, "o"=>false, "e"=>[40], "<"=>[], "~"=>[61]}, {"+"=>2, "k"=>63, "w"=>true, "o"=>false, "e"=>[41], "<"=>[], "~"=>[64]}, {"+"=>1, "k"=>64, "w"=>true, "o"=>false, "e"=>[41], "<"=>[], "~"=>[63]}, {"+"=>2, "k"=>65, "w"=>true, "o"=>false, "e"=>[42], "<"=>[], "~"=>[66]}, {"+"=>1, "k"=>66, "w"=>true, "o"=>false, "e"=>[42], "<"=>[], "~"=>[65]}, {"+"=>2, "k"=>67, "w"=>true, "o"=>false, "e"=>[43], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>68, "w"=>true, "o"=>false, "e"=>[44], "<"=>[], "~"=>[69, 191]}, {"+"=>1, "k"=>69, "w"=>true, "o"=>false, "e"=>[44], "<"=>[], "~"=>[68]}, {"+"=>1, "k"=>70, "w"=>true, "o"=>false, "e"=>[45], "<"=>[], "~"=>[71, 72]}, {"+"=>1, "k"=>71, "w"=>true, "o"=>false, "e"=>[45], "<"=>[], "~"=>[70, 72]}, {"+"=>1, "k"=>72, "w"=>true, "o"=>false, "e"=>[45], "<"=>[], "~"=>[70, 71]}, {"+"=>1, "k"=>73, "w"=>true, "o"=>false, "e"=>[46], "<"=>[], "~"=>[74]}, {"+"=>1, "k"=>74, "w"=>true, "o"=>false, "e"=>[46], "<"=>[], "~"=>[73]}, {"+"=>2, "k"=>75, "w"=>true, "o"=>false, "e"=>[47], "<"=>[], "~"=>[76]}, {"+"=>2, "k"=>76, "w"=>true, "o"=>false, "e"=>[47], "<"=>[], "~"=>[75]}, {"+"=>1, "k"=>77, "w"=>true, "o"=>false, "e"=>[48], "<"=>[], "~"=>[78]}, {"+"=>1, "k"=>78, "w"=>true, "o"=>false, "e"=>[48], "<"=>[], "~"=>[77]}, {"+"=>1, "k"=>79, "w"=>true, "o"=>false, "e"=>[49], "<"=>[], "~"=>[80]}, {"+"=>1, "k"=>80, "w"=>true, "o"=>false, "e"=>[49], "<"=>[], "~"=>[79]}, {"+"=>1, "k"=>81, "w"=>true, "o"=>false, "e"=>[50], "<"=>[], "~"=>[82]}, {"+"=>1, "k"=>82, "w"=>true, "o"=>false, "e"=>[50], "<"=>[], "~"=>[81]}, {"+"=>1, "k"=>83, "w"=>true, "o"=>false, "e"=>[51], "<"=>[], "~"=>[84]}, {"+"=>1, "k"=>84, "w"=>true, "o"=>false, "e"=>[51], "<"=>[], "~"=>[83]}, {"+"=>1, "k"=>85, "w"=>true, "o"=>false, "e"=>[52], "<"=>[], "~"=>[86, 87]}, {"+"=>1, "k"=>86, "w"=>true, "o"=>false, "e"=>[52], "<"=>[], "~"=>[85, 87]}, {"+"=>1, "k"=>87, "w"=>true, "o"=>false, "e"=>[52], "<"=>[], "~"=>[85, 86]}, {"+"=>1, "k"=>88, "w"=>true, "o"=>false, "e"=>[53], "<"=>[], "~"=>[89]}, {"+"=>1, "k"=>89, "w"=>true, "o"=>false, "e"=>[53], "<"=>[], "~"=>[88]}, {"+"=>1, "k"=>90, "w"=>true, "o"=>false, "e"=>[54], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>91, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[37]}, {"+"=>1, "k"=>92, "w"=>true, "o"=>false, "e"=>[55], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>93, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[40, 94]}, {"+"=>1, "k"=>94, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[93, 40]}, {"+"=>1, "k"=>95, "w"=>true, "o"=>false, "e"=>[56], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>96, "w"=>true, "o"=>false, "e"=>[57], "<"=>[], "~"=>[97]}, {"+"=>1, "k"=>97, "w"=>true, "o"=>false, "e"=>[57], "<"=>[], "~"=>[96]}, {"+"=>1, "k"=>98, "w"=>true, "o"=>false, "e"=>[58], "<"=>[], "~"=>[99]}, {"+"=>1, "k"=>99, "w"=>true, "o"=>false, "e"=>[58], "<"=>[], "~"=>[98]}, {"+"=>1, "k"=>100, "w"=>true, "o"=>false, "e"=>[59], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>101, "w"=>true, "o"=>false, "e"=>[60], "<"=>[], "~"=>[102, 103]}, {"+"=>1, "k"=>102, "w"=>true, "o"=>false, "e"=>[60], "<"=>[], "~"=>[101, 103]}, {"+"=>1, "k"=>103, "w"=>true, "o"=>false, "e"=>[60], "<"=>[], "~"=>[101, 102]}, {"+"=>1, "k"=>104, "w"=>true, "o"=>false, "e"=>[61], "<"=>[], "~"=>[105]}, {"+"=>1, "k"=>105, "w"=>true, "o"=>false, "e"=>[61], "<"=>[], "~"=>[104]}, {"+"=>1, "k"=>106, "w"=>true, "o"=>false, "e"=>[62], "<"=>[], "~"=>[107]}, {"+"=>1, "k"=>107, "w"=>true, "o"=>false, "e"=>[62], "<"=>[], "~"=>[106]}, {"+"=>1, "k"=>108, "w"=>true, "o"=>false, "e"=>[63], "<"=>[], "~"=>[109]}, {"+"=>1, "k"=>109, "w"=>true, "o"=>false, "e"=>[63], "<"=>[], "~"=>[108]}, {"+"=>1, "k"=>110, "w"=>true, "o"=>false, "e"=>[64], "<"=>[], "~"=>[111]}, {"+"=>1, "k"=>111, "w"=>true, "o"=>false, "e"=>[64], "<"=>[], "~"=>[110]}, {"+"=>1, "k"=>112, "w"=>true, "o"=>false, "e"=>[65], "<"=>[], "~"=>[113]}, {"+"=>1, "k"=>113, "w"=>true, "o"=>false, "e"=>[65], "<"=>[], "~"=>[112]}, {"+"=>1, "k"=>114, "w"=>true, "o"=>false, "e"=>[66], "<"=>[], "~"=>[115, 116]}, {"+"=>1, "k"=>115, "w"=>true, "o"=>false, "e"=>[66], "<"=>[], "~"=>[114, 116]}, {"+"=>1, "k"=>116, "w"=>true, "o"=>false, "e"=>[66], "<"=>[], "~"=>[114, 115]}, {"+"=>1, "k"=>117, "w"=>true, "o"=>false, "e"=>[67], "<"=>[], "~"=>[118, 119]}, {"+"=>1, "k"=>118, "w"=>true, "o"=>false, "e"=>[67], "<"=>[], "~"=>[117, 119]}, {"+"=>1, "k"=>119, "w"=>true, "o"=>false, "e"=>[67], "<"=>[], "~"=>[117, 118]}, {"+"=>1, "k"=>120, "w"=>true, "o"=>false, "e"=>[68], "<"=>[], "~"=>[121]}, {"+"=>1, "k"=>121, "w"=>true, "o"=>false, "e"=>[68], "<"=>[], "~"=>[120]}, {"+"=>1, "k"=>122, "w"=>true, "o"=>false, "e"=>[69], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>123, "w"=>true, "o"=>false, "e"=>[70], "<"=>[], "~"=>[124, 125]}, {"+"=>1, "k"=>124, "w"=>true, "o"=>false, "e"=>[70], "<"=>[], "~"=>[123, 125]}, {"+"=>1, "k"=>125, "w"=>true, "o"=>false, "e"=>[70], "<"=>[], "~"=>[123, 124]}, {"+"=>1, "k"=>126, "w"=>true, "o"=>false, "e"=>[71], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>127, "w"=>true, "o"=>false, "e"=>[72], "<"=>[], "~"=>[128]}, {"+"=>1, "k"=>128, "w"=>true, "o"=>false, "e"=>[72], "<"=>[], "~"=>[127]}, {"+"=>1, "k"=>129, "w"=>true, "o"=>false, "e"=>[73], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>130, "w"=>true, "o"=>false, "e"=>[74], "<"=>[], "~"=>[131]}, {"+"=>1, "k"=>131, "w"=>true, "o"=>false, "e"=>[74], "<"=>[], "~"=>[130]}, {"+"=>1, "k"=>132, "w"=>true, "o"=>false, "e"=>[75], "<"=>[], "~"=>[133]}, {"+"=>2, "k"=>133, "w"=>true, "o"=>false, "e"=>[75], "<"=>[], "~"=>[132, 257]}, {"+"=>1, "k"=>134, "w"=>true, "o"=>false, "e"=>[76], "<"=>[], "~"=>[135]}, {"+"=>1, "k"=>135, "w"=>true, "o"=>false, "e"=>[76], "<"=>[], "~"=>[134]}, {"+"=>1, "k"=>136, "w"=>true, "o"=>false, "e"=>[77], "<"=>[], "~"=>[137]}, {"+"=>1, "k"=>137, "w"=>true, "o"=>false, "e"=>[77], "<"=>[], "~"=>[136]}, {"+"=>1, "k"=>138, "w"=>true, "o"=>false, "e"=>[78], "<"=>[], "~"=>[139]}, {"+"=>1, "k"=>139, "w"=>true, "o"=>false, "e"=>[78], "<"=>[], "~"=>[138]}, {"+"=>1, "k"=>140, "w"=>true, "o"=>false, "e"=>[79], "<"=>[], "~"=>[141]}, {"+"=>1, "k"=>141, "w"=>true, "o"=>false, "e"=>[79], "<"=>[], "~"=>[140]}, {"+"=>1, "k"=>142, "w"=>true, "o"=>false, "e"=>[80], "<"=>[], "~"=>[143]}, {"+"=>1, "k"=>143, "w"=>true, "o"=>false, "e"=>[80], "<"=>[], "~"=>[142]}, {"+"=>1, "k"=>144, "w"=>true, "o"=>false, "e"=>[81], "<"=>[], "~"=>[145]}, {"+"=>2, "k"=>145, "w"=>true, "o"=>false, "e"=>[81], "<"=>[], "~"=>[144, 182]}, {"+"=>1, "k"=>146, "w"=>true, "o"=>false, "e"=>[82], "<"=>[], "~"=>[147]}, {"+"=>1, "k"=>147, "w"=>true, "o"=>false, "e"=>[82], "<"=>[], "~"=>[146]}, {"+"=>1, "k"=>148, "w"=>true, "o"=>false, "e"=>[83], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>149, "w"=>true, "o"=>false, "e"=>[84], "<"=>[], "~"=>[150]}, {"+"=>1, "k"=>150, "w"=>true, "o"=>false, "e"=>[84], "<"=>[], "~"=>[149]}, {"+"=>1, "k"=>151, "w"=>true, "o"=>false, "e"=>[85], "<"=>[], "~"=>[152]}, {"+"=>1, "k"=>152, "w"=>true, "o"=>false, "e"=>[85], "<"=>[], "~"=>[151]}, {"+"=>1, "k"=>153, "w"=>true, "o"=>false, "e"=>[86], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>154, "w"=>true, "o"=>false, "e"=>[87], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>155, "w"=>true, "o"=>false, "e"=>[88], "<"=>[], "~"=>[156]}, {"+"=>3, "k"=>156, "w"=>true, "o"=>false, "e"=>[88], "<"=>[], "~"=>[155]}, {"+"=>1, "k"=>157, "w"=>true, "o"=>false, "e"=>[89], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>158, "w"=>true, "o"=>false, "e"=>[90], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>159, "w"=>true, "o"=>false, "e"=>[91], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>160, "w"=>true, "o"=>false, "e"=>[92], "<"=>[], "~"=>[161, 226]}, {"+"=>1, "k"=>161, "w"=>true, "o"=>false, "e"=>[92], "<"=>[], "~"=>[160]}, {"+"=>1, "k"=>162, "w"=>true, "o"=>false, "e"=>[93], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>163, "w"=>true, "o"=>false, "e"=>[94], "<"=>[], "~"=>[164]}, {"+"=>1, "k"=>164, "w"=>true, "o"=>false, "e"=>[94], "<"=>[], "~"=>[163]}, {"+"=>1, "k"=>165, "w"=>true, "o"=>false, "e"=>[95], "<"=>[], "~"=>[166]}, {"+"=>1, "k"=>166, "w"=>true, "o"=>false, "e"=>[95], "<"=>[], "~"=>[165]}, {"+"=>1, "k"=>167, "w"=>true, "o"=>false, "e"=>[96], "<"=>[], "~"=>[168]}, {"+"=>1, "k"=>168, "w"=>true, "o"=>false, "e"=>[96], "<"=>[], "~"=>[167]}, {"+"=>1, "k"=>169, "w"=>true, "o"=>false, "e"=>[97], "<"=>[], "~"=>[170]}, {"+"=>1, "k"=>170, "w"=>true, "o"=>false, "e"=>[97], "<"=>[], "~"=>[169]}, {"+"=>1, "k"=>171, "w"=>true, "o"=>false, "e"=>[98], "<"=>[], "~"=>[172]}, {"+"=>1, "k"=>172, "w"=>true, "o"=>false, "e"=>[98], "<"=>[], "~"=>[171]}, {"+"=>1, "k"=>173, "w"=>true, "o"=>false, "e"=>[99], "<"=>[], "~"=>[174]}, {"+"=>1, "k"=>174, "w"=>true, "o"=>false, "e"=>[99], "<"=>[], "~"=>[173]}, {"+"=>1, "k"=>175, "w"=>true, "o"=>false, "e"=>[100], "<"=>[], "~"=>[176]}, {"+"=>1, "k"=>176, "w"=>true, "o"=>false, "e"=>[100], "<"=>[], "~"=>[175]}, {"+"=>1, "k"=>177, "w"=>true, "o"=>false, "e"=>[101], "<"=>[], "~"=>[178, 179, 180]}, {"+"=>1, "k"=>178, "w"=>true, "o"=>false, "e"=>[101], "<"=>[], "~"=>[177, 179, 180]}, {"+"=>1, "k"=>179, "w"=>true, "o"=>false, "e"=>[101], "<"=>[], "~"=>[177, 178, 180]}, {"+"=>1, "k"=>180, "w"=>true, "o"=>false, "e"=>[101], "<"=>[], "~"=>[177, 178, 179]}, {"+"=>1, "k"=>181, "w"=>true, "o"=>false, "e"=>[102], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>182, "w"=>true, "o"=>false, "e"=>[81], "<"=>[], "~"=>[145]}, {"+"=>1, "k"=>183, "w"=>true, "o"=>false, "e"=>[103], "<"=>[], "~"=>[184]}, {"+"=>1, "k"=>184, "w"=>true, "o"=>false, "e"=>[103], "<"=>[], "~"=>[183]}, {"+"=>1, "k"=>185, "w"=>true, "o"=>false, "e"=>[104], "<"=>[], "~"=>[186, 187]}, {"+"=>1, "k"=>186, "w"=>true, "o"=>false, "e"=>[104], "<"=>[], "~"=>[185, 187]}, {"+"=>1, "k"=>187, "w"=>true, "o"=>false, "e"=>[104], "<"=>[], "~"=>[185, 186]}, {"+"=>2, "k"=>188, "w"=>true, "o"=>false, "e"=>[105], "<"=>[], "~"=>[189, 190]}, {"+"=>2, "k"=>189, "w"=>true, "o"=>false, "e"=>[105], "<"=>[], "~"=>[188, 190]}, {"+"=>2, "k"=>190, "w"=>true, "o"=>false, "e"=>[105], "<"=>[], "~"=>[188, 189]}, {"+"=>2, "k"=>191, "w"=>true, "o"=>false, "e"=>[44], "<"=>[], "~"=>[68]}, {"+"=>1, "k"=>192, "w"=>true, "o"=>false, "e"=>[106], "<"=>[], "~"=>[193]}, {"+"=>1, "k"=>193, "w"=>true, "o"=>false, "e"=>[106], "<"=>[], "~"=>[192]}, {"+"=>1, "k"=>194, "w"=>true, "o"=>false, "e"=>[107], "<"=>[], "~"=>[195, 196, 197]}, {"+"=>1, "k"=>195, "w"=>true, "o"=>false, "e"=>[107], "<"=>[], "~"=>[194, 196, 197]}, {"+"=>1, "k"=>196, "w"=>true, "o"=>false, "e"=>[107], "<"=>[], "~"=>[194, 195, 197]}, {"+"=>1, "k"=>197, "w"=>true, "o"=>false, "e"=>[107], "<"=>[], "~"=>[194, 195, 196]}, {"+"=>1, "k"=>198, "w"=>true, "o"=>false, "e"=>[108], "<"=>[], "~"=>[199]}, {"+"=>1, "k"=>199, "w"=>true, "o"=>false, "e"=>[108], "<"=>[], "~"=>[198]}, {"+"=>2, "k"=>200, "w"=>true, "o"=>false, "e"=>[109], "<"=>[], "~"=>[201]}, {"+"=>2, "k"=>201, "w"=>true, "o"=>false, "e"=>[109], "<"=>[], "~"=>[200]}, {"+"=>2, "k"=>202, "w"=>true, "o"=>false, "e"=>[110], "<"=>[], "~"=>[203]}, {"+"=>2, "k"=>203, "w"=>true, "o"=>false, "e"=>[110], "<"=>[], "~"=>[202]}, {"+"=>2, "k"=>204, "w"=>true, "o"=>false, "e"=>[111], "<"=>[], "~"=>[205]}, {"+"=>2, "k"=>205, "w"=>true, "o"=>false, "e"=>[111], "<"=>[], "~"=>[204]}, {"+"=>1, "k"=>206, "w"=>true, "o"=>false, "e"=>[112], "<"=>[], "~"=>[207]}, {"+"=>1, "k"=>207, "w"=>true, "o"=>false, "e"=>[112], "<"=>[], "~"=>[206]}, {"+"=>1, "k"=>208, "w"=>true, "o"=>false, "e"=>[113], "<"=>[], "~"=>[209]}, {"+"=>1, "k"=>209, "w"=>true, "o"=>false, "e"=>[113], "<"=>[], "~"=>[208]}, {"+"=>1, "k"=>210, "w"=>true, "o"=>false, "e"=>[114], "<"=>[], "~"=>[211]}, {"+"=>1, "k"=>211, "w"=>true, "o"=>false, "e"=>[114], "<"=>[], "~"=>[210]}, {"+"=>1, "k"=>212, "w"=>true, "o"=>false, "e"=>[115], "<"=>[], "~"=>[213]}, {"+"=>1, "k"=>213, "w"=>true, "o"=>false, "e"=>[115], "<"=>[], "~"=>[212]}, {"+"=>1, "k"=>214, "w"=>true, "o"=>false, "e"=>[116], "<"=>[], "~"=>[215]}, {"+"=>1, "k"=>215, "w"=>true, "o"=>false, "e"=>[116], "<"=>[], "~"=>[214]}, {"+"=>1, "k"=>216, "w"=>true, "o"=>false, "e"=>[117], "<"=>[], "~"=>[217]}, {"+"=>1, "k"=>217, "w"=>true, "o"=>false, "e"=>[117], "<"=>[], "~"=>[216]}, {"+"=>1, "k"=>218, "w"=>true, "o"=>false, "e"=>[118], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>219, "w"=>true, "o"=>false, "e"=>[119], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>220, "w"=>true, "o"=>false, "e"=>[120], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>221, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[38, 40]}, {"+"=>1, "k"=>222, "w"=>true, "o"=>false, "e"=>[121], "<"=>[], "~"=>[223]}, {"+"=>1, "k"=>223, "w"=>true, "o"=>false, "e"=>[121], "<"=>[], "~"=>[222]}, {"+"=>1, "k"=>224, "w"=>true, "o"=>false, "e"=>[28], "<"=>[], "~"=>[40]}, {"+"=>1, "k"=>225, "w"=>true, "o"=>false, "e"=>[122], "<"=>[], "~"=>[]}, {"+"=>3, "k"=>226, "w"=>true, "o"=>false, "e"=>[92], "<"=>[], "~"=>[160, 330]}, {"+"=>1, "k"=>227, "w"=>true, "o"=>false, "e"=>[123], "<"=>[], "~"=>[]}, {"+"=>2, "k"=>228, "w"=>true, "o"=>false, "e"=>[31], "<"=>[], "~"=>[43, 229]}, {"+"=>2, "k"=>229, "w"=>true, "o"=>false, "e"=>[31], "<"=>[], "~"=>[43, 228]}, {"+"=>1, "k"=>230, "w"=>true, "o"=>false, "e"=>[124], "<"=>[], "~"=>[231]}, {"+"=>1, "k"=>231, "w"=>true, "o"=>false, "e"=>[124], "<"=>[], "~"=>[230]}, {"+"=>1, "k"=>232, "w"=>true, "o"=>false, "e"=>[125], "<"=>[], "~"=>[233]}, {"+"=>1, "k"=>233, "w"=>true, "o"=>false, "e"=>[125], "<"=>[], "~"=>[232]}, {"+"=>1, "k"=>234, "w"=>true, "o"=>false, "e"=>[126], "<"=>[], "~"=>[]}, {"+"=>2, "k"=>235, "w"=>true, "o"=>false, "e"=>[37], "<"=>[], "~"=>[56, 55]}, {"+"=>1, "k"=>236, "w"=>true, "o"=>false, "e"=>[127], "<"=>[], "~"=>[237]}, {"+"=>1, "k"=>237, "w"=>true, "o"=>false, "e"=>[127], "<"=>[], "~"=>[236]}, {"+"=>1, "k"=>238, "w"=>true, "o"=>false, "e"=>[128], "<"=>[], "~"=>[239]}, {"+"=>1, "k"=>239, "w"=>true, "o"=>false, "e"=>[128], "<"=>[], "~"=>[238]}, {"+"=>1, "k"=>240, "w"=>true, "o"=>false, "e"=>[129], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>241, "w"=>true, "o"=>false, "e"=>[130], "<"=>[], "~"=>[242]}, {"+"=>1, "k"=>242, "w"=>true, "o"=>false, "e"=>[130], "<"=>[], "~"=>[241]}, {"+"=>2, "k"=>243, "w"=>true, "o"=>false, "e"=>[131], "<"=>[], "~"=>[244, 245, 246, 316]}, {"+"=>2, "k"=>244, "w"=>true, "o"=>false, "e"=>[131], "<"=>[], "~"=>[243, 245, 246, 316]}, {"+"=>2, "k"=>245, "w"=>true, "o"=>false, "e"=>[131], "<"=>[], "~"=>[243, 244, 246, 316]}, {"+"=>1, "k"=>246, "w"=>true, "o"=>false, "e"=>[131], "<"=>[], "~"=>[243, 244, 245]}, {"+"=>2, "k"=>247, "w"=>true, "o"=>false, "e"=>[132], "<"=>[], "~"=>[248]}, {"+"=>2, "k"=>248, "w"=>true, "o"=>false, "e"=>[132], "<"=>[], "~"=>[247]}, {"+"=>2, "k"=>249, "w"=>true, "o"=>false, "e"=>[133], "<"=>[], "~"=>[250]}, {"+"=>2, "k"=>250, "w"=>true, "o"=>false, "e"=>[133], "<"=>[], "~"=>[249]}, {"+"=>1, "k"=>251, "w"=>true, "o"=>false, "e"=>[134], "<"=>[], "~"=>[252]}, {"+"=>1, "k"=>252, "w"=>true, "o"=>false, "e"=>[134], "<"=>[], "~"=>[251]}, {"+"=>1, "k"=>253, "w"=>true, "o"=>false, "e"=>[135], "<"=>[], "~"=>[254]}, {"+"=>1, "k"=>254, "w"=>true, "o"=>false, "e"=>[135], "<"=>[], "~"=>[253]}, {"+"=>1, "k"=>255, "w"=>true, "o"=>false, "e"=>[136], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>256, "w"=>true, "o"=>false, "e"=>[39], "<"=>[], "~"=>[60]}, {"+"=>1, "k"=>257, "w"=>true, "o"=>false, "e"=>[75], "<"=>[], "~"=>[133]}, {"+"=>1, "k"=>258, "w"=>true, "o"=>false, "e"=>[137], "<"=>[], "~"=>[259]}, {"+"=>1, "k"=>259, "w"=>true, "o"=>false, "e"=>[137], "<"=>[], "~"=>[258]}, {"+"=>1, "k"=>260, "w"=>true, "o"=>false, "e"=>[138], "<"=>[], "~"=>[261]}, {"+"=>1, "k"=>261, "w"=>true, "o"=>false, "e"=>[138], "<"=>[], "~"=>[260]}, {"+"=>1, "k"=>262, "w"=>true, "o"=>false, "e"=>[139], "<"=>[], "~"=>[263]}, {"+"=>1, "k"=>263, "w"=>true, "o"=>false, "e"=>[139], "<"=>[], "~"=>[262]}, {"+"=>1, "k"=>264, "w"=>true, "o"=>false, "e"=>[140], "<"=>[], "~"=>[265]}, {"+"=>1, "k"=>265, "w"=>true, "o"=>false, "e"=>[140], "<"=>[], "~"=>[264]}, {"+"=>1, "k"=>266, "w"=>true, "o"=>false, "e"=>[141], "<"=>[], "~"=>[267]}, {"+"=>1, "k"=>267, "w"=>true, "o"=>false, "e"=>[141], "<"=>[], "~"=>[266]}, {"+"=>1, "k"=>268, "w"=>true, "o"=>false, "e"=>[142], "<"=>[], "~"=>[269]}, {"+"=>1, "k"=>269, "w"=>true, "o"=>false, "e"=>[142], "<"=>[], "~"=>[268]}, {"+"=>1, "k"=>270, "w"=>true, "o"=>false, "e"=>[143], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>271, "w"=>true, "o"=>false, "e"=>[144], "<"=>[], "~"=>[272, 273]}, {"+"=>1, "k"=>272, "w"=>true, "o"=>false, "e"=>[144], "<"=>[], "~"=>[271, 273]}, {"+"=>1, "k"=>273, "w"=>true, "o"=>false, "e"=>[144], "<"=>[], "~"=>[271, 272]}, {"+"=>1, "k"=>274, "w"=>true, "o"=>false, "e"=>[145], "<"=>[], "~"=>[275]}, {"+"=>1, "k"=>275, "w"=>true, "o"=>false, "e"=>[145], "<"=>[], "~"=>[274]}, {"+"=>1, "k"=>276, "w"=>true, "o"=>false, "e"=>[146], "<"=>[], "~"=>[277]}, {"+"=>1, "k"=>277, "w"=>true, "o"=>false, "e"=>[146], "<"=>[], "~"=>[276]}, {"+"=>1, "k"=>278, "w"=>true, "o"=>false, "e"=>[147], "<"=>[], "~"=>[279]}, {"+"=>1, "k"=>279, "w"=>true, "o"=>false, "e"=>[147], "<"=>[], "~"=>[278]}, {"+"=>1, "k"=>280, "w"=>true, "o"=>false, "e"=>[148], "<"=>[], "~"=>[281, 282]}, {"+"=>1, "k"=>281, "w"=>true, "o"=>false, "e"=>[148], "<"=>[], "~"=>[280, 282]}, {"+"=>1, "k"=>282, "w"=>true, "o"=>false, "e"=>[148], "<"=>[], "~"=>[280, 281]}, {"+"=>2, "k"=>283, "w"=>true, "o"=>false, "e"=>[149], "<"=>[], "~"=>[284]}, {"+"=>2, "k"=>284, "w"=>true, "o"=>false, "e"=>[149], "<"=>[], "~"=>[283]}, {"+"=>2, "k"=>285, "w"=>true, "o"=>false, "e"=>[150], "<"=>[], "~"=>[286]}, {"+"=>2, "k"=>286, "w"=>true, "o"=>false, "e"=>[150], "<"=>[], "~"=>[285]}, {"+"=>1, "k"=>287, "w"=>true, "o"=>false, "e"=>[151], "<"=>[], "~"=>[288]}, {"+"=>1, "k"=>288, "w"=>true, "o"=>false, "e"=>[151], "<"=>[], "~"=>[287]}, {"+"=>2, "k"=>289, "w"=>true, "o"=>false, "e"=>[152], "<"=>[], "~"=>[290, 291]}, {"+"=>2, "k"=>290, "w"=>true, "o"=>false, "e"=>[152], "<"=>[], "~"=>[289, 291]}, {"+"=>1, "k"=>291, "w"=>true, "o"=>false, "e"=>[152], "<"=>[], "~"=>[289, 290]}, {"+"=>2, "k"=>292, "w"=>true, "o"=>false, "e"=>[153], "<"=>[], "~"=>[293]}, {"+"=>2, "k"=>293, "w"=>true, "o"=>false, "e"=>[153], "<"=>[], "~"=>[292]}, {"+"=>2, "k"=>294, "w"=>true, "o"=>false, "e"=>[154], "<"=>[], "~"=>[295]}, {"+"=>2, "k"=>295, "w"=>true, "o"=>false, "e"=>[154], "<"=>[], "~"=>[294]}, {"+"=>2, "k"=>296, "w"=>true, "o"=>false, "e"=>[155], "<"=>[], "~"=>[297]}, {"+"=>2, "k"=>297, "w"=>true, "o"=>false, "e"=>[155], "<"=>[], "~"=>[296]}, {"+"=>1, "k"=>298, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[299, 300, 301, 302, 303]}, {"+"=>1, "k"=>299, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[298, 300, 301, 302, 303]}, {"+"=>1, "k"=>300, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[298, 299, 301, 302, 303]}, {"+"=>1, "k"=>301, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[298, 299, 300, 302, 303]}, {"+"=>1, "k"=>302, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[298, 299, 300, 301, 303]}, {"+"=>1, "k"=>303, "w"=>true, "o"=>false, "e"=>[156], "<"=>[], "~"=>[298, 299, 300, 301, 302]}, {"+"=>1, "k"=>304, "w"=>true, "o"=>false, "e"=>[157], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>305, "w"=>true, "o"=>false, "e"=>[158], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>306, "w"=>true, "o"=>false, "e"=>[159], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>307, "w"=>true, "o"=>false, "e"=>[160], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>308, "w"=>true, "o"=>false, "e"=>[161], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>309, "w"=>true, "o"=>false, "e"=>[162], "<"=>[], "~"=>[310]}, {"+"=>1, "k"=>310, "w"=>true, "o"=>false, "e"=>[162], "<"=>[], "~"=>[309]}, {"+"=>1, "k"=>311, "w"=>true, "o"=>false, "e"=>[163], "<"=>[], "~"=>[312]}, {"+"=>1, "k"=>312, "w"=>true, "o"=>false, "e"=>[163], "<"=>[], "~"=>[311]}, {"+"=>1, "k"=>313, "w"=>true, "o"=>false, "e"=>[164], "<"=>[], "~"=>[]}, {"+"=>2, "k"=>314, "w"=>true, "o"=>false, "e"=>[165], "<"=>[], "~"=>[315]}, {"+"=>2, "k"=>315, "w"=>true, "o"=>false, "e"=>[165], "<"=>[], "~"=>[314]}, {"+"=>1, "k"=>316, "w"=>true, "o"=>false, "e"=>[131], "<"=>[], "~"=>[243, 244, 245]}, {"+"=>1, "k"=>317, "w"=>true, "o"=>false, "e"=>[166], "<"=>[], "~"=>[318]}, {"+"=>1, "k"=>318, "w"=>true, "o"=>false, "e"=>[166], "<"=>[], "~"=>[317]}, {"+"=>1, "k"=>319, "w"=>true, "o"=>false, "e"=>[167], "<"=>[], "~"=>[320]}, {"+"=>1, "k"=>320, "w"=>true, "o"=>false, "e"=>[167], "<"=>[], "~"=>[319]}, {"+"=>1, "k"=>321, "w"=>true, "o"=>false, "e"=>[168], "<"=>[], "~"=>[322]}, {"+"=>1, "k"=>322, "w"=>true, "o"=>false, "e"=>[168], "<"=>[], "~"=>[321]}, {"+"=>1, "k"=>323, "w"=>true, "o"=>false, "e"=>[169], "<"=>[], "~"=>[324]}, {"+"=>1, "k"=>324, "w"=>true, "o"=>false, "e"=>[169], "<"=>[], "~"=>[323]}, {"+"=>1, "k"=>325, "w"=>true, "o"=>false, "e"=>[170], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>326, "w"=>true, "o"=>false, "e"=>[171], "<"=>[], "~"=>[327]}, {"+"=>1, "k"=>327, "w"=>true, "o"=>false, "e"=>[171], "<"=>[], "~"=>[326]}, {"+"=>1, "k"=>328, "w"=>true, "o"=>false, "e"=>[172], "<"=>[], "~"=>[329]}, {"+"=>1, "k"=>329, "w"=>true, "o"=>false, "e"=>[172], "<"=>[], "~"=>[328]}, {"+"=>1, "k"=>330, "w"=>true, "o"=>false, "e"=>[92], "<"=>[], "~"=>[226]}, {"+"=>1, "k"=>331, "w"=>true, "o"=>false, "e"=>[173], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>332, "w"=>true, "o"=>false, "e"=>[174], "<"=>[], "~"=>[333]}, {"+"=>1, "k"=>333, "w"=>true, "o"=>false, "e"=>[174], "<"=>[], "~"=>[332]}, {"+"=>1, "k"=>334, "w"=>true, "o"=>false, "e"=>[175], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>335, "w"=>true, "o"=>false, "e"=>[176], "<"=>[], "~"=>[336]}, {"+"=>1, "k"=>336, "w"=>true, "o"=>false, "e"=>[176], "<"=>[], "~"=>[335]}, {"+"=>1, "k"=>337, "w"=>true, "o"=>false, "e"=>[177], "<"=>[], "~"=>[338]}, {"+"=>1, "k"=>338, "w"=>true, "o"=>false, "e"=>[177], "<"=>[], "~"=>[337]}, {"+"=>1, "k"=>339, "w"=>true, "o"=>false, "e"=>[178], "<"=>[], "~"=>[340]}, {"+"=>1, "k"=>340, "w"=>true, "o"=>false, "e"=>[178], "<"=>[], "~"=>[339]}, {"+"=>1, "k"=>341, "w"=>true, "o"=>false, "e"=>[179], "<"=>[], "~"=>[342]}, {"+"=>1, "k"=>342, "w"=>true, "o"=>false, "e"=>[179], "<"=>[], "~"=>[341]}, {"+"=>1, "k"=>343, "w"=>true, "o"=>false, "e"=>[180], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>344, "w"=>true, "o"=>false, "e"=>[181], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>345, "w"=>true, "o"=>false, "e"=>[182], "<"=>[], "~"=>[346]}, {"+"=>1, "k"=>346, "w"=>true, "o"=>false, "e"=>[182], "<"=>[], "~"=>[345]}, {"+"=>1, "k"=>347, "w"=>true, "o"=>false, "e"=>[183], "<"=>[], "~"=>[348]}, {"+"=>1, "k"=>348, "w"=>true, "o"=>false, "e"=>[183], "<"=>[], "~"=>[347]}, {"+"=>1, "k"=>349, "w"=>true, "o"=>false, "e"=>[184], "<"=>[], "~"=>[350]}, {"+"=>1, "k"=>350, "w"=>true, "o"=>false, "e"=>[184], "<"=>[], "~"=>[349]}, {"+"=>1, "k"=>351, "w"=>true, "o"=>false, "e"=>[185], "<"=>[], "~"=>[352]}, {"+"=>1, "k"=>352, "w"=>true, "o"=>false, "e"=>[185], "<"=>[], "~"=>[351]}, {"+"=>1, "k"=>353, "w"=>true, "o"=>false, "e"=>[186], "<"=>[], "~"=>[]}, {"+"=>1, "k"=>354, "w"=>true, "o"=>false, "e"=>[187], "<"=>[], "~"=>[]}]

$elements = \
[{"@"=>0, "k"=>0, "#"=>[], "%"=>0.0, "~"=>[0]}, {"@"=>0, "k"=>1, "#"=>[], "%"=>0.0, "~"=>[1]}, {"@"=>2, "k"=>2, "#"=>[{"@"=>2, "-"=>[3, 2]}], "%"=>1.0, "~"=>[2, 3]}, {"@"=>0, "k"=>3, "#"=>[], "%"=>0.0, "~"=>[4]}, {"@"=>0, "k"=>4, "#"=>[], "%"=>0.0, "~"=>[5]}, {"@"=>3, "k"=>5, "#"=>[{"@"=>2, "-"=>[7, 6]}, {"@"=>1, "-"=>[19, 6]}], "%"=>0.666666666666667, "~"=>[6, 7, 19]}, {"@"=>1, "k"=>6, "#"=>[{"@"=>1, "-"=>[36, 8]}], "%"=>1.0, "~"=>[8, 36]}, {"@"=>0, "k"=>7, "#"=>[], "%"=>0.0, "~"=>[9]}, {"@"=>0, "k"=>8, "#"=>[], "%"=>0.0, "~"=>[10]}, {"@"=>0, "k"=>9, "#"=>[], "%"=>0.0, "~"=>[11]}, {"@"=>0, "k"=>10, "#"=>[], "%"=>0.0, "~"=>[12]}, {"@"=>0, "k"=>11, "#"=>[], "%"=>0.0, "~"=>[13]}, {"@"=>0, "k"=>12, "#"=>[], "%"=>0.0, "~"=>[14]}, {"@"=>0, "k"=>13, "#"=>[], "%"=>0.0, "~"=>[15]}, {"@"=>1, "k"=>14, "#"=>[{"@"=>1, "-"=>[17, 16]}], "%"=>1.0, "~"=>[16, 17]}, {"@"=>1, "k"=>15, "#"=>[{"@"=>1, "-"=>[35, 18]}], "%"=>1.0, "~"=>[18, 35]}, {"@"=>0, "k"=>16, "#"=>[], "%"=>0.0, "~"=>[20]}, {"@"=>3, "k"=>17, "#"=>[{"@"=>3, "-"=>[22, 21]}], "%"=>1.0, "~"=>[21, 22]}, {"@"=>0, "k"=>18, "#"=>[], "%"=>0.0, "~"=>[23]}, {"@"=>0, "k"=>19, "#"=>[], "%"=>0.0, "~"=>[24]}, {"@"=>3, "k"=>20, "#"=>[{"@"=>3, "-"=>[26, 25]}], "%"=>1.0, "~"=>[25, 26]}, {"@"=>0, "k"=>21, "#"=>[], "%"=>0.0, "~"=>[27]}, {"@"=>0, "k"=>22, "#"=>[], "%"=>0.0, "~"=>[28]}, {"@"=>0, "k"=>23, "#"=>[], "%"=>0.0, "~"=>[29]}, {"@"=>1, "k"=>24, "#"=>[{"@"=>1, "-"=>[31, 30]}], "%"=>1.0, "~"=>[30, 31]}, {"@"=>0, "k"=>25, "#"=>[], "%"=>0.0, "~"=>[32]}, {"@"=>0, "k"=>26, "#"=>[], "%"=>0.0, "~"=>[33]}, {"@"=>0, "k"=>27, "#"=>[], "%"=>0.0, "~"=>[34]}, {"@"=>15, "k"=>28, "#"=>[{"@"=>2, "-"=>[38, 37]}, {"@"=>2, "-"=>[40, 38]}, {"@"=>1, "-"=>[41, 40]}, {"@"=>1, "-"=>[91, 37]}, {"@"=>1, "-"=>[93, 40]}, {"@"=>1, "-"=>[94, 40]}, {"@"=>1, "-"=>[94, 93]}, {"@"=>3, "-"=>[221, 38]}, {"@"=>2, "-"=>[221, 40]}, {"@"=>1, "-"=>[224, 40]}], "%"=>0.277777777777778, "~"=>[37, 38, 40, 41, 91, 93, 94, 221, 224]}, {"@"=>0, "k"=>29, "#"=>[], "%"=>0.0, "~"=>[39]}, {"@"=>0, "k"=>30, "#"=>[], "%"=>0.0, "~"=>[42]}, {"@"=>6, "k"=>31, "#"=>[{"@"=>2, "-"=>[228, 43]}, {"@"=>2, "-"=>[229, 43]}, {"@"=>2, "-"=>[229, 228]}], "%"=>1.0, "~"=>[43, 228, 229]}, {"@"=>1, "k"=>32, "#"=>[{"@"=>1, "-"=>[45, 44]}], "%"=>1.0, "~"=>[44, 45]}, {"@"=>1, "k"=>33, "#"=>[{"@"=>1, "-"=>[47, 46]}], "%"=>1.0, "~"=>[46, 47]}, {"@"=>3, "k"=>34, "#"=>[{"@"=>1, "-"=>[49, 48]}, {"@"=>1, "-"=>[50, 48]}, {"@"=>1, "-"=>[50, 49]}], "%"=>1.0, "~"=>[48, 49, 50]}, {"@"=>1, "k"=>35, "#"=>[{"@"=>1, "-"=>[52, 51]}], "%"=>1.0, "~"=>[51, 52]}, {"@"=>1, "k"=>36, "#"=>[{"@"=>1, "-"=>[54, 53]}], "%"=>1.0, "~"=>[53, 54]}, {"@"=>7, "k"=>37, "#"=>[{"@"=>3, "-"=>[56, 55]}, {"@"=>2, "-"=>[235, 55]}, {"@"=>2, "-"=>[235, 56]}], "%"=>1.0, "~"=>[55, 56, 235]}, {"@"=>1, "k"=>38, "#"=>[{"@"=>1, "-"=>[58, 57]}], "%"=>1.0, "~"=>[57, 58]}, {"@"=>2, "k"=>39, "#"=>[{"@"=>1, "-"=>[60, 59]}, {"@"=>1, "-"=>[256, 60]}], "%"=>0.666666666666667, "~"=>[59, 60, 256]}, {"@"=>3, "k"=>40, "#"=>[{"@"=>3, "-"=>[62, 61]}], "%"=>1.0, "~"=>[61, 62]}, {"@"=>1, "k"=>41, "#"=>[{"@"=>1, "-"=>[64, 63]}], "%"=>1.0, "~"=>[63, 64]}, {"@"=>1, "k"=>42, "#"=>[{"@"=>1, "-"=>[66, 65]}], "%"=>1.0, "~"=>[65, 66]}, {"@"=>0, "k"=>43, "#"=>[], "%"=>0.0, "~"=>[67]}, {"@"=>3, "k"=>44, "#"=>[{"@"=>1, "-"=>[69, 68]}, {"@"=>2, "-"=>[191, 68]}], "%"=>0.666666666666667, "~"=>[68, 69, 191]}, {"@"=>3, "k"=>45, "#"=>[{"@"=>1, "-"=>[71, 70]}, {"@"=>1, "-"=>[72, 70]}, {"@"=>1, "-"=>[72, 71]}], "%"=>1.0, "~"=>[70, 71, 72]}, {"@"=>1, "k"=>46, "#"=>[{"@"=>1, "-"=>[74, 73]}], "%"=>1.0, "~"=>[73, 74]}, {"@"=>2, "k"=>47, "#"=>[{"@"=>2, "-"=>[76, 75]}], "%"=>1.0, "~"=>[75, 76]}, {"@"=>1, "k"=>48, "#"=>[{"@"=>1, "-"=>[78, 77]}], "%"=>1.0, "~"=>[77, 78]}, {"@"=>1, "k"=>49, "#"=>[{"@"=>1, "-"=>[80, 79]}], "%"=>1.0, "~"=>[79, 80]}, {"@"=>1, "k"=>50, "#"=>[{"@"=>1, "-"=>[82, 81]}], "%"=>1.0, "~"=>[81, 82]}, {"@"=>1, "k"=>51, "#"=>[{"@"=>1, "-"=>[84, 83]}], "%"=>1.0, "~"=>[83, 84]}, {"@"=>3, "k"=>52, "#"=>[{"@"=>1, "-"=>[86, 85]}, {"@"=>1, "-"=>[87, 85]}, {"@"=>1, "-"=>[87, 86]}], "%"=>1.0, "~"=>[85, 86, 87]}, {"@"=>1, "k"=>53, "#"=>[{"@"=>1, "-"=>[89, 88]}], "%"=>1.0, "~"=>[88, 89]}, {"@"=>0, "k"=>54, "#"=>[], "%"=>0.0, "~"=>[90]}, {"@"=>0, "k"=>55, "#"=>[], "%"=>0.0, "~"=>[92]}, {"@"=>0, "k"=>56, "#"=>[], "%"=>0.0, "~"=>[95]}, {"@"=>1, "k"=>57, "#"=>[{"@"=>1, "-"=>[97, 96]}], "%"=>1.0, "~"=>[96, 97]}, {"@"=>1, "k"=>58, "#"=>[{"@"=>1, "-"=>[99, 98]}], "%"=>1.0, "~"=>[98, 99]}, {"@"=>0, "k"=>59, "#"=>[], "%"=>0.0, "~"=>[100]}, {"@"=>3, "k"=>60, "#"=>[{"@"=>1, "-"=>[102, 101]}, {"@"=>1, "-"=>[103, 101]}, {"@"=>1, "-"=>[103, 102]}], "%"=>1.0, "~"=>[101, 102, 103]}, {"@"=>1, "k"=>61, "#"=>[{"@"=>1, "-"=>[105, 104]}], "%"=>1.0, "~"=>[104, 105]}, {"@"=>1, "k"=>62, "#"=>[{"@"=>1, "-"=>[107, 106]}], "%"=>1.0, "~"=>[106, 107]}, {"@"=>1, "k"=>63, "#"=>[{"@"=>1, "-"=>[109, 108]}], "%"=>1.0, "~"=>[108, 109]}, {"@"=>1, "k"=>64, "#"=>[{"@"=>1, "-"=>[111, 110]}], "%"=>1.0, "~"=>[110, 111]}, {"@"=>1, "k"=>65, "#"=>[{"@"=>1, "-"=>[113, 112]}], "%"=>1.0, "~"=>[112, 113]}, {"@"=>3, "k"=>66, "#"=>[{"@"=>1, "-"=>[115, 114]}, {"@"=>1, "-"=>[116, 114]}, {"@"=>1, "-"=>[116, 115]}], "%"=>1.0, "~"=>[114, 115, 116]}, {"@"=>3, "k"=>67, "#"=>[{"@"=>1, "-"=>[118, 117]}, {"@"=>1, "-"=>[119, 117]}, {"@"=>1, "-"=>[119, 118]}], "%"=>1.0, "~"=>[117, 118, 119]}, {"@"=>1, "k"=>68, "#"=>[{"@"=>1, "-"=>[121, 120]}], "%"=>1.0, "~"=>[120, 121]}, {"@"=>0, "k"=>69, "#"=>[], "%"=>0.0, "~"=>[122]}, {"@"=>3, "k"=>70, "#"=>[{"@"=>1, "-"=>[124, 123]}, {"@"=>1, "-"=>[125, 123]}, {"@"=>1, "-"=>[125, 124]}], "%"=>1.0, "~"=>[123, 124, 125]}, {"@"=>0, "k"=>71, "#"=>[], "%"=>0.0, "~"=>[126]}, {"@"=>1, "k"=>72, "#"=>[{"@"=>1, "-"=>[128, 127]}], "%"=>1.0, "~"=>[127, 128]}, {"@"=>0, "k"=>73, "#"=>[], "%"=>0.0, "~"=>[129]}, {"@"=>1, "k"=>74, "#"=>[{"@"=>1, "-"=>[131, 130]}], "%"=>1.0, "~"=>[130, 131]}, {"@"=>2, "k"=>75, "#"=>[{"@"=>1, "-"=>[133, 132]}, {"@"=>1, "-"=>[257, 133]}], "%"=>0.666666666666667, "~"=>[132, 133, 257]}, {"@"=>1, "k"=>76, "#"=>[{"@"=>1, "-"=>[135, 134]}], "%"=>1.0, "~"=>[134, 135]}, {"@"=>1, "k"=>77, "#"=>[{"@"=>1, "-"=>[137, 136]}], "%"=>1.0, "~"=>[136, 137]}, {"@"=>1, "k"=>78, "#"=>[{"@"=>1, "-"=>[139, 138]}], "%"=>1.0, "~"=>[138, 139]}, {"@"=>1, "k"=>79, "#"=>[{"@"=>1, "-"=>[141, 140]}], "%"=>1.0, "~"=>[140, 141]}, {"@"=>1, "k"=>80, "#"=>[{"@"=>1, "-"=>[143, 142]}], "%"=>1.0, "~"=>[142, 143]}, {"@"=>2, "k"=>81, "#"=>[{"@"=>1, "-"=>[145, 144]}, {"@"=>1, "-"=>[182, 145]}], "%"=>0.666666666666667, "~"=>[144, 145, 182]}, {"@"=>1, "k"=>82, "#"=>[{"@"=>1, "-"=>[147, 146]}], "%"=>1.0, "~"=>[146, 147]}, {"@"=>0, "k"=>83, "#"=>[], "%"=>0.0, "~"=>[148]}, {"@"=>1, "k"=>84, "#"=>[{"@"=>1, "-"=>[150, 149]}], "%"=>1.0, "~"=>[149, 150]}, {"@"=>1, "k"=>85, "#"=>[{"@"=>1, "-"=>[152, 151]}], "%"=>1.0, "~"=>[151, 152]}, {"@"=>0, "k"=>86, "#"=>[], "%"=>0.0, "~"=>[153]}, {"@"=>0, "k"=>87, "#"=>[], "%"=>0.0, "~"=>[154]}, {"@"=>3, "k"=>88, "#"=>[{"@"=>3, "-"=>[156, 155]}], "%"=>1.0, "~"=>[155, 156]}, {"@"=>0, "k"=>89, "#"=>[], "%"=>0.0, "~"=>[157]}, {"@"=>0, "k"=>90, "#"=>[], "%"=>0.0, "~"=>[158]}, {"@"=>0, "k"=>91, "#"=>[], "%"=>0.0, "~"=>[159]}, {"@"=>4, "k"=>92, "#"=>[{"@"=>1, "-"=>[161, 160]}, {"@"=>2, "-"=>[226, 160]}, {"@"=>1, "-"=>[330, 226]}], "%"=>0.5, "~"=>[160, 161, 226, 330]}, {"@"=>0, "k"=>93, "#"=>[], "%"=>0.0, "~"=>[162]}, {"@"=>1, "k"=>94, "#"=>[{"@"=>1, "-"=>[164, 163]}], "%"=>1.0, "~"=>[163, 164]}, {"@"=>1, "k"=>95, "#"=>[{"@"=>1, "-"=>[166, 165]}], "%"=>1.0, "~"=>[165, 166]}, {"@"=>1, "k"=>96, "#"=>[{"@"=>1, "-"=>[168, 167]}], "%"=>1.0, "~"=>[167, 168]}, {"@"=>1, "k"=>97, "#"=>[{"@"=>1, "-"=>[170, 169]}], "%"=>1.0, "~"=>[169, 170]}, {"@"=>1, "k"=>98, "#"=>[{"@"=>1, "-"=>[172, 171]}], "%"=>1.0, "~"=>[171, 172]}, {"@"=>1, "k"=>99, "#"=>[{"@"=>1, "-"=>[174, 173]}], "%"=>1.0, "~"=>[173, 174]}, {"@"=>1, "k"=>100, "#"=>[{"@"=>1, "-"=>[176, 175]}], "%"=>1.0, "~"=>[175, 176]}, {"@"=>6, "k"=>101, "#"=>[{"@"=>1, "-"=>[178, 177]}, {"@"=>1, "-"=>[179, 177]}, {"@"=>1, "-"=>[179, 178]}, {"@"=>1, "-"=>[180, 177]}, {"@"=>1, "-"=>[180, 178]}, {"@"=>1, "-"=>[180, 179]}], "%"=>1.0, "~"=>[177, 178, 179, 180]}, {"@"=>0, "k"=>102, "#"=>[], "%"=>0.0, "~"=>[181]}, {"@"=>1, "k"=>103, "#"=>[{"@"=>1, "-"=>[184, 183]}], "%"=>1.0, "~"=>[183, 184]}, {"@"=>3, "k"=>104, "#"=>[{"@"=>1, "-"=>[186, 185]}, {"@"=>1, "-"=>[187, 185]}, {"@"=>1, "-"=>[187, 186]}], "%"=>1.0, "~"=>[185, 186, 187]}, {"@"=>6, "k"=>105, "#"=>[{"@"=>2, "-"=>[189, 188]}, {"@"=>2, "-"=>[190, 188]}, {"@"=>2, "-"=>[190, 189]}], "%"=>1.0, "~"=>[188, 189, 190]}, {"@"=>1, "k"=>106, "#"=>[{"@"=>1, "-"=>[193, 192]}], "%"=>1.0, "~"=>[192, 193]}, {"@"=>6, "k"=>107, "#"=>[{"@"=>1, "-"=>[195, 194]}, {"@"=>1, "-"=>[196, 194]}, {"@"=>1, "-"=>[196, 195]}, {"@"=>1, "-"=>[197, 194]}, {"@"=>1, "-"=>[197, 195]}, {"@"=>1, "-"=>[197, 196]}], "%"=>1.0, "~"=>[194, 195, 196, 197]}, {"@"=>1, "k"=>108, "#"=>[{"@"=>1, "-"=>[199, 198]}], "%"=>1.0, "~"=>[198, 199]}, {"@"=>2, "k"=>109, "#"=>[{"@"=>2, "-"=>[201, 200]}], "%"=>1.0, "~"=>[200, 201]}, {"@"=>2, "k"=>110, "#"=>[{"@"=>2, "-"=>[203, 202]}], "%"=>1.0, "~"=>[202, 203]}, {"@"=>2, "k"=>111, "#"=>[{"@"=>2, "-"=>[205, 204]}], "%"=>1.0, "~"=>[204, 205]}, {"@"=>1, "k"=>112, "#"=>[{"@"=>1, "-"=>[207, 206]}], "%"=>1.0, "~"=>[206, 207]}, {"@"=>1, "k"=>113, "#"=>[{"@"=>1, "-"=>[209, 208]}], "%"=>1.0, "~"=>[208, 209]}, {"@"=>1, "k"=>114, "#"=>[{"@"=>1, "-"=>[211, 210]}], "%"=>1.0, "~"=>[210, 211]}, {"@"=>1, "k"=>115, "#"=>[{"@"=>1, "-"=>[213, 212]}], "%"=>1.0, "~"=>[212, 213]}, {"@"=>1, "k"=>116, "#"=>[{"@"=>1, "-"=>[215, 214]}], "%"=>1.0, "~"=>[214, 215]}, {"@"=>1, "k"=>117, "#"=>[{"@"=>1, "-"=>[217, 216]}], "%"=>1.0, "~"=>[216, 217]}, {"@"=>0, "k"=>118, "#"=>[], "%"=>0.0, "~"=>[218]}, {"@"=>0, "k"=>119, "#"=>[], "%"=>0.0, "~"=>[219]}, {"@"=>0, "k"=>120, "#"=>[], "%"=>0.0, "~"=>[220]}, {"@"=>1, "k"=>121, "#"=>[{"@"=>1, "-"=>[223, 222]}], "%"=>1.0, "~"=>[222, 223]}, {"@"=>0, "k"=>122, "#"=>[], "%"=>0.0, "~"=>[225]}, {"@"=>0, "k"=>123, "#"=>[], "%"=>0.0, "~"=>[227]}, {"@"=>1, "k"=>124, "#"=>[{"@"=>1, "-"=>[231, 230]}], "%"=>1.0, "~"=>[230, 231]}, {"@"=>1, "k"=>125, "#"=>[{"@"=>1, "-"=>[233, 232]}], "%"=>1.0, "~"=>[232, 233]}, {"@"=>0, "k"=>126, "#"=>[], "%"=>0.0, "~"=>[234]}, {"@"=>1, "k"=>127, "#"=>[{"@"=>1, "-"=>[237, 236]}], "%"=>1.0, "~"=>[236, 237]}, {"@"=>1, "k"=>128, "#"=>[{"@"=>1, "-"=>[239, 238]}], "%"=>1.0, "~"=>[238, 239]}, {"@"=>0, "k"=>129, "#"=>[], "%"=>0.0, "~"=>[240]}, {"@"=>1, "k"=>130, "#"=>[{"@"=>1, "-"=>[242, 241]}], "%"=>1.0, "~"=>[241, 242]}, {"@"=>12, "k"=>131, "#"=>[{"@"=>2, "-"=>[244, 243]}, {"@"=>2, "-"=>[245, 243]}, {"@"=>2, "-"=>[245, 244]}, {"@"=>1, "-"=>[246, 243]}, {"@"=>1, "-"=>[246, 244]}, {"@"=>1, "-"=>[246, 245]}, {"@"=>1, "-"=>[316, 243]}, {"@"=>1, "-"=>[316, 244]}, {"@"=>1, "-"=>[316, 245]}], "%"=>0.9, "~"=>[243, 244, 245, 246, 316]}, {"@"=>2, "k"=>132, "#"=>[{"@"=>2, "-"=>[248, 247]}], "%"=>1.0, "~"=>[247, 248]}, {"@"=>2, "k"=>133, "#"=>[{"@"=>2, "-"=>[250, 249]}], "%"=>1.0, "~"=>[249, 250]}, {"@"=>1, "k"=>134, "#"=>[{"@"=>1, "-"=>[252, 251]}], "%"=>1.0, "~"=>[251, 252]}, {"@"=>1, "k"=>135, "#"=>[{"@"=>1, "-"=>[254, 253]}], "%"=>1.0, "~"=>[253, 254]}, {"@"=>0, "k"=>136, "#"=>[], "%"=>0.0, "~"=>[255]}, {"@"=>1, "k"=>137, "#"=>[{"@"=>1, "-"=>[259, 258]}], "%"=>1.0, "~"=>[258, 259]}, {"@"=>1, "k"=>138, "#"=>[{"@"=>1, "-"=>[261, 260]}], "%"=>1.0, "~"=>[260, 261]}, {"@"=>1, "k"=>139, "#"=>[{"@"=>1, "-"=>[263, 262]}], "%"=>1.0, "~"=>[262, 263]}, {"@"=>1, "k"=>140, "#"=>[{"@"=>1, "-"=>[265, 264]}], "%"=>1.0, "~"=>[264, 265]}, {"@"=>1, "k"=>141, "#"=>[{"@"=>1, "-"=>[267, 266]}], "%"=>1.0, "~"=>[266, 267]}, {"@"=>1, "k"=>142, "#"=>[{"@"=>1, "-"=>[269, 268]}], "%"=>1.0, "~"=>[268, 269]}, {"@"=>0, "k"=>143, "#"=>[], "%"=>0.0, "~"=>[270]}, {"@"=>3, "k"=>144, "#"=>[{"@"=>1, "-"=>[272, 271]}, {"@"=>1, "-"=>[273, 271]}, {"@"=>1, "-"=>[273, 272]}], "%"=>1.0, "~"=>[271, 272, 273]}, {"@"=>1, "k"=>145, "#"=>[{"@"=>1, "-"=>[275, 274]}], "%"=>1.0, "~"=>[274, 275]}, {"@"=>1, "k"=>146, "#"=>[{"@"=>1, "-"=>[277, 276]}], "%"=>1.0, "~"=>[276, 277]}, {"@"=>1, "k"=>147, "#"=>[{"@"=>1, "-"=>[279, 278]}], "%"=>1.0, "~"=>[278, 279]}, {"@"=>3, "k"=>148, "#"=>[{"@"=>1, "-"=>[281, 280]}, {"@"=>1, "-"=>[282, 280]}, {"@"=>1, "-"=>[282, 281]}], "%"=>1.0, "~"=>[280, 281, 282]}, {"@"=>2, "k"=>149, "#"=>[{"@"=>2, "-"=>[284, 283]}], "%"=>1.0, "~"=>[283, 284]}, {"@"=>2, "k"=>150, "#"=>[{"@"=>2, "-"=>[286, 285]}], "%"=>1.0, "~"=>[285, 286]}, {"@"=>1, "k"=>151, "#"=>[{"@"=>1, "-"=>[288, 287]}], "%"=>1.0, "~"=>[287, 288]}, {"@"=>4, "k"=>152, "#"=>[{"@"=>2, "-"=>[290, 289]}, {"@"=>1, "-"=>[291, 289]}, {"@"=>1, "-"=>[291, 290]}], "%"=>1.0, "~"=>[289, 290, 291]}, {"@"=>2, "k"=>153, "#"=>[{"@"=>2, "-"=>[293, 292]}], "%"=>1.0, "~"=>[292, 293]}, {"@"=>2, "k"=>154, "#"=>[{"@"=>2, "-"=>[295, 294]}], "%"=>1.0, "~"=>[294, 295]}, {"@"=>2, "k"=>155, "#"=>[{"@"=>2, "-"=>[297, 296]}], "%"=>1.0, "~"=>[296, 297]}, {"@"=>15, "k"=>156, "#"=>[{"@"=>1, "-"=>[299, 298]}, {"@"=>1, "-"=>[300, 298]}, {"@"=>1, "-"=>[300, 299]}, {"@"=>1, "-"=>[301, 298]}, {"@"=>1, "-"=>[301, 299]}, {"@"=>1, "-"=>[301, 300]}, {"@"=>1, "-"=>[302, 298]}, {"@"=>1, "-"=>[302, 299]}, {"@"=>1, "-"=>[302, 300]}, {"@"=>1, "-"=>[302, 301]}, {"@"=>1, "-"=>[303, 298]}, {"@"=>1, "-"=>[303, 299]}, {"@"=>1, "-"=>[303, 300]}, {"@"=>1, "-"=>[303, 301]}, {"@"=>1, "-"=>[303, 302]}], "%"=>1.0, "~"=>[298, 299, 300, 301, 302, 303]}, {"@"=>0, "k"=>157, "#"=>[], "%"=>0.0, "~"=>[304]}, {"@"=>0, "k"=>158, "#"=>[], "%"=>0.0, "~"=>[305]}, {"@"=>0, "k"=>159, "#"=>[], "%"=>0.0, "~"=>[306]}, {"@"=>0, "k"=>160, "#"=>[], "%"=>0.0, "~"=>[307]}, {"@"=>0, "k"=>161, "#"=>[], "%"=>0.0, "~"=>[308]}, {"@"=>1, "k"=>162, "#"=>[{"@"=>1, "-"=>[310, 309]}], "%"=>1.0, "~"=>[309, 310]}, {"@"=>1, "k"=>163, "#"=>[{"@"=>1, "-"=>[312, 311]}], "%"=>1.0, "~"=>[311, 312]}, {"@"=>0, "k"=>164, "#"=>[], "%"=>0.0, "~"=>[313]}, {"@"=>2, "k"=>165, "#"=>[{"@"=>2, "-"=>[315, 314]}], "%"=>1.0, "~"=>[314, 315]}, {"@"=>1, "k"=>166, "#"=>[{"@"=>1, "-"=>[318, 317]}], "%"=>1.0, "~"=>[317, 318]}, {"@"=>1, "k"=>167, "#"=>[{"@"=>1, "-"=>[320, 319]}], "%"=>1.0, "~"=>[319, 320]}, {"@"=>1, "k"=>168, "#"=>[{"@"=>1, "-"=>[322, 321]}], "%"=>1.0, "~"=>[321, 322]}, {"@"=>1, "k"=>169, "#"=>[{"@"=>1, "-"=>[324, 323]}], "%"=>1.0, "~"=>[323, 324]}, {"@"=>0, "k"=>170, "#"=>[], "%"=>0.0, "~"=>[325]}, {"@"=>1, "k"=>171, "#"=>[{"@"=>1, "-"=>[327, 326]}], "%"=>1.0, "~"=>[326, 327]}, {"@"=>1, "k"=>172, "#"=>[{"@"=>1, "-"=>[329, 328]}], "%"=>1.0, "~"=>[328, 329]}, {"@"=>0, "k"=>173, "#"=>[], "%"=>0.0, "~"=>[331]}, {"@"=>1, "k"=>174, "#"=>[{"@"=>1, "-"=>[333, 332]}], "%"=>1.0, "~"=>[332, 333]}, {"@"=>0, "k"=>175, "#"=>[], "%"=>0.0, "~"=>[334]}, {"@"=>1, "k"=>176, "#"=>[{"@"=>1, "-"=>[336, 335]}], "%"=>1.0, "~"=>[335, 336]}, {"@"=>1, "k"=>177, "#"=>[{"@"=>1, "-"=>[338, 337]}], "%"=>1.0, "~"=>[337, 338]}, {"@"=>1, "k"=>178, "#"=>[{"@"=>1, "-"=>[340, 339]}], "%"=>1.0, "~"=>[339, 340]}, {"@"=>1, "k"=>179, "#"=>[{"@"=>1, "-"=>[342, 341]}], "%"=>1.0, "~"=>[341, 342]}, {"@"=>0, "k"=>180, "#"=>[], "%"=>0.0, "~"=>[343]}, {"@"=>0, "k"=>181, "#"=>[], "%"=>0.0, "~"=>[344]}, {"@"=>1, "k"=>182, "#"=>[{"@"=>1, "-"=>[346, 345]}], "%"=>1.0, "~"=>[345, 346]}, {"@"=>1, "k"=>183, "#"=>[{"@"=>1, "-"=>[348, 347]}], "%"=>1.0, "~"=>[347, 348]}, {"@"=>1, "k"=>184, "#"=>[{"@"=>1, "-"=>[350, 349]}], "%"=>1.0, "~"=>[349, 350]}, {"@"=>1, "k"=>185, "#"=>[{"@"=>1, "-"=>[352, 351]}], "%"=>1.0, "~"=>[351, 352]}, {"@"=>0, "k"=>186, "#"=>[], "%"=>0.0, "~"=>[353]}, {"@"=>0, "k"=>187, "#"=>[], "%"=>0.0, "~"=>[354]}]

=begin
$suspected_synonyms = \
[{"k"=>26, "n1"=>"a", "n2"=>"un", "="=>"iPhone", "~"=>[35, 34]}, {"k"=>34, "n1"=>"to play", "n2"=>"jouer au", "="=>"Go", "~"=>[54, 53]}, {"k"=>36, "n1"=>"faire", "n2"=>"donner", "="=>"des massages", "~"=>[57, 56]}, {"k"=>36, "n1"=>"to give", "n2"=>"donner des", "="=>"massages", "~"=>[152, 56]}, {"k"=>36, "n1"=>"to give", "n2"=>"faire des", "="=>"massages", "~"=>[152, 57]}, {"k"=>37, "n1"=>nil, "n2"=>"faire du", "="=>"travail manuel", "~"=>[59, 58]}, {"k"=>45, "n1"=>"sexual", "n2"=>"sexuelle", "="=>"orientation", "~"=>[78, 77]}, {"k"=>50, "n1"=>"a", "n2"=>"un", "="=>"pick-up", "~"=>[88, 87]}, {"k"=>60, "n1"=>"personnelle", "n2"=>"home", "="=>"page", "~"=>[106, 105]}, {"k"=>63, "n1"=>"funny", "n2"=>"humoristiques", "="=>"illustrations", "~"=>[112, 111]}, {"k"=>66, "n1"=>"r\303\251vision de texte", "n2"=>"\303\251crire sans fautes", "="=>"en fran\303\247ais", "~"=>[118, 117]}, {"k"=>66, "n1"=>"proofreading", "n2"=>"spell checking", "="=>"in French", "~"=>[192, 119]}, {"k"=>81, "n1"=>"a", "n2"=>"un", "="=>"bean-bag", "~"=>[147, 146]}, {"k"=>81, "n1"=>"sac de f\303\250ves (pour s'asseoir)", "n2"=>"bean-bag", "="=>"un", "~"=>[148, 146]}, {"k"=>82, "n1"=>"me faire donner", "n2"=>"recevoir", "="=>"un massage", "~"=>[150, 149]}, {"k"=>82, "n1"=>"to receive a", "n2"=>"recevoir un", "="=>"massage", "~"=>[151, 149]}, {"k"=>82, "n1"=>"to receive a", "n2"=>"me faire donner un", "="=>"massage", "~"=>[151, 150]}, {"k"=>86, "n1"=>"to teach", "n2"=>"enseigner la", "="=>"permaculture", "~"=>[160, 159]}, {"k"=>87, "n1"=>"encyclopedia of", "n2"=>"encyclop\303\251die de la", "="=>"permaculture", "~"=>[162, 161]}, {"k"=>88, "n1"=>"find people with whom to play", "n2"=>"trouver des gens avec qui jouer au", "="=>"Go", "~"=>[164, 163]}, {"k"=>90, "n1"=>"parsley", "n2"=>"persil", "="=>"local", "~"=>[168, 167]}, {"k"=>102, "n1"=>"professionnelle", "n2"=>"professional", "="=>"page", "~"=>[188, 187]}]
=end


else # when USE_LOCAL_DATA == false ##### ^^^^^^^^^^^^ OR vvvvvvvvvvvvv ######


# Reads the wish lists, or ~volios~, of all our $users and loads the data into the following
# Arrays : $users, $wish_lists, and $categories. Beware ! Multiple calls are made to the
# split_into_synonyms() method, which, as a side effect, populates the global $lexicon
# and $lexicon_infos Arrays.
#
require 'open-uri'

wiki_address = 'http://motsapiensproject.wikia.com/wiki/'

# This pass collects the volios addresses
#
print 'Reading volios... '
$stdout.flush
open( wiki_address + 'Volios' ) do |volio|
  volio.each_line do |line|
    we_have_a_match = line.match /.*~.*href="\/wiki\/Volio_-_(.*?)"/
    if we_have_a_match then
      volio_address = wiki_address + 'Volio_-_' + we_have_a_match[1]
      $users << { 'volio' => volio_address,      \
                  'name'  => we_have_a_match[1], \
                  'infos' => []                  } # Hash.new ??
    end
  end
end


# This pass isolates the wish-list part of each volio
#
$users.each_with_index do |user, u|
  wish_list = ''
  begin
    open( user['volio'] ) do |content|
      print '+'
      $stdout.flush
      content.each_line do |line|
        in_wish_list = line.match /(<dl><dd>.*)/
        if in_wish_list then
          wish_list << in_wish_list[1] + "\n"
        end
      end
    end
  rescue
    puts "\nUser #{user} seems not to have created a volio.\n"
  end
  $wish_lists << {    'user' => u,          \
                   'content' => wish_list,  \
                      'list' => Array.new   }
end
print "\n"


# This pass isolates and categorizes the wishes individually.
#
$wish_lists.each_with_index do |list, l|
  category = nil
  cat_num = nil
  list['content'].each_line do |line|
    section = line.match /.*<b>(.*)<\/b>.*/
    if section then
      category = section[1]
      category.gsub!( /&#160;/, ' ') # Removes unbreakable whitespaces, they show as &#160; on my terminal.
                                     # Although we ~could~ keep track of them too, as yet more clues…
      cat_num = $categories.index( category )
      if not cat_num then
        $categories << category
        cat_num = $categories.length - 1
      end
      split_into_synonyms( category )       # Just to populate $lexicon.
    else
      wish = line.gsub( /<.*?>/, '').strip
      wish.gsub!( /&gt;/, '>')
      wish.gsub!( /&lt;/, '<')
      wish.gsub!( /&#160;/, ' ')
      
      list['list'] << {  'wish'     => [],        #  Before the first >> or <<.
                         'rest'     => [],        #  After the first >> or <<.
                         'type'     => :demand,   #  Can be :demand, :offer, or :interest.
                         'content'  => wish,      #  Will be deleted.
                         'category' => cat_num    #  Key to an entry in table $categories.
                      }
    end
  end
  list.delete('content')
end


# This pass chops the wishes into their components and puts infos into $users Array
#
$wish_lists.each_with_index do |user, u|
  user['list'].each_with_index do |this, w| # talking about a wish, here
    description = []
    if this['content'].include? '<<' then
      description = this['content'].split('<<')
      description.each { |w| w.strip! }
    elsif this['content'].include? '>>' then
      description = this['content'].split('>>')
      description.each { |w| w.strip! }
      this['type'] = :offer
    elsif this['content'].include? ': ' then
      infos = this['content'].split(/\s*:\s+/)
      infos.each_with_index do |part, p|
        infos[p] = split_into_synonyms( part )
       end
      $users[u]['infos'] << infos
      user['list'][w] = nil          ### will be compacted
      next
    else
      this['type'] = :interest
    end
    if description.empty? then
      description << this['content']
    end
    this.delete('content')
    description.each_with_index do |part, w|
      description[w] = split_into_synonyms( part )
      this['wish'] = description[0]
      if description.length == 1 then
        this['rest'] = nil
      else
        this['rest'] = description[1..description.length - 1].flatten
      end
    end
  end
  user['list'].compact!
end


# This pass connects to the local global-database-mirror.
# (run ./local_mirror.rb to update this local mirror)
#
# More to come.
=begin
 File::open( "idea-" + idea_name + ".txt", "w" ) do |f|
   f << idea
 end
 
 + require 'filename' (sp. ? include ?)
=end


# This recursive method will be used in the next pass.
# Requires $all_connected to be prealably set.
#
def all_connected_to( n )
  $all_connected << n
  new_array = $lexicon_infos[n]['~'].uniq - $all_connected
  new_array.each do |e|
    $all_connected += all_connected_to( e )
  end
  return $all_connected.uniq
end


# This pass will consolidate $lexicon_infos into $elements along with some stats.
#
copy_of_lexicon_infos = $lexicon_infos.dup
$elements = []
until copy_of_lexicon_infos.empty? do       # We go through every lexeme in the lexicon copy…
  k = copy_of_lexicon_infos.first['k']
  $all_connected = []
  synonyms = all_connected_to( k )
  synonyms.sort!
  map = []
  total_strength = 0
  
# …compacting them into ~elements~.
  
  synonyms.each_with_index do |s1, i1|
    synonyms.each_with_index do |s2, i2|
      if i2 >= i1 then
        next
      else
        strength = 0
        $lexicon_infos[s1]['~'].each do |s|
          if s == s2 then
            strength +=1
          end
        end
        if strength > 0 then
          map << {'-' => [s1, s2], '@' => strength}
          total_strength += strength
        end
      end
    end
    
  # Once counted in $elements, the repetition is not necessary anymore.
  
    $lexicon_infos[s1]['~'].uniq!
        
  end
  complete = 0.0
  if map != [] then
    complete = completeness( map.length, synonyms.length )
  end
  
# Create the element…
  
  $elements << {  'k' => $elements.length,  \
                  '~' => synonyms,          \
                  '#' => map,               \
                  '@' => total_strength,    \
                  '%' => complete           }
                  
# …and update the lexicon

  synonyms.each do |s|
  
    $lexicon_infos[s]['e'] << $elements.length - 1
    
    copy_of_lexicon_infos.each_with_index do |copy, c|
      if copy['k'] == s then
        copy_of_lexicon_infos.delete_at(c)  # This is just a copy, so it won't affect the lexicon.
        break
      end
    end
  end
end

copy_of_lexicon_infos.clear

=begin
print "\nHere is the data, if you want to internalize it and make tests locally :\n\n"

print "\n" + '$users = \\' + "\n"         ; p $users     
print "\n" + '$wish_lists = \\' + "\n"    ; p $wish_lists
print "\n" + '$categories = \\' + "\n"    ; p $categories    
print "\n" + '$lexicon = \\' + "\n"       ; p $lexicon       
print "\n" + '$lexicon_infos = \\' + "\n" ; p $lexicon_infos
print "\n" + '$elements = \\' + "\n"      ; p $elements
=end

end # USE_LOCAL_DATA was false, so we loaded it on board. ###########################################################


#######################
# High Level Functions

# This recursive method will be used in the two next ones.
# Requires that $all_pairs, $all_mapped and $all_mapped_strength are prealably setted.
#
def all_mapped_to( n, map )                                                # 'All that is mapped to n in map.'
  map.each do |pair|
    if pair['-'].include? n and not $all_mapped.include? pair['-'] then    # If a ~new~ pair matches…
      $all_pairs << pair
      $all_mapped << pair['-']
      $all_mapped |= all_mapped_to( (pair['-'] - [n])[0], map )
      $all_mapped_strength += pair['@']
    end
  end
  return $all_mapped
end


# This method will find ambivalent synonyms (possible errors) in weak elements.
#
def find_ambivalent_synonyms()
	weak_elements = $elements.find_all {|e| e['%'] <= $THRESHOLD_FOR_WEAKNESS and e['%'] > 0.0}
	weak_elements.each do |e|
	
		if e.has_key? 'HOMONYMY MAP' then next end

	  e['#'].each do |pair|
	    a,b = pair['-']
	    map_less_a_b = e['#'] - [pair]

	  # Let's check what the first lexeme (a) is connected to…
	  
	    $all_pairs = []
	    $all_mapped = []
	    $all_mapped_strength = 0
	    all_mapped_to_a = all_mapped_to( a, map_less_a_b ).flatten.uniq
	    mapped_to_a_strength = $all_mapped_strength
	    map_a = $all_pairs

	  # And also check what the second lexeme (b) is connected to…
	  
	    $all_pairs = []
	    $all_mapped = []
	    $all_mapped_strength = 0
	    all_mapped_to_b = all_mapped_to( b, map_less_a_b ).flatten.uniq
	    mapped_to_b_strength = $all_mapped_strength
	    map_b = $all_pairs
                                                                 # We have a suspect synonym…
	    if all_mapped_to_a & all_mapped_to_b == [] then             # …if a's and b's synonyms don't intersect,
	      if all_mapped_to_a != [] and all_mapped_to_b != [] then   # …and both have some,
	        if mapped_to_a_strength >= $NOTABLY * pair['@'] and \
	           mapped_to_b_strength >= $NOTABLY * pair['@'] then    # …and both synonym sets are internally
	                                                                # NOTABLY stronger than [a,b].
	           $ambivalent_synonyms << {  'k' => e['k'],               \
	                                      'a' => a,                    \
	                                      'b' => b,                    \
	                                     '~a' => all_mapped_to_a,      \
	                                     '~b' => all_mapped_to_b,      \
	                                     '#a' => map_a,                \
	                                     '#b' => map_b,                \
	                                     '@a' => mapped_to_a_strength, \
	                                     '@b' => mapped_to_b_strength  }
	        end
	      end
	    end
	  end
	end
end


# This method will find possible 'faux amis' or mistakes due to homonymy in weak elements.
#
def find_suspected_homonyms()
	weak_elements = $elements.find_all {|e| e['%'] <= $THRESHOLD_FOR_WEAKNESS and e['%'] > 0.0}
	weak_elements.each do |e|
	  
	  if e.has_key? 'HOMONYMY MAP' then next end
	  
	  set_of_subsets = []
    lexeme_with_the_greater_number_of_synonyms = -1
                    greater_number_of_synonyms = -1

  # We will here explore whether there aren't completely distinct synonym subsets linked to any ones of the lexemes.
  
	  e['~'].each do |tested_lexeme|
	         subsets = []

	  # First, let's find all our lexeme's synonyms.
	  
	    tested_lexeme_synonyms = e['#'].find_all {|pair| pair['-'].include? tested_lexeme}

	  # and check by the way if it is not the likeliest homonym.
	  
	    if tested_lexeme_synonyms.length > greater_number_of_synonyms then
	      greater_number_of_synonyms = tested_lexeme_synonyms.length
	      lexeme_with_the_greater_number_of_synonyms = tested_lexeme
	    end

	  # Now, let's check which ones of those synonyms connect to a distinct subset of synonyms.
	  
	    tested_lexeme_synonyms.each do |tested_pair|

	    # If this synonymous pair is already part of an identified subset, then skip it.
	    
	      already_part = false
	      subsets.each do |subset|
	        if subset['#'].find {|pair| pair == tested_pair} then
	          already_part = true
	        end
	      end
	      
	      if not already_part then
		      other_lexeme = (tested_pair['-'] - [tested_lexeme])[0]
		      map_less_tested_lexeme_synonyms = e['#'] - tested_lexeme_synonyms

		    # Let's check what this synonymous lexeme is connected to…
		    
		      $all_pairs = []
		      $all_mapped = []
		      $all_mapped_strength = 0
		      all_lexemes_mapped_to_other_lexeme = all_mapped_to( other_lexeme, map_less_tested_lexeme_synonyms ).flatten.uniq
		      all_lexemes_mapped_to_other_lexeme_strength = $all_mapped_strength
		      all_pairs_mapped_to_other_lexeme = $all_pairs

		      if all_pairs_mapped_to_other_lexeme == [] then next end

		    # If other subsets are suspected, then store this one and continue.
		    
		      if e['#'] - (all_pairs_mapped_to_other_lexeme + tested_lexeme_synonyms) != [] then

		      # Include the tested lexeme in the subset
		      
		        subset = []
		        total_strength = 0
		        all_lexemes_mapped_to_other_lexeme.each do |lexeme|
		          tested_lexeme_synonyms.each do |synonymous_pair|
		            if synonymous_pair['-'].include? lexeme then
		              subset << synonymous_pair
		              total_strength += synonymous_pair['@']
		            end
		          end
		        end

		        # Then, the subset as such.
		                subset += all_pairs_mapped_to_other_lexeme
		        total_strength += all_lexemes_mapped_to_other_lexeme_strength

		        synonyms = all_lexemes_mapped_to_other_lexeme + [tested_lexeme]

		        complete = completeness( subset.length, synonyms.length )
		        subsets << { 'k' => e['k'],           \
		                     'l' => tested_lexeme,    \
		                     '~' => synonyms,         \
		                     '#' => subset,           \
		                     '@' => total_strength,   \
		                     '%' => complete          }

		      else            # Otherwise, everything is connected in this element, so let's check the next one.

		        next weak_elements

		      end  # if e['#'] - (all_pairs_mapped_to_other_lexeme + tested_lexeme_synonyms) != []
		    end  # if not already_part
	    end  # tested_lexeme_synonyms.each

	    if subsets != [] then
	      set_of_subsets << subsets
	    end
	    
	  # At last, add the orphan synonymous lexemes to the subsets.
	  
	    remaining_pairs = e['#']
	    
	    subsets.each do |sub|
	      remaining_pairs -= sub['#']
	    end
	    
	    remaining_pairs.each do |r|
	      subsets << { 'k' => e['k'],        \
	                   'l' => tested_lexeme, \
	                   '~' => r['-'],        \
	                   '#' => [r],           \
	                   '@' => r['@'],        \
	                   '%' => 1.0            }
	    end

    end  # e['~'].each

  # For this weak element, select the lexeme with the more many synonyms (the "starrier" embranchment).
	
    starrier_lexeme_subsets = set_of_subsets.find_all {|sub| sub[0]['l'] == lexeme_with_the_greater_number_of_synonyms}
    
    $suspected_homonyms += starrier_lexeme_subsets

  end  # weak_elements.each
end


# This function says if an array (here called 'sequence') is inside another array and also returns the remaining part of this last
# array, if any (returns nil if nothing is found. Funny thing, we look only at both ends of the array.
#
def find_sequence_in_array( sequence, array )

# We don't search for big arrays in small arrays. ^^

  if (sequence.length > array.length) then
    return false, nil, nil      
  end                                               

# First check at this end. (Beginning)
  
  matching = true
  sequence.each_with_index do |element, i|
    if element != array[i] then
      matching = false
      break
    end
  end
  
  if matching then
    if sequence.length == array.length then
      return true, 'beginning', nil
    else
      return true, 'beginning', array[sequence.length..array.length - 1]
    end
  end
  
# And, if sequence and array are not of the same length…
  
  if not sequence.length == array.length then
  
  # We check at this other end. (End)
  
    matching = true
    sequence.reverse.each_with_index do |element, i|
      if element != array[array.length - 1 - i] then
        matching = false
        break
      end
    end
    
  end
  
  if matching then
    if sequence.length == array.length then
      return true, 'end', nil
    else
      return true, 'end', array[0..array.length - 1 - sequence.length]
    end
  end
  
  return false, nil, nil
  
end


# This method links a lexeme to its subdivided parts.
#
def link_to_subdivisions( key, alt_key, part1, part2 )

  if part1 == key or part2 == key then key = alt_key end

  if not $lexicon_infos[key]['<'].include? [part1, part2] then
    $lexicon_infos[key]['<'] << [part1, part2]
  end
end


# This method scans the 'lexemes' (which may be, at first, whole sentences) and guesses about parts of them
# that they are synonyms. It calls form_elements_with_isolated_lexemes(), which adds new elements.
#
def find_suspected_synonyms
  
# For each element…

  $elements.each do |element|
  
    if skip_element( element ) then next end
  
  # …test each of its internal synonyms, one to one :
  
  #     lexeme_1
  
    element['~'].each_with_index do |key1, l1|
    
    # … splitting them into words …
    
               lexeme_1 = $lexicon[key1]
      words_of_lexeme_1 = lexeme_1.split( /\s+/ )        # Split at blanks
      
  # and lexeme_2
      
      element['~'].each_with_index do |key2, l2|
        if l2 >= l1 then
          next
        end                                              # We compare only ~different~ lexemes.
        
                 lexeme_2 = $lexicon[key2]    
        words_of_lexeme_2 = lexeme_2.split( /\s+/ )
        
     # Then, we start searchin' ! The first pass will check for the beginning of lexeme_1 in lexeme_2, the second will check its end.
                
        matched_part_when_at_beginning     = nil
        remaining_part_1_when_at_beginning = nil
        remaining_part_2_when_at_beginning = nil
        matched_part_position_in_lexeme_2_when_at_beginning = nil
        matched_part_when_at_end           = nil
        remaining_part_1_when_at_end       = nil
        remaining_part_2_when_at_end       = nil
        matched_part_position_in_lexeme_2_when_at_end       = nil
	              
      # Let's first search for the longest ~beginning~ of lexeme_1 in lexeme_2.
    
        x_words = 0
      
        while x_words <= words_of_lexeme_1.length - 1 do
      
          tested_part = words_of_lexeme_1[0..x_words]
        
        # If we find the tested part of lexeme_1 in lexeme_2…          
        # (We don't examin when both contain only one element.)
          
          if not (tested_part.length == 1 and words_of_lexeme_2.length == 1)   \
             and x_words <= words_of_lexeme_2.length - 1 then

            they_match, position, remaining_part_2 = find_sequence_in_array( tested_part, words_of_lexeme_2 )
          
            if they_match then
          
            # …we keep track of where we're at…
            
              matched_part_when_at_beginning       = tested_part      # x_words grows, so we have the longest one at the end.
              matched_part_position_in_lexeme_2_when_at_beginning = position
	         
              if words_of_lexeme_1.length >= 2 and x_words < words_of_lexeme_1.length - 1 then
                remaining_part_1_when_at_beginning = words_of_lexeme_1[x_words + 1..words_of_lexeme_1.length - 1]
              else
                remaining_part_1_when_at_beginning = nil
              end
              
              remaining_part_2_when_at_beginning   = remaining_part_2
            
            end
          end
                  
          x_words += 1
        
        end   # while
      
      # Then we search for the longest ~ending~ of lexeme_1 in lexeme_2.
            
        x_words = 0
      
        while x_words <= words_of_lexeme_1.length - 2 do       # - 2 not to retest the whole of lexeme_1
      
          tested_part = words_of_lexeme_1[words_of_lexeme_1.length - 1 - x_words..words_of_lexeme_1.length - 1]
                    
        # If we find the tested part of lexeme_1 in lexeme_2…          
        # (We don't examin when both contain only one element.)
          
          if not (tested_part.length == 1 and words_of_lexeme_2.length == 1)   \
             and x_words <= words_of_lexeme_2.length - 1 then

            they_match, position, remaining_part_2 = find_sequence_in_array( tested_part, words_of_lexeme_2 )
          
            if they_match then
          
            # …we keep track of where we're at…
            
              matched_part_when_at_end       = tested_part        # x_words grows, so we have the longest one at the end.
              matched_part_position_in_lexeme_2_when_at_end = position
	         
              if words_of_lexeme_1.length >= 2 and x_words < words_of_lexeme_1.length - 1 then
                remaining_part_1_when_at_end = words_of_lexeme_1[0..words_of_lexeme_1.length - 1 - x_words - 1]
              else
                remaining_part_1_when_at_end = nil
              end
              
              remaining_part_2_when_at_end   = remaining_part_2
            
            end
          end
                  
          x_words += 1
        
        end   # while
      
      # Now, let's see if we have found something…
      
          matched_part   = nil
        remaining_part_1 = nil
        remaining_part_2 = nil
      
      # …at the beginning…
    
        if matched_part_when_at_beginning then
      
            matched_part   =     matched_part_when_at_beginning
          remaining_part_1 = remaining_part_1_when_at_beginning
          remaining_part_2 = remaining_part_2_when_at_beginning
        
        end
      
      # …and at the end.
        
        if matched_part_when_at_end then
      
        # We look for the longest match, so that we proceed from the bigger chunks to the smaller ones.
        
          if (matched_part_when_at_beginning and                                           \
             (matched_part_when_at_end.length > matched_part_when_at_beginning.length)) or \
          not matched_part_when_at_beginning then
        
              matched_part   =     matched_part_when_at_end
            remaining_part_1 = remaining_part_1_when_at_end
            remaining_part_2 = remaining_part_2_when_at_end
          
          end
        end
        
      # If we have no match, we skip to next lexeme_2.
      
        if not matched_part then next end
      
      # But if we have, we revert our matches to string…
      
        joined_matched_part     =     matched_part.join( ' ' )       
        joined_remaining_part_1 = remaining_part_1.join( ' ' ) unless remaining_part_1 == nil
        joined_remaining_part_2 = remaining_part_2.join( ' ' ) unless remaining_part_2 == nil
        
      # …we then add our matches to the $lexicon end $elements.
      
        matched_part_in_lexicon = add_lexeme( joined_matched_part, false )
        
        remaining_part_1_in_lexicon = add_lexeme( joined_remaining_part_1, false ) unless remaining_part_1 == nil
        remaining_part_2_in_lexicon = add_lexeme( joined_remaining_part_2, false ) unless remaining_part_2 == nil
        
        if remaining_part_1 and remaining_part_2 then
          add_synonyms( [remaining_part_1_in_lexicon, remaining_part_2_in_lexicon], [] )
        end
        
        if remaining_part_1 and not remaining_part_2 then 
          $lexicon_infos[remaining_part_1_in_lexicon]['o'] = true
          add_synonyms( [matched_part_in_lexicon, key1], [] )
        end
            
        if remaining_part_2 and not remaining_part_1 then 
          $lexicon_infos[remaining_part_2_in_lexicon]['o'] = true
          add_synonyms( [matched_part_in_lexicon, key2], [] )
        end

        if matched_part_when_at_beginning then
          link_to_subdivisions( key1, key2, matched_part_in_lexicon, remaining_part_1_in_lexicon )
          if matched_part_position_in_lexeme_2_when_at_beginning == 'beginning' then
            link_to_subdivisions( key2, key1, matched_part_in_lexicon, remaining_part_2_in_lexicon )
          else
            link_to_subdivisions( key2, key1, remaining_part_2_in_lexicon, matched_part_in_lexicon )
          end
        else
          link_to_subdivisions( key1, key2, remaining_part_1_in_lexicon, matched_part_in_lexicon )
          if matched_part_position_in_lexeme_2_when_at_end == 'beginning' then
            link_to_subdivisions( key2, key1, matched_part_in_lexicon, remaining_part_2_in_lexicon )
          else
            link_to_subdivisions( key2, key1, remaining_part_2_in_lexicon, matched_part_in_lexicon )
          end
        end
=begin        

    # This trend has been abandoned, but we keep the code in case it is reintroduced later.

      # Then we backtrace ancestors and 
      
          $lexicon_infos.each do |lexeme|
          
            lexeme['<'].each do |subdivision|
            
              if subdivision[0] then $lexicon_infos[subdivision[0]]['<<'] = lexeme['k'] end
              if subdivision[1] then $lexicon_infos[subdivision[1]]['<<'] = lexeme['k'] end
            
            end
          
          end    
          
          $lexicon_infos.each do |lexeme|
          
            lexeme['<'].reverse.each_with_index do |subdivision, sub|
            
              if subdivision[0] == nil or subdivision[1] == nil then
              
                $lexicon_infos[lexeme['k']]['<'] << [subdivision[0], subdivision[1]]
                
                lexeme['<'].delete_at sub
            
            end
          
          end     
=end        
        form_elements_with_isolated_lexemes( )
        resolve_homonyms( )
            
      end   # element['~'].each_with_index        
    end   # element['~'].each_with_index
  end   # $elements.each
end   # find_suspected_synonyms


# This method asks external intelligences whether the $ambivalent_synonyms are really bad.
#
def verify_with_human()

  puts "\nYou can help the Tramice 721 to solve false synonyms and homonyms by answering a few questions.\n"
  puts "\n   (At any time, to quit, type : Quit)\n\n"
  
# First, the more obvious…

  find_ambivalent_synonyms  # Function call…

  ambivalent_synonyms = $ambivalent_synonyms.dup  # We will work on a copy, because there may be deletions.
  
# Let's now ask the user what they think…
  
  ambivalent_synonyms.each do |s|
    answer_ok = true
    begin

      print ' - Are "' + $lexicon[s['a']] + '" and "' + $lexicon[s['b']] + '"' + \
            " synonyms ? (Yes/No/Pass)\n\n"
            
      answer = gets.chomp.capitalize[0,1]

      case answer

	      when 'Y'
	      
	      # This case is promptly solved.

	        $ambivalent_synonyms -= [s]
	        
	      # We nonetheless keep log of the user action.
	        
	        # $users[user]['infos'] << {  'ACTION' => 'confirmed',  \
	        #                             'WHAT'   => s,            \
	        #                             'DATE'   => Time.now      }

	      when 'N'

	      # We simply split the element in its two obvious parts.
	      
	        complete = completeness( s['#a'].length, s['~a'].length )
	        
	        $elements[s['k']] =                       \
	                       { 'k' => s['k'],           \
	                         '~' => s['~a'],          \
	                         '#' => s['#a'],          \
	                         '@' => s['@a'],          \
	                         '%' => complete          }
	                         
	        s['~a'].each do |lexeme|
	          $lexicon_infos[lexeme]['e'] -= [s['b']]
	        end
	        
	        complete = completeness( s['#b'].length, s['~b'].length )
	        
	        $elements <<  {  'k' => $elements.length, \
	                         '~' => s['~b'],          \
	                         '#' => s['#b'],          \
	                         '@' => s['@b'],          \
	                         '%' => complete          }
	                         
	        s['~b'].each do |lexeme|
	          $lexicon_infos[lexeme]['e'] -= [s['a']]
	          $lexicon_infos[lexeme]['e'] << $elements.length - 1
	        end

	      # We also remove the faulty synonyms from the $lexicon_infos.
	        
	        $lexicon_infos[s['a']]['~'] -= [s['b']]
	        $lexicon_infos[s['b']]['~'] -= [s['a']]
	        
	      # And then we consider this case filed.

	        $ambivalent_synonyms -= [s]
	        
	      # The user's action is logged.
	        
	        # $users[user]['infos'] << {  'ACTION' => 'infirmed',  \
	        #                             'WHAT'   => s,           \
	        #                             'DATE'   => Time.now     }

	        # Can we also backtrace to the faulty wish and remove it ?
	        # And also inform its author ?
	      when 'P'
	        next
	      when 'Q'
	        return
      else
        answer_ok = false
      end
    end until answer_ok
  end
  

# When ambivalents synonyms are all treated, we may always check some potential badly formed elements, due to homonymy.

  find_suspected_homonyms    # First, call the function.

  suspected_homonyms = $suspected_homonyms.dup    # We will work on a copy, because there may very well be deletions.
  
  suspected_homonyms.each do |h|
       k = h[0]['k']                 # This is the key (ID) of this element that is suspected of being actually… many.
       l = h[0]['l']                 # This is the number of the lexeme that may have different meanings.
    synonymous_subsets = []

 # So, let's ask the user to compare dubious pairs of synonyms, and reshape lexicon & elements accordingly.
          
    h.each_with_index do |sub_constellation_a, a|
      h.each_with_index do |sub_constellation_b, b|
      
        if b >= a then
          next
        end

        answer_ok = true
        
        begin # asking the folowwing question to the user, and ask until a correct answer is given.

        # But first, let's see if this potential pair has been resolved already.
          
          all_subsets_containing_either_one_of_the_two_constellations = []
          
          constellations_already_merged = false
          
          synonymous_subsets.each_with_index do |subset, s|
          
            if [sub_constellation_a, sub_constellation_b] - subset.flatten == [] then
            
              constellations_already_merged = true
              break                                        # Skip this one, it is unnecessary.
              
            end
            
          # For this, we collect all subsets containing either one of the two presently considered contellations.

            if [sub_constellation_a] - subset.flatten == [] then
              all_subsets_containing_either_one_of_the_two_constellations << s
            end
            
            if [sub_constellation_b] - subset.flatten == [] then
              all_subsets_containing_either_one_of_the_two_constellations << s
            end
          end
          
          if constellations_already_merged then next end
          
        # We may now ask the question.

          print ' - Are { '
          sub_constellation_a['~'].each { |lexeme| print '"' + $lexicon[lexeme] + '" ' }
          print '} and { '
          sub_constellation_b['~'].each { |lexeme| print '"' + $lexicon[lexeme] + '" ' }
          print "} synonymous sets ? (Yes/No/Pass)\n\n"
          
          answer = gets.chomp.capitalize[0,1]

          case answer

	          when 'Y'

	          # If no synonymous subset contains either one of the two constellations, append both.
	            
             if all_subsets_containing_either_one_of_the_two_constellations == [] then
             
	            # …add the two of them in a separate synonymous subset.

	              synonymous_subsets << [sub_constellation_a, sub_constellation_b]
	              
	            else
	            
	            # Otherwise, merge the subsets containing either one of the two currently tested constellations.
	            
	              merged_synonymous_subsets = [sub_constellation_a, sub_constellation_b]	            
	              all_subsets_containing_either_one_of_the_two_constellations.reverse.each do |s|  
	              
	                merged_synonymous_subsets |= synonymous_subsets[s]     
	                synonymous_subsets.delete_at(s)                        # ^reverse^ because we delete
	                
	              end
	              
	              synonymous_subsets << merged_synonymous_subsets
	              	            
	            end	            
	            
	          # And we also update $lexicon_infos with these new synonyms.
	            
	            $suspected_homonyms -= [h]
	            
	            # $users[user]['infos'] << {  'ACTION' => 'confirmed',                                 \
	            #                             'WHAT'   => [sub_constellation_a, sub_constellation_b],  \
	            #                             'DATE'   => Time.now                                     }
	            

	          when 'N'                        # No, the two subsets aren't synonymous.

	            if [sub_constellation_a] - synonymous_subsets.flatten != [] then
	              synonymous_subsets << [sub_constellation_a]
	            end

	            if [sub_constellation_b] - synonymous_subsets.flatten != [] then
	              synonymous_subsets << [sub_constellation_b]
	            end

	          # Let's remove the faulty synonymous_subsets from $lexicon_infos.
	            
	            sub_constellation_a['~'].each do |lexeme|
	              $lexicon_infos[lexeme]['~'] -= (sub_constellation_b['~'] - [l])
	              $lexicon_infos[lexeme]['e'] -= [k]
	            end
	            
	            sub_constellation_b['~'].each do |lexeme|
	              $lexicon_infos[lexeme]['~'] -= (sub_constellation_a['~'] - [l])
	              $lexicon_infos[lexeme]['e'] -= [k]
	            end
	            
	          # And clear this case.

	            $suspected_homonyms -= [h]
	            
	          # Now, log the user's action.
	          
	            # $users[user]['infos'] << {  'ACTION' => 'infirmed',          \
	            #                             'WHAT'   => [subset1, subset2],  \
	            #                             'DATE'   => Time.now             }

	          when 'P'
	            next
	          when 'Q'
	            return
          else
            answer_ok = false
          end
        end until answer_ok
        
      end    # h.each_with_index
    end    # h.each_with_index
    
    
  # If all the subsets are synonymous, we leave the element as it is.
    
    if synonymous_subsets.length == 1 then       
      next
    else
    
    # Otherwise, we first report the homonymous lexeme and mark off the faulty element.
      
      $homonyms << {  'l' => l,            \
	                    'h' => $lexicon[l],  \
	                    'x' => k,            \
	                    'e' => []            }

	    $elements[k]['HOMONYMY MAP'] = l	   
	    

    # Then we create separated, complete elements.

      synonymous_subsets.each do |subset|
        total_lexemes            = []
        total_map                = []
        total_strength           = 0
        
      # First, we add the constellation's pairs to the total map.
        
        subset.each do |constellation|
          total_lexemes         |= constellation['~']   # join

	        constellation['#'].each do |pair|
	            
            matched_pair = total_map.index {|p| p['-'] - pair['-'] == []}
            
            if not matched_pair then # add it to the map
            
              total_map          << { '-' => pair['-'], '@' => 1 }
              
            else # strengthen the matched pair
            
              total_map[matched_pair]['@'] += 1
              
            end # — in both cases, strengthen the map strength.
            
            total_strength       += 1	            
	        end    
        end    # subset.each
	        
      # Then, we add the total interconnection of these newly joined synonyms to the total map.
       
        total_lexemes.each_with_index do |lexeme1, l1|
          total_lexemes.each_with_index do |lexeme2, l2|
          
            if l2 >= l1 then next end
            
            matched_pair = total_map.index {|pair| (pair['-'] - [lexeme1]) - [lexeme2] == []}
            
            if not matched_pair then # add it to the map
            
              total_map          << { '-' => [lexeme1, lexeme2], '@' => 1 }
              
            else # strengthen the matched pair
            
              total_map[matched_pair]['@'] += 1
              
            end # — in both cases, increase the map strength.
            
            total_strength       += 1
            
          end
        end
        
      # Finally let's add this separated, complete element to the list !
        
        complete = completeness( total_map.length, total_lexemes.length )
        
        $elements << {  'k' => $elements.length,      \
                        '~' => total_lexemes,         \
                        '#' => total_map,             \
                        '@' => total_strength,        \
                        '%' => complete               }  # Should be 1.0 (100 %).
                        
      # Oh, yeah, let's also update the other tables… 
      
        total_lexemes.each_with_index do |lex1, l1|
        
          $lexicon_infos[lex1]['e'] << $elements.length - 1
          
          total_lexemes.each_with_index do |lex2, l2|	
            if l2 >= l1 then
              next
            end            
            $lexicon_infos[lex1]['~'] |= [lex2]
            $lexicon_infos[lex2]['~'] |= [lex1]
          end
        end
        
        $homonyms.last['e'] << $elements.length - 1
           
      end    # synonymous_subsets.each
    end    # if synonymous_subsets.length == 1 (else)
  end    # suspected_homonyms.each
  
  
# After having resolved the previous external cases, let's try to find synonyms ~inside~ our lexemes…

  find_suspected_synonyms   # The usual function call…
  
  print "\n   There is no more synonyms to check.\n\n"
  
  suspected_homonyms.clear
  
end    # verify_with_human()


# This method displays the lexicon in a readable format.
#
def print_lexicon(l)
  print "\n"
  $lexicon_infos.each do |lex|
    if l != '' and (l.to_i != lex['k']) then
      next
    else
      print lex['k'].to_s + ' ~ '
    end
    print $lexicon[lex['k']].to_s
    lex['e'].each do |element|
      print ' (#' + element.to_s + ')'
    end
    lex['~'].each do |synonym|
      print ' ~ ' + synonym.to_s
    end
    print "\n"
  end
end


# This method displays the element set in a readable format.
#
def print_elements(elem)
  print "\n"
  $elements.each do |e|
    if elem != '' and (elem.to_i != e['k']) then
      next 
    else
      print '#' + e['k'].to_s
    end
    if e.has_key? 'HOMONYMY MAP' then
      print ' { HOMONYMY MAP for : << '
      print $lexicon[e['HOMONYMY MAP']] + ' >> }' 
    end
    if e.has_key? 'SUPERCEDED by' then
      print ' { SUPERCEDED by : #'
      print e['SUPERCEDED by'].to_s + ' }' 
    end
    if e['o'] then
      print ' { OPTIONAL }'
    end
    if not e['~'].length > 1 then
      print " ~ #{$lexicon[e['~'][0]]} ~\n\n"
      next
    end
    
  # If more than one lexeme are associated with this element, then print its table.
    
    lex = e['~'].sort
    lex.each do |l|
      print ' ~ (' + l.to_s + ': ' + $lexicon[l] + ')'
    end
    print "\n\n     "
    lex.each {|l| printf( "%4d ", l )}
    print "\n"
    lex.reverse.each_with_index do |lex1, l1|
      printf( "%4d ", lex[lex.length - l1 - 1] )
      lex.each_with_index do |lex2, l2|
        case
         when l2 == lex.length - 1 - l1 
           if e.has_key? 'HOMONYMY MAP' then
             if lex1 == e['HOMONYMY MAP'] then
               print '<===='
             else
               print '.....'
             end	
           else
             print '.....'
           end
           if l1 == 0 then print "\n" end
         when l2 >= lex.length - 1 - l1
           if l2 == lex.length - 1 and l1 == lex.length - 2 then
             printf( "%3d \@", e['@'] )
           elsif l2 == lex.length - 1 and l1 == lex.length - 1 then
             printf( "%3d \%", e['%'] * 100 )
           else
             print '.....'
           end
           if l2 == lex.length - 1 then print "\n" end
        else
          pair = e['#'].find {|p| (p['-'] - [lex1]) - [lex2] == []}
          if pair then
            strength = pair['@']
            printf( "%4d ", strength )
          else
            print '     '
          end
        end
        next
      end
    end
    print "\n"
  end
end


# This function returns the lexeme corresponding to the fusion of the two received lexemes.
#
def fused_lexemes( part1, part2 )

  part1 ? part1_lexeme = $lexicon[part1] : part1_lexeme = ''
  part2 ? part2_lexeme = $lexicon[part2] : part2_lexeme = ''

  return [part1_lexeme, part2_lexeme].join( ' ' ).strip

end


#  This recursive function receives a tree of variations and returns all the permutations it implies.
#
def reconstruction_of( branch )

  part1 = branch['part1']
  part2 = branch['part2']

  if part1.class != Hash and part2.class != Hash then
    
    part1 ? part1_lexeme = $lexicon[part1] : part1_lexeme = ''
    part2 ? part2_lexeme = $lexicon[part2] : part2_lexeme = ''
    
    reconstructed_lexeme = [part1_lexeme] | [part2_lexeme]

    return reconstructed_lexeme.join( ' ' ).strip
  
  end

  if part1.class == Hash then
    part1_lexeme = reconstruction_of( part1 )
  else
    part1 ? part1_lexeme = $lexicon[part1] : part1_lexeme = ''
  end

  if part2.class == Hash then
    part2_lexeme = reconstruction_of( part2 )
  else
    part2 ? part2_lexeme = $lexicon[part2] : part2_lexeme = ''
  end

  reconstructed_lexeme = [part1_lexeme] | [part2_lexeme]

  return reconstructed_lexeme.join( ' ' ).strip

end


# This recursive method parses the possibly nested variations of a formulation and returns a tree of these variations.
#
def tree_of_variations_for( formulation )

  if formulation == nil then 
    return nil
  else
    tree_of_variations = formulation
  end

  if $lexicon_infos[formulation]['<'] != [] then
  
    $lexicon_infos[formulation]['<'].each do |subdivision|

      tree_of_variations = []
  
      part1 = subdivision[0]
      part2 = subdivision[1]
    
      part1 ? part1_synonyms = ([part1] | $lexicon_infos[part1]['~']) - [formulation] : part1_synonyms = [nil]
      part2 ? part2_synonyms = ([part2] | $lexicon_infos[part2]['~']) - [formulation] : part2_synonyms = [nil]
      
      part1_synonyms.each do |part1_synonym|
        part2_synonyms.each do |part2_synonym|
        
             part1 = tree_of_variations_for( part1_synonym )
          if part1.class == Array then part1 = part1[0] end
          
             part2 = tree_of_variations_for( part2_synonym )
          if part2.class == Array then part2 = part2[0] end
        
          tree_of_variations << { 'part1' => part1, 'part2' => part2 }
        
        end
      end
    
    end
  end
  
  return tree_of_variations

end


# This function looks for wishes synonymous to one of the given formulations and returns them.
#
def look_for_wish( wisher, wish, formulations, type_wanted )

  found_wishes = []
  tree_of_variations = []
  
  formulations.each do |formulation|
  
    formulation_synonyms = [formulation] | $lexicon_infos[formulation]['~']
    
    formulation_synonyms.each do |formulation_synonym|

      variations = tree_of_variations_for( formulation_synonym )
    
      if variations.class == Array then 
        tree_of_variations |= variations
      else
        tree_of_variations |= [variations]
      end
    end
  end
  
  
# We will collect here all the possible permutations of reorganized parts of formulations that correspond to formulations.
  
  variations = []
  
  tree_of_variations.each_with_index do |variation, v|

    if variation.class == Hash then

      in_lexicon = $lexicon.index( reconstruction_of( variation ) )
    
      if in_lexicon then variations << in_lexicon end
    
    else
      
      variations << variation
    
    end
  
  end
    
  $wish_lists.each_with_index do |user, user_index|

    if user_index == wisher then next 
    end

    user['list'].each_with_index do |description, description_index|
  
      variations.each do |variation|

        if description['type'] == type_wanted and description['wish'].include? variation then
    
        found_wishes << {        'user' => user_index, 
                               'answer' => description['wish'],
                               'wisher' => wisher,
                                 'wish' => wish                    }
        end
      end
    end
  end
  
  return found_wishes
  
end


# This method tries to find the wishes that answer each of the wishes.
#
def match_wishes( )
  
  all_the_found_wishes = []

  $wish_lists.each_with_index do |user, u|
  
    user['list'].each_with_index do |description, d|
    
      found_wishes = nil
    
      wish = description['wish']
      rest = description['rest']
      if rest == nil then rest = wish end
      
      case description['type']
      
      when :demand
      
        found_wishes = look_for_wish( u, wish, rest, :offer )
      
      when :offer
      
        found_wishes = look_for_wish( u, wish, rest, :demand )
      
      when :interest
      
        found_wishes = look_for_wish( u, wish, wish, :interest )
      
      end
      
      if found_wishes then
        all_the_found_wishes |= found_wishes
      end
      
    end
  end
  
  return all_the_found_wishes

end


#################
# Main program

puts "\n\n"
puts " - Welcome on the Tramice 721 !\n\n"
puts "#################################\n"
puts "# Notes about the version 0.0.1 \n"
puts "#\n"
puts "# This script is a first attempt at building a wish machine such as described\n"
puts "# in the document What is the Mots Sapiens Project ? (README.md) that you can find,\n"
puts "# along with the script presently running, at this GitHub repository : \n"
puts "#\n"
puts "#    https://github.com/fredofromstart/The_Mots_Sapiens_Project.git\n"
puts "#\n\n"
puts " - What is your pseudo ?\n\n"

pseudo = gets.chomp
puts "\n - Aloha, #{pseudo} !\n"

find_suspected_synonyms # This will scan the synonyms and deduce new synonyms, adding to the $elements.

command = nil

# What shall we do now ?

while command != 'quit' and command != 'q' do

  puts ""
  puts "# Type @    to help the wish machine disambiguating homonyms and erroneous"
  puts "#           synonyms by answering a few questions."
  puts "#"
  puts "# Type s    to scan the lexemes and maybe find new synonyms to add to the"
  puts "#           elements."
  puts "#"
  puts "# Type l #  to display #th lexeme within the lexicon. Type without number"
  puts "#           to list all the lexemes that have been found."
  puts "#"
  puts "# Type i    to list the lexicon along with stats about it."
  puts "#"
  puts "# Type e #  to display #th element. Type without number to list all the"
  puts "#           elements that have been found."
  puts "#"
  puts "# Type w    to display each match that the wish machine has found between"
  puts "#           different users' wishes."
  puts "#"
#  puts "# Type r    to refresh data about the current state of the volios."
#  puts "#"
  puts "# Type q    to quit the program."
  puts "#"
  puts "# Other commands will be evaluated as plain Ruby commands."
  puts ""
  puts " - What is your next command ?\n\n"
  command = gets.chomp

  if command != 'quit' and command != 'q' then
    begin
      case command
      when '@'
        verify_with_human   # for errors and homonymy ; calls find_suspected_synonyms()
      when 's'
        find_suspected_synonyms
      when 'i'
        $lexicon_infos.each_with_index {|lexeme, i| puts i.to_s + ' ' + lexeme.inspect}
      when /^l\s*(\d*)/
        print_lexicon($1)
      when /^e\s*(\d*)/
        print_elements($1)        
      when 'w'
        matches = match_wishes
        print "\n#{matches.length} matches have been found :\n\n"
        matches.each do |match|
          print " - User #{match['user']}'s (" + $users[match['user']]['name'] + ") wish ( "
          match['answer'].each do |answer|
            print '"' + $lexicon[answer] + '" '
          end
          print ") answers to user #{match['wisher']}'s (" + $users[match['wisher']]['name'] + ") wish ( "
          match['wish'].each do |wish|
            print '"' + $lexicon[wish] + '" '
          end
          print ").\n\n"
        end
      when '*'
        # Add a new command (!)
      else
        eval command
      end
    rescue => detail
      print detail.backtrace.join("\n")
    end
  end
end

puts "\n - Au revoir, #{pseudo}.\n\n"
