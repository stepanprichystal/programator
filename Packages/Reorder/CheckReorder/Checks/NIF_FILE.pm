#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::NIF_FILE;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
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
sub Run {
	my $self     = shift;
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};
	
	my $needChange = 0;
	
	my $nifPath = JobHelper->GetJobArchive( $jobId ) . $jobId . ".nif";
	
	# 1) Check nakoveni in nif
	if(-e $nifPath){
		
		my @lines = @{FileHelper->ReadAsLines($nifPath)};
		
		my @nakov = grep { $_ =~ /vrtani_\d=c/i } @lines;
		
		if(scalar(@nakov)){
			
			$self->_AddChange("V nifu u vrtani jader je hodnota C - nakoveni. Po exportu dps hodnotu znovu zapiš do nifu ručně. Tohle není zautomatizované!");
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

