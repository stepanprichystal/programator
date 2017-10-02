
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::DataMngr::StencilDataMngr::Schema;

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
	
	$self->{"dataMngr"} = shift;
	$self->{"type"}           = shift;
 
	$self->{"w"} = $self->{"dataMngr"}->GetStencilSizeX();
	$self->{"h"} = $self->{"dataMngr"}->GetStencilSizeY();
  
	return $self;
}

sub GetHolePositions {
	my $self = shift;

	# 1) Get x positions of holes
	my @xPos = ();

	if ( $self->{"dataMngr"}->GetSchemaType() eq Enums->Schema_STANDARD ) {

		my $holeCnt = int($self->{"w"} / $self->{"dataMngr"}->GetHoleDist());
		
		print STDERR "Hole count $holeCnt\n";

		my $curDistL = undef;
		my $curDistR = undef;

		# center of stencil no hole
		if ( $holeCnt % 2 == 0 ) {

			$curDistL = $self->{"w"} / 2 + $self->{"dataMngr"}->GetHoleDist() / 2;
			$curDistR = $self->{"w"} / 2 - $self->{"dataMngr"}->GetHoleDist() / 2;
			
		}
		else {
			$curDistL = $self->{"w"} / 2;
			$curDistR = $self->{"w"} / 2;
			
			push( @xPos, $self->{"w"} / 2 );    # center hole
		}
		
		my $noHole = 1;
		while ( ( $curDistR - $self->{"dataMngr"}->GetHoleSize() / 2 ) < $self->{"w"}  ) {
 
 			if($noHole){
 				$noHole = 0;
 				$curDistL -= $self->{"dataMngr"}->GetHoleDist();
 				$curDistR += $self->{"dataMngr"}->GetHoleDist();
 				next;
 			}
 
			push( @xPos, $curDistL );                       # points from center to rigth
			push( @xPos, $curDistR );    # points from center to left
			
			$curDistL -= $self->{"dataMngr"}->GetHoleDist();
			$curDistR += $self->{"dataMngr"}->GetHoleDist();
 
		}
	}
#	use Data::Dump qw(dump);
#	dump(sort(@xPos));
#	 
#	
	
	# 2) Create array withi complete hole positions
	
	my @holes = ();
 
	foreach my $x (@xPos){
		
		my %top = ("x" => $x, "y" => $self->{"h"} - ($self->{"h"} - $self->{"dataMngr"}->GetHoleDist2())/2 );
		my %bot = ("x" => $x, "y" => ($self->{"h"} - $self->{"dataMngr"}->GetHoleDist2())/2   );
		
		push(@holes, (\%top, \%bot));
	}
	
	
	return @holes;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

