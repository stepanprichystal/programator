#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"COM cre_drills_map,layer=m,map_layer=m_drillmap,preserve_attr=no,draw_origin=no,define_via_type=no,units=mm,mark_dim=50,mark_line_width=4,mark_location=center,sr=no,slots=no,columns=Count\;Type\;Finish\;Des,notype=plt,table_pos=right,table_align=bottom";# ============ INPUT LINE =================


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


