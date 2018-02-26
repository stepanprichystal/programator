
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare NC layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareNC;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNCDrawing';
use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNCStandard';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"oriStep"}    = shift;
	$self->{"step"}       = shift;
	$self->{"layerList"}  = shift;
	$self->{"profileLim"} = shift;
	
	 $self->{"outputNClayer"} = OutputParserNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	

	$self->{"prepareNCStandard"} =
	  PrepareNCStandard->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layerList"}, $self->{"profileLim"}, $self->{"outputNClayer"} );
	$self->{"prepareNCDrawing"} =
	  PrepareNCDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layerList"}, $self->{"profileLim"}, $self->{"outputNClayer"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"plateThick"} = 100;    # value of plating in holes 100 µm

	return $self;
}

sub Prepare {
	my $self       = shift;
	my @layers     = @{ shift(@_) };
	my @childSteps = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Set layer info for each NC layer and filter only NC board layer

	CamDrilling->AddNCLayerType( \@layers );
	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;
	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	# Load feature histogram histogram
	foreach my $l (@layers) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;
	}

	# Remove layers, if thay donesn't contain any features
	for ( my $i = scalar(@layers) - 1 ; $i >= 0 ; $i-- ) {

		if ( $layers[$i]->{"fHist"}->{"total"} == 0 ) {
			splice @layers, $i, 1;
		}
	}

	# 1) Check if all parameters are ok. Such as vysledne/vrtane, one surfae depth per layer, etc..
	$self->__CheckNCLayers( \@layers );
 
	
	# 2) Load histograms about layer features and their attribues
	foreach my $l (@layers) {

		# a) feature attributes histogram
		my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
		$l->{"attHist"} = \%attHist;

		# b) symbol histogram - combine line and arcs conut (because we use same tool)
		my %sHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $l->{"gROWname"}, 1, 1 );

		my %line_arcs = ();
		foreach my $k ( keys %{ $sHist{"lines"} } ) {
			$line_arcs{$k} = 0;

			$line_arcs{$k} += $sHist{"lines"}->{$k} if ( defined $sHist{"lines"}->{$k} );
			$line_arcs{$k} += $sHist{"arcs"}->{$k}  if ( defined $sHist{"arcs"}->{$k} );
		}
		$sHist{"lines_arcs"} = \%line_arcs;
		$l->{"symHist"} = \%sHist;
  

	}

	# 5) Create layer data for NC layers
	$self->{"prepareNCStandard"}->Prepare( \@layers, Enums->Type_NCLAYERS );
	$self->{"prepareNCDrawing"}->Prepare( \@layers, Enums->Type_NCLAYERS );

}

sub Clear{
	my $self   = shift;
	
	$self->{"outputNClayer"}->Clear();	
}

sub __CheckNCLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $mess = "";

	my @layerNames = map { $_->{"gROWname"} } @layers;

	unless ( LayerCheckError->CheckNCLayers( $inCAM, $jobId, $self->{"oriStep"}, \@layerNames, \$mess ) ) {

		# Do clean up

		my $inCAM = $self->{"inCAM"};
		my $jobId = $self->{"jobId"};

		foreach my $l ( $self->{"layerList"}->GetLayers() ) {

			my $lName = $l->GetOutput();

			if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
				$inCAM->COM( "delete_layer", "layer" => $lName );
			}

			#delete if step  exist
			if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"step"} ) ) {
				$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"step"}, "type" => "step" );
			}

		}

		die "Can't prepare NC layers for output. NC layers contains error: $mess \n";
	}

}

 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
