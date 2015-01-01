package Blitz;

use warnings;
use strict;

use Data::Dumper;
use Blitz::Dict;

use vars '$VERSION'; $VERSION = '0.0.1';

=head1 NAME

Blitz - German flash card generator dictionary routines

=head1 VERSION

This document describes Blitz version 0.0.1

=head1 AUTHOR

Nathan Taylor  C<< <nbtaylor@gmail.com> >>

=head1 SYNOPSIS

    my $db = dict_read();
    print "Adding " . dict_add($db, leo_translate("Quatsch!")) . " elements\n";
    dict_write($db);

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

=head2 words_from_file(filename)
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

	my @keys = keys %words;
    \@keys;
}

=head2 update_dict(words)
	Updates the dictionary file with the supplied words.
=cut
sub update_dictfile {
	my $words = shift;

	my $dict = dict_read();
	my $word_cnt = 0;
	print "Adding " . ((scalar @$words) + 1) . " new words.\n";
	for my $word (@$words) {
		print "Adding " . $word . "...\n";
	
		my $translation = leo_translate($word);
		next unless defined($translation); #undef if leo returned HTTP != 200
		$word_cnt += dict_add($dict, $translation);	
	}

	print "Added " . $word_cnt . " new translations.\n";
	dict_write($dict);
}

update_dictfile(words_from_file("../data/phrases"));
