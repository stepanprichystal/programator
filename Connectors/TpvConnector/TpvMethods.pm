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

	my @params = ( SqlParameter->new( "_CustomerId", Enums->SqlDbType_VARCHAR, $customerId ) );

	# if some value is empty, we want return null, we say by this, customer has no request for this attribut

	my $cmdPcb = "SELECT 

					IF(t1.ExportPaste = '', null , t1.ExportPaste) as ExportPaste,
					IF(t1.ProfileToPaste = '', null , t1.ProfileToPaste) as ProfileToPaste,
					IF(t1.SingleProfileToPaste = '', null , t1.SingleProfileToPaste) as SingleProfileToPaste,
					IF(t1.FiducialsToPaste = '', null , t1.FiducialsToPaste) as FiducialsToPaste,
					IF(t1.NoTpvInfoPdf = '', null , t1.NoTpvInfoPdf) as NoTpvInfoPdf,
					IF(t1.ExportPdfControl = '', null , t1.ExportPdfControl) as ExportPdfControl,
					IF(t1.ExportDataControl = '', null , t1.ExportDataControl) as ExportDataControl,
					IF(t1.ScoreCoreThick = '', null , t1.ScoreCoreThick) as ScoreCoreThick
	
    				FROM customer_note AS t1

    				WHERE t1.CustomerId = _CustomerId
    				LIMIT 1";

	my $cmdStencil = "SELECT 

					
					IF(t1.HoleDistX = '', null , t1.HoleDistX) as HoleDistX,
					IF(t1.HoleDistY = '', null , t1.HoleDistY) as HoleDistY,	
					IF(t1.OuterHoleDist = '', null , t1.OuterHoleDist) as OuterHoleDist,	
					IF(t1.CenterByData = '', null , t1.CenterByData) as CenterByData,				
					IF(t1.MinHoleDataDist = '', null , t1.MinHoleDataDist) as MinHoleDataDist,
					IF(t1.NoHalfHoles = '', null , t1.NoHalfHoles) as NoHalfHoles,
					IF(t1.NoFiducial = '', null , t1.NoFiducial) as NoFiducial
					
    				FROM customer_note_stencil AS t1
    				WHERE t1.CustomerId = _CustomerId
    				LIMIT 1";

	my @resultPcb     = Helper->ExecuteDataSet( $cmdPcb,     \@params );
	my @resultStencil = Helper->ExecuteDataSet( $cmdStencil, \@params );

	my %notes = ();

	if ( scalar(@resultPcb) ) {

		%notes = %{ $resultPcb[0] };
	}

	if ( scalar(@resultStencil) ) {

		%notes = ( %notes, %{ $resultStencil[0] } );
	}

	if (%notes) {
		return \%notes;
	}
	else {
		return 0;
	}

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

	# log will be processed by service,
	# only if same log message in DB are older then <$age> (defualt 120 minutes)
	my $age = shift;

	unless ( defined $age ) {
		$age = 120;
	}

	use Unicode::Normalize;

	$message = NFKD($message);
	$message =~ s/\p{NonspacingMark}//g;

	$message = quotemeta($message);    # escape all special characters

	my @params = (
				   SqlParameter->new( "_AppId",   Enums->SqlDbType_VARCHAR, $appId ),
				   SqlParameter->new( "_Type",    Enums->SqlDbType_VARCHAR, $type ),
				   SqlParameter->new( "_Message", Enums->SqlDbType_VARCHAR, $message ),
				   SqlParameter->new( "_PcbId",   Enums->SqlDbType_VARCHAR, $pcbId ),
				   SqlParameter->new( "_Minutes", Enums->SqlDbType_INT,     $age )
	);

	my $cmd = "INSERT 
 	INTO app_logs ( AppId,  Type,  Message,  PcbId,  ProcessLog) 
 	VALUES ( _AppId,  _Type,  _Message,  _PcbId,
		(SELECT if (
			(SELECT t2.Inserted 
			FROM(
				(SELECT t1.Inserted
				FROM app_logs AS t1
				WHERE t1.AppId = _AppId 
				AND t1.Type = _Type
				AND t1.PcbId = _PcbId
				AND t1.Message = _Message
				AND t1.ProcessLog = 1) 
				UNION 
				(SELECT NOW() - INTERVAL 1000 MINUTE as Inserted) # default time, when no same log message exist
				)
			AS t2
			ORDER BY t2.Inserted DESC
			LIMIT 1
			) + INTERVAL _Minutes MINUTE  < NOW(),
		1, # process log
		0  # not process, last same log is too young
		))
 	);";

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
        	 AND (t3.LastSentDate IS NULL OR (t3.LastSentDate + INTERVAL t2.SentErrMailInterval MINUTE) < NOW())
			 AND (t1.Inserted + INTERVAL 120 MINUTE) > NOW(); # process only logs younger than 1hour";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;

}

# Update record, which keep information how much mails was sent about log,
# and who is current receiver + increment count od sent mails
sub UpdateAppLogProcess {
	my $self     = shift;
	my $logId    = shift;
	my $receiver = shift;

	my @params1 = ( SqlParameter->new( "_LogId", Enums->SqlDbType_INT, $logId ) );

	my $cmd1 = "SELECT
				Id 
				FROM app_logs_process
				WHERE app_logs_process.LogId = _LogId;";

	my $logProcId = Helper->ExecuteScalar( $cmd1, \@params1 );

	# Insert new record
	unless ($logProcId) {

		my $cmd = "INSERT INTO app_logs_process (LogId) VALUES (_LogId);";
		Helper->ExecuteNonQuery( $cmd, \@params1 );

		my $cmd1 = "SELECT
				Id 
				FROM app_logs_process
				WHERE app_logs_process.LogId = _LogId;";

		$logProcId = Helper->ExecuteScalar( $cmd1, \@params1 );

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

# Remove app logs from table app_logs, older than 10 days
sub ClearLogDb {
	my $self    = shift;
	my $appId   = shift;
	my $type    = shift;
	my $message = shift;
	my $pcbId   = shift;

	my @params = ();

	my $cmd = "DELETE FROM  app_logs_process  WHERE LastSentDate < (now() - INTERVAL 10 DAY);";

	Helper->ExecuteNonQuery( $cmd, \@params );

	$cmd = "DELETE FROM  app_logs  WHERE Inserted < (now() - INTERVAL 10 DAY);";

	Helper->ExecuteNonQuery( $cmd, \@params );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::TpvConnector::TpvMethods';

	#	my $info = TpvMethods->InsertAppLog(
	#		"testApp", "Error", 'Ahoj j� jsem �t�p�n\n', "f52457"
	#	);

	my $inf = TpvMethods->GetCustomerInfo("07227");

	print 1;

}

1;

