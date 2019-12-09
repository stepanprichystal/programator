#-------------------------------------------------------------------------------------------#
# Description: Prepare control/cooperation data
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::ControlData;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Mail::Sender;

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
use aliased "Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit";
use aliased "Programs::Exporter::ExportChecker::Groups::OutExport::Presenter::OutUnit";
use aliased "Programs::Exporter::ExportUtility::Groups::OutExport::OutWorkUnit" => "UnitExport";
use aliased 'Helpers::FileHelper';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::Enums';
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::MailTemplate::TemplateKey';
use aliased 'Packages::Other::HtmlTemplate::HtmlTemplate';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Connectors::HeliosConnector::HegMethods';

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

	$self->{"smtp"} = 'gatema-cz.mail.protection.outlook.com'; # new servr from 29.1.2019
	$self->{"from"} = 'tpvserver@gatema.cz';

	return $self;
}

# Export control data
sub Run {
	my $self     = shift;
	my $errorStr = shift;    # ref on error string, where error message is stored
	my $type     = shift;    # Data_COOPERATION, Data_CONTROL
	my $inserted = shift;    # time of inserting request
	my $loginId  = shift;	 # login of user which requested control data

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
	my $type     = shift;    # Data_COOPERATION, Data_CONTROL
	$self->{"taskDataApp"}->{"logger"}->debug("HERE");

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Open job
	$self->{"taskDataApp"}->_OpenJob($jobId);

	$self->{"defaultInfo"} = DefaultInfo->new($jobId );
	$self->{"defaultInfo"}->Init($inCAM);

	# Check data - Group PRE (if we export some group,
	# always check PRE group too, because thera are important controls)

	$self->__CheckPREGroup( $result, $errorStr );
	my $unit = $self->__CheckOUTGroup( $result, $errorStr, $type );

	# if check are ok, prepare data
	if ($$result) {

		my $taskData    = $unit->GetExportData();
		my $exportClass = UnitExport->new( UnitEnums->UnitId_OUT );
		$exportClass->SetTaskData($taskData);

		$exportClass->Init( $inCAM, $jobId, $taskData );
		$exportClass->{"onItemResult"}->Add( sub { $self->ItemResultHandler( $result, $errorStr, @_ ) } );
		$exportClass->Run();

	}

	# Close job
	

}

sub __CheckPREGroup {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $resultMngr = ItemResultMngr->new();

	my $unit = PreUnit->new($jobId);
	$unit->SetDefaultInfo( $self->{"defaultInfo"} );
	$unit->InitDataMngr($inCAM);

	$unit->CheckBeforeExport( $inCAM, \$resultMngr );

	# ommit warnings, consider only errors

	unless ( $resultMngr->Succes(1) ) {

		$$errorStr .= $resultMngr->GetErrorsStr();
		$$result = 0;

	}
}

sub __CheckOUTGroup {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;
	my $type     = shift;    # Data_COOPERATION, Data_CONTROL

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $resultMngr = ItemResultMngr->new();

	my $unit = OutUnit->new($jobId);
	$unit->SetDefaultInfo( $self->{"defaultInfo"} );
	$unit->InitDataMngr($inCAM);

	# we want only control data, disable other "sub" groups
	my $groupData = $unit->{"dataMngr"}->GetGroupData();

	$groupData->SetExportCooper(0);
	$groupData->SetExportControl(0);

	if ( $type eq Enums->Data_COOPERATION ) {

		$groupData->SetExportCooper(1);
		$groupData->SetExportET(1);

	}
	elsif ( $type eq Enums->Data_CONTROL ) {

		$groupData->SetExportControl(1);
	}

	$unit->CheckBeforeExport( $inCAM, \$resultMngr );

	# ommit warnings, consider only errors

	unless ( $resultMngr->Succes(1) ) {

		$$errorStr .= $resultMngr->GetErrorsStr();
		$$result = 0;

	}

	return $unit;
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
	my $loginId = shift;
	
	

	$self->{"taskDataApp"}->{"logger"}->debug("send mail result $result, $errorStr, $inserted, $loginId");

	my $jobId = $self->{"jobId"};
	
	# Get info about user
	my $userInfo = HegMethods->GetEmployyInfo(undef, $loginId);
 
	# fill templkey with data
	my $templKey = TemplateKey->new();

	# compose message
	my $t = "";

	if ( $type eq Enums->Data_COOPERATION ) {

		$t = "Cooperation data";
	}
	elsif ( $type eq Enums->Data_CONTROL ) {

		$t = "Control data";
	}

	$templKey->SetAppName( EnumsApp->GetTitle( EnumsApp->App_TASKONDEMAND ) );
	$templKey->SetMessageType( $result    ? "SUCCESS"  : "FAILED" );
	$templKey->SetMessageTypeClr( $result ? "#BFE89B" : "#FF8080" );
	$templKey->SetTaskType( $t . " (requested at $inserted)" );
	$templKey->SetJobId($jobId);
	
	my $author = "";
	my $nif    = NifFile->new( $self->{"jobId"} );
	if ( $nif->Exist() ) {
		$author = $nif->GetPcbAuthor();
	}
	$templKey->SetJobAuthor( $author);

	my $str = "<br/>";

	if ($result) {
		my $url = JobHelper->GetJobArchive($jobId) . "Zdroje";
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
		
		if(defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i){
			
			push(@addres,$userInfo->{"e_mail"});
		}else{
			
			push(@addres,'pcb@gatema.cz');
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
			  bcc =>  ['stepan.prichystal@gatema.cz']   #TODO temporary
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

	use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::ControlData';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	# 1) # zkontroluje jestli jib existuje v InCAM, pokud ne odarchivuje a nahraje do InCAM
	# 2) # pokud se jedna o job ze stareho archivu, tak nahraje job do InCAMu z neho

	my $jobId = "d152456";
	my $d = ControlData->new( $inCAM, $jobId );

	my $errMess = "";

	my $result = $d->Run( \$errMess, Enums->Data_COOPERATION );

	print $result;

}

1;

