
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::LibraryFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::Frm::LayerSpecFillList';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $parent  = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $pnlType = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SchemePnlCreator_LIBRARY, $parent, $inCAM, $jobId );

	bless($self);

	# PROPERTIES

	$self->{"pnlType"} = $pnlType;
	$self->{"sigLayers"} = [ CamJob->GetSignalLayerNames( $inCAM, $jobId ) ];

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	my $pnlType = $self->{"pnlType"};

	my $szMain  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBoxes = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS

	my $schemeLayout = undef;

	if ( $pnlType eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$schemeLayout = $self->__SetLayoutSchemeCustPnl();

	}
	elsif ( $pnlType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$schemeLayout = $self->__SetLayoutSchemeProducPnl();
	}

	my $specLayerFillLayout = $self->__SetLayoutSpecialSett();

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szBoxes->Add( $schemeLayout,        1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szBoxes->Add( $specLayerFillLayout, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $szBoxes, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->AddStretchSpacer(1);

	$self->SetSizer($szMain);

	# SAVE REFERENCES

}

# Set layout for placement type
sub __SetLayoutSchemeCustPnl {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Schema selection' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szRow1    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szColLeft = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $rbStdSchema = Wx::RadioButton->new( $statBox, -1, "Customer:", &Wx::wxDefaultPosition, [ 10, 23 ], &Wx::wxRB_GROUP );
	my $rbSpecSchema = Wx::RadioButton->new( $statBox, -1, "Special:", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $stdSchemaPage  = $notebook->AddPage( 1, 0 );
	my $specSchemaPage = $notebook->AddPage( 2, 0 );

	my $stdCB  = Wx::ComboBox->new( $stdSchemaPage->GetParent(),  -1, "", [ -1, -1 ], [ 10, 23 ], [], &Wx::wxCB_READONLY );
	my $specCB = Wx::ComboBox->new( $specSchemaPage->GetParent(), -1, "", [ -1, -1 ], [ 10, 23 ], [], &Wx::wxCB_READONLY );

	my $szStdSchema = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	$szStdSchema->Add( $stdCB, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$stdSchemaPage->AddContent($stdCB);

	my $szSpecSchema = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	$szSpecSchema->Add( $specCB, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$specSchemaPage->AddContent($szSpecSchema);

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbStdSchema,  -1, sub { $notebook->ShowPage(1); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_RADIOBUTTON( $rbSpecSchema, -1, sub { $notebook->ShowPage(2); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $stdCB,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $specCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szColLeft->Add( $rbStdSchema,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szColLeft->Add( $rbSpecSchema, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $szColLeft, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $notebook,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->AddStretchSpacer(1);

	# CONTROL REFERENCES
	$self->{"notebookScheme"} = $notebook;
	$self->{"rbStdSchema"}    = $rbStdSchema;
	$self->{"rbSpecSchema"}   = $rbSpecSchema;
	$self->{"stdCB"}          = $stdCB;
	$self->{"specCB"}         = $specCB;

	return $szStatBox;
}

# Set layout for placement type
sub __SetLayoutSchemeProducPnl {
	my $self = shift;

	my $parent = $self;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Schema selection' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szRow1    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szColLeft = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $schemeTxt = Wx::StaticText->new( $statBox, -1, "Panel scheme:", &Wx::wxDefaultPosition );
	my $schemeCB = Wx::ComboBox->new( $statBox, -1, "", [ -1, -1 ], [ 10, 23 ], [], &Wx::wxCB_READONLY );

	# DEFINE EVENTS

	Wx::Event::EVT_TEXT( $schemeCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $schemeTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $schemeCB,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->AddStretchSpacer(1);

	# CONTROL REFERENCES

	$self->{"stdCB"} = $schemeCB;

	return $szStatBox;
}

# Set layout for placement type
sub __SetLayoutSpecialSett {
	my $self = shift;

	my $parent = $self;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Special schema settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# 1) Inner layer special fill

	# DEFINE CONTROLS
	 
	my @layersInfo = ();

	if ( scalar( @{ $self->{"sigLayers"} } ) > 2 ) {
		my $stackup = Stackup->new( $inCAM, $jobId );
		foreach my $layer ( @{ $self->{"sigLayers"} } ) {

			my $cuLayer  = $stackup->GetCuLayer($layer);
			my %lPars    = JobHelper->ParseSignalLayerName($layer);
			my $IProduct = $stackup->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

			my %lInf = ();
			$lInf{"name"}    = $layer;
			$lInf{"cuThick"} = $cuLayer->GetThick();
			$lInf{"cuThick"} .= " + " . StackEnums->Plating_STD if ( $IProduct->GetIsPlated() );
			$lInf{"cuUsage"} = int( $cuLayer->GetUssage() * 100 ) . "%";

			push( @layersInfo, \%lInf );

		}
	}
	else {

		my $cu = HegMethods->GetOuterCuThick($jobId);
		foreach my $layer ( @{ $self->{"sigLayers"} } ) {

			my %lInf = ();
			$lInf{"name"}    = $layer;
			$lInf{"cuThick"} = $cu;
			$lInf{"cuUsage"} = "- %";
			push( @layersInfo, \%lInf );
		}

	}

	my $layerList = LayerSpecFillList->new( $statBox, \@layersInfo );

	 
	$szStatBox->Add( $layerList,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# EVENTS
	$layerList->{"specialFillChangedEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# CONTROL REFERENCES

	$self->{"specLayerFillList"} = $layerList;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
sub SetStdSchemeList {
	my $self    = shift;
	my $schemes = shift;

	$self->{"stdCB"}->Freeze();

	$self->{"stdCB"}->Clear();

	# Set cb classes
	foreach my $scheme ( @{$schemes} ) {

		$self->{"stdCB"}->Append($scheme);
	}

	$self->{"stdCB"}->Thaw();

}

sub GetStdSchemeList {
	my $self = shift;

	my @list = $self->{"stdCB"}->GetStrings();

	return \@list;

}

sub SetSpecSchemeList {
	my $self    = shift;
	my $schemes = shift;

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$self->{"specCB"}->Freeze();

		$self->{"specCB"}->Clear();

		# Set cb classes
		foreach my $scheme ( @{$schemes} ) {

			$self->{"specCB"}->Append($scheme);
		}

		$self->{"specCB"}->Thaw();

	}

}

sub GetSpecSchemeList {
	my $self = shift;

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		my @list = $self->{"specCB"}->GetStrings();

		return \@list;

	}

}

sub SetSchemeType {
	my $self = shift;
	my $type = shift;    # standard/special

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		if ( $type eq "standard" ) {

			$self->{"rbStdSchema"}->SetValue(1);
			$self->{"rbSpecSchema"}->SetValue(0);
			$self->{"notebookScheme"}->ShowPage(1);

		}
		elsif ( $type eq "special" ) {

			$self->{"rbStdSchema"}->SetValue(0);
			$self->{"rbSpecSchema"}->SetValue(1);
			$self->{"notebookScheme"}->ShowPage(2);
		}
	}

}

sub GetSchemeType {
	my $self = shift;

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		my $type = undef;

		if ( $self->{"rbStdSchema"}->GetValue() ) {

			$type = "standard";
		}
		else {

			$type = "special";
		}

		return $type;
	}
}

sub SetScheme {
	my $self   = shift;
	my $scheme = shift;

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		if ( $self->{"rbStdSchema"}->GetValue() ) {
			$self->{"stdCB"}->SetValue($scheme);
		}
		else {
			$self->{"specCB"}->SetValue($scheme);
		}

	}
	elsif ( $self->{"pnlType"} eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$self->{"stdCB"}->SetValue($scheme);
	}

}

sub GetScheme {
	my $self = shift;

	my $scheme = undef;

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		if ( $self->{"rbStdSchema"}->GetValue() ) {
			$scheme = $self->{"stdCB"}->GetValue();
		}
		else {
			$scheme = $self->{"specCB"}->GetValue();
		}

	}
	elsif ( $self->{"pnlType"} eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$scheme = $self->{"stdCB"}->GetValue();
	}

	return $scheme;

}

sub SetSignalLayerSpecFill {
	my $self     = shift;
	my $specFill = shift;    # hah layer name + spec fill

	if ( scalar( @{ $self->{"sigLayers"} } ) ) {
		$self->{"specLayerFillList"}->SetLayersSpecFill($specFill);

	}

}

sub GetSignalLayerSpecFill {
	my $self = shift;

	if ( scalar( @{ $self->{"sigLayers"} } ) ) {
		return $self->{"specLayerFillList"}->GetLayersSpecFill();
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

