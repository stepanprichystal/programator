
package Packages::CAMJob::Stackup::ProcessStackup::Enums;

use constant {
			   LamType_STIFFPRODUCT => "LamType_STIFFPRODUCT",    # Lamination of stiffener
			   LamType_CVRLBASE     => "LamType_CVRLBASE",        # Lamination of coverlay on base material
			   LamType_CVRLPRODUCT  => "LamType_CVRLPRODUCT",     # Lamination of coverlay on product (already laminated base mat)
			   LamType_PRPGBASE     => "LamType_PRPGBASE",        # Lamination of prepreg on base material
			   LamType_FLEXPRPGBASE => "LamType_FLEXPRPGBASE",    # Lamination of flexible prepreg on base material
			   LamType_MULTIBASE    => "LamType_MULTIBASE",       # Lamination of cores
			   LamType_MULTIPRODUCT => "LamType_MULTIPRODUCT",    # Lamination of products
};

# Laminate pads type

use constant {
	ItemType_PADPAPER     => "ItemType_PADPAPER",        # disposable paper pad
	ItemType_PADRUBBER    => "ItemType_PADRUBBER",       # rubber pad
	ItemType_PADFILM      => "ItemType_PADFILM",         # disposable films
	ItemType_PADFILMSHINE => "ItemType_PADFILMSHINE",    # disposable films from shine side
	ItemType_PADALU       => "ItemType_PADALU",          # aluminuim pad
	ItemType_PADSTEEL     => "ItemType_PADSTEEL",        # steel plate

	ItemType_MATCUFOIL      => "ItemType_MATCUFOIL",
	ItemType_MATCUCORE      => "ItemType_MATCUCORE",
	ItemType_MATCORE        => "ItemType_MATCORE",
	ItemType_MATFLEXCORE    => "ItemType_MATFLEXCORE",
	ItemType_MATPREPREG     => "ItemType_MATPREPREG",
	ItemType_MATFLEXPREPREG => "ItemType_MATFLEXPREPREG",
	ItemType_MATCOVERLAY    => "ItemType_MATCOVERLAY",
	ItemType_MATSTIFFENER   => "ItemType_MATSTIFFENER",
	ItemType_MATADHESIVE    => "ItemType_MATADHESIVE",
	ItemType_MATPRODUCT     => "ItemType_MATPRODUCT"

};

1;
