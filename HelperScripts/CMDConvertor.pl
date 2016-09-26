#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"
COM sr_fill,type=solid,solid_type=surface,min_brush=25.4,use_arcs=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no,polarity=positive,step_margin_x=0,step_margin_y=0,step_max_dist_x=100,step_max_dist_y=100,sr_margin_x=0,sr_margin_y=0,sr_max_dist_x=0,sr_max_dist_y=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,consider_rout=no,dest=layer_name,layer=sc1,stop_at_steps=
";
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


