#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);
use Log::Log4perl qw(get_logger :levels);
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
use aliased "Enums::EnumsPaths";

use MIME::Lite;
use File::Basename;
use Encode qw(decode encode);

my $smtp = "127.0.0.1";      #testing server paper-cut
my $from = "test\@test.cz";

 SendMail();

sub SendMail {
	my $loginId = "000328";

	my $jobId = "D123456";

	# Get info about user
	my $userInfo = HegMethods->GetEmployyInfo( undef, $loginId );

	# fill templkey with data
	my $templKey = TemplateKey->new();

	# compose message
	my $t = "";

	my $str = "<br/>";

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

		my @addres = ();

		if ( defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i ) {

			push( @addres, $userInfo->{"e_mail"} );
		}
		else {

			push( @addres, 'pcb@gatema.cz' );
		}

		my $msg = MIME::Lite->new(
			From => $from,
			To   => join( ", ", @addres ),

			#Cc   => join( ", ", @{$cc} ),

			Bcc => ['stepan.prichystal@gatema.cz'],    #TODO temporary,

			Subject => encode( "UTF-8", "Task on demand - " . $t . " ($jobId)" ),    # Encode must by use if subject with diacritics

			Type => 'multipart/related'
		);

		# Add your text message.
		$msg->attach( Type => 'text/html',
					  Data => encode( "UTF-8", $htmlFileStr ) );

		my $result = $msg->send( 'smtp', $smtp );

		if ( $result ne 1 ) {

			print STDERR $result;
			$result = 0;

		}
	}

}
