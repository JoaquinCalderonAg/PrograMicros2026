/*
 * Laboratorio 5.c
 *
 * Created: 4/14/2026 1:10:02 PM
 * Author : Joaquín Calderón
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "PWM/adc.h"
#include "PWM/pwm.h"

// ======================================
// VARIABLES GLOBALES
// ======================================
volatile uint8_t Canal_Actual = 0;
static uint8_t Pin_PWM = PD3;

// ======================================
// PROTOTIPOS
// ======================================
void init_timer0(void);
void init_Timer2(void);
void timer2_set_pwm(uint8_t duty);

// ======================================
// MAIN
// ======================================
int main(void)
{
    cli();

    setup_adc();               // ADC
    init_timer0();             // Trigger ADC
    init_timer1();             // PWM servos
    init_Timer2();  // PWM LED

    sei();

    while (1)
    {
        // Todo ocurre en interrupciones
    }

    return 0;
}

// ======================================
// TIMER0 - DISPARA ADC
// ======================================
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

// ======================================
// TIMER2 - PWM MANUAL LED
// ======================================
void init_Timer2(void)
{
    TCCR2A = 0;
    TCCR2B = 0;

    // Prescaler 8
    TCCR2B |= (1 << CS21);

    // Interrupciones
    TIMSK2 |= (1 << TOIE2) | (1 << OCIE2A);

    // PD3 salida
    DDRD |= (1 << Pin_PWM);

    PORTD &= ~(1 << Pin_PWM);

    OCR2A = 0;
}

void timer2_set_pwm(uint8_t duty)
{
    OCR2A = duty;
}

// ======================================
// ISR TIMER0
// ======================================
ISR(TIMER0_OVF_vect)
{
    TCNT0 = 0;
    ADCSRA |= (1 << ADSC);
}

// ======================================
// ISR ADC (3 CANALES)
// ======================================
ISR(ADC_vect)
{
    uint8_t lectura = ADCH;

    switch (Canal_Actual)
    {
        case 0:
            Set_Servo_T1(lectura);
            Canal_Actual = 1;
            adc_set_channel(1);
            break;

        case 1:
            Set_Servo2_T1(lectura);
            Canal_Actual = 2;
            adc_set_channel(2);
            break;

        case 2:
            timer2_set_pwm(lectura);
            Canal_Actual = 0;
            adc_set_channel(0);
            break;
    }
}

// ======================================
// TIMER2 - INICIO PWM
// ======================================
ISR(TIMER2_OVF_vect)
{
    PORTD |= (1 << Pin_PWM);
}

// ======================================
// TIMER2 - FIN PWM
// ======================================
ISR(TIMER2_COMPA_vect)
{
    PORTD &= ~(1 << Pin_PWM);
}