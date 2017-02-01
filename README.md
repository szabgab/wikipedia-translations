Wikipedia - suggesting pages for translation
=============================================

See article: https://code-maven.com/wikipedia


There are several ways to suggest which pages to translate.

1. Unless the topic is very language orcountry specific, there is no reason to have a wikipedia
   entry in a language, but not in English. So the first caste would be
   pages that available in a language other than English, but have no apparent English translations.
   These articles might actually have an English version we just don't have the appropriate interwiki link.
   Then the task is easy. Add the interwiki links.
   If there really is no English version then they probably should be translated to English and then the
   interwiki link can be added.

2. Pages that are popular should probably have translations in more languages.
   AFAIK We don't have access to visitors statistics, but we can measure popularity by the number
   of translations. When considering which page to translate to your language, it would probably make more sense
   to translate a page that already has been translated to more languages than the other page.
   So find the pages with the most translations that are not translated a particular language.

3. Partially translated pages. If an English article that has 1000 words has a French version which is only 100 words
   long then it is quite clear that the French version is missin a lot of content. Such pages would be good places
   to contribute.

- All the above could be filtered by topic. So "all the pages in one of the above groups that are in the category 'Chemists'"



More idea
==========

* Show the date of the dumping

* Make  the list more dynamic. Maybe start by a bigger list, and the let the user mark a certain entry as 'done'.
When the visitor says it is done we can automatically remove the entry from the list (or at least mark it as 'done'
and not display it any more, or, if we would like to be more cautious, we can actually dowload the respective wikipedia
page and check if it has a link to the English version and if that English version has a link back to this page.


* Separate database for each language (probably only needed if we would like to have live queries in a dynamic application)
* Instead of static pages of the top 100 articles, create a dynamic page. (Why would this be good?)

* Maybe we would like to have some cross-language statistics? (e.g. the largest pages without English links among all the wikipedias?)

* Improve speed. It took I think 2-3 minutes to download the Hebrew files (which are 260 Mb) and 10 minutes to load them in a Vagrant box
  on my Macbook Air.
  The Arabic files (which are 570 Mb) took 40 minutes to load into the database and 36 sec to generate the html.


The code
==========

languages.json - the list of langiages we are dealing with.

wt.pl - the script that does the work.


Installation
============
On Digital Ocean we need to install
apt-get install unzip libdbd-mysql-perl libwww-perl libpath-tiny-perl libweb-query-perl libjson-perl libdatetime-tiny-perl


$ wget https://github.com/szabgab/wikipedia-translations/archive/master.zip
$ unzip master.zip
$ cd wikipedia-translations-master/


Related pages
===============
* [Wikipedia:Pages needing translation into English](https://en.wikipedia.org/wiki/Wikipedia:Pages_needing_translation_into_English)
* [Wikipedia:Translators available](https://en.wikipedia.org/wiki/Wikipedia:Translators_available) for translating from other languages to English
* [Category:Available translators in Wikipedia](https://en.wikipedia.org/wiki/Category:Available_translators_in_Wikipedia) list of all the Wikipedia translators
* [Wikipedia:Translation](https://en.wikipedia.org/wiki/Wikipedia:Translation)

