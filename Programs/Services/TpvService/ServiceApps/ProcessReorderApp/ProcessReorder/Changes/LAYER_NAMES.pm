#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::LAYER_NAMES;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::IChange');

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
 
	my @layers = CamJob->GetAllLayers($inCAM, $jobId);
	
	# old format of paste files sa_ori, sb_ori
	
	my @oldPaste = grep { $_->{"gROWname"} =~ /^s[ab]_(ori)|(made)$/} @layers;
	
	foreach my $l (@oldPaste){
		my $newName = $l->{"gROWname"};
		$newName =~ s/_/-/;
		
		$inCAM->COM("matrix_rename_layer","job"=> $jobId,"matrix"=> "matrix","layer"=>$l->{"gROWname"},"new_name"=>$newName);	
	}
	 

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


 	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::LAYER_NAMES' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f00873";
	
	my $check = Change->new("key", $inCAM, $jobId);
	
	my $mess = "";
	print "Change result: ".$check->Run(\$mess);
}

1;

