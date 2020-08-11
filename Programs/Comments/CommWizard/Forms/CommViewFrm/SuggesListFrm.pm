
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::SuggesListFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::SuggesListRowFrm';
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
	$self->{'onRemoveSuggesEvt'} = Event->new();
	$self->{'onChangeSuggesEvt'} = Event->new();

	return $self;
}

sub SetSuggestionLayout {
	my $self       = shift;
	my $suggId     = shift;
	my $suggLayout = shift;

	my $suggItem = $self->GetItem($suggId);

	$suggItem->SetSuggestionLayout($suggLayout);

}

sub SetSuggestionsLayout {
	my $self           = shift;
	my $suggListLayout = shift;

	# remove old groups
	for ( my $i = $self->GetItemsCnt() - 1 ; $i >= 0 ; $i-- ) {
		$self->RemoveItemFromQueue( $self->{"jobItems"}->[$i]->GetItemId() );
	}

	#create rows for each constraint
	for ( my $i = 0 ; $i < scalar(@{$suggListLayout}) ; $i++ ) {

		my $item = SuggesListRowFrm->new( $self->GetParentForItem(), $i );
		$self->AddItemToQueue($item);

		$item->SetSuggestionLayout( $suggListLayout->[$i] );

		$item->{'onRemoveSuggesEvt'}->Add( sub { $self->{"onRemoveSuggesEvt"}->Do(@_) } );
		$item->{'onChangeSuggesEvt'}->Add( sub { $self->{"onChangeSuggesEvt"}->Do(@_) } );

	}
}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(2);
	#
	#	$self->SetItemUnselectColor( Wx::Colour->new( 226, 238, 249 ) );
	#	$self->SetItemSelectColor( Wx::Colour->new( 191, 209, 238 ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
