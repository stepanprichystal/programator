
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnBuilder;

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use List::Util qw[min max];

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::Coupon::CpnBuilder::CpnSingleBuilder';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::CpnLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"cpnSource"} = shift;    # source datam based on InStack job xml file
	$self->{"settings"}  = shift;    # global settings for generating coupon

	$self->{"build"} = 0;            # indicator if layout was built

	# layout of whole coupon
	$self->{"layout"} = CpnLayout->new();

	return $self;
}

# Build coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self        = shift;
	my $errMess     = shift;
	my $buildParams = shift;    # contain info about constraints/microstrip groups, etc

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;
	
	$self->__CheckLayerNames();

	# built complete coupon layout
	my $cpnVariant = $buildParams->GetCpnVariant();

	foreach my $singleCpnVar ( $cpnVariant->GetSingleCpns() ) {

		# Built single coupon layout

		# filter constraints by current group
		#		my %tmp;
		#		@tmp{ @{ $groupInf->{"constrainsId"} } } = ();
		#		my @constraints = grep { exists $tmp{ $_->GetConstrainId() } } $self->{"cpnSource"}->GetConstraints();

		my $coupon = CpnSingleBuilder->new( $inCAM, $jobId, $self->{"settings"}, $singleCpnVar );

		if ( $coupon->Build($errMess) ) {

			$self->{"layout"}->AddCouponSingle( $coupon->GetLayout() );
		}
		else {
			$result = 0;
		}

		push( @{ $self->{"couponsSingle"} }, $coupon );

	}

	# Set other coupon layout property
	if ($result) {

		$self->{"layout"}->SetStepName( $self->{"settings"}->GetStepName() );
		
		# width depand on single coupon width
		my $w = max(map{ $_->GetWidth() }$self->{"layout"}->GetCouponsSingle()) + $self->{"settings"}->GetCouponMargin()/1000 * 2;
		$self->{"layout"}->SetWidth($w);

		# height depand on microstrip types
		my $h = $self->{"settings"}->GetCouponMargin()/1000 * 2 + ( scalar( @{ $self->{"couponsSingle"} } ) - 1 ) * $self->{"settings"}->GetCouponSpace()/1000;
		$h += $_->GetHeight() foreach $self->{"layout"}->GetCouponsSingle();
		$self->{"layout"}->SetHeight($h);

		$self->{"build"} = 1;    # build is ok
	}

	return $result;

}

sub GetLayout {
	my $self = shift;

	die "Coupon is not builded" unless ( $self->{"build"} );

	return $self->{"layout"};

}

sub __CheckLayerNames{
	my $self = shift;
 
	my @copperLayers = $self->{"cpnSource"}->GetCopperLayers();
 	
	# 1) Check if layer names are L1-Ln
	
	@copperLayers = sort { $a->{"LAYER_INDEX"} <=> $b->{"LAYER_INDEX"} } @copperLayers;
	
	for(my $i= 0; $i < scalar(@copperLayers); $i++){
		
		my $l = $copperLayers[$i]->{"NAME"};
		
		if($l !~ m/L(\d+)/ || $1 != $i+1){
			
			die "Wrong layer name: $l, is on postion: $i in InSTACK stackup.";
		}
	}
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Coupon::CpnBuilder::CpnBuilder';
	use aliased 'Packages::Coupon::CpnSettings::CpnSettings';
	use aliased 'Packages::Coupon::CpnSource::CpnSource';
	use aliased 'Packages::Coupon::CpnBuilder::BuildParams';
	use aliased 'Packages::Coupon::CpnGenerator::CpnGenerator';
	use aliased 'Packages::Coupon::CpnPolicy::GroupPolicy';
	use aliased 'Packages::Coupon::CpnPolicy::LayoutPolicy';
	use aliased 'Packages::Coupon::CpnPolicy::SortPolicy';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $p         = 'c:\Export\CouponExport\cpn.xml';
	my $cpnSource = CpnSource->new($p);
	my $cpnSett   = CpnSettings->new();
	$cpnSett->{"sett"}->{"trackPadIsolation"} = 200;
	my $builder = CpnBuilder->new( $inCAM, $jobId, $cpnSource, $cpnSett );

	# generate groups, choose one variant

	my @layers = map { $_->{"NAME"} } $cpnSource->GetCopperLayers();

	# Group policy

	# Return structure => Array of groups combinations
	# Each combination contain groups,
	# Each group contain strips
	my $groupPolicy = GroupPolicy->new( $cpnSource, $cpnSett->GetMaxTrackCnt() );
	
	#my @filter = (1); # below + above lines
	#my @filter = (1); # below + above lines
		my @filter = ( 5); # below + above lines
	#my @filter = (3);

	my @groupsComb = $groupPolicy->GenerateGroups( \@filter );

	# Generate structure => Arraz of group combination
	# Each combination contain groups,
	# Each group contain pools
	# Each pool contain strips
	my @groupsPoolComb = ();

	foreach my $comb (@groupsComb) {

		my $combPools = [];

		if ( $groupPolicy->VerifyGroupComb( $comb, $cpnSett->GetPoolCnt(), $cpnSett->GetMaxStripsCntH(), $combPools ) ) {

			push( @groupsPoolComb, $combPools );
		}
	}

	print STDERR "\n\n--- Combination after generate pool groups: " . scalar(@groupsPoolComb) . " \n";

	# Generate structure => Array of CpnVariant strutures
	my $layoutPolicy = LayoutPolicy->new(
										  \@layers,                         $cpnSett->GetPoolCnt(),
										  $cpnSett->GetShareGNDPads(),      $cpnSett->GetMaxTrackCnt(),
										  $cpnSett->GetTrackPadIsolation(), $cpnSett->GetTracePad2GNDPad(),
										  $cpnSett->GetPadTrackSize(),      $cpnSett->GetPadGNDSize(),
										  $cpnSett->GetRouteBetween(),      $cpnSett->GetRouteAbove(),
										  $cpnSett->GetRouteBelow(),        $cpnSett->GetRouteStraight()
	);

	my @variants = ();

	my $idx = 0;
	#my @test = ($groupsPoolComb[0]);
	#@groupsPoolComb = $groupsPoolComb[-1];
	foreach my $comb (@groupsPoolComb) {

		my $cpnVariant = $layoutPolicy->GetStripLayoutVariants( $comb);

		if ( defined $cpnVariant )  {
			push( @variants, $cpnVariant );
		}
	}
	
	unless(scalar(@variants)){
		
		die "No combination is possible";
	}
	
	# Sort policy

	my $sortPolicy   = SortPolicy->new();
	my @sortVariants = $sortPolicy->SortVariants( \@variants );

	my $v = $sortVariants[0];
	
 

	print STDERR "Choosed variant:\n\n" . $v;

	#	my $g = $groupsComb[0];    # take first comb
	#
	#	unless ( $groupPolicy->GroupCombExists( \@filter, $g ) ) {
	#		die "group doesn 't exist";
	#	}

	#my $buildParams = BuildParams->new( scalar( $cpnSource->GetConstraints() ) );
	my $buildParams = BuildParams->new($v);

	my $errMess = "";
	my $res = $builder->Build( \$errMess, $buildParams );

	print STDERR "Build: $res\n";

	my $generator = CpnGenerator->new( $inCAM, $jobId, $cpnSett );

	$inCAM->SetDisplay(0);
	$generator->Generate( $builder->GetLayout() );
	$inCAM->SetDisplay(1);

}

1;

