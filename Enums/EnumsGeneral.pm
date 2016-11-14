
package Enums::EnumsGeneral;

use constant {
			   PcbTyp_NOCOPPER   => "noCopper",
			   PcbTyp_ONELAYER   => "oneLayer",
			   PcbTyp_TWOLAYER   => "twoLayer",
			   PcbTyp_MULTILAYER => "multiLayer",
};

use constant {
			   MessageType_ERROR       => 'Error',
			   MessageType_SYSTEMERROR => 'System error',
			   MessageType_WARNING     => 'Warning',
			   MessageType_QUESTION    => 'Question',
			   MessageType_INFORMATION => 'Information'
};

use constant {
	ResultType_OK   => 'succes',
	ResultType_FAIL => 'failure',
	ResultType_NA   => 'na'

};

use constant {
			   GuideAction_SHOW    => "show",
			   GuideAction_RUN     => "run",
			   GuideAction_RUNFROM => "runFrom",
};

use constant {
			   Layers_TOP => "c",
			   Layers_BOT => "s",
			   Layers_V2  => "v2",
			   Layers_V3  => "v3",
			   Layers_V4  => "v4",
			   Layers_V5  => "v5",
			   Layers_V6  => "v6",
			   Layers_V7  => "v7",
			   Layers_V8  => "v8",
			   Layers_V9  => "v9",
			   Layers_V10 => "v10",
			   Layers_V11 => "v11",
			   Layers_V12 => "v12",
			   Layers_V13 => "v13",
			   Layers_V14 => "v14",
			   Layers_V15 => "v15",
			   Layers_V16 => "v16"
};

#A few material types used in Hellios IS
use constant {
			   Mat_FR4   => 'FR4',
			   Mat_IS410 => 'IS410',
			   Mat_Al    => 'Al',
			   Mat_G200  => 'G200'
};

# Define type of NC layers, as we defined for opur purposes
use constant {
	LAYERTYPE_plt_nDrill     => "plt_nDrill",        # normall through holes plated
	LAYERTYPE_plt_bDrillTop  => "plt_bDrillTop",     # blind holes top
	LAYERTYPE_plt_bDrillBot  => "plt_bDrillBot",     # blind holes bot
	LAYERTYPE_plt_cDrill     => "plt_cDrill",        # core plated
	LAYERTYPE_plt_nMill      => "plt_nMill",         # normall mill slits
	LAYERTYPE_plt_bMillTop   => "plt_bMillTop",      # z-axis mill slits top
	LAYERTYPE_plt_bMillBot   => "plt_bMillBot",      # z-axis mill slits bot
	LAYERTYPE_plt_dcDrill    => "plt_dcDrill",       # drill crosses
	LAYERTYPE_plt_fDrill     => "plt_fDrill",        # frame drilling "v1"
	LAYERTYPE_nplt_nMill     => "nplt_nMill",        # normall mill slits
	LAYERTYPE_nplt_bMillTop  => "nplt_bMillTop",     # z-axis mill top
	LAYERTYPE_nplt_bMillBot  => "nplt_bMillBot",     # z-axis mill bot
	LAYERTYPE_nplt_rsMill    => "nplt_rsMill",       # rs mill before plating
	LAYERTYPE_nplt_frMill    => "nplt_frMill",       # milling frame "fr"
	LAYERTYPE_nplt_score     => "nplt_score",        # scoring
	LAYERTYPE_nplt_jbMillTop => "nplt_jbMillTop",    #z-axis mill top of core
	LAYERTYPE_nplt_jbMillBot => "nplt_jbMillBot",    #z-axis mill bot of core
	LAYERTYPE_nplt_kMill     => "nplt_kmill",        #milling of gold connector
	LAYERTYPE_nplt_fMillSpec => "nplt_fMillSpec",        #special milling (ramecek, dovrtani apod)

};

use constant {
			   Etching_PATTERN => 'pattern',
			   Etching_TENTING	 => 'tenting',
			   Etching_NO	 => 'noEtching',
};


use constant {
			   DB_PRODUCTION => 'incam',
			   DB_TEST       => 'db1'
};

1;

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

