#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"copy_layer,source_job=f13608,source_step=o+1,source_layer=f,dest=layer_name,dest_step=,dest_layer=dddd,mode=append,invert=no,copy_notes=no,copy_attrs=no,copy_lpd=new_layers_only,copy_sr_feat=no (0)";# ============ INPUT LINE =================

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


