#!/usr/bin/perl-w
#################################
#Sript name: npth2m.pl
#Verze     : 1.00
#Use       : Pøesune NPTh menší než 1,02mm do vrstvy m a naopak NPTh vìtší než 1,02mm do vrstvy f
#Made      : rc
#################################

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();
my $jobID = "$ENV{JOB}";
my $step  = $ENV{STEP};
my $maxDiameter  = "1.02"; # old parametr "0.49"
my $nptLayer  = "f";
my $ptLayer  = "m";

# hide all + clear all layers
$inCAM->COM("clear_layers");
$inCAM->COM("affected_layer",name=>"",mode=>"all",affected=>"no");

$inCAM->COM("display_layer",name=>"$nptLayer",display=>"yes");
$inCAM->COM("work_layer",name=>"$nptLayer");

# filter all pads bellow 1,02mm  (= 1,02mm a ménì)
$inCAM->COM("top_tab",tab=>"Features Filter");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"all");
$inCAM->COM("set_filter_type",filter_name=>"",lines=>"no",pads=>"yes",surfaces=>"no",arcs=>"no",text=>"no");
$inCAM->COM("set_filter_polarity",filter_name=>"",positive=>"yes",negative=>"no");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"profile");
$inCAM->COM("reset_filter_criteria",filter_name=>"popup",criteria=>"inc_attr");
$inCAM->COM("reset_filter_criteria",filter_name=>"popup",criteria=>"exc_attr");
$inCAM->COM("set_filter_symbols",filter_name=>"",exclude_symbols=>"no",symbols=>"");
$inCAM->COM("set_filter_symbols",filter_name=>"",exclude_symbols=>"yes",symbols=>"");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"text");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"dcode");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"net");
$inCAM->COM("set_filter_length");
$inCAM->COM("set_filter_angle");
$inCAM->COM("adv_filter_reset");
$inCAM->COM("adv_filter_set",filter_name=>"popup",active=>"yes",limit_box=>"yes",min_dx=>"0",max_dx=>"$maxDiameter",min_dy=>"0",max_dy=>"0",bound_box=>"no",srf_values=>"no",srf_area=>"no",mirror=>"any",ccw_rotations=>"");
$inCAM->COM("filter_area_strt");
$inCAM->COM("filter_area_end",filter_name=>"popup",operation=>"select");

$inCAM->COM ('get_select_count'); 
                         if ($inCAM->{COMANS} > 0) {
	$inCAM->COM("top_tab",tab=>"Rout Parameters Page");
	$inCAM->COM("sel_move_other",target_layer=>"m",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0");
	$inCAM->COM("display_layer",name=>"$ptLayer",display=>"yes");
	$inCAM->COM("work_layer",name=>"$ptLayer");
						}


$inCAM->COM("display_layer",name=>"$ptLayer",display=>"yes");
$inCAM->COM("work_layer",name=>"$ptLayer");

# filter all pads above 1,02mm (= 1,03mm a výše)
$inCAM->COM("top_tab",tab=>"Features Filter");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"all");
$inCAM->COM("set_filter_type",filter_name=>"",lines=>"yes",pads=>"yes",surfaces=>"yes",arcs=>"yes",text=>"yes");
$inCAM->COM("set_filter_polarity",filter_name=>"",positive=>"yes",negative=>"yes");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"profile");
$inCAM->COM("reset_filter_criteria",filter_name=>"popup",criteria=>"inc_attr");
$inCAM->COM("set_filter_attributes",filter_name=>"popup",exclude_attributes=>"no",condition=>"yes",attribute=>".drill",min_int_val=>"0",max_int_val=>"0",min_float_val=>"0",max_float_val=>"0",option=>"non_plated",text=>"");
$inCAM->COM("set_filter_and_or_logic",filter_name=>"popup",criteria=>"inc_attr",logic=>"and");
$inCAM->COM("reset_filter_criteria",filter_name=>"popup",criteria=>"exc_attr");
$inCAM->COM("set_filter_symbols",filter_name=>"",exclude_symbols=>"no",symbols=>"");
$inCAM->COM("set_filter_symbols",filter_name=>"",exclude_symbols=>"yes",symbols=>"");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"text");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"dcode");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"net");
$inCAM->COM("set_filter_length");
$inCAM->COM("set_filter_angle");
$inCAM->COM("adv_filter_reset");
$inCAM->COM("adv_filter_set",filter_name=>"popup",active=>"yes",limit_box=>"yes",min_dx=>"$maxDiameter",max_dx=>"2233",min_dy=>"0",max_dy=>"0",bound_box=>"no",srf_values=>"no",srf_area=>"no",mirror=>"any",ccw_rotations=>"");
$inCAM->COM("filter_area_strt");
$inCAM->COM("filter_area_end",filter_name=>"popup",operation=>"select");

$inCAM->COM ('get_select_count'); 
                         if ($inCAM->{COMANS} > 0) {
	$inCAM->COM("top_tab",tab=>"Rout Parameters Page");
	$inCAM->COM("sel_move_other",target_layer=>"$nptLayer",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0");
	$inCAM->COM("display_layer",name=>"$ptLayer",display=>"yes");
	$inCAM->COM("work_layer",name=>"$ptLayer");
						}
$inCAM->COM("adv_filter_reset");
$inCAM->COM("reset_filter_criteria",filter_name=>"",criteria=>"all");
