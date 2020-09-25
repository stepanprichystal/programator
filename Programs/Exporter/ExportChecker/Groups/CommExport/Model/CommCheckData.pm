
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'Managers::AsyncJobMngr::Enums'       => 'EnumsJobMngr';
use aliased 'Programs::Comments::CommMail::Enums' => 'MailEnums';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsIS';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;
	my $mode     = shift;    # EnumsJobMngr->TaskMode_SYNC /  EnumsJobMngr->TaskMode_ASYNC

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";
	my $isOffer  = JobHelper->GetJobIsOffer($jobId);

	my $defaultInfo = $dataMngr->GetDefaultInfo();
	my $groupData   = $dataMngr->GetGroupData();

	my $comments   = $defaultInfo->GetComments();
	my $commLayout = $comments->GetLayout();

	# X) Check if thera are comments, but export email is not checked
	if ( scalar( $commLayout->GetAllComments() ) && !$groupData->GetExportEmail() ) {

		$dataMngr->_AddWarningResult(
									  "Approval comments",
									  "V jobu byly nalezeny komentáře ("
										. scalar( $commLayout->GetAllComments() )
										. "), ale není zapnuto exportování \"Approval\" emailu. "
										. "Je to ok? "
										. "Aby se příště tato hláška nezobrazovala, smaž nebo archivuj komentáře (volba \"Clear all\")"
		);
	}

	# When offer, check if email export is acitve
	if ( $isOffer && !$groupData->GetExportEmail() ) {

		$dataMngr->_AddWarningResult( "No email export", "Export emailu není aktivní. je to ok?" );
	}

	# X) Check if export email is checkde and change status not
	if ( !$isOffer ) {
		if ( $groupData->GetExportEmail() && !$groupData->GetChangeOrderStatus() ) {

			$dataMngr->_AddWarningResult( "Change IS stauts not checked",
										  "Export \"Approval emailu\" je aktivní, ale změna statusu zakázky v IS ne, je to ok?" );
		}
	}

	# X) Unable to open email and export on background
	if ( $groupData->GetExportEmail() && $groupData->GetEmailAction() eq MailEnums->EmailAction_OPEN && $mode ne EnumsJobMngr->TaskMode_SYNC ) {

		$dataMngr->_AddErrorResult( "Export approval email - export na pozadí",
									"Nelze exportovat job na pozadí a zároveň otevřít email po exportu (\"Open in MS Outlook\")",
									"Zvol volbu \"Send directly\"" );

	}

	# X) Check if IS status match with email type
	if ( $groupData->GetExportEmail() && $groupData->GetChangeOrderStatus() ) {

		my $status  = $groupData->GetOrderStatus();
		my $subject = $groupData->GetEmailSubject();

		if ( $status eq EnumsIS->CurStep_HOTOVOODSOUHLASIT && $subject ne MailEnums->Subject_JOBFINIFHAPPROVAL ) {

			$dataMngr->_AddWarningResult(
										  "New IS status and email subject not match",
										  "Pokud je požadavek na nový stav v IS: \"HOTOVO-odsouhlasit\", předmět emailu by měl být: \""
											. MailEnums->Subject_JOBFINIFHAPPROVAL . "\""
			);
		}

		if ( $status eq EnumsIS->CurStep_POSLANDOTAZ && $subject ne MailEnums->Subject_JOBPROCESSAPPROVAL ) {

			$dataMngr->_AddWarningResult(
										  "New IS status and email subject not match",
										  "Pokud je požadavek na nový stav v IS: \"poslan dotaz <user>\", předmět emailu by měl být: \""
											. MailEnums->Subject_JOBPROCESSAPPROVAL . "\""
			);
		}

	}

	# Get all emails
	my @emailsTo = ();
	if ( defined $groupData->GetEmailToAddress() ) {
		push( @emailsTo, @{ $groupData->GetEmailToAddress() } );
	}
	
	my @emailsCC = ();
	if ( defined $groupData->GetEmailCCAddress() ) {
		push( @emailsCC, @{ $groupData->GetEmailCCAddress() } );
	}

	# 1) Check if email exist
	if ( $groupData->GetExportEmail() && scalar(@emailsTo) == 0 ) {
		$dataMngr->_AddErrorResult( "Export approval email - chybí adresa", "Není zadána žádná emailová adresa." );
	}

	# 2) Check email validity
	if ( $groupData->GetExportEmail() ) {

		foreach my $m (@emailsTo, @emailsCC) {

			if ( $m !~ /^.+\@.+\..+$/i ) {
				$dataMngr->_AddErrorResult( "Export approval email - špatný formát", "Špatný formát emailu: $m" );
			}
		}
	}

	# 3) Unable to sent email directly to not internal mail (mail which not contain gatema.cz)
	if ( $groupData->GetExportEmail() ) {

		if ( $groupData->GetEmailAction() eq MailEnums->EmailAction_SEND ) {
			foreach my $m (@emailsTo, @emailsCC) {

				if ( $m !~ /\@gatema/ ) {
					$dataMngr->_AddErrorResult(
							  "Export approval email - sent directly",
							  "Nelze odeslat email na adresu: $m na přímo (\"Send directly\") pokud email obsahuje venkovní adresu mimo gatemu."
								. " Je to z bezpečnostních důvodů, aby se email zákazníkovi neodesílal neůmyslně vícekrát při každém exportu"
					);
				}
			}
		}
	}
	

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = " F13608 ";
	#	my $stepName = " panel ";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

