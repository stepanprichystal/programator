#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::OpfxCreator::OpfxCreator;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;    #board layers

	my @plotSets = ();
	$self->{"plotSets"} = \@plotSets;

	return $self;
}

sub AddPlotSet {
	my $self    = shift;
	my $plotSet = shift;

	push( @{ $self->{"plotSets"} }, $plotSet );

}

sub Export {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $archive = JobHelper->GetJobArchive($jobId);
	my $output  = JobHelper->GetJobOutput($jobId);

	$inCAM->COM( "set_step", "name" => "panel" );
	$inCAM->COM( "units",    "type" => "mm" );

	# Seto OPFX ouput device

	# Export single plot sets

	foreach my $plotSet ( @{ $self->{"plotSets"} } ) {

		# Select item selection
		$inCAM->COM( "output_device_select_reset", "type" => "format", "name" => "OPFX" );
		#$inCAM->COM("output_device_show","type" => "format","name" => "OPFX");
		$inCAM->COM("output_add_device","type" => "format","name" => "OPFX");
		$inCAM->COM( "output_update_device",  "type" => "format", "name" => "OPFX", "suffix" => "_opfx", "dir_path"=> $output, "format_params" => "(iol_surface_check=yes)" );

		my $fName = $jobId . "@";
		my $bigIndicator = $plotSet->GetFilmSize() eq Enums->FilmSize_Big ? "v" : "";

		# Select layer by layer
		foreach my $plotL ( $plotSet->GetLayers() ) {

			my $lName = $plotL->GetName();

			$inCAM->COM( "output_device_select_item", "type" => "format", "name" => "OPFX", "item" => $lName, "select" => "yes" );

			my $angle  = $plotSet->GetOrientation() eq Enums->Ori_VERTICAL ? 0     : 90;
			my $mirror = $plotL->Mirror()                                ? "yes" : "no";
			my $comp   = $plotL->GetComp();
			my $polarity = $plotL->GetPolarity();

			$inCAM->COM(
						 "output_update_device_layer",
						 "type"         => "format",
						 "name"         => "OPFX",
						 "layer"        => $lName,
						 "angle"        => $angle,
						 "y_mirror"     => $mirror,
						 "comp"         => $comp / 1000,
						 "polarity"     => $polarity,
						 "setupfile"    => "",
						 "setupfiletmp" => "",
						 "line_units"   => "mm",
						 "gscl_file"    => ""
			);

			$fName .= $lName . $bigIndicator . "_" . $comp;

		}

		print $inCAM->COM(
					 "output_device",
					 "type"                 => "format",
					 "name"                 => "OPFX",
					 "overwrite"            => "yes",
					 "overwrite_ext"        => "",
					 "on_checkout_by_other" => "output_anyway"
		);

		# after export, move to archive
		copy( $output . "_opfx", $archive . "." . $fName ) or die "Copy failed: $!";

	}

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
