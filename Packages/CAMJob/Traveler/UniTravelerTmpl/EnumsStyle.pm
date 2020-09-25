
package Packages::CAMJob::Traveler::UniTravelerTmpl::EnumsStyle;

use utf8;
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::Enums';

# STYLE DEFINITIONS

# Colors of stackup materials and tables

use constant {

	Clr_BOXBORDER => "0, 0, 0",

};

# Text size [mm]
use constant {
	TxtSize_SMALL  => 3.0,
	TxtSize_NORMAL => 3.4,
	TxtSize_BIG    => 4.0,
	TxtSize_PCBID  => 4.3,

};

# Stackup column widths [mm]

use constant {
	ClmnWidth_margin => 0.5,

	BoxTitleClmnWidth_1 => 30,
	BoxTitleClmnWidth_2 => 115,
	BoxTitleClmnWidth_3 => 30,
	BoxTitleClmnWidth_4 => 30,

	BoxMainClmnWidth_MARGIN => 3,
	BoxMainClmnWidth_TEXT   => 105,
	BoxMainClmnWidth_SIGN   => 30,

};

# Stackup row heights [mm]

use constant {

	# General row heights
	RowHeight_STD => 7,

	# Header and footer box rows heights
	BoxHFRowHeight_TITLE => 6,

	# Title box rows heights
	BoxTitleRowHeight_STD => 6,

	# Info box rows heights
	BoxInfoRowHeight_TITLE => 6,

};

# Other sizes
use constant {
	BoxSpace_SIZE => 2.5,
	Border_THICK  => 0.1,

};

# Return traveler marking, which represnet semiproduct type
sub GetTravelerMarking {
	my $self = shift;
	my $type = shift;

	my %t = ();

	$t{ Enums->ProductType_STENCILFLEX } = "SAB";
	$t{ Enums->ProductType_STENCILPEEL } = "SAB";
	return $t{$type};

}

1;
