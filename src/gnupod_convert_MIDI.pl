###__PERLBIN__###
#  Copyright (C) 2002-2005 Adrian Ulrich <pab at blinkenlights.ch>
#  Part of the gnupod-tools collection
#
#  URL: http://www.gnu.org/software/gnupod/
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# iTunes and iPod are trademarks of Apple
#
# This product is not supported/written/published by Apple!

use strict;



my $file  = $ARGV[0] or exit(1);
my $gimme = $ARGV[1];


if(!(-r $file)) {
 warn "$file is not readable!\n";
 exit(1);
}
elsif($gimme eq "GET_META") {
  print "FORMAT: MIDI\n";
}
elsif($gimme eq "GET_PCM") {
  my $tmpout = get_u_path("/tmp/gnupod_pcm", "wav");

  my $status = system("timidity", "-idqq", "-Ow", "-o", $tmpout, $file);
  
  if($status) {
   warn "timidity exited with $status, $!\n";
   exit(1);
  }
  
  print "PATH:$tmpout\n";
  
}
elsif($gimme eq "GET_MP3") {
  #Open a secure timidity pipe and open anotherone for lame
  #On errors, we'll get a BrokenPipe to stout
  my $tmpout = get_u_path("/tmp/gnupod_mp3", "mp3");
  open(MIDIOUT, "-|") or exec("timidity", "-idqq", "-Ow", "-o", "-", $file) or die "Could not exec timidity: $!\n";
  open(LAMEIN , "|-") or exec("lame", "--silent", "--preset","medium", "-", $tmpout) or die "Could not exec lame: $!\n";
   while(<MIDIOUT>) {
    print LAMEIN $_;
   }
  close(MIDIOUT);
  close(LAMEIN);
  print "PATH:$tmpout\n";
}
elsif($gimme eq "GET_AAC" or $gimme eq "GET_AACBM") {
  my $tmpout = get_u_path("/tmp/gnupod_faac", "m4a");
     $tmpout = get_u_path("/tmp/gnupod_faac", "m4b") if $gimme eq "GET_AACBM";
  open(MIDIOUT, "-|") or exec("timidity", "-idqq", "-Ow", "-o", "-", $file) or die "Could not exec timidity: $!\n";
  open(FAACIN , "|-") or exec("faac", "-w", "-q", "100", "-o", $tmpout, "-") or die "Could not exec faac: $!\n";
   while(<MIDIOUT>) { #Feed faac
    print FAACIN $_;
   }

  close(MIDIOUT);
  close(FAACIN);

  print "PATH:$tmpout\n";
}
else {
 warn "$0 can't encode into $gimme\n";
 exit(1);
}

exit(0);

#############################################
# Get Unique path
sub get_u_path {
 my($prefix, $ext) = @_;
 my $dst = undef;
 while($dst = sprintf("%s_%d_%d.$ext",$prefix, int(time()), int(rand(99999)))) {
  last unless -e $dst;
 }
 return $dst;
}