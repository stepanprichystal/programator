
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

	my $step       = $self->{"pasteInfo"}->{"step"};
	my $addProfile = $self->{"pasteInfo"}->{"addProfile"};
	my @layers     = $self->__GetPasteLayers();
	
	if(scalar(@layers) == 0){
		die "No paste layers for export.\n";
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $step );

	if ( $step eq "mpanel" ) {

		if ($addProfile) {

			#CamLayer->AffectLayers( $inCAM, @layers );
			#$inCAM->COM('sel_delete');

			foreach my $l (@layers) {

				$inCAM->COM( "profile_to_rout", "layer" => $l, "width" => "200" );
			}
		}
	}

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

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

