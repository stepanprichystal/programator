#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::LAYER_NAMES;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';

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

	my $reorderType = $self->{"reorderType"};
	
	my $result = 1;
 
	my @layers = CamJob->GetAllLayers($inCAM, $jobId);
	
	# 1) old format of paste files sa_ori, sb_ori
	
	my @oldPaste = grep { $_->{"gROWname"} =~ /^s[ab]_(ori)|(made)$/} @layers;
	
	foreach my $l (@oldPaste){
		my $newName = $l->{"gROWname"};
		$newName =~ s/_/-/;
		
		$inCAM->COM("matrix_rename_layer","job"=> $jobId,"matrix"=> "matrix","layer"=>$l->{"gROWname"},"new_name"=>$newName);	
	}
	
	# 2) Old format of fsch
	my $fsch = (grep { $_->{"gROWname"} =~ /^f_sch$/} @layers)[0];
	
	if(defined $fsch){
		
		$inCAM->COM("matrix_rename_layer","job"=> $jobId,"matrix"=> "matrix","layer"=>"f_sch","new_name"=>"fsch");	
		
		# set fsch as board layer
		CamLayer->SetLayerContextLayer($inCAM, $jobId, "fsch", "board");
	}
 

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


 	use aliased 'Packages::Reorder::ChangeReorder::Changes::LAYER_NAMES' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f00873";
	
	my $check = Change->new("key", $inCAM, $jobId);
	
	my $mess = "";
	print "Change result: ".$check->Run(\$mess);
}

1;

