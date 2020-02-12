#-------------------------------------------------------------------------------------------#
# Description: Prepare special helper layers for creating coverlay
# and prepreg pins for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoBendArea;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::Enums' => 'EnumsBend';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<b>=======================================================</b>" );
push( @messHead, "<b>Průvodce vytvořením vrstvy bend area</b>" );
push( @messHead, "<b>=======================================================</b> \n" );

sub CreateBendArea {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $lName = "bend";

	my $type = JobHelper->GetPcbType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbType_RIGIDFLEXI && $type ne EnumsGeneral->PcbType_RIGIDFLEXO );

	CamHelper->SetStep( $inCAM, $step );

	my $createLayer = 1;

	my @mess = (@messHead);
	push( @mess, "Vrstva \"$lName\" již existuje, chceš ji vytvořit znovu?" );

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Ne", "Ano, vytvořit" ] );

		$createLayer = 0 if ( $messMngr->Result() == 0 );
	}

	if ($createLayer) {
		$self->__CreateBendArea( $inCAM, $jobId, $step, $lName, $messMngr );
	}

	my $errMess = "";

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );

	while ( !$parser->CheckBendArea( \$errMess ) ) {

		my @mess = (@messHead);
		push( @mess, "Vrstva \"$lName\" není správně připravená", "Detail chyby:", $errMess );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "Konec", "Znovu vytvořit", "Opravím" ] );

		if ( $messMngr->Result() == 0 ) {

			return 0;
		}
		elsif ( $messMngr->Result() == 1 ) {

			$self->__CreateBendArea( $inCAM, $jobId, $step,$lName, $messMngr );
		}
		elsif ( $messMngr->Result() == 2 ) {

			$inCAM->PAUSE("Oprav vrstvu: \"bend\"");
		}

		$errMess = "";
	}

	return $result;
}

sub __CreateBendArea {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $lName    = shift;
	my $messMngr = shift;

	my $result = 1;

	CamMatrix->DeleteLayer( $inCAM, $jobId, $lName );
	CamMatrix->CreateLayer( $inCAM, $jobId, $lName, "bend_area", "positive", 1 );

	CamLayer->WorkLayer( $inCAM, $lName );

	# 1) Create border of flexible PCB parts

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lName );

	while ( $hist{"total"} == 0 ) {

		my @mess = (@messHead);
		push( @mess, "Vytvoř obrysy pružných částí ve vrstvě: \"$lName\". Obrys musí být cyklický." );

		my @layers = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "document" } CamJob->GetAllLayers( $inCAM, $jobId );
		my $def = scalar( grep { $_ eq "o" } @layers ) ? "o" : $layers[0];

		my $parLData = $messMngr->GetOptionParameter( "Zkopírovat data z vrstvy:", $def, \@layers );
		my @params = ($parLData);

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
							  \@mess, [ "Zkopopírovat data z vybrané vrstvy", "Vytvořím ručně" ],
							  undef, \@params );

		if ( $messMngr->Result() == 0 ) {

			CamLayer->WorkLayer( $inCAM, $parLData->GetResultValue(1) );
			CamLayer->CopySelOtherLayer( $inCAM, [$lName] );
			CamLayer->WorkLayer( $inCAM, $lName );
		}

		$inCAM->PAUSE("Vytvor obrysy pruznych casti");

		%hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lName );
	}

	# 2) Check if rout is cyclic

	my $isCyclic = 0;

	while ( !$isCyclic ) {

		my $polyLine = PolyLineFeatures->new();
		$polyLine->Parse( $inCAM, $jobId, $step, $lName );

		if ( $polyLine->GetPolygonsAreCyclic() ) {
			$isCyclic = 1;
		}
		else {

			my @mess = (@messHead);
			push( @mess, "Některý obrys pružné vrstvy není cyklický, oprav to." );

			my @layers = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "document" } CamJob->GetAllLayers( $inCAM, $jobId );
			my $def = scalar( grep { $_ eq "o" } @layers ) ? "o" : $layers[0];

			my $parLData = $messMngr->GetOptionParameter( "Zkopírovat data z", $def, \@layers );
			my @params = ($parLData);

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
								  \@mess, [ "Zkopopírovat data vrstvy", "Vytvořím ručně" ],
								  undef, \@params );

			$inCAM->PAUSE("Oprav obrys tak aby byl cyklický");
		}
	}

	my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step, $lName );

	my $tranZoneOk = 0;
	while (!$tranZoneOk) {

		my $errText = "";

		my @mess = (@messHead);
		push( @mess, "Vyber lajny kde má DPS tranzitní zónu, resp. hranice mezi pevnou a pružnou částí" );
		push( @mess, "Pouze feature type: \"line\" je povolený jako tranzitní zóna" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, );

		$inCAM->PAUSE("Oznac tranzitni zony");

		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $step, $lName, 0, 1 );

		my @features = $f->GetFeatures();

		if ( !scalar(@features) ) {
			$tranZoneOk = 0;
			$errText .= "Nebyly označeny žádné features.\n";

		}
		elsif ( scalar( grep { $_->{"type"} !~ /^[LA]$/i } @features ) ) {
			$tranZoneOk = 0;
			$errText .= "Označené features nejsou typu \"line\" nebo \"arc\"\n";
		}
		else {
			CamAttributes->SetFeatuesAttribute( $inCAM, EnumsBend->BendArea_TRANZONEATT );
			$tranZoneOk = 1;
		}

		unless ($tranZoneOk) {

			@mess = (@messHead);
			push( @mess, "Chyby při označení tranzitní zóny: $errText" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, );
		}
	}

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoBendArea';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d266089";

	my $notClose = 0;

	my $res = DoBendArea->CreateBendArea( $inCAM, $jobId, "o+1" );

}

1;

