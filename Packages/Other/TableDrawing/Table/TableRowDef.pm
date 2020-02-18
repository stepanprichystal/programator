
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::ISectionBuilder;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"sectionType"} = shift;

	$self->{"columns"}  = [];
	$self->{"startCol"} = undef;
	$self->{"endCol"}   = undef;
	$self->{"isActive"} = 0;

	return $self;
}

sub GetType {
	my $self = shift;

	return $self->{"sectionType"};

}

sub SetIsActive {
	my $self = shift;

	$self->{"isActive"} = shift;
}

sub GetIsActive {
	my $self = shift;

	return $self->{"isActive"};

}

sub AddColumn {
	my $self  = shift;
	my $key   = shift;
	my $width = shift;

	die "Key is not defined"   unless ( defined $key );
	die "Width is not defined" unless ( defined $width );

	die "Column with key: $key alreadzexists" if ( first { $_->GetKey() eq $key } @{ $self->{"columns"} } );

	my $col = SectionCol->new( $key, $width );

	push( @{ $self->{"columns"} }, $col );

	return $col;
}


sub GetColumn {
	my $self = shift;
	my $key  = shift;

	my $col = first { $_->GetKey() eq $key } @{ $self->{"columns"} };

	return $col;

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

