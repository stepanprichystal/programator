
#-------------------------------------------------------------------------------------------#
# Description: Contain stencil parameters prepared in stencil creator
# Class is serializable by stencil serializer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilSerializer::StencilParams;
 
#3th party library
use strict;
use warnings;


#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self; 
}
 
# ----------------------------------------------------
# General stencil information 
# ----------------------------------------------------
# Stencil source step
sub GetStencilStep {
	my $self = shift;

	return $self->{"data"}->{"stencilStep"};

}

sub SetStencilStep {
	my $self = shift;
	my $type = shift;

	$self->{"data"}->{"stencilStep"} = $type;

}
 
# Stencil type TOP/BOT/TOP+BOT
sub GetStencilType {
	my $self = shift;

	return $self->{"data"}->{"stencilType"};

}

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"data"}->{"stencilType"} = $type;

}

# Width of stencil
sub GetStencilSizeX {
	my $self = shift;

	return $self->{"data"}->{"sizeX"};

}

sub SetStencilSizeX {
	my $self = shift;
	my $size = shift;

	$self->{"data"}->{"sizeX"} = $size;

}

# Height of stencil
sub GetStencilSizeY {
	my $self = shift;
	my $size = shift;

	return $self->{"data"}->{"sizeY"};

}

sub SetStencilSizeY {
	my $self = shift;
	my $size = shift;

	$self->{"data"}->{"sizeY"} = $size;
}




# Add pcb number 0/1
sub SetAddPcbNumber {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"addPcbNumber"} = $val;
}

sub GetAddPcbNumber {
	my $self = shift;
	return $self->{"data"}->{"addPcbNumber"};
}

# position of left down corner of pcb profile
# conatain hash ref
# "x" => 
# "y" => 
sub SetTopProfilePos {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"topProfPos"} = $val;
}

sub GetTopProfilePos {
	my $self = shift;
	
	return $self->{"data"}->{"topProfPos"};
}

# position of left down corner of pcb profile
# conatain hash ref
# "x" => 
# "y" => 
sub SetBotProfilePos {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"botProfPos"} = $val;
}

sub GetBotProfilePos {
	my $self = shift;
	
	return $self->{"data"}->{"botProfPos"};
}


# dimension of active area
# conatain hash ref
# "w" => 
# "h" => 
sub SetStencilActiveArea {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"activeArea"} = $val;
}

sub GetStencilActiveArea {
	my $self = shift;
	
	return $self->{"data"}->{"activeArea"};
}



# ----------------------------------------------------
# Pcb placing information
# ----------------------------------------------------
 
# contain hash reference with info
# "isRotated" => 1/0
# "height" => 
# "width" => 
# "pasteData" => hash (height, width)
# "pasteDataPos" => hash (x, y) relative to profile pos
sub SetTopProfile {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"topProf"} = $val;
} 
 
sub GetTopProfile {
	my $self = shift;

	return $self->{"data"}->{"topProf"};
}

# contain hash reference with info
# "isRotated" => 1/0
# "height" => 
# "width" => 
# "pasteData" => hash (height, width)
# "pasteDataPos" => hash (x, y) relative to profile pos
sub SetBotProfile {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"botProf"} = $val;
} 

sub GetBotProfile {
	my $self = shift;

	return $self->{"data"}->{"botProf"};
}
 
# Information about stencil source data
# sourceType => sourceJob/sourceCustomerData
# sourceJob => jobId
# sourceJobIsPool => 1/0
sub SetDataSource {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"isPool"} = $val;
} 

sub GetDataSource {
	my $self = shift;

	return $self->{"data"}->{"isPool"};
} 
 
# ----------------------------------------------------
# Schema information
# ---------------------------------------------------- 
 
 # contain hash reference with info
# "holePositions" => array ref
# "holeSize" => int
# "type" => holes/vlepeni/inslucded
 sub SetSchema {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"schema"} = $val;
}

sub GetSchema {
	my $self = shift;
	
	return $self->{"data"}->{"schema"};
}

# ----------------------------------------------------
# Extra information - not from Stencil creator, but from ExportChecker settings
# ---------------------------------------------------- 
  # contain hash reference with info
# "halfFiducials" => 1/0
# "fiducSide" => "readable/nonreadable"
 sub SetFiducial {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"fiducials"} = $val;
}

sub GetFiducial {
	my $self = shift;
	
	return $self->{"data"}->{"fiducials"};
}
 
 
# Stencil thickness
 sub SetThickness {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"thickness"} = $val;
}

sub GetThickness {
	my $self = shift;
	
	return $self->{"data"}->{"thickness"};
}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

