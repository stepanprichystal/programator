#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::InCAM::InCAM';

my $inCAM      = InCAM->new();
my $nasobnostX = "3";
my $nasobnostY = "3";

my $krokX = "10";
my $krokY = "10";

my $cislo = 1;

my $jobName = ("$ENV{JOB}");

my @pole = ();

my $infoFile = $inCAM->INFO(
							 units           => 'mm',
							 angle_direction => 'ccw',
							 entity_type     => 'layer',
							 entity_path     => "1/1/test",
							 data_type       => 'FEATURES',
							 options         => "f0",
							 parse           => 'no'
);

my $f;
open( $f, "<" . $infoFile );
@pole = <$f>;
close($f);

my @abc = split( ' ', $pole[1] );

my $poziceX = $abc[1];
my $poziceY = $abc[2];

$inCAM->COM(
	"snap_mode",
	"mode" => "center"
);
my $x = 1;
my $y = 1;

my $pozice_oznaceniX = 0;
my $pozice_oznaceniY = 0;

my $pozice_vlozeniX = 0;
my $pozice_vlozeniY = 0;

for ( my $i = 1 ; $i < ( $nasobnostX * $nasobnostY ) ; $i++ ) {

	if ( $x == 1 and $y == 1 ) {

		$pozice_oznaceniX = $poziceX;
		$pozice_oznaceniY = $poziceY;

		$inCAM->COM(
					 "sel_single_feat",
					 "operation"  => "select",
					 "x"          => "$poziceX",
					 "y"          => "$poziceY",
					 "tol"        => "889.81",
					 "cyclic"     => "no",
					 "clear_prev" => "yes"
		);

		$inCAM->COM(
					 "sel_buffer_copy",
					 "x_datum" => "$poziceX",
					 "y_datum" => "$poziceY"
		);

		$pozice_vlozeniX = ( $poziceX + $krokX );
		$pozice_vlozeniY = ($poziceY);

		$inCAM->COM(
					 "sel_buffer_paste",
					 "x" => $pozice_vlozeniX,
					 "y" => $pozice_vlozeniY
		);
		$x++;
	}
	else {

		if ( ( $x == ( $nasobnostX - 1 ) ) and ( $y > 1 ) ) {

			$pozice_vlozeniX = ( $pozice_oznaceniX / $nasobnostX );
			$pozice_vlozeniY = ( $pozice_oznaceniY + $krokY );

			$inCAM->COM(
						 "sel_buffer_paste",
						 "x" => ($pozice_vlozeniX),
						 "y" => ($pozice_vlozeniY)
			);

			$y++;
			$x = 1;
		}
		$pozice_vlozeniX = ( $pozice_vlozeniX + $krokX );
		$pozice_vlozeniY = ($pozice_vlozeniY);

		$inCAM->COM(
					 "sel_buffer_paste",
					 "x" => ($pozice_vlozeniX),
					 "y" => ($pozice_vlozeniY)
		);

	}

	# if($x==1){
	#       $inCAM->COM("sel_single_feat",
	#                   "operation" => "select",
	#                           "x" => ($krokX*$x1),
	#                           "y" => ($krokY*$y1),
	#                         "tol" => "444.905",
	#                      "cyclic" => "no",
	#                  "clear_prev" => "yes");
	#                 }
	# else {
	#       $inCAM->COM("sel_single_feat",
	#                   "operation" => "select",
	#                           "x" => ($krokX*$x1),
	#                           "y" => ($krokY*$y1),
	#                         "tol" => "444.905",
	#                      "cyclic" => "no",
	#                  "clear_prev" => "yes");
	#                 }
	#                 $cislo=$cislo+1;
	#       $inCAM->COM("sel_change_txt",
	#                        "text" => "$cislo",
	#                      "x_size" => "2",
	#                      "y_size" => "2",
	#                    "w_factor" => "0.82020997",
	#                    "polarity" => "positive",
	#                       "angle" => "0",
	#                   "direction" => "ccw",
	#                      "mirror" => "no",
	#                    "fontname" => "standard");

}
