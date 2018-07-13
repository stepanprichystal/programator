
#-------------------------------------------------------------------------------------------#
# Description: Container, which display JobQueueItems in queue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupQueueFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupQueueRowFrm';
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
	$self->{"groupsSet"} = 0;

	#EVENTS

	#$self->{"onProduce"} = Event->new();

	return $self;
}

sub SetGroups {
	my $self         = shift;
	my $uniqueGroups = shift;
	my $constraints  = shift;
	my $constrGroups = shift;

	# remove old groups
	for(my $i= scalar(@{ $self->{"jobItems"} }) -1;  $i >= 0 ; $i--){
		
		$self->RemoveItemFromQueue( $self->{"jobItems"}->[$i]->GetItemId() );
	}
 

	#create rows for each constraint

	foreach my $g ( @{$uniqueGroups} ) {

		my @gc = grep { $constrGroups->{ $_->GetId() } ne "" && $constrGroups->{ $_->GetId() } == $g } @{$constraints};

		my $item = GroupQueueRowFrm->new( $self->GetParentForItem(), $g, \@gc );
		$self->AddItemToQueue($item);

	}

	$self->{"groupsSet"} = 1;

}

sub GroupsSet {
	my $self = shift;

	return $self->{"groupsSet"};
}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(5);

	$self->SetItemUnselectColor( Wx::Colour->new( 255, 255, 255 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 255, 255, 255 ) );
	
	$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
