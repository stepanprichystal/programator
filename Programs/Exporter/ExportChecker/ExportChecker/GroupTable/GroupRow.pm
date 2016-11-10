
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupRow;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"tableRef"} = shift;

	#require rows in nif section
	my @cells = ();
	$self->{"cells"} = \@cells;

	return $self;
}

sub AddCell {
	my $self      = shift;
	my $unit = shift;
	my $width = shift;
	
	my @allUnits = $self->{"tableRef"}->GetAllUnits();
	my $tabOrderNum = $self->{"tableRef"}->GetOrderNumber();
	
	
	$unit->SetCellWidth($width);
 	$unit->SetExportOrder($tabOrderNum + scalar(@allUnits));
 	
	push( @{$self->{"cells"}}, $unit );

	return $unit;

}

sub GetCells {
	my $self = shift;

	return @{ $self->{"cells"} };

}

#sub GetHeight {
#	my $self = shift;
#
#	my $max = 0;
#
#	foreach my $cell ( @{ $self->{"cells"} } ) {
#
#		#cell is type of panel
#
#		#my $m = $cell->GetGroupHeight();
#
#		 
#		#print "Vyska je:".$m->GetHeight()."\n";
#		#print $m{"Height"};
#		#print $m{"y"};
#		#print $m{"Y"};
#
#		my  $height  = $cell->{"form"}->{"groupHeight"};
#		
#		
#		my ($w, $h ) = $cell->{"form"}->GetSizeWH();
#		
#		print "Height = ".$h."\n";
#		
#		#my $height = $h;
#
#		if ( $height > $max ) {
#			$max = $height;
#		}
#
#	}
#
#	return $max;
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

