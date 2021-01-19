
package Packages::CAM::UniRTM::Enums;

 
# Type of features which are assigned to UniChainSequence
use constant {
	FeatType_SURF => "featureTypeSurf",
	FeatType_LINEARC => "featureTypeLineArc"
};
 
# Type of outline rout
# Type 1: Standard PCB routed with standard tools
# - direction: CW
# - rout comp: LEFT
# Type 2: Flex PCB; Hybrid PCB routed with one-flute rout tools
# - direction: CCW
# - rout comp: Right
use constant {
	OutlineType_CWLEFT => "outlineTypeCWLeft",
	OutlineType_CCWRIGHT => "outlineTypeCCWRight"
};
 
 
1;
