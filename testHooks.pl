#!/usr/bin/perl -w
 
#use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::InCAM::InCAM';
 

test();

sub test {



  
	 $ENV{INCAM_SERVER} =  "//incam/incam_server";

	 $ENV{INCAM_PRODUCT} = "c:/opt/InCAM/3.00SP1";

	 $ENV{INCAM_TMP} = "c:/tmp/InCam/"; #: Contains the path to the tmp directory.

	 $ENV{JOB} = "f13610";  # : Contains the name of the current job.

	 $ENV{STEP}  = "panel";  #: Contains the name of the current step.

     $ENV{INCAM_USER_DIR}  =  "//incam/incam_server/users/stepan"; 
     
     $ENV{INCAM_SITE_DATA_DIR} =   "//incam/incam_server/site_data";
     
     $ENV{INCAM_LOCAL_DIR} =   "//incam/incam_server/local/spr";
 




	#pcb id
	my $jobId = "f13610";

	#init CAM
	my $inCAM = InCAM->new();

	$inCAM->COM(
				 "clipb_open_job",
				 "job"              => "$jobId",
				 "update_clipboard" => "view_job"
	);
	$inCAM->COM( "open_job", "job" => "$jobId", "open_win" => "yes" );
	$inCAM->COM("open_entity",
				 "job"  => "$jobId",
				 "type" => "step",
				 "name" => "panel"
	);

	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

  
	my $stepName = "panel";
	my $layerName = "m";
	my $machine = "machine_b";
	my $setName = "abc";

	$inCAM->COM( 'set_step', "name" => $stepName );
	$inCAM->COM("open_sets_manager","test_current" => "no");
	$inCAM->COM( 'nc_create', "ncset" => $setName, "device" => $machine, "lyrs" => $layerName, "thickness"=> 0 );
	$inCAM->COM("nc_set_advanced_params","layer" => $layerName,"ncset" => $setName,"parameters" => "(iol_sm_g84_radius=no)");
	$inCAM->COM(" nc_set_current","job" => $jobId,"step" => $stepName,"layer" => $layerName,"ncset" => $setName);
	$inCAM->COM( "nc_cre_output", "layer" => $layerName, "ncset" => $setName );
	$inCAM->COM( "close_job", "job" => "f13610" );
	
}
