
package Packages::Gerbers::Mditt::ExportFiles::Enums;

use constant {
	Type_SIGNAL => "typeSignal",
	Type_MASK   => "typeMask",
	Type_PLUG   => "typePlug",
	Type_GOLD   => "typeGold"

};

use constant {
			   Fiducials_CUSQUERE          => "CuSquare",             # camera focus on copper squere
			   Fiducials_OLECHOLE2V        => "OlecHole2V",           # camera focus on 3.0mm hole (OLEC) at 2vv pcb
			   Fiducials_OLECHOLEINNERVV   => "OlecHoleInnerVV",      # camera focus on 3.0mm hole (OLEC) at core
			   Fiducials_OLECHOLEINNERVVSL => "OlecHoleInnerVVSL",    # camera focus on 3.0mm hole (OLEC) at core
			   Fiducials_OLECHOLEOUTERVV   => "OlecHoleOuterVV",      # camera focus on 3.0mm hole (OLEC) at final pcb after routing frame
};

1;

