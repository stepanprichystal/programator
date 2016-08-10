
#-------------------------------------------------------------------------------------------#
# Description: Structure represent one section in NIF file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifSection;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#name of section
	$self->{"name"} = shift; 

	#rows in section
	my @rows = (); 
	$self->{"rows"} = \@rows;
	
	#Events
	$self->{'onRowResult'} = Event->new();

	return $self;
}


# add new row to this section. If value is "undef", it is 
# considered as error occured during attemting this row value
sub AddRow {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;

	unless ( defined $value ) {
		
		my $mess = "Error when load value. Nif section: ".$self->{"name"}.", row name: ".$name.".";
		
		$self->__OnRowResult($mess);
		
		$value = "";
	}

	my %row = ( "type" => "row", "name" => $name, "value" => $value );
	push( @{ $self->{"rows"} }, \%row );

}

sub AddComment {
	my $self  = shift;
	my $value = shift;

	unless ( defined $value ) {
		$value = "";
	}

	my %row = ( "type" => "comment", "value" => $value );
	push( @{ $self->{"rows"} }, \%row );

}

sub GetName {
	my $self = shift;

	return $self->{"name"};
}

sub GetRows {
	my $self = shift;

	my @rows = ();

	foreach my $r ( @{ $self->{"rows"} } ) {

		if ( $r->{"type"} eq "row" ) {
					
			push( @rows, $r->{"name"} . "=" . $r->{"value"} );

		}
		elsif ( $r->{"type"} eq "comment" ) {
			my $comment = $r->{"value"};
			$comment =~ s/^\s+|\s+$//g;
			push( @rows, "\n* " . $comment . " *" );
		}

	}

	return @rows;
}


sub __OnRowResult {
	my $self       = shift;
	my $rowResult = shift;

	#raise onRowResult event
	$self->{'onRowResult'}->Do($rowResult);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

