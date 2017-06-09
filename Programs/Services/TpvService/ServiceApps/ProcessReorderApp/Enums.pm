
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Enums;

# represent type of DTM vzsledne/vratne holes
use constant {
			   Check_MANUAL   => "manual",
			   Check_AUTO   => "auto"
};
 
# steps of reorder 
use constant {
			   Step_AUTOERR   => "zpracovani - auto - chyba",
			   Step_AUTOOK   => "zpracovani - auto - ok"
};

1;

