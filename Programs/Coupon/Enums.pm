
package Programs::Coupon::Enums;



# coupon pad types
use constant {
			   Pad_GND   => "gndPad",
			   Pad_TRACK => "trackPad"
};

# layer types in coupon constrant (internal types for generating misrotrip combination)
# Type unused:
# - layers which order is highest or lowest more than 2 positions from track layer and track-extra layer(this layer has no impact to mesurement)
use constant {
	Layer_TYPEGND        => "layerGnd",           # layer which contain GND
	Layer_TYPETRACK      => "layerTrack",         # measurement layer
	Layer_TYPETRACKEXTRA => "layerTrackExtra",    # measurement layer
	Layer_TYPEAFFECT     => "layerAffect",        # another trace layer, empty GND
	Layer_TYPENOAFFECT   => "layerNoAffect"

};

# Route/miscrostrip line types
use constant {
			   Route_ABOVE    => "routeAbove",
			   Route_BELOW    => "routeBelow",
			   Route_STREIGHT => "routeStraight"
};

1;
