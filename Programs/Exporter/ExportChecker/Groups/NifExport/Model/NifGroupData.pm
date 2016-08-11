
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::Groups::IGroupData');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self;    # Return the reference to the hash.
}

#sub GetData {
#	my $self = shift;
#	#my %data = %{ $self };
#	return %{ $self };
#}


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

