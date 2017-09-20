
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::DataMngr::StencilDataMngr::StencilDataMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"w"} = undef;
	$self->{"h"} = undef;

	$self->{"stencilType"} = undef;
	$self->{"topProf"}     = undef;
	$self->{"botProf"}     = undef;
	$self->{"spacing"}     = undef;
	$self->{"spacingType"} = undef;
	$self->{"centerType"}  = undef;
	$self->{"schema"} = undef;

	$self->{"init"} = 0;

	return $self;
}

sub Inited {
	my $self = shift;
	my $val  = shift;

	$self->{"init"} = $val;

	if ( $self->{"init"} ) {
		$self->__RotateStencil();
	}

}

sub GetTopProfilePos {
	my $self = shift;

	my %pos = ( "x" => 0, "y" => 0 );

	$pos{"x"} = $self->__GetTopProfilePosX();
	$pos{"y"} = $self->__GetTopProfilePosY();

	return %pos;
}

sub GetBotProfilePos {
	my $self = shift;

	my %pos = ( "x" => 0, "y" => 0 );

	$pos{"x"} = $self->__GetBotProfilePosX();
	$pos{"y"} = $self->__GetBotProfilePosY();

	return %pos;
}

sub GetTopDataPos {
	my $self = shift;

	my %pos = $self->GetTopProfilePos();

	$pos{"x"} += $self->{"topProf"}->GetPDOrigin->{"x"};
	$pos{"y"} += $self->{"topProf"}->GetPDOrigin->{"y"};

	return \%pos;
}

sub GetBotDataPos {
	my $self = shift;

	my %pos = $self->GetTopProfilePos();

	$pos{"x"} += $self->{"botProf"}->GetPDOrigin->{"x"};
	$pos{"y"} += $self->{"botProf"}->GetPDOrigin->{"y"};

	return \%pos;
}

sub GetDefaultSpacing{
	my $self = shift;
	
	my $spacing = 0;
	# rotate stencils in order compute properlz default spacing
	if ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {
 
		my $sch = $self->GetSchema();
		
		if($sch->GetSchemaType() eq Enums->Schema_STANDARD){
			$spacing = ($sch->GetHoleDist2() - $self->GetTopProfile()->GetHeight() -  $self->GetBotProfile()->GetHeight())/3;
		
		
		}else{
			
			$spacing = ($sch->GetHeight() - $self->GetTopProfile()->GetHeight() -  $self->GetBotProfile()->GetHeight())/3;
		}
		
	} 
	
	return $spacing;
}


#-------------------------------------------------------------------------------------------#
#  Set Layout properties
#-------------------------------------------------------------------------------------------#

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"stencilType"} = $type;

}

sub GetStencilType {
	my $self = shift;
	my $type = shift;

	return $self->{"stencilType"};
}

sub SetTopProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"topProf"} = $top;

}

sub GetTopProfile {
	my $self = shift;

	return $self->{"topProf"};
}

sub SetBotProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"botProf"} = $top;

}

sub GetBotProfile {
	my $self = shift;

	return $self->{"botProf"};
}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

sub SetHeight {
	my $self   = shift;
	my $height = shift;

	$self->{"h"} = $height;
}

sub GetSpacing {
	my $self = shift;

	return $self->{"spacing"};
}

sub SetSpacing {
	my $self = shift;
	my $val  = shift;

	$self->{"spacing"} = $val;

}

sub SetSpacingType {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingType"} = $val;

}

sub GetSpacingType {
	my $self = shift;

	return $self->{"spacingType"};
}

sub SetHCenterType {

	my $self = shift;
	my $type = shift;

	$self->{"centerType"} = $type;

}


sub GetSchema {
	my $self = shift;

	return $self->{"schema"};
}

sub SetSchema {
	my $self = shift;
	my $val = shift;

	$self->{"schema"} = $val;

}
#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __GetTopProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"centerType"} eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"centerType"} eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"topProf"}->GetPDOrigin()->{"x"};
	}

	return $posX;
}

sub __GetTopProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();

	# Single paste data
	if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

		$posY = ( $self->{"h"} - $self->{"topProf"}->GetHeight() ) / 2;
	}

	# Merged paste data
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY = $spacing / 2 + $self->{"h"} / 2;
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY = $spacing / 2 - $self->{"topProf"}->GetPDOrigin->{"y"} + $self->{"h"} / 2;
		}
	}

	return $posY;
}

sub __GetBotProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"centerType"} eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"centerType"} eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"botProf"}->GetPDOrigin->{"x"};
	}

	return $posX;
}

sub __GetBotProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();

	# Single paste data
	if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

		$posY = ( $self->{"h"} - $self->{"botProf"}->GetHeight() ) / 2;
	}

	# Merged paste data
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY = $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetHeight();
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY =
			  $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetPasteData()->GetHeight() - $self->{"botProf"}->GetPDOrigin()->{"y"};
		}
	}

	return $posY;
}

# Find new roattion of paste profile
sub __RotateStencil {
	my $self = shift;

	unless ( $self->{"init"} ) {
		return 0;
	}

	# difference of length in percentage between profile height and width
	my $diffTop = abs( $self->{"topProf"}->GetHeight() - $self->{"topProf"}->GetWidth() ) / $self->{"topProf"}->GetHeight();

	# difference of length in percentage between profile height and width
	my $diffBot = abs( $self->{"botProf"}->GetHeight() - $self->{"botProf"}->GetWidth() ) / $self->{"botProf"}->GetHeight();

	if ( $self->{"stencilType"} eq Enums->StencilType_TOP ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth() ? "h" : "w";
		if ( $lSide ne $lProfSide && $diffTop > 0.1 ) {
			$self->{"topProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"stencilType"} eq Enums->StencilType_BOT ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth() ? "h" : "w";

		if ( $lSide ne $lProfSide && $diffBot > 0.1 ) {
			$self->{"botProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {

		if ( $self->{"topProf"} ) {

			my $lSide     = $self->GetHeight()/2 > $self->GetWidth() ? "h" : "w";
			my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth()     ? "h" : "w";

			if ( $lSide ne $lProfSide && $diffTop > 0.1 ) {
				$self->{"topProf"}->SwitchDim();
				print STDERR "switch profile\n";
			}
		}

		if ( $self->{"botProf"} ) {

			my $lSide     = $self->GetHeight()/2 > $self->GetWidth() ? "h" : "w";
			my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth()     ? "h" : "w";

			if ( $lSide ne $lProfSide && $diffBot > 0.1 ) {
				$self->{"botProf"}->SwitchDim();
				print STDERR "switch profile\n";
			}
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

