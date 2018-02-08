
#-------------------------------------------------------------------------------------------#
# Description: Parse arc countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKARC;
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

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_, Enums->Type_COUNTERSINKARC );
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
	my @chainSeq = $l->{"uniRTM"}->GetCircleChainSeq( RTMEnums->FeatType_LINEARC );

	return 0 unless (@chainSeq);

	# only special tools with angle, radius max 5mm
	@chainSeq =
	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	  @chainSeq;

	#compute radiuses for surface
	# Chain has new property "radius":  (diameter of whole surface) / 2

	# add radius property to all chain

	foreach my $chanSeq (@chainSeq) {

		my $chainSize = $chanSeq->GetChain()->GetChainSize() / 1000;    # in mm

		my $arc = ( $chanSeq->GetFeatures() )[0];
		$arc->{"dir"} = $arc->{"newDir"};                               # GetFragmentArc assume propertt "dir"
		PolygonAttr->AddArcAtt($arc);

		my $radius = $arc->{"radius"};

		my $comp = $arc->{"att"}->{".comp"};

		# comp is in center of arc
		if ( $comp eq EnumsRout->Comp_NONE ) {
			$radius += $chainSize / 2;
		}

		# comp is out of circle
		elsif (    ( $comp eq EnumsRout->Comp_LEFT && $arc->{"newDir"} eq EnumsRout->Dir_CW )
				|| ( $comp eq EnumsRout->Comp_RIGHT && $arc->{"newDir"} eq EnumsRout->Dir_CCW ) )
		{
			$radius += $chainSize;
		}

		$chanSeq->{"radius"} = $radius;
	}

	# Only radius smaller than 8
	@chainSeq = grep { $_->{"radius"} <= 8 } @chainSeq;

	my @radiuses = ();    # radiuses of whole surface, not

	for ( my $i = 0 ; $i < scalar(@chainSeq) ; $i++ ) {

		my $r = $chainSeq[$i]->{"radius"};

		unless ( grep { ( $_ - 0.01 ) < $r && ( $_ + 0.01 ) > $r } @radiuses ) {
			push( @radiuses, $r );
		}
	}

	my @toolSizes = uniq( map { $_->GetChain()->GetChainSize() } @chainSeq );

	foreach my $r (@radiuses) {

		foreach my $tool (@toolSizes) {

			my $outputLayer = OutputLayer->new();    # layer process result

			# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
			my @matchCh =
			  grep { ( $_->{"radius"} - 0.01 ) < $r && ( $_->{"radius"} + 0.01 ) > $r && $_->GetChain()->GetChainSize() == $tool } @chainSeq;

			next unless (@matchCh);

			my $toolDepth = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
			my $toolAngle = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();    # angle of tool

			my $radiusNoDepth = $matchCh[0]->{"radius"};
			my $radiusReal = CountersinkHelper->GetSlotRadiusByToolDepth( $radiusNoDepth * 1000, $tool, $toolAngle, $toolDepth * 1000 ) / 1000;

			if ( $l->{"plated"} ) {
				$radiusReal -= 0.05;
			}

			# get id of all features in chain
			my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @matchCh;

			my $drawLayer = $self->_SeparateFeatsByIdNC( \@featsId );

			# 1) Set prepared layer name
			$outputLayer->SetLayerName($drawLayer);    # Attention! lazer contain original sizes of feature, not finish/real sizes

			# 2 Add another extra info to output layer
			if ( $l->{"plated"} ) {
				$outputLayer->{"radiusBeforePlt"} = $radiusReal += 0.05;    # real compted radius of features in layer before plated
			}
			$outputLayer->{"radiusReal"} = $radiusReal;                     # real compted radius of features in layer
			$outputLayer->{"chainSeq"}   = \@matchCh;                       # All chain seq, which was processed in ori layer in this class
 
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
