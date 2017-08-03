#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::NIF_NAKOVENI;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::NifFile::NifFile';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);
	
	
	return $self;
}

# check if nif file contain "C" in  core drill. Example( f60574)
sub NeedChange {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;
	
	my $needChange = 0;
	
	my $nifPath = JobHelper->GetJobArchive( $jobId ) . $jobId . ".nif";
	
	if(-e $nifPath){
		
		my @lines = @{FileHelper->ReadAsLines($nifPath)};
		
		my @nakov = grep { $_ =~ /vrtani_\d=c/i } @lines;
		
		if(scalar(@nakov)){
			
			$needChange = 1;
		}
		
	}
	
	return $needChange;
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
 	use aliased 'Packages::Reorder::CheckReorder::Checks::NIF_NAKOVENI' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f73086";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

