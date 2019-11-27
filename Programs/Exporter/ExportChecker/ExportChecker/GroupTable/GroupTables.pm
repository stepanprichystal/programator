
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
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTable';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	my @tables = ();
	$self->{"groupTables"} = \@tables;
	
	$self->{"defaultSelected"} = undef; # Default selected table

	return $self;
}

sub AddTable {
	my $self = shift;
	my $title = shift;
	
	my $tabCnt = scalar(@{$self->{"groupTables"}});
	
	my $table = GroupTable->new($title, $tabCnt + 1);

	push( @{ $self->{"groupTables"} }, $table );
 
 	return $table;
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


sub GetDefaultSelected{
	my $self = shift;

	return $self->{"defaultSelected"};
}

sub SetDefaultSelected{
	my $self = shift;
	my $table = shift;
	
	$self->{"defaultSelected"} = $table;
	
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

