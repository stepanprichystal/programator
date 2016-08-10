
#-------------------------------------------------------------------------------------------#
# Description: Build section about scoring information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderScore;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');


#3th party library
use strict;
use warnings;

#local library

use aliased 'CamHelpers::CamHelper';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my %nifData = %{ $self->{"nifData"} };
	my $stepName = "panel";

	#delka_drazky
	if ( $self->_IsRequire("delka_drazky") ) {
		
		my $scoreExist = CamHelper->LayerExists( $inCAM, $jobId, "score" );
		
		if ($scoreExist){
			$scoreExist = 1; #it means constant score lentht 1m (the length doesn't metter)
		}else{
			$scoreExist = "";
		}
		
		$section->AddRow( "delka_drazky", $scoreExist);
	}


}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

