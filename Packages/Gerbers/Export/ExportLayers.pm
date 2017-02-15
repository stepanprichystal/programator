
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
	my $prefix      = shift; # string, which is put before each files
	my $suffixFunc  = shift; # function, which return suffix, which is add behind file
	my $breakSR     = shift;
	my $breakSymbol = shift;

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
			"format_params" => "(break_sr=$brSR)(break_symbols=$brSym)"

		);

		# Filter only layer, which we want to output
		$inCAM->COM( "output_device_set_lyrs_filter", "type" => "format", "name" => $device, "layers_filter" => $l->{"name"} );

		# Necessery set layer, otherwise
		$inCAM->COM(
					 "output_update_device_layer",
					 "type"     => "format",
					 "name"     => $device,
					 "layer"    => $l->{"name"},
					 "angle"    => "0",
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
	my $nameFunc    = shift; # func which define name of final file
	my $breakSR     = shift;
	my $breakSymbol = shift;

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
	$self->ExportLayers( $resultItem, $inCAM, $step, \@layers, EnumsPaths->Client_INCAMTMPOTHER, "", $suffixFunc, $breakSR, $breakSymbol );

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

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

