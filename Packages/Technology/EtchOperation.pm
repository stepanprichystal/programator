#-------------------------------------------------------------------------------------------#
# Description: Contain special function, for etching
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Technology::EtchOperation;

#3th party library
use strict;
use warnings;
 

#local library
use aliased 'CamHelpers::CamHelper';
#use Genesis;
 

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#


## return value of kompenzation according to settings Miroslav Tobola.
sub GetCompensation {
		my $self = shift;
		my $cuThickness = shift;
		my $constrClass = shift;
		my $innerPosition = shift;
		my %compensationAttr = ();
		
		#print STDERR "MED $cuThickness $constrClass";
		
		if ($innerPosition) {
					   %compensationAttr = (
									'5' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>80
											 },
									'9' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>80
											 },
									'18' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>80
											},
									'30' => {'level'=> [1.5, 1.4, 1.3, 1.2, 1.1, 1, 0.65], 
											 'space'=>80
											},
									'34' => {'level'=> [1.4, 1.3, 1.1, 1, 0.5], 
											 'space'=>80
											},
									'35' => {'level'=> [1.4, 1.3, 1.1, 1, 0.5], 
											 'space'=>80
											},
									'37' => {'level'=> [1.4, 1.3, 1.2, 1.1, 1, 0.5], 
											 'space'=>80
											},
									'43' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1, 0.45], 
											 'space'=>80
											},
									'60' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 0.8], 
											 'space'=>100
											},
									'70' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 0.7], 
											 'space'=>100
											},
									'75' => {'level'=> [1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 0.65], 
											 'space'=>100
											},
									'95' => {'level'=> [2, 1.9, 1.8, 1.7, 0.8],
											 'space'=>120
											},
									'105' => {'level'=> [2, 1.9, 1.8, 1.7, 0.75],
											 'space'=>120
											},
									'130' => {'level'=> [2, 1.9, 1.8, 1.7, 1.1, 1.15], 
											 'space'=>145
											},
									'140' => {'level'=> [1.75], 
											 'space'=>155
											}
						);
		}else{
						%compensationAttr = (
									'5' => {'level'=> [2.3, 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>80
											 },
									'9' => {'level'=> [3.9, 3.3, 3.2, 2.2, 2.1, 2.0, 1.9, 1.8, 1.7, 1.6], 
											 'space'=>80
											 },
									'18' => {'level'=> [2.2, 2.1, 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>80
											},
									'35' => {'level'=> [2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1], 
											 'space'=>100
											},
									'70' => {'level'=> [2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0], 
											 'space'=>100
											},
									'105' => {'level'=> [2, 1.9, 1.8, 1.7, 1.4],
											 'space'=>150
											}
						);
		}
		my $minimumSpace = $compensationAttr{$cuThickness}->{'space'};


		my @compensationLevel = @{$compensationAttr{$cuThickness}->{'level'}};
		
		my $valueKompenzace;
		my $customerLine;
		
		#my $genesis = new Genesis; #Pozor Upraveno
		
		
					if($constrClass == 3) {
							$customerLine = 400;
				}elsif($constrClass == 4) {
							$customerLine = 300;
				}elsif($constrClass == 5) {
							$customerLine = 200;
				}elsif($constrClass == 6) {
							$customerLine = 150;
				}elsif($constrClass == 7) {
							$customerLine = 125;
				}elsif($constrClass == 8) {
							$customerLine = 100;
				}

		my $countIndex = 0;
		my $maxIndex = @compensationLevel;
		while (1) {
				if (($customerLine - ($compensationLevel[$countIndex] * $cuThickness) >= $minimumSpace)) {
							$valueKompenzace = $customerLine - ($customerLine - ($compensationLevel[$countIndex] * $cuThickness));
							my $min = $customerLine - $valueKompenzace;
							last;
				}
			$countIndex++;

			if ($countIndex > $maxIndex) {
					$valueKompenzace = 0;
					last;
			}
		}
		
		
		unless ($valueKompenzace){
			$valueKompenzace = undef;
		}else{
			$valueKompenzace = sprintf "%.0f",($valueKompenzace);
		}

	return($valueKompenzace);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 

}

1;
