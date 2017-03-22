#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"chain_set_plunge,ang2=0,start_of_chain=yes,mode=straight,len4=0,ifeed=0,apply_to=all,val2=0,ang1=0,len2=0,len1=0,len3=0,ofeed=0,inl_mode=straight,layer=f,val1=0,type=open";
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


