/*
 * adc.h
 *
 * Created: 4/14/2026 1:27:31 PM
 *  Author: Joaquín Calderón
 */ 

#ifndef LIBRERIA_ADC_H
#define LIBRERIA_ADC_H

#include <stdint.h>

void setup_adc(void);
void adc_set_channel(uint8_t channel);

#endif