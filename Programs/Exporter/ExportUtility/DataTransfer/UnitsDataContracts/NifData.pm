
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NifData;
 
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

	my %exportData = ();
	$self->{"data"} = \%exportData;

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

 
# flexi_maska
sub SetFlexi_maska {
	my $self  = shift;
	$self->{"data"}->{"flexi_maska"} = shift;
}

sub GetFlexi_maska {
	my $self  = shift;
	return $self->{"data"}->{"flexi_maska"};
}
 

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

# c_mask_colour2
sub SetC_mask_colour2 {
	my $self  = shift;
	$self->{"data"}->{"c_mask_colour2"} = shift;
}

sub GetC_mask_colour2 {
	my $self  = shift;
	return $self->{"data"}->{"c_mask_colour2"};
}

# s_mask_colour2
sub SetS_mask_colour2 {
	my $self  = shift;
	$self->{"data"}->{"s_mask_colour2"} = shift;
}

sub GetS_mask_colour2 {
	my $self  = shift;
	return $self->{"data"}->{"s_mask_colour2"};
}



# c_silk_screen_colour2
sub SetC_silk_screen_colour2 {
	my $self  = shift;
	$self->{"data"}->{"c_silk_screen_colour2"} = shift;
}

sub GetC_silk_screen_colour2 {
	my $self  = shift;
	return $self->{"data"}->{"c_silk_screen_colour2"};
}

# s_silk_screen_colour2
sub SetS_silk_screen_colour2 {
	my $self  = shift;
	$self->{"data"}->{"s_silk_screen_colour2"} = shift;
}

sub GetS_silk_screen_colour2 {
	my $self  = shift;
	return $self->{"data"}->{"s_silk_screen_colour2"};
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
 
  
# Zpracoval
sub SetZpracoval {
	my $self  = shift;
	$self->{"data"}->{"zpracoval"} = shift;
}

sub GetZpracoval {
	my $self  = shift;
	return $self->{"data"}->{"zpracoval"};
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

# Technology
sub SetTechnology {
	my $self  = shift;
	
	$self->{"data"}->{"technology"} = shift;
}

sub GetTechnology {
	my $self  = shift;
	
	return $self->{"data"}->{"technology"};
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
	$self->{"data"}->{"merit_presfitt"} = $value;
}

sub GetPressfit {
	my $self  = shift;
	return $self->{"data"}->{"merit_presfitt"};
}

#tolerance hole
sub SetToleranceHole {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"mereni_tolerance_vrtani"} = $value;
}

sub GetToleranceHole {
	my $self  = shift;
	return $self->{"data"}->{"mereni_tolerance_vrtani"};
}

# Chamfer edges
sub SetChamferEdges {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"srazeni_hran"} = $value;
}

sub GetChamferEdges {
	my $self  = shift;
	return $self->{"data"}->{"srazeni_hran"};
}

#notes
sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"poznamka"} = $value;
}

sub GetNotes {
	my $self  = shift;
	return $self->{"data"}->{"poznamka"};
}

#quick notes
sub SetQuickNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"quickNotes"} = $value;
}

sub GetQuickNotes {
	my $self  = shift;
	return $self->{"data"}->{"quickNotes"};
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

#wrongFormat - wrong customer data format
sub SetWrongFormat {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"wrongFormat"} = $value;
}

sub GetWrongFormat {
	my $self  = shift;
	return $self->{"data"}->{"wrongFormat"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

