
#-------------------------------------------------------------------------------------------#
# Description: Do export of gerber layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Export::ExportLayers;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Export gerbers for each layer in @layers param
# This function allow set final name by defining funcs, which return suffix and preffix for file name
# Middle of file name  is name of exported layer
sub ExportLayers {
	my $self        = shift;
	my $resultItem  = shift;
	my $inCAM       = shift;
	my $step        = shift;
	my @layers      = @{ shift(@_) };
	my $archivePath = shift;
	my $prefix      = shift;                           # string, which is put before each files
	my $suffixFunc  = shift;                           # function, which return suffix, which is add behind file
	my $breakSR     = shift;
	my $breakSymbol = shift;
	my $breakArc    = shift;
	my $units       = shift // "inch";                 # units of exported data inch/mm
	my $offset      = shift // { "x" => 0, "y" => 0 };    # offset of exported data

	# Set default break step and repeat
	my $brSR = "no";

	if ($breakSR) {
		$brSR = "yes";
	}

	# Set default break symbols
	my $brSym = "no";

	if ($breakSymbol) {
		$brSym = "yes";
	}

	# Set default break arc
	my $brArc = "no";

	if ($breakArc) {
		$brArc = "yes";
	}

	my $device = "Gerber274x";

	# if last char is slash, remove becaues
	if ( substr( $archivePath, -1 ) eq "\\" ) {
		chop($archivePath);
	}

	# Set step
	CamHelper->SetStep( $inCAM, $step );

	# Add output device
	$inCAM->COM( "output_add_device", "type" => "format", "name" => $device );

	foreach my $l (@layers) {

		my $suffix = $suffixFunc->($l);

		my $mirror;

		if ( $l->{"mirror"} ) {
			$mirror = "yes";
		}
		else {
			$mirror = "no";
		}

		my $angle;

		if ( $l->{"angle"} ) {
			$angle = $l->{"angle"};
		}
		else {
			$angle = 0;
		}

		# Reset settings of device
		$inCAM->COM( "output_reload_device", "type" => "format", "name" => $device );

		# Udate settings o device
		$inCAM->COM(
			"output_update_device",
			"type"          => "format",
			"name"          => $device,
			"dir_path"      => $archivePath,
			"prefix"        => $prefix,
			"suffix"        => $suffix,
			"x_offset"      => $offset->{"x"},
			"y_offset"      => $offset->{"y"},
			"format_params" => "(break_sr=$brSR)(break_symbols=$brSym)(break_arc=$brArc)(units=$units)"

		);

		# Filter only layer, which we want to output
		$inCAM->COM( "output_device_set_lyrs_filter", "type" => "format", "name" => $device, "layers_filter" => $l->{"name"} );

		# Necessery set layer, otherwise
		$inCAM->COM(
					 "output_update_device_layer",
					 "type"     => "format",
					 "name"     => $device,
					 "layer"    => $l->{"name"},
					 "angle"    => $angle,
					 "x_mirror" => $mirror
		);

		$inCAM->COM( "output_device_select_reset", "type" => "format", "name" => $device );    #toto tady musi byt, nevim proc
		$inCAM->COM( "output_device_select",       "type" => "format", "name" => $device );

		$inCAM->HandleException(1);

		my $plotResult = $inCAM->COM(
									  "output_device",
									  "type"                 => "format",
									  "name"                 => $device,
									  "overwrite"            => "yes",
									  "overwrite_ext"        => "",
									  "on_checkout_by_other" => "output_anyway"
		);
		$inCAM->HandleException(0);

		if ( $plotResult > 0 ) {
			$resultItem->AddError( $inCAM->GetExceptionError() );
		}

		# test if file was outputed
		my $fname = $prefix . $l->{"name"} . $suffix;
		my $fileExist = FileHelper->GetFileNameByPattern( $archivePath . "\\", $fname );
		unless ($fileExist) {

			$resultItem->AddError( "Failed to create Gerber file: " . $archivePath . "\\" . $fname );
		}

		my $fileSize = -s $archivePath . "\\" . $fname;
		if ( $fileSize == 0 ) {

			$resultItem->AddError( "Error during create Gerber file: " . $archivePath . "\\" . $fname . ". File size is 0kB." );

		}

	}

}

# Export gerbers for each layer in @layers param
# This function allow set final name by defining func, which return final file name
sub ExportLayers2 {
	my $self        = shift;
	my $resultItem  = shift;
	my $inCAM       = shift;
	my $step        = shift;
	my @layers      = @{ shift(@_) };
	my $archivePath = shift;
	my $nameFunc    = shift;            # func which define name of final file
	my $breakSR     = shift;
	my $breakSymbol = shift;
	my $breakArc    = shift;
	my $units       = shift;
	my $offset      = shift;

	my $filesDir = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . "\\";

	my $suffixFunc = sub {
		my $l = shift;
		return $l->{"guid"};
	};

	foreach my $l (@layers) {

		my $fName = GeneralHelper->GetGUID();
		$l->{"guid"} = $fName;
	}

	# 1) export to TMP directory
	$self->ExportLayers( $resultItem, $inCAM, $step, \@layers, EnumsPaths->Client_INCAMTMPOTHER,
						 "", $suffixFunc, $breakSR, $breakSymbol, $breakArc, $units, $offset );

	# 2) move to finish dir and rename
	foreach my $l (@layers) {

		my $file = EnumsPaths->Client_INCAMTMPOTHER . $l->{"name"} . $l->{"guid"};

		if ( -e $file ) {

			move( $file, $archivePath . "\\" . $nameFunc->($l) );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	# function, which build output layer name
	my $suffixFunc = sub {

		my $layerName = shift;
		return $layerName;
	};

	use Packages::Gerbers::Export::ExportLayers;
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52457";

	my @layers = ();

	my %inf = ( "name" => "plgc" );
	push( @layers, \%inf );

	Packages::Gerbers::Export::ExportLayers->ExportLayers( undef, $inCAM, "mdi_panel", \@layers, "c:\\Export\\opfx", "", $suffixFunc );

}

1;

