#!/usr/bin/env bash
# Management script for ircservserv kubernetes processes
# Adapted from stashbot scripts

set -e

DEPLOYMENT=ircservserv
POD_NAME=ircservserv

APP_DIR=/data/project/ircservserv/ircservserv
CONFIG_DIR=/data/project/ircservserv/ircservserv-config
DEPLOYMENT_FILE=${CONFIG_DIR}/toolforge/deployment.yaml

KUBECTL=/usr/bin/kubectl

_get_pod() {
    $KUBECTL get pods \
        --output=jsonpath={.items..metadata.name} \
        --selector=name=${POD_NAME}
}

case "$1" in
    start)
        echo "Starting ircservserv k8s deployment..."
        $KUBECTL create --validate=true -f ${DEPLOYMENT_FILE}
        ;;
    run)
        date +%Y-%m-%dT%H:%M:%S
        echo "Running ircservserv..."
        cd ${CONFIG_DIR}
        ${APP_DIR}/target/release/ircservserv
        ;;
    stop)
        echo "Stopping the Kubernetes deployment..."
        $KUBECTL delete deployment ${DEPLOYMENT}
        # FIXME: wait for the pods to stop
        ;;
    restart)
        echo "Restarting the running pod..."
        exec $KUBECTL delete pod $(_get_pod)
        ;;
    status)
        echo "Active pods:"
        exec $KUBECTL get pods -l name=${POD_NAME}
        ;;
    tail)
        exec $KUBECTL logs -f $(_get_pod)
        ;;
    attach)
        echo "Attaching to pod..."
        exec $KUBECTL exec -i -t $(_get_pod) -- /bin/bash
        ;;
    compile)
        echo "Compiling ircservserv on the grid..."
        cd ${APP_DIR}
        time jsub -N build -mem 2G -sync y -cwd cargo build --release
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|tail|attach|compile}"
        exit 1
        ;;
esac

exit 0

