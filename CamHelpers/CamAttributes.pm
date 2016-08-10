#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamAttributes;

#3th party library
use strict;
use warnings;

#loading of locale modules

#use aliased 'Enums::EnumsPaths';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamCopperArea';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
 #return all attributes of step in hash
sub GetJobAttr {

	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'job',
				  entity_path     => "$jobId",
				  data_type       => 'ATTR',
				  parameters      => "name+val"
	);

	my %info = ();
	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gATTRname} } ) ; $i++ ) {

		my $name = ${ $inCAM->{doinfo}{gATTRname} }[$i];
		my $val  = ${ $inCAM->{doinfo}{gATTRval} }[$i];
		$info{$name} = $val;
	}
	return %info;
}

#return attribute value by attribute name
sub GetJobAttrByName {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $attName = shift;

	my %allAttr = $self->GetJobAttr( $inCAM, $jobId );

	return $allAttr{$attName};
}

#return all attributes of step in hash
sub GetStepAttr {

	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'step',
				  entity_path     => "$jobId/$stepName",
				  data_type       => 'ATTR',
				  parameters      => "name+val"
	);

	my %info = ();
	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gATTRname} } ) ; $i++ ) {

		my $name = ${ $inCAM->{doinfo}{gATTRname} }[$i];
		my $val  = ${ $inCAM->{doinfo}{gATTRval} }[$i];
		$info{$name} = $val;
	}
	return %info;
}

#return all layer attributes
sub GetLayerAttr {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'layer',
				  entity_path     => "$jobId/$stepName/$layerName",
				  data_type       => 'ATTR',
				  parameters      => "name+val"
	);

	my %info = ();
	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gATTRname} } ) ; $i++ ) {

		my $name = ${ $inCAM->{doinfo}{gATTRname} }[$i];
		my $val  = ${ $inCAM->{doinfo}{gATTRval} }[$i];
		$info{$name} = $val;
	}
	return %info;
}

#set $value for attribute on specific layer
sub SetLayerAttribute {

	my $self      = shift;
	my $inCAM     = shift;
	my $attribute = shift;
	my $value     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	$inCAM->COM(
				 "set_attribute",
				 "type"      => "layer",
				 "job"       => $jobId,
				 "entity"    => "",
				 "attribute" => $attribute,
				 "value"     => $value,
				 "name1"     => $stepName,
				 "name2"     => $layerName,
				 "name3"     => "",
				 "units"     => "mm"
	);

}

1;
