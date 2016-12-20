#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"COM add_polyline_end,polarity=positive,attributes=no,symbol=r200,bus_num_lines=0,bus_dist_by=pitch,bus_distance=0,bus_reference=left";# ============ INPUT LINE =================


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


