
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Forms::CreatorListFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Programs::Panelisation::PnlWizard::Forms::CreatorListRowFrm';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Other::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $dimension = [ -1, -1 ];

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# PROPERTIES

	$self->__SetLayout();

	#EVENTS

	return $self;
}

#sub SetCommentLayout {
#	my $self       = shift;
#	my $commId     = shift;
#	my $commLayout = shift;
#
#	my $commItem = $self->GetItem($commId);
#
#	$commItem->SetCommentLayout($commLayout);
#
#}

sub SetCreatorsLayout {
	my $self     = shift;
	my $creators = shift;

	my @creators = @{$creators};

	# remove old groups
	for ( my $i = $self->GetItemsCnt() - 1 ; $i >= 0 ; $i-- ) {
		$self->RemoveItemFromQueue( $self->{"jobItems"}->[$i]->GetItemId() );
	}

	#create rows for each constraint
	for ( my $i = 0 ; $i < scalar(@creators) ; $i++ ) {

		my $item = CreatorListRowFrm->new( $self->GetParentForItem(), $creators[$i]->GetModelKey(), $creators[$i] );
		$self->AddItemToQueue($item);

		#$item->SetCommentLayout( $creators[$i] );

		# Add handler to item
		#$item->{"onGroupSett"}->Add( sub { $self->{"onGroupSett"}->Do(@_) } );
	}

}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(5);

	$self->SetItemUnselectColor(AppConf->GetColor("clrCreatorListUnSelect") );
	$self->SetItemSelectColor( AppConf->GetColor("clrCreatorListSelect") );
	$self->SetItemDisabledColor( AppConf->GetColor("clrCreatorListDisable") );
	
 

}

sub GetAllCreatorKeys {
	my $self = shift;

	return map { $_->GetItemId() } @{ $self->{"jobItems"} };

}

sub EnableCreators {
	my $self        = shift;
	my $creatorKeys = shift;

	my @allCreators = @{ $self->{"jobItems"} };

	foreach my $creator (@allCreators) {

		# Set  Item as disable
		my $enable = (defined first { $_ eq $creator->GetItemId() } @{$creatorKeys}) ? 1 : 0;

		if ( $enable && $creator->GetDisabled() ) {

			# Disable item
			$creator->SetDisabled(0 );

			# Get appearance back
			$creator->Enable();

		}
		elsif ( !$enable && !$creator->GetDisabled() ) {

			# Disable item
			$creator->SetDisabled(1);

			# Adjust appearence
			$creator->Disable();
		}

	}
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
