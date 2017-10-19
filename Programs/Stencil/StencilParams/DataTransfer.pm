
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilParams::DataTransfer::DataTransfer;

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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"filePath"} = shift;

	unless ( defined $self->{"filePath"} ) {

		$self->{"filePath"} = JobHelper->GetJobOutput( $self->{"jobId"} ) . "stencilParams";
	}

	$self->{"hashData"} = {};

	return $self;
}

sub LoadStenciLParams {
	my $self = shift;

	my $json = JSON->new();

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

# Serialize class "ExportData"
sub SaveStencilParams {
	my $self          = shift;
	my $stencilParams = shift;

	my ( $sec, $min, $hour ) = localtime();
	my $time = sprintf( "%02d:%02d", $hour, $min );

	$self->{"hashData"}->{"time"}        = $time;
	$self->{"hashData"}->{"__PACKAGE__"} = ref $stencilParams;
	$self->{"hashData"}                  = $stencilParams->{"data"};

	# serialize and save
	my $hashData = $self->{"hashData"};

	my $json       = JSON->new();
	my $serialized = $json->pretty->encode($hashData);

	#delete old file
	unlink $self->{"filePath"};

	open( my $f, '>', $self->{"filePath"} );
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

