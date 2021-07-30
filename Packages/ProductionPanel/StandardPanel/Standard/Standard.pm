#-------------------------------------------------------------------------------------------#
# Description:  Class keep definition of specific standard
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::Standard::Standard;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

#use overload 
#    '""' => \&stringify;

sub new {
	my $class = shift;
	my %args = (
				 "name"        => undef,
				 "pcbType"     => undef,
				 "pcbMat"      => undef,
				 "active"      => 1,
				 "w"           => undef,
				 "h"           => undef,
				 "bl"  => undef,
				 "br" => undef,
				 "bt"   => undef,
				 "bb"   => undef,
				 "pH"   => undef,
				 "pW"   => undef,
				 @_,
	);

	my $self = {};

	bless $self;

	# This properties create uniqu key of standard
	$self->{"name"}    = $args{"name"};
	$self->{"pcbType"} = $args{"pcbType"};
	$self->{"pcbMat"}  = $args{"pcbMat"};

	# Properties
	$self->{"active"}      = $args{"active"};
	$self->{'w'}           = $args{"w"};
	$self->{'h'}           = $args{"h"};
	$self->{'bl'}  = $args{"bl"};
	$self->{'br'} = $args{"br"};
	$self->{'bt'}   = $args{"bt"};
	$self->{'bb'}   = $args{"bb"};
	$self->{'pH'}   = $args{"pH"};
	$self->{'pW'}   = $args{"pW"};
	
	$self->{'wArea'} = $self->{'w'} - ( $self->{'bl'} + $self->{'br'} );
	$self->{'hArea'} = $self->{'h'} - ( $self->{'bt'} + $self->{'bb'} );
 
	return $self;
}

sub Name {
	my $self = shift;

	return $self->{"name"};
}

sub PcbType {
	my $self = shift;

	return $self->{"pcbType"};
}

sub PcbMat {
	my $self = shift;

	return $self->{"pcbMat"};
}

sub W {
	my $self = shift;

	return $self->{"w"};
}

sub H {
	my $self = shift;

	return $self->{"h"};
}

sub BorderL {
	my $self = shift;

	return $self->{"bl"};
}

sub BorderR {
	my $self = shift;

	return $self->{"br"};
}

sub BorderT {
	my $self = shift;

	return $self->{"bt"};
}

sub BorderB {
	my $self = shift;

	return $self->{"bb"};
}

sub PrepregH {
	my $self = shift;

	return $self->{"pH"};
}

sub PrepregW {
	my $self = shift;

	return $self->{"pW"};
}

sub WArea {
	my $self = shift;

	return $self->{'w'} - ( $self->{'bl'} + $self->{'br'} )
}

sub HArea {
	my $self = shift;

	return $self->{'h'} - ( $self->{'bt'} + $self->{'bb'} );
}

sub IsActive {
	my $self = shift;

	return $self->{"active"};
}

sub PanelArea{
	my $self = shift;
	
	return $self->{"w"} * $self->{"h"};
}

sub ActiveArea{
	my $self = shift;
	
	return $self->{"wArea"} * $self->{"hArea"};
}

sub Equal {
	my $self    = shift;
	my $name    = shift;
	my $pcbType = shift;
	my $pcbMat  = shift;

	if ( $self->{"name"} eq $name && $self->{"pcbType"} eq $pcbType && $self->{"pcbMat"} eq $pcbMat ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub Key{
	my $self = shift;
	
	return join("-", ($self->{"name"}, $self->{"pcbType"}, $self->{"pcbMat"}));
	
}

#
#sub stringify {
#    my ($self) = @_;
#    
#    
#    my $txt = 
#    
#    return "";
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

