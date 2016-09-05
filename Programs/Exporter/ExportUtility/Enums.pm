
package Programs::Exporter::ExportUtility::Enums;

use constant {
			   EventType_ITEM_RESULT  => "itemResult",
			  #EventType_ITEM_ERROR   => "itemError",
			  
			   EventType_GROUP_START => "groupExportStart",
			   EventType_GROUP_END => "groupExportEnd",
			   EventType_GROUP_RESULT  => "itemResult",
			   
			   EventType_TASK_RESULT  => "itemResult",   
			   
			   
};
 
use constant {
			   ItemResult_DELIMITER  => "#<%<"			   
};


use constant {
			   GroupState_WAITING  => "waiting",	   
};

 
 
 
#
#package EnumsGeneral::UserName;
#
#use constant {
#    SPR => mku,
#	MKU => 'Warning',
#	RVI=>'Question',
#	RC => 'Information'
#};

1;

