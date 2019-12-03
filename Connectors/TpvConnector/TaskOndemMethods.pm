#-------------------------------------------------------------------------------------------#
# Description: Connector to table task_ondemand, used bz service app : task on demand
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::TpvConnector::TaskOndemMethods;

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

sub GetAllTasks {
	my $self = shift;

	my @params = ();

	my $cmd = "SELECT DISTINCT 
						JobId,
						OrderId,
						TaskType,
						Inserted,
						LoginId,
						IF(OrderId is not null, 'order' , 'pcb') as OrderType 
				FROM task_ondemand;";

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

}

# Insert new request of task, for pcb
sub InsertTaskPcb {
	my $self     = shift;
	my $jobId    = shift;
	my $taskType = shift;
	my $loginId  = shift // "-";

	my @params1 = (
					SqlParameter->new( "_JobId",    Enums->SqlDbType_VARCHAR, $jobId ),
					SqlParameter->new( "_TaskType", Enums->SqlDbType_VARCHAR, $taskType ),
					SqlParameter->new( "_LoginId",  Enums->SqlDbType_VARCHAR, $loginId )
	);

	my $cmd1 = "SELECT
				COUNT(*) 
				FROM task_ondemand
				WHERE JobId = _JobId AND TaskType = _TaskType AND LoginId = _LoginId;";

	my $taskExist = Helper->ExecuteScalar( $cmd1, \@params1 );

	# Update record
	if ($taskExist) {

		# update ecord
		my @params2 = (
						SqlParameter->new( "_JobId",    Enums->SqlDbType_VARCHAR, $jobId ),
						SqlParameter->new( "_TaskType", Enums->SqlDbType_VARCHAR, $taskType ),
						SqlParameter->new( "_LoginId",  Enums->SqlDbType_VARCHAR, $loginId )
		);

		my $cmd2 = "UPDATE task_ondemand 
				SET
				Updated = now(),
				RequestOrder = RequestOrder +1
				WHERE JobId= _JobId AND TaskType = _TaskType AND LoginId = _LoginId;";

		my $result = Helper->ExecuteNonQuery( $cmd2, \@params2 );

	}
	else {

		my $cmd = "INSERT INTO task_ondemand (JobId, TaskType, LoginId) VALUES (_JobId, _TaskType, _LoginId);";
		Helper->ExecuteNonQuery( $cmd, \@params1 );

	}
}

# delete task for pcb
sub DeleteTaskPcb {
	my $self     = shift;
	my $jobId    = shift;
	my $taskType = shift;
	my $loginId  = shift // "-";

	my @params =
	  ( SqlParameter->new( "_JobId", Enums->SqlDbType_VARCHAR, $jobId ), 
	    SqlParameter->new( "_TaskType", Enums->SqlDbType_VARCHAR, $taskType ),
	    SqlParameter->new( "_LoginId",  Enums->SqlDbType_VARCHAR, $loginId ) );
	    
	my $cmd = "DELETE FROM  task_ondemand  WHERE JobId= _JobId AND TaskType = _TaskType AND LoginId = _LoginId;";

	my $taskExist = Helper->ExecuteNonQuery( $cmd, \@params );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::TpvConnector::TaskOndemMethods';

	#TaskOndemMethods->InsertTaskPcb( "d152457", TaskEnums->Data_CONTROL );

	my @l = TaskOndemMethods->GetAllTasks();

	die;

}

1;
