
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
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";
use aliased 'CamHelpers::CamJob';

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

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my %nifData  = %{ $self->{"nifData"} };
	my $stepName = "panel"; 
	my $sr = 1;
	
	# if panel doesnt exist, set o+1 (pool)
	if(!CamHelper->StepExists($inCAM,$jobId, $stepName)){
		$stepName = "o+1";
		$sr = 0;
	}

	$self->{"scoreCheck"} = undef;

	my $scoreExist = CamHelper->LayerExists( $inCAM, $jobId, "score" );

	if ($scoreExist) {
		$self->{"scoreCheck"} = ScoreChecker->new( $inCAM, $jobId, $stepName, "score", $sr );
		$self->{"scoreCheck"}->Init();
	}

	#drazkovani
	if ( $self->_IsRequire("drazkovani") ) {

		my $drazkovani = "N";

		if ($scoreExist) {

			my $pcbPlace = $self->{"scoreCheck"}->GetPcbPlace();

			my @hPos = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );    # horizontal mark lines
			my @VPos = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );    # vertical mark lines

			if(scalar(@hPos) && scalar(@VPos)){
				
				$drazkovani = "A";
				
			}elsif(scalar(@hPos) && scalar(@VPos) == 0){
				
				$drazkovani = "Y";
				
			}elsif(scalar(@hPos) == 0 && scalar(@VPos)){
				
				$drazkovani = "X";
			}
		}

		$section->AddRow("drazkovani", $drazkovani );
	}

	#delka_drazky
	if ( $self->_IsRequire("delka_drazky") ) {
 
 		my $delka_drazky = 0;
 
		if ($scoreExist) {
			
			my %lim = CamJob->GetProfileLimits2($inCAM, $jobId, $stepName);
		
			my $w = abs($lim{"xMin"} - $lim{"xMax"});
			my $h = abs($lim{"yMin"} - $lim{"yMax"});

			my $pcbPlace = $self->{"scoreCheck"}->GetPcbPlace();

			my @hPos = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );    # horizontal mark lines
			my @VPos = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );    # vertical mark lines
			
			$delka_drazky = sprintf("%.2f", (scalar(@hPos) * $w + scalar(@VPos) * $h)/1000);
			
		} 

		$section->AddRow( "delka_drazky", $delka_drazky );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

