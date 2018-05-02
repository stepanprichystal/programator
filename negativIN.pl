#!/usr/bin/perl-w
#################################


use Genesis;
use Tk;
unless ($ENV{JOB}) {
	$jobName = shift;
} else {
	$jobName = "$ENV{JOB}";

}		
$genesis = new Genesis;
my $logo_way = "$ENV{'GENESIS_DIR'}/sys/scripts/gatema/error.gif"; 

$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
$totalRows = @{$genesis->{doinfo}{gROWname}};
for ($count=0;$count<$totalRows;$count++) {
	if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
		$rowName = ${$genesis->{doinfo}{gROWname}}[$count];
		$rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
		$rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
		$rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
		$rowPolarity = ${$genesis->{doinfo}{gROWpolarity}}[$count];

		if ($rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground") && $rowPolarity eq "negative") {
			push(@negativInner,$rowName);
		}
	}
}


foreach $layerNP (@negativInner) {
	$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"o+1",iconic=>'no');
    $genesis->AUX('set_group', group => $genesis->{COMANS});
    $genesis->COM('units',type=>'mm');

	$genesis->COM ('filter_reset',filter_name=>'popup');
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");

			$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/o+1",data_type => 'PROF_LIMITS');
    		    $DpsXsize = sprintf "%3.3f",(($genesis->{doinfo}{gPROF_LIMITSxmax} - $genesis->{doinfo}{gPROF_LIMITSxmin}) + 5);
       			$DpsYsize = sprintf "%3.3f",(($genesis->{doinfo}{gPROF_LIMITSymax} - $genesis->{doinfo}{gPROF_LIMITSymin}) + 5);
        
		$genesis->COM('create_layer',layer=>'__prevod_np__',context=>'misc',type=>'document',polarity=>'positive',ins_layer=>'',location=>'before');
		$genesis->COM ('display_layer',name=>'__prevod_np__',display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>'__prevod_np__');
	
		$genesis->COM ('add_surf_strt',surf_type=>'feature');
		$genesis->COM ('add_surf_poly_strt',x=>'-5.000',y=>'-5.000');
		$genesis->COM ('add_surf_poly_seg',x=>'-5.000',y=>"$DpsYsize");
		$genesis->COM ('add_surf_poly_seg',x=>"$DpsXsize",y=>"$DpsYsize");
		$genesis->COM ('add_surf_poly_seg',x=>"$DpsXsize",y=>'-5.000');
		$genesis->COM ('add_surf_poly_seg',x=>'-5.000',y=>'-5.000');
		$genesis->COM ('add_surf_poly_end');
		$genesis->COM ('add_surf_end',attributes=>'no',polarity=>'positive');
		
		$genesis->COM ('display_layer',name=>'__prevod_np__',display=>'no',number=>'1');
	
		$genesis->COM ('display_layer',name=>"$layerNP",display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>"$layerNP");
		$genesis->COM ('sel_copy_other',dest=>'layer_name',target_layer=>'__prevod_np__',invert=>'yes',dx=>'0',dy=>'0',size=>'0',x_anchor=>'0',y_anchor=>'0',rotation=>'0',mirror=>'none'); 
		$genesis->COM ('sel_copy_other',dest=>'layer_name',target_layer=>"${layerNP}_ori",invert=>'no',dx=>'0',dy=>'0',size=>'0',x_anchor=>'0',y_anchor=>'0',rotation=>'0',mirror=>'none'); 
		$genesis->COM ('display_layer',name=>"$layerNP",display=>'no',number=>'1');
	
		$genesis->COM ('display_layer',name=>'__prevod_np__',display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>'__prevod_np__');
		
		$genesis->COM ('sel_contourize',accuracy=>'6.35',break_to_islands=>'yes',clean_hole_size=>'60',clean_hole_mode=>'x_and_y');
		$genesis->COM ('sel_single_feat',operation=>'select',x=>'-2.500',y=>'-2.500',tol=>'1103.395',cyclic=>'no');
		$genesis->COM ('sel_delete');
		$genesis->COM ('zoom_home');
	
		$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>'o+1',source_layer=>'__prevod_np__',dest=>layer_name,dest_layer=>"$layerNP",mode=>'replace',invert=>'no');
		$genesis->COM('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>"$layerNP",type=>'signal');
		$genesis->COM('matrix_layer_polar',job=>"$jobName",matrix=>'matrix',layer=>"$layerNP",polarity=>'positive');
		$genesis->COM('delete_layer',layer=>'__prevod_np__');
}

				$mainMain = MainWindow->new();
						$topmain = $mainMain->Frame(-width=>10, -height=>20)->pack(-side=>'top');
						$botmain = $mainMain->Frame(-width=>10, -height=>20)->pack(-side=>'bottom');
						$main = $topmain->Frame(-width=>10, -height=>20)->pack(-side=>'right');
						$logomain = $topmain->Frame(-width=>10, -height=>20)->pack(-side=>'left'); 
							$radek = $main->Message(-justify=>'center', -aspect=>5000, -text=>"Prevod negativnich vnitrnich vrstev je hotov, ZKONTROLUJ!");
							$radek->pack();
							$radek->configure(-font=>'times 12 bold');
				   			$logo_frame = $logomain->Frame(-width=>50,-height=>50)->pack(-side=>'left');
							$error_logo = $logo_frame->Photo(-file=>"$logo_way");
							$logo_frame->Label(-image=>$error_logo)->pack();
					$button = $botmain ->Button(-text=>'konec',-command=>\&konec)->pack(-padx=>5,-pady=>5);
					$mainMain->waitVisibility;
					$mainMain->waitWindow;
					
sub konec {
	exit;
}