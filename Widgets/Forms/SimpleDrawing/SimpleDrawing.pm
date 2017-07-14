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

	#EVENTS
	#$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub AddLayer {
	my $self = shift;
	my $name = shift;

	if ( defined $self->{"layers"}->{"$name"} ) {
		die "Layer with name: $name, aleready exists.\n";
	}

	$self->{"layers"}->{"$name"} = DrawLayer->new($self);
	
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


 

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
