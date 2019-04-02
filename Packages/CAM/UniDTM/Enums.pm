
package Packages::CAM::UniDTM::Enums;


 
# Tell if tool comes from surface, or standard DTM
# tell, if tool is used for chain or hole
use constant {
	Source_DTM => "sourceDTM",
	Source_DTMSURF => "sourceDTMsurf",
};


# Type, which contain tools in standard DTM slot/hole
use constant {
	TypeTool_HOLE => "hole",
	TypeTool_SLOT => "slot"
};

 
 
 
1;
