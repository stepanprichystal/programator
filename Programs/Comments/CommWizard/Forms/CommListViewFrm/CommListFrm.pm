
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListRowFrm';
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
		
		$item->SetCommentLayout($commSngl[$i]);

		# Add handler to item
		#$item->{"onGroupSett"}->Add( sub { $self->{"onGroupSett"}->Do(@_) } );
	}

}

 


sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(5);

	$self->SetItemUnselectColor( Wx::Colour->new( 0, 255, 0 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 255, 197, 129 ) );

	#$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
