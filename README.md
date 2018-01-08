
README.md

a.k.a.

Journal Entry n° 1

a.k.a.



What is the Mots Sapiens Project ?
***********************************

a presentation



Note on the name : In French, « mots » translates as _words_ (the ending consonants are silent, so « Mots Sapiens » rhymes with « Homo Sapiens »). « Sapiens » means _wise_ . . . Let's see if there is any wisdom in the words we use everyday. ^^



Hi there !

This introduction describes the Mots Sapiens Project's intent and the global approach undertaken at developing it, as of March 2013. At this date, the only software that has been developed for this project consists of a very rudimentary piece of code, an incomplete and rather sketchy Ruby script — called « tramice_721.0.0.1.rb » —, which is nonetheless somewhat functional.

To learn where the project is at, what has been accomplished, what remains yet to be done as well as possible changes to its mission and approach, please read the Journal Entries to come ; please also refer yourself freely to the commented source files tendered on the present repository : 

  https://github.com/fredofromstart/The_Mots_Sapiens_Project.git



SO, WHAT IS IT ALL ABOUT ?

In two words, The Mots Sapiens Project aims at building a fully functional « wish machine » — at least one, anyway. (Preferably many more !) I called the first prototype « la Tramice 721 » upon a play of words in French which, if you are curious to know, refers to « La Matrice », the French title for « The Matrix » movie. In fact, this Tramice 721 should, if correctly programmed, do precisely the opposite of what the Matrix does in the movie. It should not drain people's energy and blind them, but rather _empower_ them ; it should not lure them, but rather give them a comprehensive and practical way to navigate life, with hints about how to build together a comprehensive, fluid, plural, colorful, solidary — in one word : _emergent_ — world.  The number 721 was added to differentiate this software from other potential future ones using the same play of words.

In more twisting words now, a wish machine is a software designed to inform wishers of which wishers are wishing wishes that are satisfactory answers to the wishes that are listed in their wish lists. (We are talking about concrete, practical wishes, here, not about some wishy-washy kind of stuff !^)

Users with matching wishes will be informed of one another's existence and eventually will communicate and meet. In the end, it is up to them whether or not any wishes are granted. _That's_ the real magic of the whole concept : _communicating beings_ are the ones who will propel the whole thing by their needs and perhaps dreams as much as by their responses to one another. The wish machine is, in itself, something like an extension, a development of the faculty of communication ; after language and alphabet and press and the net : a new tool, an _emergeware_.

This tool does more than organize fixed-in scheduled activities. With operational wish machines around, you simply, day by day, _as you wish_ indeed, state what you wish for the moment and you will be informed of which other people are presently wishing something that is an appropriate answer to what you wish (of course, people wish to offer as well as to obtain, and maybe even more : _to share_).

Let us muse for an instant on the idea of a « communicational era » where there are, finally, tools that diverse and variant beings use to optimize their interactions and use of resources, dwelling places, etc. ; where one can literally design one's environment, within basic do-no-harm principles ; where one can also be able to navigate, as freely as possible, between environments ; where, last but not least, schools and « retreats » provide open paths leading to all environments existing and possible…

As dreamlike as this may sound in the somewhat wrecked and mislead world of 2013, isn't the idea of a communicational, emergent world an interesting avenue to consider ?


HOW IS A « WISH MACHINE » EVEN POSSIBLE ?!?

The approach chosen here takes advantage of the inherent coherence of language and communication. We will simply feed our wish machines wishes written in our common natural languages.

The big and simple idea here is that the wishers are asked to formulate each of their wishes _in at least two different manners_ (either using different languages or synonyms in the same language), and to append to each of these wishes examples of wishes that would be adequate answers to them, also formulated in multiple manners.

Given that data, a correctly conceived algorithm can find, among gathered synonymous wishes, parts that correspond literally, and assume that the remaining parts are also synonymous. From that first analysis, more subdivisions of the wishes can be found. The algorithm, after having separated the wishes in their constituent parts, can then recombine them so as to correctly find more and more of the wishes that are correct answers to other wishes and to inform their authors accordingly.

For that, the wish machine should also be able to correctly identify these tricky homonyms, and locate erroneous synonyms. That, the first prototype makes an attempt to. Also, in future versions, measures must be taken toward the question of (mis)spelling ! (Maybe via crowdsourcing ?)


THE MOTS SAPIENS FORMAT

In order to reduce the number of ways to express each wish, a « canonical » format is suggested : the Mots Sapiens Format. This format suggests to start with _an infinitive verb_ that would be the continuation of the sentence « I wish . . . ». In English, the canonical versions of a wish starts with « to ». Other ways of expressing the wishes are also acceptable.

The format for a wish is this :

a wish, expressed in one way // the same wish, but expressed in a different manner, possibly in a different language // again exactly the same wish, yet formulated in another fashion // etc. << an example of a wish that would answer this one adequately // another way to express that example << a different example of a wish that would be an adequate answer // another way to express that example // etc. 

Notes : The period belongs with « the etc. » (which stands for yet another manner of expression), no ending period is necessary for the formulations. Any formulation can be written in any language. Also, if you make the « << » « >> », it becomes to mean that the first wish is an offer you make that would be an adequate answer to the following wishes (all preceded with « >> » instead of « << »). For objects, you may simply write the name of the object in many languages or in many synonymous ways (without the verb) and use either « << » or « >> » after that to indicate if the object is wanted of offered. To indicate that your wish is urgent, simply include the word « urgent » (or a synonym) in your wish.

If the wish is not followed by either a « << » nor a « >> », the wish machine will assume that the wish is not a demand nor an offer, but an _interest_ that the wisher is hoping to share with someone who has the same interest.

Each wish so formulated can be followed by a number within parentheses to indicate the minimum number of users whose wishes are a satisfactory answer to it. This could be useful for things requiring a certain number of participants such as teams. ^^

Examples may be seen at : http://motsapiensproject.wikia.com/wiki/Volios

*

It would probably be a good idea, in the future, to ask the users to specify in which _language_ each wish is written. At this time, the prototype that has been made proceeds without knowing anything about languages. A simple way to include language to the classification of the wishes would be to ask the users to include that specification in their wishes. For example, the format could suggest to prefix each formulation with a version or another of the ISO 639 code for language, immediately followed by a period.


OTHER CONSIDERATIONS

Transparency comes with a downside : it may make the people publishing data somewhat more vulnerable to potentially ill-intentioned entities who could use their very dreams in order to lure them into a trap. But what then ? Should we throw the whole idea of a wish machine into the trashcan just because some may misuse it ? Isn't transparency supposed to be a guarantee of clarity and security (unless you aim at doing something reprehensible) ? 

Actually, ill-intentioned users should think twice before they use such a machine to lure people, because a good wish machine should come with a feedback system where truth wins in the end. For such a feedback security system to be effective, users should specify beforehand on their volios (another name for their wish lists) which user(s) they are going to be working with or meeting. For this system to be effective, _user inscription_ would have to be implemented in due form, so that the users' true identities are established. Regardless, users are advised to at least make initial meetings in public areas.

*

Additionally, this kind of er… _emergeware_ should also take into account each wisher's : location, range, schedule, itineraries and availabilities — for, obviously, a good wish machine surely assists users with their appointment fixing, doesn't it ?

*

Obviously, it seems only ethical that a wish machine correctly informs each user of local _needs_ that exist around her or him, and also (through a feedback system) of the possible _consequences_ that each of her or his wishes may entail.

*

This approach is interesting because it is entirely emergent, _evolutive_. No synonym lists need to be pre-loaded, everything comes from the users' usages of language. Proportionally to its usage, this tool will be literally _growing_ some intelligence about wishes. 

In other words, it is as easy to _add_ new words to the collected and merged semantical lexicons as to _use_ them. 

You can even invent a new language altogether. It will be treated by the machine exactly as the existing ones, as long as it is coherent.


WHAT'S NEXT ?

Why, a graphical user interface, of course, with all the flourishes that it supposes (again, _at least_ one, preferably many), in order for the users to be able to visualize the communicational elements (those wish parts the machines will have excerpted) and redact their volios with but a few gestures. That interface should also aptly present the _echoes_ (the answers) to their wishes. Iconization of the communicational elements will enable interesting shortcuts, for example, we could use semantic icons on the screen, as so many keys to punch or click (like on a virtual keyboard), in order to swiftly express our practical communications.

A graphical interface would indeed be an interesting medium for enshrining a full-fledged multimedia dictionary (proposed name : « the D'ico ») where each communicational element would have its own page listing every way of expressing it. A _perso_ mode would allow users to see only certain languages and chosen formulations, while the _cosmo_ mode would display e-ve-ry way of expressing each element. Statistical tools would allow the users to detect, among other things, the new formulations whose usage is rapidly growing. Thus, catchy new formulations could become globally known very quickly. The D'ico, along with the wish machine, could indeed become a very efficient incubator for the evolution of language !

A domain name has been reserved for one or many attempts at that ulterior phase : iconVerse.info. 

*

Have you noticed the trend ? Volio, Echo, D'ico, Cosmo, Perso ;)

*

It would be interesting to have many versions of « wish machines » and to have them communicate with each others on an « information net », so as to be able to regularly and mutually update their databases with data the other machines will have gathered. We have to think of a protocol, or a standard, here.

*

Moreover, to have many versions would be good for the evolution of the tool, through the users' choices of version(s).


WHO ARE WE ?

Well, as of February 2013, there is no team as such. Apparently, I am more an inventor than an entrepreneur, and even more a writer and aspiring philosopher than an inventor. Okay, I programmed that little script, but frankly I would prefer the technical side of this project to be undertaken by more skilled individuals than me, ideally by whole teams. (Note : an emergeware, to work well, needs that _many_ use it, so a knack for dialoguing with the public is an asset.) I would probably be willing to give a hand to such individuals and teams, but probably remotely, through the net. I presently wish to concentrate my efforts in the writing of a novel that discusses a world based upon — big surprise — a paradigm of communicational emergence. I also have ideas for a comic book that would convey the same message in a more synthetic way.

I don't know where I'll settle, but I could locally use some help for sorting out and editing my notes ! I'm presently living in Quebec City, but I'm longing for the countryside.

Fred Mir, March 2013

(My real name is Frédéric Lemire, but I use Fred Mir on Facebook and some other places.)

Please, contact me at fredofromstart@gmail.com

My blog :

   http://fredofromstart.wordpress.com

------------------

Please, do download any of the available wish machines versions on this repository and try them out !

To install a Ruby interpreter on your computer, so as to be able to run the script, I recommend this site : http://www.ruby-lang.org/en/downloads/. 

To launch the script, enter « ruby tramice_721.0.0.1.rb » on the command line.

You are of course invited to write your own wish list (or volio) on this wiki devoted to the project : http://motsapiensproject.wikia.com/wiki/Home ; hopefully, there will soon be many other places where to write and update your volio. 

------------------

MIT License (MIT)

Copyright (c) 2013 Frédéric Lemire 

a.k.a. Fred Mir (on Facebook, Google+, and Wordpress among other places)
email : fredofromstart@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
