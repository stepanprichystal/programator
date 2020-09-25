#-------------------------------------------------------------------------------------------#
# Description:  Wrapper for InCAM optimization set function
# Author: SPR
#-------------------------------------------------------------------------------------------#

package Packages::ETesting::BasicHelper::OptSet;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::ETesting::BasicHelper::NetPointReport';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# delete optimization set
sub OptSetDelete {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobName    = shift;
	my $stepName   = shift;
	my $optSetName = shift;

	my $result = $inCAM->COM( "etset_opt_delete", "job" => $jobName, "step" => $stepName, "opt_name" => $optSetName );

	#if ok, InCAm return 0
	if ( $result == 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}

#test if optimization set exist
sub OptSetExist {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobName    = shift;
	my $stepName   = shift;
	my $optSetName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'et-opt',
				  entity_path     => "$jobName/$stepName/$optSetName",
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
sub OptSetCreate {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobName       = shift;
	my $stepName      = shift;             #step, which optSet is tied with
	my $setupOptName  = shift;
	my @steps         = @{ shift(@_) };    #tell, which steps are tested in this optSet
	my $optName       = shift;             #reference
	my $netPoinReport = shift;             # Ref to storing Test Point report after optimization

	$$optName = GeneralHelper->GetGUID();
	my $strSteps = join( "\\;", @steps );

	my $result = $inCAM->COM(
							  "etset_create_opt",
							  "job"          => $jobName,
							  "step"         => $stepName,
							  "opt_name"     => $$optName,
							  "setup_opt"    => $setupOptName,
							  "steps"        => $strSteps,
							  "use_cad_info" => "no",
							  "policy"       => "sm",
							  "layers_list"  => ""
	);

	$result += $inCAM->COM( "etset_opt_cur", "job" => $jobName, "step" => $stepName, "opt_name" => $$optName );

	$result += $inCAM->COM("et_netlist_optimize");

	#if ok, InCAm return 0
	if ( $result == 0 ) {

		if ( defined $netPoinReport ) {

			my $pReport = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

			# Warning, this command couse InCAM crash, if OPT set was not created properly
			$inCAM->COM( "et_optimization_text_report", "output" => "file", "out_file" => $pReport );
			$$netPoinReport = NetPointReport->new($pReport);
			unlink($pReport);
		}

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

	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::ETesting::BasicHelper::OptSet';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName      = "f13610";
	#	my $stepName     = "panel";
	#	my $setupOptName = "atg_flying";
	#	my @steps        = ( "o+1", "mpanel" );
	#	my $optName      = OptSet->OptSetCreate( $inCAM, $jobName, $stepName, $setupOptName, \@steps );
	#
	#	if ( OptSet->OptSetExist( $inCAM, $jobName, $stepName, $optName ) ) {
	#
	#		OptSet->OptSetDelete( $inCAM, $jobName, $stepName, $optName );
	#	}
}

1;
