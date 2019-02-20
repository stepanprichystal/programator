
#-------------------------------------------------------------------------------------------#
# Description: Coupon configuration 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::CpnConfigSerializer::CpnConfig;


use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

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
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"userFilter"}   = undef;    # keys represent strip id and value if strip is used in coupon
	$self->{"userGroups"}   = undef;    # contain strips splitted into group. Key is strip id, val is group number
	$self->{"globalSett"}   = undef;    # global settings of coupon
	$self->{"cpnStripSett"} = {};       # strip settings for each strip by constraint id
	$self->{"cpnGroupSett"} = {};       # group settings for each group

	$self->{"__CLASS__"} = caller();

	return $self;

}

sub SetUserFilter {
	my $self = shift;

	$self->{"userFilter"} = shift;
}

sub GetUserFilter {
	my $self = shift;

	return $self->{"userFilter"};
}

sub SetUserGroups {
	my $self = shift;

	$self->{"userGroups"} = shift;
}

sub GetUserGroups {
	my $self = shift;

	return $self->{"userGroups"};
}

sub SetGlobalSett {
	my $self = shift;

	$self->{"globalSett"} = shift;
}

sub GetGlobalSett {
	my $self = shift;

	return $self->{"globalSett"};
}

sub SetCpnStripSett {
	my $self = shift;

	$self->{"cpnStripSett"} = shift;
}

sub GetCpnStripSett {
	my $self = shift;

	return $self->{"cpnStripSett"};
}

sub SetCpnGroupSett {
	my $self = shift;

	$self->{"cpnGroupSett"} = shift;
}

sub GetCpnGroupSett {
	my $self = shift;

	return $self->{"cpnGroupSett"};
}

# Important because of serialize class
sub TO_JSON { return { %{ shift() } }; }

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
 

}

1;

