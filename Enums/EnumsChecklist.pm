
package Enums::EnumsChecklist;

# Checlist action statuses
# Warning - do not change string value,
# theeses codes are from InCAM adn are used to comparsion values returned from InCAM
use constant {
			   Status_OUTDATE => "OUTDATE",
			   Status_DONE    => "DONE",
			   Status_UNDONE  => "UNDONE",
			   Status_ERROR   => "ERROR"
};

# Names of InCAM checklist report categories returned in Checklist report
use constant {
	Cat_PADTOPAD         => "Pad to pad",
	Cat_PADTOCIRCUIT     => "Pad to circuit",
	Cat_CIRCUITTOCIRCUIT => "Circuit to circuit"

};

1;

