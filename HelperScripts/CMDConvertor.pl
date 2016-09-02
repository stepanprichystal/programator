#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"copper_area,y1=25,copper_thickness=18,consider_rout=yes,area=yes,out_layer=sum,x1=5,layer2=,drills_list=,drills=yes,layer1=c,ignore_pth_no_pad=no,dist_map=no,y_boxes=3,drills_source=matrix,x2=302,out_file=out_file,edges=yes,thickness=788.919,x_boxes=3,resolution=1,resolution_value=25.4,f_type=all,y2=382";
# ============ INPUT LINE =================


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


