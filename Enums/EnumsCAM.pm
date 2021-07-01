
# Contain enums, which are related to CAM sw, like value of attributes..

package Enums::EnumsCAM;

# possible values of layer attribute: spec_layer_fill
use constant {
	AttSpecLayerFill_NONE        => "none",
	AttSpecLayerFill_EMPTY       => "empty",
	AttSpecLayerFill_CIRCLE80PCT => "circle_80pct",
	AttSpecLayerFill_SOLID100PCT => "solid_100pct",

};

1;
