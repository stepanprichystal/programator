
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Export::ExportLayers;
 

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 
 

sub ExportLayers {
	my $self = shift;
	my $resultItem = shift;
	my $inCAM = shift;
	my $step = shift;
	my @layers = @{shift(@_)};
	my $archivePath = shift;
	my $prefix = shift;
	my $suffixFunc = shift;
 
 	my $device = "Gerber274x";
 	
 
 
# Set step
	CamHelper->SetStep($inCAM, $step);

	# Add output device
	$inCAM->COM( "output_add_device", "type" => "format", "name" => $device );

	 

	foreach my $l (@layers ) {

			my $suffix = $suffixFunc->($l);

		
		
		my $mirror;
		
		if($l->{"mirror"}){
			$mirror = "yes";
		}else{
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
			"format_params" => "(break_sr=yes)(break_symbols=yes)"

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
		my $fname = $prefix . $l->{"name"} .$suffix;
		my $fileExist = FileHelper->GetFileNameByPattern( $archivePath . "\\", $fname );
		unless ($fileExist) {
 
			$resultItem->AddError( "Failed to create Gerber file: " . $archivePath . "\\" . $fname );
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

