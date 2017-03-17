#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"chain_add,layer=f_f52456,chain_type=regular_chain,chain=1,size=2,flag=0,feed=0,speed=0,infeed_speed=0,retract_speed=0,pressure_foot=none,first=25,chng_direction=0,comp=left,repeat=no,plunge=no (0)";
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


