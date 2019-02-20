
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading stencil serialization data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::CpnConfigSerializer::CpnConfigSerializer;

#3th party library
use strict;
use warnings;
use utf8;
use JSON;

#local library

use aliased "Enums::EnumsPaths";
use aliased "Helpers::FileHelper";
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"filePath"} =  Enumsaths->Client_INCAMTMPIMPGEN;

	unless ( defined $self->{"filePath"} ) {

		my $dir = JobHelper->GetJobOutput( $self->{"jobId"} ) . "stencilParams\\";
		unless ( -e $dir ) {
			mkdir($dir) or die "Can't create dir: " . $dir . $_;
		}

		$self->{"filePath"} = $dir . "stencilParams";
	}

	$self->{"hashData"} = {};

	return $self;
}

sub ConfigFileExist{
	my $self = shift;
		
	
	return -e $self->{"filePath"} );
}

# Load serialized cpn config data
sub LoadStenciLParams {
	my $self = shift;

	my $json = JSON->new();

	unless ( -e $self->{"filePath"} ) {
		die "Serialized stensil parameter file doesnt exist" . $self->{"filePath"};
	}

	my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );

	my $hashData = $json->decode($serializeData);

	# Get information about package name
	my $packageName = $hashData->{"__PACKAGE__"};

	# Convert to object by package name
	eval("use $packageName;");
	my $stencilParams = $packageName->new();
	$stencilParams->{"data"} = $hashData;

	return $stencilParams;
}

# Serialize and store cpn config data
sub SaveCpnConfig {
	my $self          = shift;
	my $cpnConfig = shift;
	
 	my $storable     = JsonStorable->new();
	my $serialized = $storable->Encode($layout);
	
	#delete old file
	unlink $self->{"filePath"};

	open( my $f, '>', $self->{"filePath"} ) or die "Unable create config file: ".$self->{"filePath"};
	print $f $serialized;
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

