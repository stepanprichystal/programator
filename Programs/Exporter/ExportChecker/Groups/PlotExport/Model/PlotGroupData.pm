
#-------------------------------------------------------------------------------------------#
# Description: Class contain state properties, used as model for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotGroupData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	my %exportData = ();
	$self->{"data"} = \%exportData;
	
	# state of whole group. Value is enum GroupState_xx
	$self->{"state"} = Enums->GroupState_DISABLE;

	return $self;
}


# Dimension ========================================================
 
# single_x
sub SetSingle_x {
	my $self  = shift;
	$self->{"data"}->{"single_x"} = shift;
}

sub GetSingle_x {
	my $self  = shift;
	return $self->{"data"}->{"single_x"};
}

# single_y
sub SetSingle_y {
	my $self  = shift;
	$self->{"data"}->{"single_y"} = shift;
}

sub GetSingle_y {
	my $self  = shift;
	return $self->{"data"}->{"single_y"};
}

# panel_x
sub SetPanel_x {
	my $self  = shift;
	$self->{"data"}->{"panel_x"} = shift;
}

sub GetPanel_x {
	my $self  = shift;
	return $self->{"data"}->{"panel_x"};
}


# panel_y
sub SetPanel_y {
	my $self  = shift;
	$self->{"data"}->{"panel_y"} = shift;
}

sub GetPanel_y {
	my $self  = shift;
	return $self->{"data"}->{"panel_y"};
}

# nasobnost_panelu
sub SetNasobnost_panelu {
	my $self  = shift;
	$self->{"data"}->{"nasobnost_panelu"} = shift;
}

sub GetNasobnost_panelu {
	my $self  = shift;
	return $self->{"data"}->{"nasobnost_panelu"};
}

# nasobnost
sub SetNasobnost {
	my $self  = shift;
	$self->{"data"}->{"nasobnost"} = shift;
}

sub GetNasobnost {
	my $self  = shift;
	return $self->{"data"}->{"nasobnost"};
}


# MASK, SILK color ========================================================

# c_mask_colour
sub SetC_mask_colour {
	my $self  = shift;
	$self->{"data"}->{"c_mask_colour"} = shift;
}

sub GetC_mask_colour {
	my $self  = shift;
	return $self->{"data"}->{"c_mask_colour"};
}

# s_mask_colour
sub SetS_mask_colour {
	my $self  = shift;
	$self->{"data"}->{"s_mask_colour"} = shift;
}

sub GetS_mask_colour {
	my $self  = shift;
	return $self->{"data"}->{"s_mask_colour"};
}


# c_silk_screen_colour
sub SetC_silk_screen_colour {
	my $self  = shift;
	$self->{"data"}->{"c_silk_screen_colour"} = shift;
}

sub GetC_silk_screen_colour {
	my $self  = shift;
	return $self->{"data"}->{"c_silk_screen_colour"};
}

# s_silk_screen_colour
sub SetS_silk_screen_colour {
	my $self  = shift;
	$self->{"data"}->{"s_silk_screen_colour"} = shift;
}

sub GetS_silk_screen_colour {
	my $self  = shift;
	return $self->{"data"}->{"s_silk_screen_colour"};
}
 

# Tenting
sub SetTenting {
	my $self  = shift;
	$self->{"data"}->{"tenting"} = shift;
}

sub GetTenting {
	my $self  = shift;
	return $self->{"data"}->{"tenting"};
}


#maska 01
sub SetMaska01 {
	my $self  = shift;
	$self->{"data"}->{"maska01"} = shift;
}

sub GetMaska01 {
	my $self  = shift;
	return $self->{"data"}->{"maska01"};
}

#pressfit
sub SetPressfit {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"pressfit"} = $value;
}

sub GetPressfit {
	my $self  = shift;
	return $self->{"data"}->{"pressfit"};
}

#notes
sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"notes"} = $value;
}

sub GetNotes {
	my $self  = shift;
	return $self->{"data"}->{"notes"};
}

#datacode
sub SetDatacode {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"datacode"} = $value;
}

sub GetDatacode {
	my $self  = shift;
	return $self->{"data"}->{"datacode"};
}

#ul_logo
sub SetUlLogo {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"ul_logo"} = $value;
}

sub GetUlLogo {
	my $self  = shift;
	return $self->{"data"}->{"ul_logo"};
}

#prerusovana_drazka
sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"prerusovana_drazka"} = $value;
}

sub GetJumpScoring {
	my $self  = shift;
	return $self->{"data"}->{"prerusovana_drazka"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

