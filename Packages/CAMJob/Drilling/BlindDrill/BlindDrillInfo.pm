#-------------------------------------------------------------------------------------------#
# Description: Return human readable report of blind drills, if depths are ok
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo;

#3th party library
use utf8;
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::Enums';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrill';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillCheck';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub BlindDrillChecks {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;    # NC layer with start/end properties
	my $mess  = shift;

	my $result = 1;

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, [$layer] );

	my $stackup = Stackup->new($inCAM, $jobId);
	my $uniDTM  = UniDTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 0 );
	my @tools   = $uniDTM->GetUniqueTools();

	foreach my $tool (@tools) {

		print STDERR "TOOL SIZE: " . $tool->GetDrillSize() . "\n";

		my $toolOk = 1;
		my $ettStr = "";

		my %resType = ();
		my $drillType = BlindDrill->GetDrillType( $stackup, $tool->GetDrillSize(), $layer, \%resType );

		unless ($drillType) {

			my $t1 = $resType{ Enums->BLINDTYPE_STANDARD };
			my $t2 = $resType{ Enums->BLINDTYPE_SPECIAL };

			$toolOk = 0;
			$ettStr .= " Nelze vyrobit slepý otvor pomocí žádné metody výpočtu hloubky:\n";
			$ettStr .= "	".Enums->GetMethodName(Enums->BLINDTYPE_STANDARD).":\n";
			$ettStr .= "	- Aspect ratio otvoru: " . ( $t1->{"arOk"} ? "OK" : "FAIL" ) . " (požadované <=1.0, aktuální: " . sprintf("%.2f",$t1->{"ar"}) . ") \n";
			$ettStr .=
			    "	- Minimální izolace špičky vrtáku od Cu ("
			  . $t1->{"requestedIsolCuLayer"} . "): "
			  . ( $t1->{"isolOk"} ? "OK" : "FAIL" )
			  . " (požadovaná: "
			  . int($t1->{"requestedIsolThick"})
			  . " µm, aktuální: "
			  . int($t1->{"currentIsolThick"})
			  . " µm) \n";
			$ettStr .= "	".Enums->GetMethodName(Enums->BLINDTYPE_SPECIAL).":\n";
			$ettStr .= "	- Aspect ratio otvoru: " . ( $t2->{"arOk"} ? "OK" : "FAIL" ) . " (požadované <=1.0, aktuální: " . sprintf("%.2f",$t2->{"ar"}) . ") \n";
			$ettStr .=
			    "	- Minimální izolace špičky vrtáku od Cu ("
			  . $t1->{"requestedIsolCuLayer"} . "): "
			  . ( $t2->{"isolOk"} ? "OK" : "FAIL" )
			  . " (požadovaná: "
			  . int($t2->{"requestedIsolThick"})
			  . " µm, aktuální: "
			  . int($t2->{"currentIsolThick"})
			  . " µm) \n\n";
		}
		else {
			# Check drill depth
			my %resultDepth = ();
			unless ( BlindDrillCheck->CheckDrillDepth( $stackup, $tool->GetDrillSize(), $tool->GetDepth() * 1000, $layer, \%resultDepth ) ) {

				$toolOk = 0;

				$ettStr .=
				    "- Špatná hloubka vrtání ("
				  . $tool->GetDepth()*1000
				  . "µm), není v toloeranci +-10µm s vypočítanou hloubkou: "
				  . int($resultDepth{"computedDepth"}) . "µm, metoda výpočtu: ".Enums->GetMethodName($drillType)."\n\n";
			}
		}

		unless ($toolOk) {

			$result = 0;
			$$mess .= "- Otvor: " . $tool->GetDrillSize() . "µm:$ettStr";
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Stackup::Stackup::Stackup';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";
	my $step  = "o+1";

	my $stackup = Stackup->new($jobId);

	my %res = ();

	my %l = ( "gROWname" => "sc1" );

	my $mess = "";
	my $r = BlindDrillInfo->BlindDrillChecks( $inCAM, $jobId, $step, \%l, \$mess );

	print "Result:" . $r . "\n" . $mess;

}

1;
