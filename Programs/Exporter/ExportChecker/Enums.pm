
package Programs::Exporter::ExportChecker::Enums;

use constant {
			   PopupResult_CHANGE      => "changeSettings",
			   PopupResult_STOP        => "stopChecking",
			   PopupResult_EXPORTFORCE => "exportForce",
			   PopupResult_SUCCES      => "checkingSucces"
};



use constant {
			   GroupState_ACTIVEON  => "groupActiveOn",
			   GroupState_ACTIVEOFF => "groupActiveOff",
			   GroupState_DISABLE   => "groupDisable"
};


use constant {
			   ExportMode_SYNC  => "synchronousExport",
			   ExportMode_ASYNC  => "asynchronousExport"
};


#
#package EnumsGeneral::UserName;
#
#use constant {
#    SPR => mku,
#	MKU => 'Warning',
#	RVI=>'Question',
#	RC => 'Information'
#};

1;

