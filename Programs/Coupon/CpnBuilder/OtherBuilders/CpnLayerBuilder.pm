
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::CpnLayerBuilder;

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];
use Array::IntSpan;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Programs::Coupon::Enums';
use aliased 'Programs::Coupon::Helper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::LayerLayout';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layout"} = {};
	# Layout of one single coupon
	$self->{"build"} = 0;    # indicator if layout was built

	# Settings references
	$self->{"cpnSett"} = undef;    # global settings for generating coupon
	
	# Other properties
 

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $cpnSett = shift;
	my $errMess = shift;
	$self->{"cpnSett"} = $cpnSett;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $stackup;

	if ( CamJob->GetSignalLayerCnt($inCAM, $jobId) > 2 ) {
		$stackup = Stackup->new($jobId);
	}

	my @layers = map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );    # silks, mask, signal

	foreach my $l (@layers) {

		my $lLayout = LayerLayout->new($l);

		# Set mirror

		if ( $l =~ /^[mp]?c$/ ) {
			$lLayout->SetMirror(0);

		}
		elsif ( $l =~ /^[mp]?s$/ ) {
			$lLayout->SetMirror(1);

		}
		elsif ( $l =~ /^v\d+$/ ) {

			my $side = StackupOperation->GetSideByLayer( $jobId, $l, $stackup );
			$lLayout->SetMirror( $side eq "top" ? 0 : 1 );
		}

		$self->{"layout"}->{$l} = $lLayout;

	}

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

