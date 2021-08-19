
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::MDIExport::View::LayerList::LayerListFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::MDIExport::View::LayerList::LayerListRowFrm';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Other::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $parent   = shift;
	my $layerCnt = shift;

	my $layerCouples = shift;

	my $dimension = [ -1, -1 ];

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# PROPERTIES

	$self->__SetLayout( $layerCnt, $layerCouples );

	#EVENTS

	return $self;
}

sub SelectAll {
	my $self   = shift;
	my $select = shift;

	foreach my $item ( $self->GetAllItems ) {
		$item->SetIsSelected($select);
	}

}

sub __SetLayout {
	my $self         = shift;
	my $layerCnt     = shift;
	my $layerCouples = shift;

	$self->SetItemGap(2);

	#$self->SetItemUnselectColor( Wx::Colour->new( 226, 238, 249 ) );
	#$self->SetItemSelectColor( Wx::Colour->new( 191, 209, 238 ) );

	for ( my $i = 0 ; $i < scalar( @{$layerCouples} ) ; $i++ ) {

		my $layerCouple = $layerCouples->[$i];

		my $id = join( "_", @{$layerCouple} );

		my $item = LayerListRowFrm->new( $self->GetParentForItem(), $layerCnt, $id, $layerCouple->[0], $layerCouple->[1], 0 );
		$self->AddItemToQueue($item);
	}

}

# ==============================================
# PUBLIC FUNCTION
# ==============================================

sub SetCouples2Export {
	my $self           = shift;
	my $allCouplesInfo = shift;

	foreach my $coupleInf ( @{$allCouplesInfo} ) {

		my $couple = $coupleInf->{"couple"};
		my $export = $coupleInf->{"export"};

		my $id = join( "_", @{$couple} );

		my $item = $self->GetItem($id);

		$item->SetIsSelected($export);
	}
}

sub GetCouples2Export {
	my $self = shift;

	my @allCouplesInfo = ();

	foreach my $item ( $self->GetAllItems() ) {

		my @couples = ();

		if ( defined $item->GetTopLayer() && $item->GetTopLayer() ne "" ) {

			push( @couples, $item->GetTopLayer() );
		}

		if ( defined $item->GetBotLayer() && $item->GetBotLayer() ne "" ) {

			push( @couples, $item->GetBotLayer() );
		}

		my %inf = ( "couple" => \@couples, "export" => $item->GetIsSelected() );
		push( @allCouplesInfo, \%inf );
	}

	return \@allCouplesInfo;
}

sub SetLayerSettings {
	my $self       = shift;
	my $layersSett = shift;

	# Search item
	foreach my $item ( $self->GetAllItems() ) {

		if ( defined $item->GetTopLayer() ) {

			die "Settings is not defined for Top layer:" . $item->GetTopLayer() unless ( defined $layersSett->{ $item->GetTopLayer() } );

			$item->SetTopLayerSettings( $layersSett->{ $item->GetTopLayer() } );

		}

		if ( defined $item->GetBotLayer() ) {

			die "Settings is not defined for Top layer:" . $item->GetTopLayer() unless ( defined $layersSett->{ $item->GetBotLayer() } );

			$item->SetBotLayerSettings( $layersSett->{ $item->GetBotLayer() } );

		}
	}

}

sub GetLayerSettings {
	my $self = shift;

	my %layersSett = ();

	foreach my $item ( $self->GetAllItems() ) {

		if ( defined $item->GetTopLayer() && $item->GetTopLayer() ne "" ) {

			$layersSett{ $item->GetTopLayer() } = $item->GetTopLayerSettings();
		}

		if ( defined $item->GetBotLayer() && $item->GetBotLayer() ne "" ) {

			$layersSett{ $item->GetBotLayer() } = $item->GetBotLayerSettings();
		}
	}

	return \%layersSett;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
