#-------------------------------------------------------------------------------------------#
# Description: Change Cu usage in inner layers in stackup according real usage
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Stackup::DoCuUsageChange;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Path::Tiny qw(path);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::Stackup::StackupConvertor';
use aliased 'Packages::CAMJob::Stackup::StackupCheck';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';

#use aliased 'CamHelpers::CamMatrix';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamLayer';

#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::Polygon::Features::Features::Features';
#use aliased 'CamHelpers::CamAttributes';
#use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
#use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::Enums' => 'EnumsBend';
#use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
#use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<b>=======================================================</b>" );
push( @messHead, "<b> Průvodce úpravou využití Cu vnitřních vrstev ve stackupu</b>" );
push( @messHead, "<b>=======================================================</b> \n" );

sub RepairCuUsage {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	return 0 if ( $layerCnt <= 2 );

	while (1) {

		my $stackup = Stackup->new( $inCAM, $jobId, 1 );

		my @innerCuUsage = ();
		StackupCheck->CuUsageCheck( $inCAM, $jobId, \@innerCuUsage );

		die "No inner layers in list" if ( scalar(@innerCuUsage) == 0 );

		my @mess = (@messHead);

		push( @mess, "Následující tabulka ukazuje rozdíl mezi skutečným využitím Cu ve stepu panel a složením.\n\n" );

		my $stackupTxt = "";
		if ( $stackup->GetStackupSource() eq StackEnums->StackupSource_INSTACK ) {
			$stackupTxt = "InStack  ";
		}
		else {
			$stackupTxt = "Multical ";
		}

		push( @mess, "****************************************************************************************" );
		push( @mess, "|  Vrstva   |  Skutečnost  |  $stackupTxt    |  Rozdíl         |  Status => korekce         " );
		push( @mess, "****************************************************************************************" );

		foreach my $l (@innerCuUsage) {

			my $rowTxt = "";

			my $status = $l->{"status"};

			$rowTxt .= "|   "
			  . $l->{"layer"}
			  . "        | "
			  . sprintf( "%4s%%", int( $l->{"realUsage"} ) )
			  . "         | "
			  . sprintf( "%4s%%", int( $l->{"stackupUsage"} ) )
			  . "        |  ";

			my $diff = $l->{"realUsage"} - $l->{"stackupUsage"};
			my $sign = $diff;

			$diff = sprintf( "%.0f", abs($diff) );

			if ( $sign > 0 ) {
				$diff = sprintf( "%4s", $diff );
				$rowTxt .= "<g>+$diff%</g>";
			}
			elsif ( $sign < 0 ) {
				$diff = sprintf( "%5s", $diff );
				$rowTxt .= "<r>-$diff%</r>";
			}
			else {
				$diff = sprintf( "%4s", $diff );
				$rowTxt .= "  " . $diff . "%";
			}

			$rowTxt .= "        |  ";

			if ( $status eq Packages::CAMJob::Stackup::StackupCheck::USAGE_OK ) {
				$rowTxt .= "<g>OK</g> => v toleranci";
			}
			if ( $status eq Packages::CAMJob::Stackup::StackupCheck::USAGE_OK_EMPTY ) {
				$rowTxt .= "<g>OK</g> => bez motivu";
			}
			elsif ( $status eq Packages::CAMJob::Stackup::StackupCheck::USAGE_INCREASE ) {
				$rowTxt .= "<r>FAIL</r> => automatická";
			}
			elsif ( $status eq Packages::CAMJob::Stackup::StackupCheck::USAGE_DECREASE ) {
				$rowTxt .= "<r>FAIL</r> => ruční + kontrola";
			}

			push( @mess, $rowTxt );

		}

		push( @mess, "\n\nLegenda ke statusům:.\n\n" );
		push( @mess,
			      "<g>OK</g> => v toleranci:  <i>Skutečné využití Cu ve složení je v toleranci +-"
				. Packages::CAMJob::Stackup::StackupCheck::USAGETOL
				. "% a nebude opraveno</i>" );
		push( @mess,
"<g>OK</g> => bez motivu:  <i>Vrstva nemá Cu motiv. Skutečné využití může být > 0% díky fiduciálním značkám v okolí, stackup ale nastavujeme záměrně na 0%</i>"
		);
		push( @mess, "<r>FAIL</r> => automarická: <i>Skutečné využití Cu stouplo a bude automaticky opraveno</i>" );
		push( @mess,
"<r>FAIL</r> => ruční + kontrola:<i> Skutečné využití Cu pokleslo a musí být upraveno ručně s náslenou kontrolou pryskyřice</i>"
		);

		if ( $stackup->GetStackupSource() eq StackEnums->StackupSource_INSTACK ) {

			push( @mess, "\n\n <b>*Upozornění</b>" );
			push( @mess, "- Zdrojové složení je InStack složení, korekce se tedy musí provést (automaticky/ručně) v InStack složení." );
			push( @mess, "- V případě automatické opravy se vygeneruje automaticky i opravené MultiCal složení pro kontrolu pryskyřice." );
		}

		# Check if all layer usage are ok
		my @autoCorrection = ();
		my @manCorrection  = ();
		foreach my $l (@innerCuUsage) {

			push( @autoCorrection, $l ) if ( $l->{"status"} eq Packages::CAMJob::Stackup::StackupCheck::USAGE_INCREASE );
			push( @manCorrection,  $l ) if ( $l->{"status"} eq Packages::CAMJob::Stackup::StackupCheck::USAGE_DECREASE );
		}

		if ( scalar(@autoCorrection) ) {

			my @btn = [
						"Ingnorovat a pokračovat",
						"Upravím vylití vnitřních vrstev",
						"Automaticky opravit složení",
						"Upravil jsem ručně, zkontroluj"
			];
			push( @mess, "\n\nZvol jednu z možností" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, @btn );

			if ( $messMngr->Result() == 0 ) {

				last;
			}
			elsif ( $messMngr->Result() == 1 ) {

				$result = 0;
				last;
			}
			elsif ( $messMngr->Result() == 2 ) {

				# automatic
				my @forCorrect = grep { $_->{"status"} eq Packages::CAMJob::Stackup::StackupCheck::USAGE_INCREASE } @innerCuUsage;
				$self->__AutoCorrection( $inCAM, $jobId, $stackup, \@forCorrect );

			}
			elsif ( $messMngr->Result() == 3 ) {

				# manual
				next;

			}

		}
		elsif ( !scalar(@autoCorrection) && scalar(@manCorrection) ) {

			my @btn = [ "Ingnorovat a pokračovat", "Upravím vylití vnitřních vrstev", "Upravil jsem ručně, zkontroluj" ];
			push( @mess, "\n\nZvol jednu z možností" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, @btn );

			if ( $messMngr->Result() == 0 ) {

				last;

			}
			elsif ( $messMngr->Result() == 1 ) {

				$result = 0;
				last;
			}
			elsif ( $messMngr->Result() == 2 ) {

				# manual
				next;
			}
		}
		else {

			# No autocorrection no manual correction

			my @btn = [ "Upravím vylití vnitřních vrstev", "Pokračovat" ];
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, @btn );

			if ( $messMngr->Result() == 0 ) {

				$result = 0;
				last;

			}
			elsif ( $messMngr->Result() == 1 ) {

				last;
			}
		}

	}

	return $result;
}

# Return:
# - usage_ok = no need to change stackup usage
# - usage_increase
# - usage_decraase

sub __AutoCorrection {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stackup    = shift;
	my @forCorrect = @{ shift(@_) };

	if ( $stackup->GetStackupSource() eq StackEnums->StackupSource_INSTACK ) {

		# Change values in InSTACK stackup

		my $stcFile = EnumsPaths->Jobs_COUPONS . "$jobId.xml";

		my $file = path($stcFile);
		my $data = $file->slurp_utf8;

		foreach my $layerInfo (@forCorrect) {

			my $stackupLayer = $stackup->GetCuLayer( $layerInfo->{"layer"} );
			my $idx          = $stackupLayer->GetCopperNumber();

			my $count = 1;
			while ( $data =~ /COPPER_USAGE/gi ) {

				if ( $idx == $count ) {

					my $usage = sprintf( "%d", $layerInfo->{"realUsage"} );

					$data =~ s/(COPPER_USAGE=\"\w+\")/--$count == 0 ? "COPPER_USAGE=\"$usage\"":$1/ge;
					last;
				}

				$count++;
			}
		}

		$file->spew_utf8($data);

		# Generate multicall stackup for quick check bz TPV
		my $convertor = StackupConvertor->new( $inCAM, $jobId );
		$convertor->DoConvert();

	}
	elsif ( $stackup->GetStackupSource() eq StackEnums->StackupSource_ML ) {

		my $stcFile = FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $jobId );

		my $file = path($stcFile);
		my $data = $file->slurp_utf8;

		foreach my $layerInfo (@forCorrect) {

			my $stackupLayer = $stackup->GetCuLayer( $layerInfo->{"layer"} );
			my $idx          = $stackupLayer->GetCopperNumber();

			my $count = 1;
			while ( $data =~ /type="Copper"/gi ) {

				if ( $idx == $count ) {

					my $usage = sprintf( "%d", $layerInfo->{"realUsage"} );

					$data =~ s/(p=\"\w+\")/--$count == 0 ? "p=\"$usage\"":$1/ge;
					last;
				}

				$count++;
			}
		}

		$file->spew_utf8($data);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Stackup::DoCuUsageChange';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d204007";

	my $notClose = 0;

	my $res = DoCuUsageChange->RepairCuUsage( $inCAM, $jobId );

}

1;

