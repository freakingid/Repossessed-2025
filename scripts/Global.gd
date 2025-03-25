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

# Visual layering constants (z_index values)
const Z_TILEMAP                   = 0
const Z_BACKGROUND_DECALS        = 5   # Shadow overlays above floor
const Z_DROPPED_ITEMS             = 10
const Z_BASE_ENEMIES              = 20
const Z_CARRIED_CRATE_BEHIND      = 25
const Z_PLAYER_AND_CRATES         = 30
const Z_CARRIED_CRATE_IN_FRONT    = 35
const Z_FLYING_ENEMIES            = 40
const Z_OVERHEAD_DECORATIONS      = 50
const Z_UI_FLOATING              = 100


var score: int = 0
