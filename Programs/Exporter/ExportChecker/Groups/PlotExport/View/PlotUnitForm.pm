#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
use Wx;
package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');


#3th party library
use strict;
use warnings;
use Wx;
 


#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
 
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotList';

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


	$self->__SetLayout();

	#$self->Disable();
 
	# EVENTS
 

	return $self;
}
 

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	#my $settingsStatBox  = $self->__SetGroup1($self);
	#my $settingsStatBox2  = $self->__SetGroup2($self);

	my $settingsStatBox  = $self->__SetLayoutSettings($self);
	my $layersStatBox  = $self->__SetLayoutControlList($self);
	#my $layersStatBox = $self->__SetLayoutControlList($self);
 

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $settingsStatBox,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $layersStatBox,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references


}

sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );


	# DEFINE CONTROLS
	my $allChb     = Wx::CheckBox->new( $statBox, -1, "Select all",      &Wx::wxDefaultPosition);
 

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $allChb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	 
 
	# Set References
	$self->{"allChb"} = $allChb;
	 
	return $szStatBox;
}


sub __SetLayoutControlList {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );


	# DEFINE CONTROLS
	my $widget = PlotList->new($statBox  );
 

	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $widget,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	 
 
	# Set References
	#$self->{"allChb"} = $allChb;
	 
	return $szStatBox;
}
#
## Set layout for Quick set box
#sub __SetLayoutControlList {
#	my $self   = shift;
#	my $parent = shift;
#
#	#define staticboxes
#	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
#	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );
#
#
#	# DEFINE CONTROLS
#	#my $allChb     = Wx::CheckBox->new( $statBox, -1, "Select all",      &Wx::wxDefaultPosition);
# 
#	 
#	my $widget = PlotList->new($statBox  );
#	
#	
#	# SET EVENTS
#	#Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );
#
#	# BUILD STRUCTURE OF LAYOUT
#	#$szStatBox->Add( $allChb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#	 
# 
#	# Set References
#	#$self->{"allChb"} = $allChb;
#	 
#	return $szStatBox;
#}

# Control handlers
sub __OnTentingChangeHandler {
	my $self = shift;
	my $chb  = shift;

	$self->{"onTentingChange"}->Do( $chb->GetValue() );
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls{
	
	
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetSingle_x {
	my $self  = shift;
	my $value = shift;
	$self->{"singlexValTxt"}->SetLabel($value);
}

sub GetSingle_x {
	my $self = shift;
	return $self->{"singlexValTxt"}->GetLabel();
}
 
1;
