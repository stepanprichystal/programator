#-------------------------------------------------------------------------------------------#
# Description: Can read app configuration from Config.txt files
# config path is set in global variable $main::configPath
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::AppConf;

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

sub new {
	my $self = shift;
	my $path = shift;
	$self = {};
	bless $self;

	$self->{"path"} = $path;

	return $self;
}

# Return wx color based on rgb values
sub GetColor {
	my $self = shift;
	my $key  = shift;

	my $val = $self->__GetVal($key);

	my @rgb = split( ",", $val );

	chomp @rgb;

	for ( my $i = 0 ; $i < scalar(@rgb) ; $i++ ) {
		$rgb[$i] =~ s/\s//g;
	}

	my $clr = Wx::Colour->new( $rgb[0], $rgb[1], $rgb[2] );

	return $clr;
}

# Return pure value from vonfig file
sub GetValue {
	my $self = shift;
	my $key  = shift;

	my $val = $self->__GetVal($key);


	$val =~ s/^\s+|\s+$//g;

	return $val;
}

sub __GetVal {
	my $self = shift;
	my $key  = shift;

	#print STDERR $main::configPath;

	my $confPath = undef;

	if ( ref($self) && defined $self->{"path"} ) {

		$confPath = $self->{"path"};
	}
	else {

		$confPath = $main::configPath;
	}
	
	unless ( -e $confPath ) {
			die "Configuration style file $confPath doesn't exist. Key: $key";
	}

	my @lines = @{ FileHelper->ReadAsLines($confPath) };

	@lines = grep { $_ !~ /^#/ } @lines;


	my $keyFound = 0;
	my $val = undef;
	
	foreach my $l (@lines) {
		my @arr = split( "=", $l );
		if ( $arr[0] =~ /$key/ ) {
			
			$keyFound = 1;
			$val = $arr[1];
			last;
		}
	}
 
	die "Key: $key is not defined in configuration file path: $confPath" unless($keyFound);
		
	die "Value is not defined for key: $key, conf path: $confPath" unless(defined $val);
	
	return $val;

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

