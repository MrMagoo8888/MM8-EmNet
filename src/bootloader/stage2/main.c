#include "graphics.h"

void bootloadMain(unsigned char bootDrive) {

    draw_pixel(100, 100, 0x000000FF);



    __asm__ volatile("hlt");
}