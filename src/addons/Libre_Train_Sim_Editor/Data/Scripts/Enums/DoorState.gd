class_name DoorState

enum {
    MOVING = 1, # odd numbers = moving, even numbers = still

    LEFT = 2, # 0b0010
    LEFT_OPENING = LEFT | MOVING, # == 3;  never actually used (yet)

    RIGHT = 4, # 0b0100
    RIGHT_OPENING = RIGHT | MOVING, # == 5; never actually used (yet)

    BOTH = LEFT | RIGHT, # == 6 == 0b0110
    BOTH_OPENING = BOTH | MOVING, # == 7; never actually used (yet)

    CLOSED = 8,
    CLOSING = CLOSED | MOVING # == 9; this one is actually used :)
}

func is_moving(state) -> bool:
    return state & MOVING
