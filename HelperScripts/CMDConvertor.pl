#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="auto_part_place,step=o+1,unitsInPanel=automatic,minUtilization=1,minResults=1,goldTab=gold_none,autoSelectBest=no,goldMode=minimize_scoring,goldScoringDist=0,spacingAlign=keep_in_center,numMaxSteps=no_limit,transformation=rotation,rotation=any_rotation,pattern=no_pattern,flip=no_flip,interlock=none,xmin=0,ymin=0,base_rotation=0";
my $output = "\$inCAM->COM(";
my @splitted = split( ",", $inputLine );

my $section = shift(@splitted);
$section =~ s/COM\s*//;

$output .= "\"" . $section . "\",";

my @params = ();

foreach my $p (@splitted) {
	$p =~ s/=/\" => \"/;
	$p =~ s/;/\\;/;

	$p = "\"" . $p . "\"";

	push( @params, $p );

}

my $par = join( ",", @params );
$output .= $par . ");";

print $output;


