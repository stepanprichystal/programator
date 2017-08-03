#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ProcessReorder::Changes::MASK_POLAR;
use base('Packages::Reorder::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ProcessReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self  = shift;
	my $mess = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	my $result = 1;
 
	my @layers = CamJob->GetBoardLayers($inCAM, $jobId);
	
	foreach my $l (@layers){
		
		if($l->{"gROWname"} =~ /m[cs]/ && $l->{"gROWpolarity"} eq "negative"){
			
			CamLayer->SetLayerPolarityLayer($inCAM, $jobId, $l->{"gROWname"}, "positive");
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


 	use aliased 'Packages::Reorder::ProcessReorder::Changes::MASK_POLAR' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new("key", $inCAM, $jobId);
	
	my $mess = "";
	print "Change result: ".$check->Run(\$mess);
}

1;

