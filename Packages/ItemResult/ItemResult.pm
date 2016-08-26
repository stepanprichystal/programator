
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
	
	# Some result items can be included in some group, eg. layers
	$self->{"group"} = shift;
	

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

sub AddErrors {
	my $self = shift;
	my $messages = shift;
	
	foreach my $mess (@{$messages}){
		
		$self->AddError($mess);
	}
}

sub AddWarning {
	my $self = shift;
	my $mess = shift;
	$self->{"result"} = Enums->ItemResult_Fail;

	push( @{ $self->{"warnings"} }, $mess );
}

sub AddWarnings {
	my $self = shift;
	my $messages = shift;
	
	foreach my $mess (@{$messages}){
		
		$self->AddWarning($mess);
	}
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
	my $delimiter = shift;
	
	unless($delimiter){
		$delimiter = "\n";
	}

	my $str = "";

	foreach ( @{ $self->{"errors"} } ) {
		$str .= " - " . $_ . $delimiter;
	}

	return $str;
}

sub GetWarningStr {
	my $self = shift;
	my $delimiter = shift;
	
	unless($delimiter){
		$delimiter = "\n";
	}

	my $str = "";

	foreach ( @{ $self->{"warnings"} } ) {
		$str .= " - " . $_ . $delimiter;
	}

	return $str;
}

sub GetErrorCount {
	my $self = shift;
	 
	return scalar( @{ $self->{"errors"} } );
}

sub GetWarningCount {
	my $self = shift;
	 
	return scalar( @{ $self->{"warnings"} } );
}


sub GetGroup{
	my $self = shift;
	
	return $self->{"group"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

