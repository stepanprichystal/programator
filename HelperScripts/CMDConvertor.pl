#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="sr_fill,type=pattern,origin_type=datum,symbol=r50,dx=0.1,dy=0.1,x_off=0,y_off=0,break_partial=yes,cut_prims=no,outline_draw=no,outline_width=0,outline_invert=no,polarity=positive,step_margin_x=0,step_margin_y=0,step_max_dist_x=100,step_max_dist_y=100,sr_margin_x=0,sr_margin_y=0,sr_max_dist_x=0,sr_max_dist_y=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,consider_rout=no,dest=affected_layers,layer=.affected,stop_at_steps= ";






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


