#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::MISSING_JOBATTR;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamAttributes';


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
	
	my $nif = NifFile->new($jobId);
	
	# insert user name
	my $userName = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );     
	
	if(!defined $userName || $userName eq "" || $userName =~ /none/i){
		 
		 my $user = $nif->GetValue("zpracoval");
		 
		 if(!defined $user || $user eq ""){
		 	die "User is not defined in nif";
		 }
		 
		 CamAttributes->SetJobAttribute( $inCAM, $jobId, "user_name", $user );     
	}
	
	# insert pcb class
	my $pcbClass = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "pcb_class" );    
	
	if(!defined $pcbClass || $pcbClass eq ""  || $pcbClass < 3 ){
		
		 my $class = $nif->GetValue("kons_trida");
		 
		 if(!defined $class || $class < 3){
		 	die "Pcb class is not defined in nif";
		 }
		 
		 CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class", $class );     
	} 
 

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


 	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::MASK_POLAR' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new("key", $inCAM, $jobId);
	
	my $mess = "";
	print "Change result: ".$check->Run(\$mess);
}

1;

