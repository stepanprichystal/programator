#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::GerExport::View::GerUnitForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';
#use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Load data
 
	$self->__SetLayout();

	#$self->__SetName();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# EVENTS
	#$self->{'onTentingChange'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $gerbers = $self->__SetLayoutGerbers($self);
	my $paste   = $self->__SetLayoutPaste($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $gerbers, 0, &Wx::wxEXPAND );
	$szMain->Add( $paste, 0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutGerbers {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportChb"} = $exportChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutPaste {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Paste' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $exportPasteChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $stepTxt    = Wx::StaticText->new( $statBox, -1, "Step",           &Wx::wxDefaultPosition, [ 100, 22 ] );
	my $notOriTxt  = Wx::StaticText->new( $statBox, -1, "Not original",   &Wx::wxDefaultPosition, [ 100, 22 ] );
	my $profileTxt = Wx::StaticText->new( $statBox, -1, "Profile, fiduc", &Wx::wxDefaultPosition, [ 100, 22 ] );
	my $zipFileTxt = Wx::StaticText->new( $statBox, -1, "Zip file",       &Wx::wxDefaultPosition, [ 100, 22 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb     = Wx::ComboBox->new( $statBox,  -1, $last, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );
	my $notOriChb  = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $profileChb = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition , [ 70, 22 ]);
	my $zipFileChb = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition , [ 70, 22 ]);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	 

	$szRowDetail1->Add( $stepTxt, 0,  &Wx::wxALL, 0);
	$szRowDetail1->Add( $stepCb,  0,  &Wx::wxALL, 0 );

	$szRowDetail2->Add( $notOriTxt, 0,  &Wx::wxALL, 0 );
	$szRowDetail2->Add( $notOriChb, 0,  &Wx::wxALL, 0 );

	$szRowDetail3->Add( $profileTxt, 0,  &Wx::wxALL, 0 );
	$szRowDetail3->Add( $profileChb, 0,  &Wx::wxALL, 0 );

	$szRowDetail4->Add( $zipFileTxt, 0,  &Wx::wxALL, 0 );
	$szRowDetail4->Add( $zipFileChb, 0, &Wx::wxALL, 0 );

	$szRowMain1->Add( $exportPasteChb, 1, &Wx::wxALL, 0 );

	$szRowMain2->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRowMain2->Add( $szRowDetail2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRowMain2->Add( $szRowDetail3, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRowMain2->Add( $szRowDetail4, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRowMain1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"exportPasteChb"} = $exportPasteChb;

	$self->{"stepCb"}     = $stepCb;
	$self->{"notOriChb"}  = $notOriChb;
	$self->{"profileChb"} = $profileChb;
	$self->{"zipFileChb"} = $zipFileChb;

	return $szStatBox;
}
 

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Paste file info ========================================================

sub SetPasteInfo {
	my $self  = shift;
	my $info = shift;
	
	$self->{"exportPasteChb"}->SetValue($info->{"export"});
	$self->{"stepCb"}->SetValue($info->{"step"});
	$self->{"notOriChb"}->SetValue($info->{"notOriginal"});
	$self->{"profileChb"}->SetValue($info->{"addProfile"});
	$self->{"zipFileChb"}->SetValue($info->{"zipFile"});
 
}

sub GetPasteInfo {
	my $self  = shift;
	
	my %info = ();
	
	 $info{"export"} = {"exportPasteChb"}->GetValue();
	 $info{"step"} = {"stepCb"}->GetValue();
	 $info{"notOriginal"} = {"notOriChb"}->GetValue();
	 $info{"addProfile"} = {"profileChb"}->GetValue();
	 $info{"zipFile"} = {"zipFileChb"}->GetValue();
	
	return \%info;
}



# Paste file info ========================================================

sub SetLayers {
	my $self = shift;
	
	$self->{"layers"} = shift;
}

sub GetLayers {
	my $self = shift;
	
	return $self->{"layers"};
}

1;
