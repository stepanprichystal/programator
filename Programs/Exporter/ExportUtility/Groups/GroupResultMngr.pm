
#-------------------------------------------------------------------------------------------#
# Description: Represent general strucure for passing information about result of some operation
# Allow keep:
# - Operation result
# - Errors, which happend during operation
# - Warnings, which happend during operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::GroupResultMngr;
use base('Packages::ItemResult::ItemResultMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::ItemResult::Enums';
use aliased 'Programs::Exporter::ExportUtility::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_);
	bless($self);
	

	 

	return $self;    # Return the reference to the hash.
}


# Create Item result, from data which come from Export-job-worker thread
sub CreateExportItem{
	my $self = shift;
	my $id   = shift;
	my $result   = shift;
	my $errorsStr   = shift;
	my $warningStr   = shift;
	
	my $item = $self->GetNewItem($id, $result);
	my $sep = Enums->ItemResult_DELIMITER;
	
	# Try parse errors
	if($errorsStr && $errorsStr ne ""){
		my @err = split($sep, $errorsStr);
		
		$item->AddErrors(\@err);
	}
	
	# Try parse warnings
	if($warningStr && $warningStr ne ""){
		my @err = split($sep, $warningStr);
		
		$item->AddWarnings(\@err);
	}
	
	$self->AddItem($item);
}

sub GetAllItems{
	my $self = shift;
	
	return @{$self->{"itemResults"} };
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

