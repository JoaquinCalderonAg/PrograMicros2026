/*
 * adc.h
 *
 * Created: 4/14/2026 1:27:31 PM
 *  Author: Joaquín Calderón
 */ 

#ifndef adc_H
#define adc_H

#include <stdint.h>

void setup_adc(void);
void adc_set_channel(uint8_t channel);

#endif