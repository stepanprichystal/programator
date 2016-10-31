
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::ScorePosInfo;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Scoring::ScoreChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"position"} = shift;
	$self->{"dir"}    = shift;
	return $self;
}

 sub GetPosition {
	my $self = shift;
	return $self->{"position"};
}

sub GetDirection {
	my $self = shift;
	return $self->{"dir"};
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

