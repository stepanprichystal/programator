
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading information about ExportStatus
# By ExportStatus file we can decide, if job is exported ok and if could be send to produce
# ExportStatus is file which contain name of export groups, and values
# if group has been exported succes or not
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::ExportStatus::ExportStatus;

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased "Enums::EnumsPaths";
use aliased "Enums::EnumsGeneral";
use aliased "Helpers::FileHelper";
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportStatus::ExportStatusBuilder';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;
	$self->{"inCAM"} = shift;

	$self->{"filePath"} = JobHelper->GetJobArchive( $self->{"jobId"} ) . "ExportStatus";

	return $self;
}

sub IsExportOk {
	my $self = shift;

	my %hashKeys = $self->__ReadExportStatus();

	my $statusOk = 1;

	foreach my $k ( keys %hashKeys ) {

		if ( $hashKeys{$k} == 0 ) {
			$statusOk = 0;
			last;
		}

	}

	return $statusOk;

}

sub DeleteStatusFile {
	my $self = shift;

	if ( -e $self->{"filePath"} ) {

		unlink( $self->{"filePath"} );
	}

}

sub CreateStatusFile {
	my $self = shift;

	# test if file already exist
	if ( -e $self->{"filePath"} ) {
		return 1;
	}

	my $builder = ExportStatusBuilder->new();
	my @keys    = $builder->GetStatusKeys($self);

	my %hashKeys = ();

	# create hash from keys
	foreach my $k (@keys) {

		$hashKeys{$k} = 0;
	}

	$self->__SaveExportStatus( \%hashKeys );
}

sub UpdateStatusFile {
	my $self         = shift;
	my $unitKey      = shift;
	my $exportResult = shift;

	my $result = 0;

	if ( $exportResult eq EnumsGeneral->ResultType_OK ) {
		$result = 1;
	}
	elsif ( $exportResult eq EnumsGeneral->ResultType_FAIL ) {
		$result = 0;
	}

	my %hashKeys = $self->__ReadExportStatus();

	$hashKeys{$unitKey} = $result;

	$self->__SaveExportStatus( \%hashKeys );
}

sub __SaveExportStatus {
	my $self     = shift;
	my %hashData = %{ shift(@_) };

	my $json = JSON->new();

	my $serialized = $json->pretty->encode( \%hashData );

	#delete old file
	unlink $self->{"filePath"};

	open( my $f, '>', $self->{"filePath"} );
	print $f $serialized;
	close $f;
}

sub __ReadExportStatus {
	my $self = shift;

	# read from disc
	# Load data from file
	my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );

	my $json = JSON->new();

	my $hashData = $json->decode($serializeData);

	return %{$hashData};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

