
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::Layout::PasteProfile;

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

	$self->{"w"} = shift;
	$self->{"h"} = shift;

	$self->{"stencilType"} = undef;
	$self->{"topProf"}     = undef;
	$self->{"botProf"}     = undef;
	$self->{"spacing"}     = undef;
	$self->{"spacingType"} = undef;

	return $self;
}

sub SetWidth{
	my $self = shift;
	my $width = shift;
	
	$self->{"w"} = $width;
	
	$self->__RotateStencil();
}

sub SetHeight{
	my $self = shift;
	my $height = shift;
	
	$self->{"h"} = $height;
	
	$self->__RotateStencil();
}

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"stencilType"} = $type;
	
	$self->__RotateStencil();

}

sub GetTopProfilePos {
	my $self = shift;

	my %pos = ( "x" => 0, "y" => 0 );

	my $spacing     = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();

	# profile to profile
	if ( $spacingType eq Enums->Spacing_PROF2PROF ) {
		$pos{"x"} = ( $self->{"w"} - $self->{"topProf"}->GetWidth() ) / 2;

		# compute position with actual spacing
		if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

			$pos{"y"} = ( $self->{"h"} - $d{"topPcb"}->{"h"} ) / 2;

		}

		if ( $typeVal eq "both" ) {

			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $self->{"topProf"}->GetWidth() ) / 2;
			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 + $spacing / 2;
			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 - ( $spacing / 2 + $d{"botPcb"}->{"h"} );

		}

		# centre pcb vertical
		elsif ( $typeVal eq "top" ) {

			$d{"topPcb"}->{"posX"} = ( $d{"w"} - $d{"topPcb"}->{"w"} ) / 2;
			$d{"topPcb"}->{"posY"} = $d{"h"} / 2 - ( $d{"topPcb"}->{"h"} / 2 );

		}
		elsif ( $typeVal eq "bot" ) {

			$d{"botPcb"}->{"posX"} = ( $d{"w"} - $d{"botPcb"}->{"w"} ) / 2;
			$d{"botPcb"}->{"posY"} = $d{"h"} / 2 - ( $d{"botPcb"}->{"h"} / 2 );
		}
	}

}

sub SetTopProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"topProf"} = $top;
}

sub SetBotProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"topProf"} = $top;
}

sub SetSpacing {
	my $self = shift;
	my $val  = shift;

	$self->{"spacing"} = $val;
	
	$self->__RotateStencil();

}

sub SetSpacingType {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingType"} = $val;
	
	$self->__RotateStencil();

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

# Find new roattion of paste profile
sub __RotateStencil {
	my $self = shift;

	if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

			my $lSide = $self->GetHeight()/2 >   $self->GetWidth() ? "h" : "w";
 
			my $lProfSide = $self->{"topProf"}->GetHeight() >   $self->{"topProf"}->GetWidth() ? "h" : "w";
			
			if($lSide ne $lProfSide){
				$self->{"topProf"}->SwitchDim();
				$self->{"botProf"}->SwitchDim();
				
				print STDERR "switch profile\n";
			}
	}
	else {

		if ( $self->{"topProf"} ) {

			if ( $self->{"topProf"}->GetWidth() > $self->{"topProf"}->GetHeight() ) {
				$self->{"topProf"}->SwitchDim();
				
				 print STDERR "switch profile\n";
			}
		}

		if ( $self->{"botProf"} ) {

			if ( $self->{"botProf"}->GetWidth() > $self->{"botProf"}->GetHeight() ) {
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

