
#-------------------------------------------------------------------------------------------#
# Description:  Class represent universal tool regardless it is tool from surface, pad, slot..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniTool::UniToolDTM;
use base("Packages::CAM::UniDTM::UniTool::UniToolBase");

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;
 
	# Type, which contain tools in standard DTM
	$self->{"typeTool"} = undef;    # TypeTool_HOLE/TypeTool_SLOT
	
	$self->{"toolNumber"} = undef; # Order of num, resp tool D-Code

	# Types based on purpose
	$self->{"typeUse"} = undef;     # plate/nplate/pressfit/via

	$self->{"finishSize"} = undef;  # finish size of tool
	

 
	return $self;
}

# Check if depth value is set correctly
sub DepthIsOk {
	my $self = shift;

	# depth is in mm, so assume range > 0 and  < 10 mm
	my $depth = $self->GetDepth();

	if ( $depth <= 0 || $depth >= 10 || $depth eq "" ) {
		return 0;
	}
	else {
		return 1;
	}
}

# GET SET property

sub SetTypeTool {
	my $self = shift;

	$self->{"typeTool"} = shift;
}

sub GetTypeTool {
	my $self = shift;

	return $self->{"typeTool"};
}

sub SetTypeUse {
	my $self = shift;

	$self->{"typeUse"} = shift;
}

sub GetTypeUse {
	my $self = shift;

	return $self->{"typeUse"};
}

sub GetFinishSize {
	my $self = shift;

	return $self->{"finishSize"};
}

sub SetFinishSize {
	my $self = shift;

	$self->{"finishSize"} = shift;
}


sub GetToolNum {
	my $self = shift;

	return $self->{"toolNumber"};
}

sub SetToolNum {
	my $self = shift;

	$self->{"toolNumber"} = shift;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

