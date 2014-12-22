package Blitz::Dict;

use warnings;
use strict;
use Carp;

use Data::Dumper;
use List::MoreUtils qw(any);
use Storable qw(retrieve store_fd thaw);
use WWW::Dict::Leo::Org;


use base 'Exporter';

our @EXPORT = qw(db_read db_write db_add);

my $leo = new WWW::Dict::Leo::Org();
my @words = words_from_file("data/phrases");

=head1 NAME

Blitz::Dict - German flash card generator dictionary routines

=head1 VERSION

This document describes Blitz version 0.0.1

=head1 AUTHOR

Nathan Taylor  C<< <nbtaylor@gmail.com> >>

=head1 SYNOPSIS

    my $db = db_read();
    print "Adding " . db_add($db, leo_translate("Quatsch!")) . " elements\n";
    db_write($db);

=head1 DESCRIPTION
    
    TODO


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Nathan Taylor C<< <nbtaylor@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=head1 FUNCTIONS

=head2 words_from_file
    Given a filename, returns an array of all the (unique) words
    in the file.
=cut
sub words_from_file {
    my $filename = shift;
    my %words = ();
    open(IFILE, $filename) or die "Can't read $filename: $!";

    while (defined (my $line = <IFILE>)) {
        chomp $line;
        next if $line =~ /^#/ or $line =~ /^\s*$/;
        foreach my $w (split /\s+/, $line) {
            $w =~ s/[[:punct:]…]//g;
            $words{$w}++;
        }
    }

    close(IFILE);

    keys %words;
}

=head2 to_triple
    Simplify the structure returned from Dict::Leo to only have the 
    English and German translations and the appropriate part of speech.
=cut
sub to_triple {
    my @categories = @_;
    my @defns = ();

    foreach my $cat (@categories) {
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

=head2 db_read(db_path = "words.db")
    Returns a list of {en, de, type} triples stored in the supplied path.
=cut
sub db_read {
    my $db_path = shift || "words.db";

    if (-e $db_path) {
        retrieve($db_path);
    } else {
        [];
    }
}

=head2 db_add(dict, triples)
    Adds a hashref of an {en, de, type} triple, if not already present, into
    the supplied database. (TODO: O(n^2)).  Returns the number of non-duplicate
    elements added.
=cut
sub db_add {
    my $dict = shift;
    my $defns = shift;

    my $dict_sz = scalar @$dict;

    foreach my $d (@$defns) {
        push @$dict, $d unless any {$_->{en} eq $d->{en} and 
                                    $_->{de} eq $d->{de} and
                                    $_->{type} eq $d->{type} } @$dict;
    }
    return (scalar @$dict) - $dict_sz;
}

=head2 db_write(dict, db_path="words.db")
    Writes the supplied list of {en, de, type} triples to the supplied path.
=cut
sub db_write {
    my $dict = shift;
    my $db_path = shift || "words.db";

    open(my $fd, ">:encoding(UTF-8)", $db_path) or die("Can't write to db: $!");
    store_fd($dict, $fd);
    close ($fd);
}

=head2 leo_translate(word)
	Given a word, query the Leo dictionary for definitions.  Returns an array of
	hashes containing the English and German words and the type of definition it is.
=cut
sub leo_translate {
    my $word = shift;

	# Sleep for a bit so Leo doesn't notice how much we're hammering their server :3
    my $leo_result = $leo->translate($word);
	select(undef, undef, undef, 100); 

    to_triple($leo_result);
}

1; # Magic true value required at end of module
__END__
