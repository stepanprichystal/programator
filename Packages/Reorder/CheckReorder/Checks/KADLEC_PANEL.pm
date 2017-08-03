#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::KADLEC_PANEL;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::NifFile::NifFile';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# check if pcb is
sub NeedChange {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;

	my $needChange = 0;

	my $custInfo = HegMethods->GetCustomerInfo($jobId);

	# Kadlec customer
	if ( $custInfo->{"reference_subjektu"} eq "04174" || $custInfo->{"reference_subjektu"} eq "04175" ) {

		 

		my $nif = NifFile->new($jobId);

		my $val = $nif->GetValue("nasobnost_panelu");

		if ( !defined $val || $val eq "" || $val == 0 ) {

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

 	use aliased 'Packages::Reorder::CheckReorder::Checks::KADLEC_PANEL' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

