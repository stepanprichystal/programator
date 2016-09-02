
package Managers::AsyncJobMngr::Enums;

use constant {
	ExitType_SUCCES => 'Succes',
	ExitType_FAILED => 'Failed',
	ExitType_FORCE  => 'Force',

};

use constant {
			   JobState_RUNNING      => "running",
			   JobState_WAITINGQUEUE => "waitingQueue",
			   JobState_WAITINGPORT  => "waitingPort",
			   JobState_ABORTING  => "aborting",
			   JobState_DONE         => "done"
};

use constant {
	RUNMODE_Async => 'runningAsync',
	RUNMODE_Sync  => 'runningSync',

};

1;
