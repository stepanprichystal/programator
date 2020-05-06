#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::CvrlStencilPdf::CvrlStencilBuilder;

use Class::Interface;
&implements('Packages::CAMJob::Traveler::UniTraveler::TravelerDataBuilder::ITravelerBuilder');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

sub BuildOperations {
	my $self     = shift;
	my $traveler = shift;

	$traveler->AddOperation( "test name", "test info" );

}

sub BuildInfoBoxes {
	my $self     = shift;
	my $traveler = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

