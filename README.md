#  unattended-snapraid.sh 
© COPYRIGHT 2019 by T.Magerl <dev@muab.org>

LICENCE: CC BY-NC-SA 4.0 (see licence-file included)

# Description:

snapraid script for nightly schedules

updating parity data (if needed) and verifying results afterwards.

if neither is needed scan for bad blocks or verify x% of the parity (based on last verification)


# Usage:

just pass snapraid-config file for the pool you want to handle:

unattended-snapraid.sh /foo/bar.conf
