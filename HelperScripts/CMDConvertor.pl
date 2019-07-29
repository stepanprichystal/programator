#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="
sr_fill,type=predefined_pattern,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no,predefined_pattern_type=cross_hatch,indentation=even,cross_hatch_angle=45,cross_hatch_witdh=300,cross_hatch_dist=1500,polarity=positive,step_margin_x=8,step_margin_y=27,step_max_dist_x=555,step_max_dist_y=555,sr_margin_x=2.5,sr_margin_y=2.5,sr_max_dist_x=555,sr_max_dist_y=555,nest_sr=yes,consider_feat=yes,feat_margin=1,consider_drill=yes,drill_margin=1,consider_rout=no,dest=affected_layers,layer=.affected,stop_at_steps=o+1 (1)

";



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


