#!/usr/local/bin/perl

use warnings;
use strict;

# by Brent Laabs, version 0.1, April 2012
# licensed under the WTFPL -- do WTF you want with this file.


$ARGV[0] // exit usage();

#options
my $printIDs = 0;
my $usecolors = 0;
my $user_seats;

while ($ARGV[0] =~ /^-/) {
  my $option = shift;
  $option eq '-i' and $printIDs  = 1 and next;
  $option eq '-c' and $usecolors = 1 and next;
  $option =~ /^-t(\d+)/ and $user_seats = $1 and next;
  usage();
  die "Unrecognized option: $option\n";
}

my $blt_filename = shift // exit usage();
my $BLT;
open($BLT, "$blt_filename") or die "Cannot open $blt_filename";

my ($candidates, $seats) = split /\s/, <$BLT>;
$seats = $user_seats // $seats;

$candidates == 0 and die 'Incomplete ballot file: does not begin with "#candidates #seats"';

# Make empty arrays for vote tallies
my @vlen = (my @topx = (my @last = ( map { 0 } (0..$candidates+1) )));
my $votecount = 0;
my $line;

# Tally votes
while ($line = <$BLT>) {
    my @vote = split /\s/, $line;
    $vote[0] == 0 and last;
    { 
      no warnings;  #supress out of index errors
      $topx[$vote[$_]]++ for (1 .. $seats);
      $last[$vote[$candidates]]++;
      $vlen[$#vote-1]++;
      $votecount++;
    }
}

my @names = ( "John Fnord" );
my @colors = ( "555" );
for (1 .. $candidates) {
    $line = <$BLT> // die "Error: Too few candidates listed";
    $line =~ /^"(.*)"/ and push @names, $1;
    $line =~ /#([0-9a-fA-F]{3,6})/ and push @colors, $1;
}

my $election_name = <$BLT> // die "Incomplete election file: no election name at the end";
chomp $election_name;


print "$votecount votes cast to elect $candidates candidates.\n\n";


print( ($printIDs ? "|| ID " : ''), "|| Votes (Top $seats) || Name ||\n");
my @printorder = sort { $topx[$b] <=> $topx[$a] }(1..$candidates);
for my $i (@printorder) {
    print ($usecolors ? "||<#$colors[$i]> " : '|| ');
    $printIDs and print sprintf("%2d", $i), " || ";
    print sprintf("%4d",$topx[$i]), " || ", $names[$i], " ||\n";
}

print( "\n\n", ($printIDs ? "|| ID " : ''), "|| Votes (Last) || Name ||\n");
@printorder = sort { $last[$b] <=> $last[$a] }(1..$candidates);
for my $i (@printorder) {
    print ($usecolors ? "||<#$colors[$i]> " : '|| ');
    $printIDs and print sprintf("%2d", $i), " || ";
    print sprintf("%4d",$last[$i]), " || ", $names[$i], " ||\n";
}


print "\n\n|| Ballot Length || Quantity cast || Percentage ||\n";
print '|| '.sprintf("%2d",$_).' || '.sprintf("%4d",$vlen[$_]).' || '.sprintf("%5.2f",$vlen[$_]*100/$votecount)."% ||\n" for (0..$candidates);



sub usage {

print <<USAGI;
perl stvstats.pl [-i] [-c] [-t#] filename.blt

Output Options
  -i   Print IDs in the output table
  -c   Print colors given in the file into the candidate table
  -t#  Top # seats instead of the amount given in the ballot file

USAGI
 # in the name of the moon... call this program correctly!
return 0;
}