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

sub GetColumnPos {
	my $self    = shift;
	my $secType = shift;
	my $colKey  = shift;

	my $pos      = 0;
	my $posFound = 0;

	my @sec = $self->GetAllSections(1);

	for ( my $i = 0 ; $i < scalar( @sec ) ; $i++ ) {

		my @colls = $sec[$i]->GetAllColumns();

		for ( my $j = 0 ; $j < scalar(@colls) ; $j++ ) {

			if ($sec[$i]->GetType() eq $secType && $colls[$j]->GetKey() eq $colKey ) {

				$posFound = 1;
				last;
			}
			$pos++;
		}

		last if ($posFound);
	}

	die "Column: $colKey doesn't exist in section: $secType" if ( !$posFound );

	return $pos;

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
	my $activeOnly = shift // 0;

	my @sec = @{ $self->{"sections"} };

	@sec = grep { $_->GetIsActive() } @sec if ($activeOnly);

	return @sec;

}

sub GetSectionsCnt {
	my $self = shift;
	my $activeOnly = shift // 0;

	return scalar( $self->GetAllSections($activeOnly) );

}

sub GetColumnCnt {
	my $self = shift;
	my $activeOnly = shift // 0;

	my $total = 0;

	$total += $_ foreach ( map { $_->GetColumnCnt() } $self->GetAllSections($activeOnly) );

	return $total;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

