#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::Section::SectionMngr;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Packages::CAMJob::Stackup::CustStackup::Section::Section';

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

	die "Section: $type doesn't exist" unless ( defined $section );

	return $section;

}

sub GetAllSections {
	my $self = shift;

	return @{ $self->{"sections"} };

}

sub GetColumnCnt {
	my $self = shift;

	my $total = 0;
	 
	$total += $_ foreach(map { $_->GetColumnCnt() } @{ $self->{"sections"} });

	return $total;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

