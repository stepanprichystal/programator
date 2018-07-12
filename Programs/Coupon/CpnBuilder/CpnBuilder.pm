
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnBuilder;

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use List::Util qw[min max];

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Coupon::Enums';
use aliased 'Programs::Coupon::CpnBuilder::CpnSingleBuilder';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::TitleBuilder';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnLayout';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::CpnLayerBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"cpnSource"} = shift;    # source datam based on InStack job xml file

	$self->{"layout"} = CpnLayout->new();    # layout of whole coupon
	$self->{"build"}  = 0;                   # indicator if layout was built

	# Settings references
	$self->{"cpnSett"} = undef;

	return $self;
}

# Build coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self       = shift;
	my $cpnVariant = shift;    # contain info about constraints/microstrip groups, etc
	my $errMess    = shift;

	$self->{"cpnSett"} = $cpnVariant->GetCpnSettings();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	$self->__CheckLayerNames();

	# built complete coupon layout
	#my $cpnVariant = $buildParams->GetCpnVariant();

	foreach my $singleCpnVar ( $cpnVariant->GetSingleCpns() ) {

		# Built single coupon layout

		my $coupon = CpnSingleBuilder->new( $inCAM, $jobId,, );

		if ( $coupon->Build( $singleCpnVar, $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->AddCouponSingle( $coupon->GetLayout() );
		}
		else {
			$result = 0;
		}

		push( @{ $self->{"couponsSingle"} }, $coupon );

	}

	# build title
	if ( $self->{"cpnSett"}->GetTitle() ) {

		# compute height of cpn single (without cpn argin)
		my $h = ( scalar( @{ $self->{"couponsSingle"} } ) - 1 ) * $self->{"cpnSett"}->GetCouponSpace() / 1000;
		$h += $_->GetHeight() foreach $self->{"layout"}->GetCouponsSingle();

		my $tBuilder = TitleBuilder->new( $inCAM, $jobId, $h );
		if ( $tBuilder->Build( $cpnVariant, $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->SetTitleLayout( $tBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

	}

	# build other layout property
	if ($result) {

		# Cpn Margin,

		my %cpnMargin = ();
		$cpnMargin{"left"}  = $self->{"cpnSett"}->GetCouponMargin() / 1000;
		$cpnMargin{"top"}   = $self->{"cpnSett"}->GetCouponMargin() / 1000;
		$cpnMargin{"right"} = $self->{"cpnSett"}->GetCouponMargin() / 1000;
		$cpnMargin{"bot"}   = $self->{"cpnSett"}->GetCouponMargin() / 1000;

		if ( $self->{"cpnSett"}->GetTitle() ) {

			my $titleLayout = $self->{"layout"}->GetTitleLayout();

			if ( $titleLayout->GetHeight() > $self->{"cpnSett"}->GetCouponMargin() / 1000 ) {

				$cpnMargin{"left"} = $titleLayout->GetHeight() if ( $self->{"cpnSett"}->GetTitleType() eq "left" );
				$cpnMargin{"top"}  = $titleLayout->GetHeight() if ( $self->{"cpnSett"}->GetTitleType() eq "top" );
			}
		}

		$self->{"layout"}->SetCpnMargin( \%cpnMargin );

		# Step name
		$self->{"layout"}->SetStepName( $self->{"cpnSett"}->GetStepName() );

		# Cpn single positions

		my $yCurrent = $cpnMargin{"bot"};

		for ( my $i = 0 ; $i < scalar( $self->{"layout"}->GetCouponsSingle() ) ; $i++ ) {
			my $cpnSignleLayout = ( $self->{"layout"}->GetCouponsSingle() )[$i];

			my $pos = Point->new( $cpnMargin{"left"}, $yCurrent );
			$cpnSignleLayout->SetPosition($pos);

			$yCurrent += $cpnSignleLayout->GetHeight() + $self->{"cpnSett"}->GetCouponSpace() / 1000;
		}

		# Build layer information

		my $lBuilder = CpnLayerBuilder->new( $inCAM, $jobId );
		if ( $lBuilder->Build( $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->SetLayersLayout( $lBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

		# Dimensions

		my %cpnArea = $self->GetCpnArea();

		$self->{"layout"}->SetWidth( $cpnArea{"w"} );
		$self->{"layout"}->SetHeight( $cpnArea{"h"} );

		$self->{"build"} = 1;    # build is ok
	}

	return $result;

}

sub GetLayout {
	my $self = shift;

	die "Coupon is not builded" unless ( $self->{"build"} );

	return $self->{"layout"};

}

sub GetCpnArea {
	my $self = shift;
 

	my %areaInfo = ( "w" => undef, "h" => undef );

	# width depand on single coupon width
	my $w = max( map { $_->GetWidth() } $self->{"layout"}->GetCouponsSingle() ) + $self->{"cpnSett"}->GetCouponMargin() / 1000 * 2;

	# consider title text on left
	if ( $self->{"cpnSett"}->GetTitle() && $self->{"cpnSett"}->GetTitleType() eq "left" ) {

		my $tLayout = $self->{"layout"}->GetTitleLayout()->GetHeight();

		if ( $self->{"layout"}->GetTitleLayout()->GetHeight() > $self->{"cpnSett"}->GetCouponMargin() / 1000 ) {
			$w += -$self->{"cpnSett"}->GetCouponMargin() / 1000 + $self->{"layout"}->GetTitleLayout()->GetHeight();
		}
	}

	# height depand on microstrip types
	my $h = $self->{"cpnSett"}->GetCouponMargin() / 1000 * 2 +
	  ( scalar( @{ $self->{"couponsSingle"} } ) - 1 ) * $self->{"cpnSett"}->GetCouponSpace() / 1000;
	$h += $_->GetHeight() foreach $self->{"layout"}->GetCouponsSingle();

	# consider title text on top
	if ( $self->{"cpnSett"}->GetTitle() && $self->{"cpnSett"}->GetTitleType() eq "top" ) {
		if ( $self->{"layout"}->GetTitleLayout()->GetHeight() > $self->{"cpnSett"}->GetCouponMargin() / 1000 ) {
			$h += -$self->{"cpnSett"}->GetCouponMargin() / 1000 + $self->{"layout"}->GetTitleLayout()->GetHeight();
		}
	}

	$areaInfo{"h"} = $h;
	$areaInfo{"w"} = $w;

	return %areaInfo;
}

sub __CheckLayerNames {
	my $self = shift;

	my @copperLayers = $self->{"cpnSource"}->GetCopperLayers();

	# 1) Check if layer names are L1-Ln

	@copperLayers = sort { $a->{"LAYER_INDEX"} <=> $b->{"LAYER_INDEX"} } @copperLayers;

	for ( my $i = 0 ; $i < scalar(@copperLayers) ; $i++ ) {

		my $l = $copperLayers[$i]->{"NAME"};

		if ( $l !~ m/L(\d+)/ || $1 != $i + 1 ) {

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
	use aliased 'Programs::Coupon::CpnBuilder::CpnBuilder';
	use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
	use aliased 'Programs::Coupon::CpnSource::CpnSource';
	use aliased 'Programs::Coupon::CpnBuilder::BuildParams';
	use aliased 'Programs::Coupon::CpnGenerator::CpnGenerator';
	use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';
	use aliased 'Programs::Coupon::CpnPolicy::LayoutPolicy';
	use aliased 'Programs::Coupon::CpnPolicy::SortPolicy';
	use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $p         = 'c:\Export\CouponExport\cpn.xml';
	my $cpnSource = CpnSource->new($p);
	my $cpnSett   = CpnSettings->new();
	$cpnSett->{"sett"}->{"trackPadIsolation"} = 200;
	 

	my $variant = Helper->GetBestGroupCombination( $cpnSource, [ 1, 2, 3, 4, 7, 8,9], $cpnSett );
	
	die "variant is not found" unless($variant);
	
	print $variant;
	
	my $mess = "";
	my $builder = CpnBuilder->new($inCAM, $jobId, $cpnSource);
	if($builder->Build($variant, \$mess)){
		my $layout = $builder->GetLayout();
	
	
		my $generator = CpnGenerator->new($inCAM, $jobId);
		
		$inCAM->SetDisplay(0);
		
		$generator->Generate($layout);
		
		$inCAM->SetDisplay(1);
		 
	}
	
}

1;

