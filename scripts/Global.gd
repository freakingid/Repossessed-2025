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
const LAYER_FLYING_ENEMY = 1 << 8         # Layer 9
const LAYER_BARREL = 1 << 9                # Layer 10


# Visual layering constants (z_index values)
const Z_TILEMAP                   = 0
const Z_BACKGROUND_DECALS        = 5   # Shadow overlays above floor
const Z_DROPPED_ITEMS             = 10
const Z_BASE_ENEMIES              = 20
const Z_CARRIED_CRATE_BEHIND      = 25
const Z_CARRIED_CRATE_BEHIND_FLAME = 26
const Z_PLAYER_AND_CRATES         = 30
const Z_PLAYER_AND_CRATES_FLAME   = 31
const Z_CARRIED_CRATE_IN_FRONT    = 35
const Z_CARRIED_CRATE_IN_FONT_FLAME = 36
const Z_FLYING_ENEMIES            = 40
const Z_OVERHEAD_DECORATIONS      = 50
const Z_UI_FLOATING              = 100

var score: int = 0

# Ghost is essentially my base enemy properties
class GHOST:
	const SPEED = 60.0
	const DAMAGE = 1
	const HEALTH = 1
	const SCORE = 1

# Skeletons move a bit faster and can potentially get around walls
class SKELETON:
	const SPEED = GHOST.SPEED * 1.25
	const DAMAGE = GHOST.DAMAGE * 2
	const HEALTH = GHOST.HEALTH * 2
	const SCORE = GHOST.SCORE * 2

# Skeleton shooters fire arrows when in range
class SKELETON_SHOOTER:
	const SPEED = SKELETON.SPEED
	const DAMAGE = SKELETON.DAMAGE
	const HEALTH = SKELETON.HEALTH
	const SCORE = SKELETON.SCORE * 2
	const ARROW_SPEED = 150.0
	const ARROW_DAMAGE = 2
	const ARROW_LIFESPAN = 3.0
	const ARROW_FIRE_RATE = 1.5

# Lobbers are hard to chase, protect themselves with walls, and fire nasty shots
# Inside their class they will use a much faster "running away" speed
class LOBBER:
	const SPEED = GHOST.SPEED * 0.75
	const DAMAGE = GHOST.DAMAGE
	const HEALTH = GHOST.HEALTH
	const SCORE = SKELETON_SHOOTER.SCORE * 2

# Bats can fly over everything and have a fast dash speed to player
class BAT:
	const SPEED = GHOST.SPEED * 1.875
	const DAMAGE = SKELETON.DAMAGE
	const HEALTH = SKELETON.HEALTH
	const SCORE = SKELETON_SHOOTER.SCORE * 2

# Spiders move erratically toward the player in fits and starts
# Spiders can fire a web at the player that will immobilize for a time
class SPIDER:
	const SPEED = BAT.SPEED        # This is their skitter speed
	const DAMAGE = SKELETON.DAMAGE
	const HEALTH = SKELETON.HEALTH * 2
	const SCORE = LOBBER.SCORE    # Because of complex movement

# Zombies are slow, tough, but do small melee damage
class ZOMBIE:
	const SPEED = GHOST.SPEED * 0.5
	const DAMAGE = GHOST.DAMAGE * 2
	const HEALTH = GHOST.HEALTH * 4
	const SCORE = LOBBER.SCORE * 2    # Because they are so tough

# We are not actually using fire wraith or reaper yet
# Will later add a devil, vampire, frankenstein, others.
class FIRE_WRAITH:
	const SPEED = 60.0
	const DAMAGE = 3
	const HEALTH = 2
	const SCORE = 1

class REAPER:
	const SPEED = 50.0
	const DAMAGE = 3
	const HEALTH = 999
	const SCORE = 1

class PLAYER:
	const SPEED = GHOST.SPEED * 1.25
	const DAMAGE = 2
	const HEALTH = 50
	const BULLET_SPEED = 250
	const BULLET_DAMAGE = 1
	const BULLET_HEALTH = 1
	const BULLET_LIFESPAN = 1.5 # seconds
	const BULLET_BASE_FIRE_RATE = 0.2
	const BULLET_BASE_MAX_SHOTS = 3

class BARREL:
	const HEALTH = 20
	const DAMAGE = BARREL.HEALTH


# Some properties are not in here because they don't seem like leveling choices
# We didn't put Gem properties in here
# We didn't put Nova properties in here
