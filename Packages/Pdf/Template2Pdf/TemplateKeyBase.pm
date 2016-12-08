
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::Template2Pdf::TemplateKeyBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::Template2Pdf::KeyItem';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %keys = ();
	$self->{'keys'} = \%keys;

	return $self;    # Return the reference to the hash.
}

sub GetKeyData {
	my $self = shift;

	return %{$self->{'keys'}};
}

sub _SaveKeyData {
	my $self   = shift;
	my $key    = shift;
	my $enText = shift;
	my $czText = shift;

	if ( !defined $czText || $czText eq "" ) {

		$czText = $enText;
	}

	$key = "key_" . $key;

	$self->{'keys'}->{$key} = KeyItem->new( $key, $enText, $czText );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

