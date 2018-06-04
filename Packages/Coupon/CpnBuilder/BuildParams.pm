
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::BuildParams;

#3th party library
use strict;
use warnings;
use List::Util qw[max];

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	my $constrainCnt = shift;

	$self->{"constrains"} = [];

	for ( my $i = 0 ; $i < $constrainCnt ; $i++ ) {
		push( @{ $self->{"constrains"} }, $i );
	}
	
	return $self;

}


 

sub SetGroup {
	my $self         = shift;
	my @constrainsId = shift;
	my $groupId      = shift;

	foreach my $id (@constrainsId) {

		$self->{"constrains"}->[$id] = $groupId;

	}
}

sub GetGroups {
	my $self = shift;

	my @groups = ();

	my $maxGroupId = max( map { $_ } @{ $self->{"constrains"} } );

	for ( my $i = 0 ; $i <= $maxGroupId ; $i++ ) {

		my @constrains = ();

		for ( my $j = 0 ; $j < scalar( @{ $self->{"constrains"} } ) ; $j++ ) {

			if ( $self->{"constrains"}->[$j] == $i ) {
				push( @constrains, $i );
			}
		}

		if (@constrains) {

			my %groupInf = ( "groupId" => $i, "constrainsId" => \@constrains );

			push( @groups, \%groupInf );
		}
	}

	return @groups;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

