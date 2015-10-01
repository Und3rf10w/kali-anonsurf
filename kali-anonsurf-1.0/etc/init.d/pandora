#!/bin/bash
set -e
### BEGIN INIT INFO
# Provides:          pandora-bootparam
# Required-Start:
# Required-Stop:        umountroot
# Should-Start:
# Should-Stop:          halt reboot
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description: Open Parrot Pandora's box and clean the RAM.
### END INIT INFO

#
# Lorenzo "EclipseSpark" Faletra <eclipse@frozenbox.org>
#         Parrot Security OS www.parrotsec.org
#                      GNU/GPL v3
#

function bomb {
	echo "starting Parrot Pandora's box "
	sleep 5
    echo "Pandora is dropping caches"
    echo 1024 > /proc/sys/vm/min_free_kbytes
    echo 3  > /proc/sys/vm/drop_caches
    echo 1  > /proc/sys/vm/oom_kill_allocating_task
    echo 1  > /proc/sys/vm/overcommit_memory
    echo 0  > /proc/sys/vm/oom_dump_tasks
    echo "Pandora is bombing RAM"
    sdmem -fllv
    echo " - RAM bombed"
    echo "closing Parrot Pandora's box"
}




case "$1" in
        start)
                echo "Argument '$1' is not supported, use bomb instead"
        ;;
        restart|reload|force-reload)
                echo "Error: argument '$1' is not supported, use bomb instead"
        ;;
        stop)
#        	if ! grep pandora /proc/cmdline 1> /dev/null
#        	then echo "Not opening Pandora-bootparam, not enabled from kernel line"
#        	else
#              bomb
#            fi
              bomb
        ;;
        bomb)
              bomb
        ;;
        *)
              echo "USAGE: pandora bomb"
esac
