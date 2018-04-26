#!/usr/bin/perl
use Genesis;
my $genesis = new Genesis;


$genesis -> COM ('sel_clear_feat');

#smazání všech sliversù
$genesis -> COM ("affected_filter",filter=>"(type=signal|power_ground|mixed|components|mask&context=board)");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"all");
$genesis -> COM ("set_filter_type",filter_name=>"",lines=>"yes",pads=>"yes",surfaces=>"yes",arcs=>"yes",text=>"yes");
$genesis -> COM ("set_filter_polarity",filter_name=>"",positive=>"yes",negative=>"yes");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"profile");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"inc_attr");
$genesis -> COM ("set_filter_attributes",filter_name=>"popup",exclude_attributes=>"no",condition=>"no",attribute=>".sliver_fill",min_int_val=>"0",max_int_val=>"0",min_float_val=>"0",max_float_val=>"0",option=>"",text=>"");

$genesis -> COM ("set_filter_and_or_logic",filter_name=>"popup",criteria=>"inc_attr",logic=>"and");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"exc_attr");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"no",symbols=>"");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"yes",symbols=>"");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"text");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"dcode");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"net");
$genesis -> COM ("set_filter_length");
$genesis -> COM ("set_filter_angle");
$genesis -> COM ("adv_filter_reset");
$genesis -> COM ("adv_filter_set",filter_name=>"popup",active=>"yes",limit_box=>"no",bound_box=>"no",srf_values=>"no",srf_area=>"no",mirror=>"any",ccw_rotations=>"");
$genesis -> COM ("filter_area_end",operation=>"select");

#smazání všech dfm_added_shave=SLR
$genesis -> COM ("affected_filter",filter=>"(type=signal|power_ground|mixed|components|mask&context=board)");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"all");
$genesis -> COM ("set_filter_type",filter_name=>"",lines=>"yes",pads=>"yes",surfaces=>"yes",arcs=>"yes",text=>"yes");
$genesis -> COM ("set_filter_polarity",filter_name=>"",positive=>"yes",negative=>"yes");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"profile");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"inc_attr");
$genesis -> COM ("set_filter_attributes",filter_name=>"popup",exclude_attributes=>"no",condition=>"no",attribute=>".dfm_added_shave",min_int_val=>"0",max_int_val=>"0",min_float_val=>"0",max_float_val=>"0",option=>"",text=>"SLR");

$genesis -> COM ("set_filter_and_or_logic",filter_name=>"popup",criteria=>"inc_attr",logic=>"and");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"exc_attr");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"no",symbols=>"");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"yes",symbols=>"");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"text");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"dcode");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"net");
$genesis -> COM ("set_filter_length");
$genesis -> COM ("set_filter_angle");
$genesis -> COM ("adv_filter_reset");
$genesis -> COM ("adv_filter_set",filter_name=>"popup",active=>"yes",limit_box=>"no",bound_box=>"no",srf_values=>"no",srf_area=>"no",mirror=>"any",ccw_rotations=>"");
$genesis -> COM ("filter_area_end",operation=>"select");

#smazání všech dfm_added_shave=SNR
$genesis -> COM ("affected_filter",filter=>"(type=signal|power_ground|mixed|components|mask&context=board)");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"all");
$genesis -> COM ("set_filter_type",filter_name=>"",lines=>"yes",pads=>"yes",surfaces=>"yes",arcs=>"yes",text=>"yes");
$genesis -> COM ("set_filter_polarity",filter_name=>"",positive=>"yes",negative=>"yes");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"profile");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"inc_attr");
$genesis -> COM ("set_filter_attributes",filter_name=>"popup",exclude_attributes=>"no",condition=>"no",attribute=>".dfm_added_shave",min_int_val=>"0",max_int_val=>"0",min_float_val=>"0",max_float_val=>"0",option=>"",text=>"SNR");

$genesis -> COM ("set_filter_and_or_logic",filter_name=>"popup",criteria=>"inc_attr",logic=>"and");
$genesis -> COM ("reset_filter_criteria",filter_name=>"popup",criteria=>"exc_attr");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"no",symbols=>"");
$genesis -> COM ("set_filter_symbols",filter_name=>"",exclude_symbols=>"yes",symbols=>"");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"text");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"dcode");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"net");
$genesis -> COM ("set_filter_length");
$genesis -> COM ("set_filter_angle");
$genesis -> COM ("adv_filter_reset");
$genesis -> COM ("adv_filter_set",filter_name=>"popup",active=>"yes",limit_box=>"no",bound_box=>"no",srf_values=>"no",srf_area=>"no",mirror=>"any",ccw_rotations=>"");
$genesis -> COM ("filter_area_end",operation=>"select");

$genesis->COM('get_select_count');			# = pokud nejsou oznaèeny ádné vrstvy, nic to neudìlá, 
			if ($genesis->{COMANS} > 0) {	# (jinak by to smazalo všechno!!!)
					$genesis -> COM ("sel_delete");
			}
$genesis -> COM ("adv_filter_reset");
$genesis -> COM ("reset_filter_criteria",filter_name=>"",criteria=>"all");
$genesis -> COM ("affected_layer",name=>"",mode=>"all",affected=>"no");
#$genesis -> COM ("top_tab",tab=>"Checklists");