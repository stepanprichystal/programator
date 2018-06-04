
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnSource::Constraint;

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

	$self->{"cpnSource"} = shift;
	$self->{"units"}        = shift;
	$self->{"id"} = shift;
	$self->{"type"}         = shift;
	$self->{"model"}        = shift;
	$self->{"xmlConstraint"} = shift;

	return $self;
}

sub GetType{
	my $self = shift;
	
	return $self->{"type"};
}


sub GetModel{
	my $self = shift;
	
	return $self->{"model"};
}

sub GetConstrainId{
	my $self = shift;
	
	return $self->{"id"};
}


sub GetOption{
	my $self = shift;
	my $name = shift;

	my $val =$self->{"xmlConstraint"}->{"$name"};
 
	return $val;
	
}

sub GetParamDouble {
	my $self = shift;
	my $name = shift;

	my $val = ( grep { $_->{"NAME"} eq $name } $self->{"xmlConstraint"}->findnodes('./PARAMS/IMPEDANCE_CONSTRAINT_PARAMETER') )[0]
	  ->getAttribute('DOUBLE_VALUE');    # space

	if ( $self->{"units"} eq "mm" )
	{

		$val *= 25.4;
	}

	return $val;

}
 
sub GetCpnSource{
	my $self = shift;
	
	return $self->{"cpnSource"};
} 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

