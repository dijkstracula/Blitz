#!/usr/bin/perl

use warnings;
use strict;

use Blitz::Dict;
use Data::Dumper;
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

sub roots_from_dict {
    my $dict = shift;
    my %hash;

    for my $defn (@$dict) {
        for my $word (split /\s+/, $defn->{de}) {
            $hash{$word}++;
        }
    }
    my @keys = keys %hash;
    \@keys;
}

sub stem_format {
    my ($word, $roots) = @_;
    my $stems = Blitz::Dict::stem($word, $roots);

	if ((scalar (split /\W+/, $word) > 1) or (scalar @$stems) <= 1) {
		return;
	}

	$q->table(
		map { 
			my $row = $_;

			$q->Tr(
				map {
					my $entry = $_;
					$q->td($entry);
				} @$row
			);
		} @$stems,
	);
} 
my $dict = Blitz::Dict::dict_read("data/words.db");
my $trans = @$dict[rand scalar(@$dict)];

print $q->header(-type=>'text/html', -expires=>'+0d', -charset=>'utf-8');
print $q->start_html("Blitz!");
print $q->center(
    $q->h1("Translation"),
    $q->br,
    $q->h2($trans->{"en"}),
    $q->br,
    $q->h2(url_format($trans->{"de"}))
);

print $q->center(
    $q->b("Possible stemmings of root word \"" . $trans->{"root"} . "\":"),
    $q->p,
    stem_format($trans->{"root"}, roots_from_dict($dict)),
);

print $q->end_html;

