# Station Traders Redux

## ABOUT

Adds two new default ship behaviours for inbound and outbound station traders, allowing more control over trading

**This mod is beta**

**Make sure you have copies of a save from *before* you installed this mod, just in case**

Heavily inspired by the [Mules Supply and Warehouses Extended](https://www.nexusmods.com/x4foundations/mods/416) mod, but for better and worse relying almost entirely on vanilla X4 7.0 trading routines

## HOW IT WORKS

* Assign a ships default behaviour to either "Station Trader Inbound" or "Station Trader Outbound"
* Select the home station they'll trade for (click the button, right click on a station and choose 'Select')
* Optionally select the wares they'll trade, or leave it empty to use the wares set in the stations logical overview
* Select the min/max distance they'll trade
* The stations manager skill controls the maximum trade distance
* The stations logical overview decides what it will buy and sell
* The ships instructions for trade restrictions decide which factions/sectors can be bought/sold to
* All trade offers will follow vanilla X4 mechanics

## FAQ

**Q:** Mimicry?
**A:** Works fine, subordinates will mirror the commanders general orders but run their own trades

**Q:** Wares list not updating?
**A:** Update the default behaviour of the commander to force a refresh -- moving one of the range sliders allows it to be re-saved

**Q:** Performance?
**A:** Very slightly worse than the vanilla autotrading

# ITS NOT WORKING

* Wait a couple of minutes.  The mod adds "sleep periods" for errors to avoid hammering X4, and the vanilla trade routines have them too.  These can be over a minute long
* Check the ships information screen.  The orders will normally go yellow if there's a problem or it can't find a trade and it should say why
* If it can't find a trade, its nearly all vanilla mechanics.  That means either a trade restriction, there's no offers, the station doesn't have budget, etc
* Enable debug mode for X4.  This mod will helpfully spam the logs

## COMPATIBILITY

* OK: [Expert Trader and Advanced Trader Enhanced](https://www.nexusmods.com/x4foundations/mods/1235)
* OK: [Trader Seminars](https://www.nexusmods.com/x4foundations/mods/769)
* Untested but should be OK: [Mules, Supply and Warehouses Extended](https://www.nexusmods.com/x4foundations/mods/416).  Mostly relies on its own behaviour
* Untested but should be OK: [KUDA AI Tweaks](https://www.nexusmods.com/x4foundations/mods/839).  The xpath patches don't look to conflict
* Other trader mods: If they're patching the same functions this mod is, it'll probably break.  If they're not, it probably won't

## TECHNICAL DETAILS

* This mod starts with a copy of the vanilla X4 order.trade.routine -- the same one used for autotrading
* Via an scripted series of xmlstarlet xpath transformations, its transformed into a new stredux routine
* It would be possible to apply these as xpaths directly to order.trade.routine, but its pretty invasive and generates a lot of errors
* A minor patch on trade.find.free to limit our buy/sell offers to the home station
* The patch is not optimal.  Ideally we'd skip the relevant vanilla find_buy_offer/find_sell_offer completely in favour of a station specific one, but I can't see a good way with the xpath operations available
* A minor patch on order.assist to allow subordinates to inherit the station trade routine
* All actual trades then use the normal trade.find.free mechanics

## REGENERATING TRADE ROUTINE

* Open the 08.dat file from the X4 install using the X Tools (available on steam, or egosoft forum)
* Extract the aiscripts/order.trade.routine.xml file
* Save it into this mod as aiscripts/order.trade.routine.xml.orig
* Open a shell, have xmlstarlet installed
* Run bash gentraderoutine.sh

## LICENSE

MIT.  Except for aiscripts/order.stredux.traderoutine.xml because thats generated based off aiscripts/order.trade.routine.xml from the X4 Foundations game