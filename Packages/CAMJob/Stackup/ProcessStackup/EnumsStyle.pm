
package Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle;

# STYLE DEFINITIONS

# Colors of stackup materials and tables

use constant {

	Clr_BOXBORDER => => "0, 0, 0"

};

# Text size [mm]
use constant {
	TxtSize_NORMAL => 3.6,
	TxtSize_PCBID => 4,

	#			   TxtSize_MAINHEAD => 3.6,
	#			   TxtSize_SUBHEAD  => 3.6,
	#			   TxtSize_STANDARD => 3.4,
};

# Stackup column widths [mm]

use constant {
	ClmnWidth_margin => 2,

	BoxTitleClmnWidth_1 => 30,
	BoxTitleClmnWidth_2 => 120,
	BoxTitleClmnWidth_3 => 30,
	BoxTitleClmnWidth_4 => 30,

	#			   ClmnWidth_culayer  => 22,
	#			   ClmnWidth_overlap  => 4.5,
	#			   ClmnWidth_mattype  => 31,
	#			   ClmnWidth_matthick => 22,
	#			   ClmnWidth_ncdrill  => 3.7,
	#			    ClmnWidth_end  => 6,
};

# Stackup row heights [mm]

use constant {
	RowHeight_STD => 7,

	#			   RowHeight_MAINHEAD => 9,
	#			   RowHeight_STANDARD => 5,
	#			   RowHeight_MATGAP   => 0.7,
	#			    RowHeight_CORERIGID => 9.5,
	#			    RowHeight_COREFLEX => 4.6,
};

1;
