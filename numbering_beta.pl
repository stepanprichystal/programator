#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

##necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

my $nasobnostX = 5 ;
my $nasobnostY = 5;

my $krokX = 39;
my $krokY = 20;

my $velikostTextu = 2;

my @pole = ();

my $infoFile = $inCAM->INFO(
	units           => 'mm',
	angle_direction => 'ccw',
	entity_type     => 'layer',
	entity_path     => "f73260/mpanel/test",
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

$inCAM->COM( "snap_mode", "mode" => "center" );

my @poleX = ();
my @poleY = ();

my $vypocetX = 0;
my $vypocetY = 0;
my $x        = 1;
my $y        = 1;

my $vlozeniX;
my $vlozeniY;

for ( my $i = 0 ; $i < $nasobnostX ; $i++ ) {

	$vypocetX = $krokX * $i;

	push( @poleX, $vypocetX );
}

for ( my $i = 0 ; $i < $nasobnostY ; $i++ ) {

	$vypocetY = $krokY * $i;

	push( @poleY, $vypocetY );

}

for ( my $i = 1 ; $i < ( $nasobnostX * $nasobnostY ) ; $i++ ) {

	if ( $x == $nasobnostX ) {

		$vlozeniX = $poleX[ $x - 1 ];
		$vlozeniY = $poleY[ $y - 1 ];

		$x = 1;
		$y++;
	}
	else {
		$vlozeniX = $poleX[ $x - 1 ];
		$vlozeniY = $poleY[ $y - 1 ];
		$x++;
	}

	if ( $i == 1 ) {

		$inCAM->COM(
			"sel_single_feat",
			"operation"  => "select",
			"x"          => $poziceX,
			"y"          => $poziceY,
			"tol"        => "889.81",
			"cyclic"     => "no",
			"clear_prev" => "yes"
		);
		$inCAM->COM(
			"sel_buffer_copy",
			"x_datum" => $poziceX,
			"y_datum" => $poziceY
		);

		$inCAM->COM(
			"sel_buffer_paste",
			"x" => ( $poleX[ $x - 1 ] + $poziceX ),
			"y" => ( $poleY[ $y - 1 ] + $poziceY )
		);
		$inCAM->COM(
			"sel_single_feat",
			"operation"  => "select",
			"x"          => ( $poleX[ $x - 1 ] + $poziceX ),
			"y"          => ( $poleY[ $y - 1 ] + $poziceY ),
			"tol"        => "889.81",
			"cyclic"     => "no",
			"clear_prev" => "yes"
		);
		$inCAM->COM(
			"sel_change_txt",
			"text"      => $i + 1,
			"x_size"    => $velikostTextu,
			"y_size"    => $velikostTextu,
			"w_factor"  => "0.82020997",
			"polarity"  => "positive",
			"angle"     => "90",
			"direction" => "ccw",
			"mirror"    => "no",
			"fontname"  => "standard"
		);

	}
	else {
		$inCAM->COM(
			"sel_buffer_paste",
			"x" => ( $poleX[ $x - 1 ] + $poziceX ),
			"y" => ( $poleY[ $y - 1 ] + $poziceY )
		);
		$inCAM->COM(
			"sel_single_feat",
			"operation"  => "select",
			"x"          => ( $poleX[ $x - 1 ] + $poziceX ),
			"y"          => ( $poleY[ $y - 1 ] + $poziceY ),
			"tol"        => "889.81",
			"cyclic"     => "no",
			"clear_prev" => "yes"
		);
		$inCAM->COM(
			"sel_change_txt",
			"text"      => $i + 1,
			"x_size"    => $velikostTextu,
			"y_size"    => $velikostTextu,
			"w_factor"  => "0.82020997",
			"polarity"  => "positive",
			"angle"     => "90",
			"direction" => "ccw",
			"mirror"    => "no",
			"fontname"  => "standard"
		);
	}
}