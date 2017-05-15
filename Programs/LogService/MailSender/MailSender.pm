#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::LogService::MailSender::MailSender;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Programs::LogService::MailSender::AppStopCond::TestStopCond';
use aliased 'Packages::NifFile::NifFile';

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
	
	# Each app define "stop sending mail" condition
	# Objects are stored in hasha and contain method StopSend
	
	my %stopSend = ();
	$stopSend{EnumsApp->App_TEST} = TestStopCond->new();
	
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
	my $appId 		= shift;
	my $maxRepeat    = shift;
	my $maxUsrRepeat = shift;
	my $interval     = shift;

	# check if log has been processed, if not insert default process record

	my @logs = TpvMethods->GetErrLogsToProcess();
	
	foreach my $log (@logs){
		
		my $stopSending = 0;
		
		# 1) decide if stop log sending emails
		
		# a) stop sending if max email cnt was exceed
		if(($log->{"TotalSentCnt"} + 1) > $maxRepeat){
			
			$stopSending = 0;
		}
		
		# b) stop sending if is fullfil condition defined by app
		unless($self->{"stopSend"}->{$appId}->ProcessLog($log->{"PcbId"})){
			
			$stopSending = 0;
		}
		
		next if($stopSending);
		
		# 2) get receiver
		my $receiver = undef;
		if(!defined $log->{"Receiver"} || $log->{"Receiver"} eq ""){
			
			$receiver = $self->__GetDefaultReceiver($log->{"PcbId"});
			
		}else{
			
			$receiver = $self->__GetNextReceiver($log->{"Receiver"}, $log->{"ReceiverSentCnt"}, $maxRepeat);	 
		}
		
		# 3) Update info about mail sendiong for this log
		TpvMethods->UpdateAppLogProcess($log->{"LogId"}, $receiver);
		
		# 4) Sent mail with log message to receiver
		
	}

}

sub __GetDefaultReceiver {
	my $self      = shift;
	my $pcbId 	= shift;
	
	my $logAuthor = undef;
	
	# 1) Get name from nif
	my $nif = NifFile->new( $pcbId );
	if($nif->Exist()){
		$logAuthor = $nif->GetValue("zpracoval");
	}
 
	# 2) Check if name still work in GATEMA TPV :-)
	my $empl = ( grep { $_->{"login_id"} eq $logAuthor } @{ $self->{"employees"} } )[0];

	unless ( defined $empl ) {
		$empl = $self->{"employees"}->[0];
	}

	return $empl->{"login_id"};

}

sub __GetNextReceiver {
	my $self              = shift;
	my $currReceiver      = shift;
	my $receiverRepeat    = shift;
	my $maxReceiverRepeat = shift;

	my $nextReceiver = $currReceiver;

	# get next receiver
	if ( $receiverRepeat < $maxReceiverRepeat ) {

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

	return $nextReceiver;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::LogService::MailSender::MailSender';

	#	use aliased 'Packages::InCAM::InCAM';
	#

	my $sender = MailSender->new();

	print "ee";
}

1;

