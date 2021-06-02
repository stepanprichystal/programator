#-------------------------------------------------------------------------------------------#
# Description: Prepare control/cooperation data
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::AOIData::AOIData;
use base("Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::TaskOnDemandBase");

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Mail::Sender;
use List::Util qw(first);
use File::Basename;
use MIME::Lite;
use Encode qw(decode encode);

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

	my $appName = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $self    = $class->SUPER::new( $appName, $inCAM, $jobId );

	#my $self = {};
	bless $self;

	# Sender attributes
	#$self->{"smtp"} = "127.0.0.1"; #testing server paper-cut

	$self->{"smtp"} = EnumsPaths->URL_GATEMASMTP;
	$self->{"from"} = 'tpvserver@gatema.cz';

	return $self;
}

# Export control data
sub Run {
	my $self     = shift;
	my $errorStr = shift;    # ref on error string, where error message is stored
	my $type     = shift;    # Data_AOI
	my $inserted = shift;    # time of inserting request
	my $loginId  = shift;    # login of user which requested control data

	my $result = 1;

	eval {

		$self->__Run( \$result, $errorStr, $type );

	};
	if ($@) {

		my $eStr = $@;
		$$errorStr .= "\n\n" . $eStr;
		$result = 0;

	}

	unless ( $self->__SendMail( $result, $errorStr, $type, $inserted, $loginId ) ) {
		$result = 0;
	}

	return $result;
}

# Export control data
sub __Run {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;    # ref on error string, where error message is stored
	my $type     = shift;    # Data_AOI

	$self->{"logger"}->debug("HERE");

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
		$self->_OpenJob();

		# if check are ok, prepare data
		if ($$result) {

			my $AOIRepair = AOIRepair->new( $inCAM, $jobId );

			$AOIRepair->{"onItemResult"}->Add( sub { $self->ItemResultHandler( $result, $errorStr, @_ ) } );

			my $jobIdOut = $AOIRepair->GenerateJobName();
			my @lNames   = CamJob->GetSignalLayerNames( $inCAM, $jobId );
			my $OPFXPath = JobHelper->GetJobArchive($jobId) . "zdroje\\ot\\";

			my $send2server   = 1;
			my $keepFormerJob = 1;
			my $reduceSteps   = 0;
			my $contour       = 0;
			my $resize        = 2;
			my $delAttr       = 0;

			# Export onlz layer which not in aoi dir
			if ($keepFormerJob) {

				if ( -e EnumsPaths->Jobs_AOITESTSFUSIONDB . $self->{"jobId"} ) {
					my @dirs = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_AOITESTSFUSIONDB . $self->{"jobId"} );

					foreach my $dirPath (@dirs) {

						my ( $name, $path, $suffix ) = fileparse($dirPath);
						@lNames = grep { $_ ne $name } @lNames;
					}

					# If all are processed, offer all layers
					@lNames = CamJob->GetSignalLayerNames( $inCAM, $jobId ) unless ( scalar(@lNames) );
				}

			}

			$AOIRepair->CreateAOIRepairJob( $jobIdOut, \@lNames, $OPFXPath, $send2server, $keepFormerJob, $reduceSteps, $contour, $resize, $delAttr );
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

sub __SendMail {
	my $self     = shift;
	my $result   = shift;
	my $errorStr = shift;
	my $type     = shift;
	my $inserted = shift;
	my $loginId  = shift;

	my $resultMail = 1;

	$self->{"logger"}->debug("send mail result $result, $errorStr, $inserted, $loginId");

	my $jobId = $self->{"jobId"};

	# Get info about user
	my $userInfo = undef;
	if ( defined $loginId && $loginId !~ /temp/i ) {

		$userInfo = HegMethods->GetEmployyInfo( undef, $loginId );
	}

	my @addres   = ();
	my @addresCC = ();

	if ( defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i ) {

		push( @addres, $userInfo->{"e_mail"} );
	}

	# fill templkey with data
	my $templKey = TemplateKey->new();

	# compose message
	my $t = "AOI Repair";

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
		my $url = JobHelper->GetJobArchive($jobId) . "Zdroje";
		$str .= "Archiv: <a " . "href=\"" . $url . "\" >" . $url . "</a>";
	}
	else {

		$str .= "Please contact TPV\n\n Error detail:\n" . $$errorStr;
		push( @addresCC, EnumsPaths->MAIL_GATTPV );
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

		# Temporary if no adress, add SPR
		push( @addres, 'stepan.prichystal@gatema.cz' ) unless ( scalar(@addres) );

		my $msg = MIME::Lite->new(
			From => $self->{"from"},
			To   => join( ", ", @addres ),

			Cc => join( ", ", @addresCC ),

			#Bcc => ['stepan.prichystal@gatema.cz'],    #TODO temporary,

			Subject => encode( "UTF-8", "Task on demand - " . $t . " ($jobId)" ),     # Encode must by use if subject with diacritics

			Type => 'multipart/related'
		);

		# Add your text message.
		$msg->attach( Type => 'text/html',
					  Data => encode( "UTF-8", $htmlFileStr ) );

		my $resSend = $msg->send( 'smtp', $self->{"smtp"} );

		if ( $resSend ne 1 ) {

			$resultMail = 0;
		}
	}

	return $resultMail;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::AOIData::AOIData';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d322016";

	my $d = AOIData->new( EnumsApp->App_TASKONDEMAND, $inCAM, $jobId );

	my $errMess = "";

	my $result = $d->Run( \$errMess, Enums->Data_AOI );

	print $result;

}

1;

