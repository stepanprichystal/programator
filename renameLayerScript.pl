#!/usr/bin/perl-w


#loading of locale modules
 
#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );


#local library
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';

unless ($ENV{JOB}) {
	$jobName = shift;
	$stepName = shift;
} else {
	$jobName = "$ENV{JOB}";
	$stepName = "$ENV{STEP}";
	
}
my $genesis = InCAM->new();


#my $jobName = "$ENV{JOB}";
my $dcode_for_score = r500;
my %layerHash;

my $inputStep = $stepName;
my $workStep  = 'o+1';

# At first I will remove unused layers
_DeleteUnusedLayer('pastetop','pastebot');

#	
$layerHash{'plt'} = {
						'nameNew' => 'pc',
						};
$layerHash{'smt'} = {
						'nameNew' => 'mc',
						};
$layerHash{'top'} = {
						'nameNew' => 'c',
						};
$layerHash{'pg2'} = {
						'nameNew' => 'v2',
						};
$layerHash{'pg3'} = {
						'nameNew' => 'v3',
						};
$layerHash{'pg4'} = {
						'nameNew' => 'v4',
						};
$layerHash{'pg5'} = {
						'nameNew' => 'v5',
						};
$layerHash{'pg6'} = {
						'nameNew' => 'v6',
						};
$layerHash{'pg7'} = {
						'nameNew' => 'v7',
						};
$layerHash{'pg8'} = {
						'nameNew' => 'v8',
						};
$layerHash{'pg9'} = {
						'nameNew' => 'v9',
						};
$layerHash{'in2'} = {
						'nameNew' => 'v2',
						};
$layerHash{'in3'} = {
						'nameNew' => 'v3',
						};
$layerHash{'in4'} = {
						'nameNew' => 'v4',
						};
$layerHash{'in5'} = {
						'nameNew' => 'v5',
						};
$layerHash{'in6'} = {
						'nameNew' => 'v6',
						};
$layerHash{'in7'} = {
						'nameNew' => 'v7',
						};
$layerHash{'in8'} = {
						'nameNew' => 'v8',
						};
$layerHash{'in9'} = {
						'nameNew' => 'v9',
						};
$layerHash{'bot'} = {
						'nameNew' => 's',
						};
$layerHash{'smb'} = {
						'nameNew' => 'ms',
						};
$layerHash{'plb'} = {
						'nameNew' => 'ps',
						};
$layerHash{'mil'} = {
						'nameNew' => 'f',
						'type' => 'rout',
						};
$layerHash{'mil-pth'} = {
						'nameNew' => 'r',
						'type' => 'rout',
						};
$layerHash{'slot'} = {
						'nameNew' => 'r',
						'type' => 'rout',
						};
$layerHash{'sco'} = {
						'nameNew' => 'score',
						'type' => 'rout',
						};
$layerHash{'pth'} = {
						'nameNew' => 'm',
						'type' => 'drill',
						};

if (CamJob->GetSignalLayerCnt($genesis, $jobName) == 1) {
							$layerHash{'npth'} = {
													'nameNew' => 'm',
													'type' => 'drill',
													};
}else{
							$layerHash{'npth'} = {
													'nameNew' => 'd',
													'type' => 'drill',
													};
}
								
						
$genesis -> COM ('open_entity',job=>"$jobName",type=>'matrix',name=>'matrix',iconic=>'no');
		
foreach my $origName (keys %layerHash) {
		$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$inputStep/$origName",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					
						if (exists $layerHash{$origName}->{'type'}) {
									$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>"$origName",type=>$layerHash{$origName}->{'type'});
						}
						
						$genesis -> COM ('matrix_rename_layer',job=>"$jobName",matrix=>'matrix',layer=>"$origName",new_name=>$layerHash{$origName}->{'nameNew'});
				}
}
$genesis -> COM ('matrix_page_close',job=>"$jobName",matrix=>'matrix');

# Here I will merge NPTH layer with mill layer
_MergeNPTHwithMILL ('d', 'f');


$genesis -> COM ('editor_page_close');
$genesis -> COM ('copy_entity',type=>'step',source_job=>"$jobName",source_name=>"$inputStep",dest_job=>"$jobName",dest_name=>'o+1');
$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>'o+1',iconic=>'no');




sub _MergeNPTHwithMILL {
		my $nameOfnpthLayer = shift;
		my $nameOfmillLayer = shift;


		$genesis -> INFO(entity_type => 'job',entity_path => "$jobName",data_type => 'STEPS_LIST');
		my @stepsArr = @{$genesis->{doinfo}{gSTEPS_LIST}};
		
		
		$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$inputStep/$nameOfnpthLayer",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							foreach my $oneStep (@stepsArr) {
							    #$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$oneStep",iconic=>'no');
    							#$genesis -> AUX ('set_group', group => $genesis->{COMANS});
    							$genesis ->	COM ('set_step',name=>"$oneStep");
    							$genesis -> COM ('units',type=>'mm');
								$genesis -> COM ('clear_layers');
    							$genesis -> COM ('filter_reset',filter_name=>'popup');
	 							$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
	 					
			 					$genesis -> COM ('display_layer',name=>"$nameOfnpthLayer",display=>'yes',number=>'1');
	 							$genesis -> COM ('work_layer',name=>"$nameOfnpthLayer");
	 							$genesis -> COM ('sel_move_other',target_layer=>"$nameOfmillLayer",invert=>'no',dx=>'0',dy=>'0',size=>'0');
	 							
	 							$genesis -> COM ('display_layer',name=>"$nameOfnpthLayer",display=>'no',number=>'1');
	 							$genesis -> COM ('editor_page_close');
    						}
						$genesis -> COM ('delete_layer',layer=>"$nameOfnpthLayer");
				}
}

sub _DeleteUnusedLayer {	### MAZU NEPOTREBNE VRSTVY
		my @tmpArr = @_;
				foreach my $itemDel (@tmpArr) {
  						$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$inputStep/$itemDel",data_type=>'exists');
  						if ($genesis->{doinfo}{gEXISTS} eq "yes") {
  								$genesis -> COM ('delete_layer',layer=>"$itemDel");
  						}
				}
}