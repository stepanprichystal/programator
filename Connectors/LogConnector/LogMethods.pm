

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::LogConnector::LogMethods;
#STATIC class

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
#use lib qw(.. c:\Perl\site\lib\Programs\Test);
#use LoadLibrary;

use aliased 'Connectors::LogConnector::Helper';
use aliased 'Connectors::SqlParameter';
use aliased 'Connectors::LogConnector::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetLatestActionsByPcbId {
	my $self  = shift;
	my $pcbId = shift;
	my $childPcbId = shift;
	
	my $cmd    = "SELECT t1.PcbId, t1.User, t1.ActionStep, t1.ActionCode, t1.ActionOrder, DATE_FORMAT( max(t1.Inserted),'%d-%m-%Y %H:%i') as Inserted
    				FROM log_action as t1
    				WHERE t1.PcbId = _PcbId AND t1.ChildPcbId =  _ChildPcbId
    				GROUP BY ActionStep, ActionCode, ActionOrder;";
		
	my @params = (SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ), 
				SqlParameter->new( "_ChildPcbId", Enums->SqlDbType_INT, $childPcbId ));
	

	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}

sub GetActionAndMessages {
	my $self  = shift;
	my $limit = shift;
	my $from = shift;
	my $pcbId = shift;
	my $childPcbId = shift,
	my $userName = shift;
	my $typeAction = shift; #bool
	
	my $typeMessageTemp = shift; #array of types
	my @typeMessage = ();
	
	if(defined $typeMessageTemp && scalar(@{$typeMessageTemp}) > 0){
		@typeMessage = @{$typeMessageTemp};
	}
	
	#my $typeMess = scalar(@typeMessage) > 0 ? 1:0; #bool
	
	   

	my $cmd    = 
			"SELECT tabouter.PcbId, tabouter.ChildPcbId, tabouter.Type, tabouter.ActionStep, tabouter.ActionCode, tabouter.ActionOrder, tabouter.MessageCode, tabouter.MessageType,  tabouter.Result AS MessageResult, DATE_FORMAT(tabouter.Inserted,'%d-%m-%Y %H:%i') AS Inserted, tabouter.User FROM
			(
				(SELECT * FROM
					(SELECT  tab.PcbId, tab.ChildPcbId, 'Action' AS Type, tab.ActionStep, tab.ActionOrder, tab.ActionCode, null AS MessageCode, null AS MessageType, null AS Result, tab.Inserted, tab.User FROM log_action as tab) AS A)
			
					UNION ALL
			
				(SELECT * FROM
					(SELECT   tab.PcbId, tab.ChildPcbId, 'Message' AS Type, null AS ActionStep, null AS ActionOrder, null AS ActionCode, tab.MessageCode, tab.MessageType, tab.Result, tab.Inserted, tab.User FROM log_message as tab ) AS B)
			) AS tabouter WHERE 1=1 ";
		
		
	#Build WHERE clausele
	if(defined $pcbId && $pcbId ne ""){
		$cmd .= "AND (tabouter.PcbId LIKE '%_PcbId%')";
	}
	
	if(defined $childPcbId && $childPcbId ne ""){
		$cmd .= "AND (tabouter.ChildPcbId = _ChildPcbId)";
	}
	
	if($typeAction && scalar(@typeMessage) > 0){
		$cmd .= "AND (tabouter.Type = 'Action' OR tabouter.Type = 'Message')";
	}elsif($typeAction){
		$cmd .= "AND (tabouter.Type = 'Action')";
	}elsif(scalar(@typeMessage) > 0){
		$cmd .= "AND (tabouter.Type = 'Message')";
	}else{
		$cmd .= "AND (tabouter.Type <> 'Action' AND tabouter.Type <> 'Message')";
		
	}
	
	if(scalar(@typeMessage) > 0){
		$cmd .= "AND (tabouter.MessageType is null OR tabouter.MessageType IN (".join(', ', map { qq/'$_'/ } @typeMessage).")  )";
	}
	
	if(defined $userName && $userName ne ""){
		$cmd .= "AND (tabouter.User LIKE '%_User%' )";
	}
	
	$cmd .= "ORDER BY tabouter.Inserted DESC ";
	
	$cmd .= "LIMIT ".$limit." OFFSET ".$from.";";
	
	
	
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_TEXT,$pcbId ),
	SqlParameter->new( "_User", Enums->SqlDbType_TEXT,$userName ),
	SqlParameter->new( "_ChildPcbId", Enums->SqlDbType_INT, $childPcbId ));


	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}
 
sub GetLogActionMessCnt {
	my $self  = shift;
	my @params = ();
	my $cmd    = "SELECT COUNT(*) AS cnt FROM
			(
				(SELECT Id FROM log_action AS A)
			
					UNION
			
				(SELECT Id FROM log_message  AS B)
			) AS tabouter;";
		


	my @result = Helper->ExecuteDataSet( $cmd, \@params );
	
	if (@result){
		return $result[0]{"cnt"};
	}else{
		return undef;
	}

	
}





sub InsertActionLog {
	my $self  = shift;
	my $pcbId = shift;
	my $childPcbId = shift;
	my $userName = shift;
	my $actionStep = shift;
	my $actionCode = shift;
	my $actionOrder = shift;
	#my $type = Enums->ActionType_ACTION;
	

	my $cmd    = "INSERT INTO log_action (PcbId, ChildPcbId, ActionStep, ActionCode, ActionOrder, User) VALUES (_PcbId, _ChildPcbId, _ActionStep, _ActionCode, _ActionOrder, _User);";
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR,$pcbId ),
	SqlParameter->new( "_ChildPcbId", Enums->SqlDbType_INT, $childPcbId ),
	SqlParameter->new( "_User", Enums->SqlDbType_VARCHAR,$userName ),
	SqlParameter->new( "_ActionStep", Enums->SqlDbType_VARCHAR,$actionStep ),
	SqlParameter->new( "_ActionCode", Enums->SqlDbType_VARCHAR,$actionCode ),
	SqlParameter->new( "_ActionOrder", Enums->SqlDbType_INT,$actionOrder ));

	
	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}

sub InsertMessageLog {
	my $self  = shift;
	my $pcbId = shift;
	my $childPcbId = shift;
	my $userName = shift;
	my $messageCode = shift;
	my $messageType = shift;
	my $messResult = shift;
	my $oriFile = shift;
	
	#my $type = Enums->ActionType_MESSAGE;
	

	my $cmd    = "INSERT INTO log_message (PcbId, ChildPcbId, MessageCode, MessageType, Result, User, Script) VALUES (_PcbId, _ChildPcbId, _MessageCode,_MessageType, _Result, _User, _Script);";
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR,$pcbId ),
	SqlParameter->new( "_ChildPcbId", Enums->SqlDbType_INT, $childPcbId ),
	SqlParameter->new( "_User", Enums->SqlDbType_VARCHAR,$userName ),
	SqlParameter->new( "_MessageCode", Enums->SqlDbType_VARCHAR,$messageCode ),
	SqlParameter->new( "_MessageType", Enums->SqlDbType_VARCHAR,$messageType ),
	SqlParameter->new( "_Result", Enums->SqlDbType_VARCHAR,$messResult),
	SqlParameter->new( "_Script", Enums->SqlDbType_VARCHAR,$oriFile));

	
	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}


	
sub DeleteAction {
	my $self  = shift;
	my $pcbId = shift;
	my $childPcbId = shift;
	my $actionStep = shift;
	my $actionCode = shift;
	my $actionOrder = shift;
	
	my $cmd    = "DELETE FROM log_action WHERE PcbId = _PcbId AND 
												ChildPcbId = _ChildPcbId AND 
												ActionStep = _ActionStep AND 
												ActionCode = _ActionCode AND 
												ActionOrder = _ActionOrder;";
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR,$pcbId ),
	SqlParameter->new( "_ChildPcbId", Enums->SqlDbType_INT, $childPcbId ),
	SqlParameter->new( "_ActionStep", Enums->SqlDbType_VARCHAR,$actionStep ),
	SqlParameter->new( "_ActionCode", Enums->SqlDbType_VARCHAR,$actionCode ),
	SqlParameter->new( "_ActionOrder", Enums->SqlDbType_INT,$actionOrder ));

	
	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}



sub InsertErrorLog {
	my $self  = shift;
	my $pcbId = shift;
	my $description = shift;
	my $type = shift;
	my $user = shift;
 

	my $cmd    = "INSERT INTO log_error (PcbId, Description, Type, User) VALUES (_PcbId, _Description, _Type, _User);";
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR,$pcbId ),
	SqlParameter->new( "_Description", Enums->SqlDbType_VARCHAR, $description ),
	SqlParameter->new( "_Type", Enums->SqlDbType_VARCHAR,$type ),
	SqlParameter->new( "_User", Enums->SqlDbType_VARCHAR,$user ));


	my $result = Helper->ExecuteNonQuery( $cmd, \@params );

	return $result;
}




sub GetErrorLogs {
	my $self  = shift;
	my $limit = shift;
	my $from = shift;
	my $pcbId = shift;
	my $description = shift;
	my $type = shift;
	my $user = shift;
	
	my $typeMessageTemp = shift; #array of types
	my @typeMessage = ();
	
	if(defined $typeMessageTemp && scalar(@{$typeMessageTemp}) > 0){
		@typeMessage = @{$typeMessageTemp};
	}


	my $cmd    = "SELECT 
					PcbId,
					Description,
					Type,
					User,
					Inserted FROM log_error WHERE 1=1";
		
		
	#Build WHERE clausele
	if(defined $pcbId && $pcbId ne ""){
		$cmd .= "AND (PcbId LIKE '%_PcbId%')";
	}
	
	if(defined $description && $description ne ""){
		$cmd .= "AND (Description LIKE '%_Description%')";
	}
	
	if(defined $type && $type ne ""){
		$cmd .= "AND (Type LIKE '%_Type%')";
	}
	
		
	if(defined $user && $user ne ""){
		$cmd .= "AND (User LIKE '%_User%')";
	}
	
	
	$cmd .= "ORDER BY Inserted DESC ";
	
	$cmd .= "LIMIT ".$limit." OFFSET ".$from.";";
	
	
	
	my @params = (
	SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR,$pcbId ),
	SqlParameter->new( "_Description", Enums->SqlDbType_VARCHAR, $description ),
	SqlParameter->new( "_Type", Enums->SqlDbType_VARCHAR,$type ),
	SqlParameter->new( "_User", Enums->SqlDbType_VARCHAR,$user ));


	my @result = Helper->ExecuteDataSet( $cmd, \@params );

	return @result;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
 
if (0) {

	use Connectors::LogConnector::LogMethods;
	my $test = Connectors::LogConnector::Methods->GetAllLogs();

	 #Methods->InsertActionLog("f00555", "mku", "dorout");
	 
	 print $test; 
}

if (0) {

	#use Connectors::LogConnector::LogMethods;
	# my $test = Methods->GetAllLogs();

	 #Connectors::LogConnector::Methods->InsertActionLog("f00555", "mku", "dorout");
	 
	 #Connectors::LogConnector::Methods->InsertMessageLog("f00555", "mku", "checksomethning", "Did", "Information");
	 
	 
	# my @messType = ("Did", "Test");
	# my $pom = Connectors::LogConnector::Methods->GetActionAndMessages("f00555", undef, 0, 1, \@messType);
	 
#	my $pcbId = shift;
#	my $userName = shift;
#	my $typeAction = shift; #bool
#	my $typeMessage = shift; #bool
#	my $typeMessageTemp = shift; #array of types
#	my @typeMessage = ();
	 
	 print "finish"; 
}

1;
 


