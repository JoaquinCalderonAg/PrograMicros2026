;
; Proyecto 1.asm
;
; Created: 3/4/2026 4:38:00 PM
; Author : Joaquin Calderón
; Descripción: Proyecto 1 progra de micros

// 0xC2F7
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.equ T2VALUE					= 134
.equ T1VALUE					= 0xF9E5
.equ T0VALUE					= 240
.equ Max_Mode					= 5
.def MODE						= R30
.def ACTION						= R29
.def CONTADOR_SEG				= R28
.def CONTADOR_MIN				= R27
.def CONTADOR_MES				= R26
.def CONTADOR_HORA				= R25
.def BANDERA_SEG				= R24
.def DIGITO_ACTIVO				= R23
.def DIG0						= R22
.def DIG1						= R21
.def DIG2						= R20		
.def DIG3						= R19
.def ESTADO_PREVIO_BOTON		= R18

// VARIABLES EN LA RAM
.dseg	
CONTADOR_DIA:					.byte 1
DIAS_MAX:						.byte 1
SELECTOR_DIG:					.byte 1
REBOTE_FLAG:					.byte 1

//.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
RJMP START

// CALLS A LAS INTERRUPCIONES						  					  
			
.org PCI1addr								; Atiendo la interrupción para los pines del portC (botones)
RJMP BOTONES_ISR

.org OVF2addr								; Atiendo la interrupción para el timer 2 (overflow)
RJMP OverflowT2_ISR														  
								  
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

LDI R16, 0b00011111							; [0] Digito extremo izquierdo, [1]Digito medio izquierda, [2]Digito medio derecha, [3]Digito extremo derecha, [4]nada, [5]Dos puntos
OUT DDRB, R16								 
LDI R16, 0b00100000							; Configuro pullUp y leds apagadas
OUT PORTB, R16

; ======================================
; CONFIGURAR PORTC
; ======================================

LDI R16, 0b00000011							; [0]Led verde (fecha), [1]Led azul (hora), [2]Boton cambio de dígitos, [3]Boton Modo, [4]Boton decremento, [5]Botón Incremento
OUT DDRC, R16								 
LDI R16, 0b11111100							; Configuro pullUp y leds apagadas
OUT PORTC, R16

; ======================================
; CONFIGURAR PORTD
; ======================================

LDI R16, 0xFF								; [6:0] Display 7 seg, 
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
; CONFIGURAR MASCARA - TIMER2
; ======================================
LDI R16, (1<<TOIE2)							; habilito interrupción del overflow Timer 2
STS TIMSK2, R16

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

LDI R16, (1<<CS01)|(1<<CS00)				; prescaler 64
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
; CONFIGURAR TIMER2
; ======================================

LDI R16, 0x00								; MODO NORMAL
STS TCCR2A, R16

LDI R16, (1<<CS22)|(1<<CS21)|(1<<CS20)		; prescaler 1024
STS TCCR2B, R16

LDI R16, T2VALUE							; Empieza a contar desde T2VALUE
STS TCNT2, R16

LDI R16, (1<<TOV2)							; limpiar bandera overflow
OUT TIFR2, R16

; ======================================
; CONFIGURAR TABLAS DE 7 SEGMENTOS
; ======================================
Table7seg:
.db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

; ======================================
; CLEAR DE MIS REGISTROS
; ======================================

CLR MODE								   ; Aquí guardo el modo en el que estoy
CLR ACTION								   ; Aquí guardo mi bandera de Acción
CLR CONTADOR_SEG						   ; Aquí guardo mi contador de SEGUNDOS
CLR CONTADOR_MIN						   ; Aquí guardo mi contador de MINUTOS
CLR CONTADOR_MES						   ; Aquí guardo mi contador de MESES
CLR CONTADOR_HORA						   ; Aquí guardo mi contador de HORAS
CLR BANDERA_SEG							   ; Aquí guardo mi bandera del contador de segundos
CLR DIGITO_ACTIVO						   ; Aquí guardo el dígito que activo en el multiplexado 
CLR DIG0 								   ; Aquí guardo mi configuración del dígito 1 del multiplexado 
CLR DIG1								   ; Aquí guardo mi configuración del dígito 2 del multiplexado
CLR	DIG2								   ; Aquí guardo mi configuración del dígito 3 del multiplexado
CLR DIG3								   ; Aquí guardo mi configuración del dígito 4 del multiplexado
CLR ESTADO_PREVIO_BOTON					   ; Aquí guardo el estado original de mis botones
IN  ESTADO_PREVIO_BOTON, PINC
CLR R17									   ; 
CLR R16									   ; 
CLR R0				   
LDI R16, 1
STS CONTADOR_DIA, R16					   ; Aquí guardo mi contador de DIAS					 
CLR R16									   
STS DIAS_MAX, R16						   ; Aquí guardo el máximo de días según el mes.
CLR R16									   
STS SELECTOR_DIG, R16					   ; Aquí guardo el máximo de días según el mes.										    
CLR R16									   
STS REBOTE_FLAG, R16					   ; Aquí guardo el máximo de días según el mes.										    
										    
										    

											 
// ACTIVO INTERRUPCIONES GLOBALES
SEI
/********************************************************************************/
// Loop Infinito
/********************************************************************************/
MAIN_LOOP:

; ======================================
; COMPRUEBO EN QUÉ MODO ESTOY
; ======================================	

CPI BANDERA_SEG,1
BRNE NO_INC
RCALL INCREMENTO_1S

NO_INC:

; ======================================
; CONTROL ANTI REBOTE
; ======================================
LDS R16, REBOTE_FLAG
CPI R16,1
BRNE NO_REBOTE

RCALL DELAY_20MS

CLR R16
STS REBOTE_FLAG,R16

NO_REBOTE:

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
CPI		CONTADOR_SEG, 60
BRNE	FIN_INC
CLR		CONTADOR_SEG

INC		CONTADOR_MIN
CPI		CONTADOR_MIN, 60
BRNE	FIN_INC
CLR		CONTADOR_MIN

INC		CONTADOR_HORA
CPI		CONTADOR_HORA, 24
BRNE	FIN_INC
CLR		CONTADOR_HORA

LDS		R17, CONTADOR_DIA
INC		R17
STS		CONTADOR_DIA, R17
CALL	CALC_MES
LDS		R16, DIAS_MAX
CP		R17, R16
BRNE	FIN_INC
CLR		R17
STS		CONTADOR_DIA, R17

INC		CONTADOR_MES
CPI		CONTADOR_MES, 12
BRNE	FIN_INC
CLR		CONTADOR_MES

FIN_INC:

CLR BANDERA_SEG
RET


; ======================================
; REALIZO LA ACCIÓN DEL MODO 1, MOSTRAR LA HORA
; ======================================
MUESTRA_RELOJ:
	
	CBI PORTC, 0
	SBI PORTC, 1

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA
	
	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 2, MOSTRAR LA FECHA
; ======================================
MUESTRA_FECHA:
	CBI PORTC, 1
	SBI PORTC, 0

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 3,  CONFIGURAR RELOJ
; ======================================
CONFI_RELOJ:
	CBI PORTC, 0
	SBI PORTC, 1

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 4, MOSTRAR LA FECHA
; ======================================
CONFI_FECHA:
	CBI PORTC, 1
	SBI PORTC, 0

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 5, MOSTRAR LA FECHA
; ======================================
CONFI_ALARMA:

	SBI PORTC, 1
	SBI PORTC, 0

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

FIN_ISR_CONTADOR:
//CLR BANDERA_SEG
	RJMP MAIN_LOOP
/********************************************************************************/
// NON-Interrupt subroutines
/********************************************************************************/
; ======================================
; DELAY PARA ANTI REBOTE
; ======================================
DELAY_20MS:
LDI R16, 200
LOOP1:
LDI R17, 200
LOOP2:
DEC R17
BRNE LOOP2
DEC R16
BRNE LOOP1
RET


; ======================================
; Sub rutina Setear mi tabla7seg en 0
; ======================================
SetearZ0:
LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)
RET

; ======================================
; CALCULAR EL MÁXIMO DE DIAS SEGUN EL MES
; ======================================
CALC_MES:
PUSH ZH
PUSH ZL

MOV		R16, CONTADOR_MES

CPI		R16, 0
BREQ	ENERO

CPI		R16, 1
BREQ	FEBRERO

CPI		R16, 2
BREQ	MARZO

CPI		R16, 3
BREQ	ABRIL

CPI		R16, 4
BREQ	MAYO

CPI		R16, 5
BREQ	JUNIO

CPI		R16, 6
BREQ	JULIO

CPI		R16, 7
BREQ	AGOSTO

CPI		R16, 8
BREQ	SEPTIEMBRE

CPI		R16, 9
BREQ	OCTUBRE

CPI		R16, 10
BREQ	NOVIEMBRE

CPI		R16, 11
BREQ	DICIEMBRE

RJMP	FIN_CALC_MES

ENERO:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES		

FEBRERO:
LDI		R16, 29
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

MARZO:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

ABRIL:
LDI		R16, 31
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

MAYO:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

JUNIO:
LDI		R16, 31
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

JULIO:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

AGOSTO:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

SEPTIEMBRE:
LDI		R16, 31
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

OCTUBRE:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

NOVIEMBRE:
LDI		R16, 31
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

DICIEMBRE:
LDI		R16, 32
STS		DIAS_MAX, R16
	RJMP	FIN_CALC_MES

FIN_CALC_MES:
POP ZL
POP ZH
RET	

; ======================================
; SEPARAR DECENAS Y UNIDADES DE LA DERECHA
; ======================================
DIV10_DERECHA:

PUSH ZH
PUSH ZL

MOV		R16, MODE

CPI		R16, 0
BREQ	DIV_MINUTOS

CPI		R16, 1
BREQ	DIV_MES

CPI		R16, 2
BREQ	DIV_MIN_CONFI

CPI		R16, 3
BREQ	DIV_MES_CONFI


CPI		R16, 4
BRNE	SIN_SALTO
RJMP	DIV_MIN_ALARMA
SIN_SALTO:


RJMP FIN_DIV10_DERECHA

// DIVISIÓN POR 10 PARA EL APARTADO DE MINUTOS 
DIV_MINUTOS:
MOV R16, CONTADOR_MIN
CLR R17

DIV_LOOP_DER:
CPI R16,10
BRLO DIV_FIN_DER

SUBI R16,10
INC R17
RJMP DIV_LOOP_DER

DIV_FIN_DER:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG2,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG3,Z
RJMP FIN_DIV10_DERECHA

// DIVISIÓN POR 10 PARA EL APARTADO DE MESES
DIV_MES:
MOV R16, CONTADOR_MES
INC R16
CLR R17

DIV_LOOP_DER_MES:
CPI R16,10
BRLO DIV_FIN_DER_MES

SUBI R16,10
INC R17
RJMP DIV_LOOP_DER_MES

DIV_FIN_DER_MES:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG2,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG3,Z
RJMP FIN_DIV10_DERECHA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE MINUTOS 
DIV_MIN_CONFI:
MOV R16, CONTADOR_MIN
CLR R17

DIV_LOOP_DER_CONFI:
CPI R16,10
BRLO DIV_FIN_DER_CONFI

SUBI R16,10
INC R17
RJMP DIV_LOOP_DER_CONFI

DIV_FIN_DER_CONFI:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG2,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG3,Z
RJMP FIN_DIV10_DERECHA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE MESES
DIV_MES_CONFI:
MOV R16, CONTADOR_MES
INC R16
CLR R17

DIV_LOOP_DER_MES_CONFI:
CPI R16,10
BRLO DIV_FIN_DER_MES_CONFI

SUBI R16,10
INC R17
RJMP DIV_LOOP_DER_MES_CONFI

DIV_FIN_DER_MES_CONFI:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG2,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG3,Z
RJMP FIN_DIV10_DERECHA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE MINUTOS ALARMA
DIV_MIN_ALARMA:
MOV R16, CONTADOR_MIN
CLR R17

DIV_LOOP_ALARMA:
CPI R16,10
BRLO DIV_FIN_ALARMA

SUBI R16,10
INC R17
RJMP DIV_LOOP_ALARMA

DIV_FIN_ALARMA:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG2,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG3,Z
RJMP FIN_DIV10_DERECHA


FIN_DIV10_DERECHA:
POP ZL
POP ZH
RET

; ======================================
; SEPARAR DECENAS Y UNIDADES DE LA IZQUIERDA
; ======================================
DIV10_IZQUIERDA:

PUSH ZH
PUSH ZL

MOV		R16, MODE

CPI		R16, 0
BREQ	DIV_HORA

CPI		R16, 1
BREQ	DIV_DIA

CPI		R16, 2
BREQ	DIV_HORA_CONFI

CPI		R16, 3
BRNE	NO_SALTO
RJMP	DIV_DIA_CONFI
NO_SALTO:

CPI		R16, 4
BRNE	NO_SALTO1
RJMP	DIV_HORA_ALARMA
NO_SALTO1:

	RJMP FIN_DIV10_IZQUIERDA

// DIVISIÓN POR 10 PARA EL APARTADO DE HORA
DIV_HORA:
MOV R16, CONTADOR_HORA
CLR R17

DIV_LOOP_IZQ:
CPI R16,10
BRLO DIV_FIN_IZQ

SUBI R16,10
INC R17
RJMP DIV_LOOP_IZQ

DIV_FIN_IZQ:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG0,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG1,Z
	RJMP FIN_DIV10_IZQUIERDA

// DIVISIÓN POR 10 PARA EL APARTADO DE DIA
DIV_DIA:
LDS	R16, CONTADOR_DIA
CLR R17

DIV_LOOP_IZQ_DIA:
CPI R16,10
BRLO DIV_FIN_IZQ_DIA

SUBI R16,10
INC R17
RJMP DIV_LOOP_IZQ_DIA

DIV_FIN_IZQ_DIA:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG0,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG1,Z
	RJMP FIN_DIV10_IZQUIERDA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE HORA

DIV_HORA_CONFI:
MOV R16, CONTADOR_HORA
CLR R17

DIV_LOOP_IZQ_CONFI:
CPI R16,10
BRLO DIV_FIN_IZQ_CONFI

SUBI R16,10
INC R17
RJMP DIV_LOOP_IZQ_CONFI

DIV_FIN_IZQ_CONFI:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG0,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG1,Z
	RJMP FIN_DIV10_IZQUIERDA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE DIA

DIV_DIA_CONFI:
LDS	R16, CONTADOR_DIA
CLR R17

DIV_LOOP_IZQ_DIA_CONFI:
CPI R16,10
BRLO DIV_FIN_IZQ_DIA_CONFI

SUBI R16,10
INC R17
RJMP DIV_LOOP_IZQ_DIA_CONFI

DIV_FIN_IZQ_DIA_CONFI:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG0,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG1,Z
	RJMP FIN_DIV10_IZQUIERDA

// DIVISIÓN POR 10 PARA EL APARTADO DE CONFIGURACIÓN DE HORA ALARMA

DIV_HORA_ALARMA:
MOV R16, CONTADOR_HORA
CLR R17

DIV_LOOP_IZQ_ALARMA:
CPI R16,10
BRLO DIV_FIN_IZQ_ALARMA

SUBI R16,10
INC R17
RJMP DIV_LOOP_IZQ_ALARMA

DIV_FIN_IZQ_ALARMA:

CALL SetearZ0
ADD ZL,R17
ADC ZH,R0
LPM DIG0,Z

CALL SetearZ0
ADD ZL,R16
ADC ZH,R0
LPM DIG1,Z
	RJMP FIN_DIV10_IZQUIERDA

FIN_DIV10_IZQUIERDA:
POP ZL
POP ZH
RET
/********************************************************************************/
// Interrupt routines
/********************************************************************************/

; ======================================
; INTERRUPCIÓN PRESIONAR UN BOTÓN EN PORTC
; ======================================
BOTONES_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16

IN R16, PINC								; tenemos el estado actual del pinC
MOV  R17, R16								; guardamos este valor para comparar después

EOR  R16, ESTADO_PREVIO_BOTON				; detectar qué bits cambiaron ya que ESTADO_PREVIO_BOTON tiene el estado inicial de los botones. si cambió entondes es 1.


BLOQUE_MODE:
SBRC R16, 4									; si el bit 3 es 1, significa que ese botón de MODO fue el que se presionó, salto la línea	
RJMP BLOQUE_CAMBIO_DIG							  
RJMP BOTON_MODO								  
											  
											  
BLOQUE_CAMBIO_DIG:									  
SBRC R16, 3									; si el bit 2 es 1, significa que ese botón de CAMBIO DE DÍGITO fue el que se presionó, salto la línea									  
RJMP BLOQUE_INC
RJMP BOTON_CAMBIO_DIG						  
											
											
BLOQUE_INC:								  	
SBRC R16, 6									; si el bit 5 es 1, significa que ese botón de INCREMENTO fue el que se presionó, salto la línea						  
RJMP BLOQUE_DEC
RJMP BOTON_INC								  

BLOQUE_DEC:										  
SBRC R16, 5									; si el bit 4 es 1, significa que ese botón de DECREMENTO fue el que se presionó, salto la línea  
RJMP FIN_ISR
RJMP BOTON_DEC								  
											
											
											
											
											
											
// SE PRESIONÓ EL BOTÓN DE MODO									  		
BOTON_MODO:									
	LDS R16, REBOTE_FLAG				// 
	CPI R16,1							// 
	BRNE SIGAN_VIENDO_1					// 
	RJMP FIN_ISR						//		ANTI REBOTE
										// 
SIGAN_VIENDO_1:							// 
	LDI R16,1							// 
	STS REBOTE_FLAG,R16					// 
									
	INC MODE								
											
	CPI MODE, Max_Mode						
	BRNE NO_FIN_ISR
	RJMP FIN_ISR

NO_FIN_ISR:						
	CLR MODE								
											
	RJMP FIN_ISR	
							
// SE PRESIONÓ EL BOTÓN DE CAMBIO DE DÍGITO											
BOTON_CAMBIO_DIG:							
	LDS R16, REBOTE_FLAG				// 
	CPI R16,1							// 
	BRNE SIGAN_VIENDO_2					// 
	RJMP FIN_ISR						//		ANTI REBOTE
										// 
SIGAN_VIENDO_2:							// 
	LDI R16,1							// 
	STS REBOTE_FLAG,R16					// 

	PUSH R17
									
	LDI R17, 0x01							
	LDS R16, SELECTOR_DIG					
	EOR R16, R17							
	STS SELECTOR_DIG, R16	
	
	POP R17				
	RJMP FIN_ISR							

// SE PRESIONÓ EL BOTÓN DE INCREMENTO											
BOTON_INC:	
	LDS R16, REBOTE_FLAG				//
	CPI R16,1							//
	BREQ FIN_ISR						//		ANTI REBOTE
										//
	LDI R16,1							//
	STS REBOTE_FLAG,R16					//

							
	CPI MODE,0
	BREQ FIN_ISR

	CPI MODE,1
	BREQ FIN_ISR

	CPI MODE,2
	BREQ INC_RELOJ

	CPI MODE,3
	BREQ INC_FECHA

	CPI MODE,4
	BREQ INC_ALARMA
	RJMP FIN_ISR

INC_RELOJ:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ INC_MIN_RELOJ

	INC CONTADOR_HORA
	CPI CONTADOR_HORA,24
	BRNE FIN_ISR
	CLR CONTADOR_HORA
	RJMP FIN_ISR
	
	INC_MIN_RELOJ:
	INC CONTADOR_MIN
	CPI CONTADOR_MIN,60
	BRNE FIN_ISR
	CLR CONTADOR_MIN
	
	RJMP FIN_ISR

INC_FECHA:
	
	RJMP FIN_ISR

INC_ALARMA:
	
	RJMP FIN_ISR

// SE PRESIONÓ EL BOTÓN DE DECREMENTO
BOTON_DEC:
	LDS R16, REBOTE_FLAG				// 
	CPI R16,1							// 
	BREQ FIN_ISR						//		ANTI REBOTE
										// 
	LDI R16,1							// 
	STS REBOTE_FLAG,R16					// 

	CPI MODE,0
	BREQ FIN_ISR

	CPI MODE,1
	BREQ FIN_ISR

	CPI MODE,2
	BREQ DEC_RELOJ

	CPI MODE,3
	BREQ DEC_FECHA

	CPI MODE,4
	BREQ DEC_ALARMA
	RJMP FIN_ISR

DEC_RELOJ:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ DEC_MIN_RELOJ

	DEC CONTADOR_HORA
	BRPL FIN_ISR
	LDI CONTADOR_HORA,23
	RJMP FIN_ISR
	
	DEC_MIN_RELOJ:
	DEC CONTADOR_MIN
	CPI CONTADOR_MIN,60
	BRNE FIN_ISR
	CLR CONTADOR_MIN
	
	RJMP FIN_ISR

DEC_FECHA:
	
	RJMP FIN_ISR

DEC_ALARMA:
	
	RJMP FIN_ISR

FIN_ISR:
MOV  ESTADO_PREVIO_BOTON, R17							; actualizar estado previo del los botones

POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI


; ======================================
; INTERRUPCIÓN OVERFLOW TIMER 2
; ======================================
OverflowT2_ISR:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16

LDI R16, T2VALUE									; Empieza a contar desde T2VALUE
STS TCNT2, R16



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

LDI R16, HIGH(T1VALUE)							; Empieza a contar desde T1VALUE
STS TCNT1H, R16		
LDI R16, LOW(T1VALUE)
STS TCNT1L, R16

LDI BANDERA_SEG,1								; Enciendo la bandera de incremento 1 segundo


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


LDI R16, T0VALUE									; Empieza a contar desde T0VALUE
OUT TCNT0, R16

LDI R16,(1<<PB5)									; apagar dígitos
OUT PORTB,R16

; avanzar dígito
INC DIGITO_ACTIVO
CPI DIGITO_ACTIVO,4
BRLO SIGAN_VIENDO									; Salta si es menor que 4
CLR DIGITO_ACTIVO

SIGAN_VIENDO:
LDI R16,0
OUT PORTB,R16

CPI DIGITO_ACTIVO,0
BREQ MOSTRAR0

CPI DIGITO_ACTIVO,1
BREQ MOSTRAR1

CPI DIGITO_ACTIVO,2
BREQ MOSTRAR2

RJMP MOSTRAR3

MOSTRAR0:
LDI R16,0
OUT PORTB,R16

OUT PORTD,DIG0
LDI R16,(1<<PB0)
OUT PORTB,R16
RJMP FIN_MUX

MOSTRAR1:
LDI R16,0
OUT PORTB,R16

OUT PORTD,DIG1
LDI R16,(1<<PB1)
OUT PORTB,R16
RJMP FIN_MUX

MOSTRAR2:
LDI R16,0
OUT PORTB,R16

OUT PORTD,DIG2
LDI R16,(1<<PB2)
OUT PORTB,R16
RJMP FIN_MUX

MOSTRAR3:
LDI R16,0
OUT PORTB,R16

OUT PORTD,DIG3
LDI R16,(1<<PB3)
OUT PORTB,R16

FIN_MUX:

POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI
/****************************************/