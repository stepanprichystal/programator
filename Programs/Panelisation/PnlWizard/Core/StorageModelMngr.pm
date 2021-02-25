
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::StorageModelMngr;
use base ('Packages::ObjectStorable::JsonStorable::JsonStorableMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use JSON::XS;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class          = shift;
	my $jobId          = shift;
	my $modelData      = shift;
	my $modelPartsData = shift;

	my $dir = EnumsPaths->Client_INCAMTMPPNLCRE;

	unless ( -e $dir ) {
		mkdir($dir) or die "Can't create dir: " . $dir . $_;
	}

	my $p = $dir . $jobId . "_modeldata";

	my $self = $class->SUPER::new($p);
	bless $self;

	$self->{"jobId"}          = $jobId;
	$self->{"modelData"}      = $modelData;
	$self->{"modelPartsData"} = $modelPartsData;

	FileHelper->DeleteTempFilesFrom( EnumsPaths->Client_INCAMTMPPNLCRE, 3600 * 24 * 4 );    #delete 12 hours old settings

	return $self;
}

sub ExistModelData {
	my $self = shift;

	return $self->SUPER::SerializedDataExist();

}

sub GetDataByPart {
	my $self = shift;
	my $unit = shift;

	unless ( $self->{"hashGroupData"} ) {
		return 0;
	}

	my $id            = $unit->{"unitId"};
	my %hashGroupData = %{ $self->{"hashGroupData"} };

	my %data = %{ $hashGroupData{$id} };

	#get information about unit state
	my $unitState = $data{"__UNITSTATE__"};

	# Get information about package name
	my $packageName = $data{"__PACKAGE__"};

	# Convert to object by package name
	my $groupData = $packageName->new();
	$groupData->{"data"}  = \%data;
	$groupData->{"state"} = $unitState;

	return $groupData;
}

sub SaveGroupData {
	my $self = shift;

	# get actual group data from all units
	my %hashGroupData = ();

	my @units = @{ $self->{"units"}->{"units"} };

	# Get group data hasha
	# Add information about "package name"
	foreach my $unit (@units) {

		my $groupData   = $unit->GetGroupData();
		my $packageName = ref $groupData;
		my $unitState   = $groupData->{"state"};

		my %hashData = %{ $groupData->{"data"} };
		$hashData{"__PACKAGE__"}   = $packageName;
		$hashData{"__UNITSTATE__"} = $unitState;

		$hashGroupData{ $unit->{"unitId"} } = \%hashData;
	}

	$self->{"hashGroupData"} = \%hashGroupData;

	my $json = JSON::XS->new->ascii->pretty->allow_nonref;

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

