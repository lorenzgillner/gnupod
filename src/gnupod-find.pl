###__PERLBIN__###
#  Copyright (C) 2009 Heinrich Langos <henrik-gnupod at prak.org>
#  based on gnupod-search by Adrian Ulrich <pab at blinkenlights.ch>
#  Part of the gnupod-tools collection
#
#  URL: http://www.gnu.org/software/gnupod/
#
#    GNUpod is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
#    (at your option) any later version.
#
#    GNUpod is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# iTunes and iPod are trademarks of Apple
#
# This product is not supported/written/published by Apple!

use strict;
use warnings;
use GNUpod::XMLhelper;
use GNUpod::FindHelper;

#use GNUpod::ArtworkDB;
use Getopt::Long;

my $programName = "gnupod-find.pl";

my $fullversionstring =
  "$programName Version ###__VERSION__### (C) Heinrich Langos";

use vars qw(%opts);

$opts{mount} = $ENV{IPOD_MOUNTPOINT};

my $getoptres = GetOptions(
    \%opts, "version", "help|h", "mount|m=s",
    @GNUpod::FindHelper::findoptions

);

# take model and mountpoint from gnupod-search preferences
GNUpod::FooBar::GetConfig( \%opts, { mount => 's', model => 's' },
    "gnupod-search" );

usage()                              if ( $opts{help} || !$getoptres );
version()                            if $opts{version};
GNUpod::FindHelper::fullattributes() if $opts{'list-attributes'};

## all work but 1 and 2 are deprecated
#print "1: ".%GNUpod::FindHelper::FILEATTRDEF->{year}{help}."\n";
#print "2: ".%GNUpod::FindHelper::FILEATTRDEF->{year}->{help}."\n";
#print "3: ".$GNUpod::FindHelper::FILEATTRDEF{year}{help}."\n";
#print "4: ".$GNUpod::FindHelper::FILEATTRDEF{year}->{help}."\n";
#
## this does not work and without "use warnings;" you woudln't even know!
## did i mention that i hate perl?
#print "5: ".$GNUpod::FindHelper::FILEATTRDEF->{year}->{help}."\n";

my @resultlist = ();

my $foo = GNUpod::FindHelper::process_options( \%opts );

if ( !defined $foo )            { usage("Trouble parsing find options.") }
if ( ref( \$foo ) eq "SCALAR" ) { usage($foo) }

#my @filterlist = @{${$foo}[0]};
#my @sortlist = @{${$foo}[1]};
#my @viewlist = @{${$foo}[2]};
# well isn't that an ugly piece of code? it takes the array reference foo, dereferences it,
# takes one element (another array reference) out of it and dereferences that one before assigning it

# -> Connect the iPod
my $connection = GNUpod::FooBar::connect( \%opts );
usage( $connection->{status} . "\n" ) if $connection->{status};

main($connection);

####################################################
# Worker
sub main {

    my ($con) = @_;

    GNUpod::XMLhelper::doxml( $con->{xml} )
      or usage("Failed to parse $con->{xml}, did you run gnupod-init?\n");

    #print "resultlist:\n".Dumper(\@resultlist);

    @resultlist = sort GNUpod::FindHelper::comparesongs @resultlist;

    @resultlist = GNUpod::FindHelper::croplist( { results => \@resultlist } );

    #print "sortedresultlist:\n".Dumper(\@resultlist);
    GNUpod::FindHelper::prettyprint( { results => \@resultlist } )
      if (@resultlist);
}

#############################################
# Eventhandler for FILE items
sub newfile {
    my ($el) = @_;

    if ( GNUpod::FindHelper::filematches($el) ) {
        push @resultlist, \%{ $el->{file} };    #add a reference to @resultlist
    }
}

#############################################
# Eventhandler for playlist items
sub newpl {
}

###############################################################
# Basic help
sub usage {
    my ($rtxt) = @_;
    $rtxt = "" if ( !defined($rtxt) );
    die <<"EOF";
$fullversionstring
$rtxt
Usage: $programName ...

   -h, --help              display this help and exit
       --version           output version information and exit
   -m, --mount=directory   iPod mountpoint, default is \$IPOD_MOUNTPOINT
$GNUpod::FindHelper::findhelp
Report bugs to <bug-gnupod\@nongnu.org>
EOF
}

sub version {
    die <<"EOF";
$fullversionstring

This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

EOF
}

=head1 NAME

gnupod-find.pl  - Find songs on your iPod

=head1 SYNOPSIS

gnupod-find.pl [OPTION]

=head1 DESCRIPTION

C<gnupod-find.pl> searches the F<GNUtunesDB.xml> file for matches to its
arguments and shows those files.

=head1 OPTIONS

###___PODINSERT man/gnupod-find-options.pod___###

###___PODINSERT man/general-tools.pod___###

=head1 AUTHORS

Written by Eric C. Cooper <ecc at cmu dot edu> - Contributed to the 'old' GNUpod (< 0.9)

Adrian Ulrich <pab at blinkenlights dot ch> - Main author of GNUpod

Heinrich Langos <henrik-gnupod at prak dot org> - Some patches

###___PODINSERT man/footer.pod___###

