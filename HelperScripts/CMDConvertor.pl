#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================

my $inputLine ="sr_fill,type=solid,solid_type=surface,min_brush=25.4,use_arcs=yes,cut_prims=no,outline_draw=no,outli
ne_width=0,outline_invert=no,polarity=positive,step_margin_x=-20.2,step_margin_y=-35,step_max_dist_x
=0,step_max_dist_y=0,sr_margin_x=0,sr_margin_y=0,sr_max_dist_x=0,sr_max_dist_y=0,nest_sr=no,consider
_feat=yes,feat_margin=1,consider_drill=no,drill_margin=0,consider_rout=no,dest=affected_layers,layer
=.affected,stop_at_steps= (0)";


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


