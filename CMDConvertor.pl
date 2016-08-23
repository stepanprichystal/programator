#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

# ============ INPUT LINE =================
my $line = "COM cdr_opfx_output,units=inch,anchor_mode=zero,target_machine=v300,output_layers=selected,break_surf=no,break_arc=no,break_sr=yes,break_fsyms=no,upkit=yes,contourize=no,units_factor=0.001,scale_x=1,scale_y=1,accuracy=0.2,anchor_x=0,anchor_y=0,min_brush=25.4,path=c:\Export,report_file=c:/tmp/InCam/incam18736.4292,multi_trg_machines=discovery";

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

