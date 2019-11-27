
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTable;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupRow';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
 
	$self->{"title"} = shift;
	$self->{"order"} = shift;

	#require rows in nif section
	my @rows = ();
	$self->{"rows"} = \@rows;

	return $self;
}

sub GetTitle{
	my $self = shift;
	return $self->{"title"};
}

sub GetOrderNumber{
	my $self = shift;
	return $self->{"order"};
}

sub AddRow {
	my $self = shift;
	
	my $row  = GroupRow->new($self);
	
	push( @{ $self->{"rows"} }, $row );
	
	return $row;
}

sub GetRows {
	my $self = shift;

	return @{ $self->{"rows"} };
}

sub GetTab {
	my $self = shift;

	return $self->{"tab"};
}


sub GetAllUnits {
	my $self = shift;

	my @allCells = ();

	foreach my $row ( @{ $self->{"rows"} } ) {

		my @cells = $row->GetCells();

		foreach my $cell (@cells) {

			push( @allCells, $cell );
		}
	}

	return @allCells;
}


 

#sub GetTableForm {
#	my $self = shift;
#	#$tableForm is panel
#	my $tableForm = GroupTableForm->new( $self->{"parent"} );
#	$tableForm->Init( $self->{"rows"} );
#
#}

#sub GetHeight {
#	my $self = shift;
#
#	my $height = 0;
#
#	foreach my $row ( @{ $self->{"rows"} } ) {
#
#		#cell is type of panel
#		my $rowHeight = $row->GetHeight();
#
#		$height += $rowHeight;
#
#	}
#
#	return $height;
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

