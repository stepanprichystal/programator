#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::PANEL_SET;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
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

# if nif contain info about panel, and there is no mpanel
# It means it is customer set or customer
sub Run {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	unless ($jobExist) {
		return 1;
	}

	# Check only standard orders
	if ($isPool) {
		return 1;
	}

	my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );    # zakaznicky panel
	my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );      # zakaznicke sady

	my $nif        = NifFile->new($jobId);
	my $multiplNif = $nif->GetValue("nasobnost_panelu");

	# 1) Check only when nasobnost_panelu is set, thus potentional missing of job attributes
	if ( defined $multiplNif && $multiplNif ne "" && $multiplNif != 0 ) {

		my $mpanelExist = CamHelper->StepExists( $inCAM, $jobId, "mpanel" );

		# 1) if mpanel doesn't exist AND customer panel is not set => error

		if ( !$mpanelExist && $custPnlExist ne "yes" && $custSetExist ne "yes" ) {

			$self->_AddChange(
						  "V nifu je vyplněná \"nasobnost_panelu\", ale v jobu není nastaveno, že se jedná o \"zákaznický panel\ nebo \"sadu\""
							. "(respektive nejsou nastaveny atributy \"customer_panel\" nebo \"customer_set\")",
						  1
			);
		}

		# 2) check if customer set is not missing, when count of pieces in panel and nif are different
		if ( $mpanelExist && $custSetExist ne "yes" ) {

			my $multiplReal = scalar( CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "mpanel" ) );
			if ( $multiplNif != $multiplReal ) {

				$self->_AddChange(
								   "Nasobnost v nifu: \"nasobnost_panelu\" nesedí s reálnou násobností v mpanelu. "
									 . "Pravděpodobně není v jobu definovaná sada ( atribut \"customer_set\").",
								   1
				);
			}
		}
	}

	# 2) Check if "nasobnost_panelu" is not set and real number of step is in panel is not equal to "nasobnost" in nif
	if ( !defined $multiplNif || $multiplNif eq "" || $multiplNif == 0 ) {

		my $multiplReal = scalar( CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "panel" ) );
		my $multiplPnlNif = $nif->GetValue("nasobnost");

		if ( $multiplReal != $multiplPnlNif ) {

			$self->_AddChange(
							   "Pravděpodobně není v jobu definovaná sada nebo zákaznický panel,"
								 . " protože reálná násobnost panelu ($multiplReal) nesedí s násobností panelu v nifu ($multiplNif).",
							   1
			);
		}

	}

	# If customer pnl, check if all information are set
	if ( $custPnlExist eq "yes" ) {

		my $custPnlX = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singlex" );
		my $custPnlY = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_singley" );
		my $custPnlMult = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_pnl_multipl" );

		if ( !defined $custPnlX || !defined $custPnlY || !defined $custPnlMult  || $custPnlX == 0 || $custPnlY == 0  || $custPnlMult == 0 ) {
			$self->_AddChange(
							   "V atributech jobu je aktivní 'zákaznický panel', ale informace není kompletní"
								 . " (atributy jobu: \"cust_pnl_singlex\", \"cust_pnl_singley\", \"cust_pnl_multipl\")",
							   1
			);
		}
	}

	# If customer set, check if all information are set
	# Check all necessary attributes when customer set
	if ( $custSetExist eq "yes" ) {

		my $multipl = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "cust_set_multipl" );

		if ( !defined $multipl || $multipl == 0 ) {
			$self->_AddChange(
						"V atributech jobu je aktivní 'zákaznická sada', " . "ale informace není kompletní (atribut jobu: \"cust_set_multipl\")",
						1 );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::PANEL_SET' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

