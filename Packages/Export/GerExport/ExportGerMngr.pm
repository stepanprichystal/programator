
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportGerMngr;
use base('Packages::Export::MngrBase');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"layers"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

 
	$self->__Export();
}

sub __Export {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $archive     = JobHelper->GetJobArchive($jobId);
	my $output      = JobHelper->GetJobOutput($jobId);
	my $archivePath = $archive . "zdroje";

	#delete old ger form archive
	my @filesToDel = FileHelper->GetFilesNameByPattern( $archivePath, ".ger" );

	foreach my $f (@filesToDel) {
		unlink $f;
	}

	# Add output device
	$inCAM->COM( "output_add_device", "type" => "format", "name" => "Gerber274x" );

	my $resultItemGer = $self->_GetNewItem("Output files");

	foreach my $l ( @{ $self->{"layers"} } ) {

		# Reset settings of device
		$inCAM->COM( "output_reload_device", "type" => "format", "name" => "LP7008" );

		# Udate settings o device
		$inCAM->COM(
			"output_update_device",
			"type"          => "format",
			"name"          => "Gerber274x",
			"dir_path"      => $archivePath,
			"prefix"        => $jobId,
			"suffix"        => "_komp" . $l->{"comp"} . "µm-.ger",
			"format_params" => "(break_sr=yes)(break_symbols=yes)"

		);

		# Filter only layer, which we want to output
		$inCAM->COM( "output_device_set_lyrs_filter", "type" => "format", "name" => "LP7008", "layers_filter" => $l->{"name"} );

		my $mirror = $l->{"name"} =~ /c$/i ? "yes" : "no";

		# Necessery set layer, otherwise
		$inCAM->COM(
					 "output_update_device_layer",
					 "type"     => "format",
					 "name"     => "Gerber274x",
					 "layer"    => $l->{"name"},
					 "angle"    => "0",
					 "x_mirror" => $mirror
		);

		$inCAM->COM( "output_device_select_reset", "type" => "format", "name" => "Gerber274x" );    #toto tady musi byt, nevim proc
		$inCAM->COM( "output_device_select",       "type" => "format", "name" => "Gerber274x" );

		$inCAM->HandleException(1);

		my $plotResult = $inCAM->COM(
									  "output_device",
									  "type"                 => "format",
									  "name"                 => "Gerber274x",
									  "overwrite"            => "yes",
									  "overwrite_ext"        => "",
									  "on_checkout_by_other" => "output_anyway"
		);
		$inCAM->HandleException(0);

		if ( $plotResult > 0 ) {
			$resultItemGer->AddError( $inCAM->GetExceptionError() );
		}

		# test if file was outputed

		my $fileExist = FileHelper->GetFileNameByPattern( $archivePath . "\\", );
		unless ($fileExist) {

			my $fname = $jobId . $l->{"name"} . "_komp" . $l->{"comp"} . "µm-.ger";
			$resultItemGer->AddError( "Failed to create Gerber file: " . $archivePath . "\\" . $fname );
		}

	}

	$self->_OnItemResult($resultItemGer);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

