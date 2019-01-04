
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserBase::OutputClasses::OutputClassBase;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library

use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::Enums';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputClassResult';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';

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

	$self->{"result"} = OutputClassResult->new($classType, $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layer"});

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#
# this keep original DTM values in created layer
sub _SeparateFeatsBySymbolsNC {
	my $self         = shift;
	my $symbols      = shift;    # surfaces", "pads", "lines", "arcs", "text"
	my $notUpdateDTM = shift;
	my $notUpdateRTM = shift;

	my $lines    = defined( ( grep { $_ eq "lines" } @{$symbols} )[0] )    ? 1 : 0;
	my $pads     = defined( ( grep { $_ eq "pads" } @{$symbols} )[0] )     ? 1 : 0;
	my $surfaces = defined( ( grep { $_ eq "surfaces" } @{$symbols} )[0] ) ? 1 : 0;
	my $arcs     = defined( ( grep { $_ eq "arcs" } @{$symbols} )[0] )     ? 1 : 0;
	my $text     = defined( ( grep { $_ eq "text" } @{$symbols} )[0] )     ? 1 : 0;

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

	$f->SetFeatureTypes( "line" => !$lines, "pad" => !$pads, "surface" => !$surfaces, "arc" => !$arcs, "text" => !$text );

	 
	if ( $f->Select() > 0 ) {

		CamLayer->DeleteFeatures($inCAM);
	}

	# remove symbols from original layer

	my $f2 = FeatureFilter->new( $inCAM, $jobId, $l->{"gROWname"} );
	$f->SetFilterType( "line" => $lines, "pad" => $pads, "surface" => $surfaces, "arc" => $arcs, "text" => $text );

	if ( $f2->Select() > 0 ) {

		CamLayer->DeleteFeatures($inCAM);

	}
	else {

		die "Failed when select features with symbols (" . join( ";", @{$symbols} ) . ") from  layer ";
	}

	$self->__UpdateDTM( $notUpdateDTM, $notUpdateRTM );

	return $lName;
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

# Set all NC layers to finish sizes (consider type of DTM vysledne/vrtane)
sub _SetDTMFinishSizes {
	my $self  = shift;
	my $lName = shift;

	my $oriLayer = $self->{"layer"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $layerCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Prepare tool table for drill map and final sizes of data (depand on column DSize in DTM)

	my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName );

	my $DTMType = CamDTM->GetDTMType( $inCAM, $jobId, $self->{"step"}, $lName );

	# if DTM type not set, set default DTM type
	if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {

		$DTMType = CamDTM->GetDTMDefaultType( $inCAM, $jobId, $self->{"step"}, $lName, 1 );
	}

	if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {
		die "Typ v Drill tool manageru (vysledne/vrtane) neni nastaven u vrstvy: '" . $lName . "' ";
	}

	# check if dest size are defined
	my @badSize = grep { !defined $_->{"gTOOLdrill_size"} || $_->{"gTOOLdrill_size"} == 0 || $_->{"gTOOLdrill_size"} eq "" } @tools;

	if (@badSize) {
		@badSize = map { $_->{"gTOOLfinish_size"} } @badSize;
		my $toolStr = join( ", ", @badSize );
		die "Tools: $toolStr, has not set drill size.\n";
	}

	# 1) If some tool has not finish size, correct it by putting there drill size (if vysledne resize -100µm)

	foreach my $t (@tools) {

		if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} == 0 || $t->{"gTOOLfinish_size"} eq "" ) {

			if ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {

				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"} - ( 2 * Enums->Plating_THICK );    # 100µm - this is size of plating

			}
			elsif ( $DTMType eq EnumsDrill->DTM_VRTANE ) {
				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};
			}

		}
	}

	# 2) Copy 'finish' value to 'drill size' value.
	# Drill size has to contain value of finih size, because all pads, lines has size depand on this column
	# And we want diameters size after plating

	foreach my $t (@tools) {

		# if DTM is vrtane + layer is plated + it is plated through dps (layer cnt >= 2)
		if ( $DTMType eq EnumsDrill->DTM_VRTANE && $oriLayer->{"plated"} && $layerCnt >= 2 ) {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"} - ( 2 * Enums->Plating_THICK );
		}
		else {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"};
		}
	}

	# 3) Set new values to DTM
	CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName, \@tools );

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'layer',
				  entity_path     => "$jobId/" . $self->{"step"} . "/$lName",
				  data_type       => 'TOOL',
				  options         => "break_sr"
	);

	# 4) If some tools same, merge it
	$inCAM->COM( "tools_merge", "layer" => $lName );
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
