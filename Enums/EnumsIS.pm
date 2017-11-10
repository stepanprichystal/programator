
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
	CurStep_EMPTY             => "",

	# statuses of processReorder app
	CurStep_PROCESSREORDERERR => "processReorder-error",
	CurStep_PROCESSREORDEROK  => "processReorder-ok"

};

# material types from  uda_kmenova_karta_skladu.dps_type
use constant {
			   MatType_COPPER  => "Copper",
			   MatType_CORE    => "Core",
			   MatType_PREPREG => "Prepreg"
};

1;
