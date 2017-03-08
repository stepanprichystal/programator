#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniRTMBase;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Packages::Polygon::PolygonHelper';
use aliased 'Packages::Polygon::Enums' => "PolyEnums";
use aliased 'Packages::CAM::UniRTM::UniRTM::Parser::RoutParser';
use aliased 'Packages::CAM::UniRTM::UniRTM::Parser::ChainParser';
use aliased 'Packages::Polygon::PolygonPoints';

#use aliased 'CamHelpers::CamDTM';
#use aliased 'CamHelpers::CamDTMSurf';
#use aliased 'CamHelpers::CamDrilling';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolBase';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTM';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTMSURF';
#use aliased 'Packages::CAM::UniDTM::Enums';
#use aliased 'Enums::EnumsDrill';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Packages::CAM::UniDTM::UniDTM::UniDTMCheck';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;

	$self->{"breakSR"} = shift;
	$self->{"flatten"} = shift;

	my @features = ();
	$self->{"features"} = \@features;

	my @chains = ();
	$self->{"chains"} = \@chains;

	$self->{"innerRout"}     = undef;
	$self->{"outerRout"}     = undef;
	$self->{"outerBrdgRout"} = undef;

	my @nested = ();
	$self->{"uniRTMlist"} = \@nested;

	$self->__InitUniRTM();

	return $self;
}

sub __InitUniRTM {
	my $self = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my $step    = $self->{"step"};
	my $layer   = $self->{"layer"};
	my $breakSR = $self->{"breakSR"};

	# 1) Parse features
	my @features = RoutParser->GetFeatures( $inCAM, $jobId, $step, $layer, $breakSR );
	$self->{"features"} = \@features;

	# 2) Get route chains by same .rout_tool atribute
	my @chains = ChainParser->GetChains( \@features );
	$self->{"chains"} = \@chains;

	# 4) Get information about mutual position of chain sequences
	# If chain is inside another chain, save this information

	my @seqs = map { $_->GetChainSequences() } @chains;    # all chain sequences

	for ( my $i = 0 ; $i < scalar(@seqs) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar(@seqs) ; $j++ ) {

			if ( $i == $j ) {
				next;
			}

			my $seqIn  = $seqs[$i];
			my $seqOut = $seqs[$j];

			if ( $seqOut->GetCyclic() ) {

				my @seqInPoints  = $seqIn->GetPoints();
				my @seqOutPoints = $seqOut->GetPoints();

				my $pos = undef;

				if ( $seqIn->GetCyclic() ) {
					$pos = PolygonPoints->GetPoly2PolyIntersect( \@seqInPoints, \@seqOutPoints );
				}
				else {
					$pos = PolygonPoints->GetPoints2PolygonPosition( \@seqInPoints, \@seqOutPoints );
				}

				if ( $pos eq PolyEnums->Pos_INSIDE ) {
					$seqIn->SetIsInside(1);
					$seqIn->AddOutsideChainSeq($seqOut);
				}
			}
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

