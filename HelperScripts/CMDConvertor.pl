#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="sr_tab_add,step=mpanel,line=0,x=0,y=0,nx=1,ny=1,dx=354.49932,dy=198.4976,angle=0,direction=ccw,flip=no,mirror=no";

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


