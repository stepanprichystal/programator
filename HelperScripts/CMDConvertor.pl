#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;



# ============ INPUT LINE =================
my $inputLine =
"COM open_job,job=f13610,open_win=yes
AUX set_group,group=99
COM show_component,component=Action_Area,show=no,width=0,height=0
COM set_subsystem,name=1-Up-Edit
COM set_step,name=o+1
COM open_group,job=f13610,step=o+1,is_sym=no
AUX set_group,group=0
COM open_entity,job=f13610,type=step,name=o+1,iconic=no
COM snap_mode,mode=off
COM top_tab,tab=Display
COM top_tab,tab=1-Up Parameters Page
COM check_inout,job=f13610,mode=out,ent_type=job
COM set_subsystem,name=Nc-Manager
COM set_step,name=panel
COM open_group,job=f13610,step=panel,is_sym=no
AUX set_group,group=1
COM open_entity,job=f13610,type=step,name=panel,iconic=no
COM snap_mode,mode=off
COM top_tab,tab=Display
COM nc_set_current,job=f13610,step=panel,layer=,ncset=
COM units,type=mm
COM ncset_units,units=mm
COM info,out_file=/tmp/info.8488,write_mode=replace,units=mm,args= -t matrix -e f13610/matrix -d ROW
COM disp_on
COM origin_on
COM nc_create,ncset=ncset.2,device=machine_b,lyrs=m,thickness=0
COM disp_on
COM origin_on
COM disp_on
COM origin_on
COM nc_set_advanced_params,layer=m,ncset=ncset.2,parameters=(iol_sm_g84_radius=no)
COM nc_set_current,job=f13610,step=panel,layer=m,ncset=ncset.2
COM units,type=mm
COM ncset_units,units=mm
COM info,out_file=/tmp/info.12880,write_mode=replace,units=mm,args= -t matrix -e f13610/matrix -d ROW
COM info,out_file=/tmp/info.12880,write_mode=replace,units=mm,args= -t step -e f13610/panel -d PROF_LIMITS, units=mm
COM info,out_file=/tmp/info.12880,write_mode=replace,units=mm,args= -t matrix -e f13610/matrix -d ROW -p drl_dir+name
COM nc_register,angle=0,xoff=0,yoff=0,version=1,xorigin=153.5,yorigin=4,xscale=1,yscale=1,xscale_o=0,yscale_o=0,xmirror=no,ymirror=no
COM disp_on
COM origin_on
COM nc_cre_output,layer=m,ncset=ncset.2
COM disp_on
COM origin_on
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units = inch,args= -t matrix -e f13610/matrix -d ROW    
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t job -e f13610 -d ATTR -p name+val   
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t step -e f13610/panel -d PROF_LIMITS    
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t layer -e f13610/panel/c -d FEATURES   -o feat_index+f0 
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t layer -e f13610/panel/v2 -d FEATURES   -o feat_index+f0 
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t layer -e f13610/panel/v1 -d FEATURES   -o feat_index+f0 
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units = inch,args= -t matrix -e f13610/matrix -d ROW    
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t matrix -e f13610/matrix -d ROW -p drl_end+drl_start+name+drl_dir   
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units = inch,args= -t matrix -e f13610/matrix -d ROW    
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t matrix -e f13610/matrix -d ROW -p drl_end+drl_start+name+drl_dir   
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t layer -e f13610/panel/m -d TOOL   -o break_sr 
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units= mm,args= -t layer -e f13610/panel/m -d TOOL   -o break_sr 
COM get_user_name
COM info,out_file=z://tmp/info_csh.8080,write_mode=replace,units = inch,args= -t layer -e f13610/panel/c -d ATTR    
COM disp_on
COM origin_on
COM info,out_file=z://tmp/info_csh.10604,write_mode=replace,units= mm,args= -t matrix -e f13610/matrix -d ROW -p layer_type+name   
COM info,out_file=z://tmp/info_csh.10604,write_mode=replace,units= mm,args= -t ncset -e f13610/panel/m/ncset.2     
COM disp_on
COM origin_on
COM top_tab,tab=Script
COM top_tab,tab=Tools - Table
COM top_tab,tab=NC Parameters Page
COM show_tab,tab=Script,show=yes
COM top_tab,tab=Script
";
# ============ INPUT LINE =================


my $output = "\$inCAM->COM(";
my @splitted = split( ",", $inputLine );

my $section = shift(@splitted);
$section =~ s/COM\s*//;

$output .= "\"" . $section . "\",";

my @params = ();

foreach my $p (@splitted) {
	$p =~ s/=/\" => \"/;
	$p =~ s/;/\\;/;

	$p = "\"" . $p . "\"";

	push( @params, $p );

}

my $par = join( ",", @params );
$output .= $par . ");";

print $output;


