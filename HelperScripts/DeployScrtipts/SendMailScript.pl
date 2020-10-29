#-------------------------------------------------------------------------------------------#
# Send email with fetched commits messages to TPV
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;
use Switch;
use File::Basename;
use File::Copy;
use MIME::Lite;
use File::Basename;
use Encode qw(decode encode);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $commitBeforeP = shift;
my $commitAfterP  = shift;

if ( -e $commitBeforeP && -e $commitAfterP ) {

	my $res = __Sent( $commitBeforeP, $commitAfterP );

	unlink($commitBeforeP);
	unlink($commitAfterP);

}
else {

	print STDERR "Log file: $commitBeforeP doesn't exists" unless ( -e $commitBeforeP );
	print STDERR "Log file: $commitAfterP doesn't exists"  unless ( -e $commitAfterP );
}

# Sent via MIME::Lite
sub __Sent {
	my $commitBeforeP = shift;
	my $commitAfterP  = shift;

	my $to = [ EnumsPaths->MAIL_GATTPV ];

	# Do some checks before sent

	die "No email adress" if ( scalar( @{$to} ) == 0 );

	my @emails = ();
	push( @emails, @{$to} ) if ( defined $to );

	foreach my $m (@emails) {

		if ( $m !~ /^.+\@.+\..+$/i ) {
			die "Wrong email format: $m";
		}
	}

	my $from = 'tpvserver@gatema.cz';

	my $subject = "GIT report - upravy scriptu";

	my $body = "Ahoj, \n\nbyly provedeny následující úpravy (commits) ve scriptech:\n\n";
	#
	#my $body = "Ahoj, \n\n";

	my $text = __GetChanges( $commitBeforeP, $commitAfterP );
	if ( !defined $text ) {

		print STDERR "No new commits\n";
		return 0;

	}

	$body .= $text;
	$body .= "\n\n" . "---\nToto je automaticky email vygenerovany pri spusteni prikazu GIT FETCH\n\n";
	$body .= "GIT - version control system";

	my $msg = MIME::Lite->new(
		From => $from,

		To => join( ", ", @{$to} ),

		#To  => 'stepan.prichystal@gatema.cz',
		Bcc => 'stepan.prichystal@gatema.cz',    # TODO temporary for testing

		Subject => encode( "UTF-8", $subject ),  # Encode must by use if subject with diacritics

		#		Subject => $subject,  # Encode must by use if subject with diacritics

		Type => 'multipart/mixed'
	);

	# Add your text message.
	$msg->attach(
		Type => 'TEXT',

		Data => encode( "UTF-8", $body )

		  #Data => $body
	);

	my $result = $msg->send( 'smtp', EnumsPaths->URL_GATEMASMTP );

	#my $result = $msg->send( 'smtp', "127.0.0.1" );    # Paper cut testing smtp

	if ( $result ne 1 ) {

		print STDERR $result;
		$result = 0;

	}

	return $result;
}

sub __GetChanges {
	my $commitBeforeP = shift;
	my $commitAfterP  = shift;

	my $text = undef;

	my $lastCommStr = FileHelper->ReadAsString($commitBeforeP);

	my ($commId) = $lastCommStr =~ /^commit\s(\w+)\s/;

	if ( defined $commId && $commId ne "" ) {

		my $f;
		my @last10Comm;
		if ( open( $f, "<:utf8", $commitAfterP ) ) {

			@last10Comm = <$f>;

			close($f);
		}
		$text = "";

		my $i = 1;

		foreach my $l (@last10Comm) {

			if ( $l =~ /$commId/ ) {
				last;
			}

			if ( $l =~ /^commit\s(\w+)/ ) {

				$text .= $i . ") ------------------------------------------------------------------------\n";
				$i++;
			}
			else {

				$text .= $l;
			}

		}

		$text = undef if ( $i == 1 );
	}

	return $text;
}

1;

