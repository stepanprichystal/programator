#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine ="input_identify,path=,job=d152457,script_path=,gbr_ext=no,drl_ext=no,gbr_units=auto,drl_units=auto,unify=yes,break_sr=yes,gbr_wtp_filter=*,drl_wtp_filter=*,gbr_wtp_units=auto,drl_wtp_units=auto,wtp_dir=,have_wheels=yes,wheel=,gbr_consider_headlines=yes,drl_consider_headlines=yes,board_size_x=0,board_size_y=0 (1)";

 

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


