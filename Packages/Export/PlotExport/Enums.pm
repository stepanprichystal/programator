
package Packages::Export::PlotExport::Enums;

use constant {

	# use binary operators

	LType_MASKTOP => "maskTop",
	LType_MASKBOT => "maskBot",

	LType_SILKTOP => "silkTop",
	LType_SILKBOT => "silkBot",

	LType_SIGOUTER => "signalOuter",
	LType_SIGINNER => "signalInner",

	LType_GOLDFINGER => "goldfinger",
 
	LType_ALL => "allTypes"
};

use constant {

	# Oreintation of pcbs on film

	Ori_VERTICAL   => "vertical", 
	Ori_HORIZONTAL => "horizontal"
};

use constant {

	# tell which size of pcb FilmCreator counts with

	Size_PROFILE => "sizeProfile",    # size of pcb profile
	Size_FRAME   => "sizeFrame"       # siye of frame around the profile
};

use constant {

	# tell which size of pcb FilmCreator counts with

	FilmSize_SmallX => 609.6,    # size of pcb profile
	FilmSize_SmallY => 406.4,    # size of pcb profile
	FilmSize_BigX => 609.6,    # size of pcb profile
	FilmSize_BigY => 508.0,    # size of pcb profile
	
	
	FilmSize_Big => "filmBig",    # size of pcb profile
	FilmSize_Small => "filmSmall",    # size of pcb profile

};


1;
