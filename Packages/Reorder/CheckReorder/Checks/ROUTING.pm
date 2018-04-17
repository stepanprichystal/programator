#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::ROUTING;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAM::UniDTM::UniDTM';

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

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	unless ($jobExist) {
		return 0;
	}

	# 1) Check if rout is on bridges and attribute "routOnBridges" is not set.
	if ($isPool) {

		my $unitRTM = UniRTM->new( $inCAM, $jobId, "o+1", "f" );

		my @outlines = $unitRTM->GetOutlineChains();

		my @chains = $unitRTM->GetChains();
		my $onBridges = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "o+1", "rout_on_bridges" );

		# If not exist outline rout, check if pcb is on bridges
		if ( !scalar(@outlines) && $onBridges eq "no" ) {

			$self->_AddChange(
							   "Vypadá to, že dps má frézu na můstky, ale není nastaven atribut stepu o+1: \"Rout on bridges\" - \"yes\"\n"
								 . "Ověř to a nastav atribut nebo oprav obrysovou frézu.",
							   1
			);
		}
	}

	# check all plt+nplt blind rout/drill if we have still all special tools
	my @types = (
				  EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot,
				  EnumsGeneral->LAYERTYPE_plt_bMillTop,  EnumsGeneral->LAYERTYPE_plt_bMillBot
	);

	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@types ) ) {

		my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		my @tools = grep { $_->GetDrillSize() > 6000 } $unitDTM->GetUniqueTools();

		if (@tools) {

			my $str = join( ";", map { $_->GetDrillSize() } @tools );

			$self->_AddChange( "Vrstva: \""
						 . $l->{"gROWname"}
						 . "\" obsahuje speciální nástroje ($str) větší jak 6.5mm, které již nemáme."
						 . " Pokud nástroj frézuje \"countersink\", použij jiný průměr.\n"
						 . "Dej pozor, jestli nový nástroj bude stačit na průměr \"countersinku\", jestli ne tak předělej na pojezd/surface" );

			if ( grep { !defined $_->GetMagazine() } $unitDTM->GetUniqueTools() ) {

				$self->_AddChange(
						"Vrstva: \"" . $l->{"gROWname"} . "\" obsahuje speciální nástroje ($str), které nemají definovaný magazín" );
			}

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

