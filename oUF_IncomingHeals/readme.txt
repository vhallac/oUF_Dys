oUF_IncomingHeals will show incoming heals on
your unit frames. It will show your own heals 
in a different color so you can see when your 
heal will land compared to the rest of the heals.

This very descriptive asci-art will be used 
instead of a screenshot:

[##hHHhhh  ]

Here you can see a unit with 20% health getting 
healed for a total ~60% of his health. Your heal 
will heal him ~20%. Before your heal land some 
other healer will land a heal for ~10% and after 
your heal there's another heal incoming for ~30%.

You don't have to do anything special in your 
layout to get incoming heal bars on your frames. 

To not show incoming heals on a specific unit 
you can set self.ignoreIncomingHeal = true

You can use to following function to create the 
heal textures early if you want to have another 
texture, color or alpha than the default or if 
you want to disable the feature to show your own 
heals differently.
oUF_IncomingHeals_CreateDefault
Arguments:
* object      - table
* texture     - string or nil
    defaults to the texture of your health bar
* color       - table or nil
    Color for other players heals
      indexed by r, g, b, a or 1, 2, 3, 4
      values range from 0-1
      defaults to 0, 1, 0, 0.25
* playerColor - table or false or nil
    Color for your own heals
    Use false to not show your own heals 
    different than other players.
      indexed by r,g,b,a or 1,2,3,4
      values range from 0-1
      defaults to 0, 0.8, 0.8, 0.4
* alpha       - number [0-1] or nil
    Alpha for other players heals. Will 
    override whatever is set in color.
      defaults to 0.25
* playerAlpha - number [0-1] or nil
    Alpha for your own heals. Will 
    override whatever is set in playerColor.
      defaults to 0.4



Known caveats:
* Needs to use the PostUpdateHealth to resize 
  and reposition after a UNIT_(MAX)HEALTH.
  If you're already using PostUpdateHealth for 
  something you can call the global function
  oUF_IncomingHeals_UpdateHealsPostHealth with 
  all normal PostUpdateHealth arguments (self, 
  event, bar, unit, min, max) in your function.
  Example:

local UpdateHealsPostHealth = oUF_IncomingHeals_UpdateHealsPostHealth
function MyPostUpdateHealth(self, event, bar, unit, min, max)
    -- Do your usual stuff here.
    
	UpdateHealsPostHealth(self, event, bar, unit, min, max)
end
