#-------------------------------------------------------------------------------------------#
# Description: Set impedance lines
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Impedance::DoSetImpLines;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::CAM::InStackJob::InStackJob';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Set impedance lines
sub SetImpedanceLines {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	return $result if ( HegMethods->GetPcbIsPool($jobId) );

	# Find InStack xml
	my $path = EnumsPaths->Jobs_COUPONS . "$jobId.xml";
	while ( !-e $path ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Nebylo nalezeno InStack složení ($path). Vyexportuj je."] );
	}

	# Parse  XML xonstraints
	my $inStackJob = InStackJob->new($jobId);

	my @steps = grep { $_ =~ /^o\+\d+$/ } CamStep->GetAllStepNames( $inCAM, $jobId );

	foreach my $step (@steps) {

		CamHelper->SetStep( $inCAM, $step );

		foreach my $constraint ( sort { $a->GetTrackLayer(1) cmp $b->GetTrackLayer(1) } $inStackJob->GetConstraints() ) {

			$self->__SetImpedanceLine( $inCAM, $jobId, $step, $constraint, scalar( $inStackJob->GetConstraints() ), $messMngr );

		}
	}

	return $result;
}

sub __SetImpedanceLine {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $step           = shift;
	my $constraint     = shift;
	my $totalConstrCnt = shift;
	my $messMngr       = shift;

	my $l = $constraint->GetTrackLayer(1);

	CamLayer->WorkLayer( $inCAM, $l );

	my $cId      = $constraint->GetId();
	my $cType    = $constraint->GetType();
	my $cModel   = $constraint->GetModel();
	my $lineWOri = sprintf( "%.0f", $constraint->GetOption( "ORIGINAL_TRACE_WIDTH", 1 ) );
	my $lineWReq = sprintf( "%.0f", $constraint->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
	my $impVal   = $constraint->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");

	my @imgs = ();
	my $p    = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\small_" . $cType . "_" . $cModel . ".bmp";
	push( @imgs, [ 1, $p, &Wx::wxBITMAP_TYPE_BMP ] );

	my @mess = ();
	push( @mess, "Označení impedančních vodičů: $cId/$totalConstrCnt (atribut \".imp_constraint_id\")" );
	push( @mess, "=========================================\n" );
	push( @mess, " <b>Impedance</b> - Constraint id: <b>$cId</b>\n" );

	push( @mess, "- Typ: <img1> " . ValueConvertor->GetImpedanceType($cType) . " + $cModel" );
	push( @mess, "- Vrstva: <b>$l</b>" );
	push( @mess, "- Impedance: <b>$impVal ohm</b>" );
	push( @mess, "- Původní šířka: <b>$lineWOri µm</b>" );
	push( @mess, "- Požadovaná šířka: <b>$lineWReq µm</b>" );

	push( @mess, "\nOznač cesty, které mají splňovat danou impedanci." );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Přeskočit", "Zkusím štěstí", "Označím ručně" ], \@imgs );

	if ( $messMngr->Result() == 0 ) {

		# skip
		return 0;
	}
	elsif ( $messMngr->Result() == 1 ) {

		# auto

		$self->__AutoSelect( $inCAM, $constraint );
		$self->__PAUSE( $inCAM, "select_auto", $constraint );

	}
	elsif ( $messMngr->Result() == 2 ) {

		#manual
		$self->__PAUSE( $inCAM, "select_manual", $constraint );

	}

	while (1) {

		my $skip = 0;
		my $checkFeatOk = $self->__CheckSelectedLines( $inCAM, $jobId, $step, $l, $constraint, $messMngr, \$skip );

		return 0 if ($skip);

		my @mess2 = ();

		if ($checkFeatOk) {

			my $f = Features->new();

			$f->Parse( $inCAM, $jobId, $step, $l, 0, 1 );
			my @feats = $f->GetFeatures();

			my @mess = ();

			push( @mess, "<g>Označené cesty budou nastaveny jako impedanční.</g>" );
			push( @mess, "Atribut: <b>\".imp_constraint_id\" = $cId</b>\n" );
			push( @mess, "Přejete si cesty zároveň i zvětšit na požadovanou šířku?" );
			push( @mess, "Original width: <b>$lineWOri um</b>; " );
			push( @mess, "Requested width: <b>$lineWReq um</b>; " );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
								  \@mess, [ "Ne, pouze nastavit impedanci", "Ano nastavit a upravit šířku" ], \@imgs );

			if ( $messMngr->Result() == 0 ) {

				$self->__SetImpedanceLineAttr( $inCAM, $jobId, $constraint, 0, \@feats );

			}
			elsif ( $messMngr->Result() == 1 ) {
				$self->__SetImpedanceLineAttr( $inCAM, $jobId, $constraint, 1, \@feats );

			}

			last;
		}

	}

	return 1;
}

sub __AutoSelect {
	my $self       = shift;
	my $inCAM      = shift;
	my $constraint = shift;

	my $lineWOri = sprintf( "%.0f", $constraint->GetOption( "ORIGINAL_TRACE_WIDTH", 1 ) );

	print STDERR "Search lines width: $lineWOri";

	CamFilter->BySymbols( $inCAM, [ "r" . $lineWOri, "s" . $lineWOri ] );

}

sub __CheckSelectedLines {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $layer      = shift;
	my $constraint = shift;
	my $messMngr   = shift;
	my $skip       = shift;

	my $f = Features->new();

	$f->Parse( $inCAM, $jobId, $step, $layer, 0, 1 );
	my @feats = $f->GetFeatures();

	my $cId      = $constraint->GetId();
	my $cType    = $constraint->GetType();
	my $cModel   = $constraint->GetModel();
	my $lineWOri = sprintf( "%.0f", $constraint->GetOption( "ORIGINAL_TRACE_WIDTH", 1 ) );
	my $lineWReq = sprintf( "%.0f", $constraint->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
	my $impVal   = $constraint->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");

	# image collection for message form
	my @imgs = ();
	my $p    = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\small_" . $cType . "_" . $cModel . ".bmp";
	push( @imgs, [ 1, $p, &Wx::wxBITMAP_TYPE_BMP ] );

	# check if lines are selected

	if ( !CamLayer->GetSelFeaturesCnt($inCAM) ) {

		my @mess2 = ();

		push( @mess2, "<r>Nebyly vybrány žádné impedanční cesty!</r>." );
		push( @mess2, "Označ cesty, které mají splňovat danou impedanci.\n" );

		push( @mess2, " <b>Impedance</b> - Constraint id: <b>$cId</b>\n" );
		push( @mess2, "- Typ: <img1> " . ValueConvertor->GetImpedanceType($cType) . " + $cModel" );
		push( @mess2, "- Vrstva: <b>$layer</b>" );
		push( @mess2, "- Impedance: <b>$impVal ohm</b>" );
		push( @mess2, "- Původní šířka: <b>$lineWOri µm</b>" );
		push( @mess2, "- Požadovaná šířka: <b>$lineWReq µm</b>" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
							  \@mess2, [ "Přeskočit", "Zkusím štěstí", "Označím ručně" ], \@imgs );

		if ( $messMngr->Result() == 0 ) {
			
			# skip
			$$skip = 1;
			return 1;
		}
		elsif ( $messMngr->Result() == 1 ) {

			# auto
			$self->__AutoSelect( $inCAM, $constraint );
			$self->__PAUSE( $inCAM, "select_auto", $constraint );
			return 0;
		}
		elsif ( $messMngr->Result() == 2 ) {

			# manual
			$self->__PAUSE( $inCAM, "select_manual", $constraint );
			return 0;
		}

	}

	# check if all lines are type of: arc, pad
	my @wrongType = grep { $_->{"type"} ne "A" && $_->{"type"} ne "L" } @feats;

	if (@wrongType) {

		my @mess = ();

		push( @mess, "<r>Vybrané cesty obsahují jiný typ symbolu než povolené typy: line, arc.</r>" );
		push( @mess, "Oprav to.\n" );
		push( @mess, "Id zmiňovaných features: <b>" . join( "; ", map { $_->{"id"} } @wrongType ) . "</b>" );
		push( @mess, "\nChcete přesto nastavit impedančná cesty?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, ["Ano, nastavit", "Ne, opravím to" ] );

		if ( $messMngr->Result() == 1 ) {

			$self->__PAUSE( $inCAM, "correct_select", $constraint );

			return 0;
		}
	}

	# check if selected lines have right width
	my @wrongWidth = grep { $_->{"thick"} != $lineWOri } @feats;

	if (@wrongWidth) {

		my @mess = ();

		push( @mess,
			  "<r>Vybrané cesty jsou jiného průměru než je uvedený originální průměr v Impedance constraint id: <b>$cId</b>.</r>\n" );

		push( @mess, "- Typ: <img1> " . ValueConvertor->GetImpedanceType($cType) . " + $cModel" );
		push( @mess, "- Vrstva: <b>$layer</b>" );
		push( @mess, "- Impedance: <b>$impVal ohm</b>" );
		push( @mess, "- Původní šířka: <b>$lineWOri µm</b>" );
		push( @mess, "- Požadovaná šířka: <b>$lineWReq µm</b>" );

		push( @mess, "\nId zmiňovaných features: <b>" . join( "; ", map { $_->{"id"} } @wrongWidth ) . "</b>" );

		push( @mess, "\nChcete přesto nastavit impedančná cesty?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "Ano, nastavit", "Ne, opravím to" ], \@imgs );

		if ( $messMngr->Result() == 1 ) {

			$self->__PAUSE( $inCAM, "correct_select", $constraint );

			return 0;
		}
	}

	# check if selected lines do not have already contraintId attribut filled
	my @wrongCId =
	  grep { defined $_->{"att"}->{".imp_constraint_id"} && $_->{"att"}->{".imp_constraint_id"} ne "" && $_->{"att"}->{".imp_constraint_id"} != $cId }
	  @feats;

	if (@wrongCId) {

		my @mess = ();

		push( @mess,
"<r>Některé vybrané cesty jsou již označeny jako impedanční cesty, ale označení neodpovídá impedanci: Impedance constraint id: <b>$cId</b>.</r>"
		);

		push( @mess, "Typ impedance (Impedance constraints) je uložen ve feature v atributu \".imp_constraint_id\"\n" );

		push( @mess, "Id zmiňovaných features: <b>" . join( "; ", map { $_->{"id"} } @wrongCId ) . "</b>" );

		push( @mess, "\nChcete přesto nastavit impedančná cesty?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [  "Ano, nastavit", "Ne, opravím to" ] );

		if ( $messMngr->Result() == 1 ) {

			$self->__PAUSE( $inCAM, "correct_select", $constraint );

			return 0;
		}
	}

	return 1;
}

sub __SetImpedanceLineAttr {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $constraint = shift;
	my $resize     = shift;
	my $feats      = shift;

	my $cId      = $constraint->GetId();
	my $cType    = $constraint->GetType();
	my $cModel   = $constraint->GetModel();
	my $lineWOri = sprintf( "%.0f", $constraint->GetOption( "ORIGINAL_TRACE_WIDTH", 1 ) );
	my $lineWReq = sprintf( "%.0f", $constraint->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
	my $impVal   = $constraint->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");

	# set constraint ID
	CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".imp_constraint_id", $cId );

	# resize features
	if ($resize) {

		my @featId = map { $_->{"id"} } @{$feats};
		CamFilter->SelectByFeatureIndexes( $inCAM, $jobId, \@featId );

		$inCAM->COM( "sel_change_sym", "symbol" => "r$lineWReq" );
	}

	return 1;
}

# Pause script by type
# - select_auto
# - select_manual
# - correct_select
sub __PAUSE {
	my $self       = shift;
	my $inCAM      = shift;
	my $type       = shift;    #
	my $constraint = shift;

	my $cId      = $constraint->GetId();
	my $cType    = $constraint->GetType();
	my $cModel   = $constraint->GetModel();
	my $lineWOri = sprintf( "%.0f", $constraint->GetOption( "ORIGINAL_TRACE_WIDTH", 1 ) );
	my $lineWReq = sprintf( "%.0f", $constraint->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
	my $impVal   = $constraint->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");

	my $mess = "";

	if ( $type eq "select_auto" ) {

		$mess .= "Zkontroluj automaticky oznacene impedancni cesty: <b>" . ValueConvertor->GetImpedanceType($cType) . " + $cModel</b>;";
		$mess .= "Constraint id: <b>$cId</b>; ";
		$mess .= "Original width: <b>$lineWOri um</b>; ";
		$mess .= "Requested width: <b>$lineWReq um</b>; ";

	}
	elsif ( $type eq "select_manual" ) {

		$mess .= "Oznac impedancni cesty: <b>" . ValueConvertor->GetImpedanceType($cType) . " + $cModel</b>;";
		$mess .= "Constraint id: <b>$cId</b>; ";
		$mess .= "Original width: <b>$lineWOri um</b>; ";
		$mess .= "Requested width: <b>$lineWReq um</b>; ";

	}
	elsif ( $type eq "correct_select" ) {

		$mess .= "Oprav impedancni cesty a oznac je: <b>" . ValueConvertor->GetImpedanceType($cType) . " + $cModel</b>;";
		$mess .= "Constraint id: <b>$cId</b>; ";
		$mess .= "Original width: <b>$lineWOri um</b>; ";
		$mess .= "Requested width: <b>$lineWReq um</b>; ";

	}

	$inCAM->PAUSE($mess);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Impedance::DoSetImpLines';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d113608";

	my $notClose = 0;

	my $res = DoSetImpLines->SetImpedanceLines( $inCAM, $jobId );

}

1;

