#!/usr/bin/perl

use warnings;
use strict;

use Blitz::Dict;

use CGI;

my $q = CGI->new;

sub url_format {
	my $words = shift;
	my @urls = ();

	foreach my $word (split /\s+/, $words) {
		my $sterm = $word;
		$sterm =~ s/[#\-%&\$*+()]//g;
		push @urls, $q->a({-href => 'https://dict.leo.org/#/search=' . $sterm}, $word);
	}
	join " ", @urls;
}

my $dict = Blitz::Dict::dict_read("data/words.db");
my $trans = @$dict[rand scalar(@$dict)];

print $q->header(-type=>'text/html', -expires=>'+0d');
print $q->start_html("Blitz!");

print $q->center(
	$q->h1($trans->{"en"}),
	$q->br,
	$q->h1(url_format($trans->{"de"}))
);
print $q->end_html;

