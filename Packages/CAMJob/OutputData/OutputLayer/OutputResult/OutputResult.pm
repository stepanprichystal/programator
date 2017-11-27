
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputResult;

#3th party library
use strict;
use warnings;

#local library

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
	$self->{"sourceLayer"} = shift;
	$self->{"result"}      = shift;
	$self->{"clasResults"}      = shift;

	return $self;
}
sub GetResult {
	my $self = shift;

	return $self->{"result"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetClassResults {
	my $self = shift;
	my $succedOnly = shift;
	
	my @res = @{ $self->{"clasResults"} };
	
	if($succedOnly){
		
		@res = grep {$_->Result() } @res; 
	} 

	return @res;
}

sub GetSourceLayer {
	my $self = shift;

	return $self->{"sourceLayer"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
