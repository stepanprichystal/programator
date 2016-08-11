#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm;
use base qw(Wx::Panel);

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
use aliased 'CamHelpers::CamLayer';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 


sub new {
	my  $class = shift;
	my  $parent = shift;
	
	my $inCAM = shift;
	my $jobId = shift;
	my $title = shift;
	 
	my $self = $class->SUPER::new($parent);

	bless($self);
	
	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;
	
	$self->{"title"} = $title;
	
	$self->__SetLayout();
	
	$self->__SetName();
	
	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);
	
	
	# EVENTS
	$self->{'onTentingChange'}   = Event->new();
	

	return $self;
}


#sub Init{
#	my $self = shift;	
#	my $parent = shift;
#	
#	$self->Reparent($parent);
#	
#	$self->__SetLayout();
#	
#	$self->__SetName();
#}


sub __SetName {
	my $self = shift;
	
	$self->{"title"} = "Nif group";
	
}

#sub __SetHeight {
#	my $self = shift;
#	my $height = shift;
#	
#	$self->{"groupHeight"} = $height;
#	
#}


sub __SetLayout {
	my $self = shift;

	#define panels
	
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

#	my $rowCount = 15;
#	 
#	for (my $i = 0; $i < $rowCount; $i++){
#		
#		my $testTxt = Wx::StaticText->new( $self, -1, "Row_$i".$self->{"title"}, [ -1, -1 ], [-1, -1 ] );
#		$szMain->Add( $testTxt, 1, &Wx::wxEXPAND );
#	}
 
 	# Load data, for filling form by values
 	my @markingLayer = CamLayer->GetMarkingLayers( $self->{"inCAM"}, $self->{"jobId"});
  	my @markingLNames = map {uc($_->{"gROWname"})} @markingLayer;
 

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);


	# DEFINE CONTROLS
	my $tentingChb = Wx::CheckBox->new( $self, -1, "Tenting", &Wx::wxDefaultPosition, &Wx::wxDefaultSize);
	my $maskaChb = Wx::CheckBox->new( $self, -1, "Maska 100µm", &Wx::wxDefaultPosition,  &Wx::wxDefaultSize);
	my $pressfitChb = Wx::CheckBox->new( $self, -1, "Pressfit", &Wx::wxDefaultPosition,  &Wx::wxDefaultSize);
	my $jumpscoringChb = Wx::CheckBox->new( $self, -1, "Jumpscoring", &Wx::wxDefaultPosition,  &Wx::wxDefaultSize);
	
	
	my $datacodeCb = Wx::ComboBox->new( $self, -1, $markingLNames[0],  &Wx::wxDefaultPosition, [70, 20], \@markingLNames, &Wx::wxCB_READONLY );
	my $ulLogoCb = Wx::ComboBox->new( $self, -1, $markingLNames[0],  &Wx::wxDefaultPosition, [70, 20], \@markingLNames, &Wx::wxCB_READONLY );
	
	my $datacodeTxt = Wx::StaticText->new( $self, -1, "Data code" );
	my $ulLogoTxt = Wx::StaticText->new( $self, -1, "UL logo" );
	
	
	
	my $richTxt = Wx::RichTextCtrl->new( $self, -1, 'Poznamka', &Wx::wxDefaultPosition, [100, 250], &Wx::wxRE_MULTILINE |  &Wx::wxWANTS_CHARS );
	$richTxt->SetEditable(1);
	#$richTxt->SetSize( [ 100, 200 ] );
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);
	#$self->__WriteMessages($richTxt);
	$richTxt->Layout();
	
 
 	# SET EVENTS
 	Wx::Event::EVT_CHECKBOX( $tentingChb, -1, sub { $self->__OnTentingChangeHandler(@_) } );
 

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $tentingChb,   30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $datacodeCb, 10, &Wx::wxEXPAND | &Wx::wxALL, 1);
	$szRow1->Add( $datacodeTxt, 20, &Wx::wxEXPAND | &Wx::wxALL  | &Wx::wxLEFT, 2);
	#$szRow1->Add( 10, 10, 40, &Wx::wxGROW ); #expander
	
	
	$szRow2->Add( $maskaChb, 30, &Wx::wxEXPAND | &Wx::wxALL, 1);
	$szRow2->Add( $ulLogoCb, 10, &Wx::wxEXPAND | &Wx::wxALL , 1);
	$szRow2->Add( $ulLogoTxt, 20, &Wx::wxEXPAND | &Wx::wxALL  | &Wx::wxLEFT, 2);
	#$szRow2->Add( 10, 10, 40, &Wx::wxGROW ); #expander

	$szRow3->Add( $pressfitChb,    30, &Wx::wxEXPAND | &Wx::wxALL, 1);
	
	$szRow4->Add( $jumpscoringChb, 30, &Wx::wxEXPAND | &Wx::wxALL, 1);

 	$szRow5->Add( $richTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1);
 
 
 	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
 	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND );
  	$szMain->Add( $szRow3, 0, &Wx::wxEXPAND );
   	$szMain->Add( $szRow4, 0, &Wx::wxEXPAND );
    $szMain->Add( $szRow5, 0, &Wx::wxEXPAND ); 
 
	$self->SetSizer($szMain);
	
	# save control references
	$self->{"tentingChb"} = $tentingChb;
	$self->{"maskaChb"} = $maskaChb;
	$self->{"ulLogoCb"} = $ulLogoCb;
	$self->{"pressfitChb"} = $pressfitChb;
	$self->{"jumpscoringChb"} = $jumpscoringChb;
	$self->{"datacodeCb"} = $datacodeCb;
	$self->{"ulLogoCb"} = $ulLogoCb;
	$self->{"richTxt"} = $richTxt;
 
}

# Control handlers
sub __OnTentingChangeHandler{
		my $self  = shift;
		my $chb = shift;
 
		$self->{"onTentingChange"}->Do($chb->GetValue());
}


# SET CONTROL FUNCTIONS

sub SetTenting {
	my $self  = shift;
	my $value = shift;
	$self->{"tentingChb"}->SetValue($value);
}

sub SetMaska01 {
	my $self  = shift;
	my $value = shift;
	$self->{"maskaChb"}->SetValue($value);
}

sub SetPressfit {
	my $self  = shift;
	my $value = shift;
	$self->{"pressfitChb"}->SetValue($value);
}

sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"richTxt"}->WriteText($value);
}

sub SetDatacode {
	my $self  = shift;
	my $value = shift;
	$self->{"datacodeCb"}->SetValue($value);
}

sub SetUlLogo {
	my $self  = shift;
	my $value = shift;
	$self->{"ulLogoCb"}->SetValue($value);
}

sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;
	$self->{"jumpscoringChb"}->SetValue($value);
}


# GET CONTROL FUNCTIONS
 
sub GetTenting {
	my $self  = shift;
	return $self->{"tentingChb"}->GetValue();
}

sub GetMaska01 {
	my $self  = shift;
	return $self->{"maskaChb"}->GetValue();
}

sub GetPressfit {
	my $self  = shift;
	return $self->{"pressfitChb"}->GetValue();
}

sub GetNotes {
	my $self  = shift;
	$self->{"richTxt"}->GetValue();
}

sub GetDatacode {
	my $self  = shift;
	$self->{"datacodeCb"}->GetValue();
}

sub GetUlLogo {
	my $self  = shift;
	$self->{"ulLogoCb"}->GetValue();
}

sub GetJumpScoring {
	my $self  = shift;
	$self->{"jumpscoringChb"}->GetValue();
}


1;
