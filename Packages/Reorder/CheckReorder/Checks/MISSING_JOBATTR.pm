#-------------------------------------------------------------------------------------------#
# Description:  Checking missing or invalid job attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::MISSING_JOBATTR;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
use aliased 'Packages::Reorder::Enums';
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

# Check if exist new version of nif, if so it means it is from InCAM
sub Run {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $orderId     = $self->{"orderId"};
	my $reorderType = $self->{"reorderType"};

	# 1) Check user name
	my $userName = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );

	if ( !defined $userName || $userName eq "" || $userName =~ /none/i ) {

		$self->_AddChange( "V atributech jobu není definován atribut: \"user_name\". Doplň ho a vyexportuj NIF.", 1 );

	}

	# 2) Check outer class
	my $classOuter = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "pcb_class" );
	if ( !defined $classOuter || $classOuter < 3 ) {

		my $mess = "V atributech jobu není definován atribut: \"pcb_class\". Doplň ho a vyexportuj NIF.";

		if ( $reorderType eq Enums->ReorderType_POOLFORMERMOTHER ) {

			$mess =
			    "Job je bývalý POOL-matka a nepodařilo se dohledat vnější konstrukční"
			  . " třídu ani v DIF souboru ani poslední spuštěný ERF model."
			  . "Spusť checklist, doplň atribut: \"pcb_class\" a vyexportuj NIF.";
		}

		$self->_AddChange( $mess, 1 );

	}

	# 2) Check inner class
	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {
		my $classInnerOuter = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "pcb_class_inner" );
		if ( !defined $classInnerOuter || $classInnerOuter < 3 ) {

			my $mess = "V atributech jobu není definován atribut: \"pcb_class_inner\". Doplň ho a vyexportuj NIF.";

			if ( $reorderType eq Enums->ReorderType_POOLFORMERMOTHER ) {

				$mess =
				    "Job je bývalý POOL-matka a nepodařilo se dohledat vnitřní konstrukční"
				  . " třídu ani v DIF souboru ani poslední spuštěný ERF model."
				  . "Proveď checklist, doplň atribut: \"pcb_class_inner\" a vyexportuj NIF.";
			}

			$self->_AddChange( $mess, 1 );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

