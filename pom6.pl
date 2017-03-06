#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';

my $inCAM = InCAM->new();
my $jobId = "f52456";
my $step  = "o+1";
my $layer = "f";

my $symbolType = GetFeatureType( $inCAM, $jobId, $step, $layer );

if ( $symbolType =~ /s/i ) {

	print "JE to surface";
}else{
	
	print "Neni to surface";
}
 

sub GetFeatureType {
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	$inCAM->COM( "units", "type" => "mm" );

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => "select+f0",
								 parse           => 'no'
	);

	my $f;
	open( $f, "<" . $infoFile );
	my @feat = <$f>;
	close($f);
	unlink($infoFile);

	foreach my $f (@feat) {

		if ( $f =~ /###/ ) { next; }

		my @attr = ();

		# line, arcs, pads
		if ( $f =~ m/^#(\w*)/i ) {
			return $1;
		}
	}

}

