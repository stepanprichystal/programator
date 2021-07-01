
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportPasteMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path 'rmtree';

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';

use aliased 'Helpers::FileHelper';
use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"pasteInfo"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	unless ( $self->{"pasteInfo"}->{"export"} ) {

		return 0;
	}

	my $notOriginal = $self->{"pasteInfo"}->{"notOriginal"};
	my $zipFile     = $self->{"pasteInfo"}->{"zipFile"};

	my $archive      = JobHelper->GetJobArchive( $self->{"jobId"} ) . "zdroje\\";
	my $archivePaste = $archive . "data_paste";

	unless ( -e $archivePaste ) {
		mkdir($archivePaste) or die "Can't create dir: " . $archivePaste . $_;
	}

	my $dir;
	opendir( $dir, $archivePaste );
	while ( ( my $f = readdir($dir) ) ) {

		next unless $f =~ /^[a-z]/i;

		unlink( $archivePaste . "\\" . $f );

	}
	close $dir;

	$self->__Export($archivePaste);

	if ($notOriginal) {

		if ( open( my $f, '>', $archivePaste . "\\Readme.txt" ) ) {

			print $f "Paste data are not original, but generated from SMD pads in signal layers. Please check before using.";
			close($f);
		}
	}

	if ($zipFile) {
		my $zip = Archive::Zip->new();

		my $dir;
		opendir( $dir, $archivePaste );
		while ( ( my $f = readdir($dir) ) ) {

			next unless $f =~ /^[a-z]/i;

			$zip->addFile( $archivePaste . "\\" . $f, $f );

		}
		close $dir;

		## Add a directory
		#my $dir = $zip->addDirectory( $archivePath . "\\" );

		if ( $zip->writeToFileNamed( $archive . $self->{"jobId"} . "_paste_data.zip" ) == AZ_OK ) {

			rmtree($archivePaste) or die "Cannot rmtree '$archivePaste' : $!";
		}
		else {

			die 'Error when zip paste data files';
		}

	}

}

sub __Export {
	my $self        = shift;
	my $archivePath = shift;

	my $step             = $self->{"pasteInfo"}->{"step"};
	my $addProfile       = $self->{"pasteInfo"}->{"addProfile"};
	my $addSingleProfile = $self->{"pasteInfo"}->{"addSingleProfile"};
	my $addFiducial      = $self->{"pasteInfo"}->{"addFiducial"};
	my @layers           = $self->__GetPasteLayers();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( scalar(@layers) == 0 ) {
		die "No paste layers for export.\n";
	}

	# Remove empty layers (do not export)
	for ( my $i = scalar(@layers) - 1 ; $i >= 0 ; $i-- ) {

		my %h = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $layers[$i] );
		if ( $h{"total"} == 0 ) {
			splice @layers, $i, 1;
		}
	}

	CamHelper->SetStep( $inCAM, $step );

	# 0) Clip all behind profile
	foreach my $l (@layers) {

		CamLayer->ClipAreaByProf( $inCAM, $l, 0, 0, 0 );
	}

	# 1) add profile from  to step
	if ($addProfile) {

		#CamLayer->AffectLayers( $inCAM, @layers );
		#$inCAM->COM('sel_delete');

		foreach my $l (@layers) {

			$inCAM->COM( "profile_to_rout", "layer" => $l, "width" => "200" );
		}
	}

	# 2) add profile from nested steps
	if ($addSingleProfile) {

		my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

		if ( scalar(@uniqueSR) > 0 ) {

			my $lTmp = GeneralHelper->GetGUID();

			foreach my $sr (@uniqueSR) {

				CamHelper->SetStep( $inCAM, $sr->{"stepName"} );
				$inCAM->COM( "profile_to_rout", "layer" => $lTmp, "width" => "200" );
			}

			CamHelper->SetStep( $inCAM, $step );
			CamLayer->FlatternLayer( $inCAM, $jobId, $step, $lTmp );

			# copy nested profiles to sa, sb layers..
			foreach my $l (@layers) {

				$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $l );

			}
			CamLayer->ClearLayers($inCAM);
			$inCAM->COM( "delete_layer", "layer" => $lTmp );

		}
		else {

			die "No nested steps in step: " . $step . ". Can't add nested step profiles";
		}

	}

	# 3) Add fiducials

	if ($addFiducial) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step, "c", 0 );
		if ( $attHist{".fiducial_name"} ) {

			CamHelper->SetStep( $inCAM, $step );

			# delete old fiducials
			foreach my $l (@layers) {

				CamLayer->WorkLayer( $inCAM, $l );
				if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {
					$inCAM->COM("sel_delete");
				}

			}

			# put diduc to paste
			CamLayer->WorkLayer( $inCAM, "c" );
			if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {

				my $strL = join( "\\;", @layers );

				$inCAM->COM(
							 "sel_copy_other",
							 "dest"         => "layer_name",
							 "target_layer" => $strL,
							 "invert"       => "no"
				);
			}
		}
		else {
			die "No fiducial marks in step: " . $step . ". Can't add fiducials to paste files";
		}
	}

	# unselect all layers
	CamLayer->ClearLayers($inCAM);

	# export layers

	#delete old ger form archive
	my @filesToDel = FileHelper->GetFilesNameByPattern( $archivePath, ".ger" );

	foreach my $f (@filesToDel) {
		unlink $f;
	}

	# function, which build output layer name, based on layer info
	my $suffixFunc = sub {

		my $l = shift;
		return ".ger";
	};

	my @hashLayers = ();

	foreach my $l (@layers) {

		my %lInfo = ( "name" => $l );
		push( @hashLayers, \%lInfo );
	}

	my $resultItemPast = $self->_GetNewItem("Paste data");

	Helper->ExportLayers( $resultItemPast, $inCAM, $step, \@hashLayers, $archivePath, "", $suffixFunc, 1, 1 );

	$self->_OnItemResult($resultItemPast);
}

# layers end with _ori has highest priority
sub __GetPasteLayers {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = ();

	my $sa_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sa-ori" );
	my $sb_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sb-ori" );
	my $sa_made = CamHelper->LayerExists( $inCAM, $jobId, "sa-made" );
	my $sb_made = CamHelper->LayerExists( $inCAM, $jobId, "sb-made" );

	if ( $sa_ori || $sb_ori ) {

		push( @layers, "sa-ori" ) if $sa_ori;
		push( @layers, "sb-ori" ) if $sb_ori;

	}
	elsif ( $sa_made || $sb_made ) {

		push( @layers, "sa-made" ) if $sa_made;
		push( @layers, "sb-made" ) if $sb_made;
	}

	return @layers;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::GerExport::ExportPasteMngr';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my %pasteInfo = ();

	$pasteInfo{"notOriginal"}      = 0;
	$pasteInfo{"step"}             = "mpanel";
	$pasteInfo{"export"}           = 1;
	$pasteInfo{"addProfile"}       = 1;
	$pasteInfo{"addSingleProfile"} = 1;
	$pasteInfo{"addFiducial"}      = 1;
	$pasteInfo{"zipFile"}          = 1;

	my $export = ExportPasteMngr->new( $inCAM, $jobId, \%pasteInfo );
	$export->Run();

	#print $test;

}

1;

