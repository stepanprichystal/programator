
package Managers::AsyncJobMngr::Enums;

use constant {
	ExitType_SUCCES     => 'Succes',
	ExitType_FORCE      => 'Force',
	ExitType_FORCERESTART => 'ForceRestart',

};

use constant {
			   JobState_RUNNING      => "running",
			   JobState_WAITINGQUEUE => "waitingQueue",
			   JobState_WAITINGPORT  => "waitingPort",
			   JobState_ABORTING     => "aborting",
			   JobState_RESTARTING   => "restarting",
			   JobState_DONE         => "done"
};

use constant {
			   State_FREE_SERVER      => "free",
			   State_PREPARING_SERVER => "prepare",
			   State_RUNING_SERVER    => "runing",
			   State_WAITING_SERVER   => "waiting"
};

# tell if tray ico and behaviour will be used
use constant {
	RUNMODE_WINDOW => 'runmode_window',
	RUNMODE_TRAY   => 'runmode_tray',

};

use constant {
			   TaskMode_SYNC  => "synchronousTask",
			   TaskMode_ASYNC => "asynchronousTask"
};

1;
