
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ObjectStorable::JsonStorable::JsonStorable;

#3th party library
use strict;
use warnings;
use JSON;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"json"} = JSON->new();

	$self->{"json"}->convert_blessed( [1] );

	return $self;
}

sub Encode {
	my $self = shift;
	my $ref  = shift;

	my $serialized = $self->{"json"}->pretty->encode($ref);

	return $serialized;

}

sub Decode {
	my $self       = shift;
	my $serialized = shift;

	# 1) Decode string
	my $decoded = $self->{"json"}->decode($serialized);

	# 2) Find hash ref, which are serialized object (contains property __CLASS__)

	$self->__RecursiveDecode($decoded);
	
	return $decoded;

}

sub __RecursiveDecode {
	my $self       = shift;
	my $ref = shift;

	my $ref_type = ref $ref;

	if ( $ref_type eq "ARRAY" ) {
		foreach my $arritem ( @{$ref} ) {

			if ( ref($arritem) ) {

				$self->__RecursiveDecode($arritem);
			}

		}
	}
	elsif ( $ref_type eq "HASH" ) {
		foreach my $key ( keys %{$ref} ) {

			if ( ref( $ref->{$key} ) ) {

				$self->__RecursiveDecode( $ref->{$key} );
			}

		}
	}
	else {

		die "Ref type:$ref_type deserialiyation is not implemented";
	}

	# Check pottentional object structure
	# If find property __CLASS__, convert to object
	if ( ref($ref) && $ref_type eq "HASH" ) {

		if ( defined $ref->{"__CLASS__"} ) {

			$ref = bless( $ref, $ref->{"__CLASS__"} );
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

