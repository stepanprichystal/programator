
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
	$self->{"groupData"} = undef;

	$self->{"groupDataFile"} = EnumsPaths->Client_INCAMTMPSCRIPTS . $self->{"jobId"} . "_groupData";

	FileHelper->DeleteScriptTmpFiles();

	return $self;
}

# Test if data exist in log
sub ExistGroupData {
	my $self = shift;
	
	my $dataExist = 0;

	# test if exist in memory
	if ( !defined $self->{"groupData"} ) {

		# test if exist on disc
		if ( -e $self->{"groupDataFile"} ) {

			my $serializeData = FileHelper->ReadAsString( $self->{"groupDataFile"} );
			my $groupData     = decode_json($serializeData);
			$self->{"groupData"} = $groupData;

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

	unless ( $self->{"groupData"} ) {
		return 0;
	}

	my $id        = $unit->{"unitId"};
	my %allGroupData = %{ $self->{"groupData"} };
	 
	my %data = %{ $allGroupData{$id} };
	
	# Get information about package name
	my $packageName = $data{"__PACKAGE__"};
	
	# Convert to object by package name
	my $groupData = $packageName->new();
	$groupData->{"data"} = \%data;
 
	return $groupData;
}

sub SaveGroupData {
	my $self = shift;

	# get actual group data from all units
	my %allGroupData = ();
	
	my @units = @{$self->{"units"}->{"units"}};
	
	# Get group data hasha
	# Add information about "package name"
	foreach my $unit ( @units ) {

		my $groupData = $unit->GetGroupData();
		my $packageName = ref $groupData;
		
		my %hashData  = %{ $groupData->{"data"} };
		$hashData{"__PACKAGE__"} = $packageName;
		
		$allGroupData{ $unit->{"unitId"} } = \%hashData;
	}
	
	$self->{"groupData"} = \%allGroupData;

	#my %groupData = $self->{"units"}->GetGroupData();

	#my $perl_scalar = \%groupData;

	my $json = JSON->new();

	my $serializedData = $json->pretty->encode( \%allGroupData );

	#my $serializedData   =  $json->encode_json($self->{"groupData"} );

	#delete old file
	unlink $self->{"groupDataFile"};

	unless ( -e EnumsPaths->Client_INCAMTMPSCRIPTS ) {
		mkdir( EnumsPaths->Client_INCAMTMPSCRIPTS ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPSCRIPTS . $_;
	}

	open( my $f, '>', $self->{"groupDataFile"} );
	print $f $serializedData;
	close $f;

}

sub AddData {
	my $self = shift;
	my $unit = shift;
	my $data = shift;

	my $id = $unit->{"unitId"};
	$self->{"groupData"}->{$id} = $data;

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

