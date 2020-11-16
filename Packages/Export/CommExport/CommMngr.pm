
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::CommExport::CommMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use utf8;
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Encode qw(decode encode);
use POSIX qw(strftime);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::ItemResult::Enums' => 'ItemResEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Comments::Comments';
use aliased 'Programs::Comments::CommMail::Enums' => 'MailEnums';
use aliased 'Programs::Comments::CommMail::CommMail';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Managers::AbstractQueue::Task::TaskStatus::TaskStatus';

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
	$self->{"emailIntro"}        = shift;    #
	$self->{"includeOfferInf"}   = shift;    #
	$self->{"includeOfferStckp"} = shift;    #
	$self->{"clearComments"}     = shift;    # Clear commetns when mail is sent

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	

	#  1) Change status of orders
	if ( $self->{"changeOrderStatus"} ) {

		my @orders = HegMethods->GetPcbOrderNumbers($jobId);

		# 2 - predvzrovbni priprava
		# 1 - na prijmu
		@orders = map { $_->{"reference_subjektu"} } grep { $_->{"stav"} == 1 || $_->{"stav"} == 2 || $_->{"stav"} == 4 } @orders;
		my $resultStatus = $self->_GetNewItem("Change IS status");

		eval {

			foreach my $orderNum (@orders) {

				my $curStep = HegMethods->GetCurStepOfOrder($orderNum);

				if ( $curStep ne $self->{"orderStatus"} ) {

					my $succ = HegMethods->UpdatePcbOrderState( $orderNum, $self->{"orderStatus"}, 1 );
				}
			}

		};

		if ( my $e = $@ ) {

			$resultStatus->AddError( "Set state " . $self->{"orderStatus"} . " failed, try it again. Detail: " . $@ . "\n" );
		}

		$self->_OnItemResult($resultStatus);

	}

	#  2) Export email
	if ( $self->{"exportEmail"} ) {

		my $resultEmail = $self->_GetNewItem("Generate email");

		my $comm = Comments->new( $inCAM, $jobId );

		my %inf = %{ HegMethods->GetCustomerInfo($jobId) };
		my $lang = ( $inf{"zeme"} eq 25 || $inf{"zeme"} eq 79 ) ? "cz" : "en";

		my $mail = CommMail->new( $inCAM, $jobId, $comm->GetLayout(), $lang );

		my $emailExport = 1;
		if ( $self->{"emailAction"} eq MailEnums->EmailAction_OPEN ) {
			$emailExport = $mail->Open( $self->{"emailTo"}, $self->{"emailCC"}, $self->{"emailSubject"},
										$self->{"emailIntro"}, 1,
										$self->{"includeOfferInf"},
										$self->{"includeOfferStckp"} );

		}
		elsif ( $self->{"emailAction"} eq MailEnums->EmailAction_SEND ) {

			$emailExport = $mail->Sent( $self->{"emailTo"}, $self->{"emailCC"}, $self->{"emailSubject"},
										$self->{"emailIntro"}, 1,
										$self->{"includeOfferInf"},
										$self->{"includeOfferStckp"} );
		}

		# Store stamp with date to InCAM job note
		if ($emailExport) {

			my $note = CamAttributes->GetJobAttrByName( $inCAM, $jobId, ".comment" );

			$note .= " Approval email (" . ( strftime "%Y/%m/%d", localtime ) . ")";
			$inCAM->COM( "set_job_notes", "job" => $jobId, "notes" => $note );

		}
		else {
			$resultEmail->AddError("Error duriong generating email");
		}

		$self->_OnItemResult($resultEmail);

		# Clear comments if mail was exported properly

		if ( $self->{"clearComments"} && $emailExport ) {

			my $resultClear = $self->_GetNewItem("Clear comments");
			$comm->ClearCoomments();

			$self->_OnItemResult($resultClear);

		}

	}
}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1 if ( $self->{"changeOrderStatus"} );

	$totalCnt += 1 if ( $self->{"exportEmail"} );

	$totalCnt += 1 if ( $self->{"clearComments"} );

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

