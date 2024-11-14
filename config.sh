#!/usr/bin/env bash

defaultOutputFile='/dev/stdout'
separator='|'

# A4 portrait, Firefox
nbLines=75
nbColumns=106

# A4 portrait, Chromium
#nbLines=75
#nbColumns=99
# Chromium can fit the Firefox 'full page' in width (i.e. 106 chars) if scaled to 93%
# and has some extra space for 5 more lines ;-)


#blankCharacter='░'
#blankCharacter='▒'
#blankCharacter='▓'
#blankCharacter='█'
#blankCharacter='·'
blankCharacter=' '
