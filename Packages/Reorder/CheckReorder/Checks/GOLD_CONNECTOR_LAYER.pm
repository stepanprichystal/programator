#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::GOLD_CONNECTOR_LAYER;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
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

# Determine, if gold layers are preapred in job matrix
sub NeedChange {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift; 
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;
	
	my $needChange = 0;
	
	my $info = (HegMethods->GetAllByPcbId($jobId))[0];
	
	# if gold connector exist, check if opfx gold exist
	# if opfx doesn't exist, it means, thera are not prepared "gold layers" in matrix
	if(defined $info->{"zlaceni"}  && $info->{"zlaceni"} =~ /a/i ){
 
		my $path = JobHelper->GetJobArchive($jobId). "zdroje\\";
		
		my @goldOpfx = FileHelper->GetFilesNameByPattern( $path, "$jobId@"."gold" );
		
		if(scalar(@goldOpfx) == 0){
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

 
 	use aliased 'Packages::Reorder::CheckReorder::Checks::GOLD_CONNECTOR_LAYER' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f60648";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

