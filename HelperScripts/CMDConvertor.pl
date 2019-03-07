#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="copy_layer,source_job=d222775,source_step=et_panel_o+1,source_layer=bend,dest=layer_name,dest_step=et_panel_o+1,dest_layer=bend+2,mode=duplicate,invert=no,copy_notes=no,copy_attrs=yes,copy_lpd=yes,copy_sr_feat=no";




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


