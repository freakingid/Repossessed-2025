extends Node

# Collision Layers (bit flags)
const LAYER_PLAYER = 1                     # Layer 1
const LAYER_PLAYER_BULLET = 1 << 1        # Layer 2
const LAYER_ENEMY = 1 << 2                # Layer 3
const LAYER_SPAWNER = 1 << 3              # Layer 4
const LAYER_WALL = 1 << 4                 # Layer 5
const LAYER_POWERUP = 1 << 5              # Layer 6
const LAYER_ENEMY_PROJECTILE = 1 << 6     # Layer 7
const LAYER_CRATE = 1 << 7                # Layer 8

var score: int = 0
