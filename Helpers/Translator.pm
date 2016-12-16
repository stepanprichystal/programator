#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::Translator;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
sub Cz {
	my $self = shift;
	my $val    = shift;
	
	my $str = "";
	
	if(!defined $val || $val eq ""){
		
		return "";
	}	
	
	if($val eq "Silk screen top"){
		
		$str = "Potisk top";
		
	}elsif($val eq "Silk screen bot"){
	
		$str = "Potisk bot";
		
	}elsif($val eq "Solder mask top"){
	
		$str = "Maska top";
		
	}elsif($val eq "Solder mask bot"){
	
		$str = "Maska bot";
		
	}elsif($val eq "Component side"){
	
		$str = "Strana sou��stek";
		
	}elsif($val eq "Solder side"){
	
		$str = "Strana spoj�";
	}
	elsif($val eq "Green"){
	
		$str = "Zelen�";
		
	}elsif($val eq "Black"){
	
		$str = "�ern�";
		
	}elsif($val eq "White"){
	
		$str = "B�l�";
		
	}elsif($val eq "Blue"){
	
		$str = "Modr�";
		
	}elsif($val eq "Transparent"){
	
		$str = "Transparentn�";
		
	}elsif($val eq "Red"){
	
		$str = "�erven�";
		
	}elsif($val eq "Yellow"){
	
		$str = "�lut�";
		
	}
	
	
	
	else{
		
		die "Error when translating word:$val .\n";
	}
	 
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

