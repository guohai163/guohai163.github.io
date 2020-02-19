#include <gb/gb.h>
#include <stdio.h>
#include "game_role.h"
#include "mario.h"


UINT8 run_index = 0;

//定义角色
struct GameRole role;

const UWORD spritepalette[] = {
    marioCGBPal0c0,
    marioCGBPal0c1,
    marioCGBPal0c2,
    marioCGBPal0c3,

    marioCGBPal1c0,
    marioCGBPal1c1,
    marioCGBPal1c2,
    marioCGBPal1c3,

    marioCGBPal2c0,
    marioCGBPal2c1,
    marioCGBPal2c2,
    marioCGBPal2c3,

    marioCGBPal3c0,
    marioCGBPal3c1,
    marioCGBPal3c2,
    marioCGBPal3c3
};

/**
 * 初始化角色
 */
void initRole(UINT8 x, UINT8 y) 
{
    role.x = 0;
    role.y = 0;
    role.spritrun[0] = 8;
    role.spritrun[1] = 12;
    role.spritrun[2] = 16;
    role.spite_run_status = 0;
    set_sprite_tile(0, role.spritrun[role.spite_run_status]);
    role.spritids[0] = 0;
    set_sprite_prop(0,1);
    set_sprite_tile(1, role.spritrun[role.spite_run_status]+2);
    role.spritids[1] = 1;
    role.direction = 2;
    set_sprite_prop(1,1);
    movegamecharacter(&role,x,y);
    role.x = x;
    role.y = y;
}

void main()
{
    SPRITES_8x16;
    set_sprite_data(0, 20, mario);
    //引入调色板数据
    set_sprite_palette(0, 4, spritepalette);
    initRole(28,112);
    SHOW_SPRITES;
    while (1)
    {
        if(joypad()==J_RIGHT)
        {
            movegamecharacter(&role,role.x+2,role.y);
            role.x +=2;
            
        }
        else if(joypad()==J_LEFT)
        {
            movegamecharacter(&role,role.x-2,role.y);
            role.x -= 2 ;
        }
        else 
        {
            set_sprite_tile(0, 0);
            set_sprite_tile(1, 2);
        }
        delay(80);
    }
    
}
