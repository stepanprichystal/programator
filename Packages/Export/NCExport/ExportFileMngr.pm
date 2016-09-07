
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportFileMngr;
use base('Packages::Export::MngrBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';

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

	$self->__DeleteLogs();           #delete log information about job
	$self->__DeleteOldFiles();       #delete old files in archive
	$self->__DeleteOutputFiles();    #delete job output files before start export

	my @exportFiles = $self->__GetExportCombination($opManager);

	foreach my $c (@exportFiles) {

		my $result = ItemResult->new($c->{"layer"}, undef, "Layers");

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

	my $setName = GeneralHelper->GetGUID();

	$inCAM->COM( 'set_step', "name" => $stepName );
	
	$inCAM->COM("open_sets_manager","test_current" => "no");
	
	$inCAM->COM( 'nc_create', "ncset" => $setName, "device" => $machine, "lyrs" => $layerName, "thickness"=> 0 );
	
	$inCAM->COM("nc_set_advanced_params","layer" => $layerName,"ncset" => $setName,"parameters" => "(iol_sm_g84_radius=no)");
	$inCAM->COM(" nc_set_current","job" => $jobId,"step" => $stepName,"layer" => $layerName,"ncset" => $setName);
 

	$inCAM->COM("units","type" => "mm");
	$inCAM->COM("ncset_units","units" => "mm");
	#if ( $inCAM->GetStatus() > 1 ) {
	#	$methodRes->AddError( $inCAM->GetExceptionError() );
	#}

	$inCAM->COM( "nc_cre_output", "layer" => $layerName, "ncset" => $setName );
	
	my $reply = $inCAM->GetReply();

	#if ( $inCAM->GetStatus() > 1 ) {
	#	$methodRes->AddError( $inCAM->GetExceptionError() );
	#}
	
	#delete nc set
	$inCAM->COM( "nc_delete", "layer" => $layerName, "ncset" => $setName );
	
	#delete temporary files, which was created
	my $tmpName = "_".$setName."_out_";
	my $tmpExist = CamHelper->LayerExists( $inCAM, $jobId, $tmpName );

	if ($tmpExist) {
			$inCAM->COM( 'delete_layer', "layer" => $tmpName );
	}
	


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

	#load other possible errors
	$self->__GetErrorsFromHook( $layer, $resultItem );
	$self->_OnItemResult($resultItem);
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

		my @splitted = split( "/", $l );
		my $machine = $splitted[3];

		if ( $l =~ /$key/i ) {

			$l =~ m/=\s*[01]+;(.*)/i;
			my $mess = "Exporting on machine: $machine. " . $1;

			$itemResult->AddError($mess);
		}
	}
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

