## Vampire OS power management

The vpower command provides an auditable interface to system power operations. The status action reports uptime and command availability. Reboot, poweroff and halt require root plus an explicit --yes acknowledgement. The console launcher additionally requires typing REBOOT or POWER OFF. Pending filesystem writes are synchronized before dispatch. These controls do not replace a production init supervisor; shutdown ordering and unmount behavior still require runtime validation.
