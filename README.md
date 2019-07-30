#####  unattended-snapraid.sh

© COPYRIGHT 2019 by T.Magerl <dev@muab.org>

LICENCE: CC BY-NC-SA 4.0 (see licence-file included)

### Description:

* snapraid script for nightly schedules
* updating parity data (if needed) and verifying results afterwards.
* if neither is needed scan for bad blocks or verify x% of the parity (based on last verification)

#### Usage:

`unattended-snapraid.sh [configfile] [scheduled-check-amount]`

just pass snapraid-config file for the pool you want to handle.

optional: percent of archive to reverify if nothing else to do (default 3)

#### Changelog:

* 2019-07-30 NEW FEATURE: only keep 7 most recent log files
* 2019-07-30  ready for release
