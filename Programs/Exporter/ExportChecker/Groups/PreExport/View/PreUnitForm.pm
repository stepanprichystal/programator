#-------------------------------------------------------------------------------------------#
# Description: Fake viw class for PRe export
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::PreUnitForm;

#use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamDrilling';
#use aliased 'CamHelpers::CamStep';

#use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	#my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	#my $self = $class->SUPER::new($parent);
	my $self = {};

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Load data

	# EVENTS
	#$self->{'onTentingChange'} = Event->new();

	return $self;
}

sub __OnExportPasteChange {
	my $self = shift;

	if ( $self->{"exportPasteChb"}->IsChecked() ) {

		$self->{"stepCb"}->Enable();
		$self->{"notOriChb"}->Enable();
		$self->{"profileChb"}->Enable();
		$self->{"zipFileChb"}->Enable();
	}
	else {

		$self->{"stepCb"}->Disable();
		$self->{"notOriChb"}->Disable();
		$self->{"profileChb"}->Disable();
		$self->{"zipFileChb"}->Disable();
	}

}



# --------------------------------------------------------------
# Handlers, which handle events from another units/groups
# --------------------------------------------------------------

sub PlotRowSettChanged {
	my $self    = shift;
	my $plotRow = shift;

	my %lInfo = $plotRow->GetLayerValues();


	foreach my $l ( @{ $self->{"layers"} } ) {

		if ( $l->{"name"} eq $plotRow->GetRowText() ) {

			$l->{"mirror"}   = $lInfo{"mirror"};
			$l->{"polarity"} = $lInfo{"polarity"};
			$l->{"comp"}     = $lInfo{"comp"};

			# Set etching type for signal layers by polarity
			if ( $l->{"name"} =~ /^[cs]$/ || $l->{"name"} =~ /^v\d$/ ) {

				# Set polarity by etching type
				if ( $l->{"polarity"} eq "positive" ) {
					$l->{"etchingType"} = EnumsGeneral->Etching_PATTERN;
				}
				elsif ( $l->{"polarity"} eq "negative" ) {
					$l->{"etchingType"} = EnumsGeneral->Etching_TENTING;
				}
			}
		}

	}
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Layers to export ========================================================

sub SetSignalLayers {
	my $self = shift;

	$self->{"layers"} = shift;
}

sub GetSignalLayers {
	my $self = shift;

	return $self->{"layers"};
}

1;
