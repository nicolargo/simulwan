#!/bin/bash
#
# simulwan-bridge.sh
# Nicolargo - 2012
#

##############################################################################

# Nom des interfaces ou l'on doit faire les simulations
# eth0 cote LAN local 
# eth1 cote LAN distant
IF=eth1

# Liaison sortante (UPLOAD) a appliquer sur IF
# Debit sortant
BWU=8mbit
# Délai de transit sortant
DELAYU=15ms
# % de paquets perdus sortant
LOSSU=0.0001%

# Liaison entrante (DOWNLOAD) a appliquer sur IF
# Debit entrant
BWD=1mbit
# Délai de transit entrant
DELAYD=15ms
# % de paquets perdus entrant
LOSSD=0.0001%

##############################################################################

start() {
    modprobe ifb
    ip link set dev ifb0 up

    tc qdisc add dev $IF ingress

    tc filter add dev $IF parent ffff: \
    protocol ip u32 match u32 0 0 flowid 1:1 \
    action mirred egress redirect dev ifb0

    # Liaison entrante
    tc qdisc add dev ifb0 root handle 1:0 \
    netem delay $DELAYD 10ms distribution normal \
    loss $LOSSD 25%

    tc qdisc add dev ifb0 parent 1:1 handle 10: \
    tbf rate $BWD buffer 3200 limit 6000

    # Liaison sortante
    tc qdisc add dev $IF root handle 2:0 \
    netem delay $DELAYU 10ms distribution normal \
    loss $LOSSU 25%

    tc qdisc add dev $IF parent 2:1 handle 10: \
    tbf rate $BWU buffer 3200 limit 6000
}

stop() {
    tc qdisc del dev ifb0 root
    tc qdisc del dev $IF root
    # ip link set dev ifb0 down
}

restart() {
    stop
    sleep 1
    start
}

show() {
    echo "Liaison entrante"
    tc -s qdisc ls dev ifb0
    echo "Liaison sortante"
    tc -s qdisc ls dev $IF
}

case "$1" in
    start)
        echo -n "Starting WAN simul: "
        start
        echo "done"
        ;;
    stop)
        echo -n "Stopping WAN simul: "
        stop
        echo "done"
        ;;
    restart)
        echo -n "Restarting WAN simul: "
        restart
        echo "done"
        ;;
    show)
        echo "WAN simul status for $IF:"
        show
        echo ""
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|show}"
        ;;
esac

exit 0
