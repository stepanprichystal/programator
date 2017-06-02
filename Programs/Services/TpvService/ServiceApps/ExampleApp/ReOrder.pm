#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ReOrder::ReOrder;

#3th party library
use strict;
use warnings;
use Mail::Sender;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# All controls
	my @controls = ();
	$self->{"controls"} = \@controls;

	$self->{"checklist"} = undef;

	return $self;
}

sub Run {
	my $self = shift;
	
	# 1) Load and check checklist
	$self->__LoadChecklist();
	
	# 2) Load Reorder pcb
	my @reorders = grep { !defined $_->{"aktualni_krok"} || $_->{"aktualni_krok"} eq "" } HegMethods->GetReorders();
	
	foreach my $reorder (@reorders){
		
		$self->__DoChecks($reorder);
		
	}

}


# Unarchove job, do checks and create chescklist file in archive
sub __DoChecks {
	my $self = shift;
	
	# Check if pcb exist in Incam
	
	

}

sub __SetState {
	my $self = shift;

}

sub __CreateCheckFile {
	my $self = shift;

}

sub __LoadChecklist {
	my $self = shift;

	# Check if checklist is valid
	my $path  = GeneralHelper->Root() . "\\Programs\\TpvService\\Reorder\\CheckList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	# Parse

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		next if ( $l =~ /#/ );

		if ( $l =~ /[(.*)]/ ) {
 
			my %inf = ("Desc" => $1);
 			 
			for ( ; 1 .. 4 ; $i++ ) {

				my ( $k, $val ) = split( "=", $lines[$i] );

				$k =~ s/\s//g;
				$val =~ s/\s//g;
				$inf{$k} = $val;
			}
			
			$self->{"checklist"}->{$inf{"K"}} = \%inf;
		}
	}
	
	
	# 1) Check if all check has defined type
	foreach my $key (keys %{$self->{"checklist"}}){
		
		my $t = $self->{"checklist"}->{$key}->{"T"};
		my $r = $self->{"checklist"}->{$key}->{"R"};
		
		if( !defined $t || $t eq ""){
			die "Check $key has not defined type";
		}
		
		if(  $t eq "manual" && (!defined $r || $r eq "")){
			
			die "Check $key has to has defined 'R' in checklist";
		}
	}
	
	# 2) Check if all check class "keys" are in checklist
	foreach my $control (@{$self->{"controls"}}){
		
		unless( defined $self->{"checklist"}->{$control->GetCheckKey()} ){
			die "Check key ".$control->GetCheckKey()." is not defined in checklist";
		}	
	}
	
 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::LogService::MailSender::MailSender';

	#	use aliased 'Packages::InCAM::InCAM';
	#

	my $sender = MailSender->new();

	$sender->Run();

	print "ee";
}

1;

