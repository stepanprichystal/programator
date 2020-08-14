
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::CommExport::CommMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 0;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"changeOrderStatus"} = shift;    # Chenge order status when approvel mail
	$self->{"orderStatus"}       = shift;    #
	$self->{"exportEmail"}       = shift;    # Export approval mail
	$self->{"emailAction"}       = shift;    #
	$self->{"emailTo"}           = shift;    #
	$self->{"emailCC"}           = shift;    #
	$self->{"emailSubject"}      = shift;    #
	$self->{"clearComments"}     = shift;    # Clear commetns when mail is sent

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#  Change status of orders
	if ( $self->{"changeOrderStatus"} ) {

		my @orders = HegMethods->GetPcbOrderNumbers($jobId);
		@orders = map { $_->{"reference_subjektu"} } grep { $_->{"aktualni_krok"} == 2 } @orders;
		my $resultStack = $self->_GetNewItem("Change order status");

		eval {
 
			foreach my $orderNum ( @orders ) {

				my $curStep = HegMethods->GetCurStepOfOrder($orderNum);

				#my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
				#my $orderNum = $self->{"jobId"} . "-" . $orderRef;

				if ( $curStep ne EnumsIS->CurStep_HOTOVOZADAT ) {

					my $succ = HegMethods->UpdatePcbOrderState( $orderNum, EnumsIS->CurStep_HOTOVOZADAT );
				}
			}

			# remove auto process log
			if ( AsyncJobHelber->ServerVersion() ) {
				AutoProcLog->Delete( $self->GetJobId() );
			}

			$self->{"taskStatus"}->DeleteStatusFile();
			$self->{"sentToProduce"} = 1;
		};

		if ( my $e = $@ ) {

			# set status hotovo-yadat fail
			my $toProduceMngr = $self->{"produceResultMngr"};
			my $item = $toProduceMngr->GetNewItem( "Set state HOTOVO-zadat", EnumsGeneral->ResultType_FAIL );

			$item->AddError( "Set state HOTOVO-zadat failed, try it again. Detail: " . $@ . "\n" );
			$toProduceMngr->AddItem($item);

			$result = 0;

		}

		$self->_OnItemResult($resultStack);

	}

	#  Export email
	if ( $self->{"exportEmail"} ) {

		my $resultStack = $self->_GetNewItem("Email with commetns");

		$self->_OnItemResult($resultStack);
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1 if ( $self->{"changeOrderStatus"} );

	$totalCnt += 1 if ( $self->{"exportEmail"} );

	return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::ETExport::ETMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "d229010";
	#
	#	my $et = ETMngr->new( $inCAM, $jobId, "panel", 1 );
	#
	#	$et->Run()

}

1;

