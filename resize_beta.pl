#!/usr/bin/perl
use strict;
use warnings;
use Genesis; 

my $genesis = new Genesis;
my $jobName = ("$ENV{JOB}");
my $decko;
my @stepy;
my @potrebne_stepy = qw (o+1);

############################# c v2 v3 v4 v5 s mc ms 
my @layers = qw( pc mc c s ms ps);      ##
my $resize = 2;            ##
#############################

$genesis->INFO('entity_type'=>'job','entity_path'=>"$jobName",'data_type'=>'STEPS_LIST');
@stepy = @{$genesis->{doinfo}{gSTEPS_LIST}};

foreach (@stepy)
    {
        if (/(^[a-z]\d{5})/)
        {
            #print "$_\n";
            push(@potrebne_stepy, "$_");
        }            
    }
print "@potrebne_stepy\n";
print "@layers\n";
foreach (@potrebne_stepy)
    {
        $genesis -> COM ("open_entity",job=>"$jobName",type=>"step",name=>"$_",iconic=>"no");        
        $genesis -> AUX ('set_group', group => $genesis->{COMANS});#dulezity radek pro posilani scriptu do konkretniho editoru
               
        foreach (@layers)
            {
                  $genesis -> COM ("display_layer",name=>"$_",display=>"yes",number=>"1");
                  $genesis -> COM ("work_layer",name=>"$_");
                  $genesis -> COM ("sel_resize",size=>"$resize",corner_ctl=>"no");
                  $genesis -> COM ("display_layer",name=>"$_",display=>"no",number=>"1");                                 
            }                           
     $genesis -> COM ("editor_page_close");                
    }  
      