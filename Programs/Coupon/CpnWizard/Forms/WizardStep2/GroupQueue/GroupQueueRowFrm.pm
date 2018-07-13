
#-------------------------------------------------------------------------------------------#
# Description: Form represent one JobQueue item. Contain controls which show
# status of tasking job.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupQueueRowFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use utf8;
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::GroupSettPnl';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::GroupQueue::StripSettPnl';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $parent      = shift;
	my $group       = shift;
	my $constraints = shift;

	my $self = $class->SUPER::new( $parent, $group );

	bless($self);

	# PROPERTIES
	$self->{"group"}       = $group;
	$self->{"constraints"} = $constraints;

	$self->__SetLayout();

	# EVENTS

	#	$self->{"onStop"}     = Event->new();
	#	$self->{"onContinue"} = Event->new();
	#	$self->{"onAbort"}    = Event->new();
	#	$self->{"onRestart"}    = Event->new();
	#	$self->{"onRemove"}   = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS
	my $constr = $self->{"constraints"};

	#	my $idTxt = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetId(), &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	#	my $groupTxt =
	#	  Wx::TextCtrl->new( $self->{"parent"}, -1, -1, &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szRowCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowCol4 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowCol5 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupPnl = GroupSettPnl->new( $self, $self->{"group"}, $self->{"rowHeight"} );

	foreach my $constr ( @{$constr} ) {

		my $stripsPnl = StripSettPnl->new( $self, $constr->GetType(), $constr->GetModel(), $self->{"rowHeight"} );
		$szRowCol1->Add( $stripsPnl, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

		my $trackLTxt = Wx::StaticText->new( $self, -1, $constr->GetTrackLayer(), &Wx::wxDefaultPosition, [ 100, 25 ] );
		$szRowCol2->Add( $trackLTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

		my $topRefLTxt =
		  Wx::StaticText->new( $self, -1, $constr->GetTopRefLayer(), &Wx::wxDefaultPosition, [ 130, 25 ] );
		$szRowCol3->Add( $topRefLTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

		my $botRefLTxt =
		  Wx::StaticText->new( $self, -1, $constr->GetBotRefLayer(), &Wx::wxDefaultPosition, [ 130, 25 ] );
		$szRowCol4->Add( $botRefLTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
		
		my $impedanceLTxt =
		  Wx::StaticText->new( $self, -1, sprintf("%.2f Ω", $constr->GetOption("CALCULATED_IMPEDANCE")), &Wx::wxDefaultPosition, [ 130, 25 ] );
		$szRowCol5->Add( $impedanceLTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
		
		
	}
	
	$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	$szMain->Add( $groupPnl,  0, &Wx::wxALL, 4 );
	$szMain->Add( $szRowCol1, 0, &Wx::wxALL, 4 );
	$szMain->Add( $szRowCol2, 0, &Wx::wxALL, 4 );
	$szMain->Add( $szRowCol3, 0, &Wx::wxALL, 4);
	$szMain->Add( $szRowCol4, 0, &Wx::wxALL, 4 );
	$szMain->Add( $szRowCol5, 0, &Wx::wxALL, 4 );
	$szMain->Add( 1, 50, 0 );

	$self->SetSizer($szMain);

	# SET EVENTS

	#	$self->{"groupSettingsClick"}->Add( sub { $groupPnl->{"groupSettingsClick"}->Do(@_) } );
	#	$self->{"stripSettingsClick"}->Add( sub { $groupPnl->{"stripSettingsClick"}->Do(@_) } );

	# SET REFERENCES

}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

# ==============================================
# PUBLIC FUNCTION
# ==============================================

# ==============================================
# HELPER FUNCTION
# ==============================================
#sub _GetDelimiter {
#	my $self = shift;
#
#
#	my $pnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 1, 1 ] );
#	$pnl->SetBackgroundColour( Wx::Colour->new( 150, 150, 150 ) );
#
#	return $pnl;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
