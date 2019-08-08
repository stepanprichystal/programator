#-------------------------------------------------------------------------------------------#
# Description: Helper guids for setting tool in DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::DoSetDTM;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max min];

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# If exist pads larger than available tool in CNC department, move them to suitable rout layer
# countorize and set rout.
# Ignore nested steps if exist
sub MoveHoles2RoutBeforeDTMRecalc {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layer     = shift;
	my $routLayer = shift;    # Rout layer where too big pads will be moved
	my $DTMType   = shift;    # Type which will be used for set DTM tools EnumsDrill->DTM_VRTANE / EnumsDrill->DTM_VYSLEDNE

	die "Rout layer is not defined" unless ( defined $routLayer );
	die "DTM type is not defined"   unless ( defined $DTMType );

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my @tool    = CamDTM->GetToolTable( $inCAM, 'drill' );
	my $maxTool = max(@tool) * 1000;                         # in µm
	my $plating = 100;                                       # 100µm

	my @tools = grep { $_->{"gTOOLshape"} eq "hole" } CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, 0 );

	my @moveTools = ();

	if ( $DTMType eq EnumsDrill->DTM_VRTANE ) {

		@moveTools = grep { $_->{"gTOOLfinish_size"} > $maxTool } @tools;

	}
	elsif ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {

		# If DTM type will be set to DTM_VYSLEDNE, consider tool size $maxTool -

		my @tmpTools = grep { $_->{"gTOOLfinish_size"} > $maxTool - $plating } @tools;

		foreach my $t (@tmpTools) {

			my $size = CamDTM->GetDrillSizeByTool( $inCAM, $jobId, $step, $layer, $DTMType, $t->{"gTOOLnum"} );
			push( @moveTools, $t ) if ( $size == 0 );

			die "Hole (number: " . $t->{"gTOOLnum"} . ") has to by type: \"plated\" if DTM type is \"" . $DTMType . "\""
			  if ( $t->{"gTOOLtype"} ne "plated" );
		}
	}

	if (@moveTools) {
		
		CamLayer->WorkLayer($inCAM, $layer);

		my $mess = "V DTM ve vrstvě: \"$layer\" byly nalezeny velké otvory, pro které nemáme nástroj na skladě:\n";

		foreach my $t (@moveTools) {

			$mess .= " - Číslo nástroje: <b>" . $t->{"gTOOLnum"} . "</b>\n";
			$mess .= " - Finish size: <b>" . $t->{"gTOOLfinish_size"} . "µm</b>\n";
			$mess .= " - Typ otvoru: <b>" . $t->{"gTOOLtype"} . "</b>\n\n";

			if ( $DTMType eq EnumsDrill->DTM_VYSLEDNE && $t->{"gTOOLtype"} ne "plated" ) {
				$mess .= "  <r>Pozor nástroj není typu : \"plated\" " . $t->{"gTOOLtype"} . "</r>\n";
			}
		}

		$mess .= "<r>Zvol jednu z možností:</r>";
		my $options = "Konturizovat";
		$options .= " + Přesunout do: $routLayer" if ( $layer ne $routLayer );

		if ( $DTMType eq EnumsDrill->DTM_VRTANE ) {

			my @btn = ();

			push( @btn, "Nic nedělat" );
			push( @btn, $options );
			push( @btn, $options . " + vytvořit pojezd d=2mm" );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, [$mess], \@btn );

			if ( $messMngr->Result() == 0 ) {

				return 0;
			}
			elsif ( $messMngr->Result() == 1 ) {

				$self->__MoveToRoutLayer( $inCAM, $jobId, \@moveTools, $layer, $routLayer, 0, 0 );
			}
			elsif ( $messMngr->Result() == 2 ) {

				$self->__MoveToRoutLayer( $inCAM, $jobId, \@moveTools, $layer, $routLayer, 1, 0 );
			}

		}
		elsif ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {

			my @btn = ();

			push( @btn, "Nic nedělat" );
			push( @btn, $options . " + zvětšit" );
			push( @btn, $options . " + zvětšit + vytvořit pojezd d=2mm" );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, [$mess], \@btn );

			if ( $messMngr->Result() == 0 ) {

				return 0;
			}
			elsif ( $messMngr->Result() == 1 ) {

				$self->__MoveToRoutLayer( $inCAM, $jobId, \@moveTools, $layer, $routLayer, 0, $plating );

			}
			elsif ( $messMngr->Result() == 2 ) {

				$self->__MoveToRoutLayer( $inCAM, $jobId, \@moveTools, $layer, $routLayer, 1, $plating );

			}
		}
	}

	return $result;
}

sub __MoveToRoutLayer {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my @tools       = @{ shift(@_) };
	my $srcLayer    = shift;
	my $targetLayer = shift;
	my $prepareRout = shift;
	my $resize      = shift // 0;       # Resize by value of plating

	my $routTool = 2;                   # rout tool 2mm

	CamLayer->WorkLayer( $inCAM, $srcLayer );

	my @dcoded = map { $_->{"gTOOLnum"} } @tools;

	die "Error during move pads from layer: $srcLayer" unless ( CamFilter->ByDCodes( $inCAM, \@dcoded ) );

	my $lTmp = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lTmp, "rout" );
	CamLayer->MoveSelOtherLayer( $inCAM, $lTmp, 0, $resize );
	CamLayer->WorkLayer( $inCAM, $lTmp );
	CamLayer->Contourize( $inCAM, $lTmp );
	CamLayer->WorkLayer( $inCAM, $lTmp );

	if ($prepareRout) {

		$inCAM->COM(
					 'chain_add',
					 "layer" => $lTmp,
					 "size"  => $routTool,
					 "comp"  => "right"
		);
		$inCAM->COM("sel_all_feat");

		$inCAM->COM("chain_list_reset");

		$inCAM->COM(
					 "chain_pocket",
					 "layer"      => $lTmp,
					 "mode"       => "concentric",
					 "size"       => $routTool,
					 "feed"       => "0",
					 "overlap"    => "0.9",
					 "pocket_dir" => "standard"
		);
	}

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $targetLayer ) ) {

		my $mExist = CamHelper->LayerExists( $inCAM, $jobId, "m" );
		CamMatrix->CreateLayer( $inCAM, $jobId, $targetLayer, "rout", "positive", 1, ( $mExist ? "m" : "" ), "after" );
	}

	CamLayer->MoveSelOtherLayer( $inCAM, $targetLayer, 0, 0 );
	CamLayer->WorkLayer( $inCAM, $srcLayer );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::DoSetDTM';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d252332+1";

	my $typDTM = EnumsDrill->DTM_VRTANE;    # EnumsDrill->DTM_VRTANE/ EnumsDrill->DTM_VYSLEDNE

	# Uprava velkych otvoru pro f vrstvu
	my $res = DoSetDTM->MoveHoles2RoutBeforeDTMRecalc( $inCAM, $jobId, "o+1", "f", "f", $typDTM );

	# Uprava velkzch otvoru pro m

	my $res2 = DoSetDTM->MoveHoles2RoutBeforeDTMRecalc( $inCAM, $jobId, "o+1", "m", "r", $typDTM );

}

1;

