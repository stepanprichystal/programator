
#-------------------------------------------------------------------------------------------#
# Description: Represent general strucure for passing information about result of some operation
# Allow keep:
# - Operation result
# - Errors, which happend during operation
# - Warnings, which happend during operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ItemResult::ItemResult;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ItemResult::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#events
	$self->{"itemId"} = shift;

	my $result = shift;

	if ( defined $result ) {
		$self->{"result"} = $result;
	}
	else {
		$self->{"result"} = Enums->ItemResult_Succ;
	}

	my @errors = ();
	$self->{"errors"} = \@errors;
	my @warnings = ();
	$self->{"warnings"} = \@warnings;

	return $self;    # Return the reference to the hash.
}

sub Create {
	my $self = shift;

	return ItemResult->new(-1)

}

sub AddError {
	my $self = shift;
	my $mess = shift;
	$self->{"result"} = Enums->ItemResult_Fail;

	push( @{ $self->{"errors"} }, $mess );
}

sub AddWarning {
	my $self = shift;
	my $mess = shift;
	$self->{"result"} = Enums->ItemResult_Fail;

	push( @{ $self->{"warnings"} }, $mess );
}

sub ItemId {
	my $self = shift;
	return $self->{"itemId"};

}

sub Result {
	my $self = shift;
	return $self->{"result"};

}

sub SetItemId {
	my $self = shift;
	my $itemId = shift;
	$self->{"itemId"} = $itemId;

}

sub GetErrorStr {
	my $self = shift;

	my $str = "";

	foreach ( @{ $self->{"errors"} } ) {
		$str .= " - " . $_ . "\n";
	}

	return $str;
}

sub GetWarningStr {
	my $self = shift;

	my $str = "";

	foreach ( @{ $self->{"warnings"} } ) {
		$str .= " - " . $_ . "\n";
	}

	return $str;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

