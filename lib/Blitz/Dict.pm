package Blitz::Dict;

use warnings;
use strict;
use Carp;

use Data::Dumper;
use List::MoreUtils qw(any);
use Storable qw(retrieve store_fd thaw);
use WWW::Dict::Leo::Org;

use base 'Exporter';

our @EXPORT = qw(dict_read dict_write dict_add leo_translate stem);

my @suffixes = qw(en er es haft heit ig igen keit lich ologie sch schaft ung);

=head2 munge_defns
    Simplify the structure returned from Dict::Leo to only have the
    English and German translations and the appropriate part of speech.
=cut
sub munge_defns {
    my ($word, $categories) = @_;
    my @defns = ();

    # Basic forms will have the title: Mögliche Grundformen für das Wort "<infinitive>"
    my @roots = grep $_->{title} =~ /Grundformen/, @$categories;
    my $root = $roots[0]->{data}[0]{right} || $word;

    foreach my $cat (@$categories) {
           next if $cat->{title} =~ /Grundformen/;

        my @translations = @{$cat->{data}};
        foreach my $tr (@translations) {
            my $obj = {
                root => $root,
                type => $cat->{title},
                en   => $tr->{left},
                de   => $tr->{right}
            };

            push(@defns, $obj);
        }
    }

    \@defns;
}

=head2 dict_read(dict_path = "../data/words.db")
    Returns an arrayref of {en, de, root, type} hashes stored in the supplied path.
=cut
sub dict_read {
    my $dict_path = shift || "../data/words.db";

    if (-e $dict_path) {
        retrieve($dict_path);
    } else {
        [];
    }
}

=head2 dict_add(dict, triples)
    Adds a hashref of an {en, de, type} triple, if not already present, into
    the supplied database. (TODO: O(n^2)).  Returns the number of non-duplicate
    elements added.
=cut
sub dict_add {
    my $dict = shift;
    my $defns = shift;

    # leo_translate returns undef on HTTP != 200.
    return 0 if not defined($defns);

    my $dict_sz = scalar @$dict;

    foreach my $d (@$defns) {
        push @$dict, $d unless any {$_->{en} eq $d->{en} and
                                    $_->{de} eq $d->{de} and
                                    $_->{root} eq $d->{root} and
                                    $_->{type} eq $d->{type} } @$dict;
    }
    return (scalar @$dict) - $dict_sz;
}

=head2 dict_write(dict, dict_path="../data/words.db")
    Writes the supplied list of {en, de, type} triples to the supplied path.
=cut
sub dict_write {
    my $dict = shift;
    my $dict_path = shift || "../data/words.db";

    open(my $fd, ">", $dict_path) or die("Can't write to db: $!");
    store_fd($dict, $fd);
    close ($fd);
}

=head2 leo_translate(word)
    Given a word, query the Leo dictionary for definitions.  Returns an array of
    hashes containing the English and German words and the type of definition it is.
=cut
sub leo_translate {
    my $word = shift;

    my $defns = eval {
        my $leo = new WWW::Dict::Leo::Org();
        my @leo_result = $leo->translate($word);
        munge_defns($word, \@leo_result);
    };
    if ($@) {
        warn "Got error back from Leo: $@";
    }
    $defns;
}

=head2 stem(word)
    Attempt to stem a word with a given dictionary.  Returns an arrayref of
    arrays of stems.

    TODO: should match $l against a common set of suffixes if $r is empty.

    E.g. "Ausländer" => [ ["Ausländer"], ["Aus", "länder"] ]
=cut
sub stem {
    my ($word, $dict) = @_;

    my @letters = split //, $word;
    my @stems = ();

    # Exact match and suffix-match
    if ((any {lc($word) eq lc($_)} @$dict) or
        (any {lc($word) eq lc($_)} @suffixes)) {
        push @stems, [$word];
    }

    for my $i (0 .. $#letters - 1) {
        my $l = join "", @letters[0..$i];
        my $r = join "", @letters[$i+1..$#letters];

        if (any {lc($l) eq lc($_)} @$dict) {
            my $suffixes = stem($r, $dict);
            return [] if scalar($suffixes) == 0;

            for my $suffix (@$suffixes) {
                unshift @$suffix, $l;
                push @stems, $suffix;
            }
        }
    }

	@stems = sort { scalar($a) <=> scalar($b) } @stems;
    \@stems;
}

1; # Magic true value required at end of module
__END__
