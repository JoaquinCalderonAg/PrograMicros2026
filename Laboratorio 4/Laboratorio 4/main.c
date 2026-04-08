/*
 * Laboratorio 4.c
 *
 * Created: 4/7/2026 5:18:57 PM
 * Author : Joaquin Calderón
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <stdint.h>
#include <avr/interrupt.h>


volatile uint8_t CONTADOR = 0;

/****************************************/
// Function prototypes
void setup();
void initADC();
/****************************************/
// Main Function
int main(void)
{
	cli();
	setup();
	initADC();
	// ======================================
	// CONFIGURAR PINCHANGE PORTB
	// ======================================	
	PCICR  |= (1<<PCIE0);
	PCMSK0 |= (1<<PCINT0)|(1<<PCINT1);

	
	sei();
	
	while (1)
	{
		PORTD = CONTADOR;
	}
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	// ======================================
	// Prescaler de 16MHz a 1MHz
	// ======================================	
	CLKPR =(1<<CLKPCE);
	CLKPR =(1<<CLKPS2);
	
	// ======================================
	// CONFIGURACION DEL PUERTO B
	// ======================================
	DDRB   = 0x00;
	PORTB  = 0b00000011;	
	
	// ======================================
	// CONFIGURACION DEL PUERTO D
	// ======================================	
	DDRD   = 0xFF;
	PORTD  = 0x00;
	UCSR0B = 0x00;    // YA PUEDO USAR PD0 Y PD1
	
}

void initADC()
{
	
}

/****************************************/
// Interrupt routines
ISR(PCINT0_vect)
{
	// =========================
	// BOTON PB0 (INCREMENTO)
	// =========================
	if (!(PINB & (1<<PINB0)))			// Presionado
	{
		CONTADOR++;

		// ANTIRREBOTE CON WHILE
		while (!(PINB & (1<<PINB0)));   // Espera a que suelte
	}

	// =========================
	// BOTON PB1 (DECREMENTO)
	// =========================
	if (!(PINB & (1<<PINB1)))
	{
		CONTADOR--;

		// ANTIRREBOTE
		while (!(PINB & (1<<PINB1)));
	}
}
