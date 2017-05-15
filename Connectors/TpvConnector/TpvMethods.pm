#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::TpvConnector::TpvMethods;

#STATIC class

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
#use lib qw(.. c:\Perl\site\lib\Programs\Test);
#use LoadLibrary;

use aliased 'Connectors::TpvConnector::Helper';
use aliased 'Connectors::SqlParameter';
use aliased 'Connectors::TpvConnector::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetCustomerInfo {
	my $self       = shift;
	my $customerId = shift;
	my $childPcbId = shift;

	my @params = ( SqlParameter->new( "_CustomerId", Enums->SqlDbType_VARCHAR, $customerId ) );

	# if some value is empty, we want return null, we say by this, customer has no request for this attribut

	my $cmd = "SELECT 

					IF(ExportPaste = '', null , ExportPaste) as ExportPaste,
					IF(ProfileToPaste = '', null , ProfileToPaste) as ProfileToPaste,
					IF(SingleProfileToPaste = '', null , SingleProfileToPaste) as SingleProfileToPaste,
					IF(FiducialsToPaste = '', null , FiducialsToPaste) as FiducialsToPaste,
					IF(NoTpvInfoPdf = '', null , NoTpvInfoPdf) as NoTpvInfoPdf,
					IF(ExportPdfControl = '', null , ExportPdfControl) as ExportPdfControl,
					IF(ExportDataControl = '', null , ExportDataControl) as ExportDataControl,
					IF(ScoreCoreThick = '', null , ScoreCoreThick) as ScoreCoreThick
					
    				FROM customer_note 
    				WHERE CustomerId = _CustomerId
    				LIMIT 1";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	if ( scalar(@result) ) {

		return $result[0];

	}
	else {
		return 0;
	}

	return @result;
}

# Return info about all automaticlz running application on TPV server
sub GetAppInfo {
	my $self = shift;

	my $cmd = "SELECT * FROM tpv_log.app_info;";

	my @params = ();

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

# Insert new app log
sub InsertAppLog {
	my $self    = shift;
	my $appId   = shift;
	my $type    = shift;
	my $message = shift;
	my $pcbId   = shift;

	my @params = (
				   SqlParameter->new( "_AppId",   Enums->SqlDbType_VARCHAR, $appId ),
				   SqlParameter->new( "_Type",    Enums->SqlDbType_VARCHAR, $type ),
				   SqlParameter->new( "_Message", Enums->SqlDbType_VARCHAR, $message ),
				   SqlParameter->new( "_PcbId",   Enums->SqlDbType_VARCHAR, $pcbId )
	);

	my $cmd = "INSERT INTO app_logs (AppId, Type, Message, PcbId) VALUES (_PcbId, _ChildPcbId, _ActionStep, _ActionCode, _ActionOrder, _User);";

	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}


# Get logs, which is suitable for processing (send mail to tpv users)
sub GetErrLogsToProcess {
	my $self  = shift;
	my $appId = shift;

	my @params = ( SqlParameter->new( "_AppId", Enums->SqlDbType_VARCHAR, $appId ) );

	my $cmd = "SELECT 
			t1.LogId,
    		t1.Type,
   			t1.Message,
   			t1.PcbId,
   		 	t3.LastSentDate,
   		 	t3.Receiver,
   		 	IF(t3.ReceiverMailCnt is null, 0 , t3.ReceiverMailCnt) as ReceiverSentCnt,
   		 	IF(t3.MailSentCnt is null, 0 , t3.MailSentCnt) as TotalSentCnt
		FROM
    		app_logs AS t1
       		 LEFT JOIN  app_info AS t2 ON t1.AppId = t2.AppId
       		 LEFT JOIN  app_logs_process AS t3 ON t1.LogId = t3.LogId
		WHERE
   		 	t2.AppId = _AppId
      		 AND (t1.Type = 'Error' OR t1.Type = 'Warning')
       		 AND t1.ProcessLog = 1
       		 AND (t3.MailSentCnt IS NULL OR t3.MailSentCnt < t2.SentErrMailRepeat)
       		 AND (t3.LastSentDate IS NULL OR (t3.LastSentDate + INTERVAL t2.SentErrMailInterval MINUTE) < NOW());";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

}

# Update record, which keep information how much mails was sent about log,
# and who is current receiver + increment count od sent mails
sub UpdateAppLogProcess {
	my $self     = shift;
	my $logId    = shift;
	my $receiver = shift;

	my @params1 = ( SqlParameter->new( "_LogId", Enums->SqlDbType_INT, $logId ) );

	my $cmd1 = "SELECT TOP 1
				Id 
				FROM app_logs_process
				WHERE app_logs_process.LogId = _LogId;";

	my $logProcId = Helper->ExecuteScalar( $cmd1, \@params1 );

	# Insert new record
	unless ($logProcId) {

		my @params  = ( SqlParameter->new( "_LogId", Enums->SqlDbType_INT, $logId ) );
		my $cmd     = "INSERT INTO app_logs_process (LogId) VALUES (_LogId);";
		my $result1 = Helper->ExecuteNonQuery( $cmd, \@params );

	}

	# update ecord
	my @params =
	  ( SqlParameter->new( "_Id", Enums->SqlDbType_INT, $logProcId ), SqlParameter->new( "_Receiver", Enums->SqlDbType_VARCHAR, $receiver ) );

	my $cmd = "UPDATE app_logs_process 
				SET
				MailSentCnt = MailSentCnt + 1, 
				ReceiverMailCnt = IF (_Receiver <>  Receiver,  1, ReceiverMailCnt +1),
				Receiver = _Receiver, 
				LastSentDate = now()
				WHERE Id= _Id;";

	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

}

# Insert default record for log processing
sub InsertAppLogProcess {
	my $self  = shift;
	my $logId = shift;

	my @params = ( SqlParameter->new( "_LogId", Enums->SqlDbType_INT, $logId ) );

	my $cmd = "INSERT INTO app_logs_process (LogId) VALUES (_LogId);";

	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::TpvConnector::TpvMethods';

	my $info = TpvMethods->GetCustomerInfo("05626");

	print 1;

}

1;

