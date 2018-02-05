
#-------------------------------------------------------------------------------------------#
# Description: Parse pad countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserCountersink::OutputClasses::COUNTERSINKPAD;
use base('Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKPAD');

use Class::Interface;
&implements('Packages::CAMJob::OutputParser::OutputParserBase::OutputClasses::IOutputClass');

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library

use aliased 'Packages::CAMJob::OutputParser::OutputParserCountersink::Enums';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputClassResult';

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputLayer';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKPADTHR );
	bless $self;
	return $self;
}

sub Prepare {
	my $self = shift;

	$self->_Prepare();

	$self->__PrepareCountersink();

	return $self->{"result"};

}

sub __PrepareCountersink {
	my $self = shift;

	my $l = $self->{"layer"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# keep old results
	my @layers = $self->{"result"}->GetLayers();

	# init new class result
	$self->{"result"} = OutputClassResult->new( Enums->Type_COUNTERSINKPADTHR, $inCAM, $jobId, $step, $l );

	# get layer, where through hole can be
	my @npltDrill = ();
	push( @npltDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nMill ) );
	push( @npltDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nDrill ) );

	@npltDrill = map { $_->{"gROWname"} } @npltDrill;
	my $npltDrill = GeneralHelper->GetGUID();

	if ( scalar(@npltDrill) ) {
		CamLayer->AffectLayers( $inCAM, \@npltDrill );
		CamLayer->CopySelected( $inCAM, [$npltDrill] );
		CamLayer->WorkLayer( $inCAM, $npltDrill );
	}

	foreach my $lRes (@layers) {

		my %drillTools   = ();
		my $curDrillTool = undef;

		foreach my $csPad ( @{ $lRes->{"padFeatures"} } ) {

			my %pos = ( "x" => $csPad->{"x1"}, "y" => $csPad->{"y1"} );

			# if exist nplt drill layer, try to select through drill (pad) according countersink position
			my $padsCnt = 0;
			if ( scalar(@npltDrill) ) {

				$inCAM->COM(
							 "sel_single_feat",
							 "operation"  => "select",
							 "x"          => $pos{"x"},
							 "y"          => $pos{"y"},
							 "tol"        => "100",
							 "cyclic"     => "no",
							 "clear_prev" => "yes"
				);

				$inCAM->COM('get_select_count');
				$padsCnt = $inCAM->GetReply();
			}

			if ($padsCnt) {

				my $f = Features->new();
				$f->Parse( $inCAM, $jobId, $step, $npltDrill, 0, 1 );
				my @tools = map { $_->{"thick"} } grep { $_->{"type"} eq "P" } $f->GetFeatures();
				$curDrillTool = max(@tools);

			}
			else {
				$curDrillTool = "noHole";
			}

			if ( !defined $drillTools{$curDrillTool} ) {
				$drillTools{$curDrillTool} = [];
			}

			push( @{ $drillTools{$curDrillTool} }, \%pos );

		}

		foreach my $drillTool ( keys %drillTools  ) {
			my $outputLayer = OutputLayer->new();    # layer process result
			$outputLayer->{"positions"}  = $drillTools{$curDrillTool};
			$outputLayer->{"radiusReal"} = $lRes->{"radiusReal"};
			$outputLayer->{"DTMTool"}    = $lRes->{"DTMTool"};
			$outputLayer->{"drillTool"}  = $curDrillTool;                #tool size of through drill

			$self->{"result"}->AddLayer($outputLayer);
		}

 
	}
 
	die;

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
