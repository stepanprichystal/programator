
#-------------------------------------------------------------------------------------------#
# Description: Special structure which keep couple key-value
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::HtmlTemplate::KeyItem;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"key"} = shift;
	$self->{"en"}  = shift;
	$self->{"cz"}  = shift;

	return $self;
}

sub GetText {
	my $self = shift;
	my $lang = shift;

	if ( $lang eq "cz" ) {

		return $self->{"cz"};

	}
	elsif ( $lang eq "en" ) {

		return $self->{"en"};
	}

	return $self->{"title"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

