/*
 * PWM.h
 *
 * Created: 4/14/2026 1:11:25 PM
 *  Author: Joaquín Calderón
 */ 


#ifndef LIBRERIA_TIMER1PWM_H
#define LIBRERIA_TIMER1PWM_H

#include <stdint.h>

void init_timer1(void);
void Set_Servo_T1(uint8_t value);
void Set_Servo2_T1(uint8_t value);

#endif