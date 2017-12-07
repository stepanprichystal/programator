#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniChain;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Packages::CAM::UniRTM::Enums';

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

	$self->{"chainTool"} = shift;
	 
	my @chainSeq = ();
	$self->{"chainSequences"} = \@chainSeq; # features, wchich chain is created from

	my @features = ();
	$self->{"features"} = \@features; # features, wchich chain is created from
	


	return $self;
}

# Helper methods -------------------------------------

# Reeturn points, which crate given chain
# For Line, Arc (arc is fragmented on small arcs) return list of points
# - ecah points are not duplicated
# - for cycle chains, return sorted points CW (start and and are not equal)
# For Surfaces
# - return list of sorted points CW, which create envelop for surface (convex-hull)

sub GetChainPoints {
	my $self = shift;

	my @points = ();

	my @features = $self->GetFeatures();

 	if($self->GetFeatureType eq Enums->FeatType_SURF){
 		
 		
 		push( @points, map { [ $_->{"x2"}, $_->{"y2"} ] } $self->GetFeatures() )
 		
 	}else{
 		
 		push( @points, [ $features[0]->{"x2"}, $features[0]->{"y2"} ] );    # first point "x1,y1" of feature chain
		push( @points, map { [ $_->{"x2"}, $_->{"y2"} ] } $self->GetFeatures() );    # rest of points "x2,y2"
 	}
 


	return $self->{"chainSize"};

}

 


# GET/SET Properties -------------------------------------


sub AddChainSeq {
	my $self    = shift;
	my $seq = shift;

	push( @{ $self->{"chainSequences"} }, $seq );

}

sub GetChainSequences {
	my $self    = shift;
	 
	return  @{ $self->{"chainSequences"} };

}

 

sub GetChainOrder {
	my $self = shift;

	return $self->{"chainTool"}->{"chainOrder"};

}

sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };

}

sub AddFeature {
	my $self    = shift;
	my $feature = shift;

	push( @{ $self->{"features"} }, $feature );

}

sub SetFeatures {
	my $self     = shift;
	my $features = shift;

	$self->{"features"} = $features;

}

sub GetComp {
	my $self = shift;

	return $self->{"chainTool"}->{"comp"};
}

 

sub SetFootDown {
	my $self = shift;
	my $foot = shift;

	$self->{"footDown"} = $foot;

}

sub SetIsInside {
	my $self     = shift;
	my $isInside = shift;

	$self->{"isInside"} = $isInside;

}

sub GetIsInside {
	my $self = shift;

	return $self->{"isInside"};

}

sub SetOutsideChain {
	my $self  = shift;
	my $chain = shift;

	$self->{"outsideChain"} = $chain;

}

sub GetOutsideChain {
	my $self = shift;

	return $self->{"outsideChain"};

}
 

sub GetChainSize {
	my $self = shift;

	return $self->{"chainTool"}->{"chainSize"};
}

sub GetChainTool{
	my $self = shift;

	return $self->{"chainTool"};
}

sub GetStrInfo {
	my $self = shift;

	return "Chain number: \"" . $self->GetChainOrder();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

