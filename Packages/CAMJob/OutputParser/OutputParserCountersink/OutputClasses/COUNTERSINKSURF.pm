
#-------------------------------------------------------------------------------------------#
# Description: Parse pad countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserCountersink::OutputClasses::COUNTERSINKSURF;
use base('Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKSURF');

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
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKSURFTHR );
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
	$self->{"result"} = OutputClassResult->new( Enums->Type_COUNTERSINKSURFTHR, $inCAM, $jobId, $step, $l );

	# get layer, where through hole can be

	my @thrghDrill = ();

	#decide between plated/nplated layers
	if ( $l->{"plated"} ) {

		push( @thrghDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill ) );
		push( @thrghDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill ) );
	}
	else {

		push( @thrghDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nMill ) );
		push( @thrghDrill, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nDrill ) );
	}

	@thrghDrill = map { $_->{"gROWname"} } @thrghDrill;
	my $thrghDrill = GeneralHelper->GetGUID();

	if ( scalar(@thrghDrill) ) {
		CamLayer->AffectLayers( $inCAM, \@thrghDrill );
		CamLayer->CopySelected( $inCAM, [$thrghDrill] );
		CamLayer->WorkLayer( $inCAM, $thrghDrill );
	}

	foreach my $lRes (@layers) {

		my %drillTools   = ();
		my $curDrillTool = undef;

		foreach my $chainSeq ( @{ $lRes->{"chainSeq"} } ) {

			my $island = ( ( $chainSeq->GetFeatures() )[0]->{"surfaces"} )->[0]->{"island"};
			my $center = ( grep { $_->{"type"} eq "c" } @{$island} )[0];

			my %pos = ( "x" => $center->{"xmid"}, "y" => $center->{"ymid"} );

			# if exist nplt drill layer, try to select through drill (pad) according countersink position
			my $padsCnt = 0;
			if ( scalar(@thrghDrill) ) {

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
				$f->Parse( $inCAM, $jobId, $step, $thrghDrill, 0, 1 );
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

		foreach my $drillTool ( keys %drillTools ) {
			my $outputLayer = OutputLayer->new();    # layer process result

			my $drawLayer = GeneralHelper->GetGUID();
			CamMatrix->CreateLayer( $inCAM, $jobId, $drawLayer, "document", "positive", 0 );
			$outputLayer->SetLayerName($drawLayer);    # empty layer

			$outputLayer->{"positions"}  = $drillTools{$drillTool};
			$outputLayer->{"radiusReal"} = $lRes->{"radiusReal"};
			$outputLayer->{"DTMTool"}    = $lRes->{"chainSeq"}->[0]->GetChain()->GetChainTool()->GetUniDTMTool();
			my $dt = undef;
			if ( $drillTool ne "noHole" ) {
				$dt = $drillTool / 1000 / 2;           # convert to mm and get radius
			}

			$outputLayer->{"drillTool"} = $dt;         #tool size of through drill

			$self->{"result"}->AddLayer($outputLayer);
		}

	}

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
