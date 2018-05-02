#!/usr/bin/perl

use warnings;

use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Tk::LabFrame;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path qw( rmtree );

use LoadLibrary;
#use GenesisHelper;
use GeneralHelper;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';

use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckWarn';
use aliased 'Packages::Input::HelperInput';
use aliased 'Packages::GuideSubs::Netlist::NetlistControl';

use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamFilter';

use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::ProductionPanel::PoolStepPlacement';
use aliased 'Packages::ProductionPanel::CheckPanel';
use aliased 'Packages::ProductionPanel::CounterPoolPcb';

use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
use aliased 'Packages::Routing::PilotHole';
use aliased 'Packages::Routing::PlatedRoutAtt';
use aliased 'Packages::Routing::PlatedRoutArea';
 
use aliased 'Packages::GuideSubs::Scoring::DoFlattenScore';
use aliased 'Packages::Stackup::StackupDefault';
use aliased 'Packages::GuideSubs::Routing::CheckRout';
use aliased 'Packages::Compare::Layers::CompareLayers';
use aliased 'Packages::CAMJob::SolderMask::PreparationLayout';

use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';

use aliased 'Enums::EnumsProducPanel';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmpPool';

use aliased 'Managers::MessageMngr::MessageMngr';



unless ($ENV{JOB}) {
	$jobName = shift;
	$file = shift;
	$constClass = shift;
	$maska01 = shift;
	$runCSV = shift;
	$panelSizeCheck = $ARGV[0] . ' ' . $ARGV[1] . ' ' . $ARGV[2];
}else{
	$jobName = "$ENV{JOB}";
}

my $inCAM = InCAM->new();
my @errorMessageArr = ();
my @warnMessageArr = ();
my $panelSet = 0;

chomp $panelSizeCheck;


_CheckTypeOfPcb($jobName);

#Remove attr .feed from layer F
_DelAttrFeed();


# When there are uncover soldermask of drilling only from one side, then subroutine perform uncover sodermask even on the other side.
_SolderMaskUncoverVia($jobName);


 #Check if there is attribut customer_panel
if (CamAttributes->GetJobAttrByName($inCAM, $jobName, 'customer_panel') eq 'yes') {			
			$panelSet = 'custPanel';
}

# Here change negative polarity from Genesis to positive - needs INCAM
_ChangePolarityMask($jobName);

# 1) Add attribute plated rout area to step o,o+1 to all plated rout layers
# 2) Delete smd attributes from pads, where is plated rout
PlatedRoutAtt->SetRoutPlated($inCAM, $jobName);


$dtCode{HegMethods->GetDatacodeLayer($jobName)} = 1 ;


# pocet unikatnich stepu v mpanelu, zorpoznani SADY
if (CamHelper->StepExists( $inCAM, $jobName, 'mpanel')){
			my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobName, "mpanel" );

			if ( scalar(@uniqueSR) > 1 ) {
				# asi je to sada, zaskrnout sadu
						$panelSet = 'sadaPanel';
			}
}


my @pole = HegMethods->GetAllByPcbId("$jobName");
my $outputDir = $pole[0]->{'archiv'};
   $outputDir =~ s/\\/\//g;


unless ($panelSizeCheck == 0) {
		_Panelize($panelSizeCheck);
}else{
		# Check correct rout
		_CheckRout($jobName);
		
		
		# Copy all rout layers to solder mask
		PreparationLayout->CopyRoutToSolderMask($inCAM, $jobName, 'o+1' );
				
		if ( CamHelper->StepExists( $inCAM, $jobName, 'mpanel' ) ) { 
 					PreparationLayout->CopyRoutToSolderMask($inCAM, $jobName, 'mpanel' );
 					$inCAM->COM ('set_step',name=> 'o+1');
 		}
 			
 			
		# check CompareLayers
		my %att = CamAttributes->GetStepAttr( $inCAM, $jobName, 'o+1' );

			if ( $att{"comp_lay_done"} eq 'no' ) {
						CompareLayers->CompareOrigLayers($inCAM, $jobName);
						CamAttributes->SetStepAttribute( $inCAM, $jobName, 'o+1', 'comp_lay_done', 'yes' );
			}else {
				unless ( _GUIcompLayDone($jobName) ) {
						# Check will be process again
						CompareLayers->CompareOrigLayers($inCAM, $jobName);
				}
			}
		# Run panelize GUI
		_GUIpanelizace();
		
}


sub _GUIpanelizace {
		$main = MainWindow->new;
		$main->title('Panelizace');
			unless ($constClass) {
						($constClass, $wroteChackList) = _GetExistkonClass($jobName);
			}
			
			$mainFrame= $main->Frame(-width=>300, -height=>200)->pack(-side=>'top',-fill=>'both');
				$topFrame = $mainFrame->Frame(-width=>100, -height=>70)->pack(-side=>'top',-fill=>'both');
						$topFrameLeft = $topFrame->Frame(-width=>100, -height=>70)->pack(-side=>'left',-fill=>'both',-expand => "True");
									
									$topFrameLeft->Label(-text=>"Reference desky : $jobName",-font=>"Arial 10")->pack(-padx => 3, -pady => 3,-side=>'top');

									$construct_class_entry = $topFrameLeft->BrowseEntry(
														-label=>"Konstrukcni trida",
														-variable=>\$constClass,
														-listcmd=>\&_fill_const_list,
														-state=>"readonly",
														-listwidth=>50,
														-width=>10, 
														-font=>"Arial 10",
														-fg=>'red')
														->pack(-padx=>3,-pady=>3,-side=>'top',-fill=>'both');
														
													
									$topFrameLeft->Label(-text=>"Zkontrolovano v......" . _GetConstrClass($jobName , 'o+1') . $wroteChackList ,-font=>"Arial 10")->pack(-padx => 3, -pady => 3,-side=>'top');
														
						$topFrameRight = $topFrame->Frame(-width=>100, -height=>70)->pack(-side=>'right',-fill=>'both',-expand => "True");
											if ($runCSV eq 'csv') {
													if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
															$topFrameRight->Checkbutton(-text=>EnumsProducPanel->SIZE_MULTILAYER_SMALL,
																						-variable=>\$panelSizeCheck,
																						-onvalue=>EnumsProducPanel->SIZE_MULTILAYER_SMALL)
																						->pack(-side=>'top',-fill=>'both',-padx => 5, -pady => 2);
															$topFrameRight->Checkbutton(-text=>EnumsProducPanel->SIZE_MULTILAYER_BIG,
																						-variable=>\$panelSizeCheck,
																						-onvalue=>EnumsProducPanel->SIZE_MULTILAYER_BIG)
																						->pack(-side=>'top',-fill=>'both',-padx => 5, -pady => 2);
													}else{
															$topFrameRight->Checkbutton(-text=>EnumsProducPanel->SIZE_STANDARD_SMALL,
																						-variable=>\$panelSizeCheck,
																						-onvalue=>EnumsProducPanel->SIZE_STANDARD_SMALL)
																						->pack(-side=>'top',-fill=>'both',-padx => 5, -pady => 2);
															$topFrameRight->Checkbutton(-text=>EnumsProducPanel->SIZE_STANDARD_BIG,
																						-variable=>\$panelSizeCheck,
																						-onvalue=>EnumsProducPanel->SIZE_STANDARD_BIG)
																						->pack(-side=>'top',-fill=>'both',-padx => 5, -pady => 2);
													}
											}

				$middleFrame1 = $mainFrame->Frame(-width=>100, -height=>70)->pack(-side=>'top',-fill=>'both');
						$mypodframe = $middleFrame1->LabFrame(
														-width=>'300', 
														-height=>'100',
														-label=>"Poznamky k zakaznikovi",
														-font=>'normal 9 {bold }',
														-labelside=>'top',
														-bg=>'lightgrey',
														-borderwidth=>'3')
														->pack(-side=>'top',-fill=>'both');
														
									$mypodframe ->Label(-textvariable=>\HegMethods->GetTpvCustomerNote($jobName), -fg=>"blue")->pack(-side=>'top',-fill=>'both');
		if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
				$middleFrame3 = $mainFrame->Frame(-width=>100, -height=>70)->pack(-side=>'top',-fill=>'both',-expand => "True");
				 				my @innerList = _GetInnerLayers($jobName);
									$middleFrame3->Label(-text=>"Inner Layer Name")->grid(-column=>0,-row=>1,-sticky=>"news",-columnspan=>3);
								my $rowCount = 2;
										foreach my $innerLayer (@innerList) {
    													$middleFrame3->Label(-text=>"$innerLayer : ")->grid(-column=>0,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
    													${$innerLayer._button} = $middleFrame3->Button(-text=>"top",-command=>[\&change_side,"$innerLayer"])->grid(-column=>1,-row=>"$rowCount",-sticky=>"news",-columnspan=>5);
    											$rowCount ++;
										}
		}
				
				
				
		if (HegMethods->GetPcbIsPool($jobName) == 1 and $runCSV ne 'csv') {
		   		$middleFrame3 = $mainFrame->Frame(-width=>100, -height=>70)->pack(-side=>'top',-fill=>'both',-expand => "True");
		   				$poolLabFrame = $middleFrame3->LabFrame(
		   														-width=>300,
		   														-height=>100,
		   														-label=>"POOLING",
		   														-font=>'normal 9 {bold }',
		   														-fg=>'red')
		   														->pack(
		   														-side=>'top',
		   														-fill=>'both',
		   														-expand => "True");
		   														
		   				#
						# MASKA 0.1
						my $attrFrame = $poolLabFrame->Frame(
												-width=>100, 
												-height=>50)
												->pack(
												-side=>'left',
												-fill=>'both',
												-expand => "True");
									my $attrLabFrame = $attrFrame->LabFrame(
															-width=>100, 
															-height=>50,
															-label=>"ATRIBUTY",
															-font=>'normal 9 {bold }')
															->pack(
															-padx=>10,
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
#												$attrLabFrame->Checkbutton(
#																		-text => "Wrong data",
#																		-variable=>\$wrongData,
#																		-fg=>'white',
#																		-bg=>'grey',
#																		-selectcolor=>'red',
#																		-indicatoron=>'')
#																		->pack(
#																		-side=>'top',
#																		-fill=>'both',
#																		-padx=>3,
#																		-pady=>1
#																		);

										#
			 							# POZNAMKY
			 							my $noteFrame = $poolLabFrame->Frame(
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
			 													
			 					# ATRIBUTY
								my $datacodeFrame = $poolLabFrame->Frame(-width=>50, -height=>20)->pack(-side=>'right',-fill=>'y',-expand => "True");				
		   										my $datacodeLabFrame = $datacodeFrame->LabFrame(
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
												 				$datacodeLabFrame->Checkbutton(
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
										# ULLOGO 
										#my $ullogoFrame = $poolLabFrame->Frame(-width=>100, -height=>70)->pack(-side=>'left',-fill=>'both',-expand => "True");
										my $ullogoLabFrame = $datacodeFrame->LabFrame(
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
															$ullogoLabFrame->Checkbutton(
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
																		
		}
		
		
				$middleFrame2 = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top',-fill=>'both');
											$middleFrame2Top = $middleFrame2->LabFrame(
																	-label=>"Zjistene chyby",
																	-width=>100, 
																	-height=>50)
																	->pack(
																	-side=>'left',
																	-fill=>'both',
																	-expand => "True");
																	
											my $rowStart=0;
											_CheckArcInSilk($jobName);
											_CheckTableDrill($jobName);
											_CheckTableRout($jobName);
											_CheckBigestHole($jobName);
										   #_CheckminimalToolRout($jobName); Now this error is checked in LayerCheckWarn
											_CheckMpanelExistPool($jobName);
											_CheckPlgcPlgs($jobName);
											
											
											
											my $messWarn = "";
											my $resultWarn = LayerCheckWarn->CheckNCLayers( $inCAM, $jobName, "o+1", undef, \$messWarn );
											if ($resultWarn == 0) {
													push @warnMessageArr, $messWarn;
											}
											
											# contain error messages
											my $mess = "";
											#
											## Return 0 = errors, 1 = no error
											my $result = LayerCheckError->CheckNCLayers( $inCAM, $jobName, "o+1", undef, \$mess );
											if ($result == 0) {
													push @errorMessageArr, $mess;
											}
											
											my @errorWarnigsList = ();
											push @errorWarnigsList, @warnMessageArr, @errorMessageArr;
											
											
											$tmpFrameInfo = $middleFrame2Top->Frame(-width=>100, -height=>10)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
											foreach my $item (@errorWarnigsList) {
																	$tmpFrameInfo ->Label(-textvariable=>\$item, -fg=>"red")->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"w");
																	$rowStart++;
											}
				
				unless (HegMethods->GetPcbIsPool($jobName) == 1) {							
						$middleFrame3 = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top',-fill=>'both');
						$middleFrame3->Checkbutton(
											-text => "PANEL - SADA",
											-variable=>\$panelSet,
											-onvalue=>"sadaPanel", 
											-fg=>'white',
											-bg=>'grey',
											-selectcolor=>'red',
												-indicatoron=>'')
											->pack(-side=>'top',-fill=>'both');													
				}
				
				unless (HegMethods->GetPcbIsPool($jobName) == 1) {							
						$middleFrame4 = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top',-fill=>'both');
						$middleFrame4->Checkbutton(
											-text => "PANEL ZAKAZNIKA",
											-variable=>\$panelSet,
											-onvalue=>"custPanel",
											-fg=>'white',
											-bg=>'grey',
											-selectcolor=>'red',
												-indicatoron=>'')
											->pack(-side=>'top',-fill=>'both');													
				}
											
				my $condition = 'normal';
				if (scalar @errorMessageArr or HegMethods->GetPcbIsPool($jobName) == 0) {
									$condition = 'disable';
				}
				$botFrame = $mainFrame->Frame(-width=>100, -height=>70)->pack(-side=>'bottom',-fill=>'both');	
							$botFrameLeft = $botFrame->Frame(-width=>50, -height=>20)->pack(-side=>'left',-fill=>'both');	
									$botFrameLeft->Button(
						  						-width=>'15',
						  						-text => "POSLAN DOTAZ",
						  						-command=> sub {_SendQuestion($jobName)},
						  						-bg=>'grey',
						  						-state=>"normal")
						  						->pack(-fill=>'both',
						  						-padx => 1, 
						  						-pady => 5,
						  						-side=>'top');
									
									$botFrameLeft->Button(
						  						-width=>'15',
						  						-text => "CHECK POOL",
						  						-command=> sub {_CheckPool($jobName)},
						  						-bg=>'grey',
						  						-state=>"$condition")
						  						->pack(-fill=>'both',
						  						-padx => 1, 
						  						-pady => 5,
						  						-side=>'top');

						  						
							
							$botFrameRight = $botFrame->Frame(-width=>50, -height=>20)->pack(-side=>'right',-fill=>'both');	
						  			$tl_no=$botFrameRight->Button(
						  						-width=>'70',
						  						-text => "POKRACOVAT K PANELIZACI",
						  						-command=> sub {_Panelize($panelSizeCheck)},
						  						-bg=>'grey')
						  						->pack(-fill=>'both',-padx => 1, -pady => 5,-side=>'right');
	$main->MainLoop;
	
}

sub _fill_const_list {
    $construct_class_entry->delete(0,'end');
    foreach my $className (qw /3 4 5 6 7 8/) {
        $construct_class_entry->insert('end',"$className");
    }
}
sub _CheckPool{
			my $jobId = shift;
			
			# Set 
			_SetMaskSilkHelios($jobId, 'o+1');
			
			# remove all layers with +++
			CamLayer->RemoveTempLayerPlus($inCAM,$jobId);
			

 						# Set attribut construction class
 						CamJob->SetJobAttribute($inCAM, 'pcb_class', $constClass, $jobId);
 						
 						# Set user name to attribute
 						_SetAttrUser($jobId);
 						
 	 					#input parameters
 	 					my $poznamka = $txt->get("1.0","end");
	 			  		chomp($poznamka);
	 			  		$poznamka =~ s/\n/,/g;
	 			  		
 	 					my $tenting  = 0;
 	 					my $pressfit = 0;
 	 					
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
     			
 	 					my $export = NifExportTmpPool->new();
 	 				
 	 					#return 1 if OK, else 0
 	 					$export->Run( $inCAM, $jobId, $poznamka, $tenting, $pressfit, $maska01, $datacode, $ullogo, undef, $wrongData);
 	 					
 	 							my $reference = HegMethods->GetNumberOrder($jobId);
			      				HelperWriter->OnlineWrite_order( $reference, "k panelizaci" , "aktualni_krok" );
			      				HelperWriter->OnlineWrite_order( $reference, 'A', 'pooling');
			
			
								my ($pcbXsizePool,$pcbYsizePool) = _GetSizeOfPcb($jobId, 'o+1');
								
								my $pocetVrstev = CamJob->GetSignalLayerCnt($inCAM, $jobId);
					 			## write attribute to Noris
			      	 			HelperWriter->OnlineWrite_pcb("$jobId", "$constClass", "konstr_trida");
					 			HelperWriter->OnlineWrite_pcb("$jobId", "$pocetVrstev", "pocet_vrstev");
					 			HelperWriter->OnlineWrite_pcb("$jobId", "$pcbXsizePool", "kus_x");
					 			HelperWriter->OnlineWrite_pcb("$jobId", "$pcbYsizePool", "kus_y");



										# move original data to archive
										_ArchivaceData($jobId);
										
										## Add pilot holes 
										PilotHole->AddPilotHole($inCAM, $jobId, 'o+1', 'f');

										
										#prevod negativnich vnitrnich vrstev
										if ($pocetVrstev > 2) {
													my @negativInner = ();
													my $curentStep = 'o+1';
											
															$inCAM->COM( 'set_subsystem', "name" => '1-Up-Edit' );
															$inCAM->COM ('set_step',name=> 'o+1');
															
															CamLayer->ClearLayers($inCAM);
															
															
															my @signalLayers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
															my @negPolar = grep { $_->{"gROWpolarity"} eq "negative" } @signalLayers;
														
															if ( scalar(@negPolar) ) {
																@negativInner = map { $_->{"gROWname"} } @negPolar;
															}
														
															if (@negativInner) {
																foreach my $layer (@negativInner) {
																	
																			$inCAM->COM(	# backup of neg.layers in o+1 step
																			 "copy_layer",
																			 "source_job"   => $jobId,
																			 "source_step"  => $curentStep,
																			 "source_layer" => $layer,
																			 "dest"         => "layer_name",
																			 "dest_step"    => $curentStep,
																			 "dest_layer"   => $layer . '_' . $curentStep . '_ori',
																			 "mode"         => "append"
																			);
																			
																	#invert negative layers thru InCam funcionality
																	$inCAM->COM( 'matrix_layer_invert_polar', job => "$jobId", matrix => 'matrix', layers => "$layer" );
																	$inCAM->COM( 'matrix_layer_type', job => "$jobId", matrix => 'matrix', layer => "$layer", type => 'signal' );
																	
																}
																	#my @mess     = ('P�evedeny vnit�n� negativn� vrstvy upraven�m zp�sobem, po dokon�en� panelizace prohl�dni v�sledek.');
																	#my $messMngr = MessageMngr->new($jobId);
																	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );
															}
										}
										
										
										#optimalization of scoring (MPANEL) + check if score has right distance from profile when POOL
										if (CamHelper->StepExists( $inCAM, $jobId, 'mpanel')){
											$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/ScoreRepairScript.pl",dirmode=>'global',params=>"$jobId mpanel");
											$inCAM->COM('script_run',name=>"z:/sys/scripts/RouteListControlsScript.pl",dirmode=>'global',params=>"$jobId mpanel");
										}
										#optimalization of scoring when o+1_single exists + check if score has right distance from profile when POOL
										if (CamHelper->StepExists( $inCAM, $jobId, 'o+1_single') && CamHelper->StepExists( $inCAM, $jobId, 'o+1')){
											$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/ScoreRepairScript.pl",dirmode=>'global',params=>"$jobId o+1");
											$inCAM->COM('script_run',name=>"z:/sys/scripts/RouteListControlsScript.pl",dirmode=>'global',params=>"$jobId o+1");
										}
										
										
										# Run Netlist compare
										my $res = 0;
										my $notClose = 0;
 										unless (HegMethods->GetTypeOfPcb($jobId) eq 'Neplatovany') {
 													$res = NetlistControl->DoControl( $inCAM, $jobId, \$notClose);
										}
										
										# was pressed button NOT CLOSE
										if ($notClose) {
												$res = 0; 
										}
									 			if($res){
									 				$main->destroy;
									 				$inCAM -> COM ('save_job',job=>"$jobId",override=>'no',skip_upgrade=>'no');
		 							 				$inCAM -> COM ('editor_page_close');
		 							 				
		 							 				$inCAM -> COM ('check_inout',job=>"$jobId",mode=>'in',ent_type=>'job');
		 							 				
		 							 				$inCAM -> COM ('close_job',job=>"$jobId");
		 							 				$inCAM -> COM ('close_form',job=>"$jobId");
		 							 				$inCAM -> COM ('close_flow',job=>"$jobId");
		 							 				
		 							 			}

$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/poolTest.pl",dirmode=>'global',params=>"$jobId");

exit;


 			


}

sub _SendQuestion {
		my $jobId = shift;
		
			my $userName = $ENV{"LOGNAME"};
			
		 	 my $reference = HegMethods->GetNumberOrder($jobId);
			 HelperWriter->OnlineWrite_order( $reference, "poslan dotaz $userName" , "aktualni_krok" );
			 exit;
}
sub _Panelize {
	my $panelSizeName = shift;
	my $schema = '';
	
	## Add pilot holes 
			PilotHole->AddPilotHole($inCAM, $jobName, 'o+1', 'f');
	if (CamHelper->StepExists( $inCAM, $jobName, 'mpanel')){
			PilotHole->AddPilotHole($inCAM, $jobName, 'mpanel', 'f');
	}


			# When exist fsch -> remove it
			$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/fsch",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
								$inCAM->COM('delete_layer',layer=>"fsch");
					}


	# 
	if ($constClass == 0) {
			return();
	}
	
	
			# Check if the pcb is able to produce acording to Cu thickness and constr.Class
			my $copperThickness = HegMethods->GetOuterCuThick($jobName);
			_CheckKTxCU($copperThickness, $constClass);
			
			
	
			$inCAM->COM('delete_unused_sym',job=>"$jobName");
			
			$inCAM->INFO(	entity_type=>'step',
							entity_path=>"$jobName/" . EnumsProducPanel->PANEL_NAME,
							data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
								$inCAM -> COM ('delete_entity',
																job=>"$jobName",
																type=>'step',
																name=>EnumsProducPanel->PANEL_NAME
																);
					}
			
			
			if (CamHelper->StepExists($inCAM, $jobName, 'mpanel') == 1) {
					$stepName = 'mpanel';
			}else{
					$stepName = 'o+1';
			}
			
			$inCAM->COM ('set_subsystem',name=>'Panel-Design');
			$inCAM->INFO(	entity_type=>'step',
							entity_path=>"$jobName/" . EnumsProducPanel->PANEL_NAME,
							data_type=>'exists');
    					if ($inCAM->{doinfo}{gEXISTS} eq "no") {
								$inCAM->COM ('create_entity',
													job=>"$jobName",
													name=> EnumsProducPanel->PANEL_NAME,
													db=> EnumsGeneral->DB_PRODUCTION,
													is_fw=>'no',
													type=>'step',
													fw_type=>'form'
													);
						}else{
								$inCAM->COM ('delete_entity',
													job=>"$jobName",
													type=>'step',
													name=>EnumsProducPanel->PANEL_NAME
													);
								$inCAM->COM ('create_entity',
													job=>"$jobName",
													name=>EnumsProducPanel->PANEL_NAME,
													db=> EnumsGeneral->DB_PRODUCTION,
													is_fw=>'no',
													type=>'step',
													fw_type=>'form'
													);
			}
			$inCAM->COM ('set_step',
								name=>EnumsProducPanel->PANEL_NAME);
#			$inCAM->COM ('open_group',
#								job=>"$jobName",
#								step=>EnumsProducPanel->PANEL_NAME,
#								is_sym=>'no'
#								);
#			$inCAM->AUX ('set_group', 
#								group => $inCAM->{COMANS});
#			
#			$inCAM->COM ('open_entity',
#								job=>"$jobName",
#								type=>'step',
#								name=>EnumsProducPanel->PANEL_NAME,
#								iconic=>'no'
#								);
			
			
			
			# When exist draz_prog -> remove it
			$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/" . EnumsProducPanel->PANEL_NAME . "/draz_prog",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
								$inCAM->COM('delete_layer',layer=>"draz_prog");
					}
			
			
			#R$inCAM->PAUSE ("$runCSV a $file");
			if ($runCSV eq 'csv') {
						
						my %dimsPanelHash = PanelDimension->GetDimensionPanel($inCAM, $panelSizeName);
								$inCAM->COM('panel_size',
												width=>$dimsPanelHash{'PanelSizeX'} ,
												height=> $dimsPanelHash{'PanelSizeY'}
												);
					   			$inCAM->COM('sr_active',
					   							top=>$dimsPanelHash{'BorderTop'},
					   							bottom=>$dimsPanelHash{'BorderBot'},
					   							left=>$dimsPanelHash{'BorderLeft'},
					   							right=>$dimsPanelHash{'BorderRight'}
					   							);
					   	
					   	# Here script will placement each step to the production panel
					   	$inCAM->COM('zoom_home');
					   	
					   	if ((substr $file, -3) =~ /[Xx][Mm][Ll]/ ) {
					   			PoolStepPlacement->PoolStepPlaceXML($inCAM, $jobName, $file, $dimsPanelHash{'BorderLeft'}, $dimsPanelHash{'BorderBot'});
					   	}else{
					   			PoolStepPlacement->PoolStepPlace($inCAM, $jobName, $file, $dimsPanelHash{'BorderLeft'}, $dimsPanelHash{'BorderBot'});
					   	}
					   	
					   	
					   	$inCAM->PAUSE ('Zkontroluj umisteni steps');
        				$inCAM->COM('zoom_home');
        				
        				# Here is performed result all jobs on the panel and write to *.pool file
        				CounterPoolPcb -> GetCountOfOrder($inCAM, $file, $jobName);
        				
						$inCAM->COM ('show_component',
												component=>'Action_Area',
												show=>'no'
												);
												
						if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
									$schema = '4v-407';
						}else{
									$schema = '1a2v';
						}					
												
												
												
												
        	}else{
        		if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
						$schema = '4v-407';
				}else{
						$schema = '1a2v';
				}
						$inCAM->COM ('autopan_place_pcbs',job=>"$jobName",panel=>EnumsProducPanel->PANEL_NAME,pcb=>"$stepName",scheme=>"$schema",mode=>'preview',apply_pattern=>'no',apply_flip=>'no');
						$inCAM->COM ('show_component',component=>'Action_Area',show=>'no');
			
				$inCAM->PAUSE ('Vytvor panel + pouzij schema');
			}
			
			if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
					my ($xPanelSize,$yPanelSize) = _GetSizeOfPcb($jobName, 'panel');
							unless ($yPanelSize == 407) {
									$schema = '4v-485';
							}
			}
			
			# Set some attribute for PCB
			_SetAttrUser($jobName);
			_SetAttrCdrOuter($jobName);
			_SetAttrInner($jobName, $runCSV);

			set_plot_parameters($jobName);
			
			
			# Set construction class to the attribute of job
			CamJob->SetJobAttribute($inCAM, 'pcb_class', $constClass, $jobName);
			
			# Here is set attribut in job Gold_fingers
			_SetAttrGoldHolder("$jobName");
			
			# Here run scheme 
			$inCAM->COM ('autopan_run_scheme',job=>"$jobName",panel=>EnumsProducPanel->PANEL_NAME,pcb=>"$stepName",scheme=>"$schema");
			
			
			# Set attributes in Helios
			if($runCSV ne 'csv') {
						my $reference = HegMethods->GetNumberOrder($jobName);
						#HelperWriter->OnlineWrite_order( $reference, "jiz v panelu" , "aktualni_krok" );
						HelperWriter->OnlineWrite_order( $reference, 'N', 'pooling');
			}
			if($runCSV eq 'csv') {
					_SetMaskSilkHelios($jobName, 'panel');
			}
			
			
			
			
			#optimalization of scoring (MPANEL) + check if score has right distance from profile when POOL
			if (CamHelper->StepExists( $inCAM, $jobName, 'mpanel')){
				
					$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/ScoreRepairScript.pl",dirmode=>'global',params=>"$jobName mpanel");
					$inCAM->COM('script_run',name=>"z:/sys/scripts/RouteListControlsScript.pl",dirmode=>'global',params=>"$jobName mpanel");
					
					my $max = DoFlattenScore->FlattenMpanelScore( $inCAM, $jobName  );
			}
			
			#optimalization of scoring when o+1_single exists + check if score has right distance from profile when POOL
			if (CamHelper->StepExists( $inCAM, $jobName, 'o+1_single') && CamHelper->StepExists( $inCAM, $jobName, 'o+1')){
					$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/ScoreRepairScript.pl",dirmode=>'global',params=>"$jobName o+1");
					$inCAM->COM('script_run',name=>"z:/sys/scripts/RouteListControlsScript.pl",dirmode=>'global',params=>"$jobName o+1");
			}
			
			# move original data to archive
			_ArchivaceData($jobName);
			
			# Here is made stackup for pcb
			if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
						unless (_CheckExistStackup($jobName) == 1) {
									_MakeStackup($jobName);
						}else{
								my @errorList =	("Slozeni je jiz vytvoreno, NEGENERUJI");

								my $messMngr = MessageMngr->new($pcbId);
								$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList ); 
						}
			} 	
			
			
			# Set attributes conserning panel of customer
				if ($panelSet eq 'custPanel') {
						_SetPanelCustomer($jobName);
				}else{
						CamJob->SetJobAttribute($inCAM, 'customer_panel', 'no', $jobName);
				}
				
			# Set attributes conserning sada on panel
				if ($panelSet eq 'sadaPanel') {
						_SetSadaCustomer($jobName);
				}else{
						CamJob->SetJobAttribute($inCAM, 'customer_set', 'no', $jobName);
				}
			
			# Check if panel is ready for production
			CheckPanel->RunCheckOfPanel($inCAM, $jobName);
			
			# Finish message
			my @mess = ( "PANELIZACE - HOTOVO");
			my $messMngr = MessageMngr->new($jobName);
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess ); 
			
			
			# Remove older version EL test files
			my $jobFolder = substr($jobName,0,-3);
			my $etFilePath = EnumsPaths->Jobs_ELTESTS . "/$jobFolder/${jobName}t";
			
					if (-e $etFilePath) {
	  						rmtree($etFilePath);
					}
					
			# Run Netlist compare
 			unless (HegMethods->GetTypeOfPcb($jobName) eq 'Neplatovany') {
 							if($runCSV ne 'csv') {
										my $res = NetlistControl->DoControl( $inCAM, $jobName );
							}
			}
			
			
			if($runCSV eq 'csv') {
					my $fsch = CreateFsch->new( $inCAM, $jobName);
					   $fsch->Create();
			}else{
			
				# If panel contain more drifrent step, the fsch create
				my @uniqueSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobName, "panel" );
				if ( scalar(@uniqueSteps) > 1 ){
							my $fsch = CreateFsch->new( $inCAM, $jobName);
							   $fsch->Create();
				}
		
		
				# Check if contain only one kind of nested step but with various rotation
				if ( scalar(@uniqueSteps) == 1 ) {

	  					my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobName, "panel" );
	      	
				  		my $angle = $repeatsSR[0]->{"angle"};
	  					my @diffAngle = grep { $_->{"angle"} != $angle } @repeatsSR;
      	
				  		if ( scalar(@diffAngle)) {
	  						 		my $fsch = CreateFsch->new( $inCAM, $jobName);
									   $fsch->Create();
	  					}
				}
				
				# If still no exist FSCH so check if panelset is sadaPanel
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/fsch",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "no") {
								if ($panelSet eq 'sadaPanel') {
										my $fsch = CreateFsch->new( $inCAM, $jobName);
									   	   $fsch->Create();
								}
					}
			}
			
			exit;
}

sub _GetExistkonClass {
		my $idPcb = shift;
		my $atrbtClass = 0;
		my $wroteChecklist = '';
		
		   $atrbtClass = CamAttributes->GetJobAttrByName($inCAM, $idPcb, 'pcb_class');
		   
		   unless($atrbtClass) {
		   	   		my $textClass = _GetConstrClass($idPcb , 'o+1');
		   	   		
		   	   		($atrbtClass) = $textClass =~ /Class_(\d)/;
		   	   		
		   	   		if ($atrbtClass){
		   	   				$wroteChecklist = '....zapsano do KT';
		   	   		}
		  	}
		   
	return ($atrbtClass, $wroteChecklist);
}

sub _GetInnerLayers {
    my $idPcb = shift;
	my @innerList;
    $inCAM->INFO(entity_type=>'matrix',entity_path=>"$idPcb/matrix",data_type=>'ROW');
    my $totalRows = ${$inCAM->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
		my $rowFilled = ${$inCAM->{doinfo}{gROWtype}}[$count];
		my $rowName = ${$inCAM->{doinfo}{gROWname}}[$count];
		my $rowContext = ${$inCAM->{doinfo}{gROWcontext}}[$count];
		my $rowType = ${$inCAM->{doinfo}{gROWlayer_type}}[$count];
		my $rowSide = ${$inCAM->{doinfo}{gROWside}}[$count];
		if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground") && $rowSide eq "inner") {
			push @innerList,$rowName;
		}
    }
    return (@innerList);
}

sub change_side {
	my $widget = shift;
	my $currentSide = ${$widget._button}->cget(-text);
	if ($currentSide eq "top") {
		${$widget._button}->configure(-text=>"bot",-fg=>"red");
		${$widget._button}->update;
	} else {
		${$widget._button}->configure(-text=>"top",-fg=>"black");
		${$widget._button}->update;
	}
}
sub _SetAttrCdrOuter {
		my $pcbId = shift;
		my $StepName = 'panel';
		
			  $inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/c",data_type=>'exists');
  			  		if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  			
  			     				$inCAM->COM('set_attribute',type=>'layer',job=>"$pcbId",name1=>"$StepName",name2=>"c",name3=>'',attribute=>".cdr_mirror",value=>"no",units=>'mm');
  			  		}
  			  $inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/s",data_type=>'exists');
  			  		if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  			
  			     				$inCAM->COM('set_attribute',type=>'layer',job=>"$pcbId",name1=>"$StepName",name2=>"s",name3=>'',attribute=>".cdr_mirror",value=>"yes",units=>'mm');
  			  		}
}

sub _SetAttrInner {
		my $idPcb = shift;
		my $runMerge = shift;
		my @innerList = _GetInnerLayers($idPcb);
		my $panelStepName = 'panel';
		my $currentSide;
		
		#if ($runMerge eq 'csv') {
		my $i = 2;
	    foreach my $innerLayer (@innerList) {
				            my $cdrMirror;
				            
				            if ($runMerge eq 'csv') {
				            			if (0 == $i % 2) {
    						  	 				$currentSide = 'top';
							  	 		} else {
							  	 		    	$currentSide = 'bot';
							  	 		}
				            }else{

							  	 		$currentSide = ${$innerLayer._button}->cget(-text);
				            }
				            
				            
				        $inCAM->COM('set_attribute',type=>'layer',job=>"$idPcb",name1=>"$panelStepName",name2=>"$innerLayer",name3=>'',attribute=>"layer_side",value=>"$currentSide",units=>'inch');
				            if ($currentSide eq "top") {
				                    $cdrMirror = "no";
				            } else {
				                    $cdrMirror = "yes";
            				}

        				$inCAM->COM('set_attribute',type=>'layer',job=>"$idPcb",name1=>"$panelStepName",name2=>"$innerLayer",name3=>'',attribute=>".cdr_mirror",value=>"$cdrMirror",units=>'inch');
        	
        $i++;
    }
	
}

sub _SetAttrUser {
			my $idPcb = shift;
			
			#$inCAM->COM('get_user_name');
			#my $userName = "$inCAM->{COMANS}";
			my $userName = $ENV{"LOGNAME"};
			
			$inCAM->COM('set_attribute',type=>'job',job=>"$idPcb",name1=>'',name2=>'',name3=>'',attribute=>"user_name",value=>"$userName",units=>'inch');
}

sub set_plot_parameters {
		my $idPcb = shift;
		my $panelStepName = 'panel';
		
  				 $inCAM->INFO('entity_type'=>'matrix','entity_path'=>"$idPcb/matrix",'data_type'=>'ROW');
  				 my $totalRows = ${$inCAM->{doinfo}{gROWrow}}[-1];
  				 for ($count=0;$count<=$totalRows;$count++) {
  						my $rowFilled = ${$inCAM->{doinfo}{gROWtype}}[$count];
  						my $rowName = ${$inCAM->{doinfo}{gROWname}}[$count];
  						my $rowContext = ${$inCAM->{doinfo}{gROWcontext}}[$count];
  						my $rowType = ${$inCAM->{doinfo}{gROWlayer_type}}[$count];
  						my $rowSide = ${$inCAM->{doinfo}{gROWside}}[$count];
  						my $rowPolarity = ${$inCAM->{doinfo}{gROWpolarity}}[$count];
  						if ($rowFilled ne "empty" && $rowName ne "") {
  							if ($rowName eq "c") {
  								if ($pcbType eq "single") {
  									if ($rowPolarity eq "positive") {
  										$plotPolarity = "negative";
  									} else {
  										$plotPolarity = "positive";
  									}
  									$plotMirror = 0;
  								} else {
  									if ($rowPolarity eq "positive") {
  										$plotPolarity = "positive";
  									} else {
  										$plotPolarity = "negative";
  									}
  									$plotMirror = 0;
  								}
  								$plotSwap = "swap";
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							} elsif ($rowName eq "s") {
  								if ($rowPolarity eq "positive") {
  									$plotPolarity = "positive";
  								} else {
  									$plotPolarity = "negative";
  								}
  								$plotMirror = 1;
  								$plotSwap = "swap";
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							} elsif ($rowName eq "mc") {
  								if ($rowPolarity eq "positive") {
  									$plotPolarity = "positive";
  								} else {
  									$plotPolarity = "positive";
  								}
  								$plotMirror = 0;
  								$plotSwap = "swap";
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							} elsif ($rowName eq "ms") {
  								if ($rowPolarity eq "positive") {
  									$plotPolarity = "positive";
  								} else {
  									$plotPolarity = "positive";
  								}
  								$plotMirror = 1;
  								$plotSwap = "swap";
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							} elsif ($rowName =~ /v\d{1,2}/) {
  								my $currentSide = get_attributes($inCAM,$idPcb,$panelStepName,$rowName,"layer_side");
  								if ($rowPolarity eq "positive") {
  									$plotPolarity = "negative";
  								} else {
  									$plotPolarity = "positive";
  								}
  								if ($currentSide eq "top") {
  									$plotMirror = 0;
  									$plotSwap = "swap";
  								} else {
  									$plotMirror = 1;
  									$plotSwap = "swap";
  								}
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							} else {
  								$plotPolarity = "positive";
  								$plotMirror = 0;
  								$plotSwap = "no_swap";
  								$plotStretchX = 100;
  								$plotStretchY = 100;
  							}
  							$inCAM->COM('image_set_elpd2',job=>"$idPcb",step=>"$panelStepName",layer=>"$rowName",device_type=>'LP7008',polarity=>"$plotPolarity",speed=>0,xstretch=>"$plotStretchX",ystretch=>"$plotStretchY",xshift=>0,yshift=>0,xmirror=>0,ymirror=>"$plotMirror",copper_area=>0,xcenter=>0,ycenter=>0,plot_kind1=>56,plot_kind2=>56,minvec=>0,advec=>0,minflash=>0,adflash=>0,conductors1=>0,conductors2=>0,conductors3=>0,conductors4=>0,conductors5=>0,media=>'first',smoothing=>'smooth',swap_axes=>"$plotSwap",define_ext_lpd=>'no',resolution_value=>0.25,resolution_units=>'mil',quality=>'auto',enlarge_polarity=>'both',enlarge_other=>'leave_as_is',enlarge_panel=>'no',enlarge_contours_by=>0,overlap=>'no',enlarge_image_symbols=>'no',enlarge_0_vecs=>'no',enlarge_symbols=>'none',enlarge_symbols_by=>0,symbol_name1=>'',enlarge_by1=>0,symbol_name2=>'',enlarge_by2=>0,symbol_name3=>'',enlarge_by3=>0,symbol_name4=>'',enlarge_by4=>0,symbol_name5=>'',enlarge_by5=>0,symbol_name6=>'',enlarge_by6=>0,symbol_name7=>'',enlarge_by7=>0,symbol_name8=>'',enlarge_by8=>0,symbol_name9=>'',enlarge_by9=>0,symbol_name10=>'',enlarge_by10=>0);
  						}
  				 }
}
sub get_attributes {
	my ($inCAM,$job,$step,$layer,$reqAttr) = @_;
	my ($attrname,$attrval);
	my (%attr);
	my ($i);
	$job && ($type = 'job');
	$step && ($type = 'step');
	$layer && ($type = 'layer');
	$inCAM->INFO(entity_type=>"$type",entity_path=>"$job/$step/$layer",data_type=>'ATTR');
	@attrname = @{$inCAM->{doinfo}{gATTRname}};
	@attrval = @{$inCAM->{doinfo}{gATTRval}};
	for ($i=0;$i<=$#attrname;$i++) {
		if ($attrname[$i] eq $reqAttr) {
		return $attrval[$i];
		}	}
	return 0;
}
sub _GetSizeOfPcb {
		my $pcbId = shift;
		my $StepName = shift;
		
			$inCAM->INFO(units=>'mm',entity_type => 'step',entity_path => "$pcbId/$StepName",data_type => 'PROF_LIMITS');
				my $pcbXsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSxmax} - $inCAM->{doinfo}{gPROF_LIMITSxmin});
				my $pcbYsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSymax} - $inCAM->{doinfo}{gPROF_LIMITSymin});
	return($pcbXsize,$pcbYsize);
}


############################################################################################################################
#### KONTROLY
############################################################################################################################
sub _CheckArcInSilk {
	my $pcbId = shift;
	
	my $mess = "";

  			my $result = SilkScreenCheck->FeatsWidthOkAllLayers( $inCAM, $pcbId, "o+1",  \$mess );
  			unless ($result) {
  					push @errorMessageArr, $mess ;
  			}
}

sub _CheckTableRout {
	my $pcbId = shift;
	my $StepName = 'o+1';
  				$inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/f",data_type=>'exists');
  			 	if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  								$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$StepName/f",data_type => 'TOOL');
  								@hodnotyFrez = @{$inCAM->{doinfo}{gTOOLfinish_size}};
  								@hodnotyFrez = sort ({$a<=>$b} @hodnotyFrez);
  								$minFrez = $hodnotyFrez[0];
  								$minFrez = sprintf "%0.0f",($minFrez);
  			
  								$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$StepName/f",data_type => 'TOOL');
  								@hodnotyFrez = @{$inCAM->{doinfo}{gTOOLdrill_size}};
  			
  						foreach my $oneFrez (@hodnotyFrez) {
  								if ($oneFrez == 0) {
  									push @errorMessageArr, '- Pozor v seznamu FREZOVANI jsou nulove hodnoty = vetsi vrtak nez 6.50mm';
  								}
  						}
  			} 	
  		return();
}
sub _CheckTableDrill {
	my $pcbId = shift;
	my $StepName = 'o+1';
	
			$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$StepName/m",data_type => 'TOOL');
			@hodnotyVrtaku = @{$inCAM->{doinfo}{gTOOLfinish_size}};
			@hodnotyVrtaku = sort ({$a<=>$b} @hodnotyVrtaku);
			$minVrtak = $hodnotyVrtaku[0];
			$minVrtak = sprintf "%0.0f",($minVrtak);
			
			$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$StepName/m",data_type => 'TOOL');
			@hodnotyDrill = @{$inCAM->{doinfo}{gTOOLbit}};
			
			foreach my $oneDrill (@hodnotyDrill) {
				if ($oneDrill == 0) {
					push @errorMessageArr,  '- Pozor v seznamu VRTANI jsou nulove hodnoty!';
				}
			} 
}
sub _CheckBigestHole {
	my $pcbId = shift;
		if (PlatedRoutArea->PlatedAreaExceed($inCAM, $pcbId, 'o+1') == 1) {
					push @errorMessageArr,  '- Nelze udelat tentingem vetsi otvor nez 5.0mm';
		}
}


sub _CheckminimalToolRout {
			my $pcbId = shift;
			my $stepChain = 'o+1';
			
					$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$stepChain/f",data_type => 'NUM_TOOL');
					my $pocetTool = $inCAM->{doinfo}{gNUM_TOOL}; 
		
			  		$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$pcbId/$stepChain/f",data_type => 'TOOL');
  					my @bitSize = @{$inCAM->{doinfo}{gTOOLdrill_size}};
  					
  					while ($pocetTool > 0)  {
  						if ($bitSize[$pocetTool - 1] < 0.5) {
  							 push @errorMessageArr,  '- Ve freze je mensi prumer nastroje nez 0.5, presun do vrstvy m';
  							 last;
  						}
  						$pocetTool--;
  					}
}

sub _CheckMpanelExistPool {
		my $pcbId = shift;
		
		if (HegMethods->GetPcbIsPool($pcbId) == 1) {
					if (CamHelper->StepExists( $inCAM, $pcbId, 'mpanel')) {
							push @errorMessageArr,  '- Job obsahuje step MPANEL, to je u poolu nepripustne!';
					}
		}
}
sub _CheckPlgcPlgs {
		my $pcbId = shift;
		my $res = 0;
		
				my $plgCexist = CamHelper->LayerExists( $inCAM, $pcbId, 'plgc' );
				my $plgSexist = CamHelper->LayerExists( $inCAM, $pcbId, 'plgs' );
				
				   if ( $plgCexist == 1 and $plgSexist == 0 ) {
							$res = 1;
				}elsif( $plgCexist == 0 and $plgSexist == 1 ) {
							$res = 1;
				}
				
				
				if ($res) {
					push @errorMessageArr,  '- Pozor pro zaplneni nemuze byt jen jedna vrstva, i kdyz bude jedna prazdna, tak vzdy PLGC i PLGS';
				}
	
}

sub _CheckTypeOfPcb {
		my $pcbId = shift;
		my $errorExist = 0;
		
		if (HegMethods->GetTypeOfPcb($pcbId) eq 'Jednostranny') {
				unless (CamJob->GetSignalLayerCnt($inCAM, $pcbId) == 1) {
						$errorExist = 1;
				}
		}elsif (HegMethods->GetTypeOfPcb($pcbId) eq 'Oboustranny') {
				unless (CamJob->GetSignalLayerCnt($inCAM, $pcbId) == 2) {
						$errorExist = 1;
				}
		}elsif (HegMethods->GetTypeOfPcb($pcbId) eq 'Vicevrstvy') {
				unless (CamJob->GetSignalLayerCnt($inCAM, $pcbId) > 2) {
						$errorExist = 1;
				}
		}
		
		if($errorExist){
				my @errorList = ();
				
				$errorList[0] = 'Pro typ desky <b>' . HegMethods->GetTypeOfPcb($pcbId) . '</b> nesouhlasi v InCamu pocet vrstev. (Pocet vrstev = <b>' . CamJob->GetSignalLayerCnt($inCAM, $pcbId) . '</b>)';
				
				my $messMngr = MessageMngr->new($pcbId);
				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList ); 
				exit;
		}
}


sub _ArchivaceData {
		my $pcbId = shift;
			#$inCAM->PAUSE("$pcbId $outputDir/Zdroje/data/");
			unless(-e "$outputDir/Zdroje/data/"){
				mkdir("$outputDir/Zdroje/data/") or die $!;
			}
			
			if( -e "c:/pcb/$pcbId"){
				
				while(!dirmove ("c:/pcb/$pcbId","$outputDir/Zdroje/data/")){
				
					my $messMngr = MessageMngr->new($pcbId);
					my @mess = ("Nepodarilo se presunout zakaznikovi data do archivu.\n",
								"Zdroj: c:/pcb/$pcbId, Cil:$outputDir/Zdroje/data/",
								"Pravdepodobne mas nejake soubory otevrene");
					my @btn = ("Zkusit znovu", "Preskocit (zajistim zkopirovani sam)");
					
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn ); 
				
					if($messMngr->Result()){
						last;
					}
				}
			
			}#$inCAM->PAUSE("Presunuto?");
}

sub _ChangePolarityMask {
			my $pcbId = shift;
			my $StepName = 'o+1';
				  $inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/mc",data_type=>'exists');
  			  			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  					$inCAM -> COM ('matrix_layer_polar',job=>"$pcbId",matrix=>'matrix',layer=>'mc',polarity=>'positive');
  			  			}
  			  	$inCAM->INFO(entity_type=>'layer',entity_path=>"$pcbId/$StepName/ms",data_type=>'exists');
  			  			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			  					$inCAM -> COM ('matrix_layer_polar',job=>"$pcbId",matrix=>'matrix',layer=>'ms',polarity=>'positive');
  			  			}
	
}

sub _SetMaskSilkHelios {
		my $jobId = shift;
		my $stepId = shift;
		
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$stepId/pc",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk");
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$stepId/ps",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk_typ");
					
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$stepId/mc",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_barva_1");
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$stepId/ms",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_barva_2");
					}

}
sub _MakeStackup {
		my $jobId = shift;
		
				unless ($constClass) {
						$constClass = CamAttributes->GetJobAttrByName($inCAM, $jobId, 'pcb_class');
				}
				my $newThicknessCopper = HegMethods->GetOuterCuThick($jobId);
				my $countOfLayer = CamJob->GetSignalLayerCnt($inCAM, $jobId);
				
				
				unless ($newThicknessCopper) {
					 			my $result = -1;
 								my $frm = SimpleInputFrm->new(-1, "Chybi tloustka medi, zadej....", \$result);
 								$frm->ShowModal();
									$newThicknessCopper = $result;
				}
				
				my $pcbThick    = 0.7;

 				my @innerCuUsage = ();
 				my @layers       = CamJob->GetSignalLayer($inCAM, $jobId);
 				@layers = grep { $_->{"gROWname"} =~ /^v\d+$/ } @layers;
 				@layers = sort { $a->{"gROWname"} cmp $b->{"gROWname"} } @layers;

 				foreach my $l (@layers) {

 					my %area = ();
 					my ($num) = $l->{"gROWname"} =~ m/^v(\d+)$/;

 					if ( $num % 2 == 0 ) {

 						%area = CamCopperArea->GetCuArea( $newThicknessCopper, $pcbThick, $inCAM, $jobId, "panel", $l->{"gROWname"}, undef );
 					}
 					else {
 						%area = CamCopperArea->GetCuArea( $newThicknessCopper, $pcbThick, $inCAM, $jobId, "panel", undef, $l->{"gROWname"} );
 					}

 					if ($area{"percentage"} > 0) {

 						push( @innerCuUsage, sprintf "%2.0f",($area{"percentage"}) );
 					}
 				}



				
				my @attrHeg = HegMethods->GetAllByPcbId("$jobId");
				my $customerName = $pole[0]->{'customer'};

					$customerName =~ s/ /_/;                                 	


  								
  				if (HegMethods->GetPcbIsPool($jobId) == 1) {
  										StackupDefault->CreateStackup($jobId, $countOfLayer, \@innerCuUsage, $newThicknessCopper, $constClass);
  				}else{
  					
							my @mess1 = ("Pocet vrstev = $countOfLayer, Vrstva medi = $newThicknessCopper, Konstrukcni trida = $constClass, Vyuziti medi = @innerCuUsage \n\U$jobId\E_\U$countOfLayer\Evv_,_$customerName
  								");
							my @btn = ("Pokracovat - slozeni jsem vytvoril", "Vytvorit standardni slozeni"); # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
						
							my $messMngr = MessageMngr->new("$jobId");
						
							$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn);    #  Script se zastavi
						
							my $btnNumber = $messMngr->Result();    # vraci poradove cislo zmacknuteho tlacitka (pocitano od 0, zleva)

  								if ($btnNumber == 1) {
  										#print STDERR 'jsem zde';
  										StackupDefault->CreateStackup($jobId, $countOfLayer, \@innerCuUsage, $newThicknessCopper, $constClass);
	  							}else{
	  									#print STDERR 'jsem ajjj';
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
# 
sub _SetAttrGoldHolder {
		my $jobId = shift;
	
				my %result = CamGoldArea->GetGoldFingerArea(18, 1.50, $inCAM, $jobId, 'panel');	# If exist attr .gold_plating
				my $surface = HegMethods->GetPcbSurface($jobId);									# If exist surface 'plosne galvanicke zlaceni'

				if ($result{"exist"} == 1 or $surface eq 'G') {
						CamJob->SetJobAttribute($inCAM, 'goldholder', 'yes', $jobId);
				}else{
						CamJob->SetJobAttribute($inCAM, 'goldholder', 'no', $jobId);
				}
}

sub _SetSadaCustomer {
		my $jobId = shift;
		
			
			my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "mpanel" );
			
			# pocet vsech stepu v mpanelu
			my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "mpanel" );
   		
			# vychozi pocet sad
			my $setCnt = 1;
   		
			if ( scalar(@repeats) % scalar(@uniqueSR) == 0 ) {
			
				$setCnt = scalar(@repeats) / scalar(@uniqueSR);
			}
 			my $result = 0;
 		
 			my $frm = SimpleInputFrm->new(-1, "SET SADA", "Zadej pocet sad, predbezne jsem spocital $setCnt", \$result);
 			
 			$frm->ShowModal();
 			
 			if ($result) {
 					CamJob->SetJobAttribute($inCAM, 'cust_set_multipl', $result, $jobId);
 					CamJob->SetJobAttribute($inCAM, 'customer_set', 'yes', $jobId);
 			}
 			
	return();

}


sub _SetPanelCustomer {
		my $jobId = shift;
		
		# Customer's panel 
		#-------------------------
		
				my $customerPanelExist = CamAttributes->GetJobAttrByName($inCAM, $jobId, 'customer_panel');
				my $customerCountExist = CamAttributes->GetJobAttrByName($inCAM, $jobId, 'cust_pnl_multipl');
				
				if ($customerPanelExist eq 'yes' and $customerCountExist > 0) {
							my @mess1 = ("Panal zakaznika jiz byl nastaven, chces zadat znovu?");

							my $messMngr = MessageMngr->new($jobId);

							$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 , ["ANO", "NE"]);    #  Script se zastavi
							
							my $btnNumber = $messMngr->Result();    # vraci poradove cislo zmacknuteho tlacitka (pocitano od 0, zleva)
							
							if ($resulta == 0) {
									my ($singleXsize, $singleYsize, $nas_mpanel_zak) = _CustomerPanel($jobId);
				
									# Set construction class to the attribute of job
									CamJob->SetJobAttribute($inCAM, 'customer_panel', 'yes', $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_singlex', $singleXsize, $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_singley', $singleYsize, $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_multipl', $nas_mpanel_zak, $jobId);
							}
				}else{
									my ($singleXsize, $singleYsize, $nas_mpanel_zak) = _CustomerPanel($jobId);
				
									# Set construction class to the attribute of job
									CamJob->SetJobAttribute($inCAM, 'customer_panel', 'yes', $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_singlex', $singleXsize, $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_singley', $singleYsize, $jobId);
									CamJob->SetJobAttribute($inCAM, 'cust_pnl_multipl', $nas_mpanel_zak, $jobId);
				}
	
}

sub _CustomerPanel {
	my $jobId = shift;
	
 				$inCAM->COM ('set_step',name=>'o+1');
 				$inCAM->COM('units',type=>'mm');
 				
 				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/o+1/mc",data_type=>'exists');
 			   	if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
 			  		   		$inCAM->COM ('display_layer',name=>'mc',display=>'yes',number=>'1');
 							$inCAM->COM ('work_layer',name=>'mc');
 							$inCAM->COM ('snap_mode',mode=>'intersect');
 			   	}
 				
 				$coordine = $inCAM->MOUSE("r Vyber rozmer jedne desky ");
 				
 				@poleCoordine = split /\s/,$coordine;
 					my $dimSingleX = sprintf "%3.3f",($poleCoordine[2] - $poleCoordine[0]);
 					my $dimSingleY = sprintf "%3.3f",($poleCoordine[3] - $poleCoordine[1]);
 					$inCAM -> COM ('zoom_home');
 				
 				$inCAM-> PAUSE ("Panel zakaznika - zjisti nasobnost a spravny rozmer");
 				
 				$inCAM->COM('units',type=>'mm');
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

sub _GetConstrClass {
		my $jobId = shift;
		my $stepId = shift;
		my $checkList = 'Checks';
		my $positionInChecks = 'action=2';
		my $res = 0;
		
  				$inCAM->INFO(units => 'mm', angle_direction => 'ccw', entity_type => 'check',
  			  	     entity_path => "$jobId/$stepId/$checkList",
  			      	 data_type => 'EXISTS');
  				if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  			       				$inCAM->INFO(units => 'mm', angle_direction => 'ccw', entity_type => 'check',
  			  	     												entity_path => "$jobId/$stepId/$checkList",
  			       													data_type => 'ERF_MODEL',
  			       													options => $positionInChecks);
  			       													
  			       			$res = $inCAM->{doinfo}{gERF_MODEL};
  			    }
  	return($res);	       													
}

sub _CheckRout {
		my $jobId = shift;
		my $workLayer = 'f';
		my @stepRoutChain = ();
		
		
		my @steps = CamStep->GetAllStepNames($inCAM, $jobId);
		
		my @stepList = grep { $_ ne 'input' && $_ ne 'o' && $_ ne 'pcb' && $_ ne 'et_panel' && $_ ne 'o+1_single'} @steps;
		
		
		
			foreach my $step (@stepList) {
					
					$inCAM->COM ('set_step',name=>$step);
					
					my $infoFile = $inCAM->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobId/$step/$workLayer",'data_type'=>'FEATURES',parse=>'no');
					open (INFOFILE,$infoFile);
							while(<INFOFILE>) {
									if ($_ =~ /\.rout_chain=1/) {
											push @stepRoutChain, $step;
											last;
									}
							}
			}
			
			# Check correct rout
			
			foreach my $step (@stepRoutChain) {
					 
							my $check = CheckRout->new( $inCAM, $jobId, $step, 'f' );
							$check->Check(); 
							$inCAM->COM('zoom_home');
							#$inCAM->PAUSE('Zkontroluj umisteni patky');
			}
}

sub _GUIcompLayDone {
	my $pcbId = shift;

	my $messMngr = MessageMngr->new($pcbId);
	my @mess     = ("Porovnan� vrstev s origin�ln�m stepem ji� bylo provedeno, bude� cht�t zkontrolovat znovu?");
	my @btn      = ( "Zkontrolovat znovu", "Ji� nekontrolovat" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn );

	return ( $messMngr->Result() );
}

sub _CheckKTxCU {
	my $cuValue = shift;
	my $classKon = shift;
	my $res = 0;
	
  					if ($classKon == 5 and $cuValue > 70) {
  							$res = 1;
  				}elsif ($classKon == 6 and $cuValue > 35) {
  							$res = 1;
  				}elsif ($classKon == 7 and $cuValue > 18) {
  							$res = 1;
  				}elsif ($classKon == 8 and $cuValue > 18) {
  							$res = 1;
  				}
  				
  		if ($res) {
					my @errorList =	("Pozor deska nelze vyrobit z duvodu KT$classKon na Cu$cuValue, panelizace NEBUDE pokracovat. Situaci je treba resit se zakaznikem zmenou jednoho z techto atributu (KT | Cu) ; 	Vice na webu pod Minim�lni sirka vodice a izolacni mezery pro pouzitou medenou folii.");

					my $messMngr = MessageMngr->new($jobName);
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList ); 
					
					
					exit;
		}
}

# When there are uncover soldermask of drilling only from one side, then subroutine perform uncover sodermask even on the other side.
sub _SolderMaskUncoverVia {
		my $jobId = shift;
		my $drillingLayer = 'm';


		if ( CamHelper->LayerExists( $inCAM, $jobId, 'mc') == 1 and  CamHelper->LayerExists( $inCAM, $jobId, 'ms') == 1) {

						my $layerTMP = '12345';
						CamFilter->SelectByReferenece( $inCAM, $jobId, "disjoint", $drillingLayer, undef, undef, undef, 'ms');
						$inCAM->COM ('get_select_count');
									if ($inCAM->{COMANS} > 0) {
											CamLayer->CopySelected($inCAM, [$layerTMP], 0, 0 );
											CamLayer->ClearLayers($inCAM);
									
									
					 								CamFilter->SelectByReferenece( $inCAM, $jobId, "Touch", $layerTMP, undef, undef, undef, 'mc');
					 								$inCAM->COM ('get_select_count');
					 								if ($inCAM->{COMANS} > 0) {
					 										CamLayer->CopySelected($inCAM, ['ms'], 0, -50 );
					 										CamLayer->ClearLayers($inCAM);
					 										
					 										_reportTMP($jobId . ' Odmaskovany via v ms');
					 								}
					 								
					 								if (CamHelper->LayerExists( $inCAM, $jobId, $layerTMP) == 1) {
					 										$inCAM->COM('delete_layer',layer=>$layerTMP);
					 								}
					 				}
					#####################################################################################################################
									
						$layerTMP = '678910';		
						CamFilter->SelectByReferenece( $inCAM, $jobId, "disjoint", $drillingLayer, undef, undef, undef, 'mc');
						$inCAM->COM ('get_select_count');
									if ($inCAM->{COMANS} > 0) {
											CamLayer->CopySelected($inCAM, [$layerTMP], 0, 0 );
											CamLayer->ClearLayers($inCAM);
									
													CamFilter->SelectByReferenece( $inCAM, $jobId, "Touch", $layerTMP, undef, undef, undef, 'ms');
													$inCAM->COM ('get_select_count');
													if ($inCAM->{COMANS} > 0) {
															CamLayer->CopySelected($inCAM, ['mc'], 0, -50 );
															CamLayer->ClearLayers($inCAM);
															
															_reportTMP($jobId . ' Odmaskovany via v mc');
													}
													
													if (CamHelper->LayerExists( $inCAM, $jobId, $layerTMP) == 1) {
															$inCAM->COM('delete_layer',layer=>$layerTMP);
													}
									}
		}
}

sub _reportTMP {
	my $info = shift;
	
		my $path = 'r:/Archiv/report_tpv/';
			open (REPORT,">>$path/report.txt");
			print REPORT $info , "\n";
			close REPORT;
	
}

sub _DelAttrFeed {
			CamLayer->ClearLayers($inCAM);
			CamLayer->WorkLayer( $inCAM, 'f' ); 
			CamAttributes->DelFeatuesAttribute($inCAM, '.feed');
			CamLayer->ClearLayers($inCAM);
}