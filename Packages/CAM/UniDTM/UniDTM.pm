
#-------------------------------------------------------------------------------------------#
# Description: Helper method over Universal Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniDTM;
use base("Packages::CAM::UniDTM::UniDTMBase");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::UniDTM::UniTool';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;
 
	return $self;
}
 

# Return tool depth
sub GetToolDepth {
	my $self = shift;
	my $drillSize = shift;
	my $typeProcess = shift;
	
	 my $mess = "";

	unless ( $self->{"check"}->CheckToolDepthSet(\$mess) ) {

		die "Tool depth in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}
 
	my $tool = $self->GetTool($drillSize, $typeProcess);
	 
	if($tool){
		return $tool->GetDepth();
		
	}else{
		
		die "Tool: $drillSize with type: $typeProcess doesn't exist.\n";
	}
}


 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::UniDTM::UniDTM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", "fzc" ,1);

	my $mess = "";
	my $result = $unitDTM->CheckTools(\$mess);

	my @tools = $unitDTM->GetTools();
	 
	print "fff";

}

1;

