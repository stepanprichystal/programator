
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::View::CreatorListFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::CreatorListRowFrm';
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

sub SetCommentLayout {
	my $self       = shift;
	my $commId     = shift;
	my $commLayout = shift;

	my $commItem = $self->GetItem($commId);

	$commItem->SetCommentLayout($commLayout);

}

sub SetCommentsLayout {
	my $self           = shift;
	my $commListLayout = shift;

	my @commSngl = @{$commListLayout};

	# remove old groups
	for ( my $i = $self->GetItemsCnt() - 1 ; $i >= 0 ; $i-- ) {
		$self->RemoveItemFromQueue( $self->{"jobItems"}->[$i]->GetItemId() );
	}

	#create rows for each constraint
	for ( my $i = 0 ; $i < scalar(@commSngl) ; $i++ ) {

		my $item = CommListRowFrm->new( $self->GetParentForItem(), $i, $commSngl[$i] );
		$self->AddItemToQueue($item);

		$item->SetCommentLayout( $commSngl[$i] );

		# Add handler to item
		#$item->{"onGroupSett"}->Add( sub { $self->{"onGroupSett"}->Do(@_) } );
	}

	

}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(5);

	$self->SetItemUnselectColor( Wx::Colour->new( 226, 238, 249 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 191, 209, 238 ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
