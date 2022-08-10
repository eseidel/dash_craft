# dash_craft
 Just playing around.

# Building a simulator
* Give it a goal (e.g. 100 peeled bananas)
* Give it actions (fetch, peel, discard, eat, etc.)
* Simulate possible actions for the actor.
* Separate SkillState from Inventory
* SkillState (skill levels for both me and minion)
* RecipeBook (all available recipes)
* Inventory (stuff we have)
* GameState? (clicks, time, goal)?


# Todo
* Each location should be an location object rather than an ItemStack.  Drags just connect two locations rather than moving items.
* Make it possible to save current state.
* Add icons for items
* Show recipe being crafted (if known?)
* Make it possible to not-know recipes?
* Make it possible to drag a whole stack for crafting?


Bugs
* Crafting always works, even when missing things.
* When multi-crafting, can you get multi-goop?
* How is percent success effected by multi-crafting?

* Missing Features
* Learning recipes
* Recipe book


# Skill gains
* 2.2 after peeling 4 bananas (2 failures)
* .5 for first orange 2.7 (success, first)
* 0 for second orange? 2.7 (success)
* 0.9 for 3rd orange? 3.6
* 0 for 4th orange (success)
* after 9th orange (fail) 5.1
* 13th (fail) 6.0
* 15th (fail) 6.6 (58% chance)
* first walnut 7.1 (58% chance)
* second walnut (fail) 7.6 (59%)
* 4th (fail) 8.0 (60%)
* First sharp stone 0.6
* 3rd sharp stone +0.8, 1.4
* 5th sharp stone +0.7 2.1
* 7th?  0.8 to 2.9
* 9th? 0.7 to 3.6
* 0.7 to 4.3
* 0.8 to 5.1
* 0.7 to 5.8
* 0.5 to 6.3
* 0.6 to 6.9
* 0.5 to 7.4
* 0.6 to 8.0
* 0.6 to 8.6
* 0.6 to 9.2
* 0.5 to 9.7
* 


Meal prep
* banana 0.5 to 8.5
* 0.6 to 9.1
* 0.6 to 9.7 (62% chance)
* 0.4 to 10.1 (62% chance)
* 0.4 to 10.5 (63%)
* 0.6 to 11.1 (63%)
* 0.6 to 11.7 (64%)
* 0.6 to 12.3 (65%)
* 0.4 to 12.7 (65%)
* 0.5% to 13.2 (66%)
* 0.4 to 13.6 (67%)
* 0.3 to 13.9 (67%)
* 0.5 to 14.4 (68%)
* 0.5 to 14.9 ()
* 0.3 to 15.2 (69%)
* 0.3 to 15.5 (69%)
* 0.5 to 16.0 (70%)
* 0.4 to 16.4
* 0.3 to 16.7
* 0.4 to 17.1
* 0.4 to 17.5
* 0.3 to 17.8
* 0.1 to 17.9 (72%)
* 0.2 to 18.1
* 0.1 to 18.2
* 0.3 to 18.5
* 0.3 to 18.8
* 0.1 to 18.9
* 0.1 to 19.0
* 0.1 to 19.1
* 0.1 to 19.2
* 0.1 to 19.3 (74)
* 0.3 to 19.6
* 0.3 to 19.9
* 0.3 to 20.2
* 0.3 to 20.5
* 0.1 to 20.6
* 0.2 to 20.8
* 0.1 to 20.9
* 0.1 to 21.0
* 0.1 to 21.1
* 0.3 to 21.4
* 0.1 to 21.5
* 0.1 to 21.6
* 0.3 to 21.9
* 0.2 to 22.1
* 0.1 to 22.2
* 0.2 to 22.4
* 0.2 to 22.6
* 0.2 to 22.8
* 0.2 to 23.0
* 0.3 to 23.3
* 0.1 to 23.4
* 0.3 to 23.7
* 0.3 to 24.0
* 0.3 to 24.3
* 0.3 to 24.3
* 0.1 to 36.4 (95%)
* 0.1 to 36.5 (95%)

Banana's cap out at 40
