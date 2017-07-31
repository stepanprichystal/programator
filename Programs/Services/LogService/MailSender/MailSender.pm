#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::LogService::MailSender::MailSender;

#3th party library
use strict;
use warnings;
use Mail::Sender;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Programs::Services::LogService::MailSender::AppStopCond::TestStopCond';
use aliased 'Programs::Services::LogService::MailSender::AppStopCond::ReOrderStopCond';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# Get all app info
	my @appInf = TpvMethods->GetAppInfo();
	$self->{"appsInfo"} = \@appInf;

	# Get TPV employe
	my @empl = HegMethods->GetTPVEmployee();
	$self->{"employees"} = \@empl;

	# Sender attributes
	#$self->{"smtp"} = "127.0.0.1";
	$self->{"smtp"} = 'proxy.gatema.cz';
	$self->{"from"} = 'tpvserver@gatema.cz';

	# Each app define "stop sending mail" condition
	# Objects are stored in hasha and contain method StopSend

	my %stopSend = ();
	$stopSend{ EnumsApp->App_TEST }         = TestStopCond->new();
	$stopSend{ EnumsApp->App_CHECKREORDER } = ReOrderStopCond->new();

	$self->{"stopSend"} = \%stopSend;

	return $self;
}

sub Run {
	my $self = shift;

	# Filter app which want to sent err mail
	my @app2Proces = grep { $_->{"SentErrMail"} } @{ $self->{"appsInfo"} };

	foreach my $app (@app2Proces) {

		$self->__ProcesAppLogs( $app->{"AppId"}, $app->{"SentErrMailRepeat"}, $app->{"SentErrMailUserRepeat"}, $app->{"SentErrMailInterval"} )

	}

}

sub __ProcesAppLogs {
	my $self         = shift;
	my $appId        = shift;
	my $maxRepeat    = shift;
	my $maxUsrRepeat = shift;
	my $interval     = shift;

	# check if log has been processed, if not insert default process record

	my @logs = TpvMethods->GetErrLogsToProcess($appId);

	foreach my $log (@logs) {

		my $stopSending = 0;

		# 1) decide if stop log sending emails

		# a) stop sending if max email cnt was exceed
		if ( ( $log->{"TotalSentCnt"} + 1 ) > $maxRepeat ) {

			$stopSending = 0;
		}

		# b) stop sending if is fullfil condition defined by app
		if ( defined $self->{"stopSend"}->{$appId} && !$self->{"stopSend"}->{$appId}->ProcessLog( $log->{"PcbId"} ) ) {

			$stopSending = 0;
		}

		next if ($stopSending);

		# 2) get receiver

		my $receiver        = undef;
		my $receiverSentCnt = $log->{"ReceiverSentCnt"};    # number of mails which was sent to receiver

		if ( !defined $log->{"Receiver"} || $log->{"Receiver"} eq "" ) {

			$receiver = $self->__GetDefaultReceiver( $log->{"PcbId"} );
		}
		else {

			$receiver = $self->__GetNextReceiver( $log->{"Receiver"}, $log->{"ReceiverSentCnt"}, $maxUsrRepeat );

			# if receiver changed, reset mail
			if ( $log->{"Receiver"} ne $receiver->{"login_id"} ) {
				$receiverSentCnt = 0;
			}
		}

		# 3) Update info about mail sendiong for this log
		TpvMethods->UpdateAppLogProcess( $log->{"LogId"}, $receiver->{"login_id"} );

		# set pcb id
		my $pcbId = $log->{"PcbId"};
		if ( !defined $pcbId || $pcbId eq "" ) {
			$pcbId = "-";
		}

		# set author of pcb if exist
		my $pcbAuthor = "-";
		if ( $pcbId ne "-" ) {
			my $nif = NifFile->new($pcbId);
			if ( $nif->Exist() ) {
				$pcbAuthor = $nif->GetValue("zpracoval");
			}
		}

		# 4) Sent mail with log message to receiver
		$self->__SendMail(
						   $receiver->{"e_mail"}, $appId,               $log->{"TotalSentCnt"} + 1, $maxRepeat,
						   $log->{"Type"},        $receiverSentCnt + 1, $pcbId,                     $pcbAuthor,
						   $log->{"Message"}
		);
	}
}

sub __GetDefaultReceiver {
	my $self  = shift;
	my $pcbId = shift;

	my $empl = undef;

	if ( defined $pcbId ) {

		my $logAuthor = undef;

		# 1) Get name from nif
		my $nif = NifFile->new($pcbId);
		if ( $nif->Exist() ) {
			$logAuthor = $nif->GetValue("zpracoval");
		}

		# 2) Check if name still work in GATEMA TPV :-)
		$empl = ( grep { $_->{"login_id"} eq $logAuthor } @{ $self->{"employees"} } )[0];
	}

	unless ( defined $empl ) {
		$empl = $self->{"employees"}->[0];
	}

	return $empl;

}

sub __GetNextReceiver {
	my $self              = shift;
	my $currReceiver      = shift;
	my $receiverRepeat    = shift;
	my $maxReceiverRepeat = shift;

	my $nextReceiver = undef;

	# get next receiver
	if ( $receiverRepeat >= $maxReceiverRepeat ) {

		for ( my $i = 0 ; $i < scalar( @{ $self->{"employees"} } ) ; $i++ ) {

			if ( $self->{"employees"}->[$i]->{"login_id"} eq $currReceiver ) {

				# choose next receiver in order
				if ( $i + 1 == scalar( @{ $self->{"employees"} } ) ) {

					$nextReceiver = $self->{"employees"}->[0];
				}
				else {
					$nextReceiver = $self->{"employees"}->[ $i + 1 ];
				}
			}
		}

	}
	else {

		$nextReceiver = ( grep { $_->{"login_id"} eq $currReceiver } @{ $self->{"employees"} } )[0];
	}

	return $nextReceiver;
}

sub __SendMail {
	my $self              = shift;
	my $mail              = shift;    #receiver
	my $appName           = shift;
	my $appTotalSentMails = shift;
	my $appMaxSentMails   = shift;
	my $errType           = shift;
	my $warnCnt           = shift;
	my $pcbId             = shift;
	my $pcbAuthor         = shift;
	my $message           = shift;

	# prepare email html template
	my %keysData = ();

	$keysData{"key__appName"} = "App: " . EnumsApp->GetTitle($appName);

	if ( $errType eq "Error" ) {
		$keysData{"key__logTypeClr"} = "#FF8080";
	}
	else {
		$keysData{"key__logTypeClr"} = "#FFFFA8";
	}

	$keysData{"key__logType"}    = $errType;
	$keysData{"key__warningCnt"} = $warnCnt . " (total  $appTotalSentMails/$appMaxSentMails)";
	$keysData{"key__pcbId"}      = $pcbId;
	$keysData{"key__pcbAuthor"}  = $pcbAuthor;
	$keysData{"key__message"}    = $message;

	my $htmlfile = GeneralHelper->Root() . "\\Programs\\Services\\LogService\\MailSender\\template.txt";

	unless ( -e $htmlfile ) {
		die "Html template for email doesn't exist";
	}

	my $template = FileHelper->ReadAsString($htmlfile);

	foreach my $k ( keys %keysData ) {

		my $val = $keysData{$k};
		$template =~ s/$k/$val/gi;    # means replace all keys which are between characters ><, "" or \
	}

	my $sender = new Mail::Sender { smtp => $self->{"smtp"}, port => 25, from => $self->{"from"} };

	$sender->Open(
		{
		   to      => $mail,
		   subject => "Server logs - " . EnumsApp->GetTitle($appName) . " (warning  $appTotalSentMails/$appMaxSentMails)",

		   #msg     => "I'm sending you the list you wanted.",
		   #file    => 'filename.txt'
		   ctype    => "text/html",
		   encoding => "7bit",
		   bcc      => 'stepan.prichystal@gatema.cz' #TODO temporary 
		}
	);

	$sender->SendEx($template);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Services::LogService::MailSender::MailSender';

	#	use aliased 'Packages::InCAM::InCAM';
	#

	my $sender = MailSender->new();

	$sender->Run();

	print "ee";
}

1;

