
package Managers::AbstractQueue::Enums;

use constant {
	EventType_ITEM_RESULT  => "itemResult",
	EventType_GROUP_START  => "groupExportStart",
	EventType_GROUP_END    => "groupExportEnd",
	EventType_GROUP_RESULT => "groupResult",
	EventType_TASK_RESULT  => "taskResult",
	EventType_THREAD_STOP  => "threadStop"

};

# used for merge and late split messages into one string
use constant { ItemResult_DELIMITER => "#<%<" };

use constant { GroupState_WAITING => "waiting", };

1;

