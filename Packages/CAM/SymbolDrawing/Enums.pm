package Packages::CAM::SymbolDrawing::Enums;

use constant {
			   Primitive_LINE        => "primitiveLine",
			   Primitive_ARCSCE      => "primitiveArcSCE",         # arc defined bz start center end point
			   Primitive_SURFACEPOLY => "primitiveSurfacePoly",    # polygon surface
			   Primitive_PAD         => "primitivePad",
			   Primitive_TEXT        => "primitiveText"
};

use constant {
			   Polar_POSITIVE => "positive",
			   Polar_NEGATIVE => "negative"
};

1;
