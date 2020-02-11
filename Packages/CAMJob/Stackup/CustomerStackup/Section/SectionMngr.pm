#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"sections"} = [];

	return $self;
}

sub AddSection {
	my $self = shift;
	my $type = shift;

	die "Section type is not defined" unless ( defined $type );

	die "Section type: $type was already added" if ( first { $_->GetType() eq $type } @{ $self->{"sections"} } );

	my $section = Section->new($type);

	push( @{ $self->{"sections"} }, $section );

	return $section;

}

sub GetSection {
	my $self = shift;
	my $type = shift;

	my $section = first { $_->GetType() eq $type } @{ $self->{"sections"} };

	return $section;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

