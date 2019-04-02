
package Enums::EnumsDrill;

 
# Type, which is used mainlz ion hooks
# tell, if tool is used for chain or hole
use constant {
	TypeProc_HOLE => "hole",
	TypeProc_CHAIN => "chain"
};

# represent type of DTM vzsledne/vratne holes
use constant {
			   DTM_VRTANE   => "vrtane",
			   DTM_VYSLEDNE => "vysledne"
};

# represent names of DTM user column
use constant {
			   DTMclmn_DEPTH   => "depth",
			   DTMclmn_MAGINFO => "magazine_info"
};

# represent names of DTM surface user attributes
use constant {
			   DTMatt_DEPTH   => "tool_depth",
			   DTMatt_MAGINFO => "tool_magazine_info"
};

# Each tool has specified operation which is based on:
# - JOB NC layer type (set by CamDrilling->AddNCLayerType)
# - tool type (slot/hole)
# - plated/nonplated  (set by CamDrilling->AddNCLayerType)
# Rout tool speed can be calculated or default tool magazine selected based on this operation name
# See function CamHelpers::CamDrilling::GetToolOperation()
use constant {
			   ToolOp_PLATEDDRILL    => "PlatedDrill",
			   ToolOp_PLATEDROUT     => "PlatedRout",
			   ToolOp_NPLATEDDRILL   => "NPlatedDrill",
			   ToolOp_NPLATEDROUT    => "NPlatedRout",
			   ToolOp_ROUTBEFOREETCH => "RoutBeforeEtch",
			   ToolOp_ROUTBEFOREET   => "RoutBeforeET",
			   ToolOp_PREPREGROUT    => "PrepregRout",
			   ToolOp_COVERLAYROUT   => "CoverlayRout",
};

1;

