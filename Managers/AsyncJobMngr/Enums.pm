
package Managers::AsyncJobMngr::Enums;

use constant {
	ExitType_SUCCES => 'Succes',

	#ExitType_FAILED => 'Failed',
	ExitType_FORCE => 'Force',

};

use constant {
			   JobState_RUNNING      => "running",
			   JobState_WAITINGQUEUE => "waitingQueue",
			   JobState_WAITINGPORT  => "waitingPort",
			   JobState_ABORTING     => "aborting",
			   JobState_DONE         => "done"
};

use constant {
	RUNMODE_Async => 'runningAsync',
	RUNMODE_Sync  => 'runningSync',

};

use constant {
	State_FREE_SERVER      => "free",
	State_PREPARING_SERVER => "prepare",
	State_RUNING_SERVER    => "runing",
	State_WAITING_SERVER   => "waiting"
};

1;
