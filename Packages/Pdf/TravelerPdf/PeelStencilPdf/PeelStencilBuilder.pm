#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::PeelStencilPdf::PeelStencilBuilder;

use Class::Interface;
&implements('Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerDataBuilder::ITravelerBuilder');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::Enums' => 'UniTrvlEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"NCLayer"} = shift;

	$self->{"step"} = "panel";

	return $self;
}

sub BuildTraveler {
	my $self     = shift;
	my $traveler = shift;

	$traveler->SetTravelerType( UniTrvlEnums->ProductType_STENCILFLEX );
}

sub BuildOperations {
	my $self     = shift;
	my $traveler = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $side = $self->{"NCLayer"} =~ /c$/ ? "c" : "s";

	# 1) Add material preparation
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	$traveler->AddOperation( "Příprava materiálu", "Ostřihnout na rozměr: $w x $h mm " );

	# 2) Copper etching
	$traveler->AddOperation("Odleptání Cu z obou stran");

	# 3) Add Drill program

	my $CNCP = $jobId . "_fl$side" . ".";
	my $p    = JobHelper->GetJobArchive($jobId) . "nc\\$CNCP";
	$traveler->AddOperation( "Frézování šablony $CNCP", "$p" );

	# 4) Put to production hall
	$traveler->AddOperation("Předat mistrovi");

}

sub BuildInfoBoxes {
	my $self     = shift;
	my $traveler = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Stencil side
	my $side = $self->{"NCLayer"} =~ /c$/ ? "top" : "bot";

	# Add box PCB info
	my $infoBox = $traveler->AddInfoBox("Info zakázka");
	$infoBox->AddItem( "Typ desky",          "Šablona lak " . uc($side) );
	$infoBox->AddItem( "Počet přířezů", "1" );

	# Add box PCB info
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	my $infoMat = $traveler->AddInfoBox("Info materiál");

	# put material in 2 rows
	$infoMat->AddItem( "Materiál",          "Jádro FR4" );
	$infoMat->AddItem( "",          "(na typu nezáleží)" );
	$infoMat->AddItem( "Tloušťka",         "0,3mm" );
	$infoMat->AddItem( "Rozměr přířezu", "$w x $h mm" );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

