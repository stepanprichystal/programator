#-------------------------------------------------------------------------------------------#
# Description: Creator, which create sets, contain 2 merged layers - verticall
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::MultiFilmCreator;
use base('Packages::Export::PlotExport::FilmCreator::BaseFilmCreator');

use Class::Interface;
&implements('Packages::Export::PlotExport::FilmCreator::IFilmCreator');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'Packages::Export::PlotExport::FilmCreator::Helper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;

	my $inCAM    = shift;
	my $jobId    = shift;
	my $layers   = shift;
	my $smallLim = shift;
	my $bigLim   = shift;

	my $self = $class->SUPER::new( $inCAM, $jobId, $layers, @_ );
	bless $self;

	Helper->AddLayerPlotSize( Enums->Size_PROFILE, $layers, $smallLim, $bigLim );

	return $self;
}

sub GetRuleSets {
	my $self = shift;

	$self->__BuildRules();

	$self->_RunRules();

	return @{ $self->{"resultRules"} };
}

sub __BuildRules {
	my $self = shift;
	my $rule;

	# For all types of pcb

	# 1
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_SILKTOP, Enums->LType_SILKBOT );

	# 2
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_MASKTOP, Enums->LType_MASKBOT );

	# 3
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_SILKTOP, Enums->LType_MASKTOP );

	# 3
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_SILKBOT, Enums->LType_MASKBOT );

	if ( $self->{"layerCnt"} == 1 ) {

		# 4

		$rule = $self->_AddRule( Enums->Ori_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_MASKTOP, Enums->LType_SIGOUTER );

		# 5
		$rule = $self->_AddRule( Enums->Ori_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_MASKBOT, Enums->LType_SIGOUTER );

	}

	if ( $self->{"layerCnt"} >= 2 ) {

		# 4
		$rule = $self->_AddRule( Enums->Ori_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SIGOUTER, Enums->LType_SIGOUTER );

	}
 
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_GOLDFINGER, Enums->LType_GOLDFINGER );
	
	
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_PEELABLE, Enums->LType_PEELABLE );
	
	$rule = $self->_AddRule( Enums->Ori_VERTICAL );
	$rule->AddSingleTypes( Enums->LType_ALL, Enums->LType_ALL );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
	#
	#	use aliased 'CamHelpers::CamJob';
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	my $creator = MultiFilmCreator->new( $inCAM, $jobId, \@layers );

	#$creator->GetPlotterSets();

}

1;
