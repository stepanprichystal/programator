
package Packages::Stackup::Enums;
 

use constant {
    MaterialType_COPPER => "copper",
    MaterialType_PREPREG => "prepreg",
    MaterialType_CORE => "core",
	 
};


use constant {
    InStackMaterialType_ISOLATOR => "Isolator",
    InStackMaterialType_CORE => "Core",
    InStackMaterialType_FOIL => "Foil"
	 
};


use constant {
    SignalLayer_TOP => "top",
    SignalLayer_BOT => "bot"
};


use constant {
    CoreType_RIGID => "rigidCore",
    CoreType_FLEX => "flexCore"
};

1;

