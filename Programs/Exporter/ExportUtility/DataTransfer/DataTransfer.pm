
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::DataTransfer;

#3th party library
use strict;
use warnings;
use utf8;
use JSON;

#local library
use aliased "Programs::Exporter::ExportUtility::DataTransfer::ExportData";
use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

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
	$self->{"units"} = shift;
	
	# only in read mode. If data should be load not from file but from string variable
	$self->{"fileDataStr"} = shift; 
	
	$self->{"filePath"} = shift;

	#$self->{"location"}  = shift;

	#$self->{"filePath"} = EnumsPaths->Client_EXPORTFILES . $self->{"jobId"};

	$self->{"data"}     = ExportData->new();    # Class with complete export data
	$self->{"hashData"} = ();                   # "flaterned" ExportData object to hash, prepared for JSON serialization

	# structure
	my %units = ();
	$self->{"hashData"}->{"units"} = \%units;
	my %settings = ();
	$self->{"hashData"}->{"settings"} = \%settings;

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
 
 		my %unitsData = $self->{"units"}->GetExportData(1);

		foreach my $unitId ( keys %unitsData ) {

			# unit export data
			my $unitData = $unitsData{$unitId};

			$self->{"data"}->{"units"}->{$unitId} = $unitData;
		}
		 
		# 2) save units mandatory
		
		my @unitsMandatory = $self->{"units"}->GetUnitsMandatory(1);
		my @keys = map { $_->GetUnitId() } @unitsMandatory;
		
 		$self->{"hashData"}->{"settings"}->{"mandatoryUnits"} = \@keys;

	}
	elsif ( $self->{"mode"} eq Enums->Mode_READ ||  $self->{"mode"} eq Enums->Mode_READFROMSTR) {

		# read from disc
		# Load data from file
		my $serializeData = undef;
		
		if($self->{"mode"} eq Enums->Mode_READ){
			$serializeData =  FileHelper->ReadAsString( $self->{"filePath"} );
		
		}elsif($self->{"mode"} eq Enums->Mode_READFROMSTR){
			$serializeData =  $self->{"fileDataStr"};
		}
		
		# Delete file
		#unlink($self->{"filePath"});

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

		# Prepare settings

		my %settings = %{ $hashData->{"settings"} };

		%{ $self->{"data"}->{"settings"} } = %settings;

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
	my $self      = shift;
	my $mode      = shift;
	my $toProduce = shift;
	my $port      = shift;
	my $formPos   = shift;
	my $orders 	   = shift; # orders, where export utility sets state "hotovo zadat"

	# Prepare all data for serialiyation
	# Save them to property "hashData"

	# 1), prepare unit data
	my %unitsData = %{ $self->{"data"}->{"units"} };
	

	my $unitOrder = 0;
	foreach my $unitId ( keys %unitsData ) {
		
		
		my $unit = $self->{"units"}->GetUnitById($unitId);
		$unitOrder = $unit->GetExportOrder();

		my $unitData = $unitsData{$unitId};

		my %hashUnit = $self->__PrepareUnitExportData( $unitData, $unitOrder );

		$self->{"hashData"}->{"units"}->{$unitId} = \%hashUnit;

		 
	}

	# 2) prepare other

	my ( $sec, $min, $hour ) = localtime();
	my $time = sprintf( "%02d:%02d", $hour, $min );

	$self->{"hashData"}->{"settings"}->{"time"}      = $time;
	$self->{"hashData"}->{"settings"}->{"mode"}      = $mode;
	$self->{"hashData"}->{"settings"}->{"toProduce"} = $toProduce;
	$self->{"hashData"}->{"settings"}->{"port"}      = $port;

	if ($formPos) {
		$self->{"hashData"}->{"settings"}->{"formPosX"} = $formPos->x();
		$self->{"hashData"}->{"settings"}->{"formPosY"} = $formPos->y();
	}
	
	# Set orders, where export utility sets state "hotovo zadat"
	$self->{"hashData"}->{"settings"}->{"orders"}   = $orders;
	
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
	my $self      = shift;
	my $unitData  = shift;
	my $unitOrder = shift;

	my $packageName = ref $unitData;
	my %hashData    = %{ $unitData->{"data"} };
	$hashData{"__PACKAGE__"}   = $packageName;
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

