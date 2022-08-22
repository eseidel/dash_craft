# dash_craft
 Just playing around.

# Todo
* How to plan.  Do we need a fitness function?
* How to evaluate a given game state vs. another?



# Old Todo
* Each location should be an location object rather than an ItemStack.  Drags just connect two locations rather than moving items.
* Make it possible to save current state.
* Add icons for items
* Show recipe being crafted (if known?)
* Make it possible to not-know recipes?
* Make it possible to drag a whole stack for crafting?


## Bugs
* Crafting always works, even when missing things.
* When multi-crafting, can you get multi-goop?
* How is percent success effected by multi-crafting?

* Missing Features
* Learning recipes
* Recipe book

## Gather skill
12.0
2 bananas +0.5
1 banana +0.5
1 coconut +0.5
1 coconut +0.5
2 bananas +0.5
1 stone +0.5 - 15.0
1 banana +0.5
1 coconut +0.5
1 banana +0.4 - 16.4
..
1 orange +0.4 - 17.2
2 coconut +0.5 - 17.7
2 coconut +0.5 - 17.8?
1 orange +0.2 - 18.0
2 stones + 0.3 - 18.3
1 orange +0.2 - 18.5
1 banana +0.2 - 18.7
2 orange +0.2 - 18.8?
2 stone +0.3 - 19.1
2 orange +0.2 - 19.3
1 banana +0.1 - 19.4
2 orange +0.2 - 19.6
1 orange +0.1 - 19.7
2 coconut +0.2 - 19.9
1 orange +0.1 - 20.0


## MCTS Best yet (goal: 100 stones)

### explorationWeight = 1.0:

Me Energy: 85
Minion Energy: -469
Stats: GameStats{clicks: 2301, timeInMilliseconds: 1370200}
Skills: Skills(Skill.foodPrep: 0.7, Skill.toolCrafting: 0.0, Skill.gather: 135.0999999999966)
Inventory: {Coconut: 136, Stone: 100, Peeled Orange: 4, Stick: 72, Vine: 65, Goop: 4, Orange: 20, Walnut: 26, Banana: 16, Peanut: 14, Potato: 12, Chestnut: 14, Red Berry: 14, Apple: 13, Blue Berry: 6, Tomato: 9, Eggplant: 2, Lettuce: 2, Carrot: 2}

### explorationWeight = 0.5: (with some fixes)

Move 2700
Skills(Skill.foodPrep: 4.899999999999999, Skill.toolCrafting: 0.0, Skill.gather: 150.09999999999576)
Inventory({Coconut: 137, Stone: 99, Stick: 83, Vine: 84, Red Berry: 1})
Done!
Me Energy: 100
Minion Energy: -521
Stats: GameStats{clicks: 2709, timeInMilliseconds: 1607100}
Skills: Skills(Skill.foodPrep: 4.899999999999999, Skill.toolCrafting: 0.0, Skill.gather: 150.59999999999573)
Inventory: {Coconut: 138, Stone: 100, Stick: 83, Vine: 84}

### After having fixed skills to gain faster and cap at 40 from diff.

Move 1400
Skills(foodPrep: 5.0, toolCrafting: 0.0, gather: 57.6)
Inventory({Coconut: 90, Stone: 96, Stick: 41, Vine: 46, Peeled Orange: 1, Eggplant: 1})
CRAFT {Walnut Kernel: 1}
CRAFT {Peanut Kernel: 1}
Done!
Me Energy: 100
Minion Energy: -153
Stats: GameStats{clicks: 1460, timeInMilliseconds: 674900}
Skills: Skills(foodPrep: 5.2, toolCrafting: 0.0, gather: 59.3)
Inventory: {Coconut: 94, Stone: 101, Stick: 44, Vine: 48}