#-------------------------------------------------------------------------------------------#
# Description: Vyhleda OLEC znacky v Genesisu a jejich souradnice zapise do Gerber file pod nový DCODE.
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::Gerbers::Mdi::ExportFiles::FiducMark;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
# ficucial mark diameters
my $FIDMARK_MM   = "5.16120000";
my $FIDMARK_INCH = "0.202815";

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"units"} = shift;    # inch/mm

	return $self;

}

sub AddFiducialMarks {
	my $self       = shift;
	my $gerberPath = shift;
	my @fiducPos   = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $maxDCode = $self->__GetHighestDcode($gerberPath);

	# if max code doesnt exist, set fake max code 9, because first dcode in gerbers start with 10
	my $fiducDcode;

	if ( defined $maxDCode ) {

		$fiducDcode = $maxDCode + 1;
	}
	else {

		$fiducDcode = 10;
	}

	my @gbrFiducLines = ();
	push( @gbrFiducLines, 'G54D' . $fiducDcode . '*' );

	foreach my $pos (@fiducPos) {

		if ( $self->{"units"} eq "inch" ) {
			$pos->{"x"} /= 25.4;
			$pos->{"y"} /= 25.4;
		}

		my $x = sprintf( "X%010d", sprintf "%3.0f", $pos->{'x'} * 1000000 );
		my $y = sprintf( "Y%010d", sprintf "%3.0f", $pos->{'y'} * 1000000 );

		push( @gbrFiducLines, $x . $y . 'D03*' );
	}

	my $res = $self->__AddDcodeLines2Ger( $gerberPath, \@gbrFiducLines, $fiducDcode );

	return $fiducDcode;

}

# Go through gerber file and return highest DCode
sub __GetHighestDcode {
	my $self       = shift;
	my $gerberPath = shift;

	my $highestDcode;
	my $f;

	if ( open( $f, "<", "$gerberPath" ) ) {
		while (<$f>) {
			if ( $_ =~ /^\%ADD(\d{1,4})/ ) {
				$highestDcode = $1;
			}
		}
		close $f;
	}

	return $highestDcode;
}


sub __AddDcodeLines2Ger {
	my $self       = shift;
	my $gerberPath = shift;
	my @DCodeLines = @{ shift(@_) };
	my $fiducDcode = shift;

	my $tmpPath = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	my $TMPFILE;
	my $GERFILE;
	open( $TMPFILE, ">>$tmpPath" )  or die "Unable create tmp file Detail: $_";
	open( $GERFILE, "$gerberPath" ) or die "Unable open gerber file: $_";

	my $lastDcode = '%ADD' . ( $fiducDcode - 1 );
	my $fiducLineIns = 0;
	my $fiducDCodeIns = 0;
	while ( my $l = <$GERFILE> ) {

		print $TMPFILE "$l";

		# Put DCode definition on first position or of there is no MOIN/MOMM put on last postion
		# MOIN = gerber is in inches
		# MOMM = gerber is in millimetres
		if ( !$fiducDCodeIns && ($l =~ /$lastDcode/ || $l =~ /MO((IN)|(MM))/) ) {

			my $dcodeDiemeter;
			if ( $self->{"units"} eq 'mm' ) {
				$dcodeDiemeter = $FIDMARK_MM;
			}
			elsif ( $self->{"units"} eq 'inch' ) {
				$dcodeDiemeter = $FIDMARK_INCH;
			}
			else {

				die "Wrong units: " . $self->{"units"};
			}

			print $TMPFILE '%ADD' . $fiducDcode . 'C,' . $dcodeDiemeter . '*%' . "\n";
			$fiducDCodeIns = 1;
		}

		# Put lines with fiducial position
		if ( !$fiducLineIns && $l =~ /G75*/) {

			print $TMPFILE "$_\n" foreach (@DCodeLines);
			$fiducLineIns = 1;
		}

	}
	close $GERFILE;
	close $TMPFILE;
	unlink "$gerberPath";
	rename( "$tmpPath", "$gerberPath" ) or die "Unable reneame file: $_";

	return 1;
}

1;
