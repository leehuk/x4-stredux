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

    export DEBUGOUT=""

    case $XPATHTYPE in
    # Select a node (for debugging)
    s)
        [[ $DEBUGOUT ]] && echo -n "???: " && xmlstarlet sel -t -c "$XPATH" $FILE && echo
        ;;

    # Add child to a node
    ac)
        xmlstarlet ed -L -s "$XPATH" -t elem -n "$XPATHREPLACE" $FILE
        [[ $DEBUGOUT ]] && echo -n "+++: " && xmlstarlet sel -t -c "$XPATH/*" $FILE && echo
        ;;

    # Add sibling after a node
    as)
        xmlstarlet ed -L -a "$XPATH" -t elem -n "$XPATHREPLACE" $FILE
        #[[ $DEBUGOUT ]] && echo -n "+++: " && xmlstarlet sel -t -c "$XPATH" $FILE && echo
        ;;

    # Add a value to a node
    av)
        xmlstarlet ed -L -i "$XPATH" -t attr -n "$XPATHREPLACE" -v "$XPATHVALUE" $FILE
        [[ $DEBUGOUT ]] && echo -n "+++: " && xmlstarlet sel -t -c "$XPATH" $FILE && echo
        ;;

    # Delete a node
    dn)
        [[ $DEBUGOUT ]] && echo -n "---: " && xmlstarlet sel -t -c "$XPATH" $FILE && echo
        xmlstarlet ed -L -d "$XPATH" $FILE
        ;;

    # Delete a value
    dv)
        [[ $DEBUGOUT ]] && echo -n "---: " && xmlstarlet sel -t -v "$XPATH" $FILE && echo
        xmlstarlet ed -L -d "$XPATH" $FILE
        ;;
    
    # Rename a node
    rn)
        xmlstarlet ed -L -r "$XPATH" -v "$XPATHREPLACE" $FILE
        ;;

    uv)
        [[ $DEBUGOUT ]] && echo -n "---: " && xmlstarlet sel -t -v "$XPATH" $FILE && echo
        xmlstarlet ed -L -u "$XPATH" -v "$XPATHREPLACE" $FILE
        [[ $DEBUGOUT ]] && echo -n "+++: " && xmlstarlet sel -t -v "$XPATH/*" $FILE && echo
        ;;

    *)
        echo STDOUT "Error: Unknown XPATHTYPE: $XPATHTYPE"
        ;;
    esac
}

export DEBUGOUT=0

[[ $(type -P "xmlstarlet") ]] || fail "xmlstarlet must be installed"

INFILE="order.trade.routine.xml.orig"
OUTFILE="order.stredux.traderoutine.xml"

cp $INFILE $OUTFILE
export FILE=$OUTFILE

# Update the name and id of the script
doxpath '/aiscript/@name' 'uv' 'order.stredux.traderoutine'
doxpath '/aiscript/order/@id' 'uv' 'STRedux_TradeRoutine'

# Add our buystation and buydock options
doxpath '(/aiscript/order/params/param)[last()]' as 'param'
doxpath '(/aiscript/order/params/param)[last()]' av 'name' 'buystation'
doxpath '(/aiscript/order/params/param)[last()]' av 'default' 'null'
doxpath '(/aiscript/order/params/param)[last()]' av 'type' 'internal'

doxpath '(/aiscript/order/params/param)[last()]' as 'param'
doxpath '(/aiscript/order/params/param)[last()]' av 'name' 'buydock'
doxpath '(/aiscript/order/params/param)[last()]' av 'default' 'false'
doxpath '(/aiscript/order/params/param)[last()]' av 'type' 'internal'

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
doxpath '/aiscript/init/do_if[2]/@value' 'uv' "this.assignedcontrolled.order.id == 'STRedux_OutboundTrader'"
doxpath '/aiscript/attention/actions/do_if/set_order_syncpoint_reached/../@value' 'uv' "this.assignedcontrolled.order.id == 'STRedux_OutboundTrader'"

# Remove the logic overriding minbuy/minsell/maxbuy/maxsell
doxpath '/aiscript/init/do_if[@value="this.isplayerowned"]' 'dn'

# Add our parameters to the <run_script> for trade.find.free
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' as 'param'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' av 'name' 'buystation'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' av 'value' '$buystation'

doxpath '(/aiscript/attention/actions/run_script/param)[last()]' as 'param'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' av 'name' 'buydock'
doxpath '(/aiscript/attention/actions/run_script/param)[last()]' av 'value' '$buydock'

# Swap move.idle over to optional docking
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]/*" dn
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]" av 'value' '$buydock'
doxpath "/aiscript/attention/actions/run_script[@name=\"'move.idle'\"]/@name" dv
doxpath '/aiscript/attention/actions/run_script[@value="$buydock"]' rn 'do_if'

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]' ac 'do_if'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if' av 'value' '@this.ship.dock.container != $buystation or (this.ship.dock and not this.ship.dock.istradingallowed)'

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if' ac 'debug_text'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/debug_text' av 'text' "player.age + ' moving to dock at ' + \$buystation.knownname"
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/debug_text' av 'chance' '$debugchance'

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if' ac 'run_script'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' av 'name' "'order.dock'"

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' ac 'param'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@name)]' av 'name' 'destination'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@value)]' av 'value' '$buystation'

doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' ac 'param'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@name)]' av 'name' 'trading'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@value)]' av 'value' 'true'

doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' ac 'param'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@name)]' av 'name' 'waittime'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@value)]' av 'value' '60min'

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' ac 'param'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@name)]' av 'name' 'internalorder'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@value)]' av 'value' 'true'

doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script' ac 'param'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@name)]' av 'name' 'debugchance'
doxpath '/aiscript/attention/actions/do_if[@value="$buydock"]/do_if/run_script/param[not(@value)]' av 'value' '$debugchance'

doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_if' as 'do_else'
doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_else' ac 'wait'
doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_else/wait' av 'min' '10s'
doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]/do_else/wait' av 'max' '25s'

doxpath '//aiscript/attention/actions/do_if[@value="$buydock"]' as 'do_else'
doxpath '//aiscript/attention/actions/do_else[not(*)]' ac 'run_script'
doxpath '//aiscript/attention/actions/do_else/run_script' av 'name' "'move.idle'"
doxpath '//aiscript/attention/actions/do_else/run_script' ac 'param'
doxpath '//aiscript/attention/actions/do_else/run_script/param' av 'name' 'TimeOut'
doxpath '//aiscript/attention/actions/do_else/run_script/param' av 'value' '$idleduration'