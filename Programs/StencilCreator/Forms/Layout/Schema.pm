
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::Layout::Schema;

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

	$self->{"type"}           = undef;
	$self->{"holeSize"}       = undef;
	$self->{"holeSpace"}      = undef;
	$self->{"holeDist2"} = undef;

	return $self;
}

sub GetHolePositions {
	my $self = shift;

	# 1) Get x positions of holes
	my @xPos = ();

	if ( $self->{"type"} eq Enums->Schema_STANDARD ) {

		my $holeCnt = int($self->{"w"} / $self->{"holeSpace"});
		
		print STDERR "Hole count $holeCnt\n";

		my $curDistL = undef;
		my $curDistR = undef;

		# center of stencil no hole
		if ( $holeCnt % 2 == 0 ) {

			$curDistL = $self->{"w"} / 2 + $self->{"holeSpace"} / 2;
			$curDistR = $self->{"w"} / 2 - $self->{"holeSpace"} / 2;
			
		}
		else {
			$curDistL = $self->{"w"} / 2;
			$curDistR = $self->{"w"} / 2;
			
			push( @xPos, $self->{"w"} / 2 );    # center hole
		}
		
		my $noHole = 1;
		while ( ( $curDistR - $self->{"holeSize"} / 2 ) < $self->{"w"}  ) {
 
 			if($noHole){
 				$noHole = 0;
 				$curDistL -= $self->{"holeSpace"};
 				$curDistR += $self->{"holeSpace"};
 				next;
 			}
 
			push( @xPos, $curDistL );                       # points from center to rigth
			push( @xPos, $curDistR );    # points from center to left
			
			$curDistL -= $self->{"holeSpace"};
			$curDistR += $self->{"holeSpace"};
 
		}
	}
#	use Data::Dump qw(dump);
#	dump(sort(@xPos));
#	 
#	
	
	# 2) Create array withi complete hole positions
	
	my @holes = ();
 
	foreach my $x (@xPos){
		
		my %top = ("x" => $x, "y" => $self->{"h"} - ($self->{"h"} - $self->GetHoleDist2())/2 );
		my %bot = ("x" => $x, "y" => ($self->{"h"} - $self->GetHoleDist2())/2   );
		
		push(@holes, (\%top, \%bot));
	}
	
	
	return @holes;
}

sub SetSchemaType {
	my $self = shift;
	my $val  = shift;

	$self->{"type"} = $val;
}

sub GetSchemaType {
	my $self = shift;

	return $self->{"type"};
}

sub SetHoleSize {
	my $self = shift;
	my $val  = shift;

	$self->{"holeSize"} = $val;
}

sub GetHoleSize {
	my $self = shift;

	return $self->{"holeSize"};
}

sub SetHoleDist {
	my $self = shift;
	my $val  = shift;

	$self->{"holeSpace"} = $val;
}

sub GetHoleDist {
	my $self = shift;

	return $self->{"holeSpace"};
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

