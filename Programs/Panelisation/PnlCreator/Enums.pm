
package Programs::Panelisation::PnlCreator::Enums;


# Panelisation types based on panel
use constant {
			   PnlType_PRODUCTIONPNL => "type_ProductionPnl",
			   PnlType_CUSTOMERPNL   => "type_CustomerPnl"
};



# Panelisation part types
use constant {

	# Profile creators
	SizePnlCreator_USER      => "SizePnlCreator_User",
	SizePnlCreator_HEG       => "SizePnlCreator_Heg",
	SizePnlCreator_MATRIX    => "SizePnlCreator_Matrix",
	SizePnlCreator_CLASSUSER => "SizePnlCreator_ClassUser",
	SizePnlCreator_CLASSHEG  => "SizePnlCreator_ClassHeg",
	SizePnlCreator_PREVIEW   => "SizePnlCreator_Preview",

	# Step placement creaotrs
	StepPnlCreator_AUTOUSER => "StepPnlCreator_AutoUser",
	StepPnlCreator_AUTOHEG  => "StepPnlCreator_AutoHeg",
	StepPnlCreator_MATRIX   => "StepPnlCreator_Matrix",
	StepPnlCreator_SET      => "StepPnlCreator_Set",
	StepPnlCreator_PREVIEW  => "StepPnlCreator_Preview",

	# Scheme sreators
	SchemePnlCreator_LIBRARY => "SchemaPnlCreator_Library",

};

# Steps creator setting enums
use constant {
	StepPlacement_ROTATION => "StepPlacement_Rotation",
	StepPlacement_PATTERN  => "StepPlacement_Pattern",

	StepRotation_0DEG    => "StepRotation_no_rotation",
	StepRotation_90DEG   => "StepRotation_rotate_90",
	StepRotation_UNIFORM => "StepRotation_uniform",
	StepRotation_ANY     => "StepRotation_any",

	StepPattern_NO_PATTERN         => "StepRotation_no_pattern",
	StepPattern_ALTERNATE_ROW      => "StepRotation_alternate_row",
	StepRotation_ALTERNATE_COL     => "StepRotation_alternate_col",
	StepRotation_ALTERNATE_ROW_COL => "StepRotation_alternate_row_col",
	StepRotation_TOP_HALF          => "StepRotation_top_half",
	StepRotation_BOTTOM_HALF       => "StepRotation_bottom_half",
	StepRotation_RIGHT_HALF        => "StepRotation_right_half",
	StepRotation_LEFT_HALF         => "StepRotation_left_half",

	StepSpacing_KEEP_IN_CENTER => "StepSpacing_keep_in_center",
	StepSpacing_SPACE_EVENLY   => "StepSpacing_space_evenly",

	StepAmount_EXACT => "StepAmount_exact",
	StepAmount_MAX   => "StepAmount_max",
	StepAmount_AUTO  => "StepAmount_auto",

	StepPlacementMode_AUTO   => "StepPlacementMode_Auto",
	StepPlacementMode_MANUAL => "StepPlacementMode_Manual",
	
	StepInterlock_NONE => "StepInterlock_none",
	StepInterlock_SIMPLE => "StepInterlock_simple",
	StepInterlock_SLIDING => "StepInterlock_sliding",

};

1;
