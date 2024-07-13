#!/bin/bash

fail()
{
    echo $@
    exit 1
}

doxpath()
{
    XPATH="$1"
    XPATHTYPE="$2"
    XPATHREPLACE="$3"
    XPATHVALUE="$4"
    shift 4

    case $XPATHTYPE in
    # Select a node (for debugging)
    s)
        echo -n "???: " && xmlstarlet sel -t -c "$XPATH" $FILE && echo
        ;;

    # Add child to a node
    ac)
        xmlstarlet ed -L -s "$XPATH" -t elem -n "$XPATHREPLACE" $FILE
        ;;

    acv)
        xmlstarlet ed -L -s "$XPATH" -t elem -n "$XPATHREPLACE" $FILE

        XPATHCHILD="$XPATH/$XPATHREPLACE"
        if [ -n "$XPATHVALUE" ]; then
            XPATHCHILD="$XPATH/$XPATHVALUE"
        fi

        while [ -n "$2" ]; do
            xmlstarlet ed -L -i "$XPATHCHILD" -t attr -n "$1" -v "$2" $FILE
            shift 2
        done
        ;;

    # Add sibling after a node
    as)
        xmlstarlet ed -L -a "$XPATH" -t elem -n "$XPATHREPLACE" $FILE
        ;;

    # Add a sibling with values
    asv)
        xmlstarlet ed -L -a "$XPATH" -t elem -n "$XPATHREPLACE" $FILE

        while [ -n "$2" ]; do
            xmlstarlet ed -L -i "$XPATH" -t attr -n "$1" -v "$2" $FILE
            shift 2
        done
        ;;

    # Add a value to a node
    av)
        xmlstarlet ed -L -i "$XPATH" -t attr -n "$XPATHREPLACE" -v "$XPATHVALUE" $FILE
        ;;

    # Delete a node
    dn)
        xmlstarlet ed -L -d "$XPATH" $FILE
        ;;

    # Delete a value
    dv)
        xmlstarlet ed -L -d "$XPATH" $FILE
        ;;
    
    # Rename a node
    rn)
        xmlstarlet ed -L -r "$XPATH" -v "$XPATHREPLACE" $FILE
        ;;

    uv)
        xmlstarlet ed -L -u "$XPATH" -v "$XPATHREPLACE" $FILE
        ;;

    *)
        echo STDOUT "Error: Unknown XPATHTYPE: $XPATHTYPE"
        ;;
    esac
}

[[ $(type -P "xmlstarlet") ]] || fail "xmlstarlet must be installed"

INFILE="order.trade.routine.xml.orig"
OUTFILE="order.stredux.traderoutine.xml"

cp $INFILE $OUTFILE
export FILE=$OUTFILE

# Update the name and id of the script
doxpath '/aiscript/@name' 'uv' 'order.stredux.traderoutine'
doxpath '/aiscript/order/@id' 'uv' 'STRedux_TradeRoutine'

# Add our custom options
doxpath '(/aiscript/order/params/param)[last()]' asv 'param' '' 'name' 'stxoutstation' 'default' 'null' 'type' 'internal'
doxpath '(/aiscript/order/params/param)[last()]' asv 'param' '' 'name' 'stxoutdock' 'default' 'false' 'type' 'internal'
doxpath '(/aiscript/order/params/param)[last()]' asv 'param' '' 'name' 'stxinstation' 'default' 'null' 'type' 'internal'

# Remove the version patches
doxpath '/aiscript/patch' dn

# Remove skill requirement from the order (its internal anyway but)
doxpath '/aiscript/order/skill' dn

# Force the use of trade.find.free
doxpath '/aiscript/interrupts/library' dn
doxpath '/aiscript/attention/actions/include_interrupt_actions[@ref="SetFindTradeScript"]' dn
doxpath '/aiscript/attention/actions/do_if/include_interrupt_ac1tions[@ref="SetFindTradeScript"]' dn
doxpath '/aiscript/init' ac set_value
doxpath '/aiscript/init/set_value[not(@name)]' av name '$findtradescript'
doxpath '/aiscript/init/set_value[@name="$findtradescript"]' av exact "'trade.find.free'"

# Allow STRedux Trade Orders
doxpath '/aiscript/init/do_if[2]/@value' 'uv' "(this.assignedcontrolled.order.id == 'STRedux_OutboundTrader') or (this.assignedcontrolled.order.id == 'STRedux_InboundTrader')"
doxpath '/aiscript/attention/actions/do_if/set_order_syncpoint_reached/../@value' 'uv' "(this.assignedcontrolled.order.id == 'STRedux_OutboundTrader') or (this.assignedcontrolled.order.id == 'STRedux_InboundTrader')"

# Remove the logic overriding minbuy/minsell/maxbuy/maxsell
doxpath '/aiscript/init/do_if[@value="this.isplayerowned"]' 'dn'

# Add our parameters to the <run_script> for trade.find.free
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' asv 'param' '' 'name' 'stxoutstation' 'value' '$stxoutstation'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' asv 'param' '' 'name' 'stxoutdock' 'value' '$stxoutdock'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' asv 'param' '' 'name' 'stxinstation' 'value' '$stxinstation'

# Swap move.idle over to optional docking
# This ones trixy -- we need to inject all our new flow into the move.idle instruction, swap it to a do_if
# and then restore the move.idle under an else
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]/*" dn
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]" av 'value' '$stxoutdock'
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]/@name" dv
doxpath '/aiscript/attention/actions/run_script[@value="$stxoutdock"]' rn 'do_if'

doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]' acv 'do_if' '' 'value' '@this.ship.dock.container != $stxoutstation or (this.ship.dock and not this.ship.dock.istradingallowed)'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if' acv 'debug_text' '' 'text' "player.age + ' moving to dock at ' + \$stxoutstation.knownname" 'chance' '$debugchance'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if' acv 'run_script' '' 'name' "'order.dock'"

doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if/run_script' acv 'param' 'param[not(@value)]' 'name' 'destination' 'value' '$stxoutstation'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if/run_script' acv 'param' 'param[not(@value)]' 'name' 'trading' 'value' 'true'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if/run_script' acv 'param' 'param[not(@value)]' 'name' 'waittime' 'value' '60min'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if/run_script' acv 'param' 'param[not(@value)]' 'name' 'internalorder' 'value' 'true'
doxpath '/aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if/run_script' acv 'param' 'param[not(@value)]' 'name' 'debugchance' 'value' '$debugchance'

doxpath '//aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_if' as 'do_else'
doxpath '//aiscript/attention/actions/do_if[@value="$stxoutdock"]/do_else' acv 'wait' '' 'min' '10s' 'max' '25s'

doxpath '//aiscript/attention/actions/do_if[@value="$stxoutdock"]' as 'do_else'
doxpath '//aiscript/attention/actions/do_else[not(*)]' ac 'run_script'
doxpath '//aiscript/attention/actions/do_else/run_script[not(@name)]' av 'name' "'move.idle'"
doxpath '//aiscript/attention/actions/do_else/run_script' acv 'param' '' 'name' 'TimeOut' 'value' '$idleduration'