#-------------------------------------------------------------------------------------------#
# Description: Reading information from nif file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::NifFile::NifFile;

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"nifPath"} = JobHelper->GetJobArchive( $self->{"jobId"} ) . $self->{"jobId"} . ".nif";

	my %nifData = ();
	$self->{"nifData"}  = \%nifData;
	$self->{"nifExist"} = 0;
	$self->{"nifRows"}  = undef;

	$self->__ParseNif();

	return $self;
}

# Return base cu thick by layer
sub Exist {
	my $self = shift;

	if ( $self->{"nifExist"} ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if attribute exist in nif file
sub AttributeExists {
	my $self      = shift;
	my $attribute = shift;
	my $value     = shift;
	chomp($attribute);

	if ( exists $self->{"nifData"}->{$attribute} ) {

		return 1;
	}
	else {

		return 0;
	}

}

sub GetSection {
	my $self        = shift;
	my $sectionName = shift;
	my $lines       = shift;

	my $read = 1;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"nifRows"} } ) ; $i++ ) {

		my $l = $self->{"nifRows"}->[$i];

		if ( $l =~ /.*\[=+\s+SEKCE ([^=]*)\s+=+\].*/i ) {

			# if requested section, read unless another section begin
			if ( $1 =~ /$sectionName/i ) {
				push( @{$lines}, $l );

				while (1) {
					$i++;
					my $lSection = $self->{"nifRows"}->[$i];

					if ( !defined $lSection || $lSection =~ /.*\[=+\s+SEKCE ([^=]*)\s+=+\].*/i ) {
						$read = 0;
						last;
					}

					push( @{$lines}, $lSection );
				}
			}
		}

		unless ($read) {
			last;
		}
	}

	# remove line compete = 1 if exist

	@{$lines} = grep { $_ !~ /complete/i } @{$lines};

	if ( scalar( @{$lines} ) ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub GetValue {
	my $self      = shift;
	my $attribute = shift;

	chomp($attribute);

	return $self->{"nifData"}->{$attribute};
}

# Return author of pcb
sub GetPcbAuthor {
	my $self = shift;

	return $self->GetValue("zpracoval");

}

#Return color of mask in hash for top and bot side
sub GetSolderMaskColor {
	my $self = shift;

	my %mask = ();

	$mask{"top"} = $self->GetValue("maska_c_1");
	$mask{"bot"} = $self->GetValue("maska_s_1");

	return %mask;
}

#Return color of silk screen in hash for top and bot side
sub GetSilkScreenColor {
	my $self = shift;

	my %silk = ();

	$silk{"top"} = $self->GetValue("potisk_c_1");
	$silk{"bot"} = $self->GetValue("potisk_s_1");

	return %silk;
}

#Return second color of silk screen in hash for top and bot side
sub GetSilkScreenColor2 {
	my $self = shift;

	my %silk = ();

	$silk{"top"} = $self->GetValue("potisk_c_2");
	$silk{"bot"} = $self->GetValue("potisk_s_2");

	return %silk;
}

# Return:
# - 0 - if payments is not in nif or if is in inf and contains "-"
# - 1 - if payments contains "+"
sub GetPayment {
	my $self      = shift;
	my $paymentId = shift;

	my $payement = 0;

	my $row = ( grep { $_ =~ /$paymentId/i } @{ $self->{"nifRows"} } )[0];

	if ( $row && $row !~ /\-/ ) {
		$payement = 1;
	}

	return $payement;
}

sub ReplaceValue {
	my $self      = shift;
	my $attribute = shift;
	my $value     = shift;

	chomp($attribute);
	if ( exists $self->{"nifData"}->{$attribute} ) {

		my $file = path( $self->{"nifPath"} );
		my $data = $file->slurp_utf8;
		$data =~ s/($attribute)=.*/$1=$value/i;
		$file->spew_utf8($data);

		# Parse NIF again
		$self->__ParseNif();

	}
	else {
		die "Nif attribute: $attribute, doesn't exist";

	}
	return $self->{"nifData"}->{$attribute};

}

sub __ParseNif {
	my $self = shift;

	if ( -e $self->{"nifPath"} ) {

		$self->{"nifExist"} = 1;

		my @lines = @{ FileHelper->ReadAsLines( $self->{"nifPath"} ) };
		$self->{"nifRows"} = \@lines;

		foreach my $l (@lines) {

			if ( $l =~ /.*[^=]=[^=].*/ ) {

				my @splited = split( "=", $l );
				chomp @splited;

				$self->{"nifData"}->{ $splited[0] } = $splited[1];
			}
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::NifFile::NifFile';

	my $nif = NifFile->new("f52456");

	my @lines = ();
	if ( $nif->GetSection( "ostatni2", \@lines ) ) {
		print @lines;
	}
}

1;

