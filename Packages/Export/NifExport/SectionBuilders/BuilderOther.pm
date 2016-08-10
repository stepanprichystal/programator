
#-------------------------------------------------------------------------------------------#
# Description: Build section about extra pcb information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderOther;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my %nifData = %{ $self->{"nifData"} };

	#poznamka
	if ( $self->_IsRequire("poznamka") ) {

		$section->AddRow( "poznamka", $nifData{"poznamka"} );
	}

	# datacode
	if ( $self->_IsRequire("datacode") ) {

		$section->AddRow( "datacode", $nifData{"datacode"});
	}

	#poznamka
	if ( $self->_IsRequire("ul_logo") ) {

		$section->AddRow( "ul_logo", $nifData{"ul_logo"} );
	}

	#rel(22305,L)

	if ( $self->_IsRequire("rel(22305,L)") ) {

		$section->AddComment("Maska 0,1");

		my $maska = "2814075";

		unless ( $nifData{"rel(22305,L)"} ) {
			$maska = "-" . $maska;
		}

		$section->AddRow( "rel(22305,L)", $maska );
	}

	#merit_presfitt
	if ( $self->_IsRequire("merit_presfitt") ) {

		my $pressfit = "N";

		if ( $nifData{"merit_presfitt"} ) {
			$pressfit = "A";
		}

		$section->AddRow( "merit_presfitt", $pressfit );
	}

	#ul_logo
	if ( $self->_IsRequire("prerusovana_drazka") ) {
		my $jumpScore = "N";

		if ( $nifData{"prerusovana_drazka"} ) {
			$jumpScore = "A";
		}
		$section->AddRow( "prerusovana_drazka", $jumpScore );
	}

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

