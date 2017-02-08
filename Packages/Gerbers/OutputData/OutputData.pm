
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::OutputData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';

use aliased 'Packages::Gerbers::OutputData::PrepareLayers::PrepareBase';
use aliased 'Packages::Gerbers::OutputData::PrepareLayers::PrepareNC';
use aliased 'Packages::Gerbers::OutputData::LayerData::LayerDataList';

use aliased 'Packages::Gerbers::ProduceData::Output';
use aliased 'Packages::Gerbers::ProduceData::PrepareLayers';
use aliased 'Packages::Gerbers::ProduceData::PrepareInfo';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';


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

	$self->{"layerList"}     = LayerDataList->new();
	$self->{"prepareBase"} = PrepareBase->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"}, $self->{"layerList"}, $self->{"profileLim"}  );
	$self->{"prepareNC"} = PrepareNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"}, $self->{"layerList"}, $self->{"profileLim"}  );
 
	return $self;
}

# Create image preview
sub Create {
	my $self    = shift;
	my $message = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Create flattened step
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"data_step"} );
	CamHelper->SetStep( $inCAM, $self->{"data_step"} );

	# get all layers of export
	my @layers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );
	
	# filter layers, which we don't want to export
	grep { $_->{"gROWname"} } @layers;
 
	# Prepare layers for export
	$self->{"prepareBase"}->Prepare( \@layers );
	$self->{"prepareNC"}->Prepare( \@layers );
 
	return 1;
}

sub __GetLayersForExport{
		my $self = shift;
	
	
}

# Return path of image
sub GetLayers {
	my $self = shift;

	return $self->{"layerList"}->GetLayers();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::OutputData::OutputData';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	
	 

	my $jobId = "f13608";

	my $mess = "";

	my $control = OutputData->new( $inCAM, $jobId, "o+1" );
	$control->Create( \$mess );
}

1;

