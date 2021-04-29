
package Enums::EnumsChecklist;

# Checlist action statuses
# Warning - do not change string value,
# these codes are from InCAM adn are used to comparsion values returned from InCAM
use constant {
			   Status_OUTDATE => "OUTDATE",
			   Status_DONE    => "DONE",
			   Status_UNDONE  => "UNDONE",
			   Status_ERROR   => "ERROR"
};

# Names of InCAM checklist report categories returned in Checklist report
# these codes are from InCAM adn are used to comparsion values returned from InCAM
use constant {
	Cat_PAD2PAD            => "p2p",
	Cat_PAD2CIRCUIT        => "p2c",
	Cat_CIRCUIT2CIRCUIT    => "c2c",
	Cat_PTHCOMPANNULARRING => "pth_ar",
	Cat_VIAANNULARRING     => "via_ar",

};

# Return title for category key
sub GetCatTitle {
	my $self = shift;
	my $code = shift;

	my $title = "Unknown category title";

	if ( $code eq Cat_PAD2PAD ) {

		$title = "Pad to Pad";

	}
	elsif ( $code eq Cat_PAD2CIRCUIT ) {

		$title = "Pad to circuit";

	}
	elsif ( $code eq Cat_CIRCUIT2CIRCUIT ) {

		$title = "Circuit to circuit";

	}
	elsif ( $code eq Cat_PTHCOMPANNULARRING ) {

		$title = "PTH (Comp) Annular ring";

	}
	elsif ( $code eq Cat_VIAANNULARRING ) {

		$title = "VIA Annular ring";

	}

	return $title;
}

# Severity combination of checklsit
use constant {
			   Sev_GREEN  => "G",
			   Sev_YELLOW => "Y",
			   Sev_RED    => "R"
};

1;

