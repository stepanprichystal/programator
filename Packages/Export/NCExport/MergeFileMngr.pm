
#-------------------------------------------------------------------------------------------#
# Description:  Cover merging, and moving nc files to from output folder to archhive
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::MergeFileMngr;
use base('Packages::Export::MngrBase');

#3th party library
use strict;
use warnings;
 

#local library
use aliased 'Packages::Export::NCExport::FileHelper::Parser';
use aliased 'Helpers::JobHelper';

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
	$self->{"resBuilder"} = shift;

	$self->{"fileEditor"} = undef;

	$self->{"archive"} = JobHelper->GetJobArchive( $self->{"jobId"} );
	$self->{"output"}  = JobHelper->GetJobOutput( $self->{"jobId"} );

	$self->__SetArchiveDirs();

	return $self;
}



sub MergeFiles {

	my $self      = shift;
	my $opManager = shift;
	my $output;

	my @opItems = $opManager->GetOperationItems();

	foreach my $opItem (@opItems) {

		$self->__ProcessOperationItem($opItem);
	}
	
	$self->__ResultMerging();
	
}
 

# If operation contains more layers, they are merged in sequence 
sub __ProcessByMachine {
	my $self     = shift;
	my $opItem   = shift;
	my $machine  = shift;
	my @opLayers = $opItem->GetSortedLayers();

	my ( %fBef, %fAct, @fResult );
	for ( my $i = 0 ; $i < scalar(@opLayers) ; $i++ ) {

		my $layer = $opLayers[$i];

		my @lines = $self->__OpenFile( $layer, $machine->{"suffix"}, 1 );
		%fAct = $self->__ParseFile( $layer, \@lines, $opItem );

		if ( $i > 0 ) {
			@fResult = $self->__MergeFiles( $layer, $opItem, \%fAct, \%fBef );
			%fAct = Parser->ParseFile( \@fResult );
		}

		%fBef = %fAct;
	}

	$self->__SaveOperation( \%fAct, $opItem, $machine->{"suffix"} )

}

# Process operation one by one, separately for selected machines
sub __ProcessOperationItem {
	my $self   = shift;
	my $opItem = shift;

	my @machines = $opItem->GetMachines();

	foreach my $m (@machines) {

		$self->__ProcessByMachine( $opItem, $m )
	}
}

sub __SaveFile {
	my $self      = shift;
	my $parseFile = shift;
	my $path      = shift;

	my @lines = Parser->ConvertToArray($parseFile);

	my $fFin;
	open( $fFin, "+>$path" );
	print $fFin @lines;
	close($fFin);
}

# cover saving nc file, which is represent bz operation
# plus solve, when layer is splited on more then one stages
sub __SaveOperation {
	my $self      = shift;
	my $parseFile = shift;
	my $opItem    = shift;
	my $suffix    = shift;

	my $fileEditor   = $self->{"fileEditor"};
	my $stagingExist = $opItem->StagingExist();
	my $fileName     = $opItem->{"name"};

	my $jobName = $self->{"jobId"}."_";

	# 1) save standard merged file, then save staging files

	if ($stagingExist) {
		$fileName .= "_1";
	}


	my $path = $self->{'archive'} . $jobName.$fileName . "." . $suffix;

	$fileEditor->EditBeforeSave( $parseFile, $opItem );


	$self->__SaveFile( $parseFile, $path );

	# 2) save all staging files

	if ($stagingExist) {

		#How it works:
		# If any layer has more then one staging, then another stage files has to be moved to archiv
		# - stage file has same name as "main" file
		# - only differrent is file number
		# - for every another stage file <fileNumber> is increased
		# Example:
		# - c1_1.a (contain merged layers: m (stage 1) + r (stage 1))
		# - c1_2.a (contain layer: m (stage 2))
		# - c1_3.a (contain layer: r (stage 2))

		my $fileNumber = 2;

		my @layers = $opItem->GetSortedLayers();

		foreach my $l (@layers) {

			if ( $l->{"stagesCnt"} > 1 ) {

				my $stageNumber = 2;    # 2 because if file has staging, first stage is already saved (merged with another files)
				for ( my $i = 1 ; $i < $l->{"stagesCnt"} ; $i++ ) {

					#open and parse, by standard rules
					my @lines = $self->__OpenFile( $l, $suffix, $stageNumber );
					my %parseFile = $self->__ParseFile( $l, \@lines, $opItem );
					$fileEditor->EditBeforeSave( \%parseFile, $opItem );

					#build path
					$fileName = $self->{'archive'} . $jobName .$opItem->{"name"} . "_" . $fileNumber . "." . $suffix;

					$self->__SaveFile( \%parseFile, $fileName );

					#save
					$stageNumber++;
					$fileNumber++;
				}
			}
		}
	}
}


sub __OpenFile {
	my $self   = shift;
	my $file   = shift;
	my $suffix = shift;
	my $stage  = shift;

	my $fileName = $file->{"gROWname"};

	if ( $file->{"stagesCnt"} > 1 ) {

		$fileName .= "_stage_" . $stage;
	}

	my $path = $self->{'output'} . $fileName . "." . $suffix;

	my $f;
	open( $f, "<" . $path ) or die "Can't open file $path $_";
	my @lines = <$f>;
	close($f);

	return @lines;

}

# merge two file together
# order of merging depend layer which is sign as "header layer"
# If layer is "header layer", final file will contain header from it
sub __MergeFiles {
	my $self        = shift;
	my $layerSource = shift;
	my $opItem      = shift;
	my $fileSource  = shift;
	my $fileTarget  = shift;

	my @result = ();

	my $headerLayer = $opItem->GetHeaderLayer();
	if ( $layerSource == $headerLayer ) {

		@result = Parser->MergeTwoFiles( $fileTarget,  $fileSource, 0 );
	}
	else
	{
		@result = Parser->MergeTwoFiles( $fileSource, $fileTarget, 1 );
	}
	

	return @result;

}

# Every file is parsed, an here is possibility to edit special file
# before merging. E.g. add command "G82"
sub __ParseFile {
	my $self   = shift;
	my $layer  = shift;
	my $lines  = shift;
	my $opItem = shift;

	my %fParse     = Parser->ParseFile($lines);
	my $fileEditor = $self->{"fileEditor"};

	$fileEditor->EditAfterOpen( $layer, \%fParse, $opItem );

	return %fParse;

}

# set path to directory where are nc files saved
sub __SetArchiveDirs {
	my $self = shift;

	if ( $self->{"exportSingle"} ) {
		$self->{"archive"} .= "\\nc_single\\";
		unless ( -e $self->{"archive"} ) {
			mkdir( $self->{"archive"} ) or die "Can't create dir: " . $self->{"archive"} . $_;
		}
	}
	else {
		$self->{"archive"} .= "\\nc\\";
		unless ( -e $self->{"archive"} ) {
			mkdir( $self->{"archive"} ) or die "Can't create dir: " . $self->{"archive"} . $_;
		}
	}

}

# raise result of merging
sub __ResultMerging {
	my $self = shift;

	my $resultItem = $self->_GetNewItem("Merging");
 
	$self->_OnItemResult($resultItem);

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

