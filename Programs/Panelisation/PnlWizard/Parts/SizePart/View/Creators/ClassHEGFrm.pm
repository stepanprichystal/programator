
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::ClassHEGFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::Frm::PnlSizeBase);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_CLASSHEG, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	
	$self->_EnableLayoutSize(0);

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT

	# SAVE REFERENCES

	# Init combobox class
	$self->{"pnlClassCB"} = $self->_SetLayoutCBMain( "Panel class:", [],  25, 75,0  );

	$self->{"CBMainChangedEvt"}->Add( sub { $self->__OnPnlClassChanged(@_) } );


	$self->{"ISDimensionFilled"} = $self->_SetLayoutISSize( "HEG dimensions set:",  40, 10, 50  );

	# Init combobox class size
	$self->{"pnlClassSizeCB"} = $self->_SetLayoutCBSize( "Class size:", [],  24, 76,0 );
	$self->{"pnlClassSizeCB"}->Disable();

	$self->{"CBSizeChangedEvt"}->Add( sub { $self->__OnPnlClassSizeChanged(@_) } );

	# Init combobox class border
	$self->{"pnlClassBorderCB"} = $self->_SetLayoutCBBorder( "Class border:", [],  24, 76,0 );

	$self->{"CBBorderChangedEvt"}->Add( sub { $self->__OnPnlClassBorderChanged(@_) } );

}

sub __OnPnlClassChanged {
	my $self      = shift;
	my $className = shift;

	my $class = first { $_->GetName() eq $className } @{ $self->{"classes"} };

	# Set cb classes size
	$self->{"pnlClassSizeCB"}->Clear();
	foreach my $classSize ( $class->GetSizes() ) {

		$self->{"pnlClassSizeCB"}->Append( $classSize->GetName() );
	}

	if ( scalar( $class->GetSizes() ) ) {

		my $sizeName = ( $class->GetSizes() )[0]->GetName();
		$self->{"pnlClassSizeCB"}->SetValue( $sizeName );
		$self->__OnPnlClassSizeChanged($sizeName);
	}

}

sub __OnPnlClassSizeChanged {
	my $self          = shift;
	my $classSizeName = shift;

	my $class     = first { $_->GetName() eq $self->{"pnlClassCB"}->GetValue() } @{ $self->{"classes"} };
	my $classSize = first { $_->GetName() eq $classSizeName } $class->GetSizes();

	if ( defined $classSize ) {

		# Change dimension

		$self->SetWidth( $classSize->GetWidth() );
		$self->SetHeight( $classSize->GetHeight() );

		# Set cb classes border
		$self->{"pnlClassBorderCB"}->Clear();
		foreach my $classBorder ( $classSize->GetBorders() ) {

			$self->{"pnlClassBorderCB"}->Append( $classBorder->GetName() );
		}

		if ( scalar( $classSize->GetBorders() ) ) {

			my $borderName = ( $classSize->GetBorders() )[0]->GetName();
			$self->{"pnlClassBorderCB"}->SetValue( $borderName );
			$self->__OnPnlClassBorderChanged($borderName);

		}
	}
}

sub __OnPnlClassBorderChanged {
	my $self            = shift;
	my $classBorderName = shift;

	my $class       = first { $_->GetName() eq $self->{"pnlClassCB"}->GetValue() } @{ $self->{"classes"} };
	my $classSize   = first { $_->GetName() eq $self->{"pnlClassSizeCB"}->GetValue() } $class->GetSizes();
	my $classBorder = first { $_->GetName() eq $classBorderName } $classSize->GetBorders();

	# Change dimension
	if ( defined $classBorder ) {
		$self->SetBorderLeft( $classBorder->GetBorderLeft() );
		$self->SetBorderRight( $classBorder->GetBorderRight() );
		$self->SetBorderTop( $classBorder->GetBorderTop() );
		$self->SetBorderBot( $classBorder->GetBorderBot() );

	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetPnlClasses {
	my $self    = shift;
	my $classes = shift;

	$self->{"classes"} = $classes;

	$self->{"pnlClassCB"}->Clear();

	# Set cb classes
	foreach my $class ( @{$classes} ) {

		$self->{"pnlClassCB"}->Append( $class->GetName() );
	}

}

sub GetPnlClasses {
	my $self = shift;

	return $self->{"classes"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassCB"}->SetValue($val) if ( defined $val && $val ne "");;

	$self->__OnPnlClassChanged($val) if ( defined $val && $val ne "");
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"pnlClassCB"}->GetValue();
}

sub SetDefPnlSize {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassSizeCB"}->SetValue($val) if ( defined $val && $val ne "");;

	$self->__OnPnlClassSizeChanged($val) if ( defined $val && $val ne "");
}

sub GetDefPnlSize {
	my $self = shift;

	return $self->{"pnlClassSizeCB"}->GetValue();
}

sub SetDefPnlBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassBorderCB"}->SetValue($val) if ( defined $val && $val ne "");;

	$self->__OnPnlClassBorderChanged($val) if ( defined $val && $val ne "");
}

sub GetDefPnlBorder {
	my $self = shift;

	return $self->{"pnlClassBorderCB"}->GetValue();
}


sub SetISDimensionFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"ISDimensionFilled"}->SetStatus( ( $val ? EnumsGeneral->ResultType_OK : EnumsGeneral->ResultType_FAIL ) );

}

sub GetISDimensionFilled {
	my $self = shift;

	my $stat = $self->{"ISDimensionFilled"}->GetStatus();

	if ( $stat eq EnumsGeneral->ResultType_OK ) {

		return 1;
	}
	else {

		return 0;
	}
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

