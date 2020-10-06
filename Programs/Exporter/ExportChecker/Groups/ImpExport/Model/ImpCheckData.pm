
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::InStackJob::InStackJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamStepRepeatPnl';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";

	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# 1) If export is not checked, check if
	if ( !$groupData->GetBuildMLStackup() ) {

		$dataMngr->_AddErrorResult( "MultiCal stackup",
					   "MultiCal stackup by měl být vždy vygenerován z InStack stackupu, aby bylo do IS načteno aktuální InStack složení." );
	}

	# 2) Error when measurement pdf is not checked
	if ( !$groupData->GetExportMeasurePdf() ) {

		$dataMngr->_AddErrorResult( "Measurement PDF",
									"Kontrolní PDF soubor pro měření impedancí by měl být vždy pro výrobu vyexportován." );
	}

	# 3) Go through all constraint id and search if they are present in job
	my $inStackJob = InStackJob->new($jobId);
	foreach my $c ( $inStackJob->GetConstraints() ) {

		my $trackL = $c->GetTrackLayer(1);

		my @steps = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

		my $impPresent = 0;

		# Some impedance have not to by present in all steps, so merge attributes from all step together
		my %attHist = {};
		foreach my $step (@steps) {

			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step->{"stepName"}, $c->GetTrackLayer(1), 1 );

			#%attHist = (%attHist, %attHistStep);

			if ( grep { $_ == $c->GetId() } @{ $attHist{".imp_constraint_id"} } ) {
				$impPresent = 1;
				last;
			}
		}

		unless ($impPresent) {
			my $impStr = "";

			my $cId      = $c->GetId();
			my $cType    = $c->GetType();
			my $cModel   = $c->GetModel();
			my $lineWReq = sprintf( "%.0f", $c->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
			my $impVal   = $c->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");

			$impStr .= "\n- Constraint id: " . $c->GetId() . " (attribut: \".imp_constraint_id\")";
			$impStr .= "\n- Vrstva: $trackL";
			$impStr .= "\n- Typ: " . ValueConvertor->GetImpedanceType($cType) . " + $cModel";
			$impStr .= "\n- Impedance: $impVal ohm";
			$impStr .= "\n- Šířka cesty: $lineWReq µm";

			$dataMngr->_AddErrorResult( "Impedance line", "Impedanční cesta nebyla nalezena v signálové vrstvě: \"$trackL\" $impStr" );
		}

	}

	# 4) go through all impedance line and check computed width with real line width
	foreach my $c ( $inStackJob->GetConstraints() ) {

		my $cId      = $c->GetId();
		my $cType    = $c->GetType();
		my $cModel   = $c->GetModel();
		my $lineWReq = sprintf( "%.0f", $c->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );
		my $impVal   = $c->GetOption("CUSTOMER_REQUIRED_IMPEDANCE");
		my $trackL   = $c->GetTrackLayer(1);
		my $compW    = sprintf( "%.0f", $c->GetOption( "CALCULATED_TRACE_WIDTH", 1 ) );

		my @steps = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

		foreach my $step (@steps) {

			my $f = Features->new();

			$f->Parse( $inCAM, $jobId, $step->{"stepName"}, $trackL, 1 );
			my @feats = grep { $_->{"type"} =~ /^[LA]$/ } $f->GetFeatures();
			@feats = grep { $_->{"att"}->{".imp_constraint_id"} == $cId } @feats;

			next unless (@feats);

			my @wrongW = grep { $_->{"thick"} != $compW } @feats;

			if (@wrongW) {
				my $impStr = "";
				$impStr .= "\n- Constraint id: " . $c->GetId() . " (attribut: \".imp_constraint_id\")";
				$impStr .= "\n- Vrstva: $trackL";
				$impStr .= "\n- Typ: " . ValueConvertor->GetImpedanceType($cType) . " + $cModel";
				$impStr .= "\n- Impedance: $impVal ohm";
				$impStr .= "\n- Vypočítaná šířka cesty: $lineWReq µm";

				$dataMngr->_AddErrorResult(
											"Impedance line",
											"Impedanční cesty (features: "
											  . join( "; ", map { $_->{"id"} } @wrongW )
											  . " ) mají nastavenou špatnou šířku lajny.\n$impStr"
				);
			}
		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

