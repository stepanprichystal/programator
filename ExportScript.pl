#!/usr/bin/perl-w
#################################################################################################################################
#Sript name: Export.pl
#Verze     : 2.00 Nova struktura scriptu
#Use       : Export Gerber...
#Made      : RV
#logText
#################################################################################################################################
use LoadLibrary;


use Genesis;
use Tk;
use XML::Simple;
use Data::Dumper;
use Tk::LabFrame;
use File::Copy 'cp';
use Win32::OLE;
use Win32::OLE::Variant; 
use untilityScript;
#use MLDBM qw(DB_File Storable);
use File::Path qw( rmtree );
use POSIX qw(mktime);
use Time::localtime;
use Time::gmtime;
use sqlNoris;
#use Tk::StayOnTop;




#local library
use Enums;
use FileHelper;
use GeneralHelper;
use DrillHelper;
use MessageForm;
use SimpleInputForm;
use DrillCutScript;
use SimpleControlsHelper;
use GenesisHelper;
use Gatmain;
use DefaultStackupScript;

use StackupHelper;
use StackupLayerHelper;

use CheckHelper;



#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;


use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsProducPanel';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::AOIExport::AOIExportTmp';

use aliased 'Packages::CAMJob::Stackup::StackupDefault';



my $jobName = "$ENV{JOB}";
my $StepName = "$ENV{STEP}";
my $panelStepName = 'panel';
my $genesis = new Genesis;
$stepPdf = 'o+1';
$hostName = $ENV{HOST};
$sendTOplotter = 'no';
$cestaUser = "A";
$archivePath = "r:/Archiv";
#$Potisk = 'Negativ';
my $jobNAME = uc $jobName;
$ipcStep = 'panel';
my $draw_film = 'small';
@flat_freza = qw(f_sch f_lm);
$currentRoute = 'f';
my $etStep = 'et';
my $dekonConture = 0;
my $caraDisplay = '*' x 160;
my @rout_layers = qw (f_schmoll f_sm3000 r fk fs fr rs f_sch f_lm fcl_c fcl_s ppo_c ppo_s win_c win_s fz_c fz_s rz_c rz_s);
my $switchMain = 0;
my $tenting = 0;
my $MultiDrill = 0;
my $cuChange = 0;
my $exportNightElTest;
my $doCompen = 1;
my $jump = 0;
my ($cesta_drill, $cestaZdroje); 
my $frez_film = 0;
my $poolServis = 0;
my $nasobnost = 0;
my $nas_mpanel = 0;
my $splitDrill = 0;
my $result_repeat_tools = 0;
my $stavHotovo = 1;
my $button_tenting_exist = 0;
my $panelCustomer = 0;
my $pressfit = 0;
my $bga = 0;
my $checkViewRout = 0;
my %dtCode = ();
my $nifNegenerovat = 0;


	
$genesis->COM ('filter_reset',filter_name=>'popup');

my $padEnlarge = 999999;
my $linEnlarge = 999999;

my $cesta_nif = getPath($jobName);

$genesis -> COM ('clear_layers');


open (AREA,"$cesta_nif/$jobName.nif");
            while (<AREA>) {
            	if ($_ =~ /tenting=A/) {
                            $tenting = 1;
                }
                if ($_ =~ /kons_trida=(\d)/) {
                            $constClass = $1;
                }
                if ($_ =~ /nasobnost_panelu=(\d{0,4})/) {
                            $nas_mpanel = $1;
                }
                if ($_ =~ /nasobnost=(\d{0,4})/) {
                            $nasobnost = $1;
                }
                if ($_ =~ /poznamka=(.*)/) {
                            $poznamka = $1;
                }
                if ($_ =~ /rel\(22305,L\)\=2814075/) {
                            $maska01 = 1;
                }
                if ($_ =~ /merit_presfitt=A/) {
                            $pressfit = 1;
                }
                if ($_ =~ /datacode=(.*)/) {
                			my $tmpDatacode = $1;
                			my @tmpDataArr = split /,/,$tmpDatacode;
                			
                			foreach my $item (@tmpDataArr) {
										$dtCode{$item}=1;
							}
                }
                if ($_ =~ /ul_logo=(.*)/) {
                			my $tmpUl = $1;
                			my @tmpDataArr = split /,/,$tmpUl;
                			
                			foreach my $item (@tmpDataArr) {
										$ul{$item}=1;
							}
                }
                
            }
close AREA;



unless ($poznamka) {
		$poznamka .= 'Zpracovano v InCAMu.';
}


			# Here is set PCB class for historical pcb
			my $tmpClass = getInfoAttr ("$jobName", "job", "pcb_class");
			unless ($tmpClass) {
					# Set attribut construction class
 					CamJob->SetJobAttribute($genesis, 'pcb_class', $constClass, $jobName);
			}


    	
   			# Here is made stackup for pcb
			if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
						unless (_CheckExistStackup($jobName) == 1) {
									_MakeStackup();
						}else{
								my @btns = ("ok"); # "ok" = tl. cislo 1
								my @m =	("Slozeni je jiz vytvoreno, NEGENERUJI");

								new MessageForm( Enums::MessageType->WARNING, \@m, \@btns, \$result);
						}
			} 	


# Here check if is it possible use tenting
#----------------------------------------------------
my $stateTenting = _StatusTentingUseability($jobName);



# Helper for jump mark
#---------------------------------
if (-e "$cesta_nif/$jobName.pool") {
			$jump = 1;
			
}

# Check all file for el test done
#---------------------------------
my $info_ettest;
my $cestaBoards = 'c:/Boards';
{
	opendir ( DIRGERBER, $cestaBoards);
		while( (my $jobItem = readdir(DIRGERBER))){
				if ($jobItem =~ /[DdFf]\d{5,}/) {
						unless (-e "c:/Boards/$jobItem/server.ini") {
								$info_ettest = 'UDELEJ ELEKTRICKE TESTY V C:/Boards';
								last;
						}
				}
		}
	closedir DIRGERBER;	
}

# Check and change if layer fsch is type board and rout
# --------------------------------------------------
_CheckAndChangeFsch($jobName);



##################################
# delete ff layer
#--------------------------
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/ff",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    				$genesis->COM ('delete_layer',layer=>'ff');
		}
# get infromation from NORIS
#----------------------------
my $mnozstvi = getValueNoris($jobName, 'pocet');
my $customer = getValueNoris($jobName, 'customer');	
my $material = getValueNoris($jobName, 'material');	
my $surface = getValueNoris($jobName, 'surface_finishing');	
my $newThickness = getValueNoris($jobName, 'material_tloustka');
my $newThicknessCopper = getValueNoris($jobName, 'material_tloustka_medi');
my $povrchovaUprava = getValueNoris($jobName, 'surface_finishing');
my $reference = getValueNoris($jobName, 'reference_zakazky');
my $termin = getValueNoris($jobName, 'termin');
my $VVthickness = getValueNoris ($jobName,'tloustka'); #tloustka medi pro multilayer v zalozce vicevrstve
my $panelThickness = $newThickness;

#my $DPSclass = getInfoAttr ("$jobName/panel", "step", ".pnl_class");

get_current_difference($termin); # informace o rozdilu terminu a aktualniho data

	
	 if ($panelThickness eq '' and $VVthickness eq '') {
			$mainThick = MainWindow->new();
			$mainThick->title('Dopln tloustku materialu v um.');
			$mainThick->minsize(qw(350 20));
			$thickness = $mainThick->Entry(-width=>7,-font=>"normal 10 bold",-fg=>brown)->pack(-padx => 5, -pady => 5,-side=>left);
			$button=$mainThick->Button(-width=>40,-text => "OK",-command=> \&prepocetThickness)->pack(-padx => 5, -pady => 5,-side=>left);
			MainLoop();
	}
	sub prepocetThickness {
			$panelThickness = $thickness->get;
			$panelThickness = $panelThickness / 1000;
			$mainThick->destroy;
	}
	if ($panelThickness eq '') {
			$panelThickness = $VVthickness;
	}
	
		if (($mnozstvi == 0) or ($nasobnost == 0)) {
			$textInfo = 'Polarizace nenastavena automaticky';
			$barvaPisma='red';
			$Potisk = 'Negativ';
		}else{
			$barvaPisma='black';
		    $pocetPrirezu = ($mnozstvi / $nasobnost);
		    $textInfo = "Polarizace nastavena";
				# hodnota pro vykresleni potisku!
				if ($pocetPrirezu >= 50) {
					$Potisk = 'Positiv';
				}else{
					$Potisk = 'Negativ';
				}
		}
		
# Zakaznici co nechteji info v PDF
#----------------------------------
$genesis->VOF;
	my $infoTechnic = customerWithoutInfo ($customer);


	my $cuThick = HegMethods->GetOuterCuThick ($jobName);	
	(my $DpsMultilayer, my $DPSFrezovana, my $DPSScore, my $typLayerSingle) = getInfoAboutPCB();
			
	adjustGUI();
	get_minVrtak();
	&slepeOtvoryPrepocet;
	my $predkoveni = predkoveni();

			$statusLabel = sprintf "Vyber parametry a Exportuj";
			$fgStatus = 'black';



			my $valueReduction = 0;
  			if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
  					my $pathToXML = _GetXMLfile($jobName);
					my %cuThickHash = _GetCuThick($pathToXML);
					my $constrClass = CamAttributes->GetJobAttrByName($genesis, $jobName, 'pcb_class');
					
							$valueReduction = GenesisHelper::kompezace($cuThickHash{'c'}, $constrClass);
							
			}else{
					   $cuThick = HegMethods->GetOuterCuThick($jobName);
					my $constrClass = CamAttributes->GetJobAttrByName($genesis, $jobName, 'pcb_class');
					
							$valueReduction = GenesisHelper::kompezace($cuThick, $constrClass);
			}
    	
if ($genesis->{STATUS} != 0) {
	$infoStatus = 1;
	$genesis->PAUSE ('CHYBA1 - najdi chybu v cerne obrazovce Genesisu');
	exit;
}
$genesis->VON;
	#$genesis->PAUSE("$valueEnlargePAT, $FLASH, $PATTERN, $valueEnlargeTEN, ten $TENTING");
	if ($valueReduction eq "NP"){
			$colorEnlarge = 'red';
	}else{
			$colorEnlarge = 'black';
	}

		
# Zjisteni flatenove frezy 
#---------------------------
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		foreach $layer_route(@flat_freza) {
    			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/$layer_route",data_type=>'exists');
    				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    					#	$currentRoute = "$layer_route";
    						push (@flatroute,$layer_route);
    				}
    		}
    	}
    	

    	
######################################
# GUI - START
######################################
my $main = MainWindow->new;
$main->title('Macro Exportu');

	
	$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/mpanel",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$stateMpanel = 'normal';
				}else{
					$stateMpanel = 'disable';
				}
	$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/o+1",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$stateo1 = 'normal';
				}else{
					$stateo1 = 'disable';
				}

	$frame0 = $main ->Frame(-width=>100, -height=>20,-bg=>'lightblue')->pack(-side=>'bottom',-fill=>'x');
		if ($jobName eq "") {
				$statusLabel = sprintf "NEPOKRACUJ, NEMAS OTEVRENY ZADNY JOB";
				$status = $frame0 ->Label(-textvariable=>\$statusLabel,-fg=>"red",-bg=>'lightblue',-font=>'normal 9 {bold }')->pack(-side=>'top');
		} else {
				
				$status = $frame0 ->Label(-textvariable=>\$statusLabel,-fg=>"$fgStatus",-bg=>'lightblue',-font=>'normal 9 {bold }')->pack(-side=>'top');
				
					if(-e "$cesta_nif/${jobName}.pool") {
							$poolServis = 1;
							my $fsch;
							my $flm;
									$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/fsch",data_type=>'exists');
											if ($genesis->{doinfo}{gEXISTS} eq "no") {
												 $fsch = 0;
												 push(@nameFflat,'fsch');
											}else{
												 $fsch = 1;
											}
											
								if($fsch == 0){
										$statusLabel = "Nepokracuj,deska je v POOLu a ty nemas vrstvu @nameFflat, dodelat.";
										$status->configure(-fg=>'red');
								}
					}
					# kontroluji pocet patek ve vrstve F_SCH
					check_foot();
		}

# MANIFRAME
my $mainFrame = $main->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'top',-fill=>'both');



my $frameTop = $mainFrame->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'top',-fill=>'both');
			$frame1 = $frameTop->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'top',-fill=>'x');
			$frame1->Label(-text => "Data Export",-font=>"Arial 16 bold")->pack(-side=>'top');
			if ($info_ettest) {
						$frame1->Label(-text => "$info_ettest",-font=>"Arial 10 bold",-fg=>'red')->pack(-side=>'top');
			}
			$podframe1 = $frameTop->Frame(-width=>10, -height=>20)->pack(-side=>'top');
			$podframe1->Radiobutton(-value=>"E", -variable=>\$cestaUser, -text=>"c:/Export",-font=>"Arial 8 bold underline")->pack(-padx => 0, -pady => 0,-side=>'left');
			$podframe1->Radiobutton(-value=>"A", -variable=>\$cestaUser, -text=>"r:/Archiv",-font=>"Arial 8 bold underline")->pack(-padx => 0, -pady => 0,-side=>'left');
			$podframe2 = $frameTop->Frame(-width=>10, -height=>20)->pack(-side=>'top');
			if ($doCompen == 1) {
						$labelKompenz = $podframe2->Label(-text=>"Filmova kompenzace pro $cuThick um med bude ",-font=>"Arial 8 bold")->pack(-padx => 0, -pady => 0,-side=>'left');
						$enlarge_buttom = $podframe2->Entry(-width=>4,-state=>'normal',-textvariable=>"$valueReduction",-fg=>"$colorEnlarge")->pack(-padx => 5, -pady => 5,-side=>'left');
						$podframe2->Label(-text=>"um",-font=>"Arial 8 bold")->pack(-padx => 0, -pady => 0,-side=>'left');
			}else{
						$podframe2->Label(-text=>"Filmova kompenzace pro $cuThick um med bude ",-font=>"Arial 8 bold",-fg=>"red")->pack(-padx => 0, -pady => 0,-side=>'left');
						$enlarge_buttom = $podframe2->Entry(-width=>4,-state=>'normal',-textvariable=>"$valueReduction")->pack(-padx => 5, -pady => 5,-side=>'left');
						$podframe2->Label(-text=>"um (nejlepe s technology)",-font=>"Arial 8 bold",-fg=>"red")->pack(-padx => 0, -pady => 0,-side=>'left');
			}
			$frameTop->Label(-text =>"$caraDisplay")->pack(-side=>'top');
#			$frame2 = $frameTop->Frame(-width=>10, -height=>20)->pack(-side=>'left');
#			$frame2->Label(-text => "$jobName",-font=>"Arial 8 bold")->pack(-side=>'top');
#			$frame2->Label(-text => "$StepName",-font=>"Arial 8 bold")->pack(-side=>'top');
#			$frame2->Label(-text => "@flatroute",-font=>"Arial 8 bold")->pack(-side=>'top');
#			$frame2->Label(-text => "$surface",-font=>"Arial 8 bold")->pack(-side=>'top');
my $frameBot = $mainFrame->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'bottom',-fill=>'both');
my $middleframe = $frameBot->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'left',-fill=>'both');
			my $middleframeTop = $middleframe->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'top',-fill=>'both');
						
						#
						# FOTOZPRACOVANI
						
						$leftFrameFoto = $middleframeTop->Frame(
											-width=>50, 
											-height=>50)
											->pack(
											-side=>'left',
											-fill=>'y');
								$labFrameFoto = $leftFrameFoto->LabFrame(
																-width=>50,
																-height=>50,
																-label=>"Fotozpracovani - export",
																-font=>'normal 9 {bold }')
																->pack(
																-side=>'top',
																-fill=>'y',
																-expand => "True");
										$gerberFrame = $labFrameFoto->Frame(
																-width=>50, 
																-height=>50)
																->pack(
																-side=>'top',
																-fill=>'x');
													$button_gerber = $gerberFrame->Checkbutton(
																								-variable=>\$Gerber,
																								-text=>"Gerber274X")
																								->pack(-padx => 10, -pady => 5,-side=>'left');
										$plotrFrame = $labFrameFoto->Frame(
																	-width=>50, 
																	-height=>50)
																	->pack(
																	-side=>'top',
																	-fill=>'x');
													$button_plot = $plotrFrame->Checkbutton(
																							-variable=>\$plotr,
																							-text=>"Data pro Plotr")
																		  					->pack(-padx => 10, -pady => 5,-side=>'left');
			
			
			
						#
						# VRTANI
						$pomocnyframe22 = $middleframeTop->Frame(
											-width=>50, 
										    -height=>50)
										    ->pack(-side=>'left', -fill=>'y');	
								$frame4 = $pomocnyframe22->LabFrame(
															-width=>50,
															-height=>20,
															-label=>"NC - export",
															-font=>'normal 9 {bold }')
															->pack(
															-side=>'top',
															-fill=>'y',
															-expand => "True");
				
											$podFrameDrill = $frame4->Frame(
																	-width=>50, 
																	-height=>50)
																	->pack(
																	-side=>'top');
																$button_drill = $podFrameDrill->Checkbutton(
													  													-variable=>\$Drill, 
													  													-text=>"Vrtani a frezovani",)
													  													->pack(
													  													-padx => 5,
													  													-pady => 5,
													  													-side=>'top');
						#
						# DRAZKOVANI
													if ($DPSScore == 1) {
														&check_exist_kolecko;    #drive se pouzivalo kolecko ted uz je to ctverec
														$podFrameScore = $frame4->LabFrame(
																					-width=>50, 
																					-height=>50,
																					-label=>"Drazkovani")
																					->pack(
																					-side=>'top');
																			$button_score = $podFrameScore->Checkbutton(
																											  			-variable=>\$Score, 
																											  			-text=>"Score")
																											  			->pack(
																											  			-padx => 5, 
																											  			-pady => 5,
																											  			-side=>'top');
																						
																						$pomocnyFrameScoreTop = $podFrameScore->Frame(
																																	-width=>50, 
																																	-height=>50)
																																	->pack(
																																	-side=>'top',
																																	-fill=>'x');
																						$pomocnyFrameScoreBot = $podFrameScore->Frame(-width=>50, -height=>50)->pack(-side=>'top',-fill=>'x');
																						$pomocnyFrameScoreBotFiduc = $podFrameScore->Frame(-width=>50, -height=>50)->pack(-side=>'top',-fill=>'x');
																						$pomocnyFrameScoreBotFiducKC = $podFrameScore->Frame(-width=>50, -height=>50)->pack(-side=>'top',-fill=>'x');
																						$pomocnyFrameScoreJum = $podFrameScore->Frame(-width=>50, -height=>50)->pack(-side=>'top',-fill=>'x');
																						
																						if ($DpsMultilayer == 1) {
																										$textScore = 'Dopln tl. desky';
																										$statusScore = 'normal';
																										$colorScore = 'red';
																						}else{
																										$textScore = 'Tl.desky';
																										$statusScore = 'normal';# RVI disable
																										$colorScore = 'black';
																						}			
																						$pomocnyFrameScoreTop->Label(
																													-text=>"$textScore",
																													-font=>"Arial 8 bold",
																													-fg=>"$colorScore")
																													->pack(
																													-padx => 0, 
																													-pady => 0,
																													-side=>'left');
																						$enlarge_buttom_score = $pomocnyFrameScoreTop->Entry(
																																			-width=>4,
																																			-state=>"$statusScore",
																																			-textvariable=>"$panelThickness")
																																			->pack(
																																			-padx => 5, 
																																			-pady => 2,
																																			-side=>'left');
																												$pomocnyFrameScoreTop->Label(
																																			-text=>"mm",
																																			-font=>"Arial 8 bold")
																																			->pack(
																																			-padx => 0, 
																																			-pady => 0,
																																			-side=>'left');
			    								 					
			    								 					
																												$pomocnyFrameScoreBot->Label(
																																			-text=>'      Core',
																																			-font=>"Arial 8 bold",
																																			-fg=>"black")
																																			->pack(
																																			-padx => 1, 
																																			-pady => 0,
																																			-side=>'left');
																							$enlarge_buttom_core = $pomocnyFrameScoreBot->Entry(
																																				-width=>4,
																																				-state=>'normal',
																																				-textvariable=>"0.30")
																																				->pack(
																																				-padx => 5, 
																																				-pady => 2,
																																				-side=>'left');
																													$pomocnyFrameScoreBot->Label(
																																				-text=>"mm",
																																				-font=>"Arial 8 bold")
																																				->pack(
																																				-padx => 0, 
																																				-pady => 0,
																																				-side=>'left');
																		
																													$pomocnyFrameScoreBotFiduc->Label(
																																				-text=>'Posuv',
																																				-font=>"Arial 8 bold underline",
																																				-fg=>"black")
																																				->pack(
																																				-padx => 0, 
																																				-pady => 0);
																		
																													$pomocnyFrameScoreBotFiducKC->Radiobutton(
																																				-value=>"oneDirection", 
																																				-variable=>\$typScore, 
																																				-text=>"1 Smer")
																																				->pack(
																																				-padx => 0, 
																																				-pady => 0,
																																				-side=>'left');
																													$pomocnyFrameScoreBotFiducKC->Radiobutton(
																																				-value=>"klasik", 
																																				-variable=>\$typScore,
																																				-text=>"Klasik")
																																				->pack(
																																				-padx => 0, 
																																				-pady => 0,
																																				-side=>'left');
			 																										$pomocnyFrameScoreJum->Checkbutton(
			 																																	-variable=>\$jump, 
			 																																	-text=>"Jump-scoring",
			 																																	-fg=>'red')
			 																																	->pack(
			 																																	-padx => 5, 
			 																																	-pady => 5,
			 																																	-side=>'top');
													}
			
						#
						# TESTOVANI
						$pomocnyframe2 = $middleframeTop->Frame(
														-width=>100, 
														-height=>100)
														->pack(
														-side=>'left',
														-fill=>'y');
												$frame5 = $pomocnyframe2->LabFrame(
																					-width=>100,
																					-height=>100,
																					-label=>"Testovani",
																					-font=>'normal 9 {bold }')
																					->pack(
																					-side=>'top',
																					-fill=>'y',
																					-expand => "True");
																					
																		$pod1frame5 = $frame5->LabFrame(
																										-width=>100, 
																										-height=>50,
																										-label=>"El.Test")
																										->pack(
																										-side=>'top',
																										-fill=>'y',
																										-expand => "True");
																										
																							$pod2frame5 = $pod1frame5->Frame(
																															-width=>100, 
																															-height=>50)
																															->pack(
																															-side=>'top');
																											$button_ipc = $pod2frame5->Checkbutton(
																																					-variable=>\$Ipc, 
																																					-text=>"IPC        ")
																																					->pack(
																																					-padx => 0, 
																																					-pady => 0,
																																					-side=>'top');
																														  $pod2frame5->Label(
																														  							-text=>"---------------------------------------")
																														  							->pack(
																														  							-padx => 0, 
																														  							-pady => 0,
																														  							-side=>'top');
																														  							
																							$pod6frame5 = $pod1frame5->Frame(
																															-width=>10, 
																															-height=>2)
																															->pack(
																															-side=>'bottom',
																															-fill=>'x');
																											$pod4frame5 = $pod1frame5->Frame(
																																			-width=>10,
																																			-height=>2)
																																			->pack(
																																			-side=>'bottom',
																																			-fill=>'x');
																																			
																																		$pod4frame5->Radiobutton(
																																								-value=>"panel", 
																																								-variable=>\$ipcStep,
																																								-text=>"panel")
																																								->pack(
																																								-padx => 0, 
																																								-pady => 0,
																																								-side=>'left');
																																		$pod4frame5->Radiobutton(
																																								-value=>"mpanel", 
																																								-variable=>\$ipcStep,
																																								-text=>"mpanel",
																																								-state=>"$stateMpanel")
																																								->pack(
																																								-padx =>3, 
																																								-pady => 0,
																																								-side=>'right');
			
																						$pod6frame5 = $frame5->LabFrame(
																															-width=>50, 
																															-height=>50,
																															-label=>"Optický test  ")
																															->pack(
																															-side=>'top',
																															-fill=>'both',
																															-expand => "True");
																															
																												$button_aoi = $pod6frame5->Checkbutton(
																																						-variable=>\$Optika, 
																																						-text=>"AOI        ")
																																						->pack(
																																						-padx => 5, 
																																						-pady => 5,
																																						-side=>'bottom');
						#
						# PDF 
						$pomocnyframe40 = $middleframeTop->Frame(
															-width=>100,
															-height=>100)
															->pack(
															-side=>'left',
															-fill=>'both');
																
												$frame6 = $pomocnyframe40->LabFrame(
																					-width=>10, 
																					-height=>50,
																					-label=>"Pdf",
																					-font=>'normal 9 {bold }')
																					->pack(
																					-side=>'top',
																					-fill=>'y',
																					-expand => "True");
																					
																			$frame6->Checkbutton(
																									-variable=>\$Pdf, 
																									-text=>"Pdf")
																									->pack(
																									-padx => 5, 
																									-pady => 5,
																									-side=>'top');
																			$frame6->Checkbutton(
																									-variable=>\$infoTechnic, 
																									-text=>"info v PDF",
																									-font=>'normal 6 {bold }')
																									->pack(
																									-padx => 5, 
																									-pady => 5,
																									-side=>'bottom');
			
			  									$pomocnyframePDF = $frame6->Frame(-width=>100, -height=>100)->pack(-side=>'top',-fill=>'x',-fill=>'y');	
			  									$pomocnyframePDF2 = $pomocnyframePDF->Frame(-width=>10, -height=>10)->pack(-side=>'top',-fill=>'x');	
			  									$pomocnyframePDF3 = $pomocnyframePDF->Frame(-width=>10, -height=>10)->pack(-side=>'top',-fill=>'x');	
			  									$pomocnyframePDF4 = $pomocnyframePDF->Frame(-width=>10, -height=>10)->pack(-side=>'top',-fill=>'x');	
			  								
			  									
			  								
			  								
			  									$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/o+1",data_type=>'exists');
			  												if ($genesis->{doinfo}{gEXISTS} eq "yes") {
			  													$stateOa1 = 'normal';
			  												}else{
			  													$stateOa1 = 'disable';
			  												}
			  								
			  									$pomocnyframePDF2->Radiobutton(-value=>"panel", -variable=>\$stepPdf, -text=>"panel")->pack(-padx => 0, -pady => 0,-side=>'left');	
			  									$pomocnyframePDF3->Radiobutton(-value=>"mpanel", -variable=>\$stepPdf, -text=>"mpanel",-state=>"$stateMpanel")->pack(-padx => 0, -pady => 0,-side=>'left');		
			  									$pomocnyframePDF4->Radiobutton(-value=>"o+1", -variable=>\$stepPdf, -text=>"o+1",-state=>"$stateOa1")->pack(-padx => 0, -pady => 0,-side=>'left');
			
			
			
						my $middleframeBot2 = $middleframe->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'bottom',-fill=>'both');
						my $middleframeBot1 = $middleframe->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'bottom',-fill=>'both');
						
						###
						### HERE is place for attributes
							my %datacode = ();
							my %ullogo = ();
							my $markFrame = $middleframeBot1->Frame(
												-width=>50, 
												-height=>50)
												->pack(
												-side=>'left',
												-fill=>'both');
									#
									# DATACODE
									my $datacodeFrame = $markFrame->LabFrame(
															-width=>10, 
															-height=>50,
															-label=>"DATACODE",
															-font=>'normal 9 {bold }')
															->pack(
															-side=>'top',
															-fill=>'y',
															-expand => "True");
						
									 				my $d = 1;
									 				foreach my $item ('PC','MC', 'C','S','MS','PS') {
									 				$datacodeFrame->Checkbutton(
									 										-text => "$item ",
									 										-variable=>\$dtCode{$item},
									 										-fg=>'white',
									 										-bg=>'grey',
									 										-selectcolor=>'red',
									 											-indicatoron=>'')
									 										->grid(-column=>"$d",
									 										-row=>5,
									 										-sticky=>"news",
									 										-columnspan=>1);
									 				$d++;
									 				}
									#
									# ULLOGO 
									my $ullogoFrame = $markFrame->LabFrame(
																		-width=>10, 
																		-height=>50,
																		-label=>"ULLOGO",
																		-font=>'normal 9 {bold }')
																		->pack(
																		-side=>'top',
																		-fill=>'y',
																		-expand => "True");
									
													my $u = 1;
													foreach my $item ('PC','MC', 'C','S','MS','PS') {
															$ullogoFrame->Checkbutton(
																						-text => "$item ",
																						-variable=>\$ul{$item},
																						-fg=>'white',
																						-bg=>'grey',
																						-selectcolor=>'red',
																						-indicatoron=>'')
																						->grid(-column=>"$u",
																						-row=>5,
																						-sticky=>"news",
																						-columnspan=>1);
																$u++;
													}
						#
						# POZNAMKY
						my $noteFrame = $middleframeBot1->Frame(
												-width=>100, 
												-height=>50)
												->pack(
												-side=>'left',
												-fill=>'both',
												-expand => "True");
								
									my $noteLabFrame = $noteFrame->LabFrame(
															-width=>100, 
															-height=>50,
															-label=>"POZNAMKY",
															-font=>'normal 9 {bold }')
															->pack(
															-side=>'top',
															-fill=>'both',
															-expand => "True");
															
												$w = $noteLabFrame->Frame()->pack(-side=>'top', -fill=>'both', -expand=>'true');
												$yscroll = $w->Scrollbar(-orient=>'vertical');
												$xscroll = $w->Scrollbar(-orient=>'horizontal');
												$txt = $w->Text(-width=>15,-height=>5,-borderwidth=>2,-relief=>'raised', -wrap=>'none', -yscrollcommand=>['set', $yscroll],-xscrollcommand=>['set',$xscroll]);
												$yscroll->configure(-command=>['yview', $txt]); 
												$xscroll->configure(-command=>['xview', $txt]); 
												$txt->grid(-column=>0,-row=>0,-sticky=>'news');
												$yscroll->grid(-column=>1,-row=>0,-sticky=>'news');
												$xscroll->grid(-column=>0,-row=>1,-sticky=>'news');
												$w->gridColumnconfigure(0, -weight=>1);
												$w->gridRowconfigure(0, -weight=>1);	
												
												$txt->insert('end',"$poznamka");								
																					
															
															
															
															
															
															
															
															
															
															
															
															
						# ATRIBUTY
						#
						# MASKA 0.1
						my $attrFrame = $middleframeBot1->Frame(
												-width=>50, 
												-height=>50)
												->pack(
												-side=>'right',
												-fill=>'both',
												-expand => "True");
									my $attrLabFrame = $attrFrame->LabFrame(
															-width=>50, 
															-height=>50,
															-label=>"ATRIBUTY",
															-font=>'normal 9 {bold }')
															->pack(
															-side=>'top',
															-fill=>'both',
															-expand => "True");
												$attrLabFrame->Checkbutton(
																		-text => "MASKA 0.1 ",
																		-variable=>\$maska01,
																		-fg=>'white',
																		-bg=>'grey',
																		-selectcolor=>'red',
																		-indicatoron=>'')
																		->pack(
																		-side=>'top',
																		-fill=>'both',
																		-padx=>3,
																		-pady=>1
																		);
												$attrLabFrame->Checkbutton(
																		-text => "BGA",
																		-variable=>\$bga,
																		-fg=>'white',
																		-bg=>'grey',
																		-selectcolor=>'red',
																		-indicatoron=>'')
																		->pack(
																		-side=>'top',
																		-fill=>'both',
																		-padx=>3,
																		-pady=>1
																		);
											   $attrLabFrame->Checkbutton(
																		-text => "PRESSFIT",
																		-variable=>\$pressfit,
																		-fg=>'white',
																		-bg=>'grey',
																		-selectcolor=>'red',
																		-indicatoron=>'')
																		->pack(
																		-side=>'top',
																		-fill=>'both',
																		-padx=>3,
																		-pady=>1
																		);
												$attrLabFrame->Checkbutton(
																		-text => "ZKOUSKA FREZOVANI",
																		-variable=>\$checkViewRout,
																		-fg=>'white',
																		-bg=>'grey',
																		-selectcolor=>'red',
																		-indicatoron=>'')
																		->pack(
																		-side=>'top',
																		-fill=>'both',
																		-padx=>3,
																		-pady=>1
																		);
									
						#my $middleframeBot2 = $middleframe->Frame(-width=>100, -height=>80)->pack(-expand => "yes",-side=>'bottom',-fill=>'both');
									my $errorFrame = $middleframeBot2->Frame(
																			-width=>50, 
																			-height=>50)
																			->pack(
																			-side=>'right',
																			-fill=>'both',
																			-expand => "True");
												my $attrLabFrame = $errorFrame->LabFrame(
													  					-width=>50, 
													  					-height=>50,
													  					-label=>"Zjistene chyby",
													  					-font=>'normal 9 {bold }')
													  					->pack(
													  					-side=>'top',
													  					-fill=>'both',
													  					-expand => "True");
													  					
													  					
												my @tmpPole = CheckHelper->CheckAbilityKompenzation($genesis, $jobName); 					
												my %errorMessageArr = @tmpPole;
											my $rowStart=0;
											$tmpFrameInfo = $attrLabFrame->Frame(-width=>100, -height=>10)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
											foreach my $item (keys %errorMessageArr) {
																	$tmpFrameInfo ->Label(-textvariable=>\$item, -fg=>"red")->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"w");
																	$rowStart++;
														
														push (@notExport,$errorMessageArr{$item});
											}
												  					
													  					
													  					
													  					
						#
						# TLACITKA			
						my $buttomFrame = $frameBot->Frame(
															-width=>100, 
															-height=>80)
															->pack(
															-expand => "yes",
															-side=>'right',
															-fill=>'both');
													
													my $buttomFrameKonec = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>50)
																					->pack(
																					-side=>'bottom',
																					-fill=>'x');
													
																			$buttomFrameKonec->Button(-text => "Konec",-width=>'15',-height=>'1',-command=> \&exite)->pack(-padx => 10, -pady => 5,-side=>'left');
													
													my $buttomFrameExport = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>50)
																					->pack(
																					-side=>'bottom',
																					-fill=>'x');

																				my $stavExportButtom = 'normal';
																				my @removedElements = grep /NOTexport/, @notExport;
																				if (scalar @removedElements > 0) {
																						$stavExportButtom = 'disable';
																				}
																				
																			$buttomFrameExport->Button(-state=>"$stavExportButtom" ,-text => "Export",-width=>'15',-height=>'1',-command=> \&Export_test)->pack(-padx => 10, -pady => 5,-side=>'left');
													
													
													my $buttomFrameTenting = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>20)
																					->pack(
																					-side=>'bottom',
																					-fill=>'x');


																			unless($typLayerSingle == 1) {
																									$button_tenting_exist = 1;
																									$button_tenting = $buttomFrameTenting->Checkbutton(-variable=>\$tenting, -text=>"Tenting Technology",-state=>"$stateTenting")->pack(-padx => 5, -pady => 5,-side=>'left');
																			}
													
													
													unless (HegMethods->GetPcbIsPool($jobName) == 1) {
																my $buttomFrameCustomer = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>50)
																					->pack(
																					-expand => "yes",
																					-side=>'bottom',
																					-fill=>'x');

												 									$buttomFrameCustomer->Checkbutton(-variable=>\$panelCustomer, -text=>"Panel zakaznika")->pack(-padx => 5, -pady => 5,-side=>'left');
													}

													my $buttomFrameHotovo = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>50)
																					->pack(
																					-expand => "yes",
																					-side=>'bottom',
																					-fill=>'x');
													$buttomFrameHotovo->Checkbutton(-variable=>\$stavHotovo, -text=>"Hotovo-zadat", -fg=>'red')->pack(-padx => 5, -pady => 5,-side=>'left');
													
													
													my $buttomFrameNIF = $buttomFrame->Frame(
																					-width=>50, 
																					-height=>50)
																					->pack(
																					-expand => "yes",
																					-side=>'bottom',
																					-fill=>'x');
													$buttomFrameNIF->Checkbutton(-variable=>\$nifNegenerovat, -text=>"NIF negenerovat", -fg=>'black')->pack(-padx => 5, -pady => 5,-side=>'left');
													
													
													
													
													$buttomFrame->Label(-text => "$jobName",-font=>"Arial 10 bold")->pack(-padx => 10, -pady => 5,-side=>'top');
													
													$tl_ko=$buttomFrame->Button(-text => "Export Kooperace",-width=>'15',-height=>'1',-command=> \&export_kooperace);
													$tl_ko->pack(-padx => 10, -pady => 5,-side=>'top');
													
													$tl_ko=$buttomFrame->Button(-text => "Netlist control",-width=>'15',-height=>'1',-command=> \&netlist_run);
													$tl_ko->pack(-padx => 10, -pady => 5,-side=>'top');
													
													$tl_ko=$buttomFrame->Button(-text => "Cdr delete error",-width=>'15',-height=>'1',-command=> \&cdr_remove);
													$tl_ko->pack(-padx => 10, -pady => 5,-side=>'top');
													
													
													
													$buttomFrame->Button(-text => "Fill all",-width=>'15',-height=>'1',-command=> \&fillAll)->pack(-padx => 10, -pady => 5,-side=>'top');
													
													$switchMain = 1;
						
$main->waitWindow; 
exit (0);




sub fillAll {
	$plotr = 1;$Gerber = 1;$Drill = 1; $Ipc = 1; $Optika = 1;
	$button_plot->configure(-variable=>\$plotr);
	$button_gerber->configure(-variable=>\$Gerber);
	$button_drill->configure(-variable=>\$Drill);
	
	$button_ipc->configure(-variable=>\$Ipc);
	$ipcStep = "panel";
	$pod4frame5->update;

	$button_aoi->configure(-variable=>\$Optika);
	
	if (GenesisHelper->LayerExists($genesis,$jobName, 'panel', 'score') == 1) {
			$Score = 1;
			$button_score->configure(-variable=>\$Score);
	}
	unless ($stateTenting eq 'disable') {
			$tenting = 1;
			$button_tenting->configure(-variable=>\$tenting);
	}
}









sub Export_test {
	$enlarge_test = $enlarge_buttom->get;
	
	if ($enlarge_test == 0) {
			$statusLabel = sprintf "Nemas doplneny kompenzace, nejprve dopln, pak exportuj.";
			$status->configure(-fg=>"red");
			$status->update;
	}else{
		
		&Export;
		
		log_file ("$jobName - Export finished\n");
		unless ($result_repeat_tools == 1) {
						$statusLabel = sprintf "...Hotovo...";#logText
						$status->update;
						if ($poolServis == 1) {
										if ($stavHotovo == 1) {
												my $res = OnlineWrite_order( $reference, 'A', 'pooling');
												 		  OnlineWrite_order( $reference, "HOTOVO-zadat" , "aktualni_krok" );
										}else{
												my $res = OnlineWrite_order( $reference, 'A', 'pooling');
												 		  OnlineWrite_order( $reference, "Exportovano" , "aktualni_krok" );
										}
						}else{
								if (sqlNoris::getValueNoris($jobName, 'pooling') eq 'A') {
										if ($stavHotovo == 1) {
												my $res = OnlineWrite_order( $reference, 'N', 'pooling');
														  OnlineWrite_order( $reference, "HOTOVO-zadat" , "aktualni_krok" );
										}else{
														  OnlineWrite_order( $reference, "Exportovano" , "aktualni_krok" );
										}
								}else{
										if ($stavHotovo == 1) {
												OnlineWrite_order( $reference, "HOTOVO-zadat" , "aktualni_krok" );
										}else{
												OnlineWrite_order( $reference, "Exportovano" , "aktualni_krok" );
										}
								}
						}
				
		}else{
			$statusLabel = sprintf "HOTOVO, ale POZOR! Freza nema setridene nastroje - UPRAVIT!";
			$status->configure(-fg=>"red");
			
								  		my @btns = ("HOTOVO-zadat", "Exportovano"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
								  		my @m =	("Jaky stav pro zakazku nastavit? Jestli budes nesetridene nastroje opravovat dej Exportovano, v opacnem pripade Hotovo-zadat.");
								  		
								  		new MessageForm( Enums::MessageType->WARNING, \@m, \@btns, \$result);
								  		if ($result == 1) {
								  				OnlineWrite_order( $reference, "Exportovano" , "aktualni_krok" );
								  		}else{
								  				OnlineWrite_order( $reference, "HOTOVO-zadat" , "aktualni_krok");
									  	}
		}
		if($infoStatus) {
			OnlineWrite_order( $reference, "Exportovano" , "aktualni_krok" );
		}
	}
}

sub Export {
	log_file ("$jobName - Export started; Tenting = $tenting"); #log
		
		
		
		if (-e "$cesta_nif/$jobName.pool") {
				_SetMaskSilkHelios($jobName);
		}
		# Here run archiv data files.
		#_ArchivInputFiles($jobName);
			
			$genesis->VOF;
			
			$status->configure(-fg=>"black");
			$status->update;

			$genesis->COM ('set_step',name=>'panel');

	
	
	unless ($tenting == 1) {
				if ($layerCount > 2) {
						$scheme = 'pattern-vv';
				}elsif ($layerCount == 2) {
						$scheme = 'pattern-2v';
				}
				
				$genesis->COM ('autopan_run_scheme',job=>"$jobName",panel=>EnumsProducPanel->PANEL_NAME,pcb=>'o+1',scheme=>"$scheme");
				
				# Change aligmentmark to positive/negative
				_ChangePolarityFeatures($jobName);
				
	}else{
				my $paternFrameExist = _DeletePatternFrame($jobName);
				
				if($paternFrameExist){
						# Change aligmentmark to positive/negative
						_ChangePolarityFeatures($jobName);
				}
	}
	
	
	
	
	
	
	
	
	
	$valueReduction = $enlarge_buttom->get; # toto je nejake divne?
			$statusLabel = sprintf "Vyber parametry a Exportuj";
			$status->configure(-fg=>"black");
			$status->update;
			
		if ($cestaUser eq "A") {	
				$cesta_drill  = getPath($jobName);
				$cestaZdroje = "$cesta_drill/Zdroje";
		} elsif ($cestaUser eq "E") {
				$cesta_drill = "c:/Export";
				$cestaZdroje = "c:/Export";
		}
	my @layersGerber = get_layers('signal');
	my @drillQ = get_layers('drill');
	my @routQ = get_layers('rout');
	
	if ($frez_film == 1) {
					$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/f",data_type=>'exists');
						if ($genesis->{doinfo}{gEXISTS} eq "yes") {
								$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/create_drill_aid.pl",dirmode=>'global',params=>"$jobName $panelStepName");
						}
	}else{
					$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/ff",data_type=>'exists');
						if ($genesis->{doinfo}{gEXISTS} eq "yes") {
								$genesis->COM ('delete_layer',layer=>'ff');
						}
	}
	
				if ($genesis->{STATUS} != 0) {
						$infoStatus = 1;
						$genesis->PAUSE ('CHYBA - v prvni casti skriptu nastala chyba=>ulozeni, prevod okoli na tenting - najdi chybu v cerne obrazovce Genesisu');
				}
				$genesis->VON;

	
	
	
	# Customer's panel 
	#-------------------------
	if ($panelCustomer == 1) {
		
				my $customerPanelExist = CamAttributes->GetJobAttrByName($genesis, $jobName, 'customer_panel');
				if ($customerPanelExist eq 'yes') {
							my @btnsa = ("ANO", "NE"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
							my @ma =	("Panal zakaznika jiz byl nastaven, chces zadat znovu?");
						
							new MessageForm( Enums::MessageType->WARNING, \@ma, \@btnsa, \$resulta);
							if ($resulta == 2) {
									my ($singleXsize, $singleYsize, $nas_mpanel_zak) = _CustomerPanel();
				
									# Set construction class to the attribute of job
									CamJob->SetJobAttribute($genesis, 'customer_panel', 'yes', $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_singlex', $singleXsize, $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_singley', $singleYsize, $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_multipl', $nas_mpanel_zak, $jobName);
							}
				}else{
									my ($singleXsize, $singleYsize, $nas_mpanel_zak) = _CustomerPanel();
				
									# Set construction class to the attribute of job
									CamJob->SetJobAttribute($genesis, 'customer_panel', 'yes', $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_singlex', $singleXsize, $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_singley', $singleYsize, $jobName);
									CamJob->SetJobAttribute($genesis, 'cust_pnl_multipl', $nas_mpanel_zak, $jobName);
				}
	}


	# Export PLOTR
	#-------------------------
	if ($plotr == 1) {
			$genesis->VOF;
			 get_opfx_plotr();
				if ($genesis->{STATUS} != 0) {
						$infoStatus = 1;
						$genesis->PAUSE ('CHYBA - nelze vyexportovat data na plotr - najdi chybu v cerne obrazovce Genesisu');
				}
				$genesis->VON;
	}
	
	# Export FREZOVANI
	#-------------------------
	# Export VRTANI
	#-------------------------
	if ($Drill == 1) {
			
			$statusLabel = sprintf "@persentList ... exportuji data pro vrtani/frezu ... ";#logText
			$status->update;
			
			my $inCAM  = InCAM->new();
			my $export = NCExportTmp->new();

			#input parameters
			my $jobId = $ENV{"JOB"};

			# Exportovat jednotlive vrstvy nebo vsechno
			my $exportSingle = 0;

			# Vrstvy k exportovani, nema vliv pokud $exportSingle == 0
			my @pltLayers  = ();
			my @npltLayers = ();

			# Pokud se bude exportovat jednotlive po vrstvach, tak vrstvz dotahnout nejaktakhle:
			#@pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
			#@npltLayers = CamDrilling->GetNPltNCLayers( $inCAM, $jobId );

			#return 1 if OK, else 0
			$export->Run( $inCAM, $jobId, $exportSingle, \@pltLayers, \@npltLayers );
			
	}
	
	# Export DRAZKOVANI
	#-------------------------
	if ($Score == 1) {
			$genesis->VOF;
			get_DRAZ_program();
			if ($genesis->{STATUS} != 0) {
					$infoStatus = 1;
					$genesis->PAUSE ('CHYBA - nelze vyexportovat data pro drazkovani - najdi chybu v cerne obrazovce Genesisu');
			}
			$genesis->VON;
	}
	
	# Export ELEKTRICKY TEST
	#-------------------------
	if ($Ipc == 1) {
		
			$statusLabel = sprintf "@persentList ... exportuji data na elektricky test ... ";#logText
			$status->update;
			
			
			my $jobId    = $jobName;
			my $inCAM    = InCAM->new();

			my $stepToTest = "panel";
	
			my $export = ETExportTmp->new();
			$export->Run( $inCAM, $jobId, $stepToTest );
 	}
 	
 	# Export AOI
 	#-------------------------
	if ($Optika == 1) {
		
			$statusLabel = sprintf "@persentList ... exportuji data na opticky test ... ";#logText
			$status->update;
			
			#GET INPUT NIF INFORMATION
			my $stepToTest = "panel";
			my $inCAM = InCAM->new();
			my $jobId = $jobName;
			
			my $export = AOIExportTmp->new();
			$export->Run( $inCAM, $jobId, $stepToTest );
	}
	
	# Export PDF
	#-------------------------
	if ($Pdf == 1) {
			$genesis->VOF;
			get_pdfFile();
			if ($genesis->{STATUS} != 0) {
					$infoStatus = 1;
					$genesis->PAUSE ('CHYBA - nelze vyexportovat data pro pdf - najdi chybu v cerne obrazovce Genesisu');
			}
			$genesis->VON;
	}
	
	# Export GERBER_X
	#-------------------------
	if ($Gerber ==1) {
				$genesis->VOF;
				##### odstraneni vytvoreneho souboru pro JETRITE
				opendir ( DIRGERBER, $cestaZdroje);
					while( (my $oneItem = readdir(DIRGERBER))){
							if ($oneItem =~ /$jobName/) {
									if($oneItem =~ /\.ger$/) {
											unlink "$cestaZdroje/$oneItem";
									}
							}
					}
				closedir DIRGERBER;
				
				
				my $cestaPotisk = '//dc2.gatema.cz/r/Potisk';
				opendir ( GERBER, $cestaPotisk);
						while( (my $oneItem = readdir(GERBER))){
								if ($oneItem =~ /$jobName/) {
											unlink "$cestaPotisk/$oneItem";
								}
						}
				closedir GERBER;
				
				my $cestaMDI_1 = '//dc2.gatema.cz/r/MDI';
				opendir ( GERBER, $cestaMDI_1);
						while( (my $oneItem = readdir(GERBER))){
								if ($oneItem =~ /$jobName/) {
											unlink "$cestaMDI_1/$oneItem";
								}
						}
				closedir GERBER;
				
				my $cestaMDI_2 = '//dc2.gatema.cz/r/PCB/mdi';
				opendir ( GERBER, $cestaMDI_2);
						while( (my $oneItem = readdir(GERBER))){
								if ($oneItem =~ /$jobName/) {
											unlink "$cestaMDI_2/$oneItem";
								}
						}
				closedir GERBER;
				
				
				
				###################################################
			
			get_gerber(@layersGerber);
			if ($genesis->{STATUS} != 0) {
					$infoStatus = 1;
					$genesis->PAUSE ('CHYBA - nelze vyexportovat Gerber data - najdi chybu v cerne obrazovce Genesisu');
			}
			$genesis->VON;
	}
	
	
	
	# Create NIF
	#---------------------------------------
unless ($nifNegenerovat) {
	# Here is create *.bac of nif
	_ControlNifRead($jobName, $cesta_nif);
	
	
	
	$statusLabel = sprintf " ... tvorim nif ... ";#logText
	$status->update;
	#input parameters
	my $jobId = $jobName;
 
 
 
	my $poznamka = $txt->get("1.0","end");
	   chomp($poznamka);
	   $poznamka =~ s/\n/,/g;

	my @dataCodeArr = ();
 		while (my ($key,$value) = each %dtCode) {
 				if ($value) {
 					push @dataCodeArr, $key;
 				}
 		}
	my $datacode  = join(',', @dataCodeArr);
	
	my @ulArr = ();
 		while (my ($key,$value) = each %ul) {
 				if ($value) {
 					push @ulArr, $key;
 				}
 		}
	my $ullogo  = join(',', @ulArr);
	my $jumpScoring  = $jump;
	
	
	if($bga){
		$poznamka = "BGA" . ", $poznamka";
	}
	
	
	if($checkViewRout){
		$poznamka = "Zkontroluj prvni kus pri frezovani." . ", $poznamka";
	}
	
	my $inCAM = InCAM->new();
	my $export = NifExportTmp->new();

	#return 1 if OK, else 0
	$export->Run( $inCAM, $jobId, $poznamka, $tenting, $pressfit, $maska01, $datacode, $ullogo, $jumpScoring);

}
	
	
	# Kontrola zda jsou vyexportovany jadra
	#---------------------------------------
	SimpleControlsHelper->CheckOpfxCore($jobName,$layerCount);
	
	
	# Kontrola zda drayka nezasahuje do profilu, u standardni desky s Jumpscoringem
	#---------------------------------------
	if($jump == 1 && sqlNoris::getValueNoris($jobName, 'pooling') ne 'A')
	{
		if (GenesisHelper->StepExists($jobName,"o+1")){
			$genesis->COM('script_run',name=>GeneralHelper->RootScripts()."ScoreCheckProfileScript.pl",dirmode=>'global',params=>"$jobName o+1");
		}
		
		if (GenesisHelper->StepExists($jobName,"mpanel")){
			$genesis->COM('script_run',name=>GeneralHelper->RootScripts()."ScoreCheckProfileScript.pl",dirmode=>'global',params=>"$jobName mpanel");
		}		
	
	}
	
	# Kontrola zda freza s kompenzaci LEFT jede naposledy
	#---------------------------------------
	$genesis->COM('script_run',name=>GeneralHelper->RootScripts()."RouteListControlsScript.pl",dirmode=>'global',params=>"$jobName panel");	
	
	
	
	
	$genesis -> COM ('save_job',job=>"$jobName",override=>'no',skip_upgrade=>'no');
	
}
	
	
sub get_opfx_AOI {
			$statusLabel = sprintf "@persentList ... exportuji data na opticky test ... ";#logText
			$status->update;
					$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/genesis_aoi_process.pl",dirmode=>'global',params=>"$jobName $panelStepName");
}
sub export_ipc_file {
	 my $stepForIpc = shift;
	 my $dekonturizace = shift;
	 my $localBoards = 'c:/Boards';
	 my $checkStep;
	 
		$statusLabel = sprintf "@persentList ... exportuji data na elektricky test ...";#logText
		$status->update;
		
		if($stepForIpc eq 'special') {
			$checkStep = 'panel';
		}else{
			$checkStep = $stepForIpc;
		}


		$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/$checkStep",data_type=>'NUM_SR');
			if (($genesis->{doinfo}{gNUM_SR}) > 0) {
					$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/et_panel3.pl",dirmode=>'global',params=>"$jobName $stepForIpc $checkStep");
					$stepForIpc = 'et_panel';
			}
				if ($dekonturizace == 1) {
						dekonturizace_ET($stepForIpc);
				}
				$genesis -> COM ('netlist_recalc',job=>"$jobName",step=>"$stepForIpc",type=>'cur',display=>'bottom',layer_list=>'');
				$genesis -> COM ('output_layer_reset');
				$genesis -> COM ('output',job=>"$jobName",step=>"$stepForIpc",format=>'IPC-D-356A',dir_path=>"$cestaZdroje",prefix=>"${jobName}t",suffix=>'.ipc',x_anchor=>'0',y_anchor=>'0',netlist_type=>'Current',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',finished_drills=>'no',ipcd_units=>'mm',adjacency=>'yes',trace=>'yes',tooling=>'yes',shrink2gasket=>'yes',panel_img=>'yes',sr_info=>'yes',rotate_net=>'0',mirror_net=>'no',sub_panel=>"");
				
					# Vytvoreni adresare pro el.test
					#--------------------------------
					rename("$cestaZdroje/${jobName}tcurnet.ipcd.ipc","$cestaZdroje/${jobName}t.ipc");
						unless (-e "$localBoards/$jobName") {
	  						mkdir("$localBoards/${jobName}t");
	  							cp("$cestaZdroje/${jobName}t.ipc","$localBoards/${jobName}t");
						}
	#set_remove_from_DB($jobName);
}


sub get_pdfFile {	
		my @layers;
			$statusLabel = sprintf "@persentList ... exportuji pdf soubor ...";#logText
			$status->update;
		$genesis -> COM ('copy_entity',type=>'step',source_job=>"$jobName",source_name=>"$stepPdf",dest_job=>"$jobName",dest_name=>"${stepPdf}_pdf",dest_database=>'');

		$genesis->COM ('set_step',name=>"${stepPdf}_pdf");
		$genesis->COM('units',type=>'mm');

		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/f",data_type=>'exists');
    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$genesis-> COM ('compensate_layer',source_layer=>'f',dest_layer=>'_f_kom',dest_layer_type=>'rout');
					$genesis-> COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'_f_kom',context=>'board');
			}
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/r",data_type=>'exists');
    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$genesis-> COM ('compensate_layer',source_layer=>'r',dest_layer=>'_rr',dest_layer_type=>'rout');
					$genesis-> COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'_rr',context=>'board');
			}
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/score",data_type=>'exists');
	    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$genesis-> COM ('compensate_layer',source_layer=>'score',dest_layer=>'score_layer',dest_layer_type=>'rout');
					$genesis-> COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'score_layer',context=>'board');
					$genesis->COM ('display_layer',name=>'score_layer',display=>'yes',number=>'1');
		    		$genesis->COM ('work_layer',name=>'score_layer');
		    		$genesis->COM ('sel_change_sym',symbol=>'r1000',reset_angle=>'no');
		    		$genesis->COM ('display_layer',name=>'score_layer',display=>'no',number=>'1');
			}
		
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/${stepPdf}_pdf/m",data_type => 'TOOL_USER');
			$tooluser = $genesis->{doinfo}{gTOOL_USER}; 
		if ($tooluser eq 'vysledne') {
					$vys_vrt = 'Tool\;Count\;Type\;Finish\;+Tol\;-Tol\;Des';
		}else{
					$vys_vrt = 'Tool\;Count\;Type\;+Tol\;-Tol';
		}
if ($stepPdf eq 'o+1') {
	#drill map pro vrstvu M a step o+1
	$genesis->COM ('copy_layer',source_job=>"$jobName",source_step=>"${stepPdf}_pdf",source_layer=>'m',dest=>'layer_name',dest_layer=>'tmp_drill',mode=>'replace',invert=>'no');
   #$genesis->COM ('cre_drills_map',layer=>'tmp_drill',map_layer=>'pth_drill_map',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
    $genesis->COM ('cre_drills_map',layer=>'tmp_drill',map_layer=>'pth_drill_map',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>"$vys_vrt",notype=>'plt',table_pos=>'right',table_align=>'bottom');
	$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'pth_drill_map',type=>'document');
	$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'pth_drill_map',context=>'board');
	
	#drill map pro vrstvu D a step o+1
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/d",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('copy_layer',source_job=>"$jobName",source_step=>"${stepPdf}_pdf",source_layer=>'d',dest=>'layer_name',dest_layer=>'tmp_drill_d',mode=>'replace',invert=>'no');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'tmp_drill_d',type=>'drill');
			   #$genesis->COM ('cre_drills_map',layer=>'tmp_drill_d',map_layer=>'npth_drill_map',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
				$genesis->COM ('cre_drills_map',layer=>'tmp_drill_d',map_layer=>'npth_drill_map',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>'Tool\;Count\;Type\;Finish\;+Tol\;-Tol\;Des',notype=>'plt',table_pos=>'right',table_align=>'bottom');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map',type=>'document');
				$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map',context=>'board');
		}
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('copy_layer',source_job=>"$jobName",source_step=>"${stepPdf}_pdf",source_layer=>'f',dest=>'layer_name',dest_layer=>'tmp_f_npth',mode=>'replace',invert=>'no');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'tmp_f_npth',type=>'drill');
				
				$genesis->COM ('display_layer',name=>'tmp_f_npth',display=>'yes',number=>'1');
		    	$genesis->COM ('work_layer',name=>'tmp_f_npth');
		    	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.rout_chain',min_int_val=>'0',max_int_val=>'4000');
		    	$genesis->COM ('filter_area_strt');
				$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
				$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} > 0) {
				$genesis->COM ('sel_delete');
			}
				$genesis->COM ('display_layer',name=>'tmp_f_npth',display=>'no',number=>'1');
				$genesis->COM ('filter_reset',filter_name=>'popup');
				$genesis->COM ('zoom_home');
		    	
			   #$genesis->COM ('cre_drills_map',layer=>'tmp_f_npth',map_layer=>'npth_drill_map_in_f',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
				$genesis->COM ('cre_drills_map',layer=>'tmp_f_npth',map_layer=>'npth_drill_map_in_f',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>'Tool\;Count\;Type\;Finish\;+Tol\;-Tol\;Des',notype=>'plt',table_pos=>'right',table_align=>'bottom');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map_in_f',type=>'document');
				$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map_in_f',context=>'board');
		}
	
} else {
	#drill map pro vrstvu M a step mpanel nebo panel
	$genesis->COM ('flatten_layer',source_layer=>'m',target_layer=>'tmp_drill');
   #$genesis->COM ('cre_drills_map',layer=>'tmp_drill',map_layer=>'pth_drill_map',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
	$genesis->COM ('cre_drills_map',layer=>'tmp_drill',map_layer=>'pth_drill_map',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>"$vys_vrt",notype=>'plt',table_pos=>'right',table_align=>'bottom');		
	$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'pth_drill_map',type=>'document');
	$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'pth_drill_map',context=>'board');

	#drill map pro vrstvu D a step mpanel nebo panel
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/d",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    			$genesis->COM ('flatten_layer',source_layer=>'d',target_layer=>'tmp_drill_d');
    			$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'tmp_drill_d',type=>'drill');
    		   #$genesis->COM ('cre_drills_map',layer=>'tmp_drill_d',map_layer=>'npth_drill_map',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
    			$genesis->COM ('cre_drills_map',layer=>'tmp_drill_d',map_layer=>'npth_drill_map',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>'Tool\;Count\;Type\;Finish\;+Tol\;-Tol\;Des',notype=>'plt',table_pos=>'right',table_align=>'bottom');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map',type=>'document');
				$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map',context=>'board');
		}
	#drill map pro vrstvu F a step mpanel nebo panel
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('flatten_layer',source_layer=>'f',target_layer=>'tmp_f_npth');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'tmp_f_npth',type=>'drill');
				
				$genesis->COM ('display_layer',name=>'tmp_f_npth',display=>'yes',number=>'1');
		    	$genesis->COM ('work_layer',name=>'tmp_f_npth');
		    	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.rout_chain',min_int_val=>'0',max_int_val=>'4000');
		    	$genesis->COM ('filter_area_strt');
				$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
				$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} > 0) {
				$genesis->COM ('sel_delete');
			}
				$genesis->COM ('display_layer',name=>'tmp_f_npth',display=>'no',number=>'1');
				$genesis->COM ('filter_reset',filter_name=>'popup');
				$genesis->COM ('zoom_home');
		    	
			   #$genesis->COM ('cre_drills_map',layer=>'tmp_f_npth',map_layer=>'npth_drill_map_in_f',preserve_attr=>'no',draw_origin=>'no',units=>'mm',mark_dim=>'1270');
				$genesis->COM ('cre_drills_map',layer=>'tmp_f_npth',map_layer=>'npth_drill_map_in_f',preserve_attr=>'no',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150.0',sr=>'yes',slots=>'yes',columns=>'Tool\;Count\;Type\;Finish\;+Tol\;-Tol\;Des',notype=>'plt',table_pos=>'right',table_align=>'bottom');
				$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map_in_f',type=>'document');
				$genesis->COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'npth_drill_map_in_f',context=>'board');
		}
}

		$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/${stepPdf}_pdf",data_type => 'PROF_LIMITS');
        $myNulaX = ($genesis->{doinfo}{gPROF_LIMITSxmin} + 1);  
        $myNulaY = ($genesis->{doinfo}{gPROF_LIMITSymin} - 4.5);
		$myNulaXinfo = ($genesis->{doinfo}{gPROF_LIMITSxmin} + 1);  
        $myNulaYinfoZ = ($genesis->{doinfo}{gPROF_LIMITSymax} + 20);
        $myNulaYinfoT = ($genesis->{doinfo}{gPROF_LIMITSymax} + 15);
        $myNulaYinfoE = ($genesis->{doinfo}{gPROF_LIMITSymax} + 10);
		$myNulaYinfoP = ($genesis->{doinfo}{gPROF_LIMITSymax} + 5);




$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
$totalRows = @{$genesis->{doinfo}{gROWname}};
for ($count=0;$count<$totalRows;$count++) {
	if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
		$rowName = ${$genesis->{doinfo}{gROWname}}[$count];
		$rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
		$rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
		$rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
	 if ($rowName =~ /ff/g) {
			$slepeFF = 	$rowName;
     }
		if ($rowContext eq "board" && $rowName ne "fr" && $rowName ne "v1" && $rowName ne "f" && $rowName ne "score" && $rowName ne "r" && $rowName ne "$slepeFF") {
			push(@layers_name,$rowName);
			$addtext = "";
			if ($rowName eq 'gc') {
				$addtext = 'graphite TOP';
			}
			if ($rowName eq 'lc') {
				$addtext = 'peelable mask TOP';
			}
			if ($rowName eq 'pc') {
				$addtext = 'silkscreen TOP';
			}
			if ($rowName eq 'mc') {
				$addtext = 'soldermask TOP';
			}
			if ($rowName eq 'c') {
				$addtext = 'layer TOP';
			}
			if ($rowName eq 's') {
				$addtext = 'layer BOTTOM';
			} 
			if ($rowName eq 'ms') {
				$addtext = 'soldermask BOTTOM';
			} 
			if ($rowName eq 'ps') {
				$addtext = 'silkscreen BOTTOM';
			} 
			if ($rowName eq 'ls') {
				$addtext = 'peelable mask BOTTOM';
			}
			if ($rowName eq 'gs') {
				$addtext = 'graphite BOTTOM';
			}
			if ($rowName eq 'm') {
				$addtext = 'drill layer PTH';
			}
			if ($rowName eq '_f_kom') {
				$addtext = 'NPT mill layer';
			}
			if ($rowName eq 'd') {
				$addtext = 'drill layer NPTH';
			}
			if ($rowName eq 'score_layer') {
				$addtext = 'layer SCORE';
			}
			if ($rowName eq '_rr') {
				$addtext = 'PT mill layer';
			}
			if ($rowName eq 'pth_drill_map') {
				$addtext = 'PTH drill map';
			}
			if ($rowName eq 'npth_drill_map') {
				$addtext = 'NPTH drill map';
			}
			if ($rowName eq 'npth_drill_map_in_f') {
				$addtext = 'NPTH drill map in mill layer';
			}
			if ($addtext eq "") {
				$addtext = "$rowName";
			}

			
	    		$genesis->COM ('display_layer',name=>"$rowName",display=>'yes',number=>'1');
		    	$genesis->COM ('work_layer',name=>"$rowName");
		    	$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaX",y=>"$myNulaY",text=>"$addtext",x_size=>'2',y_size=>'2',w_factor=>'0.984251976',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
		    	$genesis->COM ('display_layer',name=>"$rowName",display=>'no',number=>'1');
		}
		if ($rowContext eq "board" && $rowName ne "fr" && $rowName ne "v1" && $rowName ne "f" && $rowName ne "score" && $rowName ne "r" && $rowName ne "$slepeFF") {
			push(@layers,$rowName,'\;');
			$countPrint ++;
		}
	}
}



#	if ($countPrint == 2) {
#			$nx_p = 2;
#			$ny_p = 1;
#	}elsif ($countPrint == 3) {
#			$nx_p = 3;
#			$ny_p = 1;
#	}elsif ($countPrint == 3) {
#			$nx_p = 3;
#			$ny_p = 1;
#	}elsif ($countPrint == 4) {
#			$nx_p = 2;
#			$ny_p = 2;
#	}elsif ($countPrint == 5 or $countPrint == 6) {
#			$nx_p = 2;
#			$ny_p = 3;
#	}elsif ($countPrint > 6) {
			$nx_p = 2;
			$ny_p = 2;
#	}


$genesis->INFO(entity_type=>'job',entity_path=>"$jobName",data_type=>'ATTR');
	@attrname = @{$genesis->{doinfo}{gATTRname}};
	@attrval = @{$genesis->{doinfo}{gATTRval}};

$countAttr = 0;
foreach my $singleName(@attrname) {
	if ($singleName eq 'user_name') {
		$userName = $attrval[$countAttr];	
	}
	$countAttr++;
}
		if ($userName eq 'rvi') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Radim Vitek';
					$addinfotext_telefon = 'TELEFON: 516426747';
					$addinfotext_email = 'EMAIL : radim.vitek@gatema.cz';
		}elsif($userName eq 'rc') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Radek Chlup';
					$addinfotext_telefon = 'TELEFON: 516426731';
					$addinfotext_email = 'EMAIL : radek.chlup@gatema.cz';
		}elsif($userName eq 'pn') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Pavel Nejedly';
					$addinfotext_telefon = 'TELEFON: 516426753';
					$addinfotext_email = 'EMAIL : pavel.nejedly@gatema.cz';
		}elsif($userName eq 'lba') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Lukas Bartusek';
					$addinfotext_telefon = 'TELEFON: 516426748';
					$addinfotext_email = 'EMAIL : lukas.bartusek@gatema.cz';
		}elsif($userName eq 'jkr') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Josef Krejci';
					$addinfotext_telefon = 'TELEFON: 516426734';
					$addinfotext_email = 'EMAIL : josef.krejci@gatema.cz';
		}elsif($userName eq 'va') {
					$addinfotext_zpracoval = 'ZPRACOVAL : Vaclav Ambroz';
					$addinfotext_telefon = 'TELEFON: 516426753';
					$addinfotext_email = 'EMAIL : vaclav.ambroz@gatema.cz';
		}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/s",data_type=>'exists');
    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									$addinfotext_poznamka = 'POZNAMKY: Pohled z pruhledu ze strany Top';
						}else{
									$addinfotext_poznamka = 'POZNAMKY: Pohled na medenou stranu';
						}

if ($infoTechnic == 1) {
		$genesis->COM ('display_layer',name=>"$layers_name[0]",display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>"$layers_name[0]");
			
				$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaXinfo",y=>"$myNulaYinfoZ",text=>"$addinfotext_zpracoval",x_size=>'3',y_size=>'3',w_factor=>'0.984251976',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
				$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaXinfo",y=>"$myNulaYinfoT",text=>"$addinfotext_telefon",x_size=>'3',y_size=>'3',w_factor=>'0.984251976',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
				$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaXinfo",y=>"$myNulaYinfoE",text=>"$addinfotext_email",x_size=>'3',y_size=>'3',w_factor=>'0.984251976',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
				$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$myNulaXinfo",y=>"$myNulaYinfoP",text=>"$addinfotext_poznamka",x_size=>'3',y_size=>'3',w_factor=>'0.984251976',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');

				$genesis->COM ('display_layer',name=>"$layers_name[0]",display=>'no',number=>'1');
}

$genesis->COM('print',title=>"",layer_name=>"@layers",mirrored_layers=>"",draw_profile=>'yes',drawing_per_layer=>'yes',dest=>'pdf_file',num_copies=>'1',dest_fname=>"$cestaZdroje/${jobName}-control.pdf",paper_size=>'A4',scale_to=>'0',nx=>"$nx_p",ny=>"$ny_p",orient=>'none',paper_orient=>'portrait',paper_width=>'0',paper_height=>'0',auto_tray=>'no',top_margin=>'5',bottom_margin=>'5',left_margin=>'5',right_margin=>'5',x_spacing=>'0',y_spacing=>'0');


$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/_f_kom",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'_f_kom');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/_rr",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'_rr');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/score_layer",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'score_layer');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/tmp_drill",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'tmp_drill');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/pth_drill_map",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'pth_drill_map');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/tmp_drill_d",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'tmp_drill_d');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/npth_drill_map",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'npth_drill_map');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/npth_drill_map_in_f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'npth_drill_map_in_f');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/${stepPdf}_pdf/tmp_f_npth",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->COM ('delete_layer',layer=>'tmp_f_npth');
		}
		
		$genesis->COM ('editor_page_close');
		$genesis->COM ('delete_entity',job=>"$jobName",type=>'step',name=>"${stepPdf}_pdf");

}
sub get_gerber {	
	my @layersGerber = @_; 
				#	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/ff",data_type=>'exists');
				#		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				#				push(@layersGerber,'ff');
				#		}
		$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
		$genesis->AUX('set_group', group => $genesis->{COMANS});
		
		$statusLabel = sprintf "@persentList ... exportuji gerber data ...";#logText
		$status->update;
					
		$genesis -> COM ('output_layer_reset');
		#foreach my $deleteInner (@layersGerber) {
		#		unless ($deleteInner =~ /v\d{1,2}/) {
		#			push (@newGerberList,$deleteInner);
		#		}
		#}
		@newGerberList = @layersGerber;
		foreach my $layerGerber (@newGerberList) {
				if (($layerGerber eq "mc") or ($layerGerber eq "c")) {
						$mirrorGerber = "yes";
						$pripona = "-.ger";
				}else {
						$mirrorGerber = "no";
						$pripona = "-.ger";
				}
				if ($Potisk eq "Negativ") {
						if ($layerGerber eq "pc") { 
								$mirrorGerber = "yes";
								$pripona = "n-.ger";
						}
				} elsif ($Potisk eq "Positiv") {
						if ($layerGerber eq "pc") {
								$mirrorGerber = "no";
								$pripona = "-.ger";
						}
				}
				if ($Potisk eq "Negativ") {
						if ($layerGerber eq "ps") { 
								$mirrorGerber = "no";
								$pripona = "n-.ger";
						}
				} elsif ($Potisk eq "Positiv") {
						if ($layerGerber eq "ps") {
								$mirrorGerber = "yes";
								$pripona = "-.ger";
						}
				}

				if (($layerGerber eq "c") or ($layerGerber eq "s")) {
						if ($layerCount == 1) {
								$pripona = "n_kom${valueReduction}um-.ger";
						}else{
								$pripona = "_komp${valueReduction}um-.ger";
						}
				}
				$genesis -> COM ('output_layer_reset');	
				$genesis -> COM ('output_layer_set',layer=>"$layerGerber",angle=>'0',mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
				$genesis -> COM ('output',job=>"$jobName",step=>'panel',format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>"$pripona",break_sr=>'no',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
				$genesis -> COM ('disp_on');
				$genesis -> COM ('origin_on');
		}
}
sub prepare_jetPrint {	
	my @layersGerber = @_; 

		$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
		$genesis -> AUX ('set_group', group => $genesis->{COMANS});
		
#		$statusLabel = sprintf "@persentList ... exportuji gerber data pro jetPrint ...";#logText
#		$status->update;
					
		$genesis -> COM ('output_layer_reset');

		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/pc",data_type=>'exists');
	    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
	    			get_gerber_jetPrint('pc');
	    	}
	    	
	    $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/ps",data_type=>'exists');
	    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
	    			get_gerber_jetPrint('ps');
	    	}
}

sub get_gerber_jetPrint {
	my $silkItem = shift;
	my $tmpSufix = 'jet';
	my $mirrorGerber;
	
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/$silkItem",data_type=>'SIDE');
		if ($genesis->{doinfo}{gSIDE} eq 'top') {
				$mirrorGerber = 'no';
		}else{
				$mirrorGerber = 'yes';
		}
	
	$genesis->COM ('clear_layers');
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/${silkItem}_$tmpSufix",data_type=>'exists');
	    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
	    			$genesis->COM ('delete_layer',layer=>"${silkItem}_$tmpSufix");

	    	}
	    	
	$genesis->COM ('flatten_layer',source_layer=>"$silkItem",target_layer=>"${silkItem}_$tmpSufix");
	$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>"${silkItem}_$tmpSufix",type=>'silk_screen');
	
	$genesis->COM ('display_layer',name=>"${silkItem}_$tmpSufix",display=>'yes',number=>'1');
	$genesis->COM ('work_layer',name=>"${silkItem}_$tmpSufix");

#	$genesis->COM ('clip_area_strt');
#	$genesis->COM ('clip_area_end',layers_mode=>'layer_name',layer=>"${silkItem}_$tmpSufix",area=>'profile',area_type=>'rectangle',inout=>'outside',contour_cut=>'yes',margin=>'-6000',feat_types=>'line\;pad\;surface\;arc\;text');
#	$genesis->COM ('get_select_count');
#		if ($genesis->{COMANS} > 0) {
#				$genesis->COM ('sel_delete');
#		}
	
	
	
	$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'screen_user*',min_int_val=>'999',max_int_val=>'999');
	$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'screen_day*',min_int_val=>'999',max_int_val=>'999');
	$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'screen_date*',min_int_val=>'999',max_int_val=>'999');
	$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'screen_time*',min_int_val=>'999',max_int_val=>'999');
	$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'screen_colour*',min_int_val=>'999',max_int_val=>'999');
	$genesis->COM('filter_atr_logic',filter_name=>'popup',logic=>'or');
	$genesis->COM('filter_area_strt');
	$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
	$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_delete');
					}
	$genesis->COM('filter_reset',filter_name=>'popup');
	

	$genesis->COM ('sel_multi_feat',operation=>'select',feat_types=>'pad',include_syms=>'okoli_320');
	$genesis->COM ('sel_multi_feat',operation=>'select',feat_types=>'pad',include_syms=>'okoli_145_full');
	$genesis->COM ('sel_multi_feat',operation=>'select',feat_types=>'pad',include_syms=>'s5000');
	$genesis->COM ('zoom_home');
	$genesis->COM ('sel_delete');
	
	$genesis -> COM ('output_layer_reset');	
	$genesis -> COM ('output_layer_set',layer=>"${silkItem}_$tmpSufix",angle=>'0',mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'inch',gscl_file=>'');
	$genesis -> COM ('output',job=>"$jobName",step=>'panel',format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>".ger",break_sr=>'yes',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
	$genesis -> COM ('disp_on');
	$genesis -> COM ('origin_on');
	
	$genesis->COM ('delete_layer',layer=>"${silkItem}_$tmpSufix");
	
}
########################## VRTANI ##############################################

#########################################################################################################################
###################### Drazkovani ###################################################################
sub get_DRAZ_program {
			$statusLabel = sprintf "@persentList ... exportuji data pro drazkovani ... ";#logText
			$status->update;
			
#				$genesis -> COM ('open_job',job=>"$jobName");
#				$genesis -> COM ('clipb_open_job',job=>"$jobName",update_clipboard=>'view_job');
#				$genesis -> COM ('ncset_cur',job=>"$jobName",step=>"panel",layer=>"draz_prog",ncset=>"3");
#				$genesis -> COM ('ncd_set_machine',machine=>'draz_program',thickness=>'0');
#				$genesis -> COM ('disp_on');
#				$genesis -> COM ('origin_on');
#				$genesis -> COM ('ncd_cre_drill');
#				
#				$genesis -> COM ('ncd_ncf_export',stage=>'1',split=>'1',dir=>"$cesta_drill",name=>"${jobName}dr.cut");
#
#				$genesis -> COM ('ncset_delete',name=>'3');	
				
				$panelThickness = $enlarge_buttom_score->get;
				$coreScore = $enlarge_buttom_core->get;
			
				$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
				$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/scoreMachine.pl",dirmode=>'global',params=>"$jobName $cesta_drill $panelThickness $coreScore $fiducScore $jump $typScore");
}
############################################################################################################################
sub get_routed_program {
		#my @rout_layers = @_;	 	
			$statusLabel = sprintf "@persentList ... exportuji data pro frezovani ... ";#logText
			$status->update;

		foreach my $one_rout (@rout_layers) {
			$orderLayer = '';
					if ($one_rout eq 'f_schmoll') {
							 $machine = 'schmoll';
							 $sufix = 'f1.ros';
							 $orderType = 'btrl';
							 $orderLayer = 'f';
					}elsif ($one_rout eq 'f_sm3000') {
							 $machine = 'gatema_sm3000';
							 $sufix = 'f1.rou';
							 $orderType = 'tbrl';
							 $orderLayer = 'f';
					}elsif ($one_rout eq 'r') {
								if($layerCount > 2) {
										 $machine = 'schmoll_r_vv';
								}else{
										 $machine = 'schmoll_r';
								}
							 $sufix = 'r1.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'r';
					}elsif ($one_rout eq 'fk') {
							 $machine = 'gatema_sm3000';
							 $sufix = 'fk.rou';
							 $orderType = 'tbrl';
							 $orderLayer = 'fk';
					}elsif ($one_rout eq 'fs') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'fs.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'fs';
					}elsif ($one_rout eq 'fr') {
							 $machine = 'export_ML_fr';
							 $sufix = 'fr.rou';
							 $orderType = 'tbrl';
							 $orderLayer = 'fr';
					}elsif ($one_rout eq 'rs') {
							 $machine = 'schmoll';
							 $sufix = 'rs.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'rs';
					}elsif ($one_rout eq 'f_sch') {
							 $machine = 'schmoll';
							 $sufix = 'f1.ros';
							 $orderType = 'btrl';
							 $orderLayer = 'f_sch';
					}elsif ($one_rout eq 'f_lm') {
							 $machine = 'gatema_sm3000';
							 $sufix = 'f1.rou';
							 $orderType = 'tbrl';
							 $orderLayer = 'f_lm';
					}elsif ($one_rout eq 'fcl_c') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'fcl_c.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'fcl_c';
					}elsif ($one_rout eq 'fcl_s') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'fcl_s.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'fcl_s';
					}elsif ($one_rout eq 'ppo_c') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'ppo_c.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'ppo_c';
					}elsif ($one_rout eq 'ppo_s') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'ppo_s.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'ppo_s';
					}elsif ($one_rout eq 'win_c') {
							 $machine = 'schmoll_r_vv';
							 $sufix = 'fv1.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'win_c';
					}elsif ($one_rout eq 'win_s') {
							 $machine = 'schmoll';
							 $sufix = 'fzs.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'win_s';
					}elsif ($one_rout eq 'fz_c') {
							 $machine = 'schmoll';
							 $sufix = 'fzc.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'fz_c';
					}elsif ($one_rout eq 'fz_s') {
							 $machine = 'schmoll';
							 $sufix = 'fzs.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'fz_s';
					}elsif ($one_rout eq 'rz_c') {
							 	if($layerCount > 2) {
										 $machine = 'schmoll_r_vv';
								}else{
										 $machine = 'schmoll_r';
								}
							 $sufix = 'rzc.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'rz_c';
					}elsif ($one_rout eq 'rz_s') {
							 	if($layerCount > 2) {
										 $machine = 'schmoll_r_vv';
								}else{
										 $machine = 'schmoll_r';
								}
							 $sufix = 'rzs.ros';
							 $orderType = 'tbrl';
							 $orderLayer = 'rz_s';
					}
		if ($orderLayer) {
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/$orderLayer",data_type=>'exists');
			    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {

    						$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/mpanel",data_type=>'exists');
								if ($genesis->{doinfo}{gEXISTS} eq "yes") {
										$genesis -> COM ('rename_entity',job=>"$jobName",is_fw=>'no',type=>'step',fw_type=>'form',name=>'mpanel',new_name=>'zmpanel');
								}

									
									$genesis -> COM('open_job',job=>"$jobName");
									$genesis -> COM('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
									$genesis -> AUX('set_group', group => $genesis->{COMANS});
								    $genesis -> COM('units',type=>'mm');
									
									$genesis -> COM ('ncrset_cur',job=>"$jobName",step=>"panel",layer=>"$orderLayer",ncset=>"17");
									$genesis -> COM ('ncr_set_machine',machine=>"$machine",thickness=>'0');
									$genesis -> COM ('ncrset_units',units=>'mm');
										$genesis->COM('ncr_set_params',format=>'SM3000',zeroes=>'leading',units=>'mm',tool_units=>'mm',nf1=>'3',nf2=>'3',decimal=>'yes',modal_coords=>'yes',single_sr=>'no',sr_zero_set=>'no',repetitions=>'sr',drill_layer=>'rt2drl',sr_zero_drill_layer=>'drill',break_sr=>'yes',ccw=>'no',short_lines=>'none',press_down=>'no',last_z_up=>'16',max_arc_ang=>'180',sep_lyrs=>'no',allow_no_chain_f=>'no',keep_table_order=>'yes');
											$genesis -> COM ('ncr_order',sr_line=>'1',sr_nx=>'1',sr_ny=>'1',serial=>'1',optional=>'no',mode=>"$orderType",snake=>'no',full=>'1',nx=>'0',ny=>'0');
											$genesis -> COM ('ncr_order',sr_line=>'1\;1',sr_nx=>'1\;1',sr_ny=>'1\;1',serial=>'1',optional=>'no',mode=>"$orderType",snake=>'no',full=>'1',nx=>'0',ny=>'0');
									$genesis -> COM ('ncr_cre_rout');
									$genesis -> COM ('ncrset_units',units=>'mm');
									$genesis -> COM ('ncr_ncf_export',dir=>"$cesta_drill",name=>"${jobName}${sufix}");
									$genesis -> COM ('ncrset_delete',name=>'17');

						
							$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/zmpanel",data_type=>'exists');
								if ($genesis->{doinfo}{gEXISTS} eq "yes") {
										$genesis -> COM ('rename_entity',job=>"$jobName",is_fw=>'no',type=>'step',fw_type=>'form',name=>'zmpanel',new_name=>'mpanel');
								}
					}
		}
	}
}
sub get_opfx_plotr {
			$statusLabel = sprintf "@persentList... exportuji data na plotr ...";#logText
			$status->update;
		
		$sendTOplotter = 'no';
		$Potisk = 'Negativ';
		$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
		$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/export_kresleni_incam",dirmode=>'global',params=>"$jobName $sendTOplotter $cestaZdroje $Potisk $padEnlarge $linEnlarge $valueReduction $draw_film $tenting");
		open (REPORT,"c:/tmp/Report_vykresleni");
            $statu = <REPORT>;
		close REPORT;
		unlink("c:/tmp/Report_vykresleni");
	}

sub exite {
   exit;
}
sub search_mpanel {
	$genesis->INFO('entity_type'=>'job','entity_path'=>"$jobName",'data_type'=>'STEPS_LIST');
   		 my @stepSeznam = @{$genesis->{doinfo}{gSTEPS_LIST}};
   		 
	foreach $searchMpanel(@stepSeznam) {
					if ($searchMpanel eq 'mpanel') {
						$mpanelExist = 1;
					}
					if ($searchMpanel eq 'o+1') {
						$oa1 = 1;
					}
	}
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$frezaExist = 1;
    	}
    		
	return ($mpanelExist,$frezaExist,$oa1);
}
sub dekonturizace_ET {
	my $etStep = shift;
	my @signalLayers = ();
	
	    $genesis->INFO(entity_type=>'step',entity_path=>"$jobName/$etStep",data_type=>'exists');
 				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    					$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$etStep",iconic=>'no');
    					$genesis->AUX('set_group', group => $genesis->{COMANS});
	    				$genesis->COM('units',type=>'mm');
	    				$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");

 		   			$genesis->INFO(entity_type=>'matrix',entity_path=>"$jobName/matrix",data_type=>'ROW');
						$totalRows = @{$genesis->{doinfo}{gROWname}};
							for ($count=0;$count<$totalRows;$count++) {
									if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
											$rowName = ${$genesis->{doinfo}{gROWname}}[$count];
											$rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
											$rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
											$rowSide = ${$genesis->{doinfo}{gROWside}}[$count];

											if ($rowContext eq "board" && $rowType eq "signal") {
													push(@signalLayers,$rowName);
											}
									}
							}
		foreach $oneSignal(@signalLayers) {
			$genesis->COM('affected_layer',name=>"$oneSignal",mode=>'single',affected=>'yes');
			
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'str_zn');
			$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
					if ($genesis->{COMANS} > 0) {
							$genesis->COM('sel_delete');
					}		
			
			$genesis->COM('filter_reset',filter_name=>'popup');
			#$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>'line\;pad\;surface');
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
			$genesis->COM('filter_area_strt');
			$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>'surface');
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
			$genesis->COM('filter_area_strt');
			$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
			$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} >= 1) {
						$genesis->COM('sel_contourize',accuracy=>'6.35',break_to_islands=>'yes',clean_hole_size=>'60',clean_hole_mode=>'x_and_y');
					}
			#$genesis-> COM ('affected_layer',mode=>'all',affected=>'no');
			#$genesis->COM('affected_layer',name=>"$oneSignal",mode=>'single',affected=>'yes');
			$genesis->COM('filter_reset',filter_name=>'popup');
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'yes',feat_types=>'surface');
			$genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
			$genesis->COM('filter_area_strt');
			$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
			$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} >= 1) {
							$genesis->COM('sel_fill');
					}
			$genesis-> COM ('affected_layer',mode=>'all',affected=>'no');
			$genesis->COM('filter_reset',filter_name=>'popup');
		}
	$genesis->COM ('editor_page_close');
 }
}

sub remove_mask_PTHrout {
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etStep/r",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    				$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$etStep",iconic=>'no');
			    	$genesis->AUX('set_group', group => $genesis->{COMANS});
				    $genesis->COM('units',type=>'mm');
				    
					$genesis->COM('display_layer',name=>'r',display=>'yes',number=>'1');
					$genesis->COM('work_layer',name=>'r');
					$genesis->COM('compensate_layer',source_layer=>'r',dest_layer=>'r__wcom',dest_layer_type=>'rout');
					$genesis->COM('display_layer',name=>'r',display=>'no',number=>'1');
					$genesis->COM('display_layer',name=>'r__wcom',display=>'yes',number=>'1');
					$genesis->COM('work_layer',name=>'r__wcom');
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etStep/mc",data_type=>'exists');
				    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
								$genesis->COM('affected_layer',name=>'mc',mode=>'single',affected=>'yes');
								$maskExist = 1;
						}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etStep/ms",data_type=>'exists');
				    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
								$genesis->COM('affected_layer',name=>'ms',mode=>'single',affected=>'yes');	
								$maskExist = 1;
						}
			if($maskExist) {
				$genesis->COM('sel_copy_other',dest=>'affected_layers',target_layer=>'',invert=>'yes',dx=>'0',dy=>'0',size=>'50');
				$genesis->COM('affected_layer',mode=>'all',affected=>'no');
				$genesis->COM('delete_layer',layer=>'r__wcom'); 
			}else{
				$genesis->COM('delete_layer',layer=>'r__wcom'); 
			}
			$genesis->COM ('editor_page_close');
		}
}
sub netlist_run {
		$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/scripts/control_netlist.pl",dirmode=>'global',params=>"$jobName");
}
sub cdr_remove {
		$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/cdr_error_delete",dirmode=>'global',params=>"$jobName");
		$statusLabel = sprintf "...Hotovo...";#logText
		$status->update;
}
sub export_kooperace {
		if ($cestaUser eq "A") {	
				$cesta_drill  = getPath($jobName);
				$cestaZdroje = "$cesta_drill/Zdroje";
		} elsif ($cestaUser eq "E") {
				$cesta_drill = "c:/Export";
				$cestaZdroje = "c:/Export";
		}
	$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/china",dirmode=>'global',params=>"$jobName $cestaZdroje");
	$statusLabel = sprintf "...Hotovo...";#logText
	$status->update;
}
sub chain_chain_number {
		$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/chch",dirmode=>'global',params=>"$jobName");
}
sub drill_map_koop {
		$genesis->COM('script_run',name=>"$ENV{'GENESIS_DIR'}/sys/perl/sub/dMk",dirmode=>'global',params=>"");
}
sub check_exist_kolecko {
			$genesis->COM('filter_reset',filter_name=>'popup');
			$genesis->COM('affected_layer',name=>'',mode=>'all',affected=>'no');

			$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>'panel',iconic=>'no');
    		$genesis->AUX('set_group', group => $genesis->{COMANS});
			$genesis->COM('display_layer',name=>"c",display=>'yes',number=>'1');
			$genesis->COM('work_layer',name=>"c");



			$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'outer_fiduc_score_*',min_int_val=>'999',max_int_val=>'999');
			$genesis->COM('filter_area_strt');
			$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
			$genesis->COM('filter_reset',filter_name=>'popup');
			
			$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} >= 1) {
						#$stateKolecko = 'normal';
						$fiducScore = 'kolecko';
					}else{
						#$stateKolecko = 'disable';
						$fiducScore = 'zadne';					
				#		$stateKolecko = 'disable';
				#		$fiducScore = 'ctverec';
					}
					if ($surface eq 'B' or $surface eq 'A') {
						#$stateKolecko = 'disable';
						$fiducScore = 'zadne';
					}
			$genesis->COM('filter_reset',filter_name=>'popup');
			$genesis->COM('affected_layer',name=>'',mode=>'all',affected=>'no');

			$genesis->COM('display_layer',name=>"c",display=>'no',number=>'1');
			
}


sub export_rozdel_prog {
	$splitDrill = 1;
	
	
	$genesis->COM ('affected_layer',affected=>'no',mode=>'all');
	$genesis->COM ('output_layer_reset');
	$genesis->COM ('display_layer',name=>'m',display=>'yes',number=>'1');
	$genesis->COM ('work_layer',name=>'m');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'r3200');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM ('cur_atr_set',attribute=>'.drill_stage',option=>'2');
	$genesis->COM ('sel_change_atr',mode=>'add'); 
	$genesis->COM ('display_layer',name=>'m',display=>'no',number=>'1');
	$genesis->COM ('affected_layer',affected=>'no',mode=>'all');
	$genesis->COM ('filter_reset',filter_name=>'popup');

		$ncSetCX = 18;
		$stageCX = 1;
	foreach $exportCX (b,a) {
		if ($exportCX eq 'a') {
			$genesis->COM ('set_attribute',type=>'layer',job=>"$jobName",name1=>'panel',name2=>'m',name3=>'',attribute=>'add_drill_number',value=>'no',units=>'mm');
		}
					$genesis -> COM ('open_job',job=>"$jobName");
					$genesis -> COM ('clipb_open_job',job=>"$jobName",update_clipboard=>'view_job');
					$genesis -> COM ('ncset_cur',job=>"$jobName",step=>"panel",layer=>"m",ncset=>"$ncSetCX");
					$genesis -> COM ('ncd_set_machine',machine=>'schmoll',thickness=>'0');
					$genesis -> COM ('disp_on');
					$genesis -> COM ('origin_on');
					$genesis -> COM ('ncd_cre_drill');
				#prvni tlac.
					$genesis -> COM ('disp_on');
					$genesis -> COM ('origin_on');
				#druhe tlac.
					$genesis -> COM ('disp_on');
					$genesis -> COM ('origin_on');
					$genesis -> COM ('ncd_ncf_export',stage=>"$stageCX",split=>'1',dir=>"$cesta_drill",name=>"${jobName}c${exportCX}.mes");
				#treti tlac Export
					$genesis -> COM ('disp_on');
					$genesis -> COM ('origin_on');
					$genesis -> COM ('ncset_delete',name=>"$ncSetCX");	
				
					$ncSetCX++; 
					$stageCX++;
				
			$genesis->COM ('set_attribute',type=>'layer',job=>"$jobName",name1=>'panel',name2=>'m',name3=>'',attribute=>'add_drill_number',value=>'yes',units=>'mm');

	}
	
		$genesis->COM ('display_layer',name=>'m',display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>'m');
		$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'r3200');
		$genesis->COM ('filter_area_strt');
		$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
		$genesis->COM ('cur_atr_set',attribute=>'.drill_stage',option=>'1');
		$genesis->COM ('sel_change_atr',mode=>'add'); 

		$genesis->COM ('display_layer',name=>'m',display=>'no',number=>'1');
		$genesis->COM ('affected_layer',affected=>'no',mode=>'all');
		$genesis->COM ('filter_reset',filter_name=>'popup');
}

sub get_minVrtak {
		$genesis->INFO(units => 'mm', entity_type => 'layer',entity_path => "$jobName/panel/m",data_type => 'TOOL',parameters => "drill_size",options => "break_sr");
		@valueDrillarray = @{$genesis->{doinfo}{gTOOLdrill_size}};
		@valueDrillarray = sort ({$a<=>$b} @valueDrillarray);
		
		foreach my $drillOne (@valueDrillarray) {
				unless ($drillOne == 0) {
						push(@valueDrill, $drillOne);
				}
		}

		$minVrtak = $valueDrill[0];
		$minVrtak = sprintf "%0.2f",($minVrtak/1000);
}
sub get_minFreza {
		my $layerproces = shift;
		my @routeTool = ();
		my $minFrezaTMP;
		my @valueTools = ();
		$genesis->INFO(units => 'mm', entity_type => 'layer',entity_path => "$jobName/panel/$layerproces",data_type => 'TOOL',parameters => 'drill_size',options => "break_sr");
		my @valueMilltool = @{$genesis->{doinfo}{gTOOLdrill_size}};
		
		$genesis->INFO(units => 'mm', entity_type => 'layer',entity_path => "$jobName/panel/$layerproces",data_type => 'TOOL',parameters => 'shape',options => "break_sr");
		my @valueMillshape = @{$genesis->{doinfo}{gTOOLshape}};
		
		my $countTools = 0;
			foreach (@valueMilltool) {
					if ($valueMillshape[$countTools] eq 'slot') {
						 	push(@routeTool,$valueMilltool[$countTools]);
					}					
				$countTools++;
			}
		
		@routeTool = sort ({$a<=>$b} @routeTool);
		foreach my $ToolOne (@routeTool) {
				unless ($ToolOne == 0) {
						push(@valueTools, $ToolOne);
				}
		}

		$minFrezaTMP = $valueTools[0];
		$minFrezaTMP = sprintf "%0.2f",($minFrezaTMP/1000);
	return($minFrezaTMP);
}
sub predkoveni {
	my $flashTMP = 'no';
		$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/panel/r",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					if ($povrchovaUprava eq "A" or $povrchovaUprava eq "B") {
							$flashTMP = 'yes';
					}
			}
		$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/panel/rs",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							$flashTMP = 'yes';
			}
			
#			unless ($minVrtak == 0.00) {
#					if ($minVrtak < 0.30) {
#									$flashTMP = 'yes';
#					}
#			}
			if ($pocetslepe != 0) {
							$flashTMP = 'yes';
			}
			
#			if (($panelThickness / $minVrtak) > 8) {#aspect Ratio >1:8
#					$flashTMP = 'yes';
#			}
			#if($DPSclass == 8) {
			#		$flashTMP = 'yes';
			#}
			
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/s",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "no") {
						$flashTMP = 'no';
				}
	return($flashTMP);
}

sub slepeOtvoryPrepocet {
	@layerdrill = ();
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
	my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
	my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
	my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
	my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
	if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
            $layerCount ++;
	}
	if ($rowContext eq "board" && $rowType eq "drill") {
			push(@layerdrill,$rowName);
	}
}
$countBlind = 0;
$pocetslepe = 0;
@nameBlind = ();
	foreach (@layerdrill) {
				$countBlind++;
   				if (/s([1-4][c,s])[1-9][1-9]/) {
   						push(@nameBlind,$layerdrill[$countBlind-1]);
   				$pocetslepe++;		
   				}
   	}
   	
}


sub positiveTentingY {
	$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"panel",iconic=>'no');
    $genesis->AUX('set_group', group => $genesis->{COMANS});
	$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
   	$genesis->COM ('display_layer',name=>'c',display=>'yes',number=>'1');
	$genesis->COM ('work_layer',name=>'c');
	$genesis->COM ('affected_layer',name=>"s",mode=>"single",affected=>"yes");
	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'okoli_320');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	$genesis->COM ('filter_reset',filter_name=>'popup');
	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'*okoli320*');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'s5000');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	$genesis->COM ('filter_reset',filter_name=>'popup');
	
	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>'surface');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pattern_fill',text=>'pattern_fill');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
			
	$genesis->COM ('filter_reset',filter_name=>'popup');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'punching_cross');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	
	$genesis->COM ('filter_reset',filter_name=>'popup');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'cross_outer_x');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
			
	$genesis->COM ('filter_reset',filter_name=>'popup');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'cross_outer');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
			
			
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/v2",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/fr",data_type => 'LIMITS');
						        $coverX = -($genesis->{doinfo}{gLIMITSxmin}); # 4
						        $coverY = -($genesis->{doinfo}{gLIMITSymin}); # 18
				}else{
								$coverX = 3;  
						        $coverY = 3;
				}
	$genesis->COM ('add_polyline_strt');
	$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/panel",data_type => 'PROF_LIMITS');
	$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gPROF_LIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gPROF_LIMITSymin}" - "$coverY");
	$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gPROF_LIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gPROF_LIMITSymin}" - "$coverY");
	$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gPROF_LIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gPROF_LIMITSymax}" + "$coverY");
	$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gPROF_LIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gPROF_LIMITSymax}" + "$coverY");
	$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gPROF_LIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gPROF_LIMITSymin}" - "$coverY");
	$genesis->COM ('add_polyline_end',attributes=>'no',symbol=>'r300',polarity=>'positive');
	$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
   	$genesis->COM ('display_layer',name=>'c',display=>'no',number=>'1');
	$genesis->COM ('filter_reset',filter_name=>'popup');
}
sub negativeTentingN {
	$genesis->COM ('open_entity',job=>"$jobName",type=>'step',name=>"panel",iconic=>'no');
    $genesis->AUX ('set_group', group => $genesis->{COMANS});
	$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
   	$genesis->COM ('display_layer',name=>'c',display=>'yes',number=>'1');
	$genesis->COM ('work_layer',name=>'c');
	$genesis->COM ('affected_layer',name=>"s",mode=>"single",affected=>"yes");
	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'okoli_320');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	$genesis->COM ('filter_reset',filter_name=>'popup');
	
	
		$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'*okoli320*');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'s5000');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	$genesis->COM ('filter_reset',filter_name=>'popup');
	
	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>'surface');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
	$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pattern_fill',text=>'pattern_fill');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	 $genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	
	$genesis->COM ('filter_reset',filter_name=>'popup');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'punching_cross');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	
	$genesis->COM ('filter_reset',filter_name=>'popup');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'cross_outer_x');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
			
	$genesis->COM ('filter_reset',filter_name=>'popup');
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');	
	$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'cross_outer');
	$genesis->COM ('filter_area_strt');
	$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	$genesis->COM('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_invert');
			}
	
	
	
	$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
   	$genesis->COM ('display_layer',name=>'c',display=>'no',number=>'1');
	$genesis->COM ('filter_reset',filter_name=>'popup');
}

#sub subkompenzace {
#	unless (GenesisHelper::getInfoCouldTenting($jobName, 1) == 1 and $tenting == 1) {
#  				if($cuChange == 1) {
#  						if($cuThick == 18) {
#  									$cuThick = 9;
#  									$cuChange = 0;
#  					}elsif($cuThick == 35) {
#  									$cuThick = 18;
#  									$cuChange = 0;
#  					}elsif($cuThick == 70) {
#  									$cuThick = 35;
#  									$cuChange = 0;
#  					}elsif($cuThick == 105) {
#  									$cuThick = 70;
#  									$cuChange = 0;
#  					}
#  				}
#  				if($tenting == 1) {
#  						if($cuThick == 5 or $cuThick == 9) {
#  									$cuThick = 18;
#  									$cuChange = 1;
#  					}elsif($cuThick == 18) {
#  									$cuThick = 35;
#  									$cuChange = 1;
#  					}elsif($cuThick == 35) {
#  									$cuThick = 70;
#  									$cuChange = 1;
#  					}elsif($cuThick == 70) {
#  									$cuThick = 105;
#  									$cuChange = 1;
#  					}
#  				}
#  				
#  				
#  				
#  				
#  				
#  						if ($cuThick == 5 and $predkoveni eq "no") {
#  														$cuThickForKom = '5';
#  					}elsif ($cuThick == 5 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '5K';
#  					}elsif ($cuThick == 9 and $predkoveni eq "no") { 
#  														$cuThickForKom = '9';
#  					}elsif ($cuThick == 9 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '9K';
#  					}elsif ($cuThick == 18 and $predkoveni eq "no") { 
#  														$cuThickForKom = '18';
#  					}elsif ($cuThick == 18 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '18K';
#  					}elsif ($cuThick == 35 and $predkoveni eq "no") { 
#  														$cuThickForKom = '35';
#  					}elsif ($cuThick == 35 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '35K';
#  					}elsif ($cuThick == 70 and $predkoveni eq "no") { 
#  														$cuThickForKom = '70';
#  					}elsif ($cuThick == 70 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '70K';
#  					}elsif ($cuThick == 105 and $predkoveni eq "no") { 
#  														$cuThickForKom = '105';
#  					}elsif ($cuThick == 105 and $predkoveni eq "yes") { 
#  														$cuThickForKom = '105K';
#  					}
#  			  	if ($DPSclass == 3) {
#  			  		if($typLayerSingle == 1 or $tenting == 1) {
#  					    	@ktKompenzace = qw (10 10 10 10 18 18 35 35 70 70 90 90);
#  					    }else{
#  					    	@ktKompenzace = qw (15 40 20 45 40 60 70 95 140 165 210 235);
#  					    }
#  					}elsif($DPSclass == 4) {
#  						if($typLayerSingle == 1 or $tenting == 1) {
#  					    	@ktKompenzace = qw (10 10 10 10 18 18 35 35 70 70 90 90);
#  					    }else{
#  					    	@ktKompenzace = qw (15 40 20 45 40 60 70 95 140 165 210 220);
#  					    }	
#  					}elsif($DPSclass == 5) {
#  						if($typLayerSingle == 1 or $tenting == 1) {
#  			  			@ktKompenzace = qw (10 10 10 10 18 18 35 35 70 70 90 90);
#  			  		}else{
#  			  			@ktKompenzace = qw (15 40 20 45 40 60 70 95 120 120 NP NP);
#  			  		}
#  			  	}elsif($DPSclass == 6) {
#  			  		if($typLayerSingle == 1 or $tenting == 1) {
#  					    	@ktKompenzace = qw (10 10 10 10 18 18 35 35 70 70 90 90);
#  					    }else{
#  					    	@ktKompenzace = qw (15 40 20 45 40 60 70 70 NP NP NP NP);
#  					    }
#  					}elsif($DPSclass == 7) {
#  						if($typLayerSingle == 1 or $tenting == 1) {
#  			  			@ktKompenzace = qw (10 10 10 10 18 18 30 30 30 30 30 30);
#  			  		}else{
#  			  			@ktKompenzace = qw (15 40 20 45 40 45 45 NP NP NP NP NP);
#  			  		}
#  			  	}elsif($DPSclass == 8) {
#  			  		if($typLayerSingle == 1 or $tenting == 1) {
#  			  			@ktKompenzace = qw (10 10 10 10 18 18 20 20 20 20 20 20);
#  			  		}else{
#  			  			@ktKompenzace = qw (15 20 20 20 20 20 NP NP NP NP NP NP);
#  			  		}
#  			  	}
#  			
#  			  	$cuKomCount = 0;
#  			  	foreach $itemCu ('5','5K','9','9K','18','18K','35','35K','70','70K','105','105K') {
#  			  				if ($itemCu eq $cuThickForKom) {
#  			  						$valueReduction = $ktKompenzace[$cuKomCount];
#  			  						$doCompen = 1;
#  			  				}
#  			  				$cuKomCount++;
#  			  	}
#  					if ($doCompen == 0) {
#  							$valueReduction = 0;
#  					}
#  					if ($switchMain == 1) {
#  							$enlarge_buttom->configure(-textvariable=>"$valueReduction");
#  							$enlarge_buttom->update;
#  							$labelKompenz->configure(-text=>"Filmova kompenzace pro $cuThick um med bude ");
#  							$labelKompenz->update;
#  								if ($valueReduction eq "NP"){
#  										$enlarge_buttom->configure(-textvariable=>"$valueReduction",-fg=>'red');
#  										$enlarge_buttom->update;
#  								}else{
#  										$enlarge_buttom->configure(-textvariable=>"$valueReduction",-fg=>'black');
#  										$enlarge_buttom->update;
#  								}
#  					}
#  	}
#}


sub log_file {
	my $logInfo = shift;
	my $dateString = get_current_date();
	my $timeString = get_current_time();
	my $logFile = "$ENV{'GENESIS_DIR'}/logs/${hostName}_log_file.$dateString";

	open (LOGFILE,">>$logFile");
	print LOGFILE "TIME:$timeString $logInfo\n";
	print LOGFILE "TIME:$timeString $logInfo\n";
	close (LOGFILE);
}
sub get_current_date {
	my $dateString = sprintf "%02.f%02.f%02.f",localtime->mday(),(localtime->mon() + 1),(localtime->year() + 1900);
	return ($dateString);
}
sub get_current_difference {
		my $TERM = shift;
		my @termPole = split /\./,$TERM;
		my $hourTERM = 12; # termin je pocitan do 12 hod.
		my $dayTERM = $termPole[0];
		my $mountTERM = $termPole[1] - 1;
		my $yearTERM = $termPole[2] - 1900;
		
		my $hodREAL = localtime->hour();
		my $dayREAL = localtime->mday();
		my $mountREAL = localtime->mon();
		my $yearREAL = localtime->year();

		my $unixtimeTERM = mktime (0, 0, $hourTERM, $dayTERM, $mountTERM, $yearTERM, 0, 0);
		my $unixtimeREAL = mktime (0, 0, $hodREAL, $dayREAL, $mountREAL, $yearREAL, 0, 0);
		
		my $tmp = (($unixtimeTERM - $unixtimeREAL) / 3600); #3600 prevod na hodiny
		
		while ($unixtimeTERM > $unixtimeREAL) {
					if (gmtime($unixtimeTERM)->wday() == 0 or gmtime($unixtimeTERM)->wday() == 6) {
						$tmp -= 24; # odecitam hodiny
				}
				$unixtimeTERM -= 86400; # odecitam den v sekundach
		}
#		if ($tmp < 72) { #odlozeny test o X hodin 
#			$stateOdlozenyTest = 'disable';
#			$exportNightElTest = 0;
#		}else{
#			$stateOdlozenyTest = 'normal';
#			$exportNightElTest = 1;
#		}
		$stateOdlozenyTest = 'disable';
	return ($stateOdlozenyTest);
}
sub get_current_time {
	my $dateString = sprintf "%02.f:%02.f:%02.f",localtime->hour(),localtime->min(),localtime->sec();
	return ($dateString);
}

sub get_layers {
	my $swichReturn = shift;
	my @layers = ();
	my @d_pole = ();
	my @r_pole = ();
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
	$totalRows = @{$genesis->{doinfo}{gROWname}};
	for ($count=0;$count<$totalRows;$count++) {
		if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
			$rowName = ${$genesis->{doinfo}{gROWname}}[$count];
			$rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
			$rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
			$rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
	
			if ($rowContext eq "board" && $rowType ne "drill" && $rowType ne "rout") {
				push(@layers, $rowName );
			}
			if ($rowContext eq "board" && $rowType eq "drill") {
				push(@d_pole, $rowName );
			}
			if ($rowContext eq "board" && $rowType eq "rout") {
				push(@r_pole, $rowName );
			}
		}
	}
	if ($swichReturn eq 'signal') {
			return(@layers);
	}elsif($swichReturn eq 'drill') {
			return(@d_pole);
	}elsif($swichReturn eq 'rout') {
			return(@r_pole);
	}	
}
sub removeOLDdirIPC {
		my $jobName = shift;
		my $exist;
		my $odpocet;
		my $archivePath;
		
	 			     my $jobNumber = substr($jobName,1);
					 my $odpocetTmp = $jobNumber % 500;
							if ($odpocetTmp == 0) {
									$odpocet = 0;
							}else{
									$odpocet = 1;
							}
							$jobFolder = sprintf "%05.f",((int ($jobNumber / 500) + $odpocet)* 500);
									#if ($jobFolder > 42001 ) {
											$archivePath = 'x:';
									#}else{
									#		$archivePath = 'y:';
									#}
							$cestaArchivEL  = "$archivePath/$jobFolder/${jobName}t";
									unless (-e "$cestaArchivEL") {
	  										$exist = 'N';
									}else{
											$exist = 'A';
											rmtree($cestaArchivEL);
									}
				return ($exist);
}
sub customerWithoutInfo {	
	my $customer = shift;
	my $infoT;
	
			if ($customer =~ /JSW Leiterplattenservice/) {
					$infoT = 0;
			}elsif($customer =~ /FANTEC GmbH/) {
					$infoT = 0;
			}elsif($customer =~ /[Ss][Aa][Ff][Ii][Rr][Aa][Ll]/) {
					$infoT = 0;
			}elsif($customer =~ /ECS Circuits/) {
					$infoT = 0;
			}else {
					$infoT = 1;
			}
	return($infoT)
}
sub getInfoAboutPCB {
		my $VVorDS = 0;
		my $routExist = 0;
		my $scoreExist = 0;
		my $typeDesky = 0;
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/v1",data_type=>'exists');
    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    							$VVorDS = 1;
    					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/f",data_type=>'exists');
    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    							$routExist = 1;
    					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/r",data_type=>'exists');
    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    							$routExist = 1;
    					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/score",data_type=>'exists');
    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    							$scoreExist = 1;
    					}
    			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$panelStepName/s",data_type=>'exists');
						if ($genesis->{doinfo}{gEXISTS} eq "no") {
								$typeDesky = 1;
						}
    	return($VVorDS, $routExist, $scoreExist, $typeDesky);
}
sub get_percent_inner {
					$statusLabel = sprintf "... merim vyuziti medi pro vnitrni vrstvy ...";#logText
					$status->update;
					     	$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"panel",iconic=>'no');
   						 	$genesis->AUX('set_group', group => $genesis->{COMANS});
   						 	$genesis->COM('units',type=>'mm');
		    				
		    					$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
    							$genesis->COM('sel_options',clear_mode=>'clear_after',display_mode=>'all_layers',area_inout=>'outside',area_select=>'select',select_mode=>'standard',area_touching_mode=>'include');
    							$genesis->COM('affected_filter',filter=>"(type=signal|power_ground|mixed&context=board&side=inner)");
    							$genesis->COM('get_affect_layer');
    								
    								my @innerLayerList = sort (split /\s+/,$genesis->{COMANS});
    									$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
    
    										foreach $innerOne (@innerLayerList) {
						 							$genesis->COM('copper_area',layer1=>"$innerOne",layer2=>"",drills=>'no',consider_rout=>'no',drills_source=>'matrix',thickness=>'1.5',resolution_value=>25.4,x_boxes=>3,y_boxes=>3,area=>'no',dist_map=>'no');#,out_file=>"cu_area",out_layer=>'first');
            			 							@copperAreaList = (split /\s+/,$genesis->{COMANS});
            			 							push(@persentInnerFields,$copperAreaList[1]);
            								}
    								$myCount = 0;
											foreach $inner (@innerLayerList) {
  					 								push (@persentList,"$inner=");
  					 								$persentTTT = sprintf "%2.0f",$persentInnerFields[$myCount];
  											 		push (@persentList,"$persentTTT%");
  					 								$myCount++;
   											}
   			

}
sub adjustGUI {
	if ($material =~ /clad/) {
			$typScore = 'oneDirection';
	}else{
			$typScore = 'klasik';
	}
	return ();
}
sub get_prokoveni {
	my $RETURNprokoveni = 'N';
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/s",data_type=>'exists');
    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/panel",data_type=>'SR');
							my @usedStepstmp = @{$genesis->{doinfo}{gSRstep}};
			
							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/m",data_type=>'exists');
		    						if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    							
    									foreach my $stepInPanel (@usedStepstmp) {
												$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepInPanel/m",data_type => 'FEAT_HIST',options=>'break_sr');
														if ($genesis->{doinfo}{gFEAT_HISTtotal} > 0) {
																$RETURNprokoveni = 'A';
														}
										}
										
												$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/r",data_type=>'exists');
		    											if ($genesis->{doinfo}{gEXISTS} eq "yes") {
		    													$RETURNprokoveni = 'A';
		    											}
									}else{
											$RETURNprokoveni = 'N';
									}
			}
			if (getValueNoris("$jobName", 'typ_desky') eq 'Neplatovany') {
					$RETURNprokoveni = 'N';
			}
		return ($RETURNprokoveni);
}
sub delete_older_file {
		my $jobNameTMP = shift;
		my $drill_mill = shift;
		my $odpocet;
		my $firstPath = '//192.168.2.65/f';
		my $secondPath = '//dc2.gatema.cz/S';
		my @wayArchiv = ();
		
			my $jobNumberTMP = substr($jobNameTMP,1);
			my $odpocetTmp = $jobNumberTMP % 500;
				if ($odpocetTmp == 0) {
						$odpocet = 0;
				}else{
						$odpocet = 1;
				}
			$jobFolder = sprintf "%05.f",((int ($jobNumberTMP / 500) + $odpocet)* 500);
			if ($drill_mill eq 'drill') {
					$wayArchiv[0] = "$firstPath/$jobFolder";
					$wayArchiv[1] = "$secondPath/$jobFolder";
			}else{
					$wayArchiv[0] = "$firstPath/FR-$jobFolder";
					$wayArchiv[1] = "$secondPath/FR-$jobFolder";
			}
			
			foreach my $oneWay (@wayArchiv) {
					opendir (DRILL,"$oneWay");
					my @data = readdir DRILL;
					closedir DRILL;
						foreach my $one (@data) {
								my $findIt = "$jobNameTMP";
								$findIt =~ s/[Dd]//g;
										if ($one =~ /[Dd]$findIt/g) {
												unlink "$oneWay/$one";
												log_file ("$jobName - Deleted older file - $oneWay/$one\n");
										}
						}
			}
}
sub get_info_vrtani {
	my $pocetOtvoru;
	my %holesNUM;
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/m",data_type=>'exists');
    				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    						$genesis->INFO(units => 'mm', entity_type => 'layer',entity_path => "$jobName/panel/m",data_type => 'FEAT_HIST',options => "break_sr");
											$pocetOtvoru = $genesis->{doinfo}{gFEAT_HISTpad} + 1; # pozdeji se prida cislo, proto +1
							
							$genesis->INFO(units => 'mm', entity_type => 'layer',entity_path => "$jobName/panel/m",data_type => 'TOOL',options => "break_sr");
									my @drillPole = @{$genesis->{doinfo}{gTOOLdrill_size}};
									foreach my $item (@drillPole) {
											$holesNUM{$item} = 1;
									}
					}
					my $numTypeHOLES = keys %holesNUM;
					my $pomerTMP = sprintf "%0.2f",($panelThickness / $minVrtak);# zjisteni pomeru = aspect ratio
					
		return($numTypeHOLES,$pocetOtvoru,$pomerTMP);
}
sub check_foot	{
		my $pocetFOOT;
		my @stepPanel = ();
		my $findLayF;
		
						$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/fsch",data_type=>'exists');
								if ($genesis->{doinfo}{gEXISTS} eq "yes") {
										$findLayF = 'fsch';
								}else{
										$findLayF = 'f';
								}

						$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/panel",data_type=>'exists');
		 					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
		 								$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/panel",data_type => 'SR');
				 								@stepPanel = @{$genesis->{doinfo}{gSRstep}};
					 						$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/panel",data_type => 'NUM_REPEATS');
		 									 	$pocetFOOT = $genesis->{doinfo}{gNUM_REPEATS};
		 					}
				 			foreach my $itemPCB (@stepPanel) {
		 								if ($itemPCB =~ /coupon_\d/) {
		 										$pocetFOOT -= 1;
		 								}
		 					}
				

						my $countFoot = 0;
						my $infoFile = $genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/panel/$findLayF",'data_type'=>'FEATURES',options=>'break_sr',parse=>'no');
								open (INFOf,$infoFile);
										while(<INFOf>) {
												if ($_ =~ /.foot_down/g) {
														$countFoot ++;
												}
										}
							# porovnani vyskytu patek
							if ($countFoot != $pocetFOOT) {
										$statusLabel = "Nepokracuj,nesedi pocet PATEK($countFoot ) s poctek KUSU($pocetFOOT )";
										$status->configure(-fg=>'red');
							}
}
sub freza_pred_leptanim {
		my $frezaRS;
		       $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/rs",data_type=>'exists');
        			if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							$frezaRS = A;
        			}else{
        					$frezaRS = N;
	        		}
       return($frezaRS);
}

sub merge {
	my $jobItem = shift;
	my $sourceStep = shift; 	# toto chci do targetu (r1,slepe)
	my $targetStep = shift;		# sem to budu pridavat	(m1)
	my $infoLine = shift;
	my $where = shift;			#atribut,kterym rozeznam programy frezovani / vrtani
	my $pathArchiv = getValueNoris("$jobItem", 'archiv');
	my @routCOORDtmp = ();
	my @routTOOLStmp = ();
	my @routODPADtmp = ();
	my @routCOORD = ();
	my @routTOOLS = ();

	my $pocetVrtaku = 0;
		opendir ( DIR, $pathArchiv ) || die "Error in opening dir $pathArchiv\n";
			while( (my $oneItem = readdir(DIR))){
					if ($oneItem =~ /${targetStep}$/) {
			 				open (AREAFILE,"$pathArchiv/$oneItem");
            					while (<AREAFILE>) {
            						if ($_ =~ /T\d{1,2}D\d{1,3}/) {
		            						$pocetVrtaku ++;
        		    				}
            					}
            				close AREAFILE;
					}
			}
		closedir DIR;
	my $posledniTools = $pocetVrtaku;
	$pocetVrtaku ++;
	
		opendir ( DIR, $pathArchiv ) || die "Error in opening dir $pathArchiv\n";
			while( (my $oneItem = readdir(DIR))){
					if ($oneItem =~ /${sourceStep}$/) {
			 				open (AREAROUT,"$pathArchiv/$oneItem");
            					while (<AREAROUT>) {
            							if ($_ =~ /^[Xx,Yy]/) {
            							push(@routCOORDtmp, $_);
            						}elsif ($_ =~ /^T\d{1,2}/) {
            							push(@routTOOLStmp, $_);
            						}else{
            							push(@routODPADtmp, $_);
	            					}
            					}
            				close AREAROUT;
					}
			}
		closedir DIR;
		
		
		##odmazani coordXY, ktere byly ziskany z hlavicky
		my $icount = 0;
		my @editCOORD = @routCOORDtmp;
				while (1) {
						if ($routCOORDtmp[$icount] =~ /T\d{1,2}/) {
								@routCOORDtmp = @editCOORD;
								last;
	        			}else{
	        					shift(@editCOORD);
				        }
		    		$icount ++;
				}
		##koncim s odmazavani hlavicky #####################
		
		
		
		
	my $countCOORD = $pocetVrtaku; #navyseni posledniho pouziteho nastroje v cilovem file.
	my $countTOOLS = $pocetVrtaku;


   ##prepsani v coodrinatech Txx na aktualni hodnotu
	foreach (@routCOORDtmp) {
			unless ($_ =~ /\d[Dd]/) {
				unless ($_ =~ /[XxYy]\d{1,3}\.\d{1,3}T0$/) {
						if ($_ =~ /T(\d{1,2})T0$/) {
        						$_ =~ s/T$1/T$countCOORD/g;
        						$countCOORD++;
	        			}elsif ($_ =~ /T(\d{1,2})$/) {
        						$_ =~ s/T$1/T$countCOORD/g;
        						$countCOORD++;
	        			}
	        	}
		        chomp ($_);
        		push (@routCOORD,$_);
	        }
	}
   ##koncim s prepsani v coodrinatech Txx na aktualni hodnotu #####################
	
   ##prepsani v tabulce nastroju Txx na aktualni hodnotu
	foreach (@routTOOLStmp) {
			if ($_ =~ /T(\d{1,2})D\d{1,3}/) {
        			$_ =~ s/T$1/T$countTOOLS/g;
        			$countTOOLS++;
        	}
        chomp ($_);
        push (@routTOOLS, $_);
	}
   ##koncim s prepsani v tabulce nastroju Txx na aktualni hodnotu #####################
	
	if ($where eq 'drill') {
  				#### vlozeni do vrtani 
  				open (REPORT,">>$pathArchiv/${jobItem}${targetStep}_tmp");
  				opendir ( DIR, $pathArchiv ) || die "Error in opening dir $pathArchiv\n";
  						while( (my $oneItem = readdir(DIR))){
  								#$genesis->PAUSE("$oneItem");
  								if ($oneItem =~ /${targetStep}$/) {
  						 				open (AREAM1,"$pathArchiv/$oneItem");
  			         						while (<AREAM1>) {
  			         								if ($_ =~ /[Pp][Rr][Ii][Dd][Ee][Jj] [Hh][Ll][Ii][Nn][Ii][Kk]/g) {
  			         										print REPORT "\n";
  			         										print REPORT "M47,$infoLine\n\n";
  			         										
  			         										foreach my $lineCoor (@routCOORD) {
  			         												print REPORT "$lineCoor\n";
  			         										}
  					            							print REPORT "\n";
  			     		    							print REPORT "M47,Pridej Hlinik\n\n";
  			         							}elsif($_ =~ /T${posledniTools}D\d{1,3}/) {
  			         									print REPORT "$_";
  			         									
  			         										foreach my $lineTools (@routTOOLS) {
  			         												print REPORT "$lineTools\n";
  			         										}
  			         							}else{
  			         									print REPORT "$_";
  			         							}
  			         						}
  			         				close AREAM1;
  								}
  					}
  				closedir DIR;
  				close REPORT;
  	}elsif($where eq 'rout') {
  				#### vlozeni do frezovani
  				open (REPORT,">>$pathArchiv/${jobItem}${targetStep}_tmp");
  				opendir ( DIR, $pathArchiv ) || die "Error in opening dir $pathArchiv\n";
  						while( (my $oneItem = readdir(DIR))){
  								#$genesis->PAUSE("$oneItem");
  								if ($oneItem =~ /${targetStep}$/) {
  						 				open (AREAM1,"$pathArchiv/$oneItem");
  			         						while (<AREAM1>) {
  			         								if ($_ =~ /X.\d{1,3}\.\d{1,3}Y.\d{1,3}\.\d{1,3}T1/g) {
  			         										print REPORT "\n";
  			         										print REPORT "M47,$infoLine\n\n";
  			         										
  			         										foreach my $lineCoor (@routCOORD) {
  			         												print REPORT "$lineCoor\n";
  			         										}
  			         										
  					            							print REPORT "G82\n\n";
  			     		    							print REPORT "$_";
  			         							}elsif($_ =~ /T${posledniTools}D\d{1,3}/) {
  			         									print REPORT "$_";
  			         									
  			         										foreach my $lineTools (@routTOOLS) {
  			         												print REPORT "$lineTools\n";
  			         										}
  			         							}else{
  			         									print REPORT "$_";
  			         							}
  			         						}
  			         				close AREAM1;
  								}
  					}
  				closedir DIR;
  				close REPORT;
	}
	unlink("$pathArchiv/$jobItem$targetStep");
	rename("$pathArchiv/${jobItem}${targetStep}_tmp","$pathArchiv/$jobItem$targetStep");
}
sub check_repeat_tools {
	my $jobItem = shift;
	my $sourceStep = shift;
	my $pathArchiv = getValueNoris("$jobItem", 'archiv');

	my %hashTools = ();

	my $pocetVrtaku = 0;
		opendir ( DIR, $pathArchiv ) || die "Error in opening dir $pathArchiv\n";
			while( (my $oneItem = readdir(DIR))){
					if ($oneItem =~ /${sourceStep}$/) {
			 				open (AREAFILE,"$pathArchiv/$oneItem");
            					while (<AREAFILE>) {
            						if ($_ =~ /(T\d{1,2})D\d{1,3}/) {
		            						$pocetVrtaku ++;
		            						$hashTools{$1} = 1;
        		    				}
            					}
            				close AREAFILE;
					}
			}
		closedir DIR;
	my $posledniTools = $pocetVrtaku;
	my @tmpPole = keys (%hashTools);
	my $countOFhash = @tmpPole;
	my $errorView = 0;
	unless ($posledniTools == $countOFhash) {
			$errorView = 1;
			open (STATIST1,">>r:/Archiv/report_tpv/check_repeat_tools");
			print STATIST1 "$jobItem\n";
			close STATIST1;
	}
	return ($errorView);
}
sub get_exist_CS {
		my $findLayerC = shift;
		my $findLayerS = shift;
		my $tmpInfo = 0;
		
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/$findLayerC",data_type=>'exists');
				my $Exist_C = $genesis->{doinfo}{gEXISTS};
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/$findLayerS",data_type=>'exists');
				my $Exist_S = $genesis->{doinfo}{gEXISTS};
	
						
						if (($Exist_S eq "yes") and ($Exist_C eq "yes")) {
								$tmpInfo = 2;
						} elsif (($Exist_S eq "yes") and ($Exist_C eq "no")) {
								$tmpInfo = "S";
						} elsif (($Exist_S eq "no") and ($Exist_C eq "yes")) {
								$tmpInfo = "C";
						}
	return($tmpInfo);
}

sub _MakeStackup {
				unless ($constClass) {
						$constClass = CamAttributes->GetJobAttrByName($genesis, $jobName, 'pcb_class');
				}
				my $newThicknessCopper = HegMethods->GetOuterCuThick($jobName);
				my @innerCuUsage = GenesisHelper::getUseAreaCuInner($jobName, 0);
				my $countOfLayer = CamJob->GetSignalLayerCnt($genesis, $jobName);
				
				
				unless ($newThicknessCopper) {
						my $result = -1; #return input value
						new SimpleInputForm( "Chybi tloustka medi, zadej....", \$result);
				
						$newThicknessCopper = $result;
				}
				
				
				
				my @btns = ("Pokracovat - slozeni jsem vytvoril", "Vytvorit standardni slozeni"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
  				my $result = -1;

  				my @messField = ("Pocet vrstev = $countOfLayer, Vrstva medi = $newThicknessCopper, Konstrukcni trida = $constClass, Vyuziti medi = @innerCuUsage;
  								");
  								
  				if (HegMethods->GetPcbIsPool($jobName) == 1) {
  										StackupDefault->CreateStackup($jobName, $countOfLayer, \@innerCuUsage, $newThicknessCopper, $constClass);
  				}else{
	  					new MessageForm( Enums::MessageType->WARNING, \@messField, \@btns, \$result);
  								if ($result == 1) {
  										print STDERR 'jsem zde';
  										StackupDefault->CreateStackup($jobName, $countOfLayer, \@innerCuUsage, $newThicknessCopper, $constClass);
	  							}else{
	  									print STDERR 'jsem ajjj';
		  						}
	  					
	  			}
}

sub _CheckExistStackup {
			my $idJob = shift;
			my $pathStackup = 'r:/PCB/pcb/VV_slozeni';
			my $tmpExist = 0;

			opendir ( DIRSTACKUP, $pathStackup);
					while( (my $jobItem = readdir(DIRSTACKUP))){
							$idJob = lc $idJob;
							if ($jobItem =~ /$idJob/) {
										$tmpExist = 1;
							}
							$idJob = uc $idJob;
							if ($jobItem =~ /$idJob/) {
										$tmpExist = 1;
							}
					}
			closedir DIRSTACKUP;
				
		return ($tmpExist);
			
}
	
	
	
	
	
sub _CustomerPanel {
	$genesis->COM ('set_step',name=>'o+1');
	$genesis->COM('units',type=>'mm');
	
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/mc",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
   		   		$genesis->COM ('display_layer',name=>'mc',display=>'yes',number=>'1');
				$genesis->COM ('work_layer',name=>'mc');
				$genesis->COM ('snap_mode',mode=>'intersect');
    	}
	
	$coordine = $genesis->MOUSE('r Vyber rozmer jedne desky');
	@poleCoordine = split /\s/,$coordine;
		my $dimSingleX = sprintf "%3.3f",($poleCoordine[2] - $poleCoordine[0]);
		my $dimSingleY = sprintf "%3.3f",($poleCoordine[3] - $poleCoordine[1]);
		$genesis -> COM ('zoom_home');
	
	$genesis-> PAUSE ("Panel zakaznika - zjisti nasobnost a spravny rozmer");
	
	$genesis->COM('units',type=>'mm');
			$mainPanel = MainWindow->new();
			$mainPanel ->minsize(qw(350 40));
			$mainPanel ->title('Parametry zakaznickeho panelu');
	  		$mainPanel ->Frame(-width=>100, -height=>20)->pack(-side=>'top',-fill=>'both');
	  		$mainPanel ->Label(-text=>"Zadej parametry",-font=>"Arial 10 bold")->pack(-padx => 5, -pady => 5,-side=>'top');
	  			$mainDva = $mainPanel->Frame(-width=>100, -height=>20)->pack(-side=>'top',-fill=>'both');
	  				$dimMain = $mainDva->LabFrame(-width=>100, -height=>20,-label=>'Rozmer jedne desky')->pack(-side=>'left',-fill=>'both');
	  					$xSingle = $dimMain -> LabEntry(-width=>10,-font=>'arial 10',-label=>'X',-bg=>'white')->pack(-padx => 5, -pady => 5,-side=>'left');
	  					$ySingle = $dimMain -> LabEntry(-width=>10,-font=>'arial 10',-label=>'Y',-bg=>'white')->pack(-padx => 5, -pady => 5,-side=>'left');
	  					 $xSingle->insert('end',"$dimSingleX");
	  					 $ySingle->insert('end',"$dimSingleY");
	  				$nasMain = $mainDva->LabFrame(-width=>100, -height=>20,-label=>'Nasobnost panelu')->pack(-side=>'right',-fill=>'both');	
	  					$nasMpanel = $nasMain -> LabEntry(-width=>6,-font=>'arial 10',-label=>'Celkem kusu',-bg=>'white')->pack(-padx => 5, -pady => 5,-side=>'left');
	  		
	  					
	  		$mainPanel->Button(-text => "Pokracovat",-command=>\&__getInfoPanel)->pack(-padx => 10, -pady => 5,-side=>'bottom');
	  		$mainPanel->waitWindow;
	  	return ($xSingle, $ySingle, $nasMpanel);
}
sub __getInfoPanel {
	$xSingle = $xSingle -> get;
	$ySingle = $ySingle -> get;
	$nasMpanel = $nasMpanel -> get;
	$mainPanel->destroy;
}

sub _GetXMLfile {
		my $job = shift;
		my $multiPath = 'r:/PCB/pcb/VV_slozeni';
		my $xmlFileVV = 0;
		my $jobLower = lc($job);
		my $jobUpper = uc($job);
		
					   	opendir ( DIRXML, $multiPath);
							while((my $oneItem = readdir(DIRXML))){
									if ($oneItem =~ /^$jobLower/ or $oneItem =~ /^$jobUpper/) {
										 $xmlFileVV = $oneItem;
										 last;
									}
							}
						closedir DIRXML;
			return ("$multiPath/$xmlFileVV");
}
sub _GetCuThick {
		my $path = shift;
		my %hashCopper = ();
		my %hashCopperReturn = ();
			$katalogStackup = XMLin("$path",ForceArray => 0, KeepRoot => 0, KeyAttr => {item => 'element'});
			#print Dumper $katalogStackup;

			my $countOfelem = @{$katalogStackup->{element}};

			my $pocetVrstev = 0;
			for ($i=0; $i<$countOfelem; $i++){
					if ($katalogStackup->{element}->[$i]->{type} eq 'Copper') {
							$pocetVrstev++;
							$hashCopper{"v$pocetVrstev"} = __id_convert($katalogStackup->{element}->[$i]->{id});
    				}
			}
			foreach my $item (sort keys %hashCopper) {
					if ($item eq 'v1') {
						$hashCopperReturn{'c'} = $hashCopper{$item};
				}elsif($item eq "v$pocetVrstev") {
						$hashCopperReturn{'s'} = $hashCopper{$item};
				}else{	
						$hashCopperReturn{$item} = $hashCopper{$item};
				}
			}
		return(%hashCopperReturn);
}
sub __id_convert {
	my $id = shift;
	my $copper = 0;
					if($id == 1) {
							$copper = 5;
				}elsif($id == 2) {
							$copper = 9;
				}elsif($id == 4) {
							$copper = 18;
				}elsif($id == 5) {
							$copper = 35;
				}elsif($id == 8) {
							$copper = 70;
				}elsif($id == 9) {
							$copper = 105;
				}
	return($copper);
}

sub _ArchivInputFiles {
	my $job = shift;
	
			dirmove ("c:/pcb/$job","$cesta_nif/Zdroje/data/");
}
sub _SetMaskSilkHelios {
		my $jobId = shift;
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/pc",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk");
					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/ps",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk_typ");
					
					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/mc",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_c_1");
					}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/ms",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_s_1");
					}

}




sub _StatusTentingUseability {
			my $jobId = shift;
			my $tmpStatus = 'normal';
				
					# Check big holes
					#--------------------------------------------------------
							if (GenesisHelper::getInfoCouldTenting($jobId, 1) == 1) {
										$tmpStatus = 'disable';
							}
					
					
					# Check if there is blind via
					#---------------------------------------------------------
							my $inCAM = InCAM->new();
							my @pltLayer = CamDrilling->GetPltNCLayers( $inCAM, $jobId );

							my @blind = grep {$_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot} @pltLayer;
							if(scalar(@blind)){
										$tmpStatus = 'disable';
							}
							
					$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/rs",data_type=>'exists');
							if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
										$tmpStatus = 'disable';
							}
							
							
					# Check if there is 105cu thickness
					#-----------------------------------------------------------------------------------------------------------------------------------------
					my $cuThick = 0;
					my $maximalCu = 70;
					if (HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy') {
  								my $pathToXML = _GetXMLfile($jobId);
								my %cuThickHash = _GetCuThick($pathToXML);
									$cuThick = $cuThickHash{'c'};
					}else{
							    	$cuThick = HegMethods->GetOuterCuThick($jobId);
					}
					
					if ($cuThick > $maximalCu) {
								$tmpStatus = 'disable';
					}
					
					#-----------------------------------------------------------------------------------------------------------------------------------------
					
		return($tmpStatus);
}
sub _DeletePatternFrame {
				my $pcbId = shift;
				my $patternExist = 0;
				my @layers = qw (c s);
				
				$genesis -> COM ('clear_layers');
				
				foreach my $item (@layers) {
						$genesis->INFO(entity_type=>'layer',entity_path=>"$pcbId/panel/$item",data_type=>'exists');
							if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									
										$genesis->COM ('display_layer',name=>"$item",display=>'yes',number=>'1');
		    							$genesis->COM ('work_layer',name=>"$item");
		    							
		    							
		    							
		    							$genesis->COM ('set_filter_polarity',filter_name=>'',positive=>'yes',negative=>'no');
		    							
										$genesis->COM ('filter_reset',filter_name=>'popup');
  										$genesis->COM ('set_filter_type',filter_name=>'',lines=>'no',pads=>'no',surfaces=>'yes',arcs=>'no',text=>'no');
  										$genesis->COM ('set_filter_polarity',filter_name=>'',positive=>'yes',negative=>'no');
  										$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'no',attribute=>'.pattern_fill',min_int_val=>'0',max_int_val=>'0',min_float_val=>'0',max_float_val=>'0',option=>'',text=>'');
  										$genesis->COM ('adv_filter_set',filter_name=>'popup',active=>'yes',limit_box=>'no',bound_box=>'no',srf_values=>'no',srf_area=>'yes',min_area=>'8000',max_area=>'200000',mirror=>'any',ccw_rotations=>'');
  										$genesis->COM ('filter_area_strt');
  										$genesis->COM ('filter_area_end',filter_name=>'popup',operation=>'select');
  										$genesis->COM ('get_select_count');
												if ($genesis->{COMANS} > 0) {
															$genesis->COM ('sel_delete');
															$patternExist = 1;
												}
										$genesis->COM ('filter_reset',filter_name=>'popup');
										$genesis->COM ('display_layer',name=>"$item",display=>'no',number=>'1');
							}
				}
						
				
		return($patternExist);

}
sub _ChangePolarityFeatures {
			my $pcbId = shift;
			my @layers = qw (c s);
			
			foreach my $item (@layers) {
							$genesis->INFO(entity_type=>'layer',entity_path=>"$pcbId/panel/$item",data_type=>'exists');
								if ($genesis->{doinfo}{gEXISTS} eq "yes") {
										$genesis->COM ('clear_layers');
										$genesis->COM ('filter_reset',filter_name=>'popup');
										$genesis->COM ('display_layer',name=>"$item",display=>'yes',number=>'1');
										$genesis->COM ('work_layer',name=>"$item");
										
										$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.geometry',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'centre*');
										$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.geometry',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'OLEC*');
										$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.geometry',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'punch*');
										
										$genesis->COM ('set_filter_and_or_logic',filter_name=>'popup',criteria=>'inc_attr',logic=>'or');
										$genesis->COM ('filter_area_strt');
										$genesis->COM ('filter_area_end',filter_name=>'popup',operation=>'select');
										$genesis->COM ('get_select_count');
												if ($genesis->{COMANS} > 0) {
														$genesis->COM ('sel_invert');
												}
										$genesis->COM ('display_layer',name=>"$item",display=>'no',number=>'1');
										$genesis->COM ('filter_reset',filter_name=>'popup');					
										$genesis->COM ('affected_layer',mode=>'all',affected=>'no');
										$genesis->COM ('clear_layers');
							}
			}
}

sub _ControlNifRead {
	my $jobId = shift;
	my $outputDir = shift;
	
  			unless (-e "$outputDir/$jobId.bac") {
  						if (-e "$outputDir/$jobId.nif") {
  								open (NIFREAD,"$outputDir/$jobId.nif");
  										 while (<NIFREAD>) {
  								 			   if ($_ =~ /typ_dps=pool/) {
  														cp ("$outputDir/$jobId.nif","$outputDir/${jobId}.bac");
  						                		}
  						         		}
  							    close NIFREAD;
  						}
  			}
}
sub _CheckAndChangeFsch {
		my $jobId = shift;
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobId/panel/fsch",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							$genesis->COM('matrix_layer_type',job=>"$jobId",matrix=>'matrix',layer=>'fsch',type=>'rout');
							$genesis->COM('matrix_layer_context',job=>"$jobId",matrix=>'matrix',layer=>'fsch',context=>'board');				
				}
	
}