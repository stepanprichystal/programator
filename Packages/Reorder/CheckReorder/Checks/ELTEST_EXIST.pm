#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::ELTEST_EXIST;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamJob';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# if electric test directory doesn't contain dir at least fo one machine
sub Run {
	my $self     = shift;
	
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	my $needChange = 0;

	if($isPool){
		return 0;
	}

	my $nif = NifFile->new($jobId);
	 
	# if pcb is one side + class 3, do not request test
	if($nif->GetValue("kons_trida") <= 3 && CamJob->GetSignalLayerCnt($inCAM, $jobId) == 1){
		return 0;
	}
 
	my $path = JobHelper->GetJobElTest($jobId);
 
	if ( -e $path ) {

		my @dirs = ();
		
		if ( opendir( DIR, $path ) ) {
			@dirs = readdir(DIR);
			closedir(DIR);
		}

		if ( scalar( grep { $_ =~ /^A[357]_/i } @dirs ) < 1 ) {

			$needChange = 1;
		}

	}
	else {
		$needChange = 1;
	}
	
	return $needChange;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 	use aliased 'Packages::Reorder::CheckReorder::Checks::ELTEST_EXIST' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "d10355";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

