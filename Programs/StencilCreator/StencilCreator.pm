
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::StencilCreator;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::StencilCreator::Forms::StencilFrm';
use aliased 'Programs::StencilCreator::Helpers::StencilData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# Main application form
	$self->{"form"} = StencilFrm->new( -1, $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	StencilData->SetSourceData($inCAM, $jobId, $self->{"form"});
	

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

# ================================================================================
# PRIVATE METHODS
# ================================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

