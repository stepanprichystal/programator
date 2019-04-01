#!/usr/bin/perl-w
# skript na precislovani frezovani
###############################################

use Tk;
use Tk::LabFrame;
use Tk::BrowseEntry;
use Genesis;

use LoadLibrary;

#local library
use Enums;
use FileHelper;
use GeneralHelper;
use DrillHelper;
use StackupHelper;
use MessageForm;
use SimpleInputForm;
use RoutHelper;


unless ($ENV{JOB}) {
	$jobName = shift;
} else {
	$jobName = "$ENV{JOB}";

}		

$genesis = new Genesis;





my @data = ();
@frezaPole = qw (fsch); 

		$mainPool = MainWindow->new();
		$mainPool->title('zmena chain cisel');


	$midleFrame = $mainPool ->Frame(-width=>100, -height=>20)->pack(-side=>'top',-fill=>'x');
	$midleFrame->Label(-text=>'Start chain number')->pack(-padx => 0, -pady => 0,-side=>left);	
    	$entry_lab = $midleFrame->Entry(-width=>3,-font=>"normal 10 bold")->pack(-padx => 0, -pady => 0,-side=>left);
			$entry = $midleFrame->Entry(-width=>40,-font=>"normal 10 bold")->pack(-padx => 5, -pady => 5,-side=>left);
				$entryLayer = 'fsch';
				$entry_layer = $midleFrame->BrowseEntry(-label=>'Layer',-variable => \$entryLayer,-listcmd=>\&fill_list)->pack(-side=>left);

			$button=$midleFrame->Button(-width=>30,-text => "OK",-font=>'normal 9 bold',-activebackground=>'lightblue',-command=> \&change)->pack(-padx => 5, -pady => 5,-side=>left);
			$button2=$midleFrame->Button(-width=>15,-text => "PAUSE",-command=> sub {$genesis->PAUSE('Pause'); $genesis->COM('units',type=>'mm')})->pack(-padx => 5, -pady => 5,-side=>left);
			$button2=$midleFrame->Button(-width=>15,-text => "ViewChain",-command=> sub {_viewChain()})->pack(-padx => 5, -pady => 5,-side=>left);
			
$infoFrame = $mainPool ->Frame(-width=>100, -height=>20,-bg=>'lightblue')->pack(-side=>'bottom',-fill=>'x');
$statusLabel = sprintf "Zadej jednotlive chain,oddelene carkou,ktere maji byt zmeneny";
		$status = $infoFrame ->Label(-textvariable=>\$statusLabel,-bg=>'lightblue',-font=>'normal 9 {bold }')->pack(-side=>'top');
		
#$mainPool->waitWindow;


#print @newSortPole;




sub fill_list {
	$entry_layer->delete(0,'end'); 
	foreach $fr (@frezaPole) {
    		$entry_layer->insert("end", $fr);
 	}
}
sub change {
		$valueCopy = $entry -> get;
		$newChain = $entry_lab -> get;
		$valueCopy =~ s/\s//g;
	    @poleCopy = split/,/,"$valueCopy";

$genesis -> COM ('zoom_home');
my @pulPole = ();
my $oldLayer;
my $newLayer;
	foreach my $oneChange (@poleCopy) {
				if ($oneChange =~ /\d+/) {
						$genesis -> COM ('chain_change_num',layer=>"$entryLayer",chain=>"$oneChange",new_chain=>"$newChain",renumber_sequentially=>'no');
						
						push (@pulPole, $newChain);
						$newChain ++;
				}
	}

		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/chain_num",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    				$genesis->COM('delete_layer',layer=>"chain_num");
		}
		
		
		
		
		#$genesis->('set_subsystem',name=>'Rout'); 
		#$genesis->('show_tab',tab=>'Rout Parameters Page',show=>'yes');

exit;
}

sub _viewChain {
	my %hashNum = ();
	
	

		$genesis->COM('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'fsch',type=>'rout');
		$genesis->COM('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'fsch',context=>'board');
		
			$genesis->COM ('zoom_home');
		my $infoFile = $genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/panel/fsch",'data_type'=>'FEATURES',parse=>'no');
		open (INFOFILE,$infoFile);
		while(<INFOFILE>) {
			my $chain_num;
			if ($_ =~ /\.foot_down/) {
					
						@rozdelPole = split /\s/, $_;
						foreach my $item1 (@rozdelPole) {
								if($item1 =~ /rout_chain=(\d{1,4})/) {
									 $chain_num = $1;
								}
						}
						# $rozdelPole[1] = p1x
						# $rozdelPole[2] = p1y
						# $rozdelPole[3] = p2x
						# $rozdelPole[4] = p2y
						
						$pNumX = $rozdelPole[1] + 2;
						$pNumY = ((($rozdelPole[4] - $rozdelPole[2]) / 2) + $rozdelPole[2]);
						
						$hashNum{$chain_num} = [$pNumX, $pNumY];
						#open (REPORT,">>c:/Export/test");
						#print REPORT "aa $chain_num $pNumX, $pNumY\n";
						#close REPORT;
						push @data, { name => "$chain_num",coord => { x => $pNumX, y=> $pNumY }};


			}
		}
		close INFOFILE;
		unlink $infoFile;
		
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/chain_num",data_type=>'exists');
		if ($genesis->{doinfo}{gEXISTS} eq "no") {
				$genesis->COM ('create_layer',layer=>'chain_num',context=>'misc',type=>'document',polarity=>'positive',ins_layer=>'');
		}
		#$genesis->COM ('clear_layers');
		$genesis->COM ('filter_reset',filter_name=>'popup');
		$genesis->COM ('affected_layer',name=>'',mode=>'all',affected=>'no');
		$genesis->COM ('display_layer',name=>'chain_num',display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>'chain_num');
		
		foreach my $numKey (keys %hashNum) {
				my $myNulaX = $hashNum{$numKey}->[0];
				my $myNulaY = $hashNum{$numKey}->[1];
				$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaX",y=>"$myNulaY",text=>"$numKey",x_size=>'6',y_size=>'6',w_factor=>'0.656167984',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
		}

		$genesis->COM ('zoom_home');
		
	
	
	my @sortedCh = RouteHelper->SortChains(\@data, 10);
	
	my @removedElements = grep !/s/, @sortedCh;
	my @sortField = sort ({$b<=>$a} @removedElements);
	my $numberHigh = shift @sortField;
	$numberHigh++;
	
	
	$sortLine = join(',', @sortedCh);
	$genesis->PAUSE("Zkontroluj");
	return($entry->insert('0',"$sortLine"), $entry_lab->insert('0',"$numberHigh"));
	
}
#MainLoop;
$mainPool->waitWindow;