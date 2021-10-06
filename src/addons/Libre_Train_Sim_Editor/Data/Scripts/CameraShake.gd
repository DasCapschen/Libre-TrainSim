class_name CameraShake
extends Resource

export(float) var intensity = 1.0 # multiplier

# use only 1 or 0 ; which axes should be affected
export(Vector3) var affected_translation_axes = Vector3(1,1,1) # x, y, z
export(Vector3) var affected_rotation_axes = Vector3(0,0,1) # pitch, yaw, roll


enum DurationType { DURATION, DECAY, FOREVER }
export(DurationType) var duration_type = DurationType.DURATION

export(float) var duration = 1.0 # how long the shake should last
export(float, 0.0, 1.0) var decay = 0.2 # intensity = intensity * decay


# Type of shake
# Random is very shaky, not smooth at all
# Sine is extremely smooth
# Noise is shaky, but smooth
enum ShakeType { RANDOM, SINE, NOISE }
export(ShakeType) var shake_type = ShakeType.SINE

# only used if type = Noise
export(OpenSimplexNoise) var simplex_noise

# only used if type = Sine
export(Vector3) var sine_translation_multiplier = Vector3(1,1,1)
export(Vector3) var sine_rotation_multiplier = Vector3(1,1,1)
export(Vector3) var sine_phase_shift_degrees = Vector3(0, 90, 0)

