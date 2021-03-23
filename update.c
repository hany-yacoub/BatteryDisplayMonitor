//Hany Yacoub
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "battery.h"

//Uncomment methods and comment in update_asm.s to compile in hybrid

// Uses the two global variables (ports) BATT_VOLTAGE_PORT and
// BATT_STATUS_PORT to set the fields of the parameter 'batt'.  If
// BATT_VOLTAGE_PORT is negative, then battery has been wired wrong;
// no fields of 'batt' are changed and 1 is returned to indicate an
// error.  Otherwise, sets fields of batt based on reading the voltage
// value and converting to precent using the provided formula. Returns
// 0 on a successful execution with no errors. This function DOES NOT
// modify any global variables but may access global variables.
//
// CONSTRAINT: Uses only integer operations. No floating point
// operations are used as the target machine does not have a FPU.
// 

// int set_batt_from_ports(batt_t *batt){
//     if (BATT_VOLTAGE_PORT < 0) { 
//         return 1; 
//     }

//     batt->mlvolts = BATT_VOLTAGE_PORT / 2;
    
//     if (batt->mlvolts < 3000) { 
//         batt->percent = 0;
//     } else if (batt->mlvolts > 3800) {
//         batt->percent = 100;
//     } else {
//         batt->percent = (batt->mlvolts - 3000) / 8;
//     }

    
//     if (BATT_STATUS_PORT & 0b0100){ //if bit at index 2 is set
//         batt->mode = 2; //percent mode
//     } else { 
//         batt->mode = 1; //volt mode
//     }

//     return 0;
// }


// Alters the bits of integer pointed to by 'display' to reflect the
// data in struct param 'batt'.  Does not assume any specific bit
// pattern stored at 'display' and completely resets all bits in it on
// successfully completing.  Selects either to show Volts (mode=1) or
// Percent (mode=2). If Volts are displayed, only displays 3 digits
// rounding the lowest digit up or down appropriate to the last digit.
// Calculates each digit to display changes bits at 'display' to show
// the volts/percent according to the pattern for each digit. Modifies
// additional bits to show a decimal place for volts and a 'V' or '%'
// indicator appropriate to the mode. In both modes, places bars in
// the level display as indicated by percentage cutoffs in provided
// diagrams. This function DOES NOT modify any global variables but
// may access global variables. Always returns 0.
// 

// int set_display_from_batt(batt_t batt, int *display){
//     if (batt.mode != 1 && batt.mode != 2){
//         return 1;
//     }
//     int masks[] = {0b0111111, 
//                     0b0000110, 
//                     0b1011011, 
//                     0b1001111, 
//                     0b1100110, 
//                     0b1101101,
//                     0b1111101,
//                     0b0000111,
//                     0b1111111,
//                     0b1101111,
//     };

//     *display = 0;
//     int fstD, sndD, thdD, fthD;

//     if (batt.mode == 1){ //volt mode

//         *display = *display | (1 << 22); //turns Volt indicator on
//         *display = *display & ~(1 << 21); //turns Percent indicator off
//         *display = *display | (1 << 23); //turns decimal sign on

//         fstD = batt.mlvolts / 1000; //Finds individual digits
//         sndD = batt.mlvolts / 100 % 10;
//         thdD = batt.mlvolts / 10 % 10;
//         fthD = batt.mlvolts % 10;
        
//         if (fthD >= 5) { thdD++; } //Rounds third digit if fourth digit >= 5.

//     } else { //percent mode
//         *display = *display & ~(1 << 22); //turns Volt indicator off
//         *display = *display | (1 << 21); //turns Percent indicator on
//         *display = *display & ~(1 << 23); //turns decimal sign off

//         fstD = batt.percent / 100; //Finds individual digits
//         sndD = batt.percent / 10 % 10;
//         thdD = batt.percent % 10; 
//     }

//     if (batt.mode == 2 && fstD == 0){ //Sets first digit's representation based on <100 percent or 100percent/volt mode
//         *display = *display | (0b0000000 << 14);
//     } else {
//         *display = *display | (masks[fstD] << 14); 
//     }

//     if (batt.mode == 2 && fstD == 0 && sndD == 0){ //Sets second digit's representation based on <100 percent and <10 percent or 100percent/volt mode
//         *display = *display | (0b0000000 << 7); 
//     } else {
//         *display = *display | (masks[sndD] << 7); 
//     }
    
//     *display = *display | (masks[thdD] << 0); //Sets third digit's representation
    
//     if (batt.percent >= 5){ *display = *display | (1 << 24); } else { *display = *display & ~(1 << 24); } //Sets percent bar representation
//     if (batt.percent >= 30){ *display = *display | (1 << 25); } else { *display = *display & ~(1 << 25); }
//     if (batt.percent >= 50){ *display = *display | (1 << 26); } else { *display = *display & ~(1 << 26); }
//     if (batt.percent >= 70){ *display = *display | (1 << 27); } else { *display = *display & ~(1 << 27); }
//     if (batt.percent >= 90){ *display = *display | (1 << 28); } else { *display = *display & ~(1 << 28); }
    
//     return 0;
// }

// Called to update the battery meter display.  Makes use of
// set_batt_from_ports() and set_display_from_batt() to access battery
// voltage sensor then set the display. Checks these functions and if
// they indicate an error, does NOT change the display.  If functions
// succeed, modifies BATT_DISPLAY_PORT to show current battery level.
// 
// CONSTRAINT: Does not allocate any heap memory as malloc() is NOT
// available on the target microcontroller.  Uses stack and global
// memory only.
// int batt_update(){
//     batt_t batt1;
//     if (set_batt_from_ports(&batt1)){ 
//         return 1; 
//     }
//     set_display_from_batt(batt1, &BATT_DISPLAY_PORT);
//     return 0;    
// }

