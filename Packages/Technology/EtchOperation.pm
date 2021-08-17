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
use aliased 'Enums::EnumsGeneral';

#use Genesis;

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return value of compensation according to settings Miroslav Tobola.
# TODO - this function need reimplement, too much exception
sub GetCompensation {
	my $self        = shift;
	my $cuThickness = shift;    # base layer Cu thickness
	my $constrClass = shift;
	my $isPlated    = shift;    # it means basic cuThickness is plated (+ 25um)
	my $etchType    = shift;    # EnumsGeneral->Etching_PATTERN / EnumsGeneral->Etching_TENTING

	die "PCB Cu thickness is not defined"       if ( !defined $cuThickness );
	die "PCB construction class is not defined" if ( !defined $constrClass );

	my %compensationAttr = ();

	# Another temporary solutin for 9 class
	if ( $constrClass == 9 ) {

		if ( $isPlated && $cuThickness <= 18 && $etchType eq EnumsGeneral->Etching_PATTERN ) {
			return 15;
		}

		if ( !$isPlated && $cuThickness == 18 ) {
			return 20;
		}

		return undef;
	}

	# Temporary solution 12µm Cu have same compensation as 9µm
	$cuThickness = 9 if ( $cuThickness == 12 );

	if ( !$isPlated ) {
		%compensationAttr = (
							  '5' => {
									   'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
									   'space' => 80
							  },
							  '9' => {
									   'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
									   'space' => 80
							  },
							  '12' => {
										'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
										'space' => 80
							  },
							  '18' => {
										'level' => [ 1.1, 1 ],
										'space' => 80
							  },
							  '30' => {
										'level' => [ 0.55, 0.55, 0.55, 0.55, 0.55, 0.1 ],
										'space' => 95
							  },
							  '34' => {
										'level' => [ 0.55, 0.55, 0.55, 0.55, 0.55, 0.1 ],
										'space' => 95
							  },
							  '35' => {
										'level' => [ 0.55, 0.55, 0.55, 0.55, 0.55, 0.1 ],
										'space' => 95
							  },
							  '37' => {
										'level' => [ 0.55, 0.55, 0.55, 0.55, 0.55, 0.1 ],
										'space' => 95
							  },
							  '43' => {
										'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1, 0.90, 0.45, 0.1 ],
										'space' => 95
							  },
							  '60' => {
										'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 0.8 ],
										'space' => 100
							  },
							  '70' => {
										'level' => [ 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7 ],
										'space' => 100
							  },
							  '75' => {
										'level' => [ 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 0.65 ],
										'space' => 100
							  },
							  '95' => {
										'level' => [ 2, 1.9, 1.8, 1.7, 0.8 ],
										'space' => 120
							  },
							  '105' => {
										 'level' => [ 0.75, 0.75, 0.75, 0.75, 0.75 ],
										 'space' => 120
							  },
							  '130' => {
										 'level' => [ 2, 1.9, 1.8, 1.7, 1.1, 1.15 ],
										 'space' => 145
							  },
							  '140' => {
										 'level' => [1.75],
										 'space' => 155
							  }
		);
	}
	else {
		%compensationAttr = (
							  '5' => {
									   'level' => [ 2.3, 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
									   'space' => 80
							  },
							  '9' => {
									   'level' => [ 2.2, 2.1, 2.0, 1.9, 1.8, 1.7, 1.6 ],
									   'space' => 80
							  },
							  '12' => {
										'level' => [ 2.2, 2.1, 2.0, 1.9, 1.8, 1.7, 1.6 ],
										'space' => 80
							  },
							  '18' => {
										'level' => [ 2.2, 2.1, 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
										'space' => 80
							  },
							  '35' => {
										'level' => [ 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1 ],
										'space' => 100
							  },
							  '70' => {
										'level' => [ 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0 ],
										'space' => 100
							  },
							  '105' => {
										 'level' => [ 2, 1.9, 1.8, 1.7, 1.4 ],
										 'space' => 150
							  },
							  '140' => {
										 'level' => [ 2, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0 ],
										 'space' => 170
							  }
		);
	}
	my $minimumSpace = $compensationAttr{$cuThickness}->{'space'};

	my @compensationLevel = @{ $compensationAttr{$cuThickness}->{'level'} };

	my $valueKompenzace;
	my $customerLine;

	#my $genesis = new Genesis; #Pozor Upraveno

	if ( $constrClass == 3 ) {
		$customerLine = 400;
	}
	elsif ( $constrClass == 4 ) {
		$customerLine = 300;
	}
	elsif ( $constrClass == 5 ) {
		$customerLine = 200;
	}
	elsif ( $constrClass == 6 ) {
		$customerLine = 150;
	}
	elsif ( $constrClass == 7 ) {
		$customerLine = 125;
	}
	elsif ( $constrClass == 8 ) {
		$customerLine = 100;
	}

	my $countIndex = 0;
	my $maxIndex   = @compensationLevel;
	while (1) {
		if ( ( $customerLine - ( $compensationLevel[$countIndex] * $cuThickness ) >= $minimumSpace ) ) {
			$valueKompenzace = $customerLine - ( $customerLine - ( $compensationLevel[$countIndex] * $cuThickness ) );
			my $min = $customerLine - $valueKompenzace;
			last;
		}
		$countIndex++;

		if ( $countIndex > $maxIndex ) {
			$valueKompenzace = 0;
			last;
		}
	}

	unless ($valueKompenzace) {
		$valueKompenzace = undef;
	}
	else {
		$valueKompenzace = sprintf "%.0f", ($valueKompenzace);
	}

	return ($valueKompenzace);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Technology::EtchOperation';

	my $cuThickness = 5;
	my $class       = 9;
	my $plated      = 1;

	print EtchOperation->GetCompensation( $cuThickness, $class, $plated );

}

1;
