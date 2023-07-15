(07.15.2023)
- Added `/questie query` to query the server for completed quests.
> NOTE: If you have previously used Questie, I recommend you run `/questie NUKE` to reset your data entirely.

> USAGE: After running the query, please `/reload` twice (once to push the changes to your SavedVariables, again to populate them in Questie) for changes to take effect. I hope to fix this in the future.

- Added hardcoded "map scaling".
> NOTE: This is unfortunately hardcoded until I can find a way to scale them gracefully. This supports the resized zonemap, the fullsize zonemap with quest objectives enabled, and the fullsize zonemap. If the zonemap icons are not lining up correctly, toggle Questie off and back on to see if they work correctly.

- The minimap should function 100% correctly now to my knowledge.
- Changed default AddOn settings to more closely align with WotLK.
- Changed many UI elements to be more dynamic and play nicer with other AddOns.
- Reverted Ace3 back to Ace2 for potential bug fixes.
- Removed references to EQL3 since it has no use in WotLK.