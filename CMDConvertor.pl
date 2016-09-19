#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

# ============ INPUT LINE =================
my $line = "nc_order,serial=1,sr_line=1,sr_nx=1,sr_ny=1,mode=btrl,snake=no,scope=full";

# ============ INPUT LINE =================









my @cmds = split( "COM", $line );

foreach my $inputLine (@cmds) {

	$inputLine =~ s/\n//;
	my $output = "\$inCAM->COM(";
	my @splitted = split( ",", $inputLine );

	my $section = shift(@splitted);
	$section =~ s/COM\s*//;
	$section =~ s/\s//;
	if ( $section eq "" ) {
		next;
	}

	 

	$output .= "\"" . $section . "\",";

	my @params = ();

	foreach my $p (@splitted) {
		
		$p =~ s/=/\" => \"/;
		$p =~ s/;/\\;/;

		$p = "\"" . $p . "\"";

		push( @params, $p );

	}

	my $par = join( ",", @params );
	$output .= $par . ");\n";

	print $output;

}

