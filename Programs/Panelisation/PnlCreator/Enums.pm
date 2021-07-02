
package Programs::Panelisation::PnlCreator::Enums;


# Panelisation types based on panel
use constant {
			   PnlType_PRODUCTIONPNL => "type_ProductionPnl",
			   PnlType_CUSTOMERPNL   => "type_CustomerPnl"
};



# Panelisation part types
use constant {

	# Profile creators
	SizePnlCreator_USER      => "SizePnlCreator_User", # panel + mpanel
	SizePnlCreator_HEG       => "SizePnlCreator_Heg", # panel + mpanel
	SizePnlCreator_MATRIX    => "SizePnlCreator_Matrix", # mpanel
	SizePnlCreator_CLASSUSER => "SizePnlCreator_ClassUser", # panel + mpanel
	SizePnlCreator_CLASSHEG  => "SizePnlCreator_ClassHeg", # panel + mpanel
	SizePnlCreator_PREVIEW   => "SizePnlCreator_Preview", # panel + mpanel

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
 
	StepAmount_EXACT => "StepAmount_exact",
	StepAmount_MAX   => "StepAmount_max",
	StepAmount_AUTO  => "StepAmount_auto",

	StepPlacementMode_AUTO   => "StepPlacementMode_Auto",
	StepPlacementMode_MANUAL => "StepPlacementMode_Manual",
	
 

};

1;
