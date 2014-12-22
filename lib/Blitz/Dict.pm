package Blitz::Dict;

use warnings;
use strict;
use Carp;

use Data::Dumper;
use List::MoreUtils qw(any);
use Storable qw(retrieve store_fd thaw);
use WWW::Dict::Leo::Org;

use base 'Exporter';

our @EXPORT = qw(dict_read dict_write dict_add leo_translate);

my $leo = new WWW::Dict::Leo::Org();

=head2 to_triple
    Simplify the structure returned from Dict::Leo to only have the 
    English and German translations and the appropriate part of speech.
=cut
sub to_triple {
    my $categories = shift;
    my @defns = ();

    foreach my $cat (@$categories) {
        my @translations = @{$cat->{data}};

        foreach my $tr (@translations) {
            my $obj = {
                type => $cat->{title},
                en   => $tr->{left},
                de   => $tr->{right}
            };

            next if (scalar split /\s+/, $obj->{de}) > 4 or
                (scalar split /\s+/, $obj->{en}) > 4;
            push(@defns, $obj); 
        }
    }

    \@defns;
}

=head2 dict_read(dict_path = "data/words.db")
    Returns a list of {en, de, type} triples stored in the supplied path.
=cut
sub dict_read {
    my $dict_path = shift || "data/words.db";
    retrieve($dict_path);
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
                                    $_->{type} eq $d->{type} } @$dict;
    }
    return (scalar @$dict) - $dict_sz;
}

=head2 dict_write(dict, dict_path="data/words.db")
    Writes the supplied list of {en, de, type} triples to the supplied path.
=cut
sub dict_write {
    my $dict = shift;
    my $dict_path = shift || "data/words.db";

    open(my $fd, ">:encoding(UTF-8)", $dict_path) or die("Can't write to db: $!");
    store_fd($dict, $fd);
    close ($fd);
}

=head2 leo_translate(word)
	Given a word, query the Leo dictionary for definitions.  Returns an array of
	hashes containing the English and German words and the type of definition it is.
=cut
sub leo_translate {
    my $word = shift;

	my $triple = eval {
	    my @leo_result = $leo->translate($word);
    	to_triple(\@leo_result);
    };
    if ($@) {
		warn "Got error back from Leo: " . $@ . "\n";
		undef;
    }
    $triple;
}

1; # Magic true value required at end of module
__END__
