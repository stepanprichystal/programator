
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::DataTransfer;

#3th party library
use strict;
use warnings;

#local library
use aliased "Programs::Exporter::DataTransfer::ExportData";
use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use aliased 'Programs::Exporter::DataTransfer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	# read mode or write mode
	$self->{"mode"} = shift;

	# Only in Write mode
	$self->{"unitsData"} = shift;

	$self->{"filePath"} = EnumsPaths->Client_EXPORTFILES . $self->{"jobId"};

	$self->{"data"}     = ExportData->new();    # Class with complete export data
	$self->{"hashData"} = ();                   # "flaterned" ExportData object to hash, prepared for JSON serialization

	# structure
	$self->{"hashData"}->{"units"} = ();
	$self->{"hashData"}->{"time"}  = undef;

	FileHelper->DeleteTempFilesFrom( EnumsPaths->Client_EXPORTFILES, 200 );    #delete 10000s old files

	$self->__BuildExportData();

	return $self;
}

# Return initialized ExportData class
sub __BuildExportData {
	my $self = shift;

	if ( $self->{"mode"} eq Enums->Mode_WRITE ) {

		# 1), prepare unit data
		my %unitsData = %{ $self->{"unitsData"} };

		foreach my $unitId ( keys %unitsData ) {

			# unit export data
			my $unitData = $unitsData{$unitId};

			$self->{"data"}->{"units"}->{$unitId} = $unitData;
		}

		# 2) prepare other
		$self->{"data"}->{"time"} = "tttt";

	}
	elsif ( $self->{"mode"} eq Enums->Mode_READ ) {

		# read from disc
		# Load data from file
		my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );
		my $hashData      = decode_json($serializeData);

		# Create ExportData object

		# Prepare units objects

		my %units = %{ $hashData->{"units"} };
		foreach my $unitId ( keys %units ) {

			my %unitData = %{ $units{$unitId} };

			# Get information about package name
			my $packageName = $unitData{"__PACKAGE__"};

			# Convert to object by package name
			my $exportData = $packageName->new();
			$exportData->{"data"} = \%unitData;

			$self->{"data"}->{"units"}->{$unitId} = $exportData;
		}

		# Prepare other properties
		$self->{"data"}->{"time"} = $hashData->{"time"};

	}
}

# Return inited class ExportData, which was filled by data
# which were serialized before
sub GetExportData {
	my $self = shift;

	return $self->{"data"};

}

# Serialize class "ExportData"
sub SaveData {
	my $self = shift;

	#my %unitsData = %{shift(@_)};

	# 1), prepare unit data
	my %unitsData = %{ $self->{"data"}->{"units"} };

	foreach my $unitId ( keys %unitsData ) {

		my $unitData = $unitsData{$unitId};

		my %hashUnit = $self->__PrepareUnitExportData($unitData);
		$self->{"hashData"}->{"units"}->{$unitId} = \%hashUnit;

	}

	# 2) prepare other
	$self->{"hashData"}->{"time"} = "tttt";

	# serialize and save
	$self->__SerializeExportData();

}

sub __SerializeExportData {
	my $self = shift;

	my $hashData = $self->{"hashData"};

	my $json = JSON->new();

	my $serialized = $json->pretty->encode($hashData);

	#delete old file
	unlink $self->{"filePath"};

	open( my $f, '>', $self->{"filePath"} );
	print $f $serialized;
	close $f;
}

sub __PrepareUnitExportData {
	my $self     = shift;
	my $unitData = shift;

	my $packageName = ref $unitData;
	my %hashData    = %{ $unitData->{"data"} };
	$hashData{"__PACKAGE__"} = $packageName;

	return %hashData;
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

