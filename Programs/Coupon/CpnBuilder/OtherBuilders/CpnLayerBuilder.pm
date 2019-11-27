
#-------------------------------------------------------------------------------------------#
# Description: Builder create info for each coupon layer
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
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';

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

	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {
		$stackup = Stackup->new($inCAM, $jobId);
	}

	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );    # silks, mask, signal
	my @cncLayers = grep { $_->{"gROWname"} =~ /^([mf]|score)$/ } CamJob->GetNCLayers( $inCAM, $jobId );    # m

	push( @layers, @cncLayers ) if (scalar(@cncLayers));
 
	foreach my $l (@layers) {

		my $lName = $l->{"gROWname"};

		my $lLayout = LayerLayout->new($lName);

		# Set mirror
		if ( $lName =~ /^([mf]|score)$/ ) {
			# drill + rout layer
			$lLayout->SetMirror(0);
		}
		elsif ( $lName =~ /^[mp]?c$/ ) {
			$lLayout->SetMirror(0);

		}
		elsif ( $lName =~ /^[mp]?s$/ ) {
			$lLayout->SetMirror(1);

		}
		elsif ( $lName =~ /^v\d+$/ ) {

			my $side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $lName, $stackup );
			$lLayout->SetMirror( $side eq "top" ? 0 : 1 );
		}

		# Se layer polarity
		if ( $l->{"gROWpolarity"} eq "positive" ) {
			$lLayout->SetPolarity( DrawEnums->Polar_POSITIVE );
		}
		else {
			$lLayout->SetPolarity( DrawEnums->Polar_NEGATIVE );
		}

		# Set layer type
		$lLayout->SetType( $l->{"gROWlayer_type"} );


		$self->{"layout"}->{$lName} = $lLayout;
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

