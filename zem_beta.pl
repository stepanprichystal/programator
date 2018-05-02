#!/usr/bin/perl
use strict;
use warnings;
use Genesis;
use Tk;

my $jobName = "$ENV{JOB}";
my $stepName = "$ENV{STEP}";
my $genesis = new Genesis;
my @novepole=();
my @chk=();
my @check=();
my $pocitadlo=0;
my $pocitadlo_global = 0;

&info_vrstvy;
  
&druhe_okno;
         
&copy_nova_vrstva;

#####################################################################################
sub info_vrstvy {
    $genesis ->INFO(      units => 'mm',
                    entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');

    my @ROWsignal = @{$genesis->{doinfo}{gROWlayer_type}};
    my @ROWboard = @{$genesis->{doinfo}{gROWcontext}};
    my @ROWname = @{$genesis->{doinfo}{gROWname}};        
            
    $pocitadlo=0;          
    foreach (@ROWsignal){
           
    if (($ROWsignal[$pocitadlo] eq "signal") and ($ROWboard[$pocitadlo] eq "board")){
        push (@novepole,"$ROWname[$pocitadlo]");       
        }
            
    ++$pocitadlo;       
    }       
}
#####################################################################################
sub druhe_okno{ 

    my $mw = MainWindow->new;
    #$mw->geometry("300x150");
    $mw->title("Srafovana zem");
    
    my $check_frame = $mw->Frame()->pack(-side => "top");
    $check_frame->Label(-text=>"Oznac vrstvy ktere maji srafovanou zem",
                        -font=>'normal 13 {bold }')->pack(-side => "top")->pack();
    
    my $pocitadlo = 0;
    
    foreach (@novepole) {
        $chk[$pocitadlo] = $check_frame->Checkbutton(-text => "$novepole[$pocitadlo]",
                                                 -variable => \$check[$pocitadlo],
                                                  -onvalue => "1",
                                                 -offvalue => "0",
                                                      -font=>'normal 13 {bold }')->pack();                                     
        ++$pocitadlo;
    }
   

    my $button_frame = $mw->Frame()->pack(-side => "bottom");
    my $ok_button = $button_frame->Button(-text => 'OK',
                                       -command => \&copy_nova_vrstva,
                                           -font=>'normal 13 {bold }')->pack(-side => "left");
    my $exit_button = $button_frame->Button(-text => 'Exit',
                                         -command => sub{exit},
                                             -font=>'normal 13 {bold }')->pack(-side => "right");                                        
    }
    MainLoop;                                                                        
#####################################################################################
sub copy_nova_vrstva {
    $pocitadlo = 0;
    $pocitadlo_global=0;
        foreach (@novepole){
        
            if ($check[$pocitadlo] eq 1){
                
                $genesis -> COM ('clear_layers');                                     # odznaci vsechny zobrazene i afectovane!!!
                $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");  #
                
                              
                $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"yes");
                $genesis -> COM ("sel_copy_other",dest=>"layer_name",target_layer=>"$novepole[$pocitadlo_global]_zem_carama",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
                $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"no");    
                                                                            
                $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]_zem_carama",mode=>"single",affected=>"yes");  # oznaceni vytvorene vrstvy                                                           
                $genesis -> COM ("sel_contourize",accuracy=>"0",break_to_islands=>"yes",clean_hole_size=>"0",clean_hole_mode=>"x_and_y"); # contrurize
                
                $genesis -> COM ("sel_break_isl_hole",islands_layer=>"$novepole[$pocitadlo_global]_isl_lyr",holes_layer=>"$novepole[$pocitadlo_global]_hole_lyr");  # Break to islands
                
                $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]_zem_carama",mode=>"single",affected=>"no");  # odznaceni vytvorene vrstvy
                 
                $genesis -> COM ("display_layer",name=>"$novepole[$pocitadlo_global]_hole_lyr",display=>"yes",number=>"1");
                
                $genesis -> PAUSE ('Oznac pres Bounding Box ');                               
                 
                $genesis -> COM ("sel_move_other",target_layer=>"$novepole[$pocitadlo_global]",invert=>"no",dx=>"0",dy=>"0",size=>"33",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none"); # kopirovani oznaceneho pres bouning 
                
                $genesis -> COM ("display_layer",name=>"$novepole[$pocitadlo_global]_hole_lyr",display=>"no",number=>"1");                                                                          
            }
        ++$pocitadlo;
        ++$pocitadlo_global;
        }
        
    
        

    } 
