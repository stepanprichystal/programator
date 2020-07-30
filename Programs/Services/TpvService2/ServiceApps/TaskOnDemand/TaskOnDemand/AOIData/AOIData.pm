#-------------------------------------------------------------------------------------------#
# Description: Prepare control/cooperation data
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::AOIData::AOIData;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Mail::Sender;
use List::Util qw(first);

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsApp';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::Enums';
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::MailTemplate::TemplateKey';
use aliased 'Packages::Other::HtmlTemplate::HtmlTemplate';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::AOI::AOIRepair::AOIRepair';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"taskDataApp"} = shift;
	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;

	# Sender attributes
	#$self->{"smtp"} = "127.0.0.1"; #testing server paper-cut

	$self->{"smtp"} = 'gatema-cz.mail.protection.outlook.com';    # new servr from 29.1.2019
	$self->{"from"} = 'tpvserver@gatema.cz';

	return $self;
}

# Export control data
sub Run {
	my $self     = shift;
	my $errorStr = shift;                                         # ref on error string, where error message is stored
	my $type     = shift;                                         # Data_AOI
	my $inserted = shift;                                         # time of inserting request
	my $loginId  = shift;                                         # login of user which requested control data

	my $result = 1;

	eval {

		$self->__Run( \$result, $errorStr, $type );

	};
	if ($@) {

		my $eStr = $@;
		$$errorStr .= "\n\n" . $eStr;
		$result = 0;

	}

	$self->SendMail( $result, $errorStr, $type, $inserted, $loginId );

	return $result;
}

# Export control data
sub __Run {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;    # ref on error string, where error message is stored
	my $type     = shift;    # Data_AOI
	$self->{"taskDataApp"}->{"logger"}->debug("HERE");

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Check if job is in production
	my @pcbInProduc = HegMethods->GetPcbsInProduc();    # get pcb "Ve vyrobe"
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	if ( !defined first { $_ =~ /$jobId/i } @pcbInProduc ) {

		$$errorStr = "Unable to export AOI data, job ($jobId) is not in production";
		$$result   = 0;
	}
	else {

		# Open job
		$self->{"taskDataApp"}->_OpenJob($jobId);
 
		# if check are ok, prepare data
		if ($$result) {

			my $AOIRepair = AOIRepair->new( $inCAM, $jobId );

			$AOIRepair->{"onItemResult"}->Add( sub { $self->ItemResultHandler( $result, $errorStr, @_ ) } );

			my $jobIdOut = $AOIRepair->GenerateJobName();
			my @lNames   = CamJob->GetSignalLayerNames( $inCAM, $jobId );
			my $OPFXPath = JobHelper->GetJobArchive($jobId) . "zdroje\\ot\\";

			$AOIRepair->CreateAOIRepairJob( $jobIdOut, \@lNames, $OPFXPath, 1, 0, 0, 0, 1 );

		}

	}

}

sub ItemResultHandler {
	my $self       = shift;
	my $result     = shift;
	my $errorStr   = shift;
	my $itemResult = shift;

	if ( $itemResult->GetErrorCount() > 0 ) {

		$$result = 0;
		$$errorStr .= $itemResult->GetErrorStr();

	}
}

sub SendMail {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;
	my $type     = shift;
	my $inserted = shift;
	my $loginId  = shift;

	$self->{"taskDataApp"}->{"logger"}->debug("send mail result $result, $$errorStr, $inserted, $loginId");

	my $jobId = $self->{"jobId"};

	# Get info about user
	my $userInfo = undef;

	if ( $loginId =~ /\d+/i ) {
		$userInfo = HegMethods->GetEmployyInfo( undef, $loginId );
	}

	# fill templkey with data
	my $templKey = TemplateKey->new();

	# compose message
	my $t = "";

	if ( $type eq Enums->Data_AOI ) {

		$t = "AOI repair data";
	}

	$templKey->SetAppName( EnumsApp->GetTitle( EnumsApp->App_TASKONDEMAND ) );
	$templKey->SetMessageType( $result    ? "SUCCESS" : "FAILED" );
	$templKey->SetMessageTypeClr( $result ? "#BFE89B" : "#FF8080" );
	$templKey->SetTaskType( $t . " (requested at $inserted)" );
	$templKey->SetJobId($jobId);

	my $author = "";
	my $nif    = NifFile->new( $self->{"jobId"} );
	if ( $nif->Exist() ) {
		$author = $nif->GetPcbAuthor();
	}
	$templKey->SetJobAuthor($author);

	my $str = "<br/>";

	if ($result) {
		my $url = JobHelper->GetJobArchive($jobId) . "Zdroje\\ot";
		$str .= "Archiv: <a " . "href=\"" . $url . "\" >" . $url . "</a>";
	}
	else {

		$str .= "Please contact TPV\n\n Error detail:\n" . $$errorStr;
	}

	$str =~ s/\n/<br>/g;

	$templKey->SetMessage($str);

	# Fill template with values

	my $htmlTempl = HtmlTemplate->new("en");

	my $oriTemplPath =
	  GeneralHelper->Root() . "\\Programs\\Services\\TpvService2\\ServiceApps\\TaskOnDemand\\TaskOnDemand\\MailTemplate\\template.html";

	if ( $htmlTempl->ProcessTemplate( $oriTemplPath, $templKey ) ) {

		# send email

		my $htmlFile    = $htmlTempl->GetOutFile();
		my $htmlFileStr = FileHelper->ReadAsString($htmlFile);
		unlink($htmlFile);

		my $sender = new Mail::Sender { smtp => $self->{"smtp"}, port => 25, from => $self->{"from"} };

		my @addres = ();

		if ( defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i ) {

			push( @addres, $userInfo->{"e_mail"} );
		}
		else {

			push( @addres, 'pcb@gatema.cz' );
		}

		$sender->Open(
			{
			   to      => \@addres,
			   subject => "Task on demand - " . $t . " ($jobId)",

			   #msg     => "I'm sending you the list you wanted.",
			   #file    => 'filename.txt'
			   ctype    => "text/html",
			   encoding => "7bit",

			   # bcc => ( !$result ? 'stepan.prichystal@gatema.cz' : undef )    #TODO temporary
			   bcc => ['stepan.prichystal@gatema.cz']    #TODO temporary
			}
		);

		$sender->SendEx($htmlFileStr);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::ControlData';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	# 1) # zkontroluje jestli jib existuje v InCAM, pokud ne odarchivuje a nahraje do InCAM
	#	# 2) # pokud se jedna o job ze stareho archivu, tak nahraje job do InCAMu z neho
	#
	#	my $jobId = "d152456";
	#	my $d = ControlData->new( $inCAM, $jobId );
	#
	#	my $errMess = "";
	#
	#	my $result = $d->Run( \$errMess, Enums->Data_COOPERATION );
	#
	#	print $result;

}

1;

