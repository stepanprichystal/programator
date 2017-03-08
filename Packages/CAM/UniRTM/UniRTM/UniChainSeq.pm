#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniChainSeq;

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
 
	$self->{"cyclic"}       = undef;
	$self->{"direction"}    = undef;
	$self->{"footDown"}     = 0;
	$self->{"isInside"}     = 0;        # if is inside another chain sequence
	
	my @outsideChainSeq = ();
	$self->{"outsideChainSeq"} = \@outsideChainSeq;    # chain seq ref, which is this chain sequence inside

	my @features = ();
	$self->{"features"} = \@features; # features, wchich chain sequnece is created from
	$self->{"featureType"} = undef;  # tell type of features, wchich chain is created from. FeatType_SURF/FeatType_LINEARC
 

	return $self;
}

# Helper methods -------------------------------------

# Reeturn points, which crate given chain
# For Line, Arc (arc is fragmented on small arcs) return list of points
# - ecah points are not duplicated
# - for cycle chains, return sorted points CW (start and and are not equal)
# For Surfaces
# - return list of sorted points CW, which create envelop for surface (convex-hull)

sub GetPoints {
	my $self = shift;

	my @points = ();

	my @features = $self->GetFeatures();

 	if($self->GetFeatureType eq Enums->FeatType_SURF){
 		
 		my @envPoints =  map { @{$_->{"envelop"}} } $self->GetFeatures();
 		
 		push( @points, map { [ $_->{"x"}, $_->{"y"} ] } @envPoints );
 		
 	}else{
 		
 		push( @points, [ $features[0]->{"x1"}, $features[0]->{"y1"} ] );    # first point "x1,y1" of feature chain
		push( @points, map { [ $_->{"x2"}, $_->{"y2"} ] } $self->GetFeatures() );    # rest of points "x2,y2"
 	}
 
	return @points;

}

# GET/SET Properties -------------------------------------
 

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
 
sub SetFeatureType {
	my $self  = shift;
	my $type = shift;

	$self->{"featureType"} = $type;

}

sub GetFeatureType {
	my $self = shift;

	return $self->{"featureType"};

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

sub AddOutsideChainSeq {
	my $self  = shift;
	my $chain = shift;

	push(@{$self->{"outsideChainSeq"}}, $chain);

}

sub GetOutsideChainSeq {
	my $self = shift;

	return $self->{"outsideChainSeq"};

}

sub SetCyclic {
	my $self     = shift;
	my $cyclic = shift;

	$self->{"cyclic"} = $cyclic;

}

sub GetCyclic {
	my $self = shift;

	return $self->{"cyclic"};

}


sub SetFootDown {
	my $self     = shift;
	my $footDown = shift;

	$self->{"footDown"} = $footDown;

}

sub GetFootDown {
	my $self = shift;

	return $self->{"footDown"};

}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

