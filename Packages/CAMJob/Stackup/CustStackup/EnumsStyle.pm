
package Packages::CAMJob::Stackup::CustStackup::EnumsStyle;

# STYLE DEFINITIONS

# Colors of stackup materials and tables

use constant {
	Clr_TITLEBACKG     => "201, 16, 26",
	Clr_HEADMAINBACK   => "191, 191, 191",
	Clr_HEADSUBBACK    => "217, 217, 217",
	Clr_LEFTCLMNBACK   => "242, 242, 242",
	Clr_SECTIONBORDER  => "160, 160, 160",
	Clr_SOLDERMASK     => "59, 113, 41",
	Clr_SOLDERMASKFLEX => "112, 173, 71",
	Clr_SILKSCREEN     => "200, 200, 200",
	Clr_COPPER         => "174, 57, 47",
	Clr_CORERIGID      => "248, 154, 28",
	Clr_COREFLEX       => "244, 175, 128",
	Clr_PREPREG        => "169, 161, 80",
	Clr_COVERLAY       => "255, 211, 25",
	Clr_ADHESIVE       => "189, 215, 238",
	Clr_STIFFENER      => "174, 170, 170",
	Clr_NCDRILL        => "64, 64, 64",
	Clr_TAPE           => "237, 199, 143",

};

# Text size [mm]
use constant {
			   TxtSize_TITLE    => 3.6,
			   TxtSize_MAINHEAD => 3.6,
			   TxtSize_SUBHEAD  => 3.6,
			   TxtSize_STANDARD => 3.4,
};

# Stackup column widths [mm]

use constant {
			   ClmnWidth_matname  => 47,
			   ClmnWidth_culayer  => 22,
			   ClmnWidth_overlap  => 4.5,
			   ClmnWidth_mattype  => 31,
			   ClmnWidth_matthick => 22,
			   ClmnWidth_ncdrill  => 3.7,
			   ClmnWidth_end      => 6,
};

# Stackup row heights [mm]

use constant {
			   RowHeight_TITLE     => 7,
			   RowHeight_MAINHEAD  => 9,
			   RowHeight_STANDARD  => 5,
			   RowHeight_MATGAP    => 0.7,
			   RowHeight_CORERIGID => 9.5,
			   RowHeight_COREFLEX  => 4.6,
			   RowHeight_BLOCKGAP    => 0.9,
};

1;
