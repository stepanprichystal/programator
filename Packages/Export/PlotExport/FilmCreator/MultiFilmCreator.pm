#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::MultiFilmCreator;
use base('Packages::Export::PlotExport::FilmCreator::BaseFilmCreator');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	
	my $layers = shift; #board layers
	
	
	my $self  = $class->SUPER::new($layers, @_);
	bless $self;

	return $self;
}

sub GetPlotterSets {
	my $self = shift;

	$self->__BuildRules();
	
	
	my @resultSet =  $self->_RunRules();

}

sub __BuildRules {
	my $self = shift;
	my $rule;

	if ( $self->{"layerCnt"} > 2 ) {

		# 1
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SILKTOP, Enums->LType_SILKBOT );

		# 2
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_MASKTOP, Enums->LType_MASKBOT );

		# 3
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SIGOUTER, Enums->LType_SIGOUTER );

		# 4
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SIGINNER, Enums->LType_SIGINNER );

	}
	else {
		
		
		# 1
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SILKTOP, Enums->LType_SILKBOT );

		# 2
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_MASKTOP, Enums->LType_MASKBOT );

		# 3
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SIGOUTER, Enums->LType_SIGOUTER );

		# 4
		$rule = $self->_AddRule( Enums->Position_VERTICAL );
		$rule->AddSingleTypes( Enums->LType_SIGINNER, Enums->LType_SIGINNER );

	}

}

sub __CreateSets {
	my $self = shift;

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';

	use aliased 'CamHelpers::CamJob';
	my $inCAM = InCAM->new();

	 
	my $jobId = "f13609";

	my @layers = CamJob->GetBoardBaseLayers($inCAM, $jobId);

	my $creator = MultiFilmCreator->new(\@layers);
	
	$creator->GetPlotterSets();

	 

}

1;
