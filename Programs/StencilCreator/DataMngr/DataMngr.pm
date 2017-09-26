
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::DataMngr::DataMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::StencilCreator::Enums';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::StencilDataMngr';

 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# frm data about all steps, paste layers etc..
	$self->{"stepsSize"} = undef;
	$self->{"steps"}     = undef;
	$self->{"topExist"}  = undef;
	$self->{"botExist"}  = undef;

	# actual frm state
	$self->{"stencilType"} = undef;
	$self->{"sizeX"}       = 300;
	$self->{"sizeY"}       = 480;
	$self->{"step"}        = "o+1";
	$self->{"spacing"}     = 0;

	$self->{"spacingType"} = Enums->Spacing_PROF2PROF;

	$self->{"hCenterType"} = Enums->HCenter_BYPROF;
	$self->{"holeSize"}    = 5.1;
	$self->{"schema"}      = Enums->Schema_STANDARD;

	$self->{"holeDist"}  = undef;
	$self->{"holeDist2"} = undef;
	
	$self->{"addPcbNumber"} = 1;

	
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub Init{
	my $self = shift;
	
	$self->{"stepsSize"} = shift;
	$self->{"steps"}     = shift;
	$self->{"topExist"}  = shift;
	$self->{"botExist"}  = shift;
	
}

sub GetStencilType {
	my $self = shift;

	return $self->{"stencilType"};

}

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"stencilType"} = $type;

}


sub GetStencilSizeX {
	my $self = shift;

	return $self->{"sizeX"};

}

sub SetStencilSizeX {
	my $self = shift;
	my $size = shift;

	$self->{"sizeX"} = $size;

}

sub GetStencilSizeY {
	my $self = shift;
	my $size = shift;

	return $self->{"sizeY"};

}

sub SetStencilSizeY {
	my $self = shift;
	my $size = shift;

	$self->{"sizeY"} = $size;

}

sub GetStencilStep {
	my $self = shift;

	return $self->{"step"};
}

sub SetStencilStep {
	my $self = shift;
	my $step = shift;

	$self->{"step"} = $step;
}

sub GetSpacing {
	my $self = shift;

	return $self->{"spacing"};
}

sub SetSpacing {
	my $self    = shift;
	my $spacing = shift;

	$self->{"spacing"} = $spacing;
}

# Spacing between stencil type
# 1 - profile2profile
# 2- pad2pad
sub GetSpacingType {
	my $self = shift;

	return $self->{"spacingType"};
}

sub SetSpacingType {
	my $self = shift;
	my $type = shift;

	$self->{"spacingType"} = $type;
}

# Horiyontal aligment type
sub GetHCenterType {
	my $self = shift;

	return $self->{"hCenterType"};
}

sub SetHCenterType {
	my $self = shift;
	my $type = shift;

	$self->{"hCenterType"} = $type;
}

sub SetSchemaType {
	my $self = shift;
	my $val  = shift;

	$self->{"schema"} = $val;
}

sub GetSchemaType {
	my $self = shift;

	return $self->{"schema"};
}

sub SetHoleSize {
	my $self = shift;
	my $val  = shift;

	$self->{"holeSize"} = $val;
}

sub GetHoleSize {
	my $self = shift;
	my $val  = shift;

	return $self->{"holeSize"};
}

sub SetHoleDist {
	my $self = shift;
	my $val  = shift;

	$self->{"holeDist"} = $val;
}

sub GetHoleDist {
	my $self = shift;

	return $self->{"holeDist"};
}

sub SetHoleDist2 {
	my $self = shift;
	my $val  = shift;

	$self->{"holeDist2"} = $val;
}

sub GetHoleDist2 {
	my $self = shift;
	return $self->{"holeDist2"};
}

sub SetAddPcbNumber {
	my $self = shift;
	my $val  = shift;

	$self->{"addPcbNumber"} = $val;
}

sub GetAddPcbNumber {
	my $self = shift;
	return $self->{"addPcbNumber"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

