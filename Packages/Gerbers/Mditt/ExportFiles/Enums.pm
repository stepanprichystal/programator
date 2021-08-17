
package Packages::Gerbers::Mditt::ExportFiles::Enums;

use constant {
	Type_SIGNAL => "typeSignal",
	Type_MASK   => "typeMask",
	Type_PLUG   => "typePlug",
	Type_GOLD   => "typeGold"

};

use constant {
	Fiducials_CUSQUERE          => "fiduc_CuSquere",                 # camera focus on copper squere
	Fiducials_OLECHOLE2V        => "Fiducials_OLECHOLE2V",           # camera focus on 3.0mm hole (OLEC) at 2vv pcb
	Fiducials_OLECHOLEINNERVV   => "Fiducials_OLECHOLEINNERVV",      # camera focus on 3.0mm hole (OLEC) at core
	Fiducials_OLECHOLEINNERVVSL => "Fiducials_OLECHOLEINNERVVSL",    # camera focus on 3.0mm hole (OLEC) at core
	Fiducials_OLECHOLEOUTERVV => "Fiducials_OLECHOLEOUTERVV",    # camera focus on 3.0mm hole (OLEC) at final pcb after routing frame
};

1;

