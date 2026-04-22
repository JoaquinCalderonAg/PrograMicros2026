/*
 * USART.c
 *
 * Created: 4/22/2026 8:00:21 AM
 *  Author: Joaquín Calderón 
 */ 

#define F_CPU 16000000UL

#include "USART.h"
#include <avr/interrupt.h>

static volatile char rx_buffer[USART_RX_BUFFER_SIZE];
static volatile uint8_t rx_head = 0;
static volatile uint8_t rx_tail = 0;

static volatile char tx_buffer[USART_TX_BUFFER_SIZE];
static volatile uint8_t tx_head = 0;
static volatile uint8_t tx_tail = 0;

void USART_Init(unsigned long baudrate)
{
	uint16_t ubrr;

	ubrr = (uint16_t)((F_CPU / (16UL * baudrate)) - 1UL);

	UBRR0H = (uint8_t)(ubrr >> 8);
	UBRR0L = (uint8_t)ubrr;

	UCSR0A = 0x00;
	UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

uint8_t USART_Available(void)
{
	return (rx_head != rx_tail);
}

uint8_t USART_ReadChar(char *data)
{
	if (rx_head == rx_tail)
	{
		return 0;
	}

	*data = rx_buffer[rx_tail];
	rx_tail = (uint8_t)((rx_tail + 1U) % USART_RX_BUFFER_SIZE);

	return 1;
}

uint8_t USART_SendChar(char data)
{
	uint8_t next_head;

	next_head = (uint8_t)((tx_head + 1U) % USART_TX_BUFFER_SIZE);

	if (next_head == tx_tail)
	{
		return 0;
	}

	tx_buffer[tx_head] = data;
	tx_head = next_head;

	UCSR0B |= (1 << UDRIE0);

	return 1;
}

uint8_t USART_SendString(const char *str)
{
	while (*str != '\0')
	{
		if (!USART_SendChar(*str))
		{
			return 0;
		}
		str++;
	}

	return 1;
}

uint8_t USART_SendUnsigned16(uint16_t value)
{
	char digits[5];
	uint8_t count = 0;

	if (value == 0U)
	{
		return USART_SendChar('0');
	}

	while ((value > 0U) && (count < sizeof(digits)))
	{
		digits[count] = (char)('0' + (value % 10U));
		value /= 10U;
		count++;
	}

	while (count > 0U)
	{
		count--;
		if (!USART_SendChar(digits[count]))
		{
			return 0;
		}
	}

	return 1;
}

ISR(USART_RX_vect)
{
	uint8_t next_head;
	char data;

	data = (char)UDR0;
	next_head = (uint8_t)((rx_head + 1U) % USART_RX_BUFFER_SIZE);

	if (next_head != rx_tail)
	{
		rx_buffer[rx_head] = data;
		rx_head = next_head;
	}
}

ISR(USART_UDRE_vect)
{
	if (tx_head == tx_tail)
	{
		UCSR0B &= ~(1 << UDRIE0);
	}
	else
	{
		UDR0 = tx_buffer[tx_tail];
		tx_tail = (uint8_t)((tx_tail + 1U) % USART_TX_BUFFER_SIZE);
	}
}
