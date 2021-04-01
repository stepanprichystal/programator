#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamAttributes;

#3th party library
use strict;
use warnings;

#loading of locale modules
 
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

#set job attribute
sub SetJobAttribute {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $attName = shift;
	my $value   = shift;

	$inCAM->COM(
				 "set_attribute",
				 "type"      => "job",
				 "job"       => $jobId,
				 "entity"    => "",
				 "attribute" => $attName,
				 "value"     => $value,
				 "name1"     => "",
				 "name2"     => "",
				 "name3"     => "",
				 "units"     => "mm"
	);
}


#set step attribute
sub SetStepAttribute {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step   = shift;
	my $attName = shift;
	my $value   = shift;

	$inCAM->COM(
				 "set_attribute",
				 "type"      => "step",
				 "job"       => $jobId,
				 "entity"    => "",
				 "attribute" => $attName,
				 "value"     => $value,
				 "name1"     => $step,
				 "name2"     => "",
				 "name3"     => "",
				 "units"     => "mm"
	);
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


#return value of step attribute by name
sub GetStepAttrByName {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $attName = shift;

	my %att = $self->GetStepAttr($inCAM,$jobId, $stepName);
 	
 	return $att{$attName};
 	
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

# Set atribute on selected features on affected layers
# Only attributes type: text
# Note: error in name SetFEATUESAttribute
sub SetFeatuesAttribute {

	my $self      = shift;
	my $inCAM     = shift;
	my $attribute = shift;
	my $value     = shift;

	$inCAM->COM( "cur_atr_reset", );
	$inCAM->COM( "cur_atr_set", "attribute" => $attribute, "text" => $value );
	$inCAM->COM( "sel_change_atr", "mode" => "add" );

}

# Set atribute on selected features on affected layers
# Possible for all types of attributes
sub SetFeaturesAttribute {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $attName = shift;
	my $attVal  = shift;

	# decide, which type is attribute
	my %attrInfo = $self->GetAttrParamsByName( $inCAM, $jobId, $attName );

	my $int    = 0;
	my $float  = 0;
	my $option = "";
	my $text   = "";

	if ( $attrInfo{"gATRtype"} eq "int" ) {
		$int = $attVal;
	}
	elsif ( $attrInfo{"gATRtype"} eq "float" ) {
		$float = $attVal;
	}
	elsif ( $attrInfo{"gATRtype"} eq "option" ) {
		$option = $attVal;
	}
	elsif ( $attrInfo{"gATRtype"} eq "text" ) {
		$text = $attVal;
	}

	$inCAM->COM( "cur_atr_reset", );
	$inCAM->COM(
				 'cur_atr_set',
				 "attribute" => $attName,
				 "int"       => $int,
				 "float"     => $float,
				 "option"    => $option,
				 "text"      => $text
	);

	$inCAM->COM( "sel_change_atr", "mode" => "add" );
}

# Delete atribute from selected features on affected layers
sub DelFeatuesAttribute {

	my $self      = shift;
	my $inCAM     = shift;
	my $attribute = shift;
	my $value     = shift;

	$inCAM->COM( "sel_delete_atr", "mode" => "list", "attributes" => $attribute, "attr_vals" => $value );
}

# Delete all atributes from selected features on affected layers
sub DelAllFeatuesAttribute {
	my $self      = shift;
	my $inCAM     = shift;

	$inCAM->COM( "sel_delete_atr", "mode" => "all" );
}

 


# Return array of all atributes in job (feature attributes)
sub GetAttrParams {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @arr = ();

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'attributes',
				  entity_path     => "$jobId",
				  data_type       => 'ATR',
				  parameters      => "name+type"
	);

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gATRname} } ) ; $i++ ) {
		my %info = ();
		$info{"gATRname"} = ${ $inCAM->{doinfo}{gATRname} }[$i];
		$info{"gATRtype"} = ${ $inCAM->{doinfo}{gATRtype} }[$i];
		push( @arr, \%info );

	}
	return @arr;
}

# Return attribute information by attribute name
sub GetAttrParamsByName {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $attrName = shift;

	my @attr = $self->GetAttrParams( $inCAM, $jobId );

	my $att = ( grep { $_->{"gATRname"} eq $attrName } @attr )[0];

	return %{$att};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamAttributes';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName = "d272564";

	  
	 

	print 1;

}

1;


