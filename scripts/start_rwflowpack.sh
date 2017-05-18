#!/bin/sh

# Startup rwflowpack
# copied from /usr/local/share/silk/etc/init.d/rwflowpack

# Test rwflowpack with:
#   rwfilter --proto=0-255 --pass=stdout --type=all | rwcut

#######################################################################
# RCSIDENT("$SiLK: rwflowpack.init.d.in 02367a659674 2016-05-05 20:17:43Z mthomas $")
#######################################################################

# rwflowpack start/control script
#
# /etc/init.d/rwflowpack
# chkconfig: - 20 95
# description: Start rwflowpack program

MYNAME=rwflowpack

# Determine whether our name has an addendum
BASENAME='s:\(.*/\)*\([^/]*\)$:\2:'
SEDEXT1='s/\(.*\)\.init\.d$/\1/'
SEDEXT2='s/\(.*\)\.sh$/\1/'
SCRIPTNAME=`echo $0 | sed ${BASENAME} | sed ${SEDEXT1} | sed ${SEDEXT2}`
PRETEST="\\(${MYNAME}\\)\\(-.*\\)*\$"
SUFTEST="${MYNAME}\\(-.*\\)\$"
PREFIX=`expr "x${SCRIPTNAME}" : "x${PRETEST}"`
SUFFIX=`expr "x${SCRIPTNAME}" : "x${SUFTEST}"`

if [ "x$PREFIX" != "x$MYNAME" ] ; then
    SUFFIX=
fi

# SCRIPT_CONFIG_LOCATION is the directory where the ${MYNAME}.conf
# file is located.  It can be set via an environment variable.  If the
# envar is not set, then DEFAULT_SCRIPT_CONFIG_LOCATION is used.  If
# that is not set as well, the --sysconfdir value passed to configure
# is used, which defaults to ${prefix}/etc.
DEFAULT_SCRIPT_CONFIG_LOCATION=
if [ "x$SCRIPT_CONFIG_LOCATION" = "x" ] ; then
    if [ "x$DEFAULT_SCRIPT_CONFIG_LOCATION" = "x" ] ; then
        SCRIPT_CONFIG_LOCATION="/usr/local/etc"
    else
        SCRIPT_CONFIG_LOCATION="$DEFAULT_SCRIPT_CONFIG_LOCATION"
    fi
fi
SCRIPT_CONFIG=${SCRIPT_CONFIG_LOCATION}/${MYNAME}${SUFFIX}.conf

#######################################################################

if [ ! -f "${SCRIPT_CONFIG}" ] ; then
    echo "$0: ${SCRIPT_CONFIG} does not exist."
    exit 0
fi

. "${SCRIPT_CONFIG}"

if [ "x$ENABLED" = "x" ] ; then
    exit 0
fi


#######################################################################
# SHELL FUNCTIONS

# check_empty VARNAME VALUE
#
#    Verifies that VALUE has a value.  If it doesn't, a message is
#    printed that the VARNAME variable is unset and script exits.
check_empty()
{
    if [ "x$2" = "x" ] ; then
        echo "$0: the \${$1} variable has not been set."
        exit 1
    fi
}

# check_dir VARNAME DIR
#
#    Verifies that VARNAME is set.  Next, verifies that the directory
#    DIR exists.  If not and if $CREATE_DIRECTORIES is set, the
#    directory is created.  Otherwise, an error is printed and the
#    script exits.
check_dir()
{
    check_empty "$1" "$2"
    if [ ! -d "$2" ] ; then
        if [ "${CREATE_DIRECTORIES}" = "yes" ] ; then
            mkdir -p "$2" || { echo "$0: Could not create $2" ; exit 1 ; }
            chown -h "${USER}" "$2" || { echo "$0: Could not chown $2 to ${USER}"; exit 1 ; }
        else
            echo "$0: the $2 directory does not exist."
            exit 1
        fi
    else
        chown -h "${USER}" "$2" || { echo "$0: Could not chown $2 to ${USER}"; exit 1 ; }
    fi
}

#######################################################################

# for backwards compatibility
if [ "x${BIN_DIR}" = "x" ] ; then
    #echo "Warning: PACKER_BIN deprecated in ${SCRIPT_CONFIG}.  Use BIN_DIR instead" 1>&2
    BIN_DIR="${PACKER_BIN}"
fi


RETVAL=0

PROG=rwflowpack
PROG_PATH="${BIN_DIR}/${PROG}"
PIDFILE="${PID_DIR}/${PROG}${SUFFIX}.pid"
LOG_BASENAME="${PROG}${SUFFIX}"
PROG_OPTIONS=""

if [ ! -x "${PROG_PATH}" ] ; then
    echo "$0: could not find an executable ${PROG_PATH}."
    exit 1
fi


check_empty "INPUT_MODE" "${INPUT_MODE}"
case "${INPUT_MODE}" in
    stream)
        check_empty "SENSOR_CONFIG" "${SENSOR_CONFIG}"
        PROG_OPTIONS="${PROG_OPTIONS} --sensor-configuration='${SENSOR_CONFIG}'"
        ;;
    fcfiles)
        check_empty "SENSOR_CONFIG" "${SENSOR_CONFIG}"
        PROG_OPTIONS="${PROG_OPTIONS} --input-mode=fcfiles"
        PROG_OPTIONS="${PROG_OPTIONS} --sensor-configuration='${SENSOR_CONFIG}'"
        ;;
    respool)
        PROG_OPTIONS="${PROG_OPTIONS} --input-mode=respool"
        ;;
    *)
        echo "$0: Unexpected INPUT_MODE ${INPUT_MODE}."
        echo "Set to \"stream\", \"fcfiles\", or \"respool\"."
        exit 1
        ;;
esac


if [ "x${COMPRESSION_TYPE}" != "x" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --compression-method=${COMPRESSION_TYPE}"
fi
if [ "x${FILE_LOCKING}" = "x0" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --no-file-locking"
fi
if [ "x${PACK_INTERFACES}" = "x1" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --pack-interfaces"
fi
if [ "x${FLUSH_TIMEOUT}" != "x" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --flush-timeout=${FLUSH_TIMEOUT}"
fi
if [ "x${FILE_CACHE_SIZE}" != "x" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --file-cache-size=${FILE_CACHE_SIZE}"
fi
if [ "x${POLLING_INTERVAL}" != "x" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --polling-interval=${POLLING_INTERVAL}"
fi
if [ "x${SITE_CONFIG}" != "x" ] ; then
    PROG_OPTIONS="${PROG_OPTIONS} --site-config-file='${SITE_CONFIG}'"
fi

if [ "x${PACKING_LOGIC}" != "x" ] ; then
    case "${INPUT_MODE}" in
        respool)
            ;;
        *)
            PROG_OPTIONS="${PROG_OPTIONS} --packing-logic='${PACKING_LOGIC}'"
            ;;
    esac
fi

if [ "x${ARCHIVE_DIR}" != "x" ] ; then
    check_dir "ARCHIVE_DIR" "${ARCHIVE_DIR}"
    PROG_OPTIONS="${PROG_OPTIONS} --archive-directory='${ARCHIVE_DIR}'"
    if [ "x${FLAT_ARCHIVE}" = "x1" ] ; then
        PROG_OPTIONS="${PROG_OPTIONS} --flat-archive"
    fi
fi
if [ "x${ERROR_DIR}" != "x" ] ; then
    check_dir "ERROR_DIR" "${ERROR_DIR}"
    PROG_OPTIONS="${PROG_OPTIONS} --error-directory='${ERROR_DIR}'"
fi

case "${INPUT_MODE}" in
    fcfiles|respool)
        check_dir "INCOMING_DIR" "${INCOMING_DIR}"
        PROG_OPTIONS="${PROG_OPTIONS} --incoming-directory='${INCOMING_DIR}'"
        ;;
    *)
        ;;
esac


check_empty "OUTPUT_MODE" "${OUTPUT_MODE}"
case "${OUTPUT_MODE}" in
    local-storage|local)
        check_dir "DATA_ROOTDIR" "${DATA_ROOTDIR}"
        PROG_OPTIONS="${PROG_OPTIONS} --output-mode=local-storage --root-directory='${DATA_ROOTDIR}'"
        ;;
    incremental-files)
        check_dir "INCREMENTAL_DIR" "${INCREMENTAL_DIR}"
        PROG_OPTIONS="${PROG_OPTIONS} --output-mode=incremental-files --incremental-directory='${INCREMENTAL_DIR}'"
        ;;
    remote|sending)
        check_dir "SENDER_DIR" "${SENDER_DIR}"
        check_dir "INCREMENTAL_DIR" "${INCREMENTAL_DIR}"
        PROG_OPTIONS="${PROG_OPTIONS} --output-mode=sending --sender-directory='${SENDER_DIR}' --incremental-directory='${INCREMENTAL_DIR}'"
        ;;
    *)
        echo "$0: Unexpected OUTPUT_MODE ${OUTPUT_MODE}."
        echo "Set to \"local-storage\" or \"incremental-files\"."
        exit 1
        ;;
esac

# Be certain EXTRA_ENVVAR ends with a space when it is non-empty
if [ "x${EXTRA_ENVVAR}" != "x" ]; then
    if [ "x${SILK_IPFIX_PRINT_TEMPLATES}" != "x" ]; then
        EXTRA_ENVVAR="${EXTRA_ENVVAR} SILK_IPFIX_PRINT_TEMPLATES=${SILK_IPFIX_PRINT_TEMPLATES} "
    else
        EXTRA_ENVVAR="${EXTRA_ENVVAR} "
    fi
elif [ "x${SILK_IPFIX_PRINT_TEMPLATES}" != "x" ]; then
    EXTRA_ENVVAR="SILK_IPFIX_PRINT_TEMPLATES=${SILK_IPFIX_PRINT_TEMPLATES} "
fi



#######################################################################

check_dir   "PID_DIR"  "${PID_DIR}"
PROG_OPTIONS="${PROG_OPTIONS} --pidfile='${PIDFILE}' --log-level=${LOG_LEVEL}"

case "${LOG_TYPE}" in
    syslog)
        PROG_OPTIONS="${PROG_OPTIONS} --log-destination=syslog"
        ;;
    legacy)
        check_dir "LOG_DIR" "${LOG_DIR}"
        PROG_OPTIONS="${PROG_OPTIONS} --log-directory='${LOG_DIR}' --log-basename='${LOG_BASENAME}'"
        ;;
    *)
        echo "$0: Unexpected LOG_TYPE ${LOG_TYPE}."
        echo "Set to \"legacy\" or \"syslog\"."
        exit 1
        ;;
esac


#######################################################################

# Check if $pid is running
checkpid() {
    kill -0 $1 >/dev/null 2>&1 && return 0
    return 1
}


# Get the process id from the PIDFILE
getPid() {
    RETVAL=1
    if [ -f $PIDFILE ] ; then
        RETVAL=2
        read pid < ${PIDFILE}
        if [ "X$pid" != "X" ] ; then
            RETVAL=3
            # Found a pid
            if checkpid $pid ; then
                echo $pid
                RETVAL=0
            fi
        fi
    fi
    echo ""
    return $RETVAL
}


status() {
    if [ $# -gt 0 ] ; then
        doEcho=0
    else
        doEcho=1
    fi

    # first check if the process is running
    pid=`getPid`
    RETVAL=$?

    if [ $doEcho -eq 1 ] ; then
        case "$RETVAL" in
          0)
            echo "${PROG} is running with pid $pid"
            ;;
          1)
            echo "${PROG} is stopped"
            ;;
          *)
            echo "${PROG} is dead but pid file exists"
            ;;
        esac
    fi
    return $RETVAL
}


start() {
    (status 'silent')
    pStat=$?
    if [ $pStat -eq 0 ] ; then
        status
        return 0
    fi

    /bin/echo -n "Starting ${PROG}: "
    /bin/rm -f ${PIDFILE} 2> /dev/null

    if [ X`whoami` = "X${USER}" ] ; then
        eval "${EXTRA_ENVVAR}${PROG_PATH} ${PROG_OPTIONS} ${EXTRA_OPTIONS} &"
    else
        su - ${USER} -c "${EXTRA_ENVVAR}${PROG_PATH} ${PROG_OPTIONS} ${EXTRA_OPTIONS} &"
    fi
    RETVAL=$?
    if [ "$RETVAL" -ne "0" ] ; then
        echo "[Failed]"
    else
        sleep 1
        PID=`getPid`
        if [ "x$PID" = "x" ] ; then
            echo "[Failed]"
            RETVAL=1
        else
            echo '[OK]'
        fi
    fi
    return $RETVAL
}


stop() {
    Pid=`getPid`
    if [ "X${Pid}" = "X" ] ; then
        echo "${PROG} not running"
        return 1
    fi
    /bin/echo -n "Stopping ${PROG}: "
    /bin/kill -s INT $Pid
    for s in 2 3 4 6 7; do
        sleep $s
        if checkpid $Pid ; then
            :
        else
            break;
        fi
    done
    if checkpid $Pid ; then
        /bin/kill -s KILL $Pid
        sleep 1
    fi
    (checkpid $Pid)
    RETVAL=$?
    [ "$RETVAL" -eq "1" ] && echo '[OK]' || echo '[FAILED]'
    /bin/rm -f ${PIDFILE} 2> /dev/null
    return $RETVAL
}


restart(){
    (stop)
    (start)
}


case "$1" in
  start)
    (start)
    RETVAL=$?
    ;;

  stop)
    (stop)
    RETVAL=$?
    ;;

  restart)
    (restart)
    RETVAL=$?
    ;;

  status)
    (status)
    RETVAL=$?
    ;;

  *)
    echo $"Usage: $0 {start|stop|status|restart}"
    RETVAL=1
    ;;
esac

exit $RETVAL


#######################################################################
# @OPENSOURCE_LICENSE_START@
#
# Use of the SILK system and related source code is subject to the terms
# of the following licenses:
#
# GNU General Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
#
# NO WARRANTY
#
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT,
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES.
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE
# DELIVERABLES UNDER THIS LICENSE.
#
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie
# Mellon University, its trustees, officers, employees, and agents from
# all claims or demands made against them (and any related losses,
# expenses, or attorney's fees) arising out of, or relating to Licensee's
# and/or its sub licensees' negligent use or willful misuse of or
# negligent conduct or willful misconduct regarding the Software,
# facilities, or other rights or assistance granted by Carnegie Mellon
# University under this License, including, but not limited to, any
# claims of product liability, personal injury, death, damage to
# property, or violation of any laws or regulations.
#
# Carnegie Mellon University Software Engineering Institute authored
# documents are sponsored by the U.S. Department of Defense under
# Contract FA8702-15-D-0002. Carnegie Mellon University retains
# copyrights in all material produced under this contract. The U.S.
# Government retains a non-exclusive, royalty-free license to publish or
# reproduce these documents, or allow others to do so, for U.S.
# Government purposes only pursuant to the copyright license under the
# contract clause at 252.227.7013.
#
# @OPENSOURCE_LICENSE_END@
#######################################################################


# sudo /usr/local/sbin/rwflowpack \
#   --compression-method=best \
#   --sensor-configuration=/data/sensors.conf \
#   --site-config-file=/data/silk.conf \
#   --output-mode=local-storage \
#   --root-directory=/data/ \
#   --pidfile=/var/log/rwflowpack.pid \
#   --log-level=info \
#   --log-directory=/var/log \
#   --log-basename=rwflowpack &

