
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables;

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

	my @tables = ();
	$self->{"groupTables"} = \@tables;

	return $self;
}

sub AddTable {
	my $self = shift;
	my $table  = shift;

	push( @{ $self->{"groupTables"} }, $table );
 
}
 
 
sub GetTables{
	my $self = shift;

	return @{ $self->{"groupTables"} };
} 
 
sub GetAllUnits{
	my $self = shift;
	
	my @all = ();
	
	foreach my $t (@{ $self->{"groupTables"} }){
		
		push(@all, $t->GetAllUnits());
	}

	return @all;
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

