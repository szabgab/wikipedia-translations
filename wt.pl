#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Cwd qw(getcwd);
use Web::Query;
use LWP::Simple qw(getstore);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptions);

GetOptions(\my %opt, 'help', 'fetch') or usage();
usage() if $opt{help};
usage() if not @ARGV;
my @languages = @ARGV;

if ($opt{fetch}) {
	my @links;
	
	wq('https://dumps.wikimedia.org/backup-index.html')->find('li')->each(sub {
		my ($i, $elem) = @_;  # $elem is a Web::Query object
	    # 2016-01-14 21:23:04 snwiki: Dump complete
		if ($elem->text =~ qr{^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d (\w*wiki): Dump complete$}) {
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

if ($opt{load}) {
	system "mysql -u root -psecret wikipedia < a.sql";
	system "mysql -u root -psecret wikipedia < b.sql";
}

sub usage {
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




