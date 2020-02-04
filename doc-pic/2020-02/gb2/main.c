#include <gb/gb.h>
#include <stdio.h>
#include "mario.c"


void main()
{
    SPRITES_8x16;
    set_sprite_data(0, 20, mario);
    set_sprite_tile(0, 0);
    move_sprite(0, 20, 20);
    set_sprite_tile(1, 2);
    move_sprite(1,20+8, 20);
    SHOW_SPRITES;
    while (1)
    {
        if(joypad()==J_RIGHT)
        {
            scroll_sprite(0, 2, 0);
            scroll_sprite(1, 2, 0);
        }
        if(joypad()==J_LEFT)
        {
            scroll_sprite(0, -2, 0);
            scroll_sprite(1, -2, 0);
        }
        delay(50);
    }
    
}
