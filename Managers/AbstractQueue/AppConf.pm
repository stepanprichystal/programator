#-------------------------------------------------------------------------------------------#
# Description: Can read app configuration from Config.txt files, placed in root dir of app
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AppConf;

#3th party library
use strict;
use warnings;
use Wx;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return wx color based on rgb values
sub GetColor {
	my $self = shift;
	my $key  = shift;

	my $val = $self->__GetVal($key);
	
	my @rgb = split(",", $val);
	
	chomp @rgb;
	
	for(my $i = 0; $i < scalar(@rgb); $i++){
		$rgb[$i] =~ s/\s//g;	
	} 
	 	
 
	my $clr =  Wx::Colour->new( $rgb[0], $rgb[1], $rgb[2] );
	
	return $clr;
}

# Return pure value from vonfig file
sub GetValue{
	my $self = shift;
	my $key  = shift;

	my $val =  $self->__GetVal($key);
	
	$val =~ s/^\s+|\s+$//g;
	
	return $val;
}

sub __GetVal{
	my $self = shift;
	my $key  = shift;
	
	#print STDERR $main::stylePath;
	
	unless ( -e $main::stylePath ) {
		die "Configuration style file doesn't exist";
	}

	my @lines = @{ FileHelper->ReadAsLines($main::stylePath) };
	
	@lines = grep { $_ !~ /^#/ } @lines;
 
	foreach my $l (@lines){
		my @arr = split("=", $l);
		if($arr[0] =~ /$key/){
			return $arr[1];
		}
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
