
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::BackgroundWorker::BackgroundWorkerEvent;
use base('Packages::Events::Event');

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
	my $class   = shift;
	my $errMngr = shift;
	my $self    = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Add {
	my $self        = shift;
	my $newSub      = shift;
	my $mngrPackage = caller(0);

	if ( defined $newSub ) {
		push( @{ $self->{"subs"} }, { "sub" => $newSub, "package" => $mngrPackage } );
	}
}
 

sub Do {
	my $self        = shift;
	my $mngrPackage = shift;
	my @params      = @_;

	die "Package name of Backgroun manager is not defind" unless ( defined $mngrPackage );

	#create copy of actual joined handlers
	my @hanslersTmp = grep { $_->{"package"} eq $mngrPackage } @{ $self->{"subs"} };
	
	die "No handlers with Package Background manager name: $mngrPackage" if (scalar(@hanslersTmp) == 0 );

	foreach my $s (@hanslersTmp) {

		$s->{"sub"}->(@_);
	}
}

1;

