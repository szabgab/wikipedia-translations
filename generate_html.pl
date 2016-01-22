#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper qw(Dumper);
use DBI;

my $language = 'Sundanese';
my $wiki = 'su';
my $explain = 'https://en.wikipedia.org/wiki/Sundanese_language';
my $url = "https://$wiki.wikipedia.org";

my $N = 100;


generate_html();


sub generate_html {
	my $dbh = DBI->connect('DBI:mysql:database=wikipedia;', 'root', 'secret');
	my $sth = $dbh->prepare(q{
		SELECT page_title, page_id, page_len FROM page WHERE page_namespace=0 AND page_is_redirect=0 AND page_is_new=0 AND page_len > 500 AND page_id NOT IN
                          (SELECT ll_from FROM langlinks WHERE ll_lang='en') ORDER BY page_len DESC LIMIT ?
			});
	$sth->execute($N);
	my $html = "<ul>\n";
	while (my $h = $sth->fetchrow_hashref) {
		$html .= qq{<li><a href="$url/wiki/$h->{page_title}">$h->{page_title}  ($h->{page_len})</a></li>\n};
	}
	$html .= "</ul>";
		#print Dumper $h;
		#<STDIN>;
	my $time = gmtime();

	print <<"HTML";
<p>
The top $N largest articles in <a href="$explain">$language</a> that don't have links to their English counterparts.
<p>
Last updated at $time
<p>
These articles either need an interwiki link to the English version of this page (and one from English back to this page),
or they need to be translated to English first and then they need the link to that article.
HTML

	print $html;
}


