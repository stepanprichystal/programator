
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep1::WizardStep1Frm;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::ConstraintList';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	#$self->{"layout"} = shift;

	return $self;
}

sub GetLayout {
	my $self   = shift;
	my $parent = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $parent, -1 );

	my $szRowBtns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowList = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $btnSetGroup = Wx::Button->new( $pnlMain, -1, "New group",      &Wx::wxDefaultPosition, [ 160, 33 ] );
	my $btnDelGroup = Wx::Button->new( $pnlMain, -1, "Del group",      &Wx::wxDefaultPosition, [ 160, 33 ] );
	my $btnGenGroup = Wx::Button->new( $pnlMain, -1, "Generate group", &Wx::wxDefaultPosition, [ 160, 33 ] );

	my $list = ConstraintList->new( $pnlMain, $self->{"inCAM"}, $self->{"jobId"} );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRowBtns->Add( $btnSetGroup, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowBtns->Add( $btnDelGroup, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowBtns->Add( $btnGenGroup, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRowList->Add( $list, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$pnlMain->SetSizer($szMain);

	$szMain->Add( $szRowBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRowList, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	
	
	# SET REFERENCES
	
	$self->{"constrList"} = $list;

	return $pnlMain;

}

sub Load {
	my $self       = shift;
	my $wizardStep = shift;

	my @constr = $wizardStep->GetConstraints();
	my $constrGroup = $wizardStep->GetConstrGroup();

	$self->{"constrList"}->SetConstraints(\@constr,$constrGroup );
	
	
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

}

1;

