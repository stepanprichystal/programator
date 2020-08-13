
#-------------------------------------------------------------------------------------------#
# Description: Generate email from comment layout
# - If mail is send directly use package: Mail::Sender (thread safe and no dependencies on 3rd apps)
# - If mail is only displayed use package: MIME::Lite. Work with MS Outloook
# no thread safe, thus run it in sepaarte perl process
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommMail::CommMail;

#3th party library
use utf8;
use strict;
use warnings;
use Switch;
use File::Basename;
use File::Copy;
use MIME::Lite;
use File::Basename;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Comments::Enums' => 'CommEnums';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"commLayout"} = shift;
	$self->{"lang"}       = shift // "en";

	die "Language " . $self->{"lang"} . " is not implemented" if ( $self->{"lang"} !~ /(cz)|(en)/ );

	return $self;
}

# Open via MS outlook
sub Open {
	my $self    = shift;
	my $to      = shift;
	my $cc      = shift;
	my $subject = shift;

	my $p = GeneralHelper->Root() . "\\Programs\\Comments\\CommMail\\OutlookMail.pl";

	my @cmds = ();
	push( @cmds, $to );
	push( @cmds, $cc );
	push( @cmds, $subject );
	push( @cmds, $self->__GetBody() );
	push( @cmds, [ $self->__GetAttachments() ] );
	push( @cmds, "open" );

	my $call = SystemCall->new( $p, @cmds );

	return $call->Run();
}

# Sent via MIME::Lite
sub Sent {
	my $self    = shift;
	my $to      = shift;
	my $cc      = shift;
	my $subject = shift;

	my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );

	my %employyInf = ();

	my $from = 'tpvserver@gatema.cz';
	if ( defined $name && $name ne "" ) {
		my $userInfo = HegMethods->GetEmployyInfo($name);
		if ( defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i ) {

			$from = $userInfo->{"e_mail"};
		}
	}
 

	my @attach = $self->__GetAttachments();
	my $body   = $self->__GetBody();

	my $msg = MIME::Lite->new(
							   From    => $from,
							   To      => join( ", ", @{$to} ),
							   Cc      => join( ", ", @{$cc} ),
							   Subject => $subject,
							   Type    => 'multipart/mixed'
	);

	# Add your text message.
	$msg->attach( Type => 'TEXT',
				  Data => $body );

	foreach my $att (@attach) {

		my ( $name, $path2, $suffix ) = fileparse($att);
		$msg->attach(
					  Type        => 'image/png',
					  Path        => $att,
					  Filename    => $name,
					  Disposition => 'attachment'
		);
	}

	my $result =  $msg->send( 'smtpe', EnumsPaths->URL_GATEMASMTP );
	
	if($result ne 1){
		
		print STDERR $result;
		$result = 0;
		
	}
 
	return $result;
}

sub __GetBody {
	my $self = shift;

	my $body = "";

	my @allComm = $self->{"commLayout"}->GetAllComments();

	for ( my $i = 0 ; $i < scalar(@allComm) ; $i++ ) {

		my $messSngl = "";

		my $listTag = "-";

		if ( $allComm[$i]->GetType() eq CommEnums->CommentType_QUESTION ) {

			$listTag = ( $i + 1 ) . ") " . ( $self->{"lang"} eq "cz" ? "Otázka" : "Question" );

		}
		elsif ( $allComm[$i]->GetType() eq CommEnums->CommentType_NOTE ) {

			$listTag = ( $i + 1 ) . ") " . ( $self->{"lang"} eq "cz" ? "Poznámka" : "Note" );
		}

		$messSngl .= $listTag . ": ";
		$messSngl .= $allComm[$i]->GetText();

		my @char = ( "A" .. "Z" );

		my @sugg = $allComm[$i]->GetAllSuggestions();

		#$messSngl .= "\n" if ( scalar(@sugg) );

		for ( my $j = 0 ; $j < scalar(@sugg) ; $j++ ) {

			$messSngl .= "\n	" . $char[$j] . ") " . $sugg[$j];
		}

		# Replace special char @f\d with name of file
		my @files = $allComm[$i]->GetAllFiles();
		for ( my $j = 1 ; $j <= scalar(@files) ; $j++ ) {
			my $f = $files[$i];
			my $fullName = $self->{"commLayout"}->GetFileNameByTag( $i, '@f' . ($j) );

			my $referTo = ( $self->{"lang"} eq "cz" ? "viz" : "refer to" );
			$messSngl =~ s/\@f$j/$referTo $fullName/g;
		}

		$body .= $messSngl . "\n\n";
	}

	return $body;
}

sub __GetAttachments {
	my $self = shift;

	my @attachmenst = ();

	my @allComm = $self->{"commLayout"}->GetAllComments();

	# Set attachments
	for ( my $i = 0 ; $i < scalar(@allComm) ; $i++ ) {

		my @files = $allComm[$i]->GetAllFiles();
		for ( my $j = 0 ; $j < scalar(@files) ; $j++ ) {

			my $p = $files[$j]->GetFilePath();
			my $newName = $self->{"commLayout"}->GetFullFileNameById( $i, $j );

			my $tmpPath = ( fileparse($p) )[1] . $newName;

			copy( $p, $tmpPath );
			push( @attachmenst, $tmpPath );

		}
	}

	return @attachmenst;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Comments::CommMail::CommMail';
	use aliased 'Programs::Comments::Comments';

	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d288054";

	my $inCAM = InCAM->new();
	my $comm = Comments->new( $inCAM, $jobId );

	my $mail = OutlookMail->new( $comm->GetLayout() );
	my @to   = ( 'pcb@gatema.cz', 'CAM@gatema.cz' );
	my @cc   = ('stepan.prichystal@gatema.cz');

	$mail->Open( \@to, \@cc, "test" );

}

1;

