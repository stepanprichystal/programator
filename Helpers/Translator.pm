
#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::Translator;

#3th party library
 
use utf8; 
 
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
sub GetNifCodeValue {
	my $self = shift;
	my $code = shift;

	my $info = "";

	# inner layer
	if ( $code =~ /^pc$/i ) {

		$info = "Silk screen top";
	}

	elsif ( $code =~ /^ps$/i ) {

		$info = "Silk screen bot";
	}

	elsif ( $code =~ /^mc$/i ) {

		$info = "Solder mask top";
	}
	elsif ( $code =~ /^ms$/i ) {

		$info = "Solder mask bot";
	}
	elsif ( $code =~ /^c$/i ) {

		$info = "Component side";
	}
	elsif ( $code =~ /^s$/i ) {

		$info = "Solder side";
	
	}elsif ( $code =~ /^v(\d)$/i ) {

		$info = "Inner layer $1";
	}

	return $info;
}
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
	
		$str = "Strana součástek";
		
	}elsif($val eq "Solder side"){
	
		$str = "Strana spojů";
		
	}elsif($val =~ /Inner layer (\d)/){
		
		 $str = "Vnitřní vrstva $1";
	}
	elsif($val eq "Green"){
	
		$str = "Zelená";
		
	}elsif($val eq "Black"){
	
		$str = "Černá";
		
	}elsif($val eq "White"){
	
		$str = "Bílá";
		
	}elsif($val eq "Blue"){
	
		$str = "Modrá";
		
	}elsif($val eq "Transparent"){
	
		$str = "Transparentní";
		
	}elsif($val eq "Red"){
	
		$str = "Červená";
		
	}elsif($val eq "Yellow"){
	
		$str = "Žlutá";
		
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

