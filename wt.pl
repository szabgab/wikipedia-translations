#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Cwd qw(getcwd);
use Data::Dumper qw(Dumper);
use DBI;
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptions);
use LWP::Simple qw(getstore);
use Web::Query;
use Path::Tiny qw(path);
use JSON qw(decode_json);

my $conf = decode_json path('languages.json')->slurp_utf8;

my $N = 250;


GetOptions(\my %opt, 'help', 'fetch', 'load', 'html') or usage();
usage() if $opt{help};
usage('Need at least one language') if not @ARGV;
my @languages = @ARGV;

if ($opt{fetch}) {
	my @links;
	
	wq('https://dumps.wikimedia.org/backup-index.html')->find('li')->each(sub {
		my ($i, $elem) = @_;  # $elem is a Web::Query object
	    # 2016-01-14 21:23:04 snwiki: Dump complete
		if ($elem->text =~ qr{^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d ([\w-]*wiki): Dump complete$}) {
			my $link = $elem->find('a')->attr('href') // '';
			#printf("li: %s %s\n", $elem->text, $link);  # link is: chwiki/20160111
			push @links, $link;
		}
	
	    #2016-01-17 22:31:42 <a href="huwiki/20160111">huwiki</a>: <span class='done'>Dump complete
		#printf("li: %d %s\n", $i+1, $elem->tagname);  # $elem is a Web::Query object
		
	});
	
	foreach my $link (@links) {
		my ($wiki, $date) = split /\//, $link;
		next if not grep {$wiki eq "${_}wiki"} @languages;
		say "Fetching $wiki files";
		foreach my $file ("$wiki-$date-langlinks", "$wiki-$date-page") {
			say "     $file";
			getstore("https://dumps.wikimedia.org/$link/$file.sql.gz", "sql/$file.sql.gz");
			system "gunzip sql/$file.sql.gz";
		}
	}
}

foreach my $lang (@languages) {
	if ($opt{load}) {
		say "Loading language $lang";
		my @files = glob "sql/${lang}wiki*.sql";
		#print Dumper \@files;
		if (@files == 0) {
			warn "Could not find files for $lang\n";
			next;
		}
		if (@files == 1) {
			warn "Found only one file ($files[0]) for $lang\n";
			warn next;
		}
		if (@files > 2) {
			warn "More than two files found for $lang: " . Dumper \@files;
			next;
		}
		foreach my $file (@files) {
			system "mysql -u root -psecret wikipedia < $file";
		}
	}
	if ($opt{html}) {
		say "Creating HTML for language $lang";
		generate_html($lang);
	}
}



if ($opt{html}) {
	my $html = "<ul>\n";
	foreach my $lang (sort keys %$conf) {
		$html .= qq{    <li><a href="/wikipedia/$lang">$conf->{$lang}{language}</a></li>\n};
	}
	$html .= "</ul>\n";
	path('list.txt')->spew_utf8($html);
}


sub generate_html {
	my ($wiki) = @_;

	my $url = "https://$wiki.wikipedia.org";
	my $dbh = DBI->connect('DBI:mysql:database=wikipedia;', 'root', 'secret');
#AND page_len > 500 
	my $sth = $dbh->prepare(q{
		SELECT page_title, page_id, page_len FROM page WHERE page_namespace=0 AND page_is_redirect=0 AND page_is_new=0 AND page_id NOT IN
                          (SELECT ll_from FROM langlinks WHERE ll_lang='en') ORDER BY page_len DESC LIMIT ?
			});
	$sth->execute($N);
	my $html = "<ul>\n";
	while (my $h = $sth->fetchrow_hashref) {
		$html .= qq{<li><a href="$url/wiki/$h->{page_title}">$h->{page_title}  ($h->{page_len})</a></li>\n};
	}

	my ($total_pages) = $dbh->selectrow_array(q{SELECT COUNT(*) FROM page WHERE page_namespace=0 and page_is_redirect=0 AND page_is_new=0});
	my ($no_english) = $dbh->selectrow_array(q{SELECT COUNT(page_title) FROM page WHERE page_namespace=0 AND page_is_redirect=0 AND page_is_new=0 AND page_id NOT IN
                          (SELECT ll_from FROM langlinks WHERE ll_lang='en')});


	$html .= "</ul>";
		#print Dumper $h;
		#<STDIN>;
use DateTime::Tiny;

	my $date = DateTime::Tiny->now;
	my $rtl = $conf->{$wiki}{rtl} ? q{ class="rtl"} : '';

	my $out = <<"HTML";
=title Wikipedia: $conf->{$wiki}{language} ($wiki)
=timestamp $date
=indexes wikipedia
=status show
=books wikipedia
=author szabgab
=archive 0
=comments_disqus_enable 0
=show_related 0

=abstract start
=abstract end

<!-- This is a generated file. Do not edit manually! -->
<style>
.rtl {
	direction: rtl;
	text-align: right;
}
</style>

<p>
The <a href="$conf->{$wiki}{explain}">$conf->{$wiki}{language}</a> Wikipedia has $total_pages pages. A total of $no_english pages have no link to their English counterpart.
Here we you can see the $N largest articles in that don't have links to their English counterparts.
<p>
These articles either need an interwiki link to the English version of this page (and one from English back to this page),
or they need to be translated to English first and then they need the link to that article.
<p>
Last updated at $date
<p>

<div$rtl>
$html
</div>

HTML

	path("$wiki.txt")->spew($out);
}



sub usage {
	my ($msg) = @_;
	if ($msg) {
		print "\n * $msg\n\n";
	}
	print <<"USAGE";
Usage: $0 
           --fetch
           --load
           --html
           LANGUAGES    (eg: hu fi tr)

           --help  (this help)
USAGE
	exit;
}

# https://dumps.wikimedia.org/huwiki/20160111/huwiki-20160111-langlinks.sql.gz
#suwiki-20160111-
#suwiki-20160111-page.sql.gz 
# <li>2016-01-17 22:31:42 <a href="huwiki/20160111">huwiki</a>: <span class='done'>Dump complete</span></li>




