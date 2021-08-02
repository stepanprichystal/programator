
package Programs::Panelisation::PnlCreator::Enums;

# Panelisation types based on panel
use constant {
			   PnlType_PRODUCTIONPNL => "type_ProductionPnl",
			   PnlType_CUSTOMERPNL   => "type_CustomerPnl"
};

# Panelisation part types
use constant {

	# Profile creators
	SizePnlCreator_USER      => "SizePnlCreator_User",         # panel + mpanel
	SizePnlCreator_HEG       => "SizePnlCreator_Heg",          # panel + mpanel
	SizePnlCreator_MATRIX    => "SizePnlCreator_Matrix",       # mpanel
	SizePnlCreator_CLASSUSER => "SizePnlCreator_ClassUser",    # panel + mpanel
	SizePnlCreator_CLASSHEG  => "SizePnlCreator_ClassHeg",     # panel + mpanel
	SizePnlCreator_PREVIEW   => "SizePnlCreator_Preview",      # panel + mpanel

	# Step placement creaotrs
	StepPnlCreator_CLASSUSER => "StepPnlCreator_ClassUser",
	StepPnlCreator_CLASSHEG  => "StepPnlCreator_ClassHeg",
	StepPnlCreator_MATRIX   => "StepPnlCreator_Matrix",
	StepPnlCreator_SET      => "StepPnlCreator_Set",
	StepPnlCreator_PREVIEW  => "StepPnlCreator_Preview",

	# Coupon placement creaotrs
	CpnPnlCreator_SEMIAUTO => "CpnPnlCreator_Semiauto",

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
	
	PCBStepProfile_STANDARD => "PCBStepProfile_Standard",
	PCBStepProfile_CVRLPINS => "PCBStepProfile_Cvrlpins",

};

# Cpn creator setting enums
use constant {

	# Impedanc coupon types

	#   -
	# |   |
	#   -
	# |   |
	#   -
	ImpCpnType_1 => "ImpCpnType_1",

	#
	# |   |
	#   -
	# |   |
	#
	ImpCpnType_2 => "ImpCpnType_2",

	#   -
	#
	#   -
	#
	#   -
	ImpCpnType_3 => "ImpCpnType_3",

	#   -
	# |   |
	#
	# |   |
	#   -
	ImpCpnType_4 => "ImpCpnType_4",

	#
	# |   |
	#
	# |   |
	#
	ImpCpnType_5 => "ImpCpnType_5",

	#   -
	#
	#
	#
	#   -
	ImpCpnType_6 => "ImpCpnType_6",

	# IPC3 coupon types

	#
	# |   |
	#  - -
	# |   |
	#
	IPC3CpnType_1 => "IPC3CpnType_1",

	#  - -
	#
	#  - -
	#
	#  - -
	IPC3CpnType_2 => "IPC3CpnType_2",
	
	#  
	#
	#  - - -
	#
	#  
	IPC3CpnType_3 => "IPC3CpnType_3",

	#  - -
	#
	#
	#
	#  - -
	IPC3CpnType_4 => "IPC3CpnType_4",

	#
	# |   |
	#
	# |   |
	#
	IPC3CpnType_5 => "IPC3CpnType_5",

	# ZAxis coupon types

	# |||||
	# 
	# |||||
	# 
	# |||||
	ZAxisCpnType_1 => "ZAxisCpnType_1",
	
 
	#  |||||
	#
	#
	#
	#  |||||
	ZAxisCpnType_2 => "ZAxisCpnType_2",

	#  |   |
	#  |   |
	#  |   |
	#  |   |
	#  |   |
	ZAxisCpnType_3 => "ZAxisCpnType_3",
	
	#
	#
	# |||||
	#
	#
	ZAxisCpnType_4 => "ZAxisCpnType_4",
	
	# |||||
	#
	# 
	#
	#
	ZAxisCpnType_5 => "ZAxisCpnType_5",
	
	#      |
	#      |
	#      |
	#      |
	#      |
	ZAxisCpnType_6 => "ZAxisCpnType_6",

	CpnPlacementMode_AUTO   => "CpnPlacementMode_Auto",
	CpnPlacementMode_MANUAL => "CpnPlacementMode_Manual",

};

1;
