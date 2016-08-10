#!/usr/bin/perl-w


use Genesis;
my $genesis = new Genesis;


#loading of locale modules
use LoadLibrary;


use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Archive::Zip;
use File::Find;
use Tk;

#local library
use Enums;
use FileHelper;
use GeneralHelper;
use DrillHelper;
use StackupHelper;
use MessageForm;
use SimpleInputForm;
use DefaultStackupScript;
use GenesisHelper;
use Gatmain;
use sqlNoris;

use lib qw(//incam/incam_server/site_data/scripts);
use aliased 'Packages::Drilling::FinishSizeHoles::SetHolesRun';

use warnings;

my $localPath = 'c:/pcb';
my $importPath;


##### GUI ###############################################################################
my $pathDisk = 'r:/pcb';
my $inputWindow = MainWindow->new;
$inputWindow->minsize(qw(350 20));
$inputWindow -> title('Input');

my $idFrm = $inputWindow->Frame()->grid(-column=>0,-row=>0,-sticky=>"news",-columnspan=>1);

my $tgzBttn = $idFrm->Button(-text => "Open *.tgz|*.zip ...",-font=>'normal 9 {bold }', -command => sub {MultiCustomer('open')});
$tgzBttn->grid(-column=>0,-row=>1,-sticky=>"news",-columnspan=>2,-ipady=>10,-pady=>10 );

$idFrm->Radiobutton(-value=>'c:/pcb', -variable=>\$pathDisk, -text=>"c:/pcb")->grid(-column=>3,-row=>1,-sticky=>"news",-columnspan=>1);
$idFrm->Radiobutton(-value=>'r:/pcb', -variable=>\$pathDisk, -text=>"r:/pcb")->grid(-column=>4,-row=>1,-sticky=>"news",-columnspan=>1);


my $exitBttn = $inputWindow->Button(-text => "Konec", -command =>sub{exit})->grid(-column=>0,-row=>1,-sticky=>"news",-columnspan=>4,-pady=>5 );

$inputWindow->waitWindow;

#############################################################################################

sub MultiCustomer {
	my $operat = shift;
	my $path;
    		my @types =
      			(["zip,odb++",           [qw/*.zip *.tgz/]],
       			["All files",		'*']
      		);
    			if ($operat eq 'open') {
						$path = $inputWindow->getOpenFile(-filetypes => \@types,-initialdir =>"$pathDisk");
    			}


unless (-e $path) {
		my @mess = ("Chybí importní soubor!");
		new MessageForm( Enums::MessageType->INFORMATION, \@mess, undef );
		exit;
}

#$genesis -> PAUSE("ZKONTROLUJ $path");
my @fields = split /\//,$path;

my $diskName = uc $fields[0];
my @fieldJobName = grep /[FfDd]\d{5}/, @fields;
my $jobName = lc $fieldJobName[0];


pop @fields;
if ($path =~ /\.tgz$/) {
		unless ($diskName eq 'C:') {
				dirmove (join('/', @fields),$localPath . '/' . $jobName);
				$importPath = $path;
		}else{
				#$genesis -> PAUSE("ZKONTROLUJ $path");
				$importPath = $path;
		}
}else{
		my @listFiles = ();
		my $zip = Archive::Zip ->new("$path");
		my @fileInZip = $zip->memberNames;
				foreach $fileZip (@fileInZip) {
						$zip->extractMember($fileZip,join('/', @fields) . '/'. $fileZip);
				}
		dirmove (join('/', @fields),$localPath . '/' . $jobName);
		
		find({wanted => sub {push @listFiles, $File::Find::name},no_chdir => 1}, $localPath . '/' . $jobName);

		my @tgzArr = grep /\.tgz$/, @listFiles;

		# check how many tgz file found out
		unless (scalar @tgzArr == 1) {
					my @mess = ("Nemuzu najít správný tgz file, zkontroluj, jestli existuje, pak import opakuj.");
					new MessageForm( Enums::MessageType->INFORMATION, \@mess, undef );
					exit;
		}else{
				$importPath = $tgzArr[0];
		}
}

#print $importPath;


	# Check if jobName already exist;
	$genesis -> INFO(entity_type=>'job',entity_path=>"$jobName",data_type=>'exists');
    if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				my @btns = ("SMAZAT JOB a pokracovat v importu", "KONEC"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
				my @m =	("Jmeno jobu $jobName jiz existuje!");
				
				new MessageForm( Enums::MessageType->WARNING, \@m, \@btns, \$result);
				if ($result == 1) {
					exit;
				}else{
						my @arrBTNS = ("ANO", "NE"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
						my @arrM =	("Opravdu smazat job $jobName ?");
				
						new MessageForm( Enums::MessageType->WARNING, \@arrM, \@arrBTNS, \$resultDelete);
						if ($resultDelete == 1) {
									exit;
						}else{
									$genesis -> COM ('delete_entity',job=>"$jobName",type=>'job',name=>"$jobName");
						}
				}
	}
				
 			my $reference = getValueNoris($jobName, 'reference_zakazky');
 			my $hostName = $ENV{HOST};
 			OnlineWrite_order( $reference, "zpracovava $hostName" , "aktualni_krok" );
 		
 			$genesis -> COM ('import_job',db=>'incam',path=>"$importPath",name=>"$jobName",analyze_surfaces=>'no');
 			$genesis -> COM ('clipb_open_job',job=>"$jobName",update_clipboard=>'view_job');
 			
 			$genesis -> INFO(entity_type => 'job',entity_path => "$jobName",data_type => 'STEPS_LIST');
 			my @stepsArr = @{$genesis->{doinfo}{gSTEPS_LIST}};
 			my $inputStep = $stepsArr[0];	
 			
 			$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$inputStep",iconic=>'no');
 			$genesis -> AUX ('set_group',group => $genesis->{COMANS});
 			
 			#Move all pcb to zero point
 			_MoveToZeroPoint($jobName, $inputStep);
 			
 			# Here run script for rename according to Gatema's names layers
 			$genesis -> COM('script_run',name=>"//incam/incam_server/site_data/scripts/renameLayerScript.pl",dirmode=>'global',params=>"$jobName");
 			
 			# Here run script for set value of drill diameter
 			$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/vv",dirmode=>'global',params=>"$jobName");   


 			#$genesis -> COM('show_component',component=>'CAM_Guide',show=>'yes',width=>0,height=>0);
 			#$genesis -> COM('set_current_guide',guide=>'Multi_pcb');
 			
 			# Here run script for set value of drill diameter
 			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/f",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
 						$genesis -> COM('display_layer',name=>'f',display=>'yes',number=>'1');
		    			$genesis -> COM('work_layer',name=>'f');
		    			
 						$genesis -> PAUSE("TED UDELEJ FREZU $jobName - tlacitko F4");
 						$genesis -> COM('display_layer',name=>'f',display=>'no',number=>'1');
 						
 				}
 			
 			my $stepName = 'o+1';
 			$genesis -> COM('script_run',name=>"//incam/incam_server/site_data/scripts/kontrola.pl",dirmode=>'global',params=>"$jobName $stepName");
 			
 			
 			# Here run clean-up
 			$genesis -> COM('chklist_from_lib',chklist=>'Clean_up',profile=>'none',customer=>'');
 			$genesis -> COM('chklist_open',chklist=>'Clean_up');
 			$genesis -> COM('chklist_show',chklist=>'Clean_up',nact=>'1',pinned=>'no',pinned_enabled=>'yes');
 			$genesis -> COM('chklist_run',chklist=>'Clean_up',nact=>'a',area=>'profile',async_run=>'no');
 			
 			$genesis -> PAUSE('ZKONTROLUJ CLEAN-UP');
 			$genesis -> COM('chklist_close',chklist=>'Clean_up',mode=>'hide');
 			
 			# Here run Checks
 			$genesis -> COM('chklist_from_lib',chklist=>'Checks',profile=>'none',customer=>'');
 			$genesis -> COM('chklist_open',chklist=>'Checks');
 			$genesis -> COM('chklist_show',chklist=>'Checks',nact=>'1',pinned=>'no',pinned_enabled=>'yes');
 			#$genesis -> COM('chklist_run',chklist=>'Checks',nact=>'a',area=>'profile',async_run=>'no');
 			
 			$genesis -> PAUSE('PROVED CHECK-list');
 			$genesis -> COM('chklist_close',chklist=>'Checks',mode=>'hide');
 			
 			# Here run F3 panelise.pl
 			$genesis -> COM ('save_job',job=>"$jobName",override=>'no',skip_upgrade=>'no');
 			$genesis -> COM ('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/Panelise.pl",dirmode=>'global',params=>"$jobName");
 			$genesis -> PAUSE("Po kliknuti ulozim a zavru $jobName");
 			
 			$genesis -> COM ('save_job',job=>"$jobName",override=>'no',skip_upgrade=>'no');
			$genesis -> COM ('editor_page_close');
			$genesis ->	COM ('close_job',job=>"$jobName");
			$genesis ->	COM ('close_form',job=>"$jobName");
			$genesis ->	COM ('close_flow',job=>"$jobName");
			
			
			$genesis ->	COM ('show_tab',tab=>'CAM Database Manager',show=>'yes');
			$genesis ->	COM ('top_tab',tab=>'CAM Database Manager');
			$genesis ->	COM ('cdbm_copy_jobs',jobs=>"$jobName",jobs_app=>'incam',target_app=>'genesis',target_db=>'genesis',async_run=>'yes');
 			
 			exit;
}
	
	
	


sub _MoveToZeroPoint {
		my $jobName = shift;
		my $stepName = shift;
		my $tmpLayer = 'o';
		$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'DATUM');
			my $datumPointX = sprintf "%3.3f",($genesis->{doinfo}{gDATUMx});
			my $datumPointY = sprintf "%3.3f",($genesis->{doinfo}{gDATUMy});


		$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'PROF_LIMITS');
			my $zeroPointX = sprintf "%3.3f",($genesis->{doinfo}{gPROF_LIMITSxmin} * (-1));
			my $zeroPointY = sprintf "%3.3f",($genesis->{doinfo}{gPROF_LIMITSymin} * (-1));


		if ($zeroPointX != 0 or $zeroPointY != 0) {
	   			$genesis->COM ('profile_to_rout',layer=>"$tmpLayer",width=>'300');
	   			
	   			$genesis->COM('affected_layer',mode=>'all',affected=>'yes');
	   			$genesis->COM('sel_move',dx=>"$zeroPointX",dy=>"$zeroPointY");
	   			$genesis->COM('affected_layer',mode=>'all',affected=>'no');
	   			
	   			$genesis->COM('filter_reset',filter_name=>'popup');
	   			$genesis->COM ('clear_layers');
	   			
	   			
	   			$genesis->COM('display_layer',name=>"$tmpLayer",display=>'yes',number=>'1');
		    	$genesis->COM('work_layer',name=>"$tmpLayer");
	   			$genesis->COM('filter_area_strt');
	   			$genesis->COM('filter_area_end',layer=>"$tmpLayer",filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
	   			$genesis->COM('sel_create_profile');
	   			$genesis->COM('filter_reset',filter_name=>'popup');
	   			$genesis->COM('datum', x=>'0', y=>'0');
	   			$genesis->COM('display_layer',name=>"$tmpLayer",display=>'no',number=>'1');
	   			$genesis->COM('delete_layer',layer=>"$tmpLayer");
	   			$genesis->COM('zoom_home');
	   	}else{
	   			if ($datumPointX != 0 or $datumPointY != 0) {
	   					$genesis->COM('datum', x=>'0', y=>'0');
	   					$genesis->COM('zoom_home');
	   			}
		}
}