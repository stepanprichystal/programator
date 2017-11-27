#-------------------------------------------------------------------------------------------#
# Description: Responsible for preparing job board layers for output.
# - Flatten data
# - Adjust tool diameters
# - Create depth drawing, etc, ..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';

use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareBase';
use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNC';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerDataList';

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"data_step"} = "data_" . $self->{"step"};

	# get limits of step
	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 0 );
	$self->{"profileLim"} = \%lim;

	$self->{"layerList"} = LayerDataList->new();
	$self->{"prepareBase"} =
	  PrepareBase->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"}, $self->{"layerList"}, $self->{"profileLim"} );
	$self->{"prepareNC"} =
	  PrepareNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"data_step"}, $self->{"layerList"}, $self->{"profileLim"} );

	return $self;
}

# Create image preview
sub Create {
	my $self        = shift;
	my $message     = shift;
	my $layerFilter = shift;    # request on onlyu some layers

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Create flattened step
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"data_step"}, 1 );
	CamHelper->SetStep( $inCAM, $self->{"data_step"} );
	my @childSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $self->{"step"} );

	# get all layers of export
	my @layers = $self->__GetLayersForExport($layerFilter);

	# Prepare layers for export
	#$self->{"prepareBase"}->Prepare( \@layers );
	$self->{"prepareNC"}->Prepare( \@layers, \@childSteps );

	return 1;
}

# Return DataLayer objects
sub GetLayers {
	my $self = shift;

	return $self->{"layerList"}->GetLayers();
}

# Return step name, where layers are created
sub GetStepName {
	my $self = shift;

	return $self->{"data_step"};
}

# After using prepared layers, delete layers and step from job
sub Clear {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l ( $self->GetLayers() ) {

		my $lName = $l->GetOutput();

		if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
			$inCAM->COM( "delete_layer", "layer" => $lName );
		}

		#delete if step  exist
		if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"data_step"} ) ) {
			$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"data_step"}, "type" => "step" );
		}

	}
}

sub __GetLayersForExport {
	my $self        = shift;
	my $layerFilter = shift;

	my @allLayers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @layers = ();

	# 1) Filter  requsted layer s
	if ($layerFilter) {

		my %tmp;
		@tmp{ @{$layerFilter} } = ();
		@layers = grep { exists $tmp{ $_->{"gROWname"} } } @allLayers;

	}
	else {
		@layers = @allLayers;
	}

	# 2) Filter internal layers, which are unable to export
	
	my @internal = ( "fr", "v1", "fsch");
	
	my %tmp;
	@tmp{ @internal } = ();
	@layers = grep { !exists $tmp{ $_->{"gROWname"} } } @layers;
 
	return @layers;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::OutputData::OutputData';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $mess = "";

	my $control = OutputData->new( $inCAM, $jobId, "o+1" );
	$control->Create( \$mess );

}

1;

