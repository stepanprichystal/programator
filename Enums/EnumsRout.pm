
package Enums::EnumsRout;

# represent type of DTM vzsledne/vratne holes
use constant {
			   Dir_CW  => "CW",
			   Dir_CCW => "CCW"
};

# All types of rout compensation
use constant {
			   Comp_LEFT  => "left",
			   Comp_RIGHT => "right",
			   Comp_NONE  => "none",
			   Comp_CW    => "cw",
			   Comp_CCW   => "ccw"
};

# Types of outline rout start area (corner)
use constant {
	OutlineStart_LEFTTOP  => "outlineStart_LeftTop",
	OutlineStart_RIGHTTOP => "outlineStart_RightTop",

};

# type of rout sequence
use constant {
			   SEQUENCE_BTRL => 'routSequence_BTRL',    # From BOT -> TOP -> RIGHT -> LEFT
			   SEQUENCE_BTLR => 'routSequence_BTLR',    # From BOT -> TOP -> LEFT -> RIGHT
};
1;

