Find which pages on the XY (language) wikipedia have no links to corresponding pages on the English Wikipedia.
These articles either need an interwiki link to English (and one from English back to this page) or they need
to be translated to English first.


Ideas for improvement:
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
