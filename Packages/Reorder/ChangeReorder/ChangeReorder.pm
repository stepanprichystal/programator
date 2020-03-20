#-------------------------------------------------------------------------------------------#
# Description: Identify changes which has to by done on job reorder, before it goes to production
# Theese changes are done automatically
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::ChangeReorder;

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

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;    # Job id without order id
	$self->{"orderId"} = shift;    # Complete order id (X000000-00)

	# ReorderType_POOL
	# ReorderType_POOLFORMERSTD
	# ReorderType_POOLFORMERMOTHER
	# ReorderType_STD
	# ReorderType_STDFORMERPOOL
	$self->{"reorderType"} = shift;

	my @checks = ();
	$self->{"changes"} = \@checks;

	$self->__LoadChanges();

	return $self;
}

# Do all automatic changes, which are necessary
sub RunChanges {
	my $self    = shift;
	my $errMess = shift;
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	my $result = 1;

	foreach my $change ( @{ $self->{"changes"} } ) {

		unless ( $change->Run($errMess) ) {

			$result = 0;
			last;
		}
	}

	return $result;
}

# Remove change from change list during run
sub ExcludeChange {
	my $self   = shift;
	my $change = shift;

	my $excludeOk = 0;

	for ( my $i = scalar( @{ $self->{"changes"} } ) - 1 ; $i >= 0 ; $i-- ) {

		if ( $self->{"changes"}->[$i]->GetChangeKey() eq $change ) {

			splice @{ $self->{"changes"} }, $i, 1;
			$excludeOk = 1;
			last;
		}
	}

	return $excludeOk;
}

sub __LoadChanges {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $orderId     = $self->{"orderId"};
	my $reorderType = $self->{"reorderType"};

	my $path  = GeneralHelper->Root() . "\\Packages\\Reorder\\ChangeReorder\\ChangeList";
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

			my $module = 'Packages::Reorder::ChangeReorder::Changes::' . $key;
			eval("use  $module;");

			push( @changes, $module->new( $key, $inCAM, $jobId, $orderId, $reorderType) );
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

	use aliased 'Packages::Reorder::ChangeReorder::ChangeReorder';
	use aliased 'Packages::InCAM::InCAM';

	use Data::Dump qw(dump);

	my $inCAM   = InCAM->new();
	my $jobId   = "d241318";
	my $orderId = "d241318-02";

	my $ch = ChangeReorder->new( $inCAM, $jobId, $orderId );

	my $errMess = "";
	my @arr     = $ch->RunChanges( \$errMess );
	print $errMess;

}

1;

