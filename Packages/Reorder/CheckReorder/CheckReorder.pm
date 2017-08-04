#-------------------------------------------------------------------------------------------#
# Description: Do check of reorder job. Recognize changes, which has to be done manually by tpv
# before pcb goes to production
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::CheckReorder;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Reorder::CheckReorder::CheckInfo';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# All controls
	my @controls = ();
	$self->{"controls"} = \@controls;

	my @chList = ();
	$self->{"checklist"} = \@chList;

	# 1) Load and check checklist
	$self->__LoadChecklist();

	# Load all check class
	$self->__LoadCheckClasses();

	return $self;
}

# Do all checks and return check which fail
sub RunCheck {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $jobExist = CamJob->JobExist( $inCAM, $jobId );
	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my @manCh = ();

	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $key = $checkInfo->GetKey();

		my $detail = "";    # Contain specifying message about manual task
		my %data   = ();    # Contain detail data, for process automatic task

		if ( $self->{"checks"}->{$key}->NeedChange( $inCAM, $jobId, $jobExist, $isPool, \$detail ) ) {

			my $str = undef;

			my %inf = ();
			$inf{"key"}    = $key;
			$inf{"desc"}   = $checkInfo->GetMessage();
			$inf{"detail"} = undef;

			if ( defined $detail && $detail ne "" ) {
				$inf{"detail"} = $detail;
			}
			push( @manCh, \%inf );
		}
	}

	return @manCh;
}

sub __LoadChecklist {
	my $self = shift;

	# Check if checklist is valid
	my $path  = GeneralHelper->Root() . "\\Packages\\Reorder\\CheckReorder\\CheckList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	# Parse

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		next if ( $l =~ /#/ );

		if ( $l =~ m/\[(.*)\]/ ) {

			my ($desc) = $1 =~ /\s*(.*)\s*/;
			my ($key)  = $lines[ $i + 1 ] =~ / =\s*(.*)\s*/;
			my ($mess) = $lines[ $i + 2 ] =~ / =\s*(.*)\s*/;

			my $checkInf = CheckInfo->new( $desc, $key, $mess );

			push( @{ $self->{"checklist"} }, $checkInf );

			$i += 2;
		}
	}

}

sub __LoadCheckClasses {
	my $self = shift;

	my %checks = ();

	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $key = $checkInfo->GetKey();

		my $module = 'Packages::Reorder::CheckReorder::Checks::' . $key;
		eval("use  $module;");
		$checks{$key} = $module->new($key);
	}

	$self->{"checks"} = \%checks;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

