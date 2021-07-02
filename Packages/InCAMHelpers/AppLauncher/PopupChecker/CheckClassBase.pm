
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::PopupChecker::CheckClassBase;
use base('Packages::ItemResult::ItemEventMngr');

# Abstract class #

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub _AddError {
	my $self     = shift;
	my $errTitle = shift;
	my $errText  = shift;

	my $itemResult = $self->_GetNewItem($errTitle);
	$itemResult->AddError($errText);

	$self->_OnItemResult($itemResult);

}

sub _AddWarning {
	my $self     = shift;
	my $errTitle = shift;
	my $errText  = shift;

	my $itemResult = $self->_GetNewItem($errTitle);
	$itemResult->AddWarning($errText);

	$self->_OnItemResult($itemResult);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
