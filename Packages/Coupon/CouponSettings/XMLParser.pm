
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::XMLParser;

#3th party library
use strict;
use warnings;

#local library
use XML::LibXML;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"xmlPath"} = shift;

	$self->{"dom"} = XML::LibXML->load_xml( location => $self->{"xmlPath"} );

	return $self;
}


sub GetConstrain{
		my $self = shift;
		my $id = shift;
		
		return ($self->GetConstrains())[$id];

}


sub GetConstrains {
	my $self = shift;

	my @constrains = ();

	foreach my $constrain ( $self->{"dom"}->findnodes('/document/interfacelist/JOB/STACKUP/STACKUP/IMPEDANCE_CONSTRAINTS/IMPEDANCE_CONSTRAINT') ) {

		#se_coated_lower_embedded
		#diff_coated_lower_embedded
		#coplanar_se_coated_microstrip
		#coplanar_diff_coated_microstrip
		my ( $tInStack, $mInStack ) = undef;

		if ( $constrain->{"MODEL_NAME"} =~ /^coplanar/ ) {

			( $tInStack, $mInStack ) = $constrain->{"MODEL_NAME"} =~ /^(coplanar_\w*)_(.*)/;
		}
		else {

			( $tInStack, $mInStack ) = $constrain->{"MODEL_NAME"} =~ /^(\w*)_(.*)/;
		}

		my %inf = ();

		$inf{"type"}       = $tInStack;
		$inf{"model"}      = $mInStack;
		$inf{"xmlDomData"} = $constrain;

		push( @constrains, \%inf );

		return @constrains;

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

