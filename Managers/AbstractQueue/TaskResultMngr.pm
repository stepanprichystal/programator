
#-------------------------------------------------------------------------------------------#
# Description: Extension of ItemResultMngr, allow created itemResult from
# errors "flaterned" to string. Errors are flatterned, because are passed
# from child thread to main thread.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::TaskResultMngr;
use base('Packages::ItemResult::ItemResultMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::ItemResult::Enums';
use aliased 'Managers::AbstractQueue::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;    # Return the reference to the hash.
}

# Create Item result, from "flaterned" data which come from Task-job-worker thread
sub CreateTaskItem {
	my $self       = shift;
	my $id         = shift;
	my $result     = shift;
	my $group      = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;

	my $item = $self->GetNewItem( $id, $result, $group );
	my $sep = Enums->ItemResult_DELIMITER;

	# Try parse errors
	if ( $errorsStr && $errorsStr ne "" ) {
		my @err = split( $sep, $errorsStr );

		$item->AddErrors( \@err );
	}

	# Try parse warnings
	if ( $warningStr && $warningStr ne "" ) {
		my @err = split( $sep, $warningStr );

		$item->AddWarnings( \@err );
	}

	$self->AddItem($item);

	return $item;
}

sub GetAllItems {
	my $self = shift;

	return @{ $self->{"itemResults"} };
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

