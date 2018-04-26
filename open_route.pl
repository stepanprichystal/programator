#!/usr/bin/perl
use Genesis;
my $genesis = new Genesis;
my $jobName = "$ENV{JOB}";

$genesis->COM('get_work_layer');
my $workLayer = "$genesis->{COMANS}";

$genesis -> COM ('chain_list_reset');
$genesis -> COM ('chain_set_plunge',layer=>"$workLayer",type=>'open',mode=>"straight",inl_mode=>"straight",start_of_chain=>"yes",apply_to=>"all",len1=>"0",len2=>"0",len3=>"0",len4=>"0",val1=>"0",val2=>"0",ang1=>"0",ang2=>"0",ifeed=>"0",ofeed=>"0");

