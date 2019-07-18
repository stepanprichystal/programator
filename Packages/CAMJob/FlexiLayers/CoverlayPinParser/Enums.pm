
package Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums;

# Enums of .string feature attribute values
# Each feature in "coverlaypin" layer contain one of these value in .string attribute.
use constant {

	PinString_REGISTER   => "pin_register",      # pad which is used for register coverlay with flex core
	PinString_SOLDERLINE => "pin_solderline",    # between PinString_SOLDERPIN and PinString_CUTPIN lines is place for soldering
	PinString_CUTLINE    => "pin_cutline",       # this line marks the area where coverlaz pin should be cutted
	PinString_ENDLINE    => "pin_endline",       # line marks end border of pin
	PinString_SIDELINE1  => "pin_sideline1",     # lines mark side border of pin
	PinString_SIDELINE2  => "pin_sideline2",     # lines mark connection line between PinString_BENDLINE and PinString_SIDELINE1
	PinString_BENDLINE   => "pin_bendline"       # lines marks border of bend area
};

1;
