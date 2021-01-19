
#-------------------------------------------------------------------------------------------#
# Description: Create flatten rout layer
# Class contain error events, which can occure during layer creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::CreateFsch;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Routing::RoutLayer::FlattenRout::FlattenPanel::FlattenPanel';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Routing::RoutOutline';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;

}

# Return 1 if succes, 0 if fail
# Error details can by handled by  "onItemResult" event in base class
sub Create {
	my $self = shift;

	my @excludeSteps = grep { $_ ne EnumsGeneral->Coupon_IMPEDANCE } JobHelper->GetCouponStepNames();
	my $flatten = FlattenPanel->new( $self->{"inCAM"}, $self->{"jobId"}, "panel", \@excludeSteps );

	$flatten->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	# Flatten algorithm settings
	my $srcLayer        = "f";
	my $dstLayer        = "fsch";
	my $notDrawSucc     = 0;
	my $outlRoutStart   = RoutOutline->GetDefRoutStart( $self->{"jobId"} );
	my $outlPnlSequence = $self->__GetDefRoutSequence($outlRoutStart);

	my $result = $flatten->Run( $srcLayer, $dstLayer, $notDrawSucc, $outlRoutStart, $outlPnlSequence );

	return $result;
}

# Return default rout sequence based on PCB rout start sorner
# (But it can be based on CNC machine, PCB type and anything)
sub __GetDefRoutSequence {
	my $self          = shift;
	my $outlRoutStart = shift;    # PCB outline rout start corner

	my $outlPnlSequence = undef;  # Panel routing sequence direction

	if ( $outlRoutStart eq EnumsRout->OutlineStart_LEFTTOP ) {

		$outlPnlSequence = EnumsRout->SEQUENCE_BTRL;

	}
	elsif ( $outlRoutStart eq EnumsRout->OutlineStart_RIGHTTOP ) {

		$outlPnlSequence = EnumsRout->SEQUENCE_BTLR;

	}
	else {
		die "Panel rout sequence is not recognized";
	}

	return $outlPnlSequence;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d304098";

	my $fsch = CreateFsch->new( $inCAM, $jobId );
	print $fsch->Create();

}

1;

