#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"
	COM sredit_set_step_nest,lines=1\;1,nx=1\;1,ny=1\;1,clear_selection=yes
COM nc_order,serial=1,sr_line=1\;1,sr_nx=1\;1,sr_ny=1\;1,mode=btrl,snake=no,scope=full
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


