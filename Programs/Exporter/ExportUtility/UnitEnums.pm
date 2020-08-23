
package Programs::Exporter::ExportUtility::UnitEnums;

use constant {
	UnitId_NIF   => "nif",
	UnitId_NC    => "nc",
	UnitId_ET    => "et",
	UnitId_AOI   => "aoi",
	UnitId_PLOT  => "plot",
	UnitId_PRE   => "pre",
	UnitId_GER   => "ger",
	UnitId_PDF   => "pdf",
	UnitId_SCO   => "score",
	UnitId_OUT   => "out",
	UnitId_STNCL => "stencil",
	UnitId_IMP   => "imp",
	UnitId_COMM  => "comments",
	UnitId_OFFER => "offer",
};

sub GetTitle {
	my $self = shift;
	my $code = shift;

	my $title = "Unknown";

	if ( $code eq UnitId_NIF ) {

		$title = "Nif file";

	}
	elsif ( $code eq UnitId_NC ) {

		$title = "NC programs";

	}
	elsif ( $code eq UnitId_ET ) {

		$title = "ET testing";

	}
	elsif ( $code eq UnitId_AOI ) {

		$title = "AOI testing";

	}
	elsif ( $code eq UnitId_PLOT ) {

		$title = "Plot films";

	}
	elsif ( $code eq UnitId_PRE ) {

		$title = "Dif file";

	}
	elsif ( $code eq UnitId_PDF ) {

		$title = "Pdf files";

	}
	elsif ( $code eq UnitId_GER ) {

		$title = "Gerbers";

	}
	elsif ( $code eq UnitId_SCO ) {

		$title = "Score programs";

	}
	elsif ( $code eq UnitId_OUT ) {

		$title = "Output data";

	}
	elsif ( $code eq UnitId_STNCL ) {

		$title = "Stencil data";

	}
	elsif ( $code eq UnitId_IMP ) {

		$title = "Impedance data";

	}
	elsif ( $code eq UnitId_COMM ) {

		$title = "Approval comments";

	}elsif ( $code eq UnitId_OFFER ) {

		$title = "Job offer";

	}

	return $title;
}

#sub GetDescriptions{
#	my $self = shift;
#	my $unit = shift;
#
#	use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#
#	my $description;
#
#	if($unit eq UnitEnums->UnitId_NIF ){
#
#		$description =  "Nif";
#	}
#
#}

1;

