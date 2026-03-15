;
; Proyecto 1.asm
;
; Created: 3/4/2026 4:38:00 PM
; Author : Joaquin Calderón
; Descripción: Proyecto 1 progra de micros

/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.equ T1VALUE			= 0xC2F7
.equ T0VALUE			= 134
.equ Max_Mode			= 6
.def MODE				= R30
.def ACTION				= R29
.def CONTADOR_SEG		= R28
.def CONTADOR_MIN		= R27
.def CONTADOR_MES		= R26
.def CONTADOR_YEAR		= R25
.def BANDERA_SEG				= R24

						

//.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
RJMP START

// CALLS A LAS INTERRUPCIONES
.org PCI0addr								; Atiendo la interrupción para los pines del portB (botones)
RJMP BOTON_INC_ISR							  
											  
.org PCI1addr								; Atiendo la interrupción para los pines del portC (botones)
RJMP BOTONES_ISR							  
											  
.org OVF1addr								; Atiendo la interrupción para el timer 1 (overflow)
RJMP OverflowT1_ISR							  
											  
.org OVF0addr								; Atiendo la interrupción para el timer 0 (overflow)
RJMP OverflowT0_ISR


 /****************************************/
// Configuración de la pila

START:
CLI

LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:

; ======================================
; CONFIGURAR OSCILADOR A 1MHZ
; ======================================
LDI R16, (1<<CLKPCE)						; Habilito la posibilidad de cambiar el oscilador
STS CLKPR, R16								; aquí escribo el valor en el registro CLKPR

LDI R16, 0b0000_0100						; Configuro el prescaler a 16 (16MHz/16 = 1MHz)
STS CLKPR, R16								; Escribo ese valor en el registro CLKPR y con eso ya cambié el oscilador.
// 


; ======================================
; USAR PD0 Y PD1
; ======================================
LDI R16, 0x00
STS UCSR0B, R16

; ======================================
; CONFIGURAR PORTB
; ======================================

LDI R16, 0b00011111							; [0]Digito medio izquierda, [1]Digito medio derecha, [2]No tengo nada aun, [3]Digito extremo derecha, [4]Leds 2 puntos, [5]Boton Incremento
OUT DDRB, R16								 
LDI R16, 0b00100000							; Configuro pullUp y leds apagadas
OUT PORTB, R16

; ======================================
; CONFIGURAR PORTC
; ======================================

LDI R16, 0b00000011							; [0]Led verde (fecha), [1]Led azul (hora), [2]Boton Decremento, [3]Boton Modo, [4]Boton Confirmar Configuracion, [5]Boton Eleccion de digitos
OUT DDRC, R16								 
LDI R16, 0b11111100							; Configuro pullUp y leds apagadas
OUT PORTC, R16

; ======================================
; CONFIGURAR PORTD
; ======================================

LDI R16, 0xFF								; [6:0] Display 7 seg, [7] Digito extremo izquierdo
OUT DDRD, R16								 
LDI R16, 0x00								; Todo empieza apagado
OUT PORTD, R16

////////////////////////////////
//configurar interrupciones: MASCARAS
////////////////////////////////

; ======================================
; CONFIGURAR MASCARA - TIMER0
; ======================================
LDI R16, (1<<TOIE0)							; habilito interrupción del overflow Timer0
STS TIMSK0, R16

; ======================================
; CONFIGURAR MASCARA - TIMER1
; ======================================
LDI R16, (1<<TOIE1)							; habilito interrupción del overflow Timer 1
STS TIMSK1, R16

; ======================================
; CONFIGURAR PINCHANGE PORTB
; ======================================

LDI R16, (1<<PCIE0)							; habilito interrupcion del pin change PORTB
STS PCICR, R16
LDI R16, (1<<PCINT5)						; habilita interrupcion para el pin PB5
STS PCMSK0, R16

; ======================================
; CONFIGURAR PINCHANGE PORTC
; ======================================
LDI R16, (1<<PCIE1)															; habilito interrupcion del pin change PORTC
STS PCICR, R16
LDI R16, (1<<PCINT10)|(1<<PCINT11)|(1<<PCINT12)|(1<<PCINT13)				; habilita interrupcion para el pin PC2, PC3, PC4 y PC5
STS PCMSK1, R16

; ======================================
; CONFIGURAR TIMER0
; ======================================

LDI R16, 0x00								; MODO NORMAL
OUT TCCR0A, R16

LDI R16, (1<<CS02)|(1<<CS00)				; prescaler 1024
OUT TCCR0B, R16

LDI R16, T0VALUE							; Empieza a contar desde T0VALUE
OUT TCNT0, R16

LDI R16, (1<<TOV0)							; limpiar bandera overflow
OUT TIFR0, R16

; ======================================
; CONFIGURAR TIMER1
; ======================================

LDI R16, 0x00								; MODO NORMAL
STS TCCR1A, R16								

LDI R16, (1<<CS11)|(1<<CS10)				; prescaler 64
STS TCCR1B, R16

LDI R16, HIGH(T1VALUE)						; Empieza a contar desde T1VALUE
STS TCNT1H, R16		
LDI R16, LOW(T1VALUE)
STS TCNT1L, R16

; ======================================
; CONFIGURAR TABLAS DE 7 SEGMENTOS
; ======================================
Table7seg:
.db 0x40, 0x79, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E

; ======================================
; CLEAR DE MIS REGISTROS
; ======================================

CLR MODE								   ; Aquí guardo el modo en el que estoy
CLR ACTION								   ; Aquí guardo mi bandera de Acción
CLR CONTADOR_SEG						   ; Aquí guardo mi contador de SEGUNDOS
CLR CONTADOR_MIN						   ; Aquí guardo mi contador de MINUTOS
CLR CONTADOR_MES						   ; Aquí guardo mi contador de MESES
CLR CONTADOR_YEAR						   ; Aquí guardo mi contador de AÑOS
CLR R24									   ; 
CLR R23									   ; 
CLR R22									   ; 
CLR R21									   ; 
CLR R20									   ; 
CLR R19									   ; 
CLR R18									   ; 
CLR R17									   ; 
CLR R16									   ; 

											 
// ACTIVO INTERRUPCIONES GLOBALES
SEI
/********************************************************************************/
// Loop Infinito
/********************************************************************************/
MAIN_LOOP:

; ======================================
; COMPRUEBO EN QUÉ MODO ESTOY
; ======================================	

CPI		BANDERA_SEG, 1
BREQ	INCREMENTO_1S

CPI		MODE, 0
BREQ	MUESTRA_RELOJ

CPI		MODE, 1
BREQ	MUESTRA_FECHA

CPI		MODE, 2
BREQ	CONFI_RELOJ

CPI		MODE, 3
BREQ	CONFI_FECHA

CPI		MODE, 4
BREQ	CONFI_ALARMA


    RJMP    MAIN_LOOP
; ======================================
; REALIZO LA ACCIÓN DEL CONTEO DE SEGUNDOS
; ======================================
INCREMENTO_1S:
CPI		BANDERA_SEG, 0x01
BRNE	FIN_INC

INC		CONTADOR_SEG
ANDI	CONTADOR_SEG, 0x0F

CPI		CONTADOR_SEG, 59
BRNE	FIN_INC
CLR		CONTADOR_SEG






FIN_INC:
CLR BANDERA_SEG
	RJMP MAIN_LOOP


; ======================================
; REALIZO LA ACCIÓN DEL MODO 1, MOSTRAR LA HORA
; ======================================
MUESTRA_RELOJ:

	RJMP MAIN_LOOP

; ======================================
; REALIZO LA ACCIÓN DEL MODO 2, MOSTRAR LA FECHA
; ======================================
MUESTRA_FECHA:

	RJMP MAIN_LOOP

; ======================================
; REALIZO LA ACCIÓN DEL MODO 3,  CONFIGURAR RELOJ
; ======================================
CONFI_RELOJ:

	RJMP MAIN_LOOP

; ======================================
; REALIZO LA ACCIÓN DEL MODO 4, MOSTRAR LA FECHA
; ======================================
CONFI_FECHA:

	RJMP MAIN_LOOP

; ======================================
; REALIZO LA ACCIÓN DEL MODO 5, MOSTRAR LA FECHA
; ======================================
CONFI_ALARMA:

	RJMP MAIN_LOOP
/********************************************************************************/
// NON-Interrupt subroutines
/********************************************************************************/


/********************************************************************************/
// Interrupt routines
/********************************************************************************/
; ======================================
; INTERRUPCIÓN PRESIONAR BOTÓN INCREMENTO EN PORTB
; ======================================
BOTON_INC_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16




POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI

; ======================================
; INTERRUPCIÓN PRESIONAR UN BOTÓN EN PORTC
; ======================================
BOTONES_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16



POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI

; ======================================
; INTERRUPCIÓN OVERFLOW TIMER 1
; ======================================
OverflowT1_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16

LDI R16, HIGH(T1VALUE)						; Empieza a contar desde T1VALUE
STS TCNT1H, R16		
LDI R16, LOW(T1VALUE)
STS TCNT1L, R16



POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI

; ======================================
; INTERRUPCIÓN OVERFLOW TIMER 0
; ======================================
OverflowT0_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16

LDI R16, T0VALUE							; Empieza a contar desde T0VALUE
OUT TCNT0, R16


POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI
/****************************************/