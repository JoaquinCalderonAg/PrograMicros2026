/*
 * PWMT2.c
 *
 * Created: 4/14/2026 1:10:02 PM
 * Author : Joaquín Calderón
 */

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "PWMT2.h"

// VARIABLES GLOBALES
volatile uint16_t servo2_high_ticks = 75;   // 1500 us / 20 us = 75
volatile uint8_t led_duty = 0;

// INICIALIZAR TIMER2
void init_timer2_all(void)
{
	// D11 como salida
	DDRB |= (1 << PB3);
	PORTB &= ~(1 << PB3);

	// D3 como salida
	DDRD |= (1 << PD3);
	PORTD &= ~(1 << PD3);

	TCCR2A = 0;
	TCCR2B = 0;
	TCNT2  = 0;

	// Modo CTC
	TCCR2A |= (1 << WGM21);

	// Prescaler 8
	TCCR2B |= (1 << CS21);

	OCR2A = 39;

	// Interrupción por compare match A
	TIMSK2 |= (1 << OCIE2A);
}


void timer2_set_servo2(uint8_t value)
{
	servo2_high_ticks = 25 + (((uint32_t)value * 100UL) / 255UL);
}

// ======================================
// AJUSTAR LED
// ======================================
void timer2_set_led(uint8_t duty)
{
	led_duty = duty;
}

ISR(TIMER2_COMPA_vect)
{
	static uint16_t servo_tick = 0;
	static uint8_t led_phase = 0;


	if (servo_tick == 0)
	{
		PORTB |= (1 << PB3);   // Iniciar pulso
	}

	if (servo_tick >= servo2_high_ticks)
	{
		PORTB &= ~(1 << PB3);  // Terminar pulso
	}

	servo_tick++;
	if (servo_tick >= 1000)
	{
		servo_tick = 0;
	}

// LED EN D3

	led_phase++;
	if (led_phase < led_duty)
	PORTD |= (1 << PD3);
	else
	PORTD &= ~(1 << PD3);
}