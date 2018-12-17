#!/usr/bin/env bash
#   Use this script to test if a given TCP host/port are available
echo "start to exe"

WAITFORIT_cmdname=${0##*/}

echoerr() { if [[ $WAITFORIT_QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $WAITFORIT_cmdname host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    if [[ $WAITFORIT_TIMEOUT -gt 0 ]]; then
        echoerr "$WAITFORIT_cmdname: waiting $WAITFORIT_TIMEOUT seconds for ${hostports[*]}"
    else
        echoerr "$WAITFORIT_cmdname: waiting for ${hostports[*]} without a timeout"
    fi
   
    for hostAndport in ${hostports[*]}
    do
       hostport=(${hostAndport//:/ })
       WAITFORIT_start_ts=$(date +%s)
       while :
       do
         if [[ $WAITFORIT_ISBUSY -eq 1 ]]; then
            nc -z ${hostport[0]} ${hostport[1]}
            WAITFORIT_result=$?
         else
	   (echo > /dev/tcp/${hostport[0]}/${hostport[1]}) >/dev/null 2>&1
	    WAITFORIT_result=$?
         fi
	 if [[ $WAITFORIT_result -eq 0 ]]; then
	    WAITFORIT_end_ts=$(date +%s)
	    echoerr "$WAITFORIT_cmdname: ${hostport[0]}:${hostport[1]} is available after $((WAITFORIT_end_ts - WAITFORIT_start_ts)) seconds"
	    break
         fi
	 sleep 1
       done
    done
    return $WAITFORIT_result
}

wait_for_wrapper()
{
	j=0
	str=""
	while [ $j -lt ${#hostports[*]} ]
	do
		    echo ${hostports[j]}
		    str=$str" "${hostports[j]}
		    let j++
	done
	str=${str#* }
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [[ $WAITFORIT_QUIET -eq 1 ]]; then
	    echo "$0"
       # timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 --quiet --child --host=$WAITFORIT_HOST --port=$WAITFORIT_PORT --timeout=$WAITFORIT_TIMEOUT &
       timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 --quiet --child --hostports=$str --timeout=$WAITFORIT_TIMEOUT &
    else
       # timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 --child --host=$WAITFORIT_HOST --port=$WAITFORIT_PORT --timeout=$WAITFORIT_TIMEOUT &
       echo "$WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 $str --child --timeout=$WAITFORIT_TIMEOUT &"
       timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 $str --child  --timeout=$WAITFORIT_TIMEOUT &
    fi
    WAITFORIT_PID=$!
    trap "kill -INT -$WAITFORIT_PID" INT
    wait $WAITFORIT_PID
    WAITFORIT_RESULT=$?
    if [[ $WAITFORIT_RESULT -ne 0 ]]; then
        echoerr "$WAITFORIT_cmdname: timeout occurred after waiting $WAITFORIT_TIMEOUT seconds for $WAITFORIT_HOST:$WAITFORIT_PORT"
    fi
    return $WAITFORIT_RESULT
}

# process arguments
echo "xxxxx$#"
declare -a hostports
i=0
while [[ $# -gt 0 ]]
do
    case "$1" in
        *:* )
	echo "2222222$1"
	hostports[${i}]=$1
        WAITFORIT_hostport=(${1//:/ })
        WAITFORIT_HOST=${WAITFORIT_hostport[0]}
        WAITFORIT_PORT=${WAITFORIT_hostport[1]}
        shift 1
        let i=${i}+1
        ;;
        --child)
	echo "cccccccccccccc"
        WAITFORIT_CHILD=1
        shift 1
        ;;
        -q | --quiet)
        WAITFORIT_QUIET=1
        shift 1
        ;;
        -s | --strict)
        WAITFORIT_STRICT=1
        shift 1
        ;;
        -h)
        WAITFORIT_HOST="$2"
        if [[ $WAITFORIT_HOST == "" ]]; then break; fi
        shift 2
        ;;
        --host=*)
        WAITFORIT_HOST="${1#*=}"
        shift 1
        ;;
        --hostports=*)
		hostports=("${1#*=}")
		        shift 1
			        ;;
        -p)
        WAITFORIT_PORT="$2"
        if [[ $WAITFORIT_PORT == "" ]]; then break; fi
        shift 2
        ;;
        --port=*)
        WAITFORIT_PORT="${1#*=}"
        shift 1
        ;;
        -t)
        WAITFORIT_TIMEOUT="$2"
        if [[ $WAITFORIT_TIMEOUT == "" ]]; then break; fi
        shift 2
        ;;
        --timeout=*)
        WAITFORIT_TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        WAITFORIT_CLI=("$@")
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

echo "while is over"

if [[ "$WAITFORIT_HOST" == "" || "$WAITFORIT_PORT" == "" ]]; then
	echoerr "Error: you need to provide a host and port to test."
	usage
fi

WAITFORIT_TIMEOUT=${WAITFORIT_TIMEOUT:-15}
WAITFORIT_STRICT=${WAITFORIT_STRICT:-0}
WAITFORIT_CHILD=${WAITFORIT_CHILD:-0}
WAITFORIT_QUIET=${WAITFORIT_QUIET:-0}

# check to see if timeout is from busybox?
WAITFORIT_TIMEOUT_PATH=$(type -p timeout)
WAITFORIT_TIMEOUT_PATH=$(realpath $WAITFORIT_TIMEOUT_PATH 2>/dev/null || readlink -f $WAITFORIT_TIMEOUT_PATH)
if [[ $WAITFORIT_TIMEOUT_PATH =~ "busybox" ]]; then
	 WAITFORIT_ISBUSY=1
	 WAITFORIT_BUSYTIMEFLAG="-t"
else
	WAITFORIT_ISBUSY=0
	WAITFORIT_BUSYTIMEFLAG=""
fi

if [[ $WAITFORIT_CHILD -gt 0 ]]; then
	wait_for
	WAITFORIT_RESULT=$?
	exit $WAITFORIT_RESULT
else
	if [[ $WAITFORIT_TIMEOUT -gt 0 ]]; then
		wait_for_wrapper
		WAITFORIT_RESULT=$?
	else
		wait_for
		WAITFORIT_RESULT=$?
	fi
fi

if [[ $WAITFORIT_CLI != "" ]]; then
	if [[ $WAITFORIT_RESULT -ne 0 && $WAITFORIT_STRICT -eq 1 ]]; then
		echoerr "$WAITFORIT_cmdname: strict mode, refusing to execute subprocess"
		exit $WAITFORIT_RESULT
	fi
	exec "${WAITFORIT_CLI[@]}"
else
	exit $WAITFORIT_RESULT
fi
