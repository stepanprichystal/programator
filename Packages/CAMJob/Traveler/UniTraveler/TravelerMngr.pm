
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::TravelerMngr;

#3th party library
use strict;
use warnings;
use List::Util qw(first min);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#require rows in nif section
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"pcbInfoIS"} = ( HegMethods->GetAllByPcbId( $self->{"jobId"} ) )[0];

	return $self;
}

sub GetOrderId {
	my $self = shift;

	my $orderName = $self->{"jobId"} . "-" . Enums->KEYORDERNUM;

	return $orderName;

}

sub GetPCBName {
	my $self = shift;

	return $self->{"pcbInfoIS"}->{"board_name"};

}

sub GetCustomerName {
	my $self = shift;

	return HegMethods->GetCustomerInfo( $self->{"jobId"} )->{"customer"};

}

sub GetPCBEmployeeInfo {
	my $self = shift;

	my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );

	my %employyInf = ();

	if ( defined $name && $name ne "" ) {

		%employyInf = %{ HegMethods->GetEmployyInfo($name) }

	}

	return %employyInf;
}

sub GetOrderTerm {
	my $self = shift;

	my $dateTerm = Enums->KEYORDERTERM;

	return $dateTerm;
}

sub GetOrderDate {
	my $self = shift;

	my $dateStart = Enums->KEYORDERDATE;

	return $dateStart;
}

sub GetPanelSize {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	return ( $w, $h );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

