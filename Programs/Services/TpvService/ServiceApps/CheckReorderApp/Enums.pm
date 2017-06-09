
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::Enums;

# represent type of DTM vzsledne/vratne holes
use constant {
			   Check_MANUAL   => "manual",
			   Check_AUTO   => "auto"
};
 
# steps of reorder 
use constant {
			   Step_ERROR   => "zpracovani - chyba",
			   Step_AUTO   => "zpracovani - auto",
			   Step_MANUAL   => "zpracovani - rucni",
			   Step_PANELIZATION   => "k panelizaci"
};

1;

