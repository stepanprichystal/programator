#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ProcessReorder::ProcessReorder;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	my @checks = ();
	$self->{"changes"} = \@checks;

	$self->__LoadChanges();

	return $self;
}

sub RunChanges {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	foreach my $change ( @{ $self->{"changes"} } ) {

		unless ( $change->Run($errMess) ) {

			$result = 0;
			last;
		}
	}

	return $result;
}

sub __LoadChanges {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my $path  = GeneralHelper->Root() . "Packages\\Reorder\\ProcessReorder\\ChangeList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	unless ( -e $path ) {
		die "Unable to process reorder $jobId, because \"ChangeList\" file doesnt exist.\n";
	}

	my @changes = ();

	@lines = grep { $_ !~ /#/ } @lines;

	foreach my $l (@lines) {

		$l =~ s/\s//g;

		if ( $l ne "" ) {

			my $key = uc($l);

			my $module = 'Packages::Reorder::ProcessReorder::Changes::' . $key;
			eval("use  $module;");

			push( @changes, $module->new( $key, $inCAM, $jobId, $isPool) );
		}
	}

	unless ( scalar(@changes) ) {
		die "Unable to process reorder $jobId, because there are no automatic changes.\n";

	}

	$self->{"changes"} = \@changes;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

