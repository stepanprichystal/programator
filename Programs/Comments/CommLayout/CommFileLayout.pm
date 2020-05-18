
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommLayout::CommFileLayout;
use base qw(Programs::Comments::CommLayout::CommLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $fileName = shift;
	my $filePath = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"fileName"} = $fileName;
	$self->{"filePath"} = $filePath;

	return $self;
}


sub SetFileName {
	my $self = shift;
	$self->{"fileName"} = shift;
}

sub GetFileName {
	my $self = shift;
	return $self->{"fileName"};
}

sub GetFilePath {
	my $self = shift;

	return $self->{"filePath"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

