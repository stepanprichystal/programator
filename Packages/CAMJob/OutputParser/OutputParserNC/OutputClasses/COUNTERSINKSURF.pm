
#-------------------------------------------------------------------------------------------#
# Description: Parse Surface countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKSURF;
use base('Packages::CAMJob::OutputParser::OutputParserBase::OutputClasses::OutputClassBase');

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

use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::Enums';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputClassResult';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputLayer';
use aliased 'CamHelpers::CamMatrix';
#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKSURF );
	bless $self;
	return $self;
}

sub Prepare {
	my $self = shift;

	$self->_Prepare();

	return $self->{"result"};

}

sub _Prepare {
	my $self = shift;

	my $l = $self->{"layer"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $lName    = $l->{"gROWname"};
	my @chainSeq = $l->{"uniRTM"}->GetCircleChainSeq( RTMEnums->FeatType_SURF );

	return 0 unless (@chainSeq);

	# only special tools with angle
	@chainSeq =
	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	  @chainSeq;

	#compute radiuses for surface
	foreach my $ch (@chainSeq) {

		my $points = ( $ch->GetFeatures() )[0]->{"surfaces"}->[0]->{"island"};
		$ch->{"radius"} = abs( $points->[0]->{"x"} - $points->[1]->{"xmid"} );
	}

	# Chain has new property "radius":  (diameter given by outer edge of rout compensation) / 2

	my @radiuses = ();    # radiuses of whole surface, not

	for ( my $i = 0 ; $i < scalar(@chainSeq) ; $i++ ) {

		my $r = $chainSeq[$i]->{"radius"};

		unless ( grep { ( $_ - 0.01 ) < $r && ( $_ + 0.01 ) > $r } @radiuses ) {
			push( @radiuses, $r );
		}
	}

	# Only radius smaller than 8
	@chainSeq = grep { $_->{"radius"} <= 8 } @chainSeq;

	my @toolSizes = uniq( map { $_->GetChain()->GetChainSize() } @chainSeq );

	foreach my $r (@radiuses) {

		foreach my $tool (@toolSizes) {

			my $outputLayer = OutputLayer->new();    # layer process result

			# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
			my @matchCh =
			  grep { ( $_->{"radius"} - 0.01 ) < $r && ( $_->{"radius"} + 0.01 ) > $r && $_->GetChain()->GetChainSize() == $tool } @chainSeq;

			next unless (@matchCh);

			my $toolDTM   = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool();
			my $toolDepth = $toolDTM->GetDepth();                                       # depth of tool
			my $toolAngle = $toolDTM->GetAngle();                                       # angle of tool

			my $radiusNoDepth = $matchCh[0]->{"radius"};
			my $radiusReal =
			  CountersinkHelper->GetSlotRadiusByToolDepth( $radiusNoDepth * 1000, $tool, $toolAngle, $toolDepth * 1000 ) / 1000;    # in mm
			my $exceededDepth = CountersinkHelper->GetToolExceededDepth( $tool, $toolAngle, $toolDepth * 1000 ) / 1000;             # in mm
			       # get id of all features in chain
			my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @matchCh;

			my $separateL = $self->_SeparateFeatsByIdNC( \@featsId );
			my $drawLayer = CamLayer->RoutCompensation( $inCAM, $separateL, "document" );
						CamMatrix->DeleteLayer($inCAM, $jobId, $separateL);

			if ( $l->{"plated"} ) {
				CamLayer->WorkLayer( $inCAM, $drawLayer );
				CamLayer->ResizeFeatures( $inCAM, -2 * Enums->Plating_THICK );
				$radiusReal -= Enums->Plating_THICKMM;
			}

			# 1) Set prepared layer name
			# Attention!
			# - layer contain original sizes of feature. ( if plated, features are resized by 2xplating thick)
			# - rout layer are compensated to document (feature compnsate thickness is kept)
			$outputLayer->SetLayerName($drawLayer);

			# 2 Add another extra info to output layer

			if ( $l->{"plated"} ) {
				$outputLayer->SetDataVal( "radiusBeforePlt", $radiusReal + Enums->Plating_THICKMM )
				  ;                                    # real compted radius of features in layer before plated [mm]
			}

			$outputLayer->SetDataVal( "radiusReal",    $radiusReal );     # real compted radius of features in layer [mm]
			$outputLayer->SetDataVal( "DTMTool",       $toolDTM );        # DTM tool, which is used for this pads
			$outputLayer->SetDataVal( "exceededDepth", $exceededDepth )
			  ;    # exceeded depth of tool if exist (if depth ot tool is bigger than size of tool peak)
			$outputLayer->SetDataVal( "chainSeq", \@matchCh );    # All chain seq, which was processed in ori layer in this class

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
