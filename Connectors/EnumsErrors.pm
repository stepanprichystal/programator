
package Connectors::EnumsErrors;

use constant {
    LOGDBERROR => 'Error when read/write to TPV log to database.',
    LOGDBCONN => 'Error when opening TPV log database.',
    TPVDBERROR => 'Error when read/write to TPV database.',
    TPVDBCONN => 'Error when opening TPV database.',
    HELIOSDBCONN => 'Error when opening Norris/Helios database.',
    HELIOSDBREADERROR => 'Error when READ to Noris/Helios database.',
    HELIOSDBWRITEERROR => 'Error when WRITE to Noris/Helios database.',
    
    
};


1;

