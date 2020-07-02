#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="
add_surf_fill,type=pattern,origin_type=datum,symbol=r20,dx=0.1,dy=0.1,x_off=0,y_off=0,break_partial=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no,predefined_pattern_type=dots,indentation=even,dots_shape=circle,dots_diameter=10,dots_grid=200";



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


