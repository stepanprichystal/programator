
package Packages::CAMJob::Traveler::UniTraveler::Enums;

use utf8;
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::Enums';

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
	BoxMainClmnWidth_TEXT   => 100,
	BoxMainClmnWidth_SIGN   => 10,

};

# Stackup row heights [mm]

use constant {
	RowHeight_STD         => 6,
	BoxHFRowHeight_TITLE  => 4,
	BoxTitleRowHeight_STD => 6,

};

# Other sizes
use constant {
	BoxSpace_SIZE => 2.5,
	Border_THICK  => 0.1,

};

1;
