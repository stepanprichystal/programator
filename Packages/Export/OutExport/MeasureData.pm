
#-------------------------------------------------------------------------------------------#
# Description: Export measurep pdf (driil maps) for cooperation pcb
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::OutExport::MeasureData;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use utf8;
use strict;
use warnings;

use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNC';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerDataList';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"data_step"} = "drillMap_step";
	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 0 );
	$self->{"profileLim"} = \%lim;

	$self->{"layerList"} = LayerDataList->new();
	$self->{"prepareNC"} =
	  PrepareNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"data_step"}, $self->{"layerList"}, $self->{"profileLim"} );

	return $self;
}

# Prepare gerber files
sub Output {
	my $self    = shift;
	my $message = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Create flattened step
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"data_step"}, 1 );
	CamHelper->SetStep( $inCAM, $self->{"data_step"} );
	my @childSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $self->{"step"} );

	# get all layers of export
	my @layers = grep { $_->{"gROWname"} =~ /^m$/ } CamJob->GetAllLayers( $inCAM, $jobId );

	# Prepare layers for export

	$self->{"prepareNC"}->Prepare( \@layers, \@childSteps );
	
	my @layersOut = map { $_->GetOutput() } $self->{"layerList"}->GetLayers();
	
	# draw pcb number to layer
	foreach my $l (@layersOut){
		
		my %profileLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"data_step"}, 1 );
 
		my %positionInf = ( "x" => 2, "y" => $profileLim{"yMax"} +2 );
		
		CamLayer->WorkLayer( $inCAM, $l );
		
		CamSymbol->AddText( $inCAM, "Pcb id: $jobId", \%positionInf, 2, undef, 0.5 );
	}
 
	$self->__OutputPdf(\@layersOut);
	

	$self->__Clear();

	return 1;
}


sub __OutputPdf {
	my $self      = shift;
	my $layers = shift;
	 

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layerStr = join(";", @{$layers});

	my $outputPath =  EnumsPaths->Jobs_COOPERDRILL . $jobId . "_drillmap.pdf";
	 
	$outputPath =~ s/\\/\//g;

	CamHelper->SetStep( $inCAM, $self->{"data_step"} );

	$inCAM->COM(
				 'print',
				 layer_name        => $layerStr,
				 mirrored_layers   => '',
				 draw_profile      => 'yes',
				 drawing_per_layer => 'yes',
				 label_layers      => 'no',
				 dest              => 'pdf_file',
				 num_copies        => '1',
				 dest_fname        => $outputPath,
				 paper_size        => 'A4',
				 orient            => 'none',
				 auto_tray         => 'no',
				 top_margin        => '0',
				 bottom_margin     => '0',
				 left_margin       => '0',
				 right_margin      => '0',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
	
	);
 
}


# After using prepared layers, delete layers and step from job
sub __Clear {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l ( $self->{"layerList"}->GetLayers() ) {

		my $lName = $l->GetOutput();

		if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
			$inCAM->COM( "delete_layer", "layer" => $lName );
		}
	}

	#delete if step  exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"data_step"} ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"data_step"}, "type" => "step" );
	}
	
	$self->{"prepareNC"}->Clear();
	
	
}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __GetPadFeats {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lPom = GeneralHelper->GetGUID();
	$inCAM->COM( "merge_layers", "source_layer" => $layer, "dest_layer" => $lPom );

	CamLayer->WorkLayer( $inCAM, $lPom );
	$inCAM->COM('sel_break');
	$inCAM->COM( 'sel_contourize', "accuracy" => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60', "clean_hole_mode" => 'x_and_y' );

	my @feats = ();

	for ( my $i = 0.01 ; $i < 25 ; $i += 0.01 ) {

		CamLayer->WorkLayer( $inCAM, $lPom );

		if ( CamFilter->BySurfaceArea( $inCAM, 0, $i ) > 0 ) {

			my $sellected = GeneralHelper->GetGUID();
			CamLayer->CopySelOtherLayer( $inCAM, [$sellected] );

			CamLayer->WorkLayer( $inCAM, $layer );

			if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $layer, undef, undef, undef, $sellected ) ) {

				my $f = Features->new();
				$f->Parse( $inCAM, $jobId, $self->{"step"}, $layer, 0, 1 );

				@feats = grep { $_->{"symbol"} =~ /(\d+\.?\d*)x(\d+\.?\d*)/i } $f->GetFeatures();

				if ( scalar(@feats) ) {
					last;
				}
			}
			else {

				die "Error during  select minimal pads in stencil layer";
			}

			$inCAM->COM( 'delete_layer', layer => $sellected );
		}
	}

	$inCAM->COM( 'delete_layer', layer => $lPom );

	return @feats;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::OutExport::MeasureData';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152456";

	my $export = MeasureData->new( $inCAM, $jobId, "o+1" );
	$export->Output();

}

1;

