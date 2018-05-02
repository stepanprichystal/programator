#!/usr/bin/perl
use strict;
use warnings;
use Genesis;
use Tk; 
use File::Copy;
use File::Basename;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

my $genesis = new Genesis;
my $jobName = "$ENV{JOB}";
#my $stepName ="$ENV{STEP}";

my $count;
my @matrix_pole;
my @stepSeznam;
my @output = qw (Gerber PDF ET);
my $select_output;
my %hash_layers;
my $select_steps;
my $cestaZdroje = 'c:/Export';
my $localBoards = 'c:/Boards';
my $filelog = 'c:/Export/log.txt';
my $archivePath = 'r:/Archiv';
my @text;
my @files;
my $zazipovat=0;                 
my $mw = MainWindow->new;

info_name();
info_steps();
tk();

sub info_name{
    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = @{$genesis->{doinfo}{gROWname}};
    
      for ($count=0;$count<$totalRows;$count++) {
    
            if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {  	
            my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
            push (@matrix_pole,$rowName);	
            }		
    }
}

sub info_steps{
    $genesis->INFO('entity_type'=>'job','entity_path'=>"$jobName",'data_type'=>'STEPS_LIST');
     @stepSeznam = @{$genesis->{doinfo}{gSTEPS_LIST}};
}

sub tk {		 

#$mw->geometry("300x300");
$mw->title("Export_beta");
my $frame1 = $mw->Frame()->grid(
		-row        => 0,
		-column     => 0,
	);      
my $frame2 = $mw->Frame()->grid(
		-row        => 0,
		-column     => 1,
	);      
my $frame3 = $mw->Frame()->grid(
		-row        => 0,
		-column     => 2,
	);
my $frame4 = $mw->Frame()->grid(
		-row        => 0,
		-column     => 3
          	); 
my $frame5 = $mw->Frame()->grid(
		-row        => 0,
		-column     => 4
          	);              	

  foreach (@output) {
        my $chk1 = $frame1->Radiobutton(-text => $_,
                                             -variable => \$select_output,                                      
                                             -value => $_,                                                                                                                   
                                             )->pack(-side => 'top' );
       }  
    foreach (@stepSeznam) {

        my $chk2 = $frame2->Radiobutton(-text => $_,
                                             -variable => \$select_steps,                                      
                                             -value => $_,                                                                       
                                             )->pack(-side => 'top' );                                                
    }     
    foreach (@matrix_pole) {
        my $chk3 = $frame3->Checkbutton(-text => $_,
                                             -variable => \$hash_layers{$_},
                                             -onvalue => 1,
                                             -offvalue => 0
                                            )->pack(-side => 'top' );                                                                                                                                                                    
    }
    foreach (%hash_layers){    
    $hash_layers{$_}=0;    
    }
my $chk4 = $frame4->Checkbutton(-text => "Zazipovat",
                                             -variable => \$zazipovat,
                                             -onvalue => 1,
                                             -offvalue => 0
                                            )->pack(-side => 'top' );                            
                    
my $ok_button = $frame5->Button(-text => 'OK',
                                      -command => \&export)->pack(-side => 'left' );

my $exit_button = $frame5->Button(-text => 'Exit',
                                     
                                      -command => sub{exit})->pack(-side => 'left' );
 MainLoop;                                     
}

sub export_gerber {
#  print "Key: $_ and Value: $hash_layers{$_}\n" foreach (keys%hash_layers);
#     foreach (@matrix_pole){
# 
#         print "$_ : $hash_layers{$_}\n";   
#         push (@text,"$_ : $hash_layers{$_}\n");            
#     }
# 
# $mw->messageBox(-message => "Vysledek: \n\n@text\n$select_steps\n$select_output", -type => "ok");
print "Key: $_ and Value: $hash_layers{$_}\n" foreach (keys %hash_layers);	  
    foreach (keys %hash_layers){
    
        if ($hash_layers{$_} eq "1"){        
        $genesis -> COM ('output_layer_reset');	
        $genesis -> COM ('output_layer_set',layer=>$_,angle=>'0',mirror=>"no",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
        $genesis -> COM ('output',job=>"$jobName",step=>$select_steps,format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>".ger",break_sr=>'yes',break_symbols=>'yes',break_arc=>'yes',scale_mode=>'all',surface_mode=>'fill',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
        $genesis -> COM ('disp_on');
        $genesis -> COM ('origin_on');
         
        push (@files,"$jobName$_.ger");  
        }
        
                
                       
    }   
    if($zazipovat == 1){
    zip();
    }
exit;    
}
sub export_pdf {

#  foreach (@matrix_pole){
# 
#         print "$_ : $hash_layers{$_}\n";   
#         push (@text,"$_ : $hash_layers{$_}\n");            
#     }
# 
# $mw->messageBox(-message => "Vysledek: \n\n@text\n$select_steps\n$select_output", -type => "ok");

foreach (keys %hash_layers){
      if ($hash_layers{$_} == 1){
      $genesis->COM ("open_entity",job=>"$jobName",type=>"step",name=>"$select_steps",iconic=>"no");
      $genesis->COM ("print_show");
      $genesis->COM ("print",title=>'',layer_name=>"$_",mirrored_layers=>'',
      draw_profile=>"yes",drawing_per_layer=>"yes",label_layers=>"no",dest=>"pdf_file",
      num_copies=>"1",dest_fname=>"$cestaZdroje/$jobName$_.pdf",paper_size=>"A4",
      scale_to=>"0",nx=>"1",ny=>"1",orient=>"none",paper_orient=>"portrait",paper_width=>"0",
      paper_height=>"0",auto_tray=>"no",top_margin=>"12.7",bottom_margin=>"12.7",left_margin=>"12.7",
      right_margin=>"12.7",x_spacing=>"0",y_spacing=>"0",color1=>"990000",color2=>"9900",color3=>"99",
      color4=>"990099",color5=>"999900",color6=>"9999",color7=>"0");
      $genesis->COM ("editor_page_close");
} 
}
}

sub et{
$genesis -> COM ('output_layer_reset');
$genesis -> COM ('output',job=>"$jobName",step=>"$select_steps",format=>'IPC-D-356A',dir_path=>"$cestaZdroje",prefix=>"${jobName}t",suffix=>'.ipc',x_anchor=>'0',y_anchor=>'0',netlist_type=>'Current',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',finished_drills=>'no',ipcd_units=>'mm',adjacency=>'yes',trace=>'yes',tooling=>'yes',shrink2gasket=>'yes',panel_img=>'yes',sr_info=>'yes',rotate_net=>'0',mirror_net=>'no',sub_panel=>""); 
	rename("$cestaZdroje/${jobName}tcurnet.ipcd.ipc","$cestaZdroje/${jobName}t.ipc");
						unless (-e "$localBoards/$jobName") {
	  						mkdir("$localBoards/${jobName}t");
	  							move("$cestaZdroje/${jobName}t.ipc","$localBoards/${jobName}t");
            }
}

sub export{
    if ($select_output eq "Gerber"){
    export_gerber();
    }
    if ($select_output eq "PDF"){
    export_pdf();
    }
    if ($select_output eq "ET"){
    et();
    }
}

sub zip{
my $jobFolder = substr($jobName, 0,3);
my $jobFolder_velke = uc($jobFolder);
my $jobName_velke = uc($jobName);
my $cestaArchiv  = "$archivePath/$jobFolder_velke/$jobName_velke/Zdroje";
my $newZipFilename = "$cestaZdroje/${jobName}_data_paste.zip";
	
my $zip = Archive::Zip->new(); 
foreach (@files)
 {
    $zip->addFile("$cestaZdroje/$_", basename("$cestaZdroje/$_"));   
 }

$zip->writeToFileNamed($newZipFilename);

#   r:/Archiv/F02/F00253/Zdroje/
    foreach (@files) {
    unlink "$cestaZdroje/$_";
    }	
move("$cestaZdroje/${jobName}_data_paste.zip","$cestaArchiv");

}						                                        

