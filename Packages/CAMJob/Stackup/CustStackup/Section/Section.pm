
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::Section::Section;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Packages::CAMJob::Stackup::CustStackup::Section::SectionCol';

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
	my $self    = shift;
	my $key     = shift;
	my $width   = shift;
	my $backgStyle = shift;
	my $rowStyle = shift;
	my $position = shift;    # if postition is defined, column is inserted on this postition

	die "Key is not defined"   unless ( defined $key );
	die "Width is not defined" unless ( defined $width );

	my $intKey = $self->__GetColInKey($key);

	die "Column with key: $key; in section: " . $self->GetType() . " already exists" if ( first { $_->GetKey() eq $intKey } @{ $self->{"columns"} } );

	my $col = SectionCol->new( $intKey, $width, $backgStyle, $rowStyle );

	push( @{ $self->{"columns"} }, $col );

	return $col;
}

sub GetColumn {
	my $self = shift;
	my $key  = shift;

	my $intKey = $self->__GetColInKey($key);

	my $col = first { $_->GetKey() eq $intKey } @{ $self->{"columns"} };

	return $col;

}

sub GetAllColumns {
	my $self = shift;
	my $key  = shift;

	return @{ $self->{"columns"} };
}

sub GetColumnCnt {
	my $self = shift;

	return scalar( $self->GetAllColumns() );
}

sub __GetColInKey {
	my $self   = shift;
	my $colKey = shift;

	#return $self->GetType()."__".$colKey;
	return $colKey;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

