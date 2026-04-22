/*
 * Laboratorio 5.c
 *
 * Created: 4/14/2026 1:10:02 PM
 * Author : Joaquín Calderón
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "PWM/PWMT1.h"
#include "PWM/adc.h"
#include "PWM/PWMT2.h"


// VARIABLES GLOBALES
volatile uint8_t adc_Actual = 0;


// PROTOTIPOS
void init_timer0(void);


// MAIN
int main(void)
{
    cli();

    setup_adc();          
    init_timer0();        
    init_timer1();        
    init_timer2_all();    

    sei();

    while (1)
    {
        
    }

    return 0;
}

// ISR ADC (3 CANALES)
ISR(ADC_vect)
{
    uint8_t lectura = ADCH;

    switch (adc_Actual)
    {
        case 0:
            TIMER1_PWM1_set_servo_PW(lectura); 
            adc_Actual = 1;
            adc_set_channel(1);
            break;

        case 1:
            timer2_set_servo2(lectura);        
            adc_Actual = 2;
            adc_set_channel(2);
            break;

        case 2:
            timer2_set_led(lectura);           
            adc_Actual = 0;
            adc_set_channel(0);
            break;
    }
}

// TIMER0 - ADC
void init_timer0(void)
{
    TCCR0A = 0;
    TCCR0B = 0;

    // Prescaler 64
    TCCR0B |= (1 << CS01) | (1 << CS00);

    TCNT0 = 0;

    // Interrupt overflow
    TIMSK0 |= (1 << TOIE0);
}

// ISR TIMER0
ISR(TIMER0_OVF_vect)
{
    TCNT0 = 0;
    ADCSRA |= (1 << ADSC);
}

