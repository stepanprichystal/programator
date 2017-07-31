
# Contain enums, which are related to script and applications on server

package Enums::EnumsIS;

# possible values of column 'Aktualni krok' in order
use constant {
	CurStep_HOTOVOZADAT => "HOTOVO-zadat",
	CurStep_KPANELIZACI => "k panelizaci",
	CurStep_EXPORTERROR => "exportUtility-error",    # when export utility fail

	# statuses of checkReorder app
	CurStep_CHECKREORDERERROR => "checkReorder-error",
	CurStep_ZPRACOVANIAUTO    => "zpracovani-auto",
	CurStep_ZPRACOVANIMAN     => "zpracovani-rucni",
	CurStep_ZPRACOVANIREV     => "zpracovani-revize",

	# statuses of processReorder app
	CurStep_PROCESSREORDERERR => "processReorder-error",
	CurStep_PROCESSREORDEROK  => "processReorder-ok",

};

1;
