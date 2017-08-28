#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::PATTERN;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutArea';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);
	
	
	return $self;
}

# if pcb is pool, check if plated rout areaa is exceed for tenting
sub Run {
	my $self     = shift;
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};
	
	unless($jobExist){
		return 1;
	}
 
	if($isPool && PlatedRoutArea->PlatedAreaExceed($inCAM, $jobId, "o+1")){
		
		$self->_AddChange("Dps je pool a musí jít do výroby patternem, kvůli velkému prokovenému otvoru.", 1)
	}
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
 	use aliased 'Packages::Reorder::CheckReorder::Checks::POOL_PATTERN' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52456";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

