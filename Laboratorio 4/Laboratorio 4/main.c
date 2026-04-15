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
volatile uint8_t CONTADOR_DISP = 0;
volatile uint8_t ADC_val = 0;
volatile uint8_t PORTB_leds = 0;


/****************************************/
// Function prototypes
void setup();
void initADC();
//ánodo común
const uint8_t tabla[16] = {
	0x40,
	0x79,
	0x24,
	0x30,
	0x19,
	0x12,
	0x02,
	0x78,
	0x00,
	0x10,
	0x08,
	0x03,
	0x46,
	0x21,
	0x06,
	0x0E
};
/****************************************/
// Main Function
int main(void)
{
	cli();
	setup();
	initADC();
	// ======================================
	// CONFIGURAR PINCHANGE PORTC
	// ======================================	
	PCICR  |= (1<<PCIE1);
	PCMSK1 |= (1<<PCINT12)|(1<<PCINT13);

	// ======================================
	// HABILITAR INTERRUPCION ADC
	// ======================================
	ADCSRA  |= (1<<ADIE);
	ADCSRA	|= (1<<ADSC);		// INICIAR ADC
	
	// ======================================
	// HABILITAR INTERRUPCION TIMER0
	// ======================================
	TIMSK0 |= (1<<TOIE0);

		
	sei();
	
	while (1)
	{
		// LEDs contador
		//PORTB = (PORTB & 0xF0) | (CONTADOR & 0x0F);
		PORTB_leds = (CONTADOR & 0x0F);
		PORTC = (PORTC & 0xF0) | ((CONTADOR >> 4) & 0x0F);
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
	DDRB   = 0b00111111;					// El primer nible para los primeros leds del contador y PB4(Dígito 1/ izquierda) PB5(dígito 2/ derecha)
	PORTB  = 0b00000000;		
	
	// ======================================
	// CONFIGURACION DEL PUERTO D
	// ======================================	
	DDRD   = 0xFF;							// Todo portD para display y PD7 para led de comparación. 
	PORTD  = 0x00;
	UCSR0B = 0x00;							// YA PUEDO USAR PD0 Y PD1

	// ======================================
	// CONFIGURACION DEL PUERTO C
	// ======================================
	DDRC   = 0b00001111;					// El primer nible es para el nible alto del contador. PC4 botón incremento, PC5 botón decremento. 
	PORTC  = 0b00110000;
	
	// ======================================
	// CONFIGURACION DEL TIMER0
	// ======================================
	TCCR0A = 0x00;    //; MODO NORMAL
	TCCR0B |= (1<<CS01)|(1<<CS00);	//; prescaler 64
	TCNT0	= 240;		
	TIFR0  |= (1<<TOV0);
}

void initADC()
{
	// BORRAR ADMUX
	ADMUX	= 0;
	ADMUX	|= (1<<REFS0)|(1<<ADLAR)|(1<<MUX0)|(1<<MUX1)|(1<<MUX2);
	
	// BORRAR ADCSRA
	ADCSRA	=0;
	ADCSRA	|= (1<<ADEN)|(1<<ADPS0)|(1<<ADPS1);			// Habilito el ADC y le pongo un prescaler de 8
	
	
}

/****************************************/
// Interrupt routines
ISR(PCINT1_vect)
{
	// =========================
	// BOTON PC4 (INCREMENTO)
	// =========================
	if (!(PINC & (1<<PINC4)))			// Presionado
	{
		CONTADOR++;

		// ANTIRREBOTE CON WHILE
		while (!(PINC & (1<<PINC4)));   // Espera a que suelte
	}

	// =========================
	// BOTON PB5 (DECREMENTO)
	// =========================
	if (!(PINC & (1<<PINC5)))
	{
		CONTADOR--;

		// ANTIRREBOTE
		while (!(PINC & (1<<PINC5)));
	}
}

ISR(ADC_vect)
{

	ADC_val = ADCH; 
	ADCSRA |= (1<<ADSC); // reiniciar
	
}

	
ISR(TIMER0_OVF_vect)
{
	static uint8_t mux = 0;

	TCNT0 = 240;

	uint8_t salida = (PORTB_leds & 0x0F);

	// apagar displays
	salida |= (1<<PB4) | (1<<PB5);

	uint8_t high = (ADC_val >> 4) & 0x0F;
	uint8_t low  = ADC_val & 0x0F;

	uint8_t display;

	if (mux == 0)
	{
		display = tabla[high];
		salida &= ~(1<<PB4);
	}
	else
	{
		display = tabla[low];
		salida &= ~(1<<PB5);
	}

	// =========================
	// COMPARACIÓN POST-LAB
	// =========================
	if (ADC_val == CONTADOR)
	{
		display |= (1<<PD7);    // ENCENDER LED
	}
	else
	{
		display &= ~(1<<PD7);   // APAGAR LED
	}

	PORTD = display;
	PORTB = salida;

	mux ^= 1;
}