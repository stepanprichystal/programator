
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::PcbLabel;

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::PoolMerge::MergeGroup::PcbLabel';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

sub AddLabels {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) Identify step
	my @jobNames = $self->{"poolInfo"}->GetJobNames();

	# 2) identify top and bot layers for adding label
	my @signal = CamJob->GetSignalLayer( $inCAM, $masterJob );

	foreach my $s (@signal) {

		if ( $s->{"gROWname"} =~ /^c$/ ) {
			push( @top, $s->{"gROWname"} );
		}

		if ( $s->{"gROWname"} =~ /^s$/ ) {
			push( @bot, $s->{"gROWname"} );
		}

		if ( $s->{"gROWname"} =~ /^v\(d+)$/ ) {
			if ( $1 % 2 == 0 ) {
				push( @top, $s->{"gROWname"} );
			}
			else {
				push( @bot, $s->{"gROWname"} );
			}
		}
	}

	# 3) Add label to signal layer of each step

	foreach my $jobName (@jobNames) {

		CamHelper->SetStep( $inCAM, $jobName );

		my %lim = CamJob->GetProfileLimits2( $inCAM, $order->{"jobName"}, "o+1", 1 );

		my $lTop = GeneralHelper->GetGUID();
		my $lBot = GeneralHelper->GetGUID();

		$self->__PrepareLabel( "top", $jobName, $masterJob, \%lim, $lTop );
		$self->__PrepareLabel( "bot", $jobName, $masterJob, \%lim, $lBot );

		my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $masterJob, $jobName, $lTop );
		my $featuresCount = $hist->{"total"};

		# 1) copy to top layers
		$self->__CopyLabel( \@top, $lTop, $masterJob );
		$self->__CopyLabel( \@bot, $lBot, $masterJob );

		$inCAM->COM( 'delete_layer', layer => $lTop );
		$inCAM->COM( 'delete_layer', layer => $lBot );
	}

	return $result;
}

sub __CopyLabel {
	my $self      = shift;
	my @top       = @{ shift(@_) };
	my $lName     = shift;
	my $masterJob = shift;

	if ( scalar(@top) ) {
		CamLayer->WorkLayer( $inCAM, $lName );
		my $layers = join( "\;"@top );
		$inCAM->COM( "sel_copy_other", "dest" => "layer_name", "target_layer" => $layers );

		my $f = FeatureFilter->new( $inCAM, $masterJob, undef, \@top );
		$f->SetProfile(2);
		$f->AddIncludeAtt( ".string", "pcb_label" );
		my $cnt = $f->Select();

		if ( ( scalar(@top) * $cnt ) != $featuresCount ) {
			die "error when copy label to lyers";
		}
	}
	
	CamLayer->ClearLayers( $inCAM);
}

sub __PrepareLabel {
	my $self      = shift;
	my $side      = shift;
	my $jobName   = shift;
	my $masterJob = shift;
	my $lim       = shift;
	my $lName     = shift;

	my $pcbW = abs( $lim->{"xMax"} - $lim->{"xMin"} );
	my $pcbH = abs( $lim->{"yMax"} - $lim->{"yMin"} );

	# deside, if label text should be smaller then normal
	my $standardLblWidth = 20;
	my $maxLblWidth      = $standardLblWidth;
	my $drawH            = 1;
	my $drawV            = 1;

	# deside if draw horiyontal

	if ( $pcbW < $standardLblWidth && $pcbH < $standardLblHeight ) {

		# Draw only horizontal
		if ( $pcbW > $pcbH ) {
			$maxLblWidth = $pcbW;
			$drawV       = 0;
		}

		# Draw only vertical
		else {
			$maxLblWidth = $pcbH;
			$drawH       = 0;
		}
	}

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	my $draw = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	if ( $side eq "top" ) {

		# Horizontal
		my $xPos = $lim->{"xMax"} / 2;    # on centre
		if ( $pcbW < $standardLblWidth * 2 ) {
			$xPos = $lim->{"xMin"}        # in zero
		}

		my $sym = LabelSym->new( $jobName, 0, 0, $maxLblWidth );
		$draw->AddSymbol( $sym, Point->new( $xPos, $lim->{"yMax"} ) ) if $drawH;

		# Vertical
		my $yPos = $lim->{"yMax"} / 2;    # on centre
		if ( $pcbH < $standardLblWidth * 2 ) {
			$yPos = $lim->{"yMin"}        # in zero
		}

		my $sym2 = LabelSym->new( $jobName, 0, 1, $maxLblWidth );
		$draw->AddSymbol( $sym2, Point->new( $lim->{"xMin"}, $yPos ) ) if $drawV;

	}
	elsif ( $side eq "bot" ) {

		# Horizontal
		my $xPos = $lim->{"xMax"} / 2;    # on centre
		if ( $pcbW < $standardLblWidth * 2 ) {
			$xPos = $lim->{"xMin"}        # in zero
		}

		my $sym = LabelSym->new( $jobName, 1, 0, $maxLblWidth );
		$draw->AddSymbol( $sym, Point->new( $xPos, $lim->{"yMax"} ) ) if $drawH;

		# Vertical
		my $yPos = $lim->{"yMax"} / 2;    # on centre
		if ( $pcbH < $standardLblWidth * 2 ) {
			$yPos = $lim->{"yMin"}        # in zero
		}

		my $sym2 = LabelSym->new( $jobName, 1, 1, $maxLblWidth );
		$draw->AddSymbol( $sym2, Point->new( $lim->{"xMax"}, $yPos ) ) if $drawV;
	}

	$draw->Draw();

	CamLayer->WorkLayer( $inCAM, $lName );
	CamAttributes->SetFeaturesAttribute( $inCAM, $masterJob, ".string", "pcb_label" );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

