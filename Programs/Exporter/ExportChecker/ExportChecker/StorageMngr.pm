
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

	$self->{"jobId"} = shift;
	$self->{"units"} = shift;
	my %groupData = ();
	$self->{"groupData"} = \%groupData;

	$self->{"groupDataFile"} = EnumsPaths->Client_INCAMTMPSCRIPTS . $self->{"jobId"} . "_groupData";

	FileHelper->DeleteScriptTmpFiles();
	
	
	return $self;
	

}

sub ExistGroupData {
	my $self = shift;

	if ( -e $self->{"groupDataFile"} ) {

		return 1;

	}
	else {

		return 0;
	}

}

sub GetGroupData {
	my $self = shift;
	# test if exist in memory
	unless ( $self->{"groupDataFile"} ) {

		# test if exist on disc
		if ( $self->ExistGroupData() ) {

			my $serializeData = FileHelper->ReadAsString( $self->{"groupDataFile"} );
			my $groupData     = decode_json($serializeData);
			$self->{"groupData"} = $groupData;

		}
		else { return 0; }
	}

}

sub SaveGroupData {
	my $self = shift;

	my %groupData = $self->{"units"}->GetGroupData();
	$self->{"groupData"} = \%groupData;

	#my %groupData = $self->{"units"}->GetGroupData();

	#my $perl_scalar = \%groupData;

	my $serializedData = encode_json( $self->{"groupData"} );

	#delete old file
	unlink $self->{"groupDataFile"};
	
	unless(-e EnumsPaths->Client_INCAMTMPSCRIPTS){
		mkdir( EnumsPaths->Client_INCAMTMPSCRIPTS ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPSCRIPTS . $_;
	}
 
	open( my $f, '>', $self->{"groupDataFile"} );
	print $f $serializedData;
	close $f;

}

sub GetDataByUnit {
	my $self = shift;
	my $unit = shift;

	my $id        = $unit->{"unitId"};
	my %groupData = %{ $self->{"groupData"} };
	my $data      = undef;

	my %data = %{ $groupData{$id} };

	return %data;
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

