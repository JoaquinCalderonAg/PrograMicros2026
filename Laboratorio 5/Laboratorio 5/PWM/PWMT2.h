/*
 * PWMT2.h
 *
 * Created: 4/14/2026 1:10:02 PM
 * Author : Joaquín Calderón
 */


#ifndef PWMT2_H
#define PWMT2_H

#include <stdint.h>

void init_timer2_all(void);
void timer2_set_servo2(uint8_t value);
void timer2_set_led(uint8_t duty);

#endif