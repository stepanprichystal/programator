
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportFileMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"stepName"}     = shift;
	$self->{"exportSingle"} = shift;
	$self->{"resBuilder"}   = shift;

	return $self;
}

sub ExportFiles {
	my $self      = shift;
	my $opManager = shift;

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . " BUG stop ExportFiles sub - 1 \n " );

	$self->__DeleteLogs();    #delete log information about job

	$self->__DeleteOldFiles();    #delete old files in archive

	$self->__DeleteOutputFiles(); #delete job output files before start export

	my @exportFiles = $self->__GetExportCombination($opManager);

	foreach my $c (@exportFiles) {

		my $result = ItemResult->new( $c->{"layer"}, undef, "Layers" );

		foreach ( @{ $c->{"machines"} } ) {

			$self->__ExportNcSet( $c->{"layer"}, $_->{"id"}, $result );
		}

		$self->__ResultExportLayer( $c->{"layer"}, $result );
	}

}

sub __ExportNcSet {
	my $self      = shift;
	my $layerName = shift;
	my $machine   = shift;
	my $methodRes = shift;

	my $jobId    = $self->{"jobId"};
	my $inCAM    = $self->{"inCAM"};
	my $stepName = $self->{"stepName"};

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, __ExportNcSet 1\n ");

	# Check if Null point is in left down corner of profile
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName, 1 );

	if ( int( $lim{"xMin"} ) != 0 || int( $lim{"yMin"} ) != 0 ) {

		die "Left-down profile corner is not placed in \"zero point\".\n";
	}

	$inCAM->COM( 'set_step', "name" => $stepName );

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, __ExportNcSet 2\n ");

	$inCAM->COM( "open_sets_manager", "test_current" => "no" );

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, __ExportNcSet 3\n ");

	my $setName = undef;

	# This command sometimes fail - Illegal entity name. Put here three attempts
	foreach ( 1 .. 3 ) {

		$setName = GeneralHelper->GetGUID();

		$inCAM->HandleException(1);
		$inCAM->COM( 'nc_create', "ncset" => $setName, "device" => $machine, "lyrs" => $layerName, "thickness" => 0 );
		$inCAM->HandleException(0);

		get_logger("abstractQueue")->error("Finding  $jobId BUG stop during export 1\n ");

		last if ( $inCAM->GetStatus() == 0 );

		get_logger("abstractQueue")->error( "Error during command nc_create\n " . $inCAM->GetExceptionError() );
	}

	$inCAM->COM( "nc_set_advanced_params", "layer" => $layerName, "ncset" => $setName, "parameters" => "(iol_sm_g84_radius=no)" );

	$inCAM->COM( " nc_set_current", "job" => $jobId, "step" => $stepName, "layer" => $layerName, "ncset" => $setName );

	my $lType = CamHelper->LayerType( $inCAM, $jobId, $layerName );

	# Set order of routing

	if ( $lType eq "rout" ) {

		if ( $layerName ne "fsch" ) {

			#check if panel contain name "mapanel" step
			my $mpanelExist = CamStepRepeat->ExistStepAndRepeat( $inCAM, $jobId, $stepName, "mpanel" );

			if ($mpanelExist) {

				# find line number with first occurence of mpanel in SR table
				my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName );

				my $lNum = undef;

				for ( my $i = 0 ; $i < scalar(@sr) ; $i++ ) {

					if ( $sr[$i]->{"gSRstep"} eq "mpanel" ) {
						$lNum = $i + 1;
						last;
					}
				}

				# first, order each mpanel steps
				$inCAM->COM( "sredit_set_step_nest", "lines" => $lNum, "nx" => "1", "ny" => "1", "clear_selection" => "yes" );
				$inCAM->COM(
							 "nc_order",
							 "serial"  => "1",
							 "sr_line" => "1",
							 "sr_nx"   => "1",
							 "sr_ny"   => "1",
							 "mode"    => "btrl",
							 "snake"   => "no",
							 "scope"   => "parent"
				);

				# then, order all o+1 steps in mpanel scope
				$inCAM->COM( "sredit_set_step_nest", "lines" => "$lNum\;1", "nx" => "1\;1", "ny" => "1\;1", "clear_selection" => "yes" );
				$inCAM->COM(
							 "nc_order",
							 "serial"  => "1",
							 "sr_line" => "$lNum\;1",
							 "sr_nx"   => "1\;1",
							 "sr_ny"   => "1\;1",
							 "mode"    => "btrl",
							 "snake"   => "no",
							 "scope"   => "parent"
				);

				# result is -> first are drilled all o+1 mpanel by mapanel
				# second are drilled mpanels

			}
			else {

				$inCAM->COM( "sredit_set_step_nest", "lines" => "1", "nx" => "1", "ny" => "1", "clear_selection" => "yes" );
				$inCAM->COM(
							 "nc_order",
							 "serial"  => "1",
							 "sr_line" => "1",
							 "sr_nx"   => "1",
							 "sr_ny"   => "1",
							 "mode"    => "btrl",
							 "snake"   => "no",
							 "scope"   => "full"
				);
			}

		}
	}

#$inCAM->COM("nc_order","full" =>"0", "serial" => "1","sr_line" => "1","sr_nx" => "1","sr_ny" => "1","mode" => "btrl","snake" => "no","scope" => "full");

	#if ( $inCAM->GetStatus() > 1 ) {
	#	$methodRes->AddError( $inCAM->GetExceptionError() );
	#}

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 2\n ");

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	$inCAM->COM( "nc_cre_output", "layer" => $layerName, "ncset" => $setName );

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 3\n ");

	$methodRes->AddError( $inCAM->GetExceptionError() );

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 4\n ");

	#if ( $inCAM->GetStatus() > 1 ) {
	#	$methodRes->AddError( $inCAM->GetExceptionError() );
	#}
	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 5\n ");

	#delete nc set
	$inCAM->COM( "nc_delete", "layer" => $layerName, "ncset" => $setName );

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 6\n ");

	#delete temporary files, which was created
	my $tmpName = "_" . $setName . "_out_";
	my $tmpExist = CamHelper->LayerExists( $inCAM, $jobId, $tmpName );

	if ($tmpExist) {
		$inCAM->COM( 'delete_layer', "layer" => $tmpName );
	}

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 7\n ");

	# Clear step selection (some steps can)
	$self->{"inCAM"}->COM("sredit_sel_clear");

	get_logger("abstractQueue")->error("Finding  $jobId layer: $layerName, machine: $machine, BUG stop during export 8\n ");

}

# Return all export combination
# Each machine, can procces only some type of nc task such as drill/mill/depth drill with camreas etc..
sub __GetExportCombination {
	my $self      = shift;
	my $opManager = shift;

	my @exportComb = ();
	my @opItems    = @{ $opManager->{"operItems"} };

	foreach my $opItem (@opItems) {

		my @comb = $opItem->GetExportCombination();

		#find if given layer is already contained in array <@exportComb>
		# if yes, add machines to this layer

		foreach my $lMachine (@comb) {

			my $idx = ( grep { $exportComb[$_]->{"layer"} eq $lMachine->{"layer"} } 0 .. $#exportComb )[0];

			unless ( defined $idx ) {

				my %info = ( "layer" => $lMachine->{"layer"} );
				push( @exportComb, \%info );
				$idx = scalar(@exportComb) - 1;

			}

			#test, if machine for this layer alreadz exist
			my @newMachine = ();

			foreach my $mach ( @{ $lMachine->{"machines"} } ) {

				unless ( scalar( grep { $_ == $mach } @{ $exportComb[$idx]->{"machines"} } ) ) {

					push( @newMachine, $mach );
				}

			}

			if ( scalar(@newMachine) ) {

				push( @{ $exportComb[$idx]->{"machines"} }, @newMachine );
			}
		}
	}

	return @exportComb;
}

# If export all, delete all files in job atchiov nc directory
sub __DeleteOldFiles {
	my $self = shift;

	my $path;

	if ( $self->{"exportSingle"} ) {

		$path = JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc_single\\";
	}
	else {

		$path = JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc\\";
	}

	my $dir;
	if ( opendir( $dir, $path ) ) {
		while ( my $file = readdir($dir) ) {

			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );
			unlink $path . $file;

		}

		closedir($dir);
	}

	# Check if exist some "old format" drilling, if so delete. Old format are .ros, .rou, .mes
	my $archivePath = JobHelper->GetJobArchive( $self->{"jobId"} );

	my @mes = FileHelper->GetFilesNameByPattern( $archivePath, ".mes" );
	my @meg = FileHelper->GetFilesNameByPattern( $archivePath, ".meg" );
	my @ros = FileHelper->GetFilesNameByPattern( $archivePath, ".ros" );
	my @rou = FileHelper->GetFilesNameByPattern( $archivePath, ".rou" );

	foreach my $f ( ( @mes, @meg, @ros, @rou ) ) {
		unlink $f;
	}
}

# If export all, delete all files in job atchiov nc directory
sub __DeleteOutputFiles {
	my $self = shift;

	my $path = JobHelper->GetJobOutput( $self->{"jobId"} );

	my $dir;
	if ( opendir( $dir, $path ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );
			unlink $path . $file;
		}

		closedir($dir);
	}
}

sub __DeleteLogs {
	my $self = shift;

	my $logFile = EnumsPaths->Client_INCAMTMPNC . $self->{"jobId"};

	if ( -e $logFile ) {
		unlink($logFile) or die "$logFile: $!";
	}

}

sub __ResultExportLayer {
	my $self       = shift;
	my $layer      = shift;
	my $resultItem = shift;

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . "   __ResultExportLayer 1 \n " );

	#load other possible errors
	$self->__GetErrorsFromHook( $layer, $resultItem );
	$self->_OnItemResult($resultItem);

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . "   __ResultExportLayer 2\n " );
}

# Search errors in log, genereeted by hooks, outfile, nc_create, etc..
sub __GetErrorsFromHook {
	my $self       = shift;
	my $layer      = shift;
	my $itemResult = shift;

	my $logFile = EnumsPaths->Client_INCAMTMPNC . $self->{"jobId"};

	my @lines = ();

	if ( open( my $f, "<$logFile" ) ) {
		@lines = <$f>;
		close($f);
	}

	my $key = $self->{"jobId"} . "/" . $self->{"stepName"} . "/" . $layer;

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		my @splitted  = split( "/", $l );
		my $machine   = $splitted[3];
		my ($errType) = $l =~ /$key\/.*\/(.*)\s*=/i;
		$errType =~ s/\s//;

		if ( $l =~ /$key/i ) {

			$l =~ m/=\s*[01]+;(.*)/i;
			my $mess = "Exporting on machine: $machine. " . $1;

			if ( $errType =~ /[(drill)|(rout)](tool)?parameters/ ) {
				$itemResult->AddWarning($mess);
			}
			else {
				$itemResult->AddError($mess);
			}

		}
	}

	get_logger("abstractQueue")->error( "Finding  " . $self->{"jobId"} . "   __GetErrorsFromHook\n " );
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

