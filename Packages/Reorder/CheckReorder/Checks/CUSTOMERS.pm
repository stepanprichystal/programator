#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::CUSTOMERS;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
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
sub Run {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	my $needChange = 0;

	my $custInfo = HegMethods->GetCustomerInfo($jobId);

	# 1) Kadlec customer
	if ( $custInfo->{"reference_subjektu"} eq "04174" || $custInfo->{"reference_subjektu"} eq "04175" ) {

		my $nif = NifFile->new($jobId);

		my $val = $nif->GetValue("nasobnost_panelu");

		if ( !defined $val || $val eq "" || $val == 0 ) {

			$self->_AddChange("Zákazník Kadlec si přeje veškeré dps dodávat v panelu. Předělej na panel.");
		}
	}

	# 2)Pickering

	if (    $custInfo->{"reference_subjektu"} eq "06544"
		 || $custInfo->{"reference_subjektu"} eq "06545"
		 || $custInfo->{"reference_subjektu"} eq "06546" )
	{

		$self->_AddChange("Zákazník Pickering si přeje upravit číslo objednávek na deskách dle OneNotu");

	}

	# 2) Meatest

	if ( $custInfo->{"reference_subjektu"} eq "05052" ) {

		#test if no UL in Heg
		my $ul = HegMethods->GetUlLogoLayer($jobId);

		if ( !defined $ul || $ul eq "" ) {

			$self->_AddChange("Zákazník si přeje vkládat do všech desek UL logo (14.8.2017)");

		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::KADLEC_PANEL' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

