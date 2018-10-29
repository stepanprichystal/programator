
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::CreateFsch;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Routing::RoutLayer::FlattenRout::FlattenPanel::FlattenPanel';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"resultItem"} = ItemResult->new("Final result");
	
	return $self;

}

sub Create {
	my $self = shift;

	my @excludeSteps = grep { $_ ne EnumsGeneral->Coupon_IMPEDANCE }JobHelper->GetCouponStepNames();
	my $flatten = FlattenPanel->new( $self->{"inCAM"}, $self->{"jobId"}, "panel", "f", "fsch", 0,  \@excludeSteps  );

	$flatten->{"onItemResult"}->Add( sub { $self->__ProcesResult(@_) } );

	my $result = $flatten->Run();

	# process errors warnings

	my $messMngr = MessageMngr->new( $self->{"jobId"} );

	if ( $self->{"resultItem"}->GetErrorCount() ) {

		my @mess = $self->{"resultItem"}->GetErrors();
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );    #  Script se zastavi

	}

	if ( $self->{"resultItem"}->GetWarningCount() ) {

		my @mess = $self->{"resultItem"}->GetWarnings();
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );    #  Script se zastavi

	}

	return $result;
}

sub __ProcesResult {
	my $self = shift;
	my $res  = shift;

	foreach my $e ( $res->GetErrors() ) {

		$self->{"resultItem"}->AddError($e);

	}

	foreach my $w ( $res->GetWarnings() ) {

		$self->{"resultItem"}->AddWarning($w);

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d113608";
  

	my $fsch = CreateFsch->new( $inCAM, $jobId);
	print $fsch->Create();

}

1;

