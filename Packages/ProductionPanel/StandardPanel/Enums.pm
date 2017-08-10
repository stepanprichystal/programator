
package Packages::ProductionPanel::StandardPanel::Enums;

# Enums of all standard including historic standard in mm
use constant {
			   Standard_307x407   => "standard_307x407",
			   Standard_307x486p2 => "standard_307x486p2",
			   Standard_295x355   => "standard_295x355",
			   Standard_295x460   => "standard_295x460",
};

# Indicate if panel is standard, smaller than standard or bigger than standard
use constant {
	Type_NONSTANDARD    => "type_NonStandard",       # other than below defined types
	Type_STANDARD       => "type_Standard",          # dimension equal to actual standard dim
	Type_STANDARDNOAREA => "type_StandardNoArea",    # dimension equal to actual standard dim, except area

};

# Indicate if active area of specific standard panel is standard, smaller or bigger
use constant {
	Type_STANDARDAREA => "type_StandardArea",        # dimension equal to actual standard active area dim for specific standard panel
	Type_SMALLAREA    => "Type_SmallArea",           # both dimension w AND h are smaller than actual standard active area for specific standard panel
	Type_BIGAREA      => "Type_BigArea",             # both dimension w AND h are bigger than actual standard active area for specific standard panel
	Type_BIGHAREA => "Type_BigHArea",    # height is bigger than actual standard active area for specific standard panel. Width is same or smaller
	Type_BIGWAREA => "Type_BigWArea",    # width is bigger than actual standard active area for specific standard panel. Height is same or smaller

};

# Pcb types in terms of standard definitions
use constant {
	PcbType_FLEXI => "pcbType_FLEXI",    # flexi standards
	PcbType_MULTI => "pcbType_MULTI",    # multilayer standards
	PcbType_1V2V  => "PcbType_1V2V",     # noncpoppper + single + double

};

# Pcb material types in terms of standard definitions
use constant {
	PcbMat_SPEC => "PcbMat_SPEC",        # other than below defined materials
	PcbMat_FR4  => "PcbMat_FR4",         #  FR4 material
	PcbMat_ALU  => "PcbMat_ALU",         #   Alu material

};

1;

