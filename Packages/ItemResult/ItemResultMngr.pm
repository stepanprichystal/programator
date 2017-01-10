
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
	my $self   = shift;
	my $id     = shift;
	my $result = shift;
	my $group  = shift;

	#my $groupId = $self->{"groupId"};

	my $item = ItemResult->new( $id, $result, $group );

	return $item;
}

sub AddItem {
	my $self = shift;
	my $item = shift;

	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	push( @{ $self->{"itemResults"} }, $item );
}

sub AddItems {
	my $self  = shift;
	my @items = @{ shift(@_) };

	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	push( @{ $self->{"itemResults"} }, @items );
}

sub GetAllItems {
	my $self = shift;

	return @{ $self->{"itemResults"} };
}

sub Clear {
	my $self = shift;

	my @itemsResult = ();
	$self->{"itemResults"} = \@itemsResult;

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

			push( @errors, \%info );
		}
	}

	return @errors;
}

sub GetErrorsStr {
	my $self = shift;
	my $addItemId = shift;
	my $str  = "";

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"errors"} } ) ) {

			if ($addItemId) {
				$str .= "\nItem -  " . $item->ItemId().":\n";
			}
			$str .= $item->GetErrorStr();
		}
	}

	return $str;
}

# Return total error count
# Each items has own array of error, thus we count all errors from this array
sub GetErrorsCnt {
	my $self = shift;

	my $total = 0;

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		$total += scalar( @{ $item->{"errors"} } );
	}

	return $total;
}

sub GetWarningsStr {
	my $self      = shift;
	my $addItemId = shift;

	my $str = "";

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"warnings"} } ) ) {

			if ($addItemId) {
				$str .= "Item: " . $item->ItemId();
			}

			$str .= $item->GetWarningStr();
		}
	}

	return $str;
}

sub GetWarnings {
	my $self     = shift;
	my @warnings = ();

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		if ( scalar( @{ $item->{"warnings"} } ) ) {
			my %info = ();

			$info{"itemId"} = $item->ItemId();
			$info{"value"} = join( ",\n", @{ $item->{"warnings"} } );

			push( @warnings, \%info );
		}
	}

	return @warnings;
}

# Return total warning count
# Each items has own array of warning, thus we count all warnings from this array
sub GetWarningsCnt {
	my $self = shift;

	my $total = 0;

	foreach my $item ( @{ $self->{"itemResults"} } ) {

		$total += scalar( @{ $item->{"warnings"} } );
	}

	return $total;
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

