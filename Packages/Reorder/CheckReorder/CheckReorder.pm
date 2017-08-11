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
	#my @controls = ();
	#$self->{"controls"} = \@controls;

	my @chList = ();
	$self->{"checks"} = \@chList;

	# 1) Load  checklist and check classes
	$self->__LoadChecks();

	## Load all check class
	#3$self->__LoadCheckClasses();

	return $self;
}

# Do all checks and return check which fail
sub RunChecks {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 
	my @manCh = ();

	foreach my $check ( @{ $self->{"checks"} } ) {
 
		$check->Run();
		my @changes = $check->GetChanges();
		
		if(scalar(@changes)){
			push( @manCh, @changes );
		}	 
	}

	return @manCh;
}

#sub __LoadChecklist {
#	my $self = shift;
#
#	# Check if checklist is valid
#	my $path  = GeneralHelper->Root() . "\\Packages\\Reorder\\CheckReorder\\CheckList";
#	my @lines = @{ FileHelper->ReadAsLines($path) };
#
#	# Parse
#
#	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {
#
#		my $l = $lines[$i];
#
#		next if ( $l =~ /#/ );
#
#		if ( $l =~ m/\[(.*)\]/ ) {
#
#			my ($desc) = $1 =~ /\s*(.*)\s*/;
#			my ($key)  = $lines[ $i + 1 ] =~ / =\s*(.*)\s*/;
#			my ($mess) = $lines[ $i + 2 ] =~ / =\s*(.*)\s*/;
#
#			my $checkInf = CheckInfo->new( $desc, $key, $mess );
#
#			push( @{ $self->{"checklist"} }, $checkInf );
#
#			$i += 2;
#		}
#	}
#
#}
#
#sub __LoadCheckClasses {
#	my $self = shift;
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	my $jobExist = CamJob->JobExist( $inCAM, $jobId );
#	my $isPool = HegMethods->GetPcbIsPool($jobId);
#
#	my %checks = ();
#
#	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {
#
#		my $key = $checkInfo->GetKey();
#
#		my $module = 'Packages::Reorder::CheckReorder::Checks::' . $key;
#		eval("use  $module;");
#		$checks{$key} = $module->new($key, $inCAM, $jobId, $jobExist, $isPool);
#	}
#
#	$self->{"checks"} = \%checks;
#
#}

sub __LoadChecks {
	my $self = shift;

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);
	my $jobExist = CamJob->JobExist( $inCAM, $jobId );

	my $path  = GeneralHelper->Root() . "\\Packages\\Reorder\\CheckReorder\\CheckList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	unless ( -e $path ) {
		die "Unable to process reorder $jobId, because \"CheckList\" file doesnt exist.\n";
	}

	my @checks = ();

	@lines = grep { $_ !~ /#/ } @lines;

	foreach my $l (@lines) {

		$l =~ s/\s//g;

		if ( $l ne "" ) {

			my $key = uc($l);

			my $module = 'Packages::Reorder::CheckReorder::Checks::' . $key;
			eval("use  $module;");

			push( @checks, $module->new( $key, $inCAM, $jobId, $jobExist, $isPool ) );
		}
	}

	unless ( scalar(@checks) ) {
		die "Unable to process reorder $jobId, because there are no automatic changes.\n";

	}

	$self->{"checks"} = \@checks;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::CheckReorder';
	
	use aliased 'Packages::InCAM::InCAM';
	
	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "f52457";
	
	my $ch = CheckReorder->new($inCAM, $jobId);
	my @arr = $ch->RunChecks();
	
	dump(@arr)

}

1;

