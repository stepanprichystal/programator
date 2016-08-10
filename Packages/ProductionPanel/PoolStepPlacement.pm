
#-------------------------------------------------------------------------------------------#
# Description: Placement pool step to the production panel according to csv file from GatemaOptimizer
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::PoolStepPlacement;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub PoolStepPlace {
	my $self  = shift;
	my $inCam = shift;
	my $pcbId = shift;
	my $csvFile = shift;
	my $borderLeft = shift;
	my $borderBot = shift;


			my @inportPole = ();
			my $pocetJobs;
			my %hashOnlyOneJobs;
			my @handleCSV = qw (jobName placeX placeY dimX dimY rotace);
			
			
			if($csvFile){
			    	open (CSVFILE,"$csvFile");
			            	while (<CSVFILE>) {
											 @inportPole = split /\"/,$_;
											 $indexIN = 0;
											 $pocetJobs++;
											 		foreach my $item (@inportPole) {
											 			if ($item ne "") {
											 				unless($item eq "\n") {
																	unless ($item eq ",") {
																			if ($item =~ /([DdFf]\d{5})\-\d{2}/) {
																					$item = lc$1;
																					$kontakt{$pocetJobs}{$handleCSV[$indexIN]} = $item;
																					$hashOnlyOneJobs{$item} = 1;
																			}else{
																					$kontakt{$pocetJobs}{$handleCSV[$indexIN]} = $item;
																			}
																			$indexIN++;
																			$Colum++;
																	}
															}
														}
													}
			        	    }
						close CSVFILE;
			}
			#rozmisteni
			for ($i=1;$i<=$pocetJobs;$i++) {
				#jobName placeX placeY dimX dimY rotace);
				my $job = $kontakt{$i}{'jobName'};
				my $placeX = $kontakt{$i}{'placeX'} + $borderLeft;
				my $placeY = $kontakt{$i}{'placeY'} + $borderBot;
				my $rotate = $kontakt{$i}{'rotace'};
					if($job eq $pcbId) {
						$job = 'o+1';
					}
					if($rotate == 1) {
						$rotate = 90;
					}else{
						$rotate = 0;
					}
					$inCam->COM('sr_tab_add',line=>"$i",step=>"$job",x=>"$placeX",y=>"$placeY",nx=>'1',ny=>'1',angle=>"$rotate");
			}
}
1;

