/*
 * Laboratorio 6.c
 *
 * Created: 4/22/2026 12:56:54 AM
 * Author : Joaquín Calderón
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "Librerias/ADC.h"
#include "Librerias/USART.h"

typedef enum
{
	APP_MENU = 0,
	APP_WAIT_ASCII
} app_state_t;

static void Outputs_Init(void)
{
	DDRB = 0x3F;
	PORTB = 0x00;

	DDRC |= (1 << PC0) | (1 << PC1);
	DDRC &= ~(1 << PC2);
	PORTC &= (uint8_t)~((1 << PC0) | (1 << PC1));
}

static void DisplayAsciiOnLeds(uint8_t value)
{
	PORTB = value & 0x3F;
	PORTC = (PORTC & 0xFC) | ((value >> 6) & 0x03);
}

static void SendPotMessage(uint16_t value)
{
	while (!USART_SendString("ADC A2: "))
	{
	}

	while (!USART_SendUnsigned16(value))
	{
	}

	while (!USART_SendString("\r\n"))
	{
	}
}

static void SendText(const char *text)
{
	while (*text != '\0')
	{
		while (!USART_SendChar(*text))
		{
		}
		text++;
	}
}

static void SendUnsignedValue(uint16_t value)
{
	while (!USART_SendUnsigned16(value))
	{
	}
}

static void ShowMainMenu(void)
{
	SendText("\r\nMenu principal\r\n");
	SendText("1. No hacer nada\r\n");
	SendText("2. Mostrar ASCII de un caracter en LEDs\r\n");
	SendText("3. Mostrar valor del potenciometro\r\n");
	SendText("Seleccione una opcion: ");
}

int main(void)
{
	char received_char;
	uint16_t adc_value;
	app_state_t app_state;

	Outputs_Init();
	DisplayAsciiOnLeds(0);
	ADC_Init();
	USART_Init(9600);
	sei();

	app_state = APP_MENU;

	SendText("Laboratorio 6 UART + ADC listo\r\n");
	SendText("Potenciometro en A2\r\n");
	ShowMainMenu();

	while (1)
	{
		if (USART_ReadChar(&received_char))
		{
			if ((received_char == '\r') || (received_char == '\n'))
			{
				continue;
			}

			if (app_state == APP_WAIT_ASCII)
			{
				DisplayAsciiOnLeds((uint8_t)received_char);

				SendText("\r\nCaracter recibido: ");
				while (!USART_SendChar(received_char))
				{
				}
				SendText("\r\nValor decimal: ");
				SendUnsignedValue((uint8_t)received_char);
				SendText("\r\n");

				app_state = APP_MENU;
				ShowMainMenu();
			}
			else
			{
				switch (received_char)
				{
					case '1':
					DisplayAsciiOnLeds(0);
					SendText("\r\nMenu principal\r\n");
					ShowMainMenu();
					break;

					case '2':
					SendText("\r\nIngrese un caracter: ");
					app_state = APP_WAIT_ASCII;
					break;

					case '3':
					adc_value = ADC_Read(2);
					SendText("\r\n");
					SendPotMessage(adc_value);
					ShowMainMenu();
					break;

					default:
					SendText("\r\nOpcion invalida\r\n");
					ShowMainMenu();
					break;
				}
			}
		}
		_delay_ms(10);
	}
}



