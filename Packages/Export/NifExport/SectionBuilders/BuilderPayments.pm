
#-------------------------------------------------------------------------------------------#
# Description: Build section about general pcb information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderPayments;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';

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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	# 4007223 - panelizace

	if ( $self->_IsRequire("4007223") ) {

		$section->AddComment("Panelizace");

		my $panelizace = "4007223";

		my $exist = CamHelper->StepExists( $inCAM, $jobId, "o+1_single" );

		unless ($exist) {

			$panelizace = "-" . $panelizace;
		}

		$section->AddRow( "rel(22305,L)", $panelizace );
	}

	# 4007223 - frezovani pred prokovem

	if ( $self->_IsRequire("4010802") ) {

		$section->AddComment("Frezovani pred prokovem");

		my $platedMill = "4010802";

		my $exists = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		unless ($exists) {

			$platedMill = "-" . $platedMill;
		}

		$section->AddRow( "rel(22305,L)", $platedMill );
	}

	# 4115894 - drazkovani

	if ( $self->_IsRequire("4115894") ) {

		$section->AddComment("Frezovani pred prokovem");

		my $scoring = "4115894";

		my $exists = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_score );

		unless ($exists) {

			$scoring = "-" . $scoring;
		}

		$section->AddRow( "rel(22305,L)", $scoring );
	}

	# check inner layers
	my $unitRTM   = UniRTM->new( $inCAM, $jobId, "o+1", "f" );
	my @out       = $unitRTM->GetOutlineChains();
	my $extraMill = 0;

	if ( scalar(@out) == 1 ) {

		# check if there is inner rout
		my @inside = grep { $_->GetIsInside() } $unitRTM->GetChainSequences();
		$extraMill = 1 if ( scalar(@inside) );
	}
	elsif ( scalar(@out) > 1 ) {

		# more than one outline => it means extra milling
		$extraMill = 1;
	}

	# 4141429 - vnitrni freza 2vv

	if ( $self->_IsRequire("4141429") ) {

		$section->AddComment("Vnitrni frezovani  2VV");

		my $inLayer = "4141429";

		my $exists = 0;

		if (! ($layerCnt == 2 && $extraMill)) {
			
			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer);
	}
	
	# 8364285 - vnitrni freza 4vv

	if ( $self->_IsRequire("8364285") ) {

		$section->AddComment("Vnitrni frezovani  4VV");

		my $inLayer = "8364285";
		my $exists = 0;

		if (! ($layerCnt == 4 && $extraMill)) {
			
			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer);
	}

	# 8364286 - vnitrni freza 6vv, 8vv

	if ( $self->_IsRequire("8364286") ) {

		$section->AddComment("Vnitrni frezovani  6VV, 8VV");

		my $inLayer = "8364286";
		my $exists = 0;

		if (! ($layerCnt > 4 && $extraMill)) {
			
			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer);
	}
	
	# 4007224 - jine nazvy souboru
	
	if ( $self->_IsRequire("4007224") ) {

		$section->AddComment("Jine nazvy souboru");

		my $platedMill = "4007224";

		my $exists = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		unless ($exists) {

			$platedMill = "-" . $platedMill;
		}

		$section->AddRow( "rel(22305,L)", $platedMill );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

