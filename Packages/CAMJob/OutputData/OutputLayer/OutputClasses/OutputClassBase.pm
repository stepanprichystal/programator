
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputClasses::OutputClassBase;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library

use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputClassResult';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;

	my $classType = shift;

	$self->{"result"} = OutputClassResult->new($classType);

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#
# this keep original DTM values in created layer
sub _SeparateFeatsBySymbolsNC {
	my $self         = shift;
	my $symbols      = shift; # surface", "pad", "line", "arc"
	my $notUpdateDTM = shift;
	my $notUpdateRTM = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $l = $self->{"layer"};

	my $lName = GeneralHelper->GetNumUID();

	# copy fuul original lazer in order keep DTM values
	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $step,
				 "source_layer" => $l->{"gROWname"},
				 "dest"         => 'layer_name',
				 "dest_layer"   => $lName,
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	# remove features, symbol type don't match which symbols (from new layer)

	my $f = FeatureFilter->new( $inCAM, $jobId, $lName );
	$f->AddExcludeSymbols($symbols);

	if ( $f->Select() > 0 ) {

		CamLayer->DeleteFeatures($inCAM);
	}

	# remove symbols from original layer

	my $f2 = FeatureFilter->new( $inCAM, $jobId, $l->{"gROWname"} );
	$f2->AddIncludeSymbols($symbols);

	if ( $f2->Select() > 0 ) {

		CamLayer->DeleteFeatures($inCAM);

	}
	else {

		die "Failed when select features with symbols (" . join( ";", @{$symbols} ) . ") from  layer ";
	}

	$self->__UpdateDTM( $notUpdateDTM, $notUpdateRTM );

}

# This function is prete same, but by default update UniDTM and UniRTM if exist
sub _SeparateFeatsByIdNC {
	my $self         = shift;
	my $features     = shift;
	my $notUpdateDTM = shift;
	my $notUpdateRTM = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $l = $self->{"layer"};

	my $layer = $self->_SeparateFeatsById($features);

	$self->__UpdateDTM( $notUpdateDTM, $notUpdateRTM );

	return $layer;
}

sub _SeparateFeatsById {
	my $self       = shift;
	my $featuresId = shift;    # by feature ids

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $l     = $self->{"layer"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetNumUID();
	my $f = FeatureFilter->new( $inCAM, $jobId, $l->{"gROWname"} );
	$f->AddFeatureIndexes($featuresId);

	if ( $f->Select() > 0 ) {

		$inCAM->COM(
			"sel_move_other",

			# "dest"         => "layer_name",
			"target_layer" => $lName
		);

		CamLayer->WorkLayer( $inCAM, $lName );
		my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_delete");

		$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		$inCAM->COM( "delete_layer", "layer" => $lComp );

		return $lName;
	}
	else {

		die "Failed when select features (" . join( ";", @{$featuresId} ) . ") from  layer ";

	}

}

sub __UpdateDTM {
	my $self         = shift;
	my $notUpdateDTM = shift;
	my $notUpdateRTM = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $l = $self->{"layer"};

	unless ($notUpdateDTM) {

		if ( defined $l->{"uniDTM"} ) {

			$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 0 );
		}

		if ( defined $l->{"uniRTM"} ) {

			$l->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 0, $l->{"uniDTM"} );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
