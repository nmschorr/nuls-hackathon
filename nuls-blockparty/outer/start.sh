#!/bin/bash
# from nuls chainbox, modified by nmschorr

MODULE_PATH=$(cd `dirname $0`;pwd)
cd "${MODULE_PATH}"

LOGS_DIR="./log"

APP_NAME="nuls-blockparty" #  
if [ -z "${APP_NAME}" ]; then
    echoRed "APP_NAME"
    exit 0;
fi

VERSION="1.0.0"; # %Version  
JAR_FILE="${MODULE_PATH}/${APP_NAME}-${VERSION}.jar"
MAIN_CLASS="io.nuls.NulsModuleBootstrap" # MAIN_CLASS  
JOPT_XMS="256"  # JOPT_XMS  
JOPT_XMX="256"    # JOPT_XMX  
JOPT_METASPACESIZE="128"  # %JOPT_METASPACESIZE  
JOPT_MAXMETASPACESIZE="256"  # %JOPT_MAXMETASPACESIZE  
JAVA_OPTS=""  # %JAVA_OPTS  

getModuleItem(){
    while read line
	do
		pname=`echo $line | awk -F '=' '{print $1}'`
		pvalue=`awk -v a="$line" '
						BEGIN{
							len = split(a,ary,"=")
							r=""
							for ( i = 2; i <= len; i++ ){
								if(r != ""){
									r = (r"=")
								}
								r=(r""ary[i])
					 		}
							print r
						}
					'`
		if [ "${pname}" == $2 ]; then
			echo ${pvalue};
			return 1;
		fi
	done < $1
	return 0
}


function get_fullpath()
{
    if [ -f "$1" ];
    then
        tempDir=`dirname $1`;
        fileName=$1
        echo "`cd $tempDir; pwd`/${fileName##*/}";
    else
        echo `cd $1; pwd`;
    fi
}


echoRed() { echo -e $'\e[0;31m'$1$'\e[0m'; }
echoGreen() { echo -e $'\e[0;32m'$1$'\e[0m'; }
echoYellow() { echo -e $'\e[0;33m'$1$'\e[0m'; }
log(){
    now=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${now}    $@" >> ${STDOUT_FILE}
    echoGreen "$@"
}

# won't run without arg, so if running separately add anything after start.sh
if [ ! -n "$1" ]; then 
    echo "enter an argument"
    #exit 0;
fi

while [ ! -z $1 ] ; do
    case "$1" in
        "--jre") 
            #log "jre path : $2"
            JAVA_HOME=$2
            shift 2 ;;
        "--managerurl") 
            #log "NulstarUrl is : $2"; 
            NulstarUrl=$2;    
            shift 2 ;;
        "--config")
            config=$2;
            shift 2 ;;
        "--datapath")
            datapath="-DdataPath=$2";
            shift 2 ;;
        "--logpath")
            LOGS_DIR="$2/$APP_NAME"
            logpath="-Dlog.path=$2/$APP_NAME";
            shift 2 ;;
        * ) shift
    esac
done  

if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
fi
START_DATE=`date +%Y%m%d%H%M%S`

if [ -z "${config}" ]; then
    config="../../../../nuls.ncf"
fi

_dataPath=`getModuleItem ${config} "dataPath"`
_logPath=`getModuleItem ${config} "logPath"`
cd `dirname ${config}`
if [ ! -d ${_dataPath} ]; then
    mkdir ${_dataPath}
fi
STDOUT_FILE="`get_fullpath ${_logPath}`/$APP_NAME/stdout.log"
datapath="-DdataPath=`get_fullpath ${_dataPath}`"
logpath="-Dlog.path=`get_fullpath ${_logPath}`/$APP_NAME";

if [ ! -d ${_logPath} ]; then
    mkdir ${_logPath}
fi
cd $MODULE_PATH

checkLogDir(){
    if [ ! -d ${LOGS_DIR} ]; then
        mkdir ${LOGS_DIR}
    fi
}

checkIsRunning(){
    if [ ! -z "`ps -ef|grep -w "name=${APP_NAME} "|grep -v grep|awk '{print $2}'`" ]; then
        pid=`ps -ef|grep -w "name=${APP_NAME} "|grep -v grep|awk '{print $2}'`

        if [ -n "${RESTART}" ];
        then
            log "$APP_NAME Already running pid=$pid";
            log "do restart ${APP_NAM}"
            log "stop ${APP_NAME}@${pid} failure,dump and kill it."
            kill $pid > /dev/null 2>&1
        else
            echoRed "$APP_NAME Already running pid=$pid";
            exit 0;
        fi
    fi
}


# 
checkJavaVersion(){
    JAVA="$JAVA_HOME/bin/java"
    if [ ! -r "$JAVA" ]; then
        JAVA='java'
    fi

    JAVA_EXIST=`${JAVA} -version 2>&1 |grep 11`
    if [ ! -n "$JAVA_EXIST" ]; then
            log "JDK version is not 11"
            ${JAVA} -version
            exit 0
    fi
}

checkJavaVersion 
checkLogDir
checkIsRunning

# nms on DBP added
DBP="-Ddebug=1 -agentlib:jdwp=transport=dt_socket,server=y,address=127.0.0.1:8000,suspend=n"

CLASSPATH=" -classpath ./lib/*"

CLASSPATH="${CLASSPATH}:${JAR_FILE}"
JAVA_OPTS=" -server ${DBP} -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -Xms${JOPT_XMS}m -Xmx${JOPT_XMX}m -XX:MetaspaceSize=${JOPT_METASPACESIZE}m -XX:MaxMetaspaceSize=${JOPT_MAXMETASPACESIZE}m -XX:+ParallelRefProcEnabled -XX:+TieredCompilation -XX:+ExplicitGCInvokesConcurrent $JAVA_OPTS"
JAVA_OOM_DUMP="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOGS_DIR}/oom-${START_DATE}.hprof"
JAVA_OPTS="$JAVA_OPTS $JAVA_GC_LOG $JAVA_OOM_DUMP  -Dapp.name=$APP_NAME ${logpath} ${datapath} "
echo "${JAVA} -Ddebug=1 ${JAVA_OPTS} ${CLASSPATH} ${MAIN_CLASS} ${NulstarUrl}"
CMD="${JAVA} ${JAVA_OPTS} ${CLASSPATH} ${MAIN_CLASS} ${NulstarUrl} "
CMD="${CMD} > ${STDOUT_FILE}"
CMD="$CMD 2>&1 & ";
eval $CMD

log "${APP_NAME} IS STARTING \n ${APP_NAME} START CMD: $CMD  \n ${APP_NAME} 日志文件: ${STDOUT_FILE}"



