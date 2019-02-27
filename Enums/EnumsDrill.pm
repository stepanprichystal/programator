
package Enums::EnumsDrill;

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

# Each tool has specified operation which is based on layer type and tool type (slot/hole)
# Based on this parameter, rout tool speed can be calculated or default tool magazine selected
use constant {
			   ToolOp_PLATEDDRILL    => "PlatedDrill",
			   ToolOp_PLATEDROUT     => "PlatedRout",
			   ToolOp_NPLATEDROUT    => "NPlatedRout",
			   ToolOp_NPLATEDDRILL   => "NPlatedDrill",
			   ToolOp_ROUTBEFOREETCH => "RoutBeforeEtch",
			   ToolOp_ROUTBEFOREET   => "RoutBeforeET",
			   ToolOp_PREPREGROUT    => "PrepregRout",
			   ToolOp_COVERLAYROUT   => "CoverlayRout",
};

1;

