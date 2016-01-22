#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Cwd qw(getcwd);
use Web::Query;
use LWP::Simple qw(getstore);
use File::Temp qw(tempdir);

my @links;

wq('https://dumps.wikimedia.org/backup-index.html')->find('li')->each(sub {
	my ($i, $elem) = @_;  # $elem is a Web::Query object
    # 2016-01-14 21:23:04 snwiki: Dump complete
	if ($elem->text =~ qr{^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d (\w\wwiki): Dump complete$}) {
		my $link = $elem->find('a')->attr('href') // '';
		printf("li: %s %s\n", $elem->text, $link);  # link is: chwiki/20160111
		push @links, $link;
	}

    #2016-01-17 22:31:42 <a href="huwiki/20160111">huwiki</a>: <span class='done'>Dump complete
	#printf("li: %d %s\n", $i+1, $elem->tagname);  # $elem is a Web::Query object
	
});

foreach my $link (@links) {
	my ($wiki, $date) = split /\//, $link;
	next if $wiki ne 'suwiki';
	my $old_dir = getcwd();
	my $dir = tempdir( CLEANUP => 1 );
	chdir $dir;
	getstore("https://dumps.wikimedia.org/$link/$wiki-$date-langlinks.sql.gz", "a.sql.gz";
	system "gunzip a.sql.gz";
	system "mysql -u root -psecret wikipedia < a.sql";

	getstore("https://dumps.wikimedia.org/$link/$wiki-$date-page.sql.gz", "b.sql.gz";
	system "gunzip b.sql.gz";
	system "mysql -u root -psecret wikipedia < b.sql";


	my $dbh = DBI->connect('DBI:mysql:database=wikipedia;', 'root', 'secret');
	my $sth = $dbh->prepare('SELECT page_title, page_id, page_len FROM page WHERE page_namespace=0 AND page_is_redirect=0 AND page_is_new=0 AND page_len > 500 AND page_id NOT IN
                           (SELECT ll_from FROM langlinks WHERE ll_lang='en') ORDER BY page_len DESC LIMIT 100');
	$sth->execute;
	while (my $h = $sth->fetchrow_hashref) {
	}
}

# https://dumps.wikimedia.org/huwiki/20160111/huwiki-20160111-langlinks.sql.gz
#suwiki-20160111-
#suwiki-20160111-page.sql.gz 
# <li>2016-01-17 22:31:42 <a href="huwiki/20160111">huwiki</a>: <span class='done'>Dump complete</span></li>




