
use Wx;

#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleDrawing::SimpleDrawing;
use base qw(Wx::Panel);

#3th party library
use Wx;
use strict;
use warnings;
use List::Util qw[min max];

#local library
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::SimpleDrawing::DrawLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, $dimension );

	bless($self);

	# Items references
	$self->__SetLayout();

	my %layers = ();
	$self->{"layers"} = \%layers;
	$self->{"scale"}  = 1;

	#$self->{"backgroundDC"} = Wx::ClientDC->new($self);
	$self->{"width"}  = ( @{$dimension} )[0];
	$self->{"height"} = ( @{$dimension} )[1];

	Wx::Event::EVT_PAINT( $self,  sub { $self->__Paint(@_)} );

	#EVENTS
	#$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

# Example, scale "2" means, all values are multiply by 2. Line 10px long will by drawed like 100px long
sub SetScale {
	my $self  = shift;
	my $scale = shift;

	$self->{"scale"} = shift;

	foreach ( keys %{ $self->{"layers"} } ) {

		$_->{"DC"}->SetUserScale($scale);
	}

}

# Real scale is value, which all coordinate are multiply,
# when whole image is supposed to by visible in drawing panel
sub GetRealScale {
	my $self = shift;
	my $dc   = shift;

	#$self->{"scale"}

	# Get max and min X+Y coordinate from all DC layers
	#	my $minX = undef;
	#	my $maxX = undef;

	#	my $minY = undef;
	#	my $maxY = undef;

	#	foreach ( keys %{ $self->{"layers"} } ) {
	#
	#		my $dc = $self->{"layers"}->{$_}->{"DC"};
	#
	#		my $valMinX = $dc->MinX();
	#		my $valMaxX = $dc->MaxX();
	#
	#		$minX = $valMinX if ( !defined $minX || $valMinX < $minX );    # set min value
	#		$maxX = $valMaxX if ( !defined $maxX || $valMaxX > $maxX );    # set max value
	#
	#		my $valMinY = $dc->MinY();
	#		my $valMaxY = $dc->MaxY();
	#
	#		$minY = $valMinY if ( !defined $minY || $valMinY < $minY );    # set min value
	#		$maxY = $valMaxY if ( !defined $maxY || $valMaxY > $maxY );    # set max value
	#	}

	my $minX = $dc->MinX();
	my $maxX = $dc->MaxX();

	my $minY = $dc->MinY();
	my $maxY = $dc->MaxY();

	# compute real scale
	my $wDraw = abs( min( 0, $minX ) ) + max( $self->{"width"},  $maxX );
	my $hDraw = abs( min( 0, $minY ) ) + max( $self->{"height"}, $maxY );

	my $newScale = 1;

	# ned compute new scale in order drawin will be whole visible in frame
	if ( $wDraw > $self->{"width"} || $hDraw > $self->{"height"} ) {

		# choose axis, which need more shrink
		if ( $self->{"width"} / $wDraw < $self->{"height"} / $hDraw ) {

			$newScale = $self->{"width"} / $wDraw;
		}
		else {
			$newScale = $self->{"height"} / $hDraw;
		}
	}

	my $realScale = $self->{"scale"};

	# need recompute
	if ( $newScale != 1 ) {
		$realScale *= $newScale;
	}

	return $realScale;
}

sub AddLayer {
	my $self    = shift;
	my $name    = shift;
	my $drawSub = shift;

	if ( defined $self->{"layers"}->{"$name"} ) {
		die "Layer with name: $name, aleready exists.\n";
	}

	$self->{"layers"}->{"$name"} = DrawLayer->new( $self, $drawSub );

	#$self->{"layers"}->{"$name"} =  Wx::ClientDC->new( $self );

	return $self->{"layers"}->{"$name"};
}

sub GetLayer {
	my $self = shift;
	my $name = shift;

	my $l = $self->{"layers"}->{"$name"};

	unless ( defined $l ) {
		die "Layer with name: $l, doesn't exists.\n";
	}

	return $l;
}

sub SetBackgroundBrush {
	my $self  = shift;
	my $color = shift;
	my $brush = shift;

	$self->{"backgClr"}   = $color;
	$self->{"backgBrush"} = $brush;

	#$self->SetBackgroundColour($color);    #green
	                                       #$self->Refresh();
	                                       
	#my $dcb = Wx::WindowDC->new($self);
	#$dcb->SetBackground(Wx::Brush->new(Wx::Colour->new( 20, 235, 235 ), &Wx::wxBRUSHSTYLE_CROSSDIAG_HATCH  ));

}

sub RefreshDrawing{
		my $self = shift;
		
		$self->{"autoZoom"} = 1;
		$self->Refresh(); # By  calling refresh on panel, "Paint event is raised"
	
}

sub __Paint {
	my $self = shift;
	
	my $dc = Wx::PaintDC->new($self);
	
	unless( $self->{"autoZoom"}){
		$dc->SetBrush($self->{"backgBrush"});
			$dc->DrawRectangle(-100, -100, 1000, 1000);
	}
	
	
	if(defined  $self->{"realScale"}){
		$dc->SetUserScale( $self->{"realScale"}, $self->{"realScale"} );
	}

	print "brush style: ".&Wx::wxBRUSHSTYLE_HORIZONTAL_HATCH;
	
	my $b = Wx::Brush->new('red', 115  );
	print "Is hatch: ".$b->GetStyle();
	

	#$dc->SetBrush(Wx::Brush->new('red', &Wx::wxBRUSHSTYLE_CROSSDIAG_HATCH  ));
	#my $dcb = Wx::ClientDC->new($self->{"drawingPnl"});
	#$dc->SetBackground(Wx::Brush->new('red', 115  ));
 	#$dc->Clear();

	foreach ( keys %{ $self->{"layers"} } ) {

		my $sub = $self->{"layers"}->{$_}->{"drawSub"};

		$sub->($dc)

	}

	if ( $self->{"autoZoom"} ) {

		$self->{"autoZoom"} = 0;

		if ( $self->__NeedReDraw($dc) ) {
			print "REdraw\n";
		}
		else {
			print "NO-REdraw\n";
		}

	}else{
		
	}
	
	 

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	#$self->SetBackgroundStyle( $brush );    #green

}

sub __NeedReDraw {
	my $self = shift;
	my $dc   = shift;

	# Get teal scale
	$self->{"realScale"} = $self->GetRealScale($dc);

	if ( $self->{"scale"} != $self->{"realScale"} ) {

		print STDERR "New scale: " . $self->{"realScale"} . "\n";

		$self->Refresh();

		#$self->__ZoomDrawing( $real, $dc );
		return 1;

	}
	else {
		return 0;
	}

}

sub __ZoomDrawing {
	my $self  = shift;
	my $scale = shift;
	my $dc    = shift;

	$dc->SetUserScale( $scale, $scale );
	$self->Refresh();

	#$self->Layout();

	#
	#	foreach ( keys %{ $self->{"layers"} } ) {
	#
	#		my $dc = $self->{"layers"}->{$_}->{"DC"};
	#
	#		$dc->SetUserScale($scale, $scale);
	#		$self->Refresh();
	#		$self->Layout();
	#	}
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

