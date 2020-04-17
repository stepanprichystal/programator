
package Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle;

# STYLE DEFINITIONS

# Colors of stackup materials and tables

use constant {

	Clr_BOXBORDER => => "0, 0, 0",
	Clr_BOXBORDERLIGHT => => "191, 191, 191",
	Clr_PRODUCT => "31, 133, 222",

	Clr_COPPER    => "174, 57, 47",
	Clr_CORERIGID => "248, 154, 28",
	Clr_COREFLEX  => "244, 175, 128",
	Clr_PREPREG   => "169, 161, 80",
	Clr_COVERLAY  => "255, 211, 25",
	Clr_ADHESIVE  => "189, 215, 238",
	Clr_STIFFENER => "174, 170, 170",
	
	Clr_PADPAPER => "82, 186, 255",
	Clr_PADRUBBER => "255, 79, 140",
	Clr_PADFILM => "82, 255, 149",

};

# Text size [mm]
use constant {
	TxtSize_NORMAL => 3.6,
	TxtSize_PCBID  => 4.5,

};

# Stackup column widths [mm]

use constant {
	ClmnWidth_margin => 2,

	BoxTitleClmnWidth_1 => 30,
	BoxTitleClmnWidth_2 => 85,
	BoxTitleClmnWidth_3 => 30,
	BoxTitleClmnWidth_4 => 30,

	BoxMainClmnWidth_MARGIN      => 2.9,
	BoxMainClmnWidth_STCKOVRLP   => 2.9,
	BoxMainClmnWidth_STCKOVRLPIN => 2.38,
	BoxMainClmnWidth_TYPE        => 21,
	BoxMainClmnWidth_ID          => 9,
	BoxMainClmnWidth_KIND        => 24,
	BoxMainClmnWidth_NAME        => 40,
	BoxMainClmnWidth_THICK       => 9,
};

# Stackup row heights [mm]

use constant {
	RowHeight_STD         => 7,
	BoxTitleRowHeight_STD => 6,

	BoxMainRowHeight_TITLE    => 6,
	BoxMainRowHeight_TITLEGAP => 9,
	BoxMainRowHeight_MATGAP   => 2,
	BoxMainRowHeight_MATROW   => 6,

};

# Other sizes
use constant {
	BoxSpace_SIZE => 3.7,

};

1;
