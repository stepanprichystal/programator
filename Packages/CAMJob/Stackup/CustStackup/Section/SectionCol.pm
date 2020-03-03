
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::Section::SectionCol;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"key"}         = shift;
	$self->{"width"}       = shift;
	$self->{"borderStyle"} = shift;

	return $self;
}

sub GetKey {
	my $self = shift;

	return $self->{"key"};

}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};

}

sub GetBorderStyle{
	my $self = shift;
	
	
	return $self->{"borderStyle"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

