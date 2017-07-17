
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleDrawing::DrawLayer;

#3th party library
use Wx;
use strict;
use warnings;

#local library
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::SimpleDrawing::DrawItem';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class   = shift;
	my $drawing = shift;
	my $drawSub = shift;
	my $self    = {};
	bless($self);

	my @drawList = ();
	$self->{"drawList"} = \@drawList;

	#$self->{"DC"}      = Wx::ClientDC->new($drawing);
	$self->{"drawSub"} = $drawSub;
	$self->{"brush"} = undef;
	$self->{"drawing"} = $drawing;

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#
#
#sub DrawRectangle {
#	my $self = shift;
#	my $sX    = shift;
#	my $sY    = shift;
#	my $eX    = shift;
#	my $eY    = shift;
#
#
# 	my $s = $self->{"drawing"}->GetRecompScale();
#
#	$self->{"DC"}->DrawRectangle( $sX*$s, $sY*$s, $eX*$s, $eY*$s);
#}

sub SetBrush {
	my $self  = shift;
	my $brush = shift;

	$self->{"brush"} = $brush;
}

sub DrawRectangle {
	my $self = shift;
	my $dc = shift;
	

	$dc->SetBrush($self->{"brush"});

	$dc->DrawRectangle(@_);

	#$self->{"DC"}->DrawRectangle(@_);

	 
	
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
