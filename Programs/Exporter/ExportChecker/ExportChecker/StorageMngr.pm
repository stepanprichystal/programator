
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::StorageMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use JSON;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"}     = shift;
	$self->{"units"}     = shift;
	$self->{"hashGroupData"} = undef; #serialized group data file

	$self->{"groupDataFile"} = EnumsPaths->Client_INCAMTMPCHECKER . $self->{"jobId"} . "_groupData";

	FileHelper->DeleteTempFilesFrom(EnumsPaths->Client_INCAMTMPCHECKER, 3600*12); #delete 10000s old files

	return $self;
}

# Test if data exist in log
sub ExistGroupData {
	my $self = shift;
	
	my $dataExist = 0;

	# test if exist in memory
	if ( !defined $self->{"hashGroupData"} ) {

		# test if exist on disc
		if ( -e $self->{"groupDataFile"} ) {

			my $serializeData = FileHelper->ReadAsString( $self->{"groupDataFile"} );
			my $groupData     = decode_json($serializeData);
			$self->{"hashGroupData"} = $groupData;

			$dataExist =  1;
		}
	}
	else {
		
		$dataExist = 1;
	}

	return $dataExist;
}

 

sub GetDataByUnit {
	my $self = shift;
	my $unit = shift;

	unless ( $self->{"hashGroupData"} ) {
		return 0;
	}

	my $id        = $unit->{"unitId"};
	my %hashGroupData = %{ $self->{"hashGroupData"} };
	 
	my %data = %{ $hashGroupData{$id} };
	
	#get information about unit state
	my  $unitState = $data{"__UNITSTATE__"};
	
	# Get information about package name
	my $packageName = $data{"__PACKAGE__"};
	
	# Convert to object by package name
	my $groupData = $packageName->new();
	$groupData->{"data"} = \%data;
	$groupData->{"state"} = $unitState;
 
	return $groupData;
}

sub SaveGroupData {
	my $self = shift;

	# get actual group data from all units
	my %hashGroupData = ();
	
	my @units = @{$self->{"units"}->{"units"}};
	
	# Get group data hasha
	# Add information about "package name"
	foreach my $unit ( @units ) {

		my $groupData = $unit->GetGroupData();
		my $packageName = ref $groupData;
		my $unitState = $groupData->{"state"};
		
		my %hashData  = %{ $groupData->{"data"} };
		$hashData{"__PACKAGE__"} = $packageName;
		$hashData{"__UNITSTATE__"} = $unitState;
		
		$hashGroupData{ $unit->{"unitId"} } = \%hashData;
	}
	
	$self->{"hashGroupData"} = \%hashGroupData;

	my $json = JSON->new();

	my $serializedData = $json->pretty->encode( \%hashGroupData );

	#delete old file
	unlink $self->{"groupDataFile"};

	unless ( -e EnumsPaths->Client_INCAMTMPCHECKER ) {
		mkdir( EnumsPaths->Client_INCAMTMPCHECKER ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPCHECKER . $_;
	}

	open( my $f, '>', $self->{"groupDataFile"} );
	print $f $serializedData;
	close $f;
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

