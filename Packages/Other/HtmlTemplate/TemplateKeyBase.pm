
#-------------------------------------------------------------------------------------------#
# Description: This is template class
# Allow add and keep keys and values for html template
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::HtmlTemplate::TemplateKeyBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Other::HtmlTemplate::KeyItem';

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

	return %{ $self->{'keys'} };
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

