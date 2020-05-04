
package Packages::CAMJob::Stackup::ProcessStackupTempl::Enums;

use constant {
	LamType_STIFFPRODUCT    => "LamType_STIFFPRODUCT",       # Lamination of stiffener
	LamType_CVRLBASE        => "LamType_CVRLBASE",           # Lamination of coverlay on base material
	LamType_CVRLPRODUCT     => "LamType_CVRLPRODUCT",        # Lamination of coverlay on product (already laminated base mat)
	LamType_RIGIDBASE       => "LamType_RIGIDBASE",          # Lamination of prepreg on base rigid material
	LamType_FLEXBASE        => "LamType_FLEXBASE",           # Lamination of flexible prepreg on base material
	LamType_RIGIDFINAL      => "LamType_RIGIDFINAL",         # Lamination of cores
	LamType_ORIGIDFLEXFINAL => "LamType_ORIGIDFLEXFINAL",    # Lamination of cores
	LamType_IRIGIDFLEXFINAL => "LamType_IRIGIDFLEXFINAL",    # Lamination of cores

};

# Laminate pads type

use constant {
	ItemType_PADPAPER     => "ItemType_PADPAPER",            # disposable paper pad
	ItemType_PADRUBBER    => "ItemType_PADRUBBER",           # rubber pad
	ItemType_PADRELEASE   => "ItemType_PADRELEASE",          # disposable release films
	ItemType_PADFILM      => "ItemType_PADFILM",             # disposable films
	ItemType_PADFILMGLOSS => "ItemType_PADFILMGLOSS",        # disposable films from shine side
	ItemType_PADFILMMATT  => "ItemType_PADFILMMATT",         # disposable films from matt side
	ItemType_PADALU       => "ItemType_PADALU",              # aluminuim pad
	ItemType_PADSTEEL     => "ItemType_PADSTEEL",            # steel plate

	ItemType_MATCUFOIL        => "ItemType_MATCUFOIL",
	ItemType_MATCUCORE        => "ItemType_MATCUCORE",
	ItemType_MATCORE          => "ItemType_MATCORE",
	ItemType_MATFLEXCORE      => "ItemType_MATFLEXCORE",
	ItemType_MATPREPREG       => "ItemType_MATPREPREG",
	ItemType_MATFLEXPREPREG   => "ItemType_MATFLEXPREPREG",
	ItemType_MATCOVERLAY      => "ItemType_MATCOVERLAY",
	ItemType_MATSTIFFENER     => "ItemType_MATSTIFFENER",
	ItemType_MATSTIFFADHESIVE => "ItemType_MATSTIFFADHESIVE",
	ItemType_MATCVRLADHESIVE  => "ItemType_MATCVRLADHESIVE",
	ItemType_MATPRODUCTDPS    => "ItemType_MATPRODUCTDPS",
	ItemType_MATPRODUCTCORE   => "ItemType_MATPRODUCTCORE"

};

use constant {
	
	KEYORDERNUM   => "key_orderNum",
	KEYORDERDATE  => "key_orderDate",
	KEYORDERTERM  => "key_orderTerm",
	KEYORDEAMOUNTTOT => "key_orderAmountTot",
	KEYORDEAMOUNT => "key_orderAmountBase",
	KEYORDEAMOUNTEXT => "key_orderAmountExt",
	KEYTOTALPACKG => "key_totalPackg",
	KEYEXTRAPRODUC => "key_extraProducText",
	KEYEXTRAPRODUCVAL => "key_extraProducVal"

};

1;
