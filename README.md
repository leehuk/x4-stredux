# Station Traders Redux

## ABOUT

Adds two new default ship behaviours for inbound and outbound station traders, allowing more control over trading

Heavily inspired by the [Mules Supply and Warehouses Extended](https://www.nexusmods.com/x4foundations/mods/416) mod, but relying almost entirely on vanilla X4 trading routines

## HOW IT WORKS

* Assign a ships default behaviour to either "Station Trader Inbound" or "Station Trader Outbound"
* Select the home station they'll trade for
* Optionally select the wares they'll trade, or leave it empty to use the wares for sale in the station
* Select the min/max distance they'll trade
* The home stations manager skill controls the maximum trade distance
* All trade offers will follow vanilla X4 mechanics

## FAQ

**Q:** Mimicry?
**A:** Works fine, subordinates will mirror the commanders general orders but run their own trades

**Q:** Wares list not updating?
**A:** Update the default behaviour of the commander to force a refresh -- moving one of the range sliders allows it to be re-saved

**Q:** Inbound and outbound trades with the same ship?
**A:** Try the vanilla mechanics of assigning ships to stations or vanilla autotrading?

**Q:** Performance?
**A:** Very slightly worse than the vanilla autotrading

## COMPATIBILITY

* OK: [Expert Trader and Advanced Trader Enhanced](https://www.nexusmods.com/x4foundations/mods/1235)
* OK: [Trader Seminars](https://www.nexusmods.com/x4foundations/mods/769)
* Untested but should be OK: [Mules, Supply and Warehouses Extended](https://www.nexusmods.com/x4foundations/mods/416).  Mostly relies on its own behaviour
* Untested but should be OK: [KUDA AI Tweaks](https://www.nexusmods.com/x4foundations/mods/839).  The xpath patches don't look to conflict
* Other trader mods: If they're patching the same functions this mod is, it'll probably break.  If they're not, it won't

## TECHNICAL DETAILS

* This mod starts with a copy of the vanilla X4 order.trade.routine -- the same one used for autotrading
* Via an scripted series of xmlstarlet xpath transformations, its transformed into a new stredux routine
* It would be possible to apply these as xpaths directly to order.trade.routine, but its pretty invasive and generates a lot of errors
* A minor patch on trade.find.free to limit our buy/sell offers to the home station
* The patch is not optimal.  Ideally we'd skip the relevant vanilla find_buy_offer/find_sell_offer completely in favour of a station specific one, but I can't see a good way with the xpath operations available
* A minor patch on order.assist to allow subordinates to inherit the station trade routine
* All actual trades then use the normal trade.find.free mechanics