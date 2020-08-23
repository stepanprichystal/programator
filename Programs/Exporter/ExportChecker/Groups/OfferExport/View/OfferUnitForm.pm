#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::OfferExport::View::OfferUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';

#use aliased 'Packages::Offersting::BasicHelper::Helper' => 'OfferHelper';
use aliased 'CamHelpers::CamStepRepeat';

#use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;
	$self->{"defaultInfo"} = $defaultInfo;

	# Load data

	$self->__SetLayout();

	# EVENTS
	$self->{'addSpecifToMailEvt'}  = Event->new();
	$self->{'addStackupToMailEvt'} = Event->new();
	
	
	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $storeSpecToISTxt = Wx::StaticText->new( $self, -1, "Specification to IS", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $storeSpecToISChb = Wx::CheckBox->new( $self, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	my $approvalEmail = $self->__SetLayoutEmail($self);

	# SOffer EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $storeSpecToISTxt, 0, &Wx::wxEXPAND );
	$szRow1->Add( $storeSpecToISChb, 0, &Wx::wxEXPAND );

	$szMain->Add( $szRow1,        0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $approvalEmail, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references
	$self->{"storeSpecToISChb"} = $storeSpecToISChb;
	 

}

# Set layout for Quick set box
sub __SetLayoutEmail {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Add to approval email' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $addSpecifToEmailTxt = Wx::StaticText->new( $statBox, -1, "Data specification", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $addSpecifToEmailChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	my $addStackupToEmailTxt = Wx::StaticText->new( $statBox, -1, "PDF stackup", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $addStackupToEmailChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	# SOffer EVENTS
	Wx::Event::EVT_CHECKBOX( $addSpecifToEmailChb,  -1, sub { $self->{"addSpecifToMailEvt"}->Do( $addSpecifToEmailChb->GetValue() ) } );
	Wx::Event::EVT_CHECKBOX( $addStackupToEmailChb, -1, sub { $self->{"addStackupToMailEvt"}->Do( $addStackupToEmailChb->GetValue() ) } )
	  ;

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $addSpecifToEmailTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $addSpecifToEmailChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $addStackupToEmailTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $addStackupToEmailChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"addSpecifToEmailChb"}  = $addSpecifToEmailChb;
	$self->{"addStackupToEmailChb"} = $addStackupToEmailChb;
	$self->{"statBoxEmail"} = $statBox;
	return $szStatBox;
}


# =====================================================================
# HANDLERS FOR ANOTHER GROUP EVENTS
# =====================================================================

sub OnCommGrouExportEmail {
	my $self      = shift;
	my $addSpecif = shift;

	if(defined $addSpecif && $addSpecif){
		
		$self->{"statBoxEmail"}->Enable();
	}else{
		
		$self->{"statBoxEmail"}->Disable();
	}

}
 

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	$self->{"statBoxEmail"}->Disable();

}

# =====================================================================
# SOffer/GOffer CONTROLS VALUES
# =====================================================================

# Store  offer job specification to IS
sub SetSpecifToIS {
	my $self = shift;

	$self->{"storeSpecToISChb"}->SetValue(shift);
}

sub GetSpecifToIS {
	my $self = shift;

	if ( $self->{"storeSpecToISChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Add pdf stackup to approval email
sub SetAddSpecifToEmail {
	my $self = shift;

	$self->{"addSpecifToEmailChb"}->SetValue(shift);
}

sub GetAddSpecifToEmail {
	my $self = shift;
	if ( $self->{"addSpecifToEmailChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Add pdf stackup to approval email
sub SetAddStackupToEmail {
	my $self = shift;

	$self->{"addStackupToEmailChb"}->SetValue(shift);
}

sub GetAddStackupToEmail {
	my $self = shift;
	if ( $self->{"addStackupToEmailChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
