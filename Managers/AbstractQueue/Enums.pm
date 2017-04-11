
package Managers::AbstractQueue::Enums;

use constant {
	EventType_ITEM_RESULT  => "itemResult",
	EventType_GROUP_START  => "groupTaskStart",
	EventType_GROUP_END    => "groupTaskEnd",
	EventType_GROUP_RESULT => "groupResult",
	EventType_TASK_RESULT  => "taskResult",
	EventType_SPECIAL      => "special"           # item, whcih keeps extra info (eg, chose master pcbid of pool)

};

# used for merge and late split messages into one string
use constant { ItemResult_DELIMITER => "#<%<" };

use constant { GroupState_WAITING => "waiting", };

1;

