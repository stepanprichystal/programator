#!/usr/bin/perl

use Genesis;
my $genesis = new Genesis;



unless ($ENV{JOB}) {
	$jobName = shift;
	$stepName = shift;
}else{
	$jobName = "$ENV{JOB}";
	$stepName = "$ENV{STEP}";
}

$genesis->COM('editor_page_close');
$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$stepName",iconic=>'no');
$genesis->COM('clear_layers');


# Here will be create netlist panel for check.
my $stepNetlist = 'o+1_panel';
$genesis -> COM('copy_entity',type=>'step',source_job=>"$jobName",source_name=>'mpanel',dest_job=>"$jobName",dest_name=>"$stepNetlist",dest_database=>'');




    my $layerCount = 0;
    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
	my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
	my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
	my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
	my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
			if ($rowName) {
            		push(@layersFlatten,$rowName);
			}
	}
				foreach $oneLayer (@layersFlatten) {
					$genesis->COM('flatten_layer',source_layer=>"$oneLayer",target_layer=>"${oneLayer}_flat_");
				}
				foreach $oneLayer (@layersFlatten) {
					$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$stepName",source_layer=>"${oneLayer}_flat_",dest=>'layer_name',dest_layer=>"$oneLayer",mode=>'replace',invert=>'no');
					$genesis -> COM ('delete_layer',layer=>"${oneLayer}_flat_");
				}
				$genesis -> COM ('sr_active',top=>'0',bottom=>'0',left=>'0',right=>'0');
				$genesis -> COM ('profile_to_rout',layer=>'prof_tmp',width=>'300');

				$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'NUM_SR');
			    		$numStepPanel = $genesis->{doinfo}{gNUM_SR};
  							for($z=1;$z<=$numStepPanel;$z++) {
 				 					$genesis->COM('sr_tab_del',line=>'1');
  							}
  							
  			$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'PROF_LIMITS');
        		$myDpsXsize = sprintf "%3.3f",($genesis->{doinfo}{gPROF_LIMITSxmin} * -1);
        		$myDpsYsize = sprintf "%3.3f",($genesis->{doinfo}{gPROF_LIMITSymin} * -1);
        		
  			$genesis -> COM ('affected_layer',affected=>'yes',mode=>'all');
	       	$genesis -> COM ('sel_move',dx=>"$myDpsXsize",dy=>"$myDpsYsize");
	       	$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
	       	
	       	$genesis -> COM ('display_layer',name=>'prof_tmp',display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>'prof_tmp');
			$genesis -> COM ('filter_area_strt');
			$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
			$genesis -> COM ('sel_create_profile');
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('display_layer',name=>'prof_tmp',display=>'no',number=>'1');
	       	
	       	$genesis->COM ('delete_layer',layer=>'prof_tmp');
	       	$genesis->COM ('datum',x=>0,y=>0);
			$genesis->COM ('zoom_home');
	       	
	       	
	       	$genesis->COM ('rename_entity',job=>"$jobName",is_fw=>'no',type=>'step',fw_type=>'form',name=>'o+1',new_name=>'o+1_single');
			$genesis->COM ('rename_entity',job=>"$jobName",is_fw=>'no',type=>'step',fw_type=>'form',name=>'mpanel',new_name=>'o+1');
	       	
	       	
	       	