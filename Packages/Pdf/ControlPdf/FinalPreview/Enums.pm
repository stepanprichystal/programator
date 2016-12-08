
package Packages::Pdf::ControlPdf::FinalPreview::Enums;

use constant {
	Type_PCBMAT => "typePcbMat",
	Type_OUTERCU => "typeOuterCu",
	Type_MASK => "typeMask",
	Type_SILK => "typeSilk",
	Type_PLTDEPTHNC => "typePltDepthNc",
	Type_NPLTDEPTHNC => "typeNPltDepthNc",
	Type_THROUGHNC => "typeThroughNc"

};


	push(@{$self->{"layers"}}, LayerData->new(Enums->Type_PLTDEPTHNC));
	push(@{$self->{"layers"}}, LayerData->new(Enums->Type_NPLTDEPTNC));
	push(@{$self->{"layers"}}, LayerData->new(Enums->Type_THROUGHNC));



use constant {
	View_FROMTOP => "viewFromTop",
	View_FROMBOT => "viewFromBot"
	 

};
 

1;
