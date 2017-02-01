
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::ProduceData;

#3th party library
use strict;
use warnings;

#local library

 

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Gerbers::ProduceData::LayerDataList';
use aliased 'Packages::Gerbers::ProduceData::Output';
use aliased 'Packages::Gerbers::ProduceData::OutputPrepare';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"step"} = shift;
	
	$self->{"data_step"} = "data_".$self->{"step"};

	$self->{"layerList"}     = LayerDataList->new(  );
	$self->{"outputPrepare"} = OutputPrepare->new(  $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"} );
	$self->{"output"}     = Output->new(  $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"} );
	$self->{"outputPath"}    = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

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
	CamHelper->SetStep( $inCAM, $self->{"mdiStep"} );
	

	# get all board layers
	my @layers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );

 
	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );


	# Prepare layers for export
	$self->{"outputPrepare"}->PrepareLayers( \@layers );
	 
  
	$self->{"output"}->Output( $self->{"layerList"} );

	return 1;
}

# Return path of image
sub GetOutput {
	my $self = shift;

	return $self->{"outputPdf"}->GetOutput();
}
 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

