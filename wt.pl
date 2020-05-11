#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use autodie;
use Cwd qw(getcwd);
use Data::Dumper qw(Dumper);
use DBI;
use Encode qw(decode);
use File::Copy qw(move);
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptions);
use LWP::Simple qw(getstore);
#use Web::Query;
use Path::Tiny qw(path);
use JSON qw(from_json);
use POSIX ();

my $languages_json = 'languages.json';
my $json_str = do {
    open my $fh, '<:encoding(UTF-8)', $languages_json;
    local $/ = undef;
    <$fh>;
};
#print($json_str);
#exit;
my $conf = from_json( $json_str, { utf8  => 0 } );

my $N = 250;


GetOptions(\my %opt, 'help', 'fetch', 'load', 'html', 'date=s', 'all') or usage();
usage() if $opt{help};
usage() if not $opt{date};
my @languages = @ARGV;
if ($opt{all}) {
    @languages = sort keys %$conf;
}
usage('Need at least one language') if not @languages;


if ($opt{fetch}) {
    foreach my $lang (@languages) {
        say $lang;
        # https://dumps.wikimedia.org/hewiki/20170120/
        # files to download:
        # https://dumps.wikimedia.org/hewiki/20170201/hewiki-20170201-langlinks.sql.gz
        # https://dumps.wikimedia.org/hewiki/20170201/hewiki-20170201-page.sql.gz
        mkdir 'sql' if not -e 'sql';
        foreach my $type ("langlinks", "page") {
            my $gzfile = "${lang}wiki-$opt{date}-$type.sql.gz";
            my $file = substr $gzfile, 0, -3;
            my $url = "https://dumps.wikimedia.org/${lang}wiki/$opt{date}/$gzfile";
            say $url;
            my $start = time;
            if (not -e "sql/$gzfile" and not -e "sql/$file") {
                my $exit_code = system "wget $url";
                die "Exit code $exit_code. Could not fetch from $url\n" if $exit_code;
                move $gzfile, "sql/$gzfile";
                system "gunzip sql/$gzfile";
            }
            my $end = time;
            say "Elapsed: ", ($end-$start);
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
        system "mysql -u root -psecret -e 'DROP DATABASE wikipedia'";
        system "mysql -u root -psecret -e 'CREATE DATABASE wikipedia'";
        foreach my $file (@files) {
            system "mysql -u root -psecret wikipedia < $file";
        }
    }
    if ($opt{html}) {
        say "Creating HTML for language $lang";
        generate_html($lang);
    }
}


#if ($opt{html}) {
#   my $html = "<ul>\n";
#   foreach my $lang (sort keys %$conf) {
#       $html .= qq{    <li><a href="/wikipedia/$lang">$conf->{$lang}{language}</a></li>\n};
#   }
#   $html .= "</ul>\n";
#   path('list.txt')->spew_utf8($html);
#}


sub generate_html {
    my ($wiki) = @_;

    my $url = "https://$wiki.wikipedia.org";
#AND page_len > 500
    my $skip = '';
    if ($conf->{$wiki}{skip}) {
        $skip = 'AND page_title NOT IN (' . join(",", map { qq{"$_"} } @{ $conf->{$wiki}{skip} }) . ')';
    }
    my $sql = qq{
        SELECT page_title, page_id, page_len
        FROM page
        WHERE
                page_namespace=0
            AND page_is_redirect=0
            AND page_is_new=0
            AND page_id NOT IN (SELECT ll_from FROM langlinks WHERE ll_lang='en')
            $skip
        ORDER BY page_len DESC LIMIT ?
    };

    my $dbh = DBI->connect('DBI:mysql:database=wikipedia;', 'root', 'secret');
    my $sth = $dbh->prepare($sql);
    $sth->execute($N);
    my $html = "<ul>\n";
    while (my $h = $sth->fetchrow_hashref) {
        my $page_title = decode('UTF-8', $h->{page_title});
        my $page_len = commafy($h->{page_len});
        $html .= qq{<li><a href="$url/wiki/$page_title">$page_title  ($page_len)</a></li>\n};
    }

    my ($total_pages) = $dbh->selectrow_array(q{SELECT COUNT(*) FROM page WHERE page_namespace=0 and page_is_redirect=0 AND page_is_new=0});
    my ($no_english) = $dbh->selectrow_array(q{SELECT COUNT(page_title) FROM page WHERE page_namespace=0 AND page_is_redirect=0 AND page_is_new=0 AND page_id NOT IN
                          (SELECT ll_from FROM langlinks WHERE ll_lang='en')});

    $total_pages = commafy($total_pages);
    $no_english  = commafy($no_english);


    $html .= "</ul>";

    my $timestamp = POSIX::strftime("%Y-%m-%dT%H:%M:%S", localtime());
    my $rtl = $conf->{$wiki}{rtl} ? q{ class="rtl"} : '';

    my $out = <<"HTML";
=title Wikipedia: $conf->{$wiki}{language} ($wiki)
=timestamp $timestamp
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
Here you can see the $N largest articles that don't have links to their English counterparts.
<p>
These articles either need an interwiki link to the English version of this page (and one from English back to this page),
or they need to be translated to English first and then they need the link to the English version.
<p>
Last updated at $timestamp using dump from $opt{date}
<p>
Read more about <a href="/wikipedia">this project</a>, look at the source code on GitHub, mark some of the pages to be skipped from this list.
<p>

<div$rtl>
$html
</div>

HTML

    open my $fh, '>:encoding(UTF-8)', "$wiki.txt";
    print $fh $out;
    close $fh;
}

sub commafy {
    my $s = shift;
    1 while $s =~ s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $s;
}


sub usage {
    my ($msg) = @_;
    if ($msg) {
        print "\n * $msg\n\n";
    }
    my $languages = join " ", sort keys %$conf;
    print <<"USAGE";
Usage: $0 
           --date [latest | YYYYMMDD]
           --fetch
           --load
           --html

           --all
           LANGUAGES    ($languages)

           --help  (this help)
USAGE
    exit;
}

sub list_pages {
    my $dbh = DBI->connect('DBI:mysql:database=wikipedia;', 'root', 'secret');
    my $sth = $dbh->prepare('SELECT page_title from page LIMIT 20');
    $sth->execute();
    while (my $h = $sth->fetchrow_hashref) {
        say decode('UTF-8', $h->{page_title});
    }
}

# vim: expandtab

