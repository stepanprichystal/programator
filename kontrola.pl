#!/usr/bin/perl

use warnings;


use Genesis;

use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Tk::LabFrame;
use XML::Simple;
use Data::Dumper;


use lib qw(//incam/incam_server/site_data/scripts);

use aliased 'Connectors::HeliosConnector::HegMethods';



unless ($ENV{JOB}) {
	$jobName = shift;
	$StepName = shift;
}else{
	$jobName = "$ENV{JOB}";
	$StepName = "$ENV{STEP}";
}

$genesis = new Genesis;

my %hashXML = ();
my %hashINFO = ();
my @errorMessageArr = ();

my $main = MainWindow->new;
$main->title('Informace o DPS');
			$mainFrame= $main->Frame(-width=>100, -height=>80)->pack(-side=>'top', -fill=>'both');
				$topFrame = $mainFrame->Frame(-width=>400, -height=>150)->pack(-side=>'top');
						$topFrameLeft = $topFrame->Frame(
												-width=>100, 
												-height=>150)
												->pack(-side=>'left',-fill=>'y');
										$topFrameLeftTop = $topFrameLeft->LabFrame(
																	-label=>"Informace Helios",
																	-width=>100, 
																	-height=>150)
																	->pack(-side=>'top');
						$topFrameMiddle = $topFrame->Frame(
												-width=>100, 
												-height=>150)
												->pack(-side=>'left',-fill=>'y');
										$topFrameMiddleTop = $topFrameMiddle->LabFrame(
																	-label=>"Objednavka XML",
																	-width=>100, 
																	-height=>150)
																	->pack(-side=>'top');
						$topFrameRight = $topFrame->Frame(
												-width=>100, 
												-height=>150)
												->pack(-side=>'left',-fill=>'y');
										$topFrameRightTop = $topFrameRight->LabFrame(
																	-label=>"Nabidka",
																	-width=>100, 
																	-height=>150)
																	->pack(-side=>'top',-fill=>'both');
								_PutHeliosInfo($topFrameLeftTop);
								_PutOfferToGui($topFrameRightTop);
								_PutXMLorder($topFrameMiddleTop);
               			
				$middleFrame1 = $mainFrame->Frame(-width=>400, -height=>150)->pack(-side=>'top',-fill=>'both');
											$mypodframe = $middleFrame1->LabFrame(
																	-width=>'100', 
																	-height=>'70',
																	-label=>"Pozmanky k zakaznikovi",
																	-font=>'normal 9 {bold }',
																	-labelside=>'top',
																	-bg=>'lightgrey',
																	-borderwidth=>'3')
																	->pack(-fill=>'both',-side=>'top');
																	
											$mypodframe ->Label(-textvariable=>\HegMethods->GetTpvCustomerNote($jobName), -fg=>"blue")->pack(-side=>'top',-fill=>'both');
				$middleFrame2 = $mainFrame->Frame(-width=>400, -height=>150)->pack(-side=>'top',-fill=>'both');
											$middleFrame2Top = $middleFrame2->LabFrame(
																	-label=>"Zjistene chyby",
																	-width=>100, 
																	-height=>50)
																	->pack(-side=>'left',-fill=>'both');
											my $rowStart=0;
											_CheckTableDrill();
											_CheckTableRout();
											_CheckTermoPoint();
											$tmpFrameInfo = $middleFrame2Top->Frame(-width=>200, -height=>10)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
											foreach my $item (@errorMessageArr) {
																	$tmpFrameInfo ->Label(-textvariable=>\$item, -fg=>"red")->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"w");
																	$rowStart++;
											}
				$botFrame = $mainFrame->Frame(-width=>400, -height=>150)->pack(-side=>'bottom');
				$tl_no=$botFrame->Button(-width=>'120',-text => "POKRACOVAT",-command=> \sub {$main->destroy},-bg=>'grey')->pack(-fill=>'both',-padx => 1, -pady => 1,-side=>'right');
				
$main->MainLoop;

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
				__GetValueXML($hashXML{$tmpPole[0]}, $outputDir, $articleid);
									if (%hashXML) {	
										
													$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$StepName",data_type => 'PROF_LIMITS');
													my $pcbXsize = sprintf "%3.2f",($genesis->{doinfo}{gPROF_LIMITSxmax} - $genesis->{doinfo}{gPROF_LIMITSxmin});
													my $pcbYsize = sprintf "%3.2f",($genesis->{doinfo}{gPROF_LIMITSymax} - $genesis->{doinfo}{gPROF_LIMITSymin});
	
													if ($pcbXsize > $pcbYsize) {
																my $tmpXsize = $pcbXsize;
		   															$pcbXsize = $pcbYsize;
		   															$pcbYsize = $tmpXsize;
													}
													
													my $viewInfo = 0;
													my $viewInfo1 = 0;
													my $viewInfo2 = 0;
													my $viewInfo3 = 0;
													
													unless($hashINFO{size_x} < ($pcbXsize + 1) and $hashINFO{size_x} > ($pcbXsize - 1)) {
															$viewInfo = 1;
															$viewInfo1 = 1;
													}
													unless($hashINFO{size_y} < ($pcbYsize + 1) and $hashINFO{size_y} > ($pcbYsize - 1)) {
															$viewInfo = 1;
															$viewInfo1 = 1;
													}
													
													my ($silkPCBtop, $silkPCBbot) = 0;
													$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/pc",data_type=>'exists');
									    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									    							$silkPCBtop = 1;
									    					}
									    			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/ps",data_type=>'exists');
									    					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									    							$silkPCBbot = 1;
									    					}
									    			if (($hashINFO{silkscreenTOP} eq 'prazdna' and $silkPCBtop == 1) or ($hashINFO{silkscreenTOP} ne 'prazdna' and $silkPCBtop == 0)) {
									    							$viewInfo = 1;
									    							$viewInfo2 = 1;
									    			}
													if (($hashINFO{silkscreenBOT} eq 'prazdna' and $silkPCBbot == 1) or ($hashINFO{silkscreenBOT} ne 'prazdna' and $silkPCBbot == 0)) {
									    							$viewInfo = 1;
									    							$viewInfo2 = 1;
									    			}
									    							
													if ($hashINFO{special_layer_construction} eq 'yes') {
																	$viewInfo3 = 1;
													}
													
													
													
													
													my $rowStart = 0;
													$framegrid = $orderFrame->Frame(-width=>200, -height=>150)->grid(-column=>0,-row=>0,-columnspan=>2,-sticky=>"news");
													
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozdil v rozmeru",-font=>'arial 10 {bold}',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"news");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Nesedi potisk v datech / objednavka",-font=>'arial 10 {bold}',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"news");
													}
													if($viewInfo){
													$rowStart++;
													$framegrid->Label(-text=>"Cislo objednavky",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{order_num}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo){
													$rowStart++;
													$framegrid->Label(-text=>"Nazev DPS",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{pcb_name}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozmer X",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{size_x}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo1){
													$rowStart++;
													$framegrid->Label(-text=>"Rozmer Y",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{size_y}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Potisk TOP",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{silkscreenTOP}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if($viewInfo2){
													$rowStart++;
													$framegrid->Label(-text=>"Potisk BOT",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{silkscreenBOT}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													if ($viewInfo3){
													$rowStart++;
													$framegrid->Label(-text=>"Special stackup",-font=>'arial 9',-fg=>'red')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{special_layer_construction}",-font=>'arial 9',-fg=>'red')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													}
													
													$rowStart++;
													$framegrid->Label(-text=>"Cu OUTER",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{cu_outer}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													$rowStart++;
													$framegrid->Label(-text=>"Cu INNER",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{cu_inner}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													$rowStart++;
													$framegrid->Label(-text=>"Material",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{material}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													$rowStart++;
													$framegrid->Label(-text=>"Pocet vrstev",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{pocet_vrstev}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
													$rowStart++;
													$framegrid->Label(-text=>"Sideplating",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{sideplating}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													$rowStart++;
													$framegrid->Label(-text=>"Prokovena freza",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{pth_freza}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													
													$rowStart++;
													$framegrid->Label(-text=>"Datacode",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>1,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$framegrid->Label(-text=>"$hashINFO{datacode}",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>2,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
									
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
													$framegrid->Label(-text=>"Poznamka",-font=>'arial 9',-fg=>'DimGray')->grid(-column=>0,-row=>"$rowStart",-columnspan=>1,-sticky=>"w");
													$pole = $framegrid->Text(-width=>30, -height=>"$heightTest")->grid(-column=>1,-row=>"$rowStart",-columnspan=>2,-sticky=>"w",-padx=>1);
													$pole->insert("end", "$hashINFO{poznamky}");				
									}else{
													$framegrid = $frameright->Frame(-width=>200, -height=>150)->grid(-column=>0,-row=>0,-columnspan=>3);
													$framegrid->Label(-text=>"                            NENASEL JSEM XML",-font=>'arial 10',-fg=>'blue')->grid(-column=>0,-row=>1);
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
												my $emptyText = 'prazdna';
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
												if ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenTOP} =~ /^HASH/){$hashINFO{'silkscreenTOP'}="$emptyText";}else{$hashINFO{'silkscreenTOP'}= ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenTOP});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenBOT} =~ /^HASH/){$hashINFO{'silkscreenBOT'}="$emptyText";}else{$hashINFO{'silkscreenBOT'}= ($katalog->{Order}->[$countPCB]->{PCB}->{silkscreenBOT});};
												if ($katalog->{Order}->[$countPCB]->{PCB}->{special_layer_construction} =~ /^HASH/){$hashINFO{'special_layer_construction'}="$emptyText";}else{$hashINFO{'special_layer_construction'}= ($katalog->{Order}->[$countPCB]->{PCB}->{special_layer_construction});};
										}
								}else{
									last;
								}
						$countPCB++
					}
			}else{	
										# v pripade HASH je xml struktura odlisna
										if ($katalog->{Order}->{PCB}->{articleid} eq $articleid) {
												my $emptyText = 'prazdna';
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
												if ($katalog->{Order}->{PCB}->{silkscreenTOP} =~ /^HASH/){$hashINFO{'silkscreenTOP'}="$emptyText";}else{$hashINFO{'silkscreenTOP'}= ($katalog->{Order}->{PCB}->{silkscreenTOP});};
												if ($katalog->{Order}->{PCB}->{silkscreenBOT} =~ /^HASH/){$hashINFO{'silkscreenBOT'}="$emptyText";}else{$hashINFO{'silkscreenBOT'}= ($katalog->{Order}->{PCB}->{silkscreenBOT});};
												if ($katalog->{Order}->{PCB}->{special_layer_construction} =~ /^HASH/){$hashINFO{'special_layer_construction'}="$emptyText";}else{$hashINFO{'special_layer_construction'}= ($katalog->{Order}->{PCB}->{special_layer_construction});};
												
										}
			}
	if ($hashINFO{'size_x'} > $hashINFO{'size_y'}) {
		my $tmpXsize = $hashINFO{'size_x'};
		   $hashINFO{'size_x'} = $hashINFO{'size_y'};
		   $hashINFO{'size_y'} = $tmpXsize;
	}

}
sub _PutHeliosInfo {
		my $heliosFrame = shift;

							my @infoPcbHelios = HegMethods->GetUserInfoHelios($jobName);
							my $i=0;
									foreach my $item (sort keys $infoPcbHelios[0]) {
													#set color 
													my $colorText1 = 'black';
													my $colorText2 = 'black';
													
													if ($item =~ /POOLing=N/) {
														$colorText1 = 'red';
														$colorText2 = 'red';
													}
                        		
													my $putTextInfo1 = $item . "=";
													my $putTextInfo2 = $infoPcbHelios[0]->{$item};
													$tmpFrameH[$i] = $heliosFrame ->Frame(-width=>200, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo1, -fg=>"$colorText1")->pack(-side=>'left');
													$tmpFrameH[$i] ->Label(-textvariable=>\$putTextInfo2, -fg=>"$colorText2")->pack(-side=>'left');
													
												
									$i++;
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
													$tmpFrame[$i] = $OfferFrame->Frame(-width=>200, -height=>10)->pack(-side=>'top',-fill=>'x');
													$tmpFrame[$i] ->Label(-textvariable=>\$putTextInfo1, -fg=>"$colorText1")->pack(-side=>'left');
													$tmpFrame[$i] ->Label(-textvariable=>\$putTextInfo2, -fg=>"$colorText2")->pack(-side=>'left');
													
												
									$i++;
									}
							}else{
								$OfferFrame ->Label(-text=>'Nepripojena zadna nabidka', -fg=>'black')->pack(-side=>'top',-fill=>'y');
							}
}

sub _CheckTableRout {
  				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepName/f",data_type=>'exists');
  			 	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
  								$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/f",data_type => 'TOOL');
  								@hodnotyFrez = @{$genesis->{doinfo}{gTOOLfinish_size}};
  								@hodnotyFrez = sort ({$a<=>$b} @hodnotyFrez);
  								$minFrez = $hodnotyFrez[0];
  								$minFrez = sprintf "%0.0f",($minFrez);
  			
  								$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/f",data_type => 'TOOL');
  								@hodnotyFrez = @{$genesis->{doinfo}{gTOOLdrill_size}};
  			
  						foreach my $oneFrez (@hodnotyFrez) {
  								if ($oneFrez == 0) {
  									push @errorMessageArr, '- Pozor v seznamu FREZOVANI jsou nulove hodnoty = vetsi vrtak nez 6.50mm';
  								}
  						}
  			} 	
  		return();
}
sub _CheckTableDrill {
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/m",data_type => 'TOOL');
			@hodnotyVrtaku = @{$genesis->{doinfo}{gTOOLfinish_size}};
			@hodnotyVrtaku = sort ({$a<=>$b} @hodnotyVrtaku);
			$minVrtak = @hodnotyVrtaku[0];
			$minVrtak = sprintf "%0.0f",($minVrtak);
			
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$StepName/m",data_type => 'TOOL');
			@hodnotyDrill = @{$genesis->{doinfo}{gTOOLbit}};
			
			foreach my $oneDrill (@hodnotyDrill) {
				if ($oneDrill == 0) {
					push @errorMessageArr,  '- Pozor v seznamu VRTANI jsou nulove hodnoty!';
				}
			} 
}

sub _CheckTermoPoint {
	
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
   	 my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
   	 for ($count=0;$count<=$totalRows;$count++) {
				my $rowPolarity = ${$genesis->{doinfo}{gROWpolarity}}[$count];
				my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
				my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
				my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
					if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
				            $layerCount ++;
				            push(@seznamVrstev,$rowName,$rowPolarity);
					}
		}
	%hashSeznamVrstev = @seznamVrstev;


	if ($layerCount > 2) {
		foreach $oneLay (keys %hashSeznamVrstev) {
		my $padTermalCount = 0;
		my $infoFile = $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepName/$oneLay",data_type=>'FEATURES',options=>'break_sr',parse=>'no');
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
					$valueHash = $hashSeznamVrstev{$oneLay};
						unless ($valueHash eq "negative") {
							push(@errorLayers,$oneLay);
								push @errorMessageArr, "- Zavazna chyba, vrstva @errorLayers obsahuje termobody a je nastavena jako $valueHash, skript konci - nejprve oprav.";
							$quickExist = 1;
						} 
				}
				close INFOFILE;
				unlink $infoFile;
		}
	}
}
