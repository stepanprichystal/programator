
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepariong text file with information about exported job
# and layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::OutputInfo;

#3th party library
use threads;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

use Time::localtime;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums' => "EnumsOutput";
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::TifFile::TifScore';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::Marking::MarkingULLogo';
use aliased 'Helpers::ValueConvertor';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"step"}     = shift;
	$self->{"filesDir"} = shift;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @lines = ();

	# Head of file

	my $time = sprintf "%02.f:%02.f:%02.f", localtime->hour(), localtime->min(), localtime->sec();
	my $date = sprintf "%02.f.%02.f.%04.f", localtime->mday(), ( localtime->mon() + 1 ), ( localtime->year() + 1900 );

	push( @lines, "------------------------------------------------------------------------" );
	push( @lines, " Information about pcb data number: " . uc( $self->{"jobId"} ) );
	push( @lines, "------------------------------------------------------------------------" );
	push( @lines, "" );
	push( @lines, $self->__CompleteLine( " Pcb:", uc( $self->{"jobId"} ) ) );
	push( @lines, $self->__CompleteLine( " Export date:", "$date at $time" ) );
	push( @lines, $self->__CompleteLine( " Contact:", 'cam@gatema.cz' ) );

	push( @lines, "" );

	# Layers
	push( @lines, "------------------------------------------------------------------------" );
	push( @lines, " Exported files " );
	push( @lines, "------------------------------------------------------------------------" );

	push( @lines, "" );

	push( @lines, " Board layers:" );
	push( @lines, "" );

	foreach my $l ( $layerList->GetLayersByType( EnumsOutput->Type_BOARDLAYERS ) ) {

		push( @lines, $self->__CompleteLine( " - " . $l->GetName() . ".ger", $l->GetTitle() . $self->__GetInfo($l) ) );

	}

	push( @lines, "" );

	push( @lines, " Mechanic layers:" );
	push( @lines, "" );

	foreach my $l ( ( $layerList->GetLayersByType( EnumsOutput->Type_NCLAYERS ), $layerList->GetLayersByType( EnumsOutput->Type_NCDEPTHLAYERS ) ) ) {

		push( @lines, $self->__CompleteLine( " - " . $l->GetName() . ".ger", $l->GetTitle() . $self->__GetInfo($l) ) );

	}

	my @specSurf = $layerList->GetLayersByType( EnumsOutput->Type_SPECIALSURF );

	if ( scalar(@specSurf) ) {

		push( @lines, "" );

		push( @lines, " Special surface layers:" );
		push( @lines, "" );

		foreach my $l (@specSurf) {

			push( @lines, $self->__CompleteLine( " - " . $l->GetName() . ".ger", $l->GetTitle() . $self->__GetInfo($l) ) );

		}

	}

	push( @lines, "" );

	push( @lines, " Other files:" );
	push( @lines, "" );

	foreach my $l (
					(
					  $layerList->GetLayersByType( EnumsOutput->Type_OUTLINE ),
					  $layerList->GetLayersByType( EnumsOutput->Type_DRILLMAP ),
					  $layerList->GetLayersByType( EnumsOutput->Type_FILLEDHOLES )
					)
	  )
	{

		push( @lines, $self->__CompleteLine( " - " . $l->GetName() . ".ger", $l->GetTitle() . $self->__GetInfo($l) ) );

	}

	# Add info about extra files (stackup etc)
	if ( $self->{"layerCnt"} > 2 ) {
		push( @lines, $self->__CompleteLine( " - " . $self->{"jobId"} . "stackup.pdf", "Pcb stackup" ) );
	}

	push( @lines, "" );

	push( @lines, "------------------------------------------------------------------------" );
	push( @lines, " Important notes " );
	push( @lines, "------------------------------------------------------------------------" );

	push( @lines, "" );

	# 1) Finish diameters
	push( @lines, " - All diameters in data are finish diameters!" );

	# 2) Gold finger count
	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) && CamGoldArea->GoldFingersExist( $inCAM, $jobId, $step, "c" ) ) {
		my $cnt = CamGoldArea->GetGoldFingerCount( $inCAM, $jobId, $step, "c" );
		push( @lines, " - Gold finger from TOP (count: $cnt)" );
	}

	if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) && CamGoldArea->GoldFingersExist( $inCAM, $jobId, $step, "s" ) ) {
		my $cnt = CamGoldArea->GetGoldFingerCount( $inCAM, $jobId, $step, "s" );
		push( @lines, " - Gold finger from BOT (count: $cnt)" );
	}

	# 3) Score thickness
	if ( CamHelper->LayerExists( $inCAM, $jobId, "score" ) ) {

		my $sco            = TifScore->new($jobId);
		my $scoreThickness = $sco->GetScoreThick();

		if ( !defined $scoreThickness || $scoreThickness eq "" || $scoreThickness == 0 ) {
			die "Material thickness after scoring is not defined in \"TifFile\"."
			  . " Export \"Score group\" first to store \"Material thickness after scoring\" to Tif file.";
		}

		push( @lines, " - Material thickness after V-scoring is " . $scoreThickness . "mm" );
	}

	# 4) UL logo
	my $ulLogo = HegMethods->GetUlLogoLayer($jobId);
	$ulLogo =~ s/\s//g;
	$ulLogo = lc($ulLogo);
	my @layerNames = split( ",", $ulLogo );
	my @layersJob = MarkingULLogo->GetULLogoLayers( $inCAM, $jobId, "panel" );
	push( @layerNames, @layersJob );

	if ( scalar(@layerNames) ) {

		for ( my $i = 0 ; $i < scalar(@layerNames) ; $i++ ) {
			$layerNames[$i] = ValueConvertor->GetNifCodeValue( $layerNames[$i] );
		}
		push( @lines, " - PCB contains UL logo at layers: " .  join( "; ", uniq(@layerNames) )  );
	}

	my $path = $self->{"filesDir"} . "ReadMe.txt";

	my $f;

	if ( open( $f, ">", $path ) ) {

		foreach my $l (@lines) {

			print $f "\n" . $l;
		}

		close($f);
	}

}

sub __GetInfo {
	my $self = shift;
	my $l    = shift;

	my $inf = "";

	if ( defined $l->GetInfo() && $l->GetInfo() ne "" ) {
		$inf = " (" . $l->GetInfo() . ") ";
	}

	return $inf;
}

sub __CompleteLine {
	my $self      = shift;
	my $leftText  = shift;
	my $rightText = shift;

	my $fillCnt = int( 35 - length($leftText) );    # 30 is requested total title len

	my $fill = "";

	for ( my $i = 0 ; $i < $fillCnt ; $i++ ) {
		$fill .= " ";
	}

	return $leftText . $fill . $rightText;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
