
package Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle;

use utf8;
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';

# STYLE DEFINITIONS

# Colors of stackup materials and tables

use constant {

	Clr_BOXBORDER      => "0, 0, 0",
	Clr_BOXBORDERLIGHT => "191, 191, 191",
	Clr_PRODUCT        => "31, 133, 222",

	Clr_COPPER    => "156, 1, 1",
	Clr_CORERIGID => "159, 149, 19",
	Clr_COREFLEX  => "159, 149, 19",
	Clr_PREPREG   => "71, 143, 71",
	Clr_COVERLAY  => "255, 211, 25",
	Clr_ADHESIVE  => "189, 215, 238",
	Clr_STIFFENER => "174, 170, 170",

	Clr_PADPAPER     => "159, 217, 255",
	Clr_PADRUBBER    => "255, 174, 202",
	Clr_PADFILM      => "136, 254, 175",
	Clr_PADALU       => "180, 180, 180",
	Clr_PADSTEEL     => "146, 146, 146",

};

# Text size [mm]
use constant {
	TxtSize_SMALL => 3.0,
	TxtSize_NORMAL => 3.4,
	TxtSize_BIG    => 4.0,
	TxtSize_PCBID  => 5.0,

};

# Stackup column widths [mm]

use constant {
	ClmnWidth_margin => 0.5,

	BoxTitleClmnWidth_1 => 30,
	BoxTitleClmnWidth_2 => 115,
	BoxTitleClmnWidth_3 => 30,
	BoxTitleClmnWidth_4 => 30,

	BoxMainClmnWidth_MARGIN      => 3,
	BoxMainClmnWidth_PADOVRLP    => 2.5,
	BoxMainClmnWidth_STCKOVRLP   => 4.5,
	BoxMainClmnWidth_STCKOVRLPIN => 1,
	BoxMainClmnWidth_TYPE        => 22,
	BoxMainClmnWidth_ID          => 4,
	BoxMainClmnWidth_KIND        => 23,
	BoxMainClmnWidth_NAME        => 49,
	BoxMainClmnWidth_THICK       => 8,

	BoxMatListClmnWidth_TYPE  => 25,
	BoxMatListClmnWidth_REF   => 22,
	BoxMatListClmnWidth_KIND  => 22,
	BoxMatListClmnWidth_NAME  => 49,
	BoxMatListClmnWidth_COUNT => 7,

};

# Stackup row heights [mm]

use constant {
	RowHeight_STD => 6,

	BoxHFRowHeight_TITLE  => 4,
	BoxTitleRowHeight_STD => 6,

	BoxMainRowHeight_TITLE       => 6,
	BoxMainRowHeight_TITLEGAP    => 5,
	BoxMainRowHeight_MATGAP      => 0.7,
	BoxMainRowHeight_MATROW      => 5,
	BoxMainRowHeight_STEELPADROW => 2,

};

# Other sizes
use constant {
	BoxSpace_SIZE => 2.5,
	Border_THICK  => 0.1,

};

sub GetItemTitle {
	my $self = shift;
	my $type = shift;

	my %t = ();

	$t{ Enums->ItemType_PADPAPER }     = "Papírová podl.";     # disposable paper pad
	$t{ Enums->ItemType_PADRUBBER }    = "Gumová podl.";     # rubber pad
	$t{ Enums->ItemType_PADFILM }      = "Plastová podl.";      # disposable plastic films
	$t{ Enums->ItemType_PADFILMGLOSS } = "";                      # disposable plastic shine film side
	$t{ Enums->ItemType_PADRELEASE }   = "Separ. fólie";         # disposable release films
	$t{ Enums->ItemType_PADALU }       = "Hliníková podl.";    # aluminuim pad
	$t{ Enums->ItemType_PADSTEEL }     = "Separ. plech";          # steel plate

	$t{ Enums->ItemType_MATCUFOIL }        = "Cu fólie";
	$t{ Enums->ItemType_MATCUCORE }        = "Cu jádro";
	$t{ Enums->ItemType_MATCORE }          = "Jádro rigid";
	$t{ Enums->ItemType_MATFLEXCORE }      = "Jádro flex";
	$t{ Enums->ItemType_MATPREPREG }       = "Prepreg";
	$t{ Enums->ItemType_MATFLEXPREPREG }   = "Prepreg flex";
	$t{ Enums->ItemType_MATCOVERLAY }      = "Coverlay";
	$t{ Enums->ItemType_MATSTIFFENER }     = "Stiffener";
	$t{ Enums->ItemType_MATCVRLADHESIVE }  = "Lepidlo";
	$t{ Enums->ItemType_MATSTIFFADHESIVE } = "Lepidlo";
	$t{ Enums->ItemType_MATPRODUCTDPS }    = "Polotovar DPS";
	$t{ Enums->ItemType_MATPRODUCTCORE }    = "Polotovar";
	
	

	return $t{$type};

}

sub GetLamTitle {
	my $self = shift;
	my $type = shift;

	my %t = ();

	$t{ Enums->LamType_STIFFPRODUCT } = "Lisování Stiffeneru";
	$t{ Enums->LamType_CVRLBASE }     = "Lisování FLEX + COVERLAY";
	$t{ Enums->LamType_CVRLPRODUCT }  = "Lisování FLEX + COVERLAY";
	$t{ Enums->LamType_RIGIDBASE }    = "Lisování polotovaru";
	$t{ Enums->LamType_FLEXBASE }     = "Lisování FLEX jádra";
	$t{ Enums->LamType_RIGIDFINAL }    = "Lisování";
	$t{ Enums->LamType_ORIGIDFLEXFINAL }    = "Lisování";
	$t{ Enums->LamType_IRIGIDFLEXFINAL }    = "Lisování";
 
	 

	return $t{$type};
}
1;
