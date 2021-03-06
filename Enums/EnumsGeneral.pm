
package Enums::EnumsGeneral;

use constant {
			   PcbType_NOCOPPER   => "noCopper",
			   PcbType_1V         => "oneLayer",
			   PcbType_2V         => "twoLayer",
			   PcbType_MULTI      => "multiLayer",
			   PcbType_1VFLEX     => "flexType_oneLayer",
			   PcbType_2VFLEX     => "flexType_twoLayer",
			   PcbType_MULTIFLEX  => "flexType_multilayer",
			   PcbType_RIGIDFLEXO => "flexType_rigidFlexO",
			   PcbType_RIGIDFLEXI => "flexType_rigidFlexI",
			   PcbType_STENCIL    => "stencil"
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

# Define type of NC layers, as we defined for opur purposes
use constant {
	LAYERTYPE_plt_nDrill         => "plt_nDrill",            # normall through holes plated
	LAYERTYPE_plt_bDrillTop      => "plt_bDrillTop",         # blind holes top
	LAYERTYPE_plt_bDrillBot      => "plt_bDrillBot",         # blind holes bot
	LAYERTYPE_plt_nFillDrill     => "plt_nFillDrill",        # filled through holes plated
	LAYERTYPE_plt_bFillDrillTop  => "plt_bFillDrillTop",     # blind filled holes top
	LAYERTYPE_plt_bFillDrillBot  => "plt_bFillDrillBot",     # blind filled holes bot
	LAYERTYPE_plt_cDrill         => "plt_cDrill",            # core plated
	LAYERTYPE_plt_cFillDrill     => "plt_cFillDrill",        # core filled plated
	LAYERTYPE_plt_nMill          => "plt_nMill",             # normall mill slits
	LAYERTYPE_plt_bMillTop       => "plt_bMillTop",          # z-axis mill slits top
	LAYERTYPE_plt_bMillBot       => "plt_bMillBot",          # z-axis mill slits bot
	LAYERTYPE_plt_fDrill         => "plt_fDrill",            # frame drilling "v"
	LAYERTYPE_plt_fcDrill        => "plt_fcDrill",           # core frame drilling "v1"
	LAYERTYPE_plt_fcPressDrill   => "plt_fcPressDrill",      # core frame drilling - press holes "v1p1; v2p2; ..."
	LAYERTYPE_nplt_nDrill        => "nplt_nDril",            # normall drill without slots from TOP
	LAYERTYPE_nplt_nDrillBot     => "nplt_nDrilBot",         # normall drill without slots from BOT
	LAYERTYPE_nplt_nMill         => "nplt_nMill",            # normall mill slots
	LAYERTYPE_nplt_nMillBot         => "nplt_nMillBot",            # normall mill slots
	LAYERTYPE_nplt_bMillTop      => "nplt_bMillTop",         # z-axis mill top
	LAYERTYPE_nplt_bMillBot      => "nplt_bMillBot",         # z-axis mill bot
	LAYERTYPE_nplt_rsMill        => "nplt_rsMill",           # rs mill before plating
	LAYERTYPE_nplt_frMill        => "nplt_frMill",           # milling frame "fr"
	LAYERTYPE_nplt_score         => "nplt_score",            # scoring
	LAYERTYPE_nplt_cbMillTop     => "nplt_cbMillTop",        # z-axis mill top of core
	LAYERTYPE_nplt_cbMillBot     => "nplt_cbMillBot",        # z-axis mill bot of core
	LAYERTYPE_nplt_kMill         => "nplt_kmill",            # milling of gold connector
	LAYERTYPE_nplt_lcMill        => "nplt_lcMill",           # milling of template for c side (snimaci lak)
	LAYERTYPE_nplt_lsMill        => "nplt_lsMill",           # milling of template for s side (snimaci lak)
	LAYERTYPE_nplt_fMillSpec     => "nplt_fMillSpec",        # special milling (ramecek, dovrtani apod)
	LAYERTYPE_nplt_cvrlycMill    => "nplt_cvrlycMill",       # top coverlay mill
	LAYERTYPE_nplt_cvrlysMill    => "nplt_cvrlysMill",       # bot coverlay mill
	LAYERTYPE_nplt_prepregMill   => "nplt_prepregMill",      # prepreg mill
	LAYERTYPE_nplt_stiffcMill    => "nplt_stiffcMill",       # milling for stiffener from side c
	LAYERTYPE_nplt_stiffsMill    => "nplt_stiffsMill",       # milling for stiffener from side s
	LAYERTYPE_nplt_stiffcAdhMill => "nplt_stiffcAdhMill",    # depth milling of top stiffener adhesive from top
	LAYERTYPE_nplt_stiffsAdhMill => "nplt_stiffsAdhMill",    # depth milling of bot stiffener adhesive from top
	LAYERTYPE_nplt_bstiffcMill   => "nplt_bstiffcMill",      # depth milling of stiffener from side c
	LAYERTYPE_nplt_bstiffsMill   => "nplt_bstiffsMill",      # depth milling for stiffener from side s
	LAYERTYPE_nplt_soldcMill     => "nplt_soldfcMill",       # milling of template for soldering coverlay from side c
	LAYERTYPE_nplt_soldsMill     => "nplt_soldfsMill",       # milling of template for soldering coverlay from side s
	LAYERTYPE_nplt_tapecMill     => "nplt_tapecMill",        # milling of doublesided tape sticked from top
	LAYERTYPE_nplt_tapesMill     => "nplt_tapesMill",        # milling of doublesided tape sticked from bot
	LAYERTYPE_nplt_tapebrMill    => "nplt_tapebrMill",       # milling of doublesided tape bridges after tape is pressed

};

use constant {
			   Etching_PATTERN => 'pattern',
			   Etching_TENTING => 'tenting',
			   Etching_ONLY    => 'etching',
};

use constant {
			   Technology_GALVANICS   => 'galvanics',
			   Technology_RESIST      => 'resist',
			   Technology_OTHER       => 'other',
			   Technology_SCREENPRINT => 'screenprint'
};

use constant {
			   DB_PRODUCTION => 'incam',
			   DB_TEST       => 'db1'
};

# names of special coupon steps
use constant {
	Coupon_IMPEDANCE => 'coupon_impedance',    # coupon for impedance measurement
	Coupon_DRILL     => 'coupon_drill',        # coupon for drill hole measrument
	Coupon_IPC3MAIN  => 'coupon_ipc3main',     # coupon for IPC class 3 - contain holes + lines
	Coupon_IPC3DRILL => 'coupon_drill',        # coupon for IPC class 3 - through hole measurement (Warning - same step name as coupon_drill)
	Coupon_ZAXIS     => 'coupon_zaxis_',       # coupon for zaxis rout testing. Real coupon has always number behind name.

};

1;

