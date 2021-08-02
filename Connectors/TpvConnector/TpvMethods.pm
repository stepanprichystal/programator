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
					IF(t1.ScoreCoreThick = '', null , t1.ScoreCoreThick) as ScoreCoreThick,
					IF(t1.RequiredSchemas = '', null , t1.RequiredSchemas) as RequiredSchemas,
					IF(t1.PlatedHolesType = '', null , t1.PlatedHolesType) as PlatedHolesType,
					IF(t1.MinCustPnlDim1 = '', null , t1.MinCustPnlDim1) as MinCustPnlDim1,
					IF(t1.MinCustPnlDim2 = '', null , t1.MinCustPnlDim2) as MinCustPnlDim2,
					IF(t1.MaxCustPnlDim1 = '', null , t1.MaxCustPnlDim1) as MaxCustPnlDim1,
					IF(t1.MaxCustPnlDim2 = '', null , t1.MaxCustPnlDim2) as MaxCustPnlDim2,
					IF(t1.InsertDataCode = '', null , t1.InsertDataCode) as InsertDataCode,
					IF(t1.InsertULLogo = '', null , t1.InsertULLogo) as InsertULLogo,
					IF(t1.GlobalEmailEQ = '', null , t1.GlobalEmailEQ) as GlobalEmailEQ,
					IF(t1.SmallNpth2Pth = '', null , t1.SmallNpth2Pth) as SmallNpth2Pth
	
    				FROM customer_note AS t1

    				WHERE t1.CustomerId = _CustomerId
    				LIMIT 1";

	my $cmdStencil = "SELECT 

					
					IF(t1.HoleDistX = '', null , t1.HoleDistX) as HoleDistX,
					IF(t1.HoleDistY = '', null , t1.HoleDistY) as HoleDistY,	
					IF(t1.OuterHoleDist = '', null , t1.OuterHoleDist) as OuterHoleDist,	
					IF(t1.CenterByData = '', null , t1.CenterByData) as CenterByData,				
					IF(t1.MinHoleDataDist = '', null , t1.MinHoleDataDist) as MinHoleDataDist,
					IF(t1.HalfHoles = '', null , t1.HalfHoles) as HalfHoles,
					IF(t1.NoFiducial = '', null , t1.NoFiducial) as NoFiducial,
					IF(t1.SizeX = '', null , t1.SizeX) as SizeX,
					IF(t1.SizeY = '', null , t1.SizeY) as SizeY
					
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
 
	use Unicode::Normalize;

	$message = NFKD($message);
	$message =~ s/\p{NonspacingMark}//g;
	
	$message = quotemeta($message); # escape all special characters

	my @params = (
				   SqlParameter->new( "_AppId",   Enums->SqlDbType_VARCHAR, $appId ),
				   SqlParameter->new( "_Type",    Enums->SqlDbType_VARCHAR, $type ),
				   SqlParameter->new( "_Message", Enums->SqlDbType_VARCHAR, $message ),
				   SqlParameter->new( "_PcbId",   Enums->SqlDbType_VARCHAR, $pcbId ) 
				  
	);

	my $cmd = 
	"INSERT 
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
				
				AND t1.ProcessLog = 1) 
				UNION 
				(SELECT NOW() - INTERVAL 1000 YEAR as Inserted) # default time, when no same log message exist
				)
			AS t2
			ORDER BY t2.Inserted DESC
			LIMIT 1
			) + INTERVAL (SELECT LogDuplicityInterval FROM app_info WHERE AppId = _AppId) MINUTE  < NOW(),
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

# Return log by id
sub GetLogById {
	my $self  = shift;
	my $logId = shift;

	my @params = ( SqlParameter->new( "_LogId", Enums->SqlDbType_VARCHAR, $logId ) );

	my $cmd = "SELECT * 
				FROM app_logs
				WHERE LogId = _LogId;";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return %{$result[0]};

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

# Insert new pcbId which is unable to archive
# Remove records older than 2 days
# Do not insert if alreadz inserted
sub InsertUnableToArchive{
	my $self    = shift;
	my $pcbId   = shift;
	
	
	# Clear  record older than 14 days
	my $cmd = "DELETE FROM  archivejobs_notArchived  WHERE Inserted < (now() - INTERVAL 2 DAY);";
	Helper->ExecuteNonQuery( $cmd, []);
	
	
	
	my @params1 = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd1 = "SELECT
				PcbId 
				FROM archivejobs_notArchived
				WHERE PcbId = _PcbId;";

	my $pcbIdExist = Helper->ExecuteScalar( $cmd1, \@params1 );
	
	unless($pcbIdExist){
 
		my $cmd2 = "INSERT INTO archivejobs_notArchived (PcbId) VALUES (_PcbId);";
		Helper->ExecuteNonQuery( $cmd2, \@params1 );
	}
	
	
}

# Return arary of jobs which are unable to archive
sub GetUnableToArchivedJobs{
	my $self    = shift;
	
	my @params = ();

	my $cmd = "SELECT 
			*
		FROM archivejobs_notArchived ";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return map { $_->{"PcbId"} } @result;
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::TpvConnector::TpvMethods';

	#my $info = TpvMethods->InsertAppLog(
#		"archiveJobs", "Error", 'Ahoj já\n jsem štěpán', "f52456"
#	);


	my @arr = TpvMethods->GetErrLogsToProcess("archiveJobs");
#
#	use Data::Dump qw(dump);
#
#	dump(@arr);

	 # TpvMethods->InsertUnableToArchive("d152457");

	#my @jobs = TpvMethods->GetUnableToArchivedJobs();
	 
	 
	 die;

}

1;

