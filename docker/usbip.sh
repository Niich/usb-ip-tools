#!/bin/sh

### BEGIN INIT INFO
# Provides:       usbip
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the usbip web server
# Description:       starts usbip using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/usbipd
NAME=usbip
DESC=usbip

# Include usbip defaults if available
if [ -r /etc/default/usbip ]; then
        . /etc/default/usbip
fi

STOP_SCHEDULE="${STOP_SCHEDULE:-QUIT/5/TERM/5/KILL/5}"

test -x $DAEMON || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions

# Try to extract usbip pidfile
PID=$(cat /etc/usbip/usbip.conf | grep -Ev '^\s*#' | awk 'BEGIN { RS="[;{}]" } { if ($1 == "pid") print $2 }' | head -n1)
if [ -z "$PID" ]; then
        PID=/run/usbip.pid
fi

if [ -n "$ULIMIT" ]; then
        # Set ulimit if it is set in /etc/default/usbip
        ulimit $ULIMIT
fi

start_usbip() {
        # Start the daemon/service
        #
        # Returns:
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        start-stop-daemon --start --quiet --pidfile $PID --exec $DAEMON --test > /dev/null \
                || return 1
        start-stop-daemon --start --quiet --pidfile $PID --exec $DAEMON -- \
                $DAEMON_OPTS 2>/dev/null \
                || return 2
}

test_config() {
        # Test the usbip configuration
        $DAEMON -t $DAEMON_OPTS >/dev/null 2>&1
}

stop_usbip() {
        # Stops the daemon/service
        #
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        start-stop-daemon --stop --quiet --retry=$STOP_SCHEDULE --pidfile $PID --name $NAME
        RETVAL="$?"
        sleep 1
        return "$RETVAL"
}

reload_usbip() {
        # Function that sends a SIGHUP to the daemon/service
        start-stop-daemon --stop --signal HUP --quiet --pidfile $PID --name $NAME
        return 0
}

rotate_logs() {
        # Rotate log files
        start-stop-daemon --stop --signal USR1 --quiet --pidfile $PID --name $NAME
        return 0
}

upgrade_usbip() {
        # Online upgrade usbip executable
        # http://usbip.org/en/docs/control.html
        #
        # Return
        #   0 if usbip has been successfully upgraded
        #   1 if usbip is not running
        #   2 if the pid files were not created on time
        #   3 if the old master could not be killed
        if start-stop-daemon --stop --signal USR2 --quiet --pidfile $PID --name $NAME; then
                # Wait for both old and new master to write their pid file
                while [ ! -s "${PID}.oldbin" ] || [ ! -s "${PID}" ]; do
                        cnt=`expr $cnt + 1`
                        if [ $cnt -gt 10 ]; then
                                return 2
                        fi
                        sleep 1
                done
                # Everything is ready, gracefully stop the old master
                if start-stop-daemon --stop --signal QUIT --quiet --pidfile "${PID}.oldbin" --name $NAME; then
                        return 0
                else
                        return 3
                fi
        else
                return 1
        fi
}

case "$1" in
        start)
                log_daemon_msg "Starting $DESC" "$NAME"
                start_usbip
                case "$?" in
                        0|1) log_end_msg 0 ;;
                        2)   log_end_msg 1 ;;
                esac
                ;;
        stop)
                log_daemon_msg "Stopping $DESC" "$NAME"
                stop_usbip
                case "$?" in
                        0|1) log_end_msg 0 ;;
                        2)   log_end_msg 1 ;;
                esac
                ;;
        restart)
                log_daemon_msg "Restarting $DESC" "$NAME"

                # Check configuration before stopping usbip
                if ! test_config; then
                        log_end_msg 1 # Configuration error
                        exit $?
                fi

                stop_usbip
                case "$?" in
                        0|1)
                                start_usbip
                                case "$?" in
                                        0) log_end_msg 0 ;;
                                        1) log_end_msg 1 ;; # Old process is still running
                                        *) log_end_msg 1 ;; # Failed to start
                                esac
                                ;;
                        *)
                                # Failed to stop
                                log_end_msg 1
                                ;;
                esac
                ;;
        reload|force-reload)
                log_daemon_msg "Reloading $DESC configuration" "$NAME"

                # Check configuration before stopping usbip
                #
                # This is not entirely correct since the on-disk usbip binary
                # may differ from the in-memory one, but that's not common.
                # We prefer to check the configuration and return an error
                # to the administrator.
                if ! test_config; then
                        log_end_msg 1 # Configuration error
                        exit $?
                fi

                reload_usbip
                log_end_msg $?
                ;;
        configtest|testconfig)
                log_daemon_msg "Testing $DESC configuration"
                test_config
                log_end_msg $?
                ;;
        status)
                status_of_proc -p $PID "$DAEMON" "$NAME" && exit 0 || exit $?
                ;;
        upgrade)
                log_daemon_msg "Upgrading binary" "$NAME"
                upgrade_usbip
                log_end_msg $?
                ;;
        rotate)
                log_daemon_msg "Re-opening $DESC log files" "$NAME"
                rotate_logs
                log_end_msg $?
                ;;
        *)
                echo "Usage: $NAME {start|stop|restart|reload|force-reload|status|configtest|rotate|upgrade}" >&2
                exit 3
                ;;
esac