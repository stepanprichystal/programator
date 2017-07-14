
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleDrawing::DrawLayer;
use base qw(Wx::ClientDC);

#3th party library
use Wx;
use Wx;
use strict;
use warnings;

#local library
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class     = shift;
	my $drawing    = shift;
 
	my $self = $class->SUPER::new( $drawing);

	bless($self);
 
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#
 
#sub DrawRectangle {
#	my $self = shift;
#	my $sX    = shift;
#	my $sY    = shift;
#	my $eX    = shift;
#	my $eY    = shift;
# 
#	$self->DrawRectangle( 100,100, 200,200 );
#}
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
