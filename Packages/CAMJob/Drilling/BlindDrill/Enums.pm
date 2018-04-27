
package Packages::CAMJob::Drilling::BlindDrill::Enums;


use constant {
			   MIN_ISOLATION    => 50,    # Size of isolation from end of peak to next isolated Cu lazer. Minimum = 50µm
			   DRILL_TOLERANCE  => 15,    # Tolerance of blind drilling 15µm
			   DRILL_TOOL_ANGLE => 130    # Angle of blind drill tools. Standard 130°
};

# Blind drill type from "Calculation Blind Vias with concical tool" document
use constant {
			   BLINDTYPE_STANDARD => "blindType_standard",           # Cylindrical part of tool ends at the middle of landing Cu (TYPE 1)
			   BLINDTYPE_SPECIAL  => "blindType_special"    # Concical part of tool is half way through the landing Cu (TYPE 2)
};


# return human readable name for blind drill computation methods
sub GetMethodName{
	my $self = shift;
	my $code = shift;
	
	my $name = undef;
	
	if($code eq BLINDTYPE_STANDARD){
		
		$name = "Type 1 (standard)";
	}elsif($code eq BLINDTYPE_SPECIAL){
		
		$name = "Type 2 (special)";
	}
	
	return $name;
}

1;

