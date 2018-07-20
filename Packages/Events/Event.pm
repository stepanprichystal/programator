
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Events::Event;

#3th party library
use utf8;
use strict;
use warnings;

#local library


#use aliased 'Programs::CamGuide::Actions::MillingActions';
#se Programs::CamGuide::Actions::Milling;
#use Programs::CamGuide::Actions::Pause;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	#incam library
	my @subs = ();
	$self->{"subs"} = \@subs;
	
	return $self;
}


sub Add{
	my $self = shift; 
	my $newSub = shift;
	
	if(defined $newSub){
		push (@{$self->{"subs"}}, $newSub);
	}
}

sub RemoveAll{
	my $self = shift; 
	my $subRef = shift;
	
	$self->{"subs"} = [];
}


sub Handlers{
	my $self = shift; 
	
	return scalar(@{$self->{"subs"}});
}

sub Do{
	my $self = shift; 
 
 	#create copy of actual joined handlers
 	my @hanslersTmp = @{$self->{"subs"}};

	foreach my $s (@hanslersTmp){
		
		$s->(@_);
	}	
}

1;
	
	
 
