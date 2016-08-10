#-------------------------------------------------------------------------------------------#
# Description: Wrapper for InCAM electrical set function
# Author: SPR
#-------------------------------------------------------------------------------------------#

package Packages::ETesting::BasicHelper::ETSet;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
# delete et set
sub ETSetDelete {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobName    = shift;
	my $stepName   = shift;
	my $optSetName = shift;
	my $etsetName  = shift;

	my $result = $inCAM->COM(
							  "etset_test_delete",
							  "job"       => $jobName,
							  "step"      => $stepName,
							  "opt_name"  => $optSetName,
							  "test_name" => $etsetName,
							  "split_1"   => "split_1"
	);

	#if ok, InCAm return 0
	if ( $result == 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}

#test if et set exist
sub ETSetExist {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobName    = shift;
	my $stepName   = shift;
	my $optSetName = shift;
	my $etsetName  = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'et-opt',
				  entity_path     => "$jobName/$stepName/$optSetName/$etsetName",
				  data_type       => 'EXISTS'
	);
	my $reply = $inCAM->{"doinfo"}{"gEXISTS"};

	if ( $reply eq "yes" ) {
		return 1;
	}
	else {
		return 0;
	}
}

#create optimization set for given job, steps
# return 0/1 depand on failure/succes
# parameter $optName is reference and will  contain optSet name
sub ETSetCreate {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobName  = shift;
	my $stepName = shift;    #step, which optSet is tied with
	my $optName  = shift;

	my $etSetName = shift;    #reference
	$$etSetName = GeneralHelper->GetGUID();

	my $result = $inCAM->COM(
							  "etset_create_test",
							  "job"            => $jobName,
							  "step"           => $stepName,
							  "opt_name"       => $optName,
							  "test_name"      => $$etSetName,
							  "split_1"        => "split_1",
							  "setup_test"     => "1",
							  "component_down" => "no"
	);

	#if ok, InCAm return 0
	if ( $result == 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}

# Do output of ipc, based on ETSet and OptSet
# Default output location: EnumsPaths->Client_ELTESTS
sub ETSetOutput {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobName   = shift;
	my $stepName  = shift;    #step, which optSet is tied with
	my $optName   = shift;
	my $etSetName = shift;

	#optional parameters
	my $outPath  = shift;
	my $fileName = shift;
	my $fileSuff = shift;

	unless ($outPath) {
		$outPath = EnumsPaths->Client_ELTESTS . $jobName . "t";
	}

	unless ($fileName) {
		$fileName = lc($jobName) . "t";
	}

	unless ($fileSuff) {
		$fileSuff = "ipc";
	}

	#test if outpath dir exist
	unless ( -e $outPath ) {
		mkdir($outPath) or die "Can't create dir: " . $outPath . $_;
	}

	my $params =
"(dir_path=$outPath)(filename=$fileName)(extension=$fileSuff)(dx=0)(dy=0)(angle=0)(adapter_coord=no)(angle_direction=cw)(out_unit=inch)(adjacency=no)(out_mid_points=no)(net_name_from_one=no)(tooling=yes)(trace=yes)(surface_mode=contour)(surface_aperture=25.4)(min_brush_for_fill=25.4)(_099_extention_rec=no)(iol_ipcd356a_radius_tol=2)(iol_ipcd356a_outline_draw_size=50)(iol_ipcd356a_output_profiles=yes)";
 	
	my $result = $inCAM->COM(
							  "et_output",
							  "job"                => $jobName,
							  "step"               => $stepName,
							  "opt_name"           => $optName,
							  "test_name"          => $etSetName,
							  "split_1"            => "",
							  "type"               => "optimization",
							  "output_format_name" => "ipca",
							  "car_format_name"    => "none",
							  "steps"              => "",
							  "et_format_params"   => $params,
							  "car_format_params"  => ""
	);
	
	
 

	#if ok, InCAm return 0
	if ( $result == 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::ETesting::BasicHelper::OptSet';
	use aliased 'Packages::ETesting::BasicHelper::ETSet';
	my $inCAM = InCAM->new();

	my $jobName      = "f13610";
	my $stepName     = "panel";
	my $setupOptName = "atg_flying";
	my @steps        = ( "o+1", "mpanel" );

	my $optName = OptSet->OptSetCreate( $inCAM, $jobName, $stepName, $setupOptName, \@steps );

	my $etsetName = ETSet->ETSetCreate( $inCAM, $jobName, $stepName, $optName );

	ETSet->ETSetOutput( $inCAM, $jobName, $stepName, $optName, $etsetName );

	if ( ETSet->ETSetExist( $inCAM, $jobName, $stepName, $optName, $etsetName ) ) {

		ETSet->ETSetDelete( $inCAM, $jobName, $stepName, $optName, $etsetName );
	}

	if ( OptSet->OptSetExist( $inCAM, $jobName, $stepName, $optName ) ) {

		OptSet->OptSetDelete( $inCAM, $jobName, $stepName, $optName );
	}

}

1;
