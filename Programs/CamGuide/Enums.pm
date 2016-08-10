
package Programs::CamGuide::Enums;


use utf8;

use constant {
    ActionType_DO => 'Do',
    ActionType_DOANDSTOP => 'DoAndStop',
	ActionType_CHECK => 'Check',
	ActionType_PAUSE => 'Pause'
};

use constant {
    ActStatus_VISITED => 'Visited',
    ActStatus_UNVISITED => 'Unvisited',
};


use constant {
    ERR_SETCANCONTINUE => "Error: Action - %s must set \'If guide script can continue\' by SetCanContinue() method.",
    ERR_SETPAUSEMESS => "Error: Action - %s must set \'Pause message\' by SetPauseMess() method.",
    ERR_ACTIONNAME => "Error: Action  must set value \$n\{'%s'\} in action subroutine.",
    ERR_ACTIONDESC => "Error: Action must set value \$d\{'%s'\} in action subroutine.",
    ERR_GUIDEID => "Initialization guide %s is not possible. \"Guide Id\" in %s package has to be equal with \"Guide Id\" in \"GuideSelector table\".\n",
};


use constant {
    ActualStep_STEPO => 'o',
    ActualStep_STEPOPLUS1 => 'o+1',
    ActualStep_STEPMPANEL => 'mpanel',
    ActualStep_STEPPANEL => 'panel',
    ActualStep_STEPEXPORT => 'export',
};

use constant {
    GUIDEITEM_ACTION => "Action",
    GUIDEITEM_STEP => "Step",
    GUIDEITEM_FINISH => "Finish"
};


use constant {
    TXT_PRIPRAVAR => "Dps musí obsahovat přípraváře, vytvoř ji",

};

1;
