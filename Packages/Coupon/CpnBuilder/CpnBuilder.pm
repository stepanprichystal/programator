
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

	# built complete coupon layout

	foreach my $groupInf ( $buildParams->GetGroups() ) {

		# Built single coupon layout

		# filter constraints by current group
		my %tmp;
		@tmp{ @{ $groupInf->{"constrainsId"} } } = ();
		my @constraints = grep { exists $tmp{ $_->GetConstrainId() } } $self->{"cpnSource"}->GetConstraints();

		my $coupon = CpnSingleBuilder->new( $inCAM, $jobId, $self->{"settings"}, \@constraints );

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
		$self->{"layout"}->SetWidth( $self->{"settings"}->GetWidth() );

		# height depand on microstrip types
		my $h = $self->{"settings"}->GetCouponMargin() * 2 + ( scalar( @{ $self->{"couponsSingle"} } ) - 1 ) * $self->{"settings"}->GetCouponSpace();
		$h += $_->GetHeight() foreach @{ $self->{"couponsSingle"} };
		$self->{"layout"}->SetHeight($h);

		$self->{"build"} = 1;                # build is ok
	}

	return $result;

}

sub GetLayout {
	my $self = shift;

	die "Coupon is not builded" unless ( $self->{"build"} );

	return $self->{"layout"};

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

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $p         = 'c:\tmp\inplan\write\output\Diff_Coated_Microstrip\Diff_Coated_Microstrip.xml';
	my $cpnSource = CpnSource->new($p);
	my $sett      = CpnSettings->new();

	my $builder = CpnBuilder->new( $inCAM, $jobId, $cpnSource, $sett );

	my $buildParams = BuildParams->new( scalar( $cpnSource->GetConstraints() ) );

	my $errMess = "";
	my $res = $builder->Build( \$errMess, $buildParams );

	print STDERR "Build: $res\n";

	my $generator = CpnGenerator->new( $inCAM, $jobId, $sett);

	$generator->Generate( $builder->GetLayout() );

}

1;

