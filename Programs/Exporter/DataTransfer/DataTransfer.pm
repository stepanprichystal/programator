
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::DataTransfer;

#3th party library
use strict;
use warnings;
use JSON;


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

	# This parameter have to be passed only in Write mode
	$self->{"unitsData"} = shift;
	$self->{"location"} = shift;

	$self->{"filePath"} = EnumsPaths->Client_EXPORTFILES . $self->{"jobId"};

	$self->{"data"}     = ExportData->new();    # Class with complete export data
	$self->{"hashData"} = ();                   # "flaterned" ExportData object to hash, prepared for JSON serialization

	# structure
	$self->{"hashData"}->{"units"} = ();
	#$self->{"hashData"}->{"time"}  = undef;
	#$self->{"hashData"}->{"location"}  = undef;

	#FileHelper->DeleteTempFilesFrom( EnumsPaths->Client_EXPORTFILES, 200 );    #delete 10000s old files

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
		#$self->{"hashData"}->{"location"}  =

	}
	elsif ( $self->{"mode"} eq Enums->Mode_READ ) {

		# read from disc
		# Load data from file
		my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );
		
		my $json = JSON->new();

		my $hashData = $json->decode($serializeData);
		
		#my $hashData      = decode_json($serializeData);

		# Create ExportData object

		# Prepare units objects

		my %units = %{ $hashData->{"units"} };
		foreach my $unitId ( keys %units ) {

			my %unitData = %{ $units{$unitId} };

			# Get information about package name
			my $packageName = $unitData{"__PACKAGE__"};

			# Convert to object by package name
			eval("use $packageName;");
			my $exportData = $packageName->new();
			$exportData->{"data"} = \%unitData;

			$self->{"data"}->{"units"}->{$unitId} = $exportData;
		}

		# Prepare other properties
		$self->{"data"}->{"time"} = $hashData->{"time"};
		$self->{"data"}->{"mode"} = $hashData->{"mode"};
		$self->{"data"}->{"toProduce"} = $hashData->{"toProduce"};
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
	my $mode = shift;
	my $toProduce = shift;
	
	#my %unitsData = %{shift(@_)};

	# 1), prepare unit data
	my %unitsData = %{ $self->{"data"}->{"units"} };


	my $unitOrder = 0;
	foreach my $unitId ( keys %unitsData ) {

		my $unitData = $unitsData{$unitId};

		my %hashUnit = $self->__PrepareUnitExportData($unitData, $unitOrder);

		$self->{"hashData"}->{"units"}->{$unitId} = \%hashUnit;
		
		$unitOrder ++;
	}

	# 2) prepare other
	
	my ($sec,$min,$hour) = localtime();

	$self->{"hashData"}->{"time"} = printf("%02d:%02d", $hour, $min);;
	$self->{"hashData"}->{"mode"} = $mode;
	$self->{"hashData"}->{"toProduce"} = $toProduce;
	

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
	my $unitOrder = shift;

	my $packageName = ref $unitData;
	my %hashData    = %{ $unitData->{"data"} };
	$hashData{"__PACKAGE__"} = $packageName;
	$hashData{"__UNITORDER__"} = $unitOrder;
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

