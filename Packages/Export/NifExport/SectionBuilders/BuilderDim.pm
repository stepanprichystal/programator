
#-------------------------------------------------------------------------------------------#
# Description: Build section with info about dimension, multiplicity etc
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderDim;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my %nifData  = %{ $self->{"nifData"} };
	my $stepName = "panel";

	my %pnlDim;
	my %frDim;

	#single_x
	if ( $self->_IsRequire("single_x") ) {
		$section->AddRow( "single_x", $nifData{"single_x"} );
	}

	#single_y
	if ( $self->_IsRequire("single_y") ) {
		$section->AddRow( "single_y", $nifData{"single_y"} );
	}

	#panel_x
	if ( $self->_IsRequire("panel_x") ) {
		$section->AddRow( "panel_x", $nifData{"panel_x"} );
	}

	#panel_y
	if ( $self->_IsRequire("panel_y") ) {
		$section->AddRow( "panel_y", $nifData{"panel_y"} );
	}

	#nasobnost_panelu
	if ( $self->_IsRequire("nasobnost_panelu") ) {
		$section->AddRow( "nasobnost_panelu", $nifData{"nasobnost_panelu"} );
	}

	#nasobnost
	if ( $self->_IsRequire("nasobnost") ) {
		$section->AddRow( "nasobnost", $nifData{"nasobnost"} );
	}

	if ( $self->_IsRequire("fr_rozmer_x") || $self->_IsRequire("fr_rozmer_y") ) {
		%frDim = $self->__GetFrDimemsion($stepName);
	}

	#fr_rozmer_x
	if ( $self->_IsRequire("fr_rozmer_x") ) {
		$section->AddRow( "fr_rozmer_x", $frDim{"xSize"} );
	}

	#fr_rozmer_y
	if ( $self->_IsRequire("fr_rozmer_y") ) {
		$section->AddRow( "fr_rozmer_y", $frDim{"ySize"} );
	}

	if ( $self->_IsRequire("rozmer_x") || $self->_IsRequire("rozmer_y") ) {
		%pnlDim = $self->__GetPnlDimemsion($stepName);
	}

	#rozmer_x
	if ( $self->_IsRequire("rozmer_x") ) {
		$section->AddRow( "rozmer_x", $pnlDim{"xSize"} );
	}

	#rozmer_y
	if ( $self->_IsRequire("rozmer_y") ) {
		$section->AddRow( "rozmer_y", $pnlDim{"ySize"} );
	}

}

sub __GetPnlDimemsion {
	my $self     = shift;
	my $stepName = shift;
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};

	my %lim = CamJob->GetProfileLimits( $inCAM, $jobId, $stepName );

	my %dim = ();

	$dim{"xSize"} = sprintf "%.1f", ( $lim{"xmax"} - $lim{"xmin"} );
	$dim{"ySize"} = sprintf "%.1f", ( $lim{"ymax"} - $lim{"ymin"} );

	return %dim;
}

sub __GetFrDimemsion {
	my $self     = shift;
	my $stepName = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $layerCnt = $self->{"layerCnt"};

	my $routThick = 2.0;

	my %dim = ();

	my $frExist = CamHelper->LayerExists( $inCAM, $jobId, "fr" );

	unless ($frExist) {
		$dim{"xSize"} = undef;
		$dim{"ySize"} = undef;
	}
	else {
		my %lim = CamJob->GetLayerLimits( $inCAM, $jobId, $stepName, "fr" );

		$dim{"xSize"} = sprintf "%.1f", ( $lim{"xmax"} - $lim{"xmin"} ) - ( 3 * $routThick );
		$dim{"ySize"} = sprintf "%.1f", ( $lim{"ymax"} - $lim{"ymin"} ) - ( 3 * $routThick );
	}

	return %dim;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

