
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
	LamPad_PADPAPER  => "LamPad_PADPAPER",        # Lamination of stiffener
	LamPad_PADRUBBER => "LamPad_PADRUBBER",        # Lamination of stiffener
	LamPad_PADFILM   => "LamPad_PADFILM"         # Lamination of stiffener
  };

  1;
