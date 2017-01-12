
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Mdi::ExportFiles::ExportXml;
 

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';

#use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';

#use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Export::GerExport::Helper';

#use aliased 'CamHelpers::CamSymbol';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Packages::Polygon::PolygonHelper';
#use aliased 'Packages::Polygon::Features::Features::RouteFeatures';
#use aliased 'Packages::Gerbers::Export::ExportLayers';
#use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Packages::Mdi::ExportFiles::FiducMark';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self  = {};
	bless $self;
 

	return $self;
}

sub Export{
	my $self    = shift;
	
	
	my $templ = $self->__LoadTemplate();
	
	unless($templ){
		return 0;
	}
	
	# Set job name
	$templ->{"job_params"}->{"job_name"}
	
	
	
}

sub __LoadTemplate {
	my $self    = shift;
	
	my $templPath = GeneralHelper->Root()."\\Packages\\Mdi\\ExportFiles\\template.xml";
 	my $templXml = FileHelper->Open( $templPath );
 

	my @thickList = ();

	my $xml = XMLin(
					 $templXml,
					 ForceArray => undef,
					 KeyAttr    => undef,
					 KeepRoot   => 1,
	);

	return $xml;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Mdi::ExportFiles::ExportXml';

	my $ExportXml = ExportXml->new();
	$ExportXml->__LoadTemplate();

}

1;

