/*
 * CFile1.c
 *
 * Created: 4/14/2026 1:11:36 PM
 *  Author: Joaquín Calderón
 */ 

#include <avr/io.h>
#include <stdint.h>
#include "PWM.h"

void init_timer1(void)
{
	// PB1 (D9) y PB2 (D10)
	DDRB |= (1 << DDB1) | (1 << DDB2);

	TCCR1A = 0;
	TCCR1B = 0;

	// Fast PWM con ICR1 como TOP
	TCCR1A |= (1 << COM1A1) | (1 << COM1B1);
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12);

	// Prescaler 8
	TCCR1B |= (1 << CS11);

	// 20 ms
	ICR1 = 39999;

	// Centro inicial
	OCR1A = 3000;
	OCR1B = 3000;
}

void Set_Servo_T1(uint8_t value)
{
	uint16_t pulso_us = 500 + (((uint32_t)value * 2000UL) / 255UL);
	OCR1A = pulso_us * 2;
}

void Set_Servo2_T1(uint8_t value)
{
	uint16_t pulso_us = 500 + (((uint32_t)value * 2000UL) / 255UL);
	OCR1B = pulso_us * 2;
}