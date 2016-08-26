
#-------------------------------------------------------------------------------------------#
# Description: Represent general strucure for passing information about result of some operation
# Allow keep:
# - Operation result
# - Errors, which happend during operation
# - Warnings, which happend during operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ItemResult::ItemResultMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::ItemResult::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my @itemResults = ();
	$self->{"itemResults"} = \@itemResults;

	return $self;    # Return the reference to the hash.
}

sub GetNewItem {
	my $self = shift;
	my $id   = shift;
	my $result = shift;
	my $group = shift;

	#my $groupId = $self->{"groupId"};

	my $item = ItemResult->new($id, $result, $group);

	return $item;
}

sub AddItem {
	my $self = shift;
	my $item = shift;

	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	push( @{ $self->{"itemResults"} }, $item );
}

sub Succes {
	my $self = shift;

	my @failed = grep { $_->{"result"} eq Enums->ItemResult_Fail } @{ $self->{"itemResults"} };

	unless ( scalar(@failed) ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub GetErrors {
	my $self   = shift;
	my @errors = ();

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"errors"} } ) ) {
			my %info = ();

			$info{"itemId"} = $item->ItemId();
			$info{"value"} = join( ",\n", @{ $item->{"errors"} } );
			
			push(@errors, \%info);
		}
	}

	return @errors;
}

sub GetErrorsStr {
	my $self = shift;
	my $str  = "";

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"errors"} } ) ) {

			$str .= $item->GetErrorStr();
		}
	}

	return $str;
}

sub GetWarningsStr {
	my $self = shift;
	my $str  = "";

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"warnings"} } ) ) {

			$str .= $item->GetwarningStr();
		}
	}

	return $str;
}

sub GetWarnings {
	my $self   = shift;
	my @warnings = ();

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"warnings"} } ) ) {
			my %info = ();

			$info{"itemId"} = $item->ItemId();
			$info{"value"} = join( ",\n", @{ $item->{"warnings"} } );
			
			push(@warnings, \%info);
		}
	}

	return @warnings;
}

sub GetFailResults {
	my $self = shift;

	my @failed = grep { $_->{"result"} eq Enums->ItemResult_Fail } @{ $self->{"itemResults"} };

	return @failed;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ItemResult::ItemResultMngr';

	my $mngr = ItemResultMngr->new();

}

1;

