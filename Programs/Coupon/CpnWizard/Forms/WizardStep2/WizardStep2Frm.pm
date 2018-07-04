
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::WizardStep2Frm;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';


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

sub GetLayout{
	my $self = shift;
	my $parent = shift;
	
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $parent, -1 );

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $statusTxt1 = Wx::StaticText->new( $pnlMain, -1, "Step 2", &Wx::wxDefaultPosition );
 	my $statusTxt2 = Wx::StaticText->new( $pnlMain, -1, "blalba 2", &Wx::wxDefaultPosition );
	 
	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);

	$szMain->Add( $statusTxt1,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $statusTxt2,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
 
	return $pnlMain;
	
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

