 
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleDrawing::DrawItem;

#3th party library
use Wx;
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class   = shift;
	my $drawSub = shift;
	my $subParams = shift;
	
	my $self    = {};
	bless($self);
 
	$self->{"drawSub"} = $drawSub;
	$self->{"subParams"} = $subParams;
 
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

sub SetBrush{
	my $self = shift;
	my $brush = shift;

	$self->{"DC"}->SetBrush($brush);
}

sub DrawRectangle {
	my $self = shift;

	$self->{"DC"}->DrawRectangle(@_);

	if ( $self->{"drawing"}->__NeedReDraw() ) {
		print "REdraw\n";
	}
	else {
		print "NO-REdraw\n";
	}
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
