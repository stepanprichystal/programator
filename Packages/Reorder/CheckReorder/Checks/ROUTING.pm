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
							   "Vypad� to, �e dps m� fr�zu na m�stky, ale nen� nastaven atribut stepu o+1: \"Rout on bridges\" - \"yes\"\n"
								 . "Ov�� to a nastav atribut nebo oprav obrysovou fr�zu.",
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
						 . "\" obsahuje speci�ln� n�stroje ($str) v�t�� jak 6.5mm, kter� ji� nem�me."
						 . " Pokud n�stroj fr�zuje \"countersink\", pou�ij jin� pr�m�r.\n"
						 . "Dej pozor, jestli nov� n�stroj bude sta�it na pr�m�r \"countersinku\", jestli ne tak p�ed�lej na pojezd/surface" );

			if ( grep { !defined $_->GetMagazine() } $unitDTM->GetUniqueTools() ) {

				$self->_AddChange(
						"Vrstva: \"" . $l->{"gROWname"} . "\" obsahuje speci�ln� n�stroje ($str), kter� nemaj� definovan� magaz�n" );
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

