# Live simulator
## Description
![App view](https://i.imgur.com/B2FateD.png)

This is a simulation of life, where on the cellular field agents and food for are indicated in two colors, red and blue, respectively. Cell brightness describes energy for an agent cell, food amount for a food cell. Each agent has his own set of instructions (stand, move around the field, clone himself). 

To perform them, energy is needed, which can be resumed by moving into a cell with food. This project targets two goals:
1. Build a stable ecosystem (agents are alive)
2. Get cool graphic effects

Both are done by changing the simulation parameters described below.
## Usage
After launching the app, a field will be generated. It will be shown in the center of the screen. Simulation stats will be displayed in the top left corner.

The app has 2 input modes:
1. simulation control (default)
2. console

In **simulation control** mode you may use:
- `Space` to pause/unpause simulation
- `N` to go only 1 tact ahead

To switch to **console mode** and back from it, use `Tab`.

**Console mode** is used for advanced game control. Using commands you may change simulation parameters and do some cool stuff described a bit later
These commands for simulation parameters changes are available: 
- `ame` - agent move energy
- `ace` - agent clone energy
- `amo` - agent mutation odds
- `fgl` - food grow limit
- `fgt` - food grow time
- `tft` - time for tact (in ms)
- `mce` - min clone energy
- `fma` - food max amount
- `fia` - food max init amount
- `fms` - food max spawn amount
- `fsa` - food spawn amount
- `cfs` - change field size (in cells)

Each of them requires a number parameter (with space as delimetr)

There is also a second type of commands - actions:
- `hlp` - show most used commands
- `rst` - restart simulation
- `dra` - enable agent draw mode
- `drf` - enable food draw mode
- `drc` - enable clear mode
- `drs` - disable draw mode

In draw mode a cursor appears, and you can either click on the required cells one by one or click and move the mouse above the required cells while holding the button pressed.

Note that you __can't__ continue the simulation while the drawing is active. Use `drs` to stop it.

After the game ends you may use draw mode to add some agents and continue the simulation. (Note that it will be paused)