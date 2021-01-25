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
use Encode qw(decode encode);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Comments::Enums' => 'CommEnums';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Stackup::StackupCode';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ControlPdf';
use aliased 'Programs::Comments::CommMail::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"commLayout"} = shift;           # make a deep copy. Package can cange layout
	$self->{"lang"}       = shift // "en";

	die "Language " . $self->{"lang"} . " is not implemented" if ( $self->{"lang"} !~ /(cz)|(en)/ );

	return $self;
}

# Open via MS outlook
sub Open {
	my $self          = shift;
	my $to            = shift;
	my $cc            = shift;
	my $subjectType   = shift;
	my $introduction  = shift;
	my $addFooter     = shift // 1;
	my $addOfferInf   = shift // 0;    # Add offer data specitication to email
	my $addOfferStckp = shift // 0;    # Add offer pdf stackup to email

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $p = GeneralHelper->Root() . "\\Programs\\Comments\\CommMail\\OutlookMail.pl";

	my @cmds = ();
	push( @cmds, $to );
	push( @cmds, $cc );
	push( @cmds, $self->__GetSubjectByType($subjectType) );

	my $bodyTxt = "";
	$bodyTxt .= $introduction . "\n\n" if ($introduction);
	$bodyTxt .= $self->__GetBody( $addOfferInf, $addOfferStckp );
	$bodyTxt .= $self->__GetFooter() if ($addFooter);

	#$bodyTxt=  encode( "UTF-8", $bodyTxt );

	push( @cmds, $bodyTxt );
	push( @cmds, [ $self->__GetAttachments($addOfferStckp) ] );
	push( @cmds, "open" );

	my $call = SystemCall->new( $p, @cmds );

	my $res = $call->Run();

	return $res;
}

# Sent via MIME::Lite
sub Sent {
	my $self          = shift;
	my $to            = shift;
	my $cc            = shift;
	my $subjectType   = shift;
	my $introduction  = shift;
	my $addFooter     = shift // 1;
	my $addOfferInf   = shift // 0;    # Add offer data specitication to email
	my $addOfferStckp = shift // 0;    # Add offer pdf stackup to email

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Do some checks before sent

	die "No email adress" if ( scalar( @{$to} ) == 0 );

	my @emails = ();
	push( @emails, @{$to} ) if ( defined $to );
	push( @emails, @{$cc} ) if ( defined $cc );

	foreach my $m (@emails) {

		if ( $m !~ /^.+\@.+\..+$/i ) {
			die "Wrong email format: $m";
		}
	}

	#	foreach my $m (@emails) {
	#
	#		if ( $m !~ /\@gatema/ ) {
	#			die "Unable to send email directly for email adress outside company: $m";
	#		}
	#	}

	#my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );
	my $name       = getlogin();
	my %employyInf = ();

	my $from      = 'tpvserver@gatema.cz';
	my $userEmail = 0;
	if ( defined $name && $name ne "" ) {
		my $userInfo = HegMethods->GetEmployyInfo($name);
		if ( defined $userInfo && defined $userInfo->{"e_mail"} =~ /^[a-z0-9.]+\@[a-z0-9.-]+$/i ) {

			$from      = $userInfo->{"e_mail"};
			$userEmail = 1;
		}
	}

	my $subject = $self->__GetSubjectByType($subjectType);

	my $body = "";
	$body .= $introduction . "\n\n" if ($introduction);
	$body .= $self->__GetBody( $addOfferInf, $addOfferStckp );
	$body .= $self->__GetFooter() if ($addFooter);

	my $bcc = $userEmail ? $from : "";    # Send copy of email to user

	my $msg = MIME::Lite->new(
		From => $from,
		To   => join( ", ", @{$to} ),
		Cc   => join( ", ", @{$cc} ),

		Bcc => $bcc,

		Subject => encode( "UTF-8", $subject ),    # Encode must by use if subject with diacritics

		Type => 'multipart/mixed'
	);

	# Add your text message.
	$msg->attach( Type => 'TEXT',
				  Data => encode( "UTF-8", $body ) );

	my @attach = $self->__GetAttachments($addOfferStckp);

	foreach my $att (@attach) {

		my ( $name, $path2, $suffix ) = fileparse($att);
		$msg->attach(
					  Type        => 'image/png',
					  Path        => $att,
					  Filename    => $name,
					  Disposition => 'attachment'
		);
	}

	my $result = $msg->send( 'smtp', EnumsPaths->URL_GATEMASMTP );

	#my $result = $msg->send( 'smtp', "127.0.0.1" );    # Paper cut testing smtp

	if ( $result ne 1 ) {

		print STDERR $result;
		$result = 0;

	}

	return $result;
}

# Return order/offer number for given pcbid
sub GetCurrOrderNumbers {
	my $self = shift;
	my $active = shift // 1;

	my @orders = HegMethods->GetPcbOrderNumbers( $self->{"jobId"} );

	if ($active) {

		# 5 - storno
		# 7 - ukoncena
		@orders = grep { $_->{"stav"} !~ /^[57]$/ } @orders;

	}

	@orders = map { $_->{"reference_subjektu"} } @orders;

	return @orders;
}

# Get email introduction
sub GetDefaultIntro {
	my $self        = shift;
	my $subjectType = shift;    # subject type

	die "No subject type defined" if ( !defined $subjectType );

	my $intro = "";

	# 1) Build greeting

	my %helloTbl = ();

	$helloTbl{ Enums->Subject_JOBFINIFHAPPROVAL }{"en"}    = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_JOBFINIFHAPPROVAL }{"cz"}    = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_JOBPROCESSAPPROVAL }{"en"}   = "Dear customer";            # email goes to customer
	$helloTbl{ Enums->Subject_JOBPROCESSAPPROVAL }{"cz"}   = "Vážený zákazníku";    # email goes to customer
	$helloTbl{ Enums->Subject_JOBRETURNTOSALES }{"en"}     = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_JOBRETURNTOSALES }{"cz"}     = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_OFFERFINIFHAPPROVAL }{"en"}  = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_OFFERFINIFHAPPROVAL }{"cz"}  = "Ahoj";                     # email goes to sales
	$helloTbl{ Enums->Subject_OFFERPROCESSAPPROVAL }{"en"} = "Dear customer";            # email goes to customer
	$helloTbl{ Enums->Subject_OFFERPROCESSAPPROVAL }{"cz"} = "Vážený zákazníku";    # email goes to customer

	$intro .= $helloTbl{$subjectType}{ $self->{"lang"} };

	$intro .= ",\n\n";

	# 1) Build introduction
	if ( $subjectType eq Enums->Subject_JOBFINIFHAPPROVAL ) {

		# Go to Gatema sales

		$intro .= "zakázka je zpracovaná, před zahájením výroby prosím odsouhlasit u zákazníka následující TPV komentáře:";

	}
	elsif ( $subjectType eq Enums->Subject_OFFERFINIFHAPPROVAL ) {

		# Go to Gatema sales

		$intro .= "nabídka je zpracovaná.";

	}
	elsif ( $subjectType eq Enums->Subject_JOBPROCESSAPPROVAL ) {

		# Go to Gatema customer

		if ( $self->{"lang"} eq "cz" ) {

			$intro .= "prosíme o reakci na následující komentáře z TPV oddělení, týkající se vaší objednávky.";

		}
		elsif ( $self->{"lang"} eq "en" ) {

			$intro .= "please respond to the following comments from CAM department regarding your order.";

		}

	}
	elsif ( $subjectType eq Enums->Subject_OFFERPROCESSAPPROVAL ) {

		# Go to Gatema customer

		if ( $self->{"lang"} eq "cz" ) {

			$intro .= "prosíme o reakci na následující komentáře z TPV oddělení, týkající se vaší poptávky.";

		}
		elsif ( $self->{"lang"} eq "en" ) {

			$intro .= "please respond to the following comments from CAM department regarding your inquiry.";

		}
	}
	elsif ( $subjectType eq Enums->Subject_JOBRETURNTOSALES ) {

		# Go to Gatema customer

		if ( $self->{"lang"} eq "cz" || $self->{"lang"} eq "en" ) {

			$intro .= "vracím zakázku na OÚ a prosím o dořešení následujích komentářů:";

		}
	}

	return $intro;

}

sub __GetSubjectByType {
	my $self        = shift;
	my $subjectType = shift;

	my $subject = $subjectType;    # by default subject equals subjectType

	my $jobId = $self->{"jobId"};

	my %sub = ();

	$sub{ Enums->Subject_JOBFINIFHAPPROVAL }{"en"}    = "Approval before production";
	$sub{ Enums->Subject_JOBFINIFHAPPROVAL }{"cz"}    = "Odsouhlasení před výrobou";    #"odsouhlasení před zahájením výroby";
	$sub{ Enums->Subject_JOBPROCESSAPPROVAL }{"en"}   = "Technical question";
	$sub{ Enums->Subject_JOBPROCESSAPPROVAL }{"cz"}   = "Technický dotaz";                #"technický dotaz";
	$sub{ Enums->Subject_JOBRETURNTOSALES }{"en"}     = "Zakázka vrácena na OÚ";        # zakázka vrácena na oú
	$sub{ Enums->Subject_JOBRETURNTOSALES }{"cz"}     = "Zakázka vrácena na OÚ";        # zakázka vrácena na oú
	$sub{ Enums->Subject_OFFERFINIFHAPPROVAL }{"en"}  = "RFQ approval";
	$sub{ Enums->Subject_OFFERFINIFHAPPROVAL }{"cz"}  = "RFQ odsouhlasení";               #"Poptávka hotovo";
	$sub{ Enums->Subject_OFFERPROCESSAPPROVAL }{"en"} = "RFQ - technical question";
	$sub{ Enums->Subject_OFFERPROCESSAPPROVAL }{"cz"} = "RFQ - technický dotaz";          #"Poptávka - technický dotaz";

	if ( defined $sub{$subjectType} && defined $sub{$subjectType}{ $self->{"lang"} } ) {

		$subject = "";

		# 1) Add order/offer id
		my $jobTxt = "<job number not found>";
		my @orders = $self->GetCurrOrderNumbers();
		if (@orders) {
			$jobTxt = uc( join( "; ", @orders ) );

		}
		$subject .= $jobTxt . ": ";

		# 2) Add subject title
		$subject .= $sub{$subjectType}{ $self->{"lang"} };

		# 3) Add customer data name
		my $pcbInf = HegMethods->GetBasePcbInfo($jobId);
		if ( defined $pcbInf->{"nazev_subjektu"} && $pcbInf->{"nazev_subjektu"} ne "" ) {
			$subject .= " (" . $pcbInf->{"nazev_subjektu"} . ")";

		}

		# 4) If job is not offer try to add customer order
		if (@orders) {
			my $custOrderInf = HegMethods->GetCustomerOrderInfo( $orders[0] );

			if ( defined $custOrderInf ) {
				my $custOrder = $custOrderInf->{"nazev_subjektu"};

				if ( defined $custOrder && $custOrder ne "" ) {
					$subject .= " - " . $custOrder;
				}
			}
		}

	}

	die "Email subject is empty" if ( !defined $subject || $subject eq "" );

	return $subject;
}

sub __GetBody {
	my $self          = shift;
	my $addOfferInf   = shift;
	my $addOfferStckp = shift;

	my $body = "";

	# 1) Build body from comments

	my @allComm = $self->{"commLayout"}->GetAllComments();

	for ( my $i = 0 ; $i < scalar(@allComm) ; $i++ ) {

		my $messSngl = "";

		my $listTag = "-";

		$listTag = ( $i + 1 ) . ") ";

		$messSngl .= $listTag;
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

			#my $referTo = ( $self->{"lang"} eq "cz" ? "viz" : "refer to" );
			$messSngl =~ s/\@f$j/$fullName/g;
		}

		$body .= $messSngl . "\n\n";
	}

	# 2) Build body from inquiry information
	if ($addOfferInf) {

		my $inquiryInf = $self->__GetInquiryInf($addOfferStckp);

		$body = $inquiryInf . "\n\n" . $body;
	}

	die "Email body is empty" if ( scalar(@allComm) > 1 && ( !defined $body || $body eq "" ) );

	return $body;
}

# Return mail footer with contact information
sub __GetFooter {
	my $self = shift;

	my $footer = "";

	# Add footer
	#my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );
	my $name = getlogin();
	if ( defined $name && $name ne "" ) {
		my $userInfo = HegMethods->GetEmployyInfo( getlogin() );
		if ( defined $userInfo ) {

			$footer = "---\n";
			$footer .= ( $self->{"lang"} eq "cz" ? "Děkuji"                       : "Thank you" ) . "\n";
			$footer .= ( $self->{"lang"} eq "cz" ? "S pozdravem"                   : "With Best Regards" ) . "\n\n";
			$footer .= $userInfo->{"prijmeni"} . "\n";
			$footer .= $userInfo->{"jmeno"} . "\n";
			$footer .= ( $self->{"lang"} eq "cz" ? "Technická příprava výroby" : "CAM Department" ) . "\n\n";

			my $tel = $userInfo->{"telefon_prace"};

			# add +420
			$tel = "+420 " . $tel if ( $tel !~ /\+420/ );

			$footer .= "T " . $tel . "\n";
			$footer .= $userInfo->{"e_mail"} . "\n";
			$footer .= "Gatema PCB a.s.\n";
			$footer .= "Průmyslová 2503/2\n";
			$footer .= "CZ 680 01 Boskovice";
		}
	}

	return $footer;
}

sub __GetAttachments {
	my $self          = shift;
	my $addOfferStckp = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

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

	# Add inquiry infstackup
	if ($addOfferStckp) {
		my $mess = "";
		my $control = ControlPdf->new( $inCAM, $jobId, "o+1", 0, 0, $self->{"lang"}, 1 );

		$control->AddStackupPreview( \$mess );
		my $reuslt = $control->GeneratePdf( \$mess );

		if ($reuslt) {

			my $pdfPath = $control->GetOutputPath();
			my $newName = "_stackup.pdf";

			my @orders = $self->GetCurrOrderNumbers();

			if ( scalar(@orders) ) {
				$newName = uc( $orders[0] ) . $newName;
			}
			else {
				$newName = uc($jobId) . $newName;
			}

			my $path = ( fileparse($pdfPath) )[1];
			$path .= "\\" . $newName;

			rename( $pdfPath, $path );
			unshift( @attachmenst, $path );

		}
		else {
			die "Error during create stackup. Detail: $mess";
		}

	}

	return @attachmenst;
}

sub __GetInquiryInf {
	my $self          = shift;
	my $addOfferStckp = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = "panel";

	if ( !CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
		$step = "o+1";
	}

	my $stckpCode = StackupCode->new( $inCAM, $jobId, $step );

	my $txt = shift;

	my @text = ();

	my $isFlex = JobHelper->GetIsFlex($jobId);

	push( @text, "Informace o poptávce pro obchodní úsek Gatema:" );
	push( @text, "" );

	if ($addOfferStckp) {

		my $stckpName = "_stackup.pdf";
		my @orders    = $self->GetCurrOrderNumbers();
		if ( scalar(@orders) ) {
			$stckpName = uc( $orders[0] ) . $stckpName;
		}
		else {
			$stckpName = uc($jobId) . $stckpName;
		}

		push( @text, "- PDF stackup ($stckpName) v příloze" );
	}
	push( @text, "- Typ: " . HegMethods->GetTypeOfPcb($jobId) );
	push( @text, "- Flex kód: " . $stckpCode->GetStackupCode(1) ) if ($isFlex);
	push( @text, "- Třída: " . CamJob->GetJobPcbClass( $inCAM, $jobId ) . "." );

	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	push( @text, "- Rozměr kusu: " . $dim{"single_x"} . "x" . $dim{"single_y"} . "mm" );

	if ( defined $dim{"nasobnost_panelu"} && $dim{"nasobnost_panelu"} > 0 ) {
		push( @text, "- Rozměr panelu: " . $dim{"panel_x"} . "x" . $dim{"panel_y"} . "mm" );
		push( @text, "- Násobnost panelu: " . $dim{"nasobnost_panelu"} );
	}

	push( @text, "- Násobnost přířezu: " . $dim{"nasobnost"} );
	push( @text, "- Rozměr přířezu: " . $dim{"vyrobni_panel_x"} . "x" . $dim{"vyrobni_panel_y"} . "mm" );

	push( @text, "\nInformace o poptávce pro zákazníka:" );

	return join( "\n", @text );

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

