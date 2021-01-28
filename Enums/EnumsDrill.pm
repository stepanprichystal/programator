
package Enums::EnumsDrill;

# Type, which is used mainlz ion hooks
# tell, if tool is used for chain or hole
use constant {
			   TypeProc_HOLE  => "hole",
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

# Type, which contain tools in standard DTM slot/hole
use constant {
			   TypeTool_HOLE => "hole",
			   TypeTool_SLOT => "slot"
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
			   ToolOp_TAPEROUT       => "TapeRout",
};

# Material codes for hybrid materials
# This code clearly describes which materials are combined together
# Code is used for:
# - parameters files filename
# - choosing right tool magazine
# WARNING:
# - Do not use dashes in constant values
#  (we want to constant name was as same as constant values, and dash is not alowed in constant name)
# - If constant values is changed, all filenames has to be ranamed to
use constant {
			   HYBRID_PYRALUX__FR4  => 'HYBRID_PYRALUX-FR4',
			   HYBRID_THINFLEX__FR4 => 'HYBRID_THINFLEX-FR4',
			   HYBRID_RO3__FR4      => 'HYBRID_RO3-FR4',
			   HYBRID_RO4__FR4      => 'HYBRID_RO4-FR4',
			   HYBRID_R58X0__FR4    => 'HYBRID_R58X0-FR4',
			   HYBRID_ITERA__FR4    => 'HYBRID_ITERA-FR4'
};

# Possible types of via filling from inner/outer placement point of view
#- ViaFill_OUTER => Via fill drilling which start/end on outer layers of stackup (c;s layer)
#- ViaFill_INNER   => Via fill drilling which start/end inside stackup (v\d layer)
use constant {
			   ViaFill_OUTER => "viaFillTopThrough",
			   ViaFill_INNER => "viaFillTopBlind"
};

1;

