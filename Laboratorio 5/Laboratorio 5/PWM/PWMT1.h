/*
 * PWMT1.h
 *
 * Created: 4/14/2026 1:11:25 PM
 *  Author: Joaquín Calderón
 */ 

#ifndef PWMT1_H
#define PWMT1_H

#include <stdint.h>

void init_timer1(void);
void TIMER1_PWM1_set_servo_PW(uint8_t value);

#endif