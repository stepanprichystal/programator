
package Packages::CAM::PanelClass::Enums;

# Steps creator setting enums
use constant {
	PnlClassTransform_ROTATION => "rotation",
	PnlClassTransform_PATTERN  => "pattern",

	PnlClassRotation_0DEG    => "no_rotation",
	PnlClassRotation_90DEG   => "rotate_90",
	PnlClassRotation_UNIFORM => "uniform",
	PnlClassRotation_ANY     => "any_rotation",

	PnlClassPattern_NO_PATTERN        => "no_pattern",
	PnlClassPattern_ALTERNATE_ROW     => "alternate_row",
	PnlClassPattern_ALTERNATE_COL     => "alternate_col",
	PnlClassPattern_ALTERNATE_ROW_COL => "alternate_row_col",
	PnlClassPattern_TOP_HALF          => "top_half",
	PnlClassPattern_BOTTOM_HALF       => "bottom_half",
	PnlClassPattern_RIGHT_HALF        => "right_half",
	PnlClassPattern_LEFT_HALF         => "left_half",

	PnlClassSpacingAlign_KEEP_IN_CENTER => "keep_in_center",
	PnlClassSpacingAlign_SPACE_EVENLY   => "space_evenly",

	PnlClassInterlock_NONE    => "none",
	PnlClassInterlock_SIMPLE  => "simple",
	PnlClassInterlock_SLIDING => "sliding",

	PnlClassNumMaxSteps_NO_LIMIT => "no_limit"

};

# Pcb type in terms of panel size depending on material
use constant {

	PCBMaterialType_RIGID  => "rigid",
	PCBMaterialType_FLEX   => "flex",
	PCBMaterialType_HYBRID => "hybrid",
	PCBMaterialType_AL     => "al",

};

# Pcb type in terms of panel size depending on material
use constant {

	PCBLayerCnt_2V => "2v",
	PCBLayerCnt_VV => "vv"
};

# Pcb type in terms of panel size depending on material
use constant {

	PCBSpecial_PBHAL => "pbhal",
	PCBSpecial_AU => "au",
	PCBSpecial_GRAFIT => "grafit"
};

1;
