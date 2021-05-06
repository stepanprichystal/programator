
# Contain enums, which are related to script and applications on server

package Enums::EnumsIS;

# possible values of column 'Aktualni krok' in order
use constant {
	CurStep_HOTOVOZADAT => "HOTOVO-zadat",
	CurStep_ZADANO      => "ZADANO",
	CurStep_KPANELIZACI => "k panelizaci",
	CurStep_EXPORTERROR => "exportUtility-error",    # when export utility fail

	# statuses of checkReorder app
	CurStep_CHECKREORDERERROR => "checkReorder-error",
	CurStep_ZPRACOVANIAUTO    => "zpracovani-auto",
	CurStep_ZPRACOVANIMAN     => "zpracovani-rucni",
	CurStep_EMPTY             => "",

	# statuses of processReorder app
	CurStep_PROCESSREORDERERR => "processReorder-error",
	CurStep_PROCESSREORDEROK  => "processReorder-ok",

	# statuses of job approval
	CurStep_HOTOVOODSOUHLASIT => "HOTOVO-odsouhlasit",
	CurStep_POSLANDOTAZ       => "poslan dotaz <user>",
	CurStep_NOVADATA          => "posle nova data",
	CurStep_VRACENONAOU       => "vraceno na OU",

};

# material types from  uda_kmenova_karta_skladu.dps_type
use constant {
			   MatType_COPPER      => "Copper",
			   MatType_CORE        => "Core",
			   MatType_PREPREG     => "Prepreg",
			   MatType_PREPREGFLEX => "Prepreg Flex"
};

# Operation ID - attribut which is able to fill with additional information
# (by arbitrary number of pairs: key + value)
use constant {
	
#	# Main PCB operation
#	OpId_galvanicke_medeni_tenting_1    => "galvanicke_medeni_tenting_1",
#	OpId_galvanicke_medeni_tenting_2    => "galvanicke_medeni_tenting_2",
#	OpId_galvanicke_medeni_tenting_3    => "galvanicke_medeni_tenting_3",
#	OpId_galvanicke_medeni_a_cinovani_1 => "galvanicke_medeni_a_cinovani_1",
#	OpId_galvanicke_medeni_a_cinovani_2 => "galvanicke_medeni_a_cinovani_2",
#	OpId_galvanicke_medeni_a_cinovani_3 => "galvanicke_medeni_a_cinovani_3",

	# Core operatioon
	OpId_galvanicke_medeni_tenting   => "galvanicke_medeni_tenting",
	OpId_galvanike_medeni_a_cinovani => "galvanike_medeni_a_cinovani"

};

1;
