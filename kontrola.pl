#!/usr/bin/perl


use warnings;

use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Tk::LabFrame;
use XML::Simple;
use Data::Dumper;
use File::Find;


use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutAtt';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Helpers::ValueConvertor';

use aliased 'Packages::CAMJob::Marking::Marking';

my $inCAM    = InCAM->new();

unless ($ENV{JOB}) {
	$jobName = shift;
   $StepName = shift;
}else{
	$jobName = "$ENV{JOB}";
	$StepName = "$ENV{STEP}";
}


$inCAM->COM('script_run',name=>"y:/server/site_data/scripts/ScoreRepairScript.pl",dirmode=>'global',params=>"$jobName $StepName");

# 1) Add attribute plated rout area to step o,o+1 to all plated rout layers
# 2) Delete smd attributes from pads, where is plated rout
PlatedRoutAtt->SetRoutPlated($inCAM, $jobName);




my %hashXML = ();
my %hashINFO = ();
my @errorMessageArr = ();

my $main = MainWindow->new;
$main->title('Informace o DPS');
			my $mainFrame= $main->Frame(-width=>100, -height=>150)->pack(-side=>'top', -fill=>'x');
				my $topFrame = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top');
						my $topFrameLeftLeft = $topFrame->Frame(
												-width=>100, 
												-height=>150)
												->pack(-side=>'left',-fill=>'both');
										my $topFrameLeftLeftTop = $topFrameLeftLeft->LabFrame(
																	-label=>"Obchodni specifikace/konfigurator",
																	-width=>100, 
																	-height=>150)
																	->pack(-side=>'top',																
																	-fill=>'both',
																	-expand => "True");
						my $topFrameLeft = $topFrame->Frame(
												-width=>100, 
												-height=>150)
												->pack(-side=>'left',-fill=>'both');
										my $topFrameLeftTop = $topFrameLeft->LabFrame(
																	-label=>"Informace Helios",
																	-width=>100, 
																	-height=>150)
																	->pack(
																	-side=>'top',
																	-fill=>'both',
																	-expand => "True");
										
								my $xmlExist = 0;
								my @infoPcbOffer = HegMethods->GetAllByPcbId($jobName);
								my $outputDir = $infoPcbOffer[0]{'archiv'};
		   						$outputDir =~ s/\\/\//g;
								opendir (XML,"$outputDir");
								my @dataArchivXML = readdir XML;
								closedir XML;
											foreach my $items (@dataArchivXML) {
															if($items =~ /.[Xx][Mm][Ll]/) {	
																	$xmlExist = 1;
															}
											}
									if ($xmlExist == 1){							
													my $topFrameMiddle = $topFrame->Frame(
																					-width=>100, 
																					-height=>150)
																					->pack(-side=>'left',-fill=>'y');
																			my $topFrameMiddleTop = $topFrameMiddle->LabFrame(
																										-label=>"Objednavka XML",
																										-width=>100, 
																										-height=>150)
																										->pack(-side=>'top',																
																										-fill=>'both',
																										-expand => "True");
														_PutXMLorder($topFrameMiddleTop);	
									}
																										
																										
							my @infoPcbOfferN = HegMethods->GetAllByPcbIdOffer($jobName);
							if ($infoPcbOfferN[0]{'Nabidku_zpracoval'}) {
									my $topFrameRight = $topFrame->Frame(
															-width=>100, 
															-height=>150)
															->pack(-side=>'left',-fill=>'y');
													my $topFrameRightTop = $topFrameRight->LabFrame(
																				-label=>"Nabidka",
																				-width=>100, 
																				-height=>150)
																				->pack(-side=>'top',
																				-fill=>'both',
																				-expand => "True");
																				
									_PutOfferToGui($topFrameRightTop);
							}								
																	
																	
								_PutOUspecInfo($topFrameLeftLeftTop);
								_PutHeliosInfo($topFrameLeftTop);

								
               			
				my $middleFrame1 = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top',-fill=>'both');
											my $mypodframe = $middleFrame1->LabFrame(
																	-width=>'100', 
																	-height=>'70',
																	-label=>"Pozmanky k zakaznikovi",
																	-font=>'normal 9 {bold }',
																	-labelside=>'top',
																	-bg=>'lightgrey',
																	-borderwidth=>'3')
																	->pack(-fill=>'both',-side=>'top',-expand => "True");
																	
											$mypodframe ->Label(-textvariable=>\HegMethods->GetTpvCustomerNote($jobName), -fg=>"blue")->pack(-side=>'top',-fill=>'both');
				my $middleFrame2 = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'top',-fill=>'both');
											my $middleFrame2Top = $middleFrame2->LabFrame(
																	-label=>"Zjistene chyby",
																	-width=>100, 
																	-height=>50)
																	->pack(
																	-side=>'left',
																	-fill=>'both',
																	-expand => "True");
											my $rowStart=0;
											_CheckTableDrill();
											_CheckTableRout();
											_CheckTermoPoint();
											_CheckCustomerFinishHoles($jobName);
											_CheckStatusPriprava($jobName);
											_CheckLimitWithTabs($jobName);
											
											my $dataCodeHeg = lc HegMethods->GetDatacodeLayer($jobName);
											if($dataCodeHeg) {
												_CheckCorrectDataCode($jobName, $dataCodeHeg);
											}
											
											if ($hashINFO{ipc_class} == 3) {
													push (@errorMessageArr, '- NEVYRABIME CLASS 3, informuj obchod.')
											}
											
											_CheckCutomerNetlist($jobName);
											
											my $tmpFrameInfo = $middleFrame2Top->Frame(-width=>100, -height=>10)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
											foreach my $item (@errorMessageArr) {
																	$tmpFrameInfo ->Label(-textvariable=>\$item, -fg=>"red", -font=>"ARIAL 12")->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"w");
																	$rowStart++;
											}
				my $botFrame = $mainFrame->Frame(-width=>100, -height=>150)->pack(-side=>'bottom');
				my $tl_no=$botFrame->Button(-width=>'120',-text => "POKRACOVAT",-command=> \sub {$main->destroy},-bg=>'grey')->pack(-fill=>'both',-padx => 1, -pady => 1,-side=>'right');
				
$main->MainLoop;



	opendir ( BOARDS, EnumsPaths->Client_ELTESTS );
		while( (my $jobItem = readdir(BOARDS))){
					if ($jobItem =~ /[Dd]\d{6,}/) {
							if (-e EnumsPaths->Client_ELTESTS . "$jobItem/$jobItem.pad") {
									_MoveToServer($jobItem);
							}
					}
	}
	closedir BOARDS;
	
	
	# Check csv file and write to send control data to HEG if it is Q-Print
	if (HegMethods->GetIdcustomer($jobName) eq '06815') {
			my $importPath = _SearchCSV($jobName);

				if ( $importPath ) {
						if (_SendGerber($importPath)) {
								HegMethods->UpdateOrderNotes($jobName, 'Odeslat data CONTROL na odsouhlaseni.');
						}
				}
	}
	
	





sub _PutXMLorder {
		my $orderFrame = shift;
		my @infoPcbOffer = HegMethods->GetAllByPcbId($jobName);
		my $articleid = $infoPcbOffer[0]{'zakaznicke_cislo'}; 				# vrati ID desky dle EURA
		my $outputDir = $infoPcbOffer[0]{'archiv'};
		   $outputDir =~ s/\\/\//g;

		opendir (XML,"$outputDir");
		my @dataArchivXML = readdir XML;
		closedir XML;
				foreach my $items (@dataArchivXML) {
						if($items =~ /.[Xx][Mm][Ll]/) {
								my $mtime = (stat "$outputDir/$items")[9];	# vrati posledni datum editace souboru
								$hashXML{$mtime} = "$items";
						}
				}

		if (%hashXML) {																# kontrola jestli nejake xml existuje
				my @tmpPole = (sort {$b<=>$a} keys %hashXML);						# setridi time souboru dle velisti
				my $framegrid = 0;
				
				__GetValueXML($hashXML{$tmpPole[0]}, $outputDir, $articleid);
									if (%hashXML) {	
												my $viewInfo = 0;
												my $viewInfo1 = 0;
												my $viewInfo2 = 0;
												my $viewInfo3 = 0;
												my $viewInfo4 = 0;
												
												my $stepTmp = $StepName;
												
												
											if (CamHelper->StepExists( $inCAM, $jobName, 'mpanel')){
														$stepTmp = 'mpanel';
											}
												
											($viewInfo, $viewInfo1) = _CompareDimPcbXml($jobName, $stepTmp);	

													
													my ($silkPCBtop, $silkPCBbot) = 0;
													$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/pc",data_type=>'exists');
									    					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
									    							$silkPCBtop = 1;
									    					}
									    			$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/ps",data_type=>'exists');
									    					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
									    							$silkPCBbot = 1;
									    					}
									    			if (($hashINFO{silkscreenTOP} eq '-' and $silkPCBtop == 1) or ($hashINFO{silkscreenTOP} ne '-' and $silkPCBtop == 0)) {
									    							$viewInfo = 1;
									    							$viewInfo2 = 1;
									    			}
													if (($hashINFO{silkscreenBOT} eq '-' and $silkPCBbot == 1) or ($hashINFO{silkscreenBOT} ne '-' and $silkPCBbot == 0)) {
									    							$viewInfo = 1;
									    							$viewInfo2 = 1;
									    			}
									    							
													if ($hashINFO{special_layer_construction} eq 'yes') {
																	$viewInfo3 = 1;
													}
													if ($hashINFO{goldfingers} > 0 ) {
																	$viewInfo4 = 1;
													}

													
													my $rowStart = 0;
													$framegrid = $orderFrame->Frame(-width=>100, -height=>150)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
													
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozdil v rozmeru",-font=>'arial 10 {bold}',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>2,-sticky=>"news");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Nesedi potisk v datech / objednavka",-font=>'arial 10 {bold}',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>2,-sticky=>"news");
													}
													if($viewInfo){
													$rowStart++;
													$framegrid->Label(-text=>"Cislo objednavky",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{order_num}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo){
													$rowStart++;
													$framegrid->Label(-text=>"Nazev DPS",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{pcb_name}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozmer X",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{size_x}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozmer Y",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{size_y}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Potisk TOP",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{silkscreenTOP}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Potisk BOT",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{silkscreenBOT}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if ($viewInfo3){
													$rowStart++;
													$framegrid->Label(-text=>"Special stackup",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{special_layer_construction}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{layer_buildup} eq 'N/D') {
															$rowStart++;
															$framegrid->Label(-text=>"Stackup",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
															$framegrid->Label(-text=>"Neni striktne definovan",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}elsif($hashINFO{layer_buildup} eq '4L01') {
															$rowStart++;
															$framegrid->Label(-text=>"Stackup",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
															$framegrid->Label(-text=>"Standradni slozeni (Core 1,20)",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");	
													}elsif($hashINFO{layer_buildup} eq 'CUST') {
															$rowStart++;
															$framegrid->Label(-text=>"Stackup",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
															$framegrid->Label(-text=>"Specialni slozeni",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");	
													}
													
													
													if ($viewInfo4){
													$rowStart++;
													$framegrid->Label(-text=>"Zlaceny konektor",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{goldfingers} padu",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													
													
													
													
													
													if ($hashINFO{chamfered_borders} > 0){
															$rowStart++;
															$framegrid->Label(-text=>"Srazeni konektoru",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
															$framegrid->Label(-text=>"$hashINFO{chamfered_borders} stupnu",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{pressfit} eq 'yes'){
															$rowStart++;
															$framegrid->Label(-text=>"Pressfit",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
															$framegrid->Label(-text=>"$hashINFO{pressfit}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													
													$rowStart++;
													$framegrid->Label(-text=>"Cu OUTER",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{cu_outer}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													$rowStart++;
													$framegrid->Label(-text=>"Cu INNER",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{cu_inner}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													$rowStart++;
													$framegrid->Label(-text=>"Material",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{material}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													$rowStart++;
													$framegrid->Label(-text=>"Pocet vrstev",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{pocet_vrstev}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													if ($hashINFO{sideplating} eq 'yes'){
														$rowStart++;
														$framegrid->Label(-text=>"Sideplating",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{sideplating}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{pth_freza} eq 'yes'){
														$rowStart++;
														$framegrid->Label(-text=>"Prokovena freza",-font=>'arial 9',-fg=>'red')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{pth_freza}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													$rowStart++;
													$framegrid->Label(-text=>"Datacode",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{datacode}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													if ($hashINFO{panel_processing} ne '-'){
														$rowStart++;
														my $font = 'arial 9';
														if ($hashINFO{panel_processing} =~ /perf/){
															$font = 'arial 9 bold underline';
														}
														$framegrid->Label(-text=>"Opracovani",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{panel_processing}",-font=> $font,-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{panel_processing_x} ne '-'){
														$rowStart++;
														my $font = 'arial 9';
														if ($hashINFO{panel_processing_x} =~ /perf/){
															$font = 'arial 9 bold underline';
														}
														$framegrid->Label(-text=>"Opracovani v ose X",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{panel_processing_x}",-font=> $font,-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{panel_processing_y} ne '-'){
														$rowStart++;
														my $font = 'arial 9';
														if ($hashINFO{panel_processing_y} =~ /perf/){
															$font = 'arial 9 bold underline';
														}
														$framegrid->Label(-text=>"Opracovani v ose Y",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{panel_processing_y}",-font=> $font,-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													$rowStart++;
													$framegrid->Label(-text=>"Min_track",-font=>'arial 9 {underline}',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{min_track}",-font=>'arial 9 {underline}',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													if ($hashINFO{via_filling} ne '-'){
														$rowStart++;
														$framegrid->Label(-text=>"Filled_vias",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"Typ zaplneni => $hashINFO{via_filling}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if ($hashINFO{ipc_class} ne '-'){
														$rowStart++;
														$framegrid->Label(-text=>"IPC class",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
														$framegrid->Label(-text=>"$hashINFO{ipc_class}",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													if(HegMethods->GetPcbIsPool($jobName) == 0) {
											  					$rowStart++;
											  					$framegrid->Label(-text=>"Maska TOP",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
											  					$framegrid->Label(-text=>"$hashINFO{solderstopTOP}",-font=>'arial 9',-bg=> _TranformColour($hashINFO{solderstopTOP}), -fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									          			
											  					$rowStart++;
											  					$framegrid->Label(-text=>"Maska BOT",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
											  					$framegrid->Label(-text=>"$hashINFO{solderstopBOT}",-font=>'arial 9',-bg=> _TranformColour($hashINFO{solderstopBOT}), -fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									          			
											  					$rowStart++;
											  					$framegrid->Label(-text=>"Silk TOP",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
											  					$framegrid->Label(-text=>"$hashINFO{silkscreenTOP}",-font=>'arial 9',-bg=>_TranformColour($hashINFO{silkscreenTOP}),  -fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									          			
											  					$rowStart++;
											  					$framegrid->Label(-text=>"Silk BOT",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
											  					$framegrid->Label(-text=>"$hashINFO{silkscreenBOT}",-font=>'arial 9',-bg=>_TranformColour($hashINFO{silkscreenBOT}),  -fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
									
													my $heightTest;
													my $delkapath =  length($hashINFO{poznamky});
													if ($delkapath < 60) {
														$heightTest = 3;
													}elsif($delkapath < 90){
														$heightTest = 4;
													}elsif($delkapath < 120){
														$heightTest = 5;
													}elsif($delkapath < 150){
														$heightTest = 6;
													}else{
														$heightTest = 10;
													}
													$rowStart++;
													$framegrid->Label(-text=>"Poznamka",-font=>'arial 9 {bold}',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													my $u = $rowStart + 1;
													my $pole = $framegrid->Text(-width=>30, -height=>"$heightTest")->grid(-column=>0,-row=>"$u",-columnspan=>2,-sticky=>"w",-padx=>1);
													$pole->insert("end", "$hashINFO{poznamky}");
													
													
													if ($hashINFO{poznamky}=~ /EXACT QUANTITY/ ) {
															HegMethods->UpdateOrderNotes($jobName, 'PRESNY POCET KUSU');
													}
																	
									}	
		}
}

sub __GetValueXML {
	my $xmlFile = shift;
	my $outputDir = shift;
	my $articleid = shift;
	
	my $katalog = XMLin("$outputDir/$xmlFile");

	my $getStructure = $katalog->{Order};									# dostanu hodnotu ARRAY / HASH, tim poznam, jak se XML dale vyviji
			if ($getStructure =~ /^ARRAY/) {								
					my $countPCB = 0;
					while (1) {
							my $tmp = $katalog->{Order}->[$countPCB];
								if ($tmp) {
										if ($katalog->{Order}->[$countPCB]->{PCB}->{articleid} eq $articleid) {
												my $emptyText = '-';
												if ($katalog->{Order}->[$countPCB]->{number} =~ /^HASH/){$hashINFO{'order_num'}="$emptyText";}else{$hashINFO{'order_num'}= ($katalog->{Order}->[$countPCB]->{number});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{name} =~ /^HASH/){$hashINFO{'pcb_name'}="$emptyText";}else{$hashINFO{'pcb_name'}= ($katalog->{Order}->[$countPCB]->{PCB}->{name});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{layers} =~ /^HASH/){$hashINFO{'pocet_vrstev'}="$emptyText";}else{$hashINFO{'pocet_vrstev'}= ($katalog->{Order}->[$countPCB]->{PCB}->{layers});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{sizeX} =~ /^HASH/){$hashINFO{'size_x'}="$emptyText";}else{$hashINFO{'size_x'}= ($katalog->{Order}->[$countPCB]->{PCB}->{sizeX});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{sizeY} =~ /^HASH/){$hashINFO{'size_y'}="$emptyText";}else{$hashINFO{'size_y'}= ($katalog->{Order}->[$countPCB]->{PCB}->{sizeY});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{material} =~ /^HASH/){$hashINFO{'material'}="$emptyText";}else{$hashINFO{'material'}= ($katalog->{Order}->[$countPCB]->{PCB}->{material});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{cuouter} =~ /^HASH/){$hashINFO{'cu_outer'}="$emptyText";}else{$hashINFO{'cu_outer'}= ($katalog->{Order}->[$countPCB]->{PCB}->{cuouter});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{cuinner} =~ /^HASH/){$hashINFO{'cu_inner'}="$emptyText";}else{$hashINFO{'cu_inner'}= ($katalog->{Order}->[$countPCB]->{PCB}->{cuinner});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{datacode} =~ /^HASH/){$hashINFO{'datacode'}="$emptyText";}else{$hashINFO{'datacode'}= ($katalog->{Order}->[$countPCB]->{PCB}->{datacode});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{plate_slits} =~ /^HASH/){$hashINFO{'pth_freza'}="$emptyText";}else{$hashINFO{'pth_freza'}= ($katalog->{Order}->[$countPCB]->{PCB}->{plate_slits});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{sideplating} =~ /^HASH/){$hashINFO{'sideplating'}="$emptyText";}else{$hashINFO{'sideplating'}= ($katalog->{Order}->[$countPCB]->{PCB}->{sideplating});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{notes} =~ /^HASH/){$hashINFO{'poznamky'}="$emptyText";}else{$hashINFO{'poznamky'}= ($katalog->{Order}->[$countPCB]->{PCB}->{notes});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{order_category} =~ /^HASH/){$hashINFO{'order_category'}="$emptyText";}else{$hashINFO{'order_category'}= ($katalog->{Order}->[$countPCB]->{PCB}->{order_category});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{solderstopTOP} =~ /^HASH/){$hashINFO{'solderstopTOP'}="$emptyText";}else{$hashINFO{'solderstopTOP'}= ($katalog->{Order}->[$countPCB]->{PCB}->{solderstopTOP});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{solderstopBOT} =~ /^HASH/){$hashINFO{'solderstopBOT'}="$emptyText";}else{$hashINFO{'solderstopBOT'}= ($katalog->{Order}->[$countPCB]->{PCB}->{solderstopBOT});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenTOP} =~ /^HASH/){$hashINFO{'silkscreenTOP'}="$emptyText";}else{$hashINFO{'silkscreenTOP'}= ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenTOP});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenBOT} =~ /^HASH/){$hashINFO{'silkscreenBOT'}="$emptyText";}else{$hashINFO{'silkscreenBOT'}= ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenBOT});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{special_layer_construction} =~ /^HASH/){$hashINFO{'special_layer_construction'}="$emptyText";}else{$hashINFO{'special_layer_construction'}= ($katalog->{Order}->[$countPCB]->{PCB}->{special_layer_construction});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{layer_buildup} =~ /^HASH/){$hashINFO{'layer_buildup'}="$emptyText";}else{$hashINFO{'layer_buildup'}= ($katalog->{Order}->[$countPCB]->{PCB}->{layer_buildup});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{goldfingers} =~ /^HASH/){$hashINFO{'goldfingers'}="$emptyText";}else{$hashINFO{'goldfingers'}= ($katalog->{Order}->[$countPCB]->{PCB}->{goldfingers});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing} =~ /^HASH/){$hashINFO{'panel_processing'}="$emptyText";}else{$hashINFO{'panel_processing'}= ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{min_track} =~ /^HASH/){$hashINFO{'min_track'}="$emptyText";}else{$hashINFO{'min_track'}= ($katalog->{Order}->[$countPCB]->{PCB}->{min_track});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{chamfered_borders} =~ /^HASH/){$hashINFO{'chamfered_borders'}="$emptyText";}else{$hashINFO{'chamfered_borders'}= ($katalog->{Order}->[$countPCB]->{PCB}->{chamfered_borders});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{pressfit} =~ /^HASH/){$hashINFO{'pressfit'}="$emptyText";}else{$hashINFO{'pressfit'}= ($katalog->{Order}->[$countPCB]->{PCB}->{pressfit});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{via_filling} =~ /^HASH/){$hashINFO{'via_filling'}="$emptyText";}else{$hashINFO{'via_filling'}= ($katalog->{Order}->[$countPCB]->{PCB}->{via_filling});};	
												if ($katalog->{Order}->[$countPCB]->{PCB}->{ipc_class} =~ /^HASH/){$hashINFO{'ipc_class'}="$emptyText";}else{$hashINFO{'ipc_class'}= ($katalog->{Order}->[$countPCB]->{PCB}->{ipc_class});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing_x} =~ /^HASH/){$hashINFO{'panel_processing_x'}="$emptyText";}else{$hashINFO{'panel_processing_x'}= ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing_x});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing_y} =~ /^HASH/){$hashINFO{'panel_processing_y'}="$emptyText";}else{$hashINFO{'panel_processing_y'}= ($katalog->{Order}->[$countPCB]->{PCB}->{panel_processing_y});};
										
										}
								}else{
									last;
								}
						$countPCB++
					}
			}else{	
										# v pripade HASH je xml struktura odlisna
										if ($katalog->{Order}->{PCB}->{articleid} eq $articleid) {
												my $emptyText = '-';
												if ($katalog->{Order}->{number} =~ /^HASH/){$hashINFO{'order_num'}="$emptyText";}else{$hashINFO{'order_num'}= ($katalog->{Order}->{number});};
												if ($katalog->{Order}->{PCB}->{name} =~ /^HASH/){$hashINFO{'pcb_name'}="$emptyText";}else{$hashINFO{'pcb_name'}= ($katalog->{Order}->{PCB}->{name});};
												if ($katalog->{Order}->{PCB}->{layers} =~ /^HASH/){$hashINFO{'pocet_vrstev'}="$emptyText";}else{$hashINFO{'pocet_vrstev'}= ($katalog->{Order}->{PCB}->{layers});};
												if ($katalog->{Order}->{PCB}->{sizeX} =~ /^HASH/){$hashINFO{'size_x'}="$emptyText";}else{$hashINFO{'size_x'}= ($katalog->{Order}->{PCB}->{sizeX});};
												if ($katalog->{Order}->{PCB}->{sizeY} =~ /^HASH/){$hashINFO{'size_y'}="$emptyText";}else{$hashINFO{'size_y'}= ($katalog->{Order}->{PCB}->{sizeY});};
												if ($katalog->{Order}->{PCB}->{material} =~ /^HASH/){$hashINFO{'material'}="$emptyText";}else{$hashINFO{'material'}= ($katalog->{Order}->{PCB}->{material});};
												if ($katalog->{Order}->{PCB}->{cuouter} =~ /^HASH/){$hashINFO{'cu_outer'}="$emptyText";}else{$hashINFO{'cu_outer'}= ($katalog->{Order}->{PCB}->{cuouter});};
												if ($katalog->{Order}->{PCB}->{cuinner} =~ /^HASH/){$hashINFO{'cu_inner'}="$emptyText";}else{$hashINFO{'cu_inner'}= ($katalog->{Order}->{PCB}->{cuinner});};
												if ($katalog->{Order}->{PCB}->{datacode} =~ /^HASH/){$hashINFO{'datacode'}="$emptyText";}else{$hashINFO{'datacode'}= ($katalog->{Order}->{PCB}->{datacode});};
												if ($katalog->{Order}->{PCB}->{plate_slits} =~ /^HASH/){$hashINFO{'pth_freza'}="$emptyText";}else{$hashINFO{'pth_freza'}= ($katalog->{Order}->{PCB}->{plate_slits});};
												if ($katalog->{Order}->{PCB}->{sideplating} =~ /^HASH/){$hashINFO{'sideplating'}="$emptyText";}else{$hashINFO{'sideplating'}= ($katalog->{Order}->{PCB}->{sideplating});};
												if ($katalog->{Order}->{PCB}->{notes} =~ /^HASH/){$hashINFO{'poznamky'}="$emptyText";}else{$hashINFO{'poznamky'}= ($katalog->{Order}->{PCB}->{notes});};
												if ($katalog->{Order}->{PCB}->{order_category} =~ /^HASH/){$hashINFO{'order_category'}="$emptyText";}else{$hashINFO{'order_category'}= ($katalog->{Order}->{PCB}->{order_category});};
												if ($katalog->{Order}->{PCB}->{solderstopTOP} =~ /^HASH/){$hashINFO{'solderstopTOP'}="$emptyText";}else{$hashINFO{'solderstopTOP'}= ($katalog->{Order}->{PCB}->{solderstopTOP});};
												if ($katalog->{Order}->{PCB}->{solderstopBOT} =~ /^HASH/){$hashINFO{'solderstopBOT'}="$emptyText";}else{$hashINFO{'solderstopBOT'}= ($katalog->{Order}->{PCB}->{solderstopBOT});};
												if ($katalog->{Order}->{PCB}->{silkscreenTOP} =~ /^HASH/){$hashINFO{'silkscreenTOP'}="$emptyText";}else{$hashINFO{'silkscreenTOP'}= ($katalog->{Order}->{PCB}->{silkscreenTOP});};
												if ($katalog->{Order}->{PCB}->{silkscreenBOT} =~ /^HASH/){$hashINFO{'silkscreenBOT'}="$emptyText";}else{$hashINFO{'silkscreenBOT'}= ($katalog->{Order}->{PCB}->{silkscreenBOT});};
												if ($katalog->{Order}->{PCB}->{special_layer_construction} =~ /^HASH/){$hashINFO{'special_layer_construction'}="$emptyText";}else{$hashINFO{'special_layer_construction'}= ($katalog->{Order}->{PCB}->{special_layer_construction});};	
												if ($katalog->{Order}->{PCB}->{layer_buildup} =~ /^HASH/){$hashINFO{'layer_buildup'}="$emptyText";}else{$hashINFO{'layer_buildup'}= ($katalog->{Order}->{PCB}->{layer_buildup});};
												if ($katalog->{Order}->{PCB}->{goldfingers} =~ /^HASH/){$hashINFO{'goldfingers'}="$emptyText";}else{$hashINFO{'goldfingers'}= ($katalog->{Order}->{PCB}->{goldfingers});};
												if ($katalog->{Order}->{PCB}->{panel_processing} =~ /^HASH/){$hashINFO{'panel_processing'}="$emptyText";}else{$hashINFO{'panel_processing'}= ($katalog->{Order}->{PCB}->{panel_processing});};
												if ($katalog->{Order}->{PCB}->{min_track} =~ /^HASH/){$hashINFO{'min_track'}="$emptyText";}else{$hashINFO{'min_track'}= ($katalog->{Order}->{PCB}->{min_track});};
												if ($katalog->{Order}->{PCB}->{chamfered_borders} =~ /^HASH/){$hashINFO{'chamfered_borders'}="$emptyText";}else{$hashINFO{'chamfered_borders'}= ($katalog->{Order}->{PCB}->{chamfered_borders});};
												if ($katalog->{Order}->{PCB}->{pressfit} =~ /^HASH/){$hashINFO{'pressfit'}="$emptyText";}else{$hashINFO{'pressfit'}= ($katalog->{Order}->{PCB}->{pressfit});};
												if ($katalog->{Order}->{PCB}->{via_filling} =~ /^HASH/){$hashINFO{'via_filling'}="$emptyText";}else{$hashINFO{'via_filling'}= ($katalog->{Order}->{PCB}->{via_filling});};												
												if ($katalog->{Order}->{PCB}->{ipc_class} =~ /^HASH/){$hashINFO{'ipc_class'}="$emptyText";}else{$hashINFO{'ipc_class'}= ($katalog->{Order}->{PCB}->{ipc_class});};
												if ($katalog->{Order}->{PCB}->{panel_processing_x} =~ /^HASH/){$hashINFO{'panel_processing_x'}="$emptyText";}else{$hashINFO{'panel_processing_x'}= ($katalog->{Order}->{PCB}->{panel_processing_x});};
												if ($katalog->{Order}->{PCB}->{panel_processing_y} =~ /^HASH/){$hashINFO{'panel_processing_y'}="$emptyText";}else{$hashINFO{'panel_processing_y'}= ($katalog->{Order}->{PCB}->{panel_processing_y});};
										}
			}
	if ($hashINFO{'size_x'} > $hashINFO{'size_y'}) {
		my $tmpXsize = $hashINFO{'size_x'};
		   $hashINFO{'size_x'} = $hashINFO{'size_y'};
		   $hashINFO{'size_y'} = $tmpXsize;
	}

}
sub _PutOUspecInfo {
		my $heliosFrame = shift;
		my ($xDPSsize, $yDPSsize) =_GetDimPCB();
		my $colorText1 = 0;
		my $colorText2 = 0;
		
							my @infoPcbHelios = HegMethods->GetSalesSpec($jobName);
							
							$infoPcbHelios[0]->{' Reference desky'} = $jobName;
							$infoPcbHelios[0]->{' Rozmer desky'} = $xDPSsize . ' x ' . $yDPSsize;
							
							my $i=0;
									foreach my $item (sort keys $infoPcbHelios[0]) {
													#set color 
													unless ($infoPcbHelios[0]->{$item} eq 'Ne') {
															$colorText1 = 'black';
															$colorText2 = 'red';
													}else{
															$colorText1 = 'black';
															$colorText2 = 'black';
													}
													if ($infoPcbHelios[0]->{$item} eq 'Jeden kus') {
                        										$infoPcbHelios[0]->{$item} = '';
                        							}
                        										
													my $putTextInfo1 = $item . "=";
													my $putTextInfo2 = $infoPcbHelios[0]->{$item};
													chomp $putTextInfo2;
													if($putTextInfo2){
															my @tmpFrameH = ();
															$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
															$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo1, -fg=>"$colorText1")->pack(-side=>'left');
															$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo2, -fg=>"$colorText2",-font=> 'ARIAL 9 {bold}')->pack(-side=>'left');		
														$i++;
													}
									}
													my @tmpInfoHelios = HegMethods->GetAllByPcbId($jobName);	
													my $poznamkaTpv = $tmpInfoHelios[0]->{'poznamka_web'};
													my $heightTest;
													my $delkapath =  length($poznamkaTpv);
													if ($delkapath < 60) {
														$heightTest = 5;
													}elsif($delkapath < 90){
														$heightTest = 8;
													}elsif($delkapath < 120){
														$heightTest = 10;
													}elsif($delkapath < 150){
														$heightTest = 12;
													}else{
														$heightTest = 10;
													}
													
													my $colorTpv = 'DimGray';
													if ($poznamkaTpv) {
															$colorTpv = 'red';
													}
													my @tmpFrameH = ();
													$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrameH[$i]->Label(-text=>"Poznamka od Zakaznika",-font=>'arial 9 {bold}',-fg=>"$colorTpv")->grid(-column=>0,-row=>"$i",-columnspan=>1,-sticky=>"w");
													my $u = $i + 1;
													my $pole = $tmpFrameH[$i]->Text(-width=>30, -height=>"$heightTest")->grid(-column=>0,-row=>"$u",-columnspan=>2,-sticky=>"w",-padx=>1);
													$pole->insert("end", "$poznamkaTpv");
									
}
sub _GetDimPCB {
		$inCAM->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$StepName",data_type => 'PROF_LIMITS');
				my $pcbXsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSxmax} - $inCAM->{doinfo}{gPROF_LIMITSxmin});
				my $pcbYsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSymax} - $inCAM->{doinfo}{gPROF_LIMITSymin});
				
		return($pcbXsize, $pcbYsize);
}
sub _PutHeliosInfo {
		my $heliosFrame = shift;

							my @infoPcbHelios = HegMethods->GetUserInfoHelios($jobName);
							my $i=0;
									foreach my $item (sort keys $infoPcbHelios[0]) {
										
													my $putTextInfo1 = $item . "=";
													my $putTextInfo2 = $infoPcbHelios[0]->{$item};
													chomp $putTextInfo2;
													
													#set color 
													my $colorText1 = 'black';
													my $colorText2 = 'black';
													
													if ($item =~ /POOLing=N/) {
														$colorText1 = 'red';
														$colorText2 = 'red';
													}
													if ($item =~ /Poznamka/) {
														if ($putTextInfo2) {
																$colorText2 = 'red';
														}
													}
													if ($item =~ /Data/) {
															if ($putTextInfo2) {
																	$colorText1 = 'red';
																	$colorText2 = 'red';
															}
													}
													
													if ($item =~ /Tloustka$/) {
														if ($putTextInfo2 > 1.70 or $putTextInfo2 < 1.45) {
																$colorText1 = 'red';
																$colorText2 = 'red';
														}
													}
													
													if ($item =~ /Vysledne_formatovani/) {
														$colorText2 = 'red';
													}
													
													
													
													my @tmpFrameH = ();
													$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo1, -fg=>"$colorText1")->pack(-side=>'left');
													$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo2, -fg=>"$colorText2")->pack(-side=>'left');
									$i++;
									}
													my @tmpInfoHelios = HegMethods->GetAllByPcbId($jobName);	
													my $poznamkaTpv = $tmpInfoHelios[0]->{'poznamka_tpv'};
													my $heightTest;
													my $delkapath =  length($poznamkaTpv);
													if ($delkapath < 60) {
														$heightTest = 5;
													}elsif($delkapath < 90){
														$heightTest = 8;
													}elsif($delkapath < 120){
														$heightTest = 10;
													}elsif($delkapath < 150){
														$heightTest = 12;
													}else{
														$heightTest = 10;
													}
													
													my $colorTpv = 'DimGray';
													if ($poznamkaTpv) {
															$colorTpv = 'red';
													}
													my @tmpFrameH = ();
													$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrameH[$i]->Label(-text=>"Poznamka pro TPV",-font=>'arial 9 {bold}',-fg=>"$colorTpv")->grid(-column=>0,-row=>"$i",-columnspan=>1,-sticky=>"w");
													my $u = $i + 1;
													my $pole = $tmpFrameH[$i]->Text(-width=>30, -height=>"$heightTest")->grid(-column=>0,-row=>"$u",-columnspan=>2,-sticky=>"w",-padx=>1);
													$pole->insert("end", "$poznamkaTpv");
													
													$i++;
													$u++;
													my %maska1 = HegMethods->GetSolderMaskColor($jobName);
													my %maska2 = HegMethods->GetSolderMaskColor2($jobName);
													my %potisk1 = HegMethods->GetSilkScreenColor($jobName);
													my %potisk2 = HegMethods->GetSilkScreenColor2($jobName);
													
													#ValueConvertor->GetMaskCodeToColor($mask{'top');
													
													$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
													
													if($potisk2{'top'}){
															$u++;
															$tmpFrameH[$i]->Label(-text=>'Potisk2 ', -width=>30, -bg=>ValueConvertor->GetSilkCodeToColor($potisk2{'top'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($potisk2{'top'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($potisk1{'top'}){
															$u++;	
															$tmpFrameH[$i]->Label(-text=>'Potisk1 ', -width=>30, -bg=>ValueConvertor->GetSilkCodeToColor($potisk1{'top'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($potisk1{'top'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($maska2{'top'}){
															$u++;	
															$tmpFrameH[$i]->Label(-text=>'Maska2 ', -width=>30, -bg=>ValueConvertor->GetMaskCodeToColor($maska2{'top'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($maska2{'top'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($maska1{'top'}){
															$u++;
															$tmpFrameH[$i]->Label(-text=>'Maska1 ', -width=>30, -bg=>ValueConvertor->GetMaskCodeToColor($maska1{'top'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($maska1{'top'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($maska1{'bot'}){
															$u++;
															$tmpFrameH[$i]->Label(-text=>'Maska1 ', -width=>30, -bg=>ValueConvertor->GetMaskCodeToColor($maska1{'bot'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($maska1{'bot'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($maska2{'bot'}){
															$u++;
															$tmpFrameH[$i]->Label(-text=>'Maska2 ', -width=>30, -bg=>ValueConvertor->GetMaskCodeToColor($maska2{'bot'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($maska2{'bot'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($potisk1{'bot'}){
															$u++;	
															$tmpFrameH[$i]->Label(-text=>'Potisk1 ', -width=>30, -bg=>ValueConvertor->GetSilkCodeToColor($potisk1{'bot'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($potisk1{'bot'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
													if($potisk2{'bot'}){
															$u++;	
															$tmpFrameH[$i]->Label(-text=>'Potisk2 ', -width=>30, -bg=>ValueConvertor->GetSilkCodeToColor($potisk2{'bot'}),-fg=>_Transf_FG(ValueConvertor->GetSilkCodeToColor($potisk2{'bot'})),-borderwidth=>1, -relie=>'sunken')->grid(-column=>0,-row=>"$u",-columnspan=>10,-sticky=>"w",-padx=>2);
													}
}

sub _PutOfferToGui {
		my $OfferFrame = shift;
							my @infoPcbOffer = HegMethods->GetAllByPcbIdOffer($jobName);
							my $i=0;
							if ($infoPcbOffer[0]{'Nabidku_zpracoval'}) {
									foreach my $item (sort keys $infoPcbOffer[0]) {
													#set color 
													my $colorText1 = 'black';
													my $colorText2 = 'black';
													
													if ($item =~ /Poznamk/) {
														$colorText1 = 'black';
														$colorText2 = 'red';
													}
													if ($item =~ /Rozme/) {
														$colorText1 = 'blue';
														$colorText2 = 'blue';
													}
                        		
													my $putTextInfo1 = $item . "=";
													my $putTextInfo2 = $infoPcbOffer[0]->{$item};
													my @tmpFrame = ();
													$tmpFrame[$i] = $OfferFrame->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrame[$i] ->Label(-textvariable=>\$putTextInfo1, -fg=>"$colorText1")->pack(-side=>'left');
													$tmpFrame[$i] ->Label(-textvariable=>\$putTextInfo2, -fg=>"$colorText2")->pack(-side=>'left');
													
												
									$i++;
									}
									
									my @infoPcbOffer = HegMethods->GetExternalDoc($jobName);		
									my @dokuments = split /,/ ,$infoPcbOffer[0]->{'externi_dokumenty'};
									
									my $countOfDoc = 1;
									foreach my $oneDoc (@dokuments) {
										
											$tmpFrame[$i] = $OfferFrame->Frame(-width=>100, -height=>10)->pack(-side=>'top',-fill=>'x');
											my $tl_no=$tmpFrame[$i]->Button(-width=>'20',-text => "Externi dokument " . $countOfDoc,-command=> \sub {system("c:/Program Files (x86)/Internet Explorer/iexplore.exe", $oneDoc);},-bg=>'blue',-fg=>'white')->pack(-padx => 1, -pady => 1,-side=>'left');
											
										$i++;
										$countOfDoc++;
									}
							}else{
								$OfferFrame ->Label(-text=>'Nepripojena zadna nabidka', -fg=>'black')->pack(-side=>'top',-fill=>'y');
							}
}

sub _CheckTableRout {
  				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepName/f",data_type=>'exists');
  			 	if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
  								$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/f",data_type => 'TOOL');
  								my @hodnotyFrez = @{$inCAM->{doinfo}{gTOOLfinish_size}};
  								@hodnotyFrez = sort ({$a<=>$b} @hodnotyFrez);
  								my $minFrez = $hodnotyFrez[0];
  								$minFrez = sprintf "%0.0f",($minFrez);
  			
  								$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/f",data_type => 'TOOL');
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
			$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/m",data_type => 'TOOL');
			my @hodnotyVrtaku = @{$inCAM->{doinfo}{gTOOLfinish_size}};
			@hodnotyVrtaku = sort ({$a<=>$b} @hodnotyVrtaku);
			my $minVrtak = $hodnotyVrtaku[0];
			$minVrtak = sprintf "%0.0f",($minVrtak);
			
			$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/m",data_type => 'TOOL');
			my @hodnotyDrill = @{$inCAM->{doinfo}{gTOOLbit}};
			
			foreach my $oneDrill (@hodnotyDrill) {
				if ($oneDrill == 0) {
					push @errorMessageArr,  '- Pozor v seznamu VRTANI jsou nulove hodnoty!';
				}
			} 
}

sub _CheckTermoPoint {
	my @seznamVrstev = ();
	my $layerCount = 0;
	
	$inCAM->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
   	 my $totalRows = ${$inCAM->{doinfo}{gROWrow}}[-1];
   	 for (my $count=0;$count<=$totalRows;$count++) {
				my $rowPolarity = ${$inCAM->{doinfo}{gROWpolarity}}[$count];
				my $rowName = ${$inCAM->{doinfo}{gROWname}}[$count];
				my $rowContext = ${$inCAM->{doinfo}{gROWcontext}}[$count];
				my $rowType = ${$inCAM->{doinfo}{gROWlayer_type}}[$count];
					if ($rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
				            $layerCount ++;
				            push(@seznamVrstev,$rowName,$rowPolarity);
					}
		}
	my %hashSeznamVrstev = @seznamVrstev;


	if ($layerCount > 2) {
		foreach my $oneLay (keys %hashSeznamVrstev) {
		my $padTermalCount = 0;
		my $infoFile = $inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepName/$oneLay",data_type=>'FEATURES',options=>'break_sr',parse=>'no');
				my $padCount = 0;
				open (INFOFILE,"$infoFile");
				while (<INFOFILE>) {
					if ($_ =~ /ths/) {
						$padTermalCount ++;
					}elsif ($_ =~ /thr/) {
						$padTermalCount ++;
					}
				}
				if ($padTermalCount > 0) {
					my @errorLayers = ();
					my $valueHash = $hashSeznamVrstev{$oneLay};
						unless ($valueHash eq "negative") {
							push(@errorLayers,$oneLay);
								push @errorMessageArr, "- Zavazna chyba, vrstva @errorLayers obsahuje termobody a je nastavena jako $valueHash, skript konci - nejprve oprav.";
						} 
				}
				close INFOFILE;
				unlink $infoFile;
		}
	}
}

sub _CheckCustomerFinishHoles {
		my $jobId = shift;
		my $stepId = 'o+1';
		my $layerId = 'm';
		
		$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobId/$stepId/$layerId",data_type => 'TOOL');
				if (scalar (grep /^0$/, @{$inCAM->{doinfo}{gTOOLfinish_size}}) > 0) {
						 push @errorMessageArr , '- Pozor, spatne zadane hodnoty finish size, dopln rucne!';
				}
	return ();
}

sub _CheckStatusPriprava {
	my $jobId = shift;

	my $num = HegMethods->GetPcbOrderNumber($jobId);

	my $res = 1;

	for ( $num ; $num > 0 ; $num-- ) {

		$num = sprintf( "%02d", $num );

		if ( HegMethods->GetStatusOfOrder( $jobId . "-" . $num, 1 ) eq 'Predvyrobni priprava' ) {
			$res = 0;
			last;
		}
		
	}

		if ($res) {
			push @errorMessageArr , '- Pozor, zakazka neni ve stavu "Predvyrobni priprava" !';
		}

	return ();
}

sub _CheckLimitWithTabs {
	my $jobId = shift;
	
	my $limitKusu = 50;
		my @tmpInfoHelios = HegMethods->GetAllByPcbId($jobName);	
		my $pozadavekKusu = $tmpInfoHelios[0]->{'pocet'};
		
		if (__CheckMinAreaForTabs($jobId) == 1 and $pozadavekKusu > $limitKusu ) {
					push @errorMessageArr , "- Je prekrocen limit kusu($limitKusu) frezovanych na mustky, jestli zakazik nepozaduje panel, je nutne domluvit dodavani v panelu - jinak nelze vyrobit.Vice ve OneNotu-Nejmensi rozmer kusu na patku.";
		}	
}

sub _CheckCorrectDataCode {
	my $jobId = shift;
	my $layer = shift;
	my $step = 'o+1';
	
			unless ( Marking->DatacodeExists( $inCAM, $jobId, $step, $layer ) ) {
                               
						push @errorMessageArr , $hashINFO{datacode}.  "- Datacode je ve spatnem formatu nebo v pozadovane vrstve chybi.";
			}
}



sub __CheckMinAreaForTabs {
	my $jobId = shift;
	my $stepId = 'o+1';
	my $minArea = 400; 	#minimal value without tabs
	my $minDim = 20;	#minimal dimension
	my $infoLine = 1; # return 1 when tabs
	
 		$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$stepId/f",data_type=>'exists');
			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
 				$inCAM -> COM('display_layer',name=>'f',display=>'yes',number=>'1');
		    		$inCAM -> COM('work_layer',name=>'f');
		}

	
	# Get dimension of pcb
	my ($XsizePcb,$YsizePcb) = __GetSizeOfPcb($jobId, $stepId);
		
		$inCAM -> COM('display_layer',name=>'f',display=>'no',number=>'1');
	
		if ($XsizePcb < $minDim and $YsizePcb < $minDim) {
				return($infoLine);
		}elsif (CamCopperArea->GetProfileArea($inCAM, $jobId, $stepId) < $minArea) {
				return($infoLine);
		}else{
				return(0);
		}
}
sub _CheckCutomerNetlist {
	my $jobId = shift;
	
		unless (HegMethods->GetIdcustomer($jobId) eq '05626') { # U multi pcb to neni potreba kontrolovat
			$inCAM->INFO(units => 'mm', angle_direction => 'ccw', entity_type => 'netlist',entity_path => "$jobId/o+1/cadnet",data_type => 'EXISTS');
         			if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
         					push @errorMessageArr , "- Byl nalezen netlist zakaznika, je nutne jej porovnat s nactenymi daty, vice informaci ve OneNotu pod NETLIST - porovnani zak.IPC";
		 			}
		}
}



sub __GetSizeOfPcb {
		my $pcbId = shift;
		my $StepName = shift;
		
			$inCAM->INFO(units=>'mm',entity_type => 'step',entity_path => "$pcbId/$StepName",data_type => 'PROF_LIMITS');
				my $pcbXsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSxmax} - $inCAM->{doinfo}{gPROF_LIMITSxmin});
				my $pcbYsize = sprintf "%3.2f",($inCAM->{doinfo}{gPROF_LIMITSymax} - $inCAM->{doinfo}{gPROF_LIMITSymin});
	return($pcbXsize,$pcbYsize);
}

sub _TranformColour {
		my $colour = shift;
		
		if ($colour eq '-') {
			$colour = 'lightgrey';
		}
	return($colour);
}

sub _MoveToServer {
	 	 my $jobName = shift;
	 	 my $cestaArchivEL = 0;
	 	 my $jobFolder = 0;
	 	 			
	 	$jobFolder = uc substr($jobName,0,4);
					
					#$archivePath = '\\\\gatema.cz/fs/EL_DATA';
					
					my $archivePath = EnumsPaths->Jobs_ELTESTS;
				
						$cestaArchivEL  = "$archivePath/$jobFolder";
							unless (-e "$cestaArchivEL") {
	  							mkdir("$archivePath/$jobFolder");
							}
			 dirmove (EnumsPaths->Client_ELTESTS . $jobName,"$cestaArchivEL/$jobName");
}

sub _CompareDimPcbXml {
		my $jobId = shift;
		my $step = shift;
		my $res = 0;
		
		
		my ($pcbXsize,$pcbYsize) = __GetSizeOfPcb($jobId, $step);
	
					if ($pcbXsize > $pcbYsize) {
									my $tmpXsize = $pcbXsize;
				   						$pcbXsize = $pcbYsize;
				   						$pcbYsize = $tmpXsize;
					}
													
					unless($hashINFO{size_x} < ($pcbXsize + 1) and $hashINFO{size_x} > ($pcbXsize - 1)) {
									$res = 1;
					}
					unless($hashINFO{size_y} < ($pcbYsize + 1) and $hashINFO{size_y} > ($pcbYsize - 1)) {
									$res = 1;
					}
	return($res, $res);
}

sub _SearchCSV {
		my $jobId = shift;
		my $localPath = 'c:/pcb';
		my @listFiles = ();
		my $res = 0;
		
					find({wanted => sub {push @listFiles, $File::Find::name},no_chdir => 1}, $localPath . '/' . $jobId);

					my @tgzArr = grep /\.csv$/, @listFiles;

					if (scalar @tgzArr == 1) {
							$res = $tgzArr[0];
					}
	return($res);
}


sub _SendGerber {
	my $path = shift;
	my $res = 0;
	
	open (CSV,"$path");
				while (<CSV>) {
					if ($_ =~ /[Ww][Oo][Rr][Kk][Ii][Nn][Gg]\s[Gg][Ee][Rr][Bb][Ee][Rr]/) {
						$res = 1;
						last;
					}
				}
	close CSV;
	return($res);
}


sub _Transf_FG{
	my $color = shift;
	my $res = 'Black';
	
		if( $color eq 'Black') {
				$res = 'White';
		}
	
	return($res);
}

