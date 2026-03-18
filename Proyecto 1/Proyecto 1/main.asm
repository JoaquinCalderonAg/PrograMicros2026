;
; Proyecto 1.asm
;
; Created: 3/4/2026 4:38:00 PM
; Author : Joaquin Calderón
; Descripción: Proyecto 1 progra de micros

//0xFFE5
// 0xC2F7
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.equ T2VALUE					= 134
.equ T1VALUE					= 0xC2F7
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
ALARMA_MIN:						.byte 1
ALARMA_HORA:					.byte 1
CONTEO_T2:						.byte 1
ALARMA_ACTIVA:					.byte 1
ALARMA_SONANDO:					.byte 1

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

LDI R16, 0b00111111							; [0] Digito extremo izquierdo, [1]Digito medio izquierda, [2]Digito medio derecha, [3]Digito extremo derecha, [4]nada, [5]Dos puntos
OUT DDRB, R16								 
LDI R16, 0b00000000							; Configuro pullUp y leds apagadas
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
STS SELECTOR_DIG, R16					   ; Aquí guardo el selector de dígitos que estoy configurando.										    
CLR R16									   
STS REBOTE_FLAG, R16					   ; Aquí guardo la bandera del antirebote										    
CLR R16									   
STS ALARMA_MIN, R16						   ; Aquí guardo el minuto donde sonará la alarma										    
CLR R16									   
STS ALARMA_HORA, R16					   ; Aquí guardo la hora donde sonará la alarma		
CLR R16									   
STS CONTEO_T2, R16						   ; Aquí guardo el conteo de overflows del timer 2	
CLR R16									   
STS ALARMA_ACTIVA, R16					   ; Aquí guardo la bandera de la activación de la alarma	
CLR R16									   
STS ALARMA_SONANDO, R16					   ; Aquí guardo la bandera de la alarma sonando				    

											 
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


CPI		MODE, 0
BREQ	SALTO_MUESTRA_RELOJ

CPI		MODE, 1
BREQ	SALTO_MUESTRA_FECHA

CPI		MODE, 2
BREQ	SALTO_CONFI_RELOJ

CPI		MODE, 3
BREQ	SALTO_CONFI_FECHA

CPI		MODE, 4
BREQ	SALTO_CONFI_ALARMA
RJMP    MAIN_LOOP

SALTO_CONFI_ALARMA:
RJMP CONFI_ALARMA

SALTO_CONFI_FECHA:
RJMP CONFI_FECHA

SALTO_CONFI_RELOJ:
RJMP CONFI_RELOJ

SALTO_MUESTRA_FECHA:
RJMP MUESTRA_FECHA

SALTO_MUESTRA_RELOJ:
RJMP MUESTRA_RELOJ

; ======================================
; REALIZO LA ACCIÓN DEL CONTEO DE SEGUNDOS
; ======================================
INCREMENTO_1S:
PUSH R16
PUSH R17
PUSH R0
PUSH ZH
PUSH ZL

CPI BANDERA_SEG, 0x01
BRNE FIN_INC

CLR BANDERA_SEG

INC		CONTADOR_SEG
CPI		CONTADOR_SEG, 60
BRNE	FIN_INC
CLR		CONTADOR_SEG

INC		CONTADOR_MIN
CPI		CONTADOR_MIN, 60
BRNE	FIN_INC
CLR		CONTADOR_MIN

CLR R16
STS ALARMA_SONANDO, R16


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
; =========================
; DETECTAR ALARMA 
; =========================

LDS R16, ALARMA_HORA
CPI R16,0
BRNE CONTINUA_ALARMA

LDS R16, ALARMA_MIN
CPI R16,0
BREQ FIN_ALARMA

CONTINUA_ALARMA:

LDS R16, ALARMA_SONANDO
CPI R16,1
BREQ FIN_ALARMA


LDS R16, ALARMA_HORA							 ; comparar hora
CP  R16, CONTADOR_HORA							 
BRNE FIN_ALARMA									 
												 
								 
LDS R16, ALARMA_MIN								 ; comparar minuto
CP  R16, CONTADOR_MIN							 
BRNE FIN_ALARMA									 
												 
								 
LDI R16,1										 ; activar alarma
STS ALARMA_ACTIVA, R16							 
STS ALARMA_SONANDO, R16							 
												 
FIN_ALARMA:

POP ZL
POP ZH
POP R0
POP R17
POP R16
RET


; ======================================
; REALIZO LA ACCIÓN DEL MODO 1, MOSTRAR LA HORA
; ======================================
MUESTRA_RELOJ:

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA
	
	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 2, MOSTRAR LA FECHA
; ======================================
MUESTRA_FECHA:

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 3,  CONFIGURAR RELOJ
; ======================================
CONFI_RELOJ:

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 4, MOSTRAR LA FECHA
; ======================================
CONFI_FECHA:

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

	RJMP FIN_ISR_CONTADOR

; ======================================
; REALIZO LA ACCIÓN DEL MODO 5, MOSTRAR LA FECHA
; ======================================
CONFI_ALARMA:

	CALL DIV10_IZQUIERDA
	CALL DIV10_DERECHA

FIN_ISR_CONTADOR:
//CLR BANDERA_SEG
	RJMP MAIN_LOOP
/********************************************************************************/
// NON-Interrupt subroutines
/********************************************************************************/


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
BREQ	SIGO1
RJMP	FIN_DIV10_DERECHA

SIGO1:
RJMP	DIV_MIN_ALARMA
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
LDS R16, ALARMA_MIN
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
BREQ	SALTO1
RJMP	SALTO1_2

SALTO1:
RJMP DIV_DIA_CONFI
SALTO1_2:

CPI		R16, 4
BREQ	SALTO2
RJMP	FIN_DIV10_IZQUIERDA

SALTO2:
RJMP	DIV_HORA_ALARMA
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
LDS R16, ALARMA_HORA
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


SBRS R16, 3									; Si el bit 3 está en 1 significa que se presionó el botón MODO
RJMP SIGUIENTE1
RJMP BOTON_MODO	
							 
SIGUIENTE1:											 
SBRS R16, 2									; Si el bit 2 está en 1 significa que se presionó el botón CAMBIO DE DÍGITO 
RJMP SIGUIENTE2
RJMP BOTON_CAMBIO_DIG						 
			
SIGUIENTE2:								 
SBRS R16, 5									; Si el bit 5 está en 1 significa que se presionó el botón INCREMENTO
RJMP SIGUIENTE3
RJMP BOTON_INC								 

SIGUIENTE3:											 
SBRS R16, 4									; Si el bit 4 está en 1 significa que se presionó el botón DECREMENTO
RJMP FIN_ISR									 
RJMP BOTON_DEC							  	 
											 																																
											
// SE PRESIONÓ EL BOTÓN DE MODO									  		
BOTON_MODO:		
LDS R16, ALARMA_ACTIVA
CPI R16,1
BRNE CONTINUAR_BOTON_MODO

CLR R16
STS ALARMA_ACTIVA, R16
RJMP FIN_ISR

CONTINUAR_BOTON_MODO:
										
	SBRS R17, 3								; Si el bit 3 está en 1 significa que dejé de presionar el botón y ya no tengo que hacer nada
	RJMP CONTINUAR1
	RJMP FIN_ISR
	
CONTINUAR1:	
	INC MODE								
											
	CPI MODE, Max_Mode						
	BREQ CLEAR_MODE
	RJMP FIN_ISR

CLEAR_MODE:						
	CLR MODE								
											
	RJMP FIN_ISR	
							
// SE PRESIONÓ EL BOTÓN DE CAMBIO DE DÍGITO											
BOTON_CAMBIO_DIG:	
LDS R16, ALARMA_ACTIVA
CPI R16,1
BRNE CONTINUAR_BOTON_CAMBIO

CLR R16
STS ALARMA_ACTIVA, R16
RJMP FIN_ISR

CONTINUAR_BOTON_CAMBIO:


	SBRS R17, 2								; Si el bit 2 está en 1 significa que dejé de presionar el botón y ya no tengo que hacer nada
	RJMP CONTINUAR2
	RJMP FIN_ISR
	
CONTINUAR2:		
	CPI MODE,0
	BREQ SALTO_FIN_ISR

	CPI MODE,1
	BREQ SALTO_FIN_ISR

	CPI MODE,2
	BREQ CAMBIO_DIGITO

	CPI MODE,3
	BREQ CAMBIO_DIGITO

	CPI MODE,4
	BREQ CAMBIO_DIGITO
	RJMP FIN_ISR	
					
SALTO_FIN_ISR:
RJMP FIN_ISR
	
CAMBIO_DIGITO:		

	LDS R16, SELECTOR_DIG
	LDI ACTION, 1
	EOR R16, ACTION
	STS SELECTOR_DIG, R16
	
					
	RJMP FIN_ISR							

// SE PRESIONÓ EL BOTÓN DE INCREMENTO											
BOTON_INC:
LDS R16, ALARMA_ACTIVA
CPI R16,1
BRNE CONTINUAR_BOTON_INC

CLR R16
STS ALARMA_ACTIVA, R16
RJMP FIN_ISR

CONTINUAR_BOTON_INC:
	

	SBRS R17, 5								; Si el bit 5 está en 1 significa que dejé de presionar el botón y ya no tengo que hacer nada
	RJMP CONTINUAR3
	RJMP FIN_ISR
	
CONTINUAR3:
							
	CPI MODE,0
	BREQ SALTO_FIN_ISR

	CPI MODE,1
	BREQ SALTO_FIN_ISR

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
	CPI CONTADOR_HORA,25
	BRNE SALTO_FIN_ISR
	CLR CONTADOR_HORA
	RJMP FIN_ISR
	
	INC_MIN_RELOJ:
	INC CONTADOR_MIN
	CPI CONTADOR_MIN,60
	BRNE SALTO_FIN_ISR
	CLR CONTADOR_MIN
	
	RJMP FIN_ISR

INC_FECHA:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ INC_MES_FECHA

	LDS ACTION, DIAS_MAX

	LDS R16, CONTADOR_DIA
	INC R16
	CPI R16, 32
	BRNE FIN_INC_FECHA
	LDI R16,1
	STS CONTADOR_DIA, R16
	RJMP FIN_ISR
	
	INC_MES_FECHA:
	INC CONTADOR_MES
	CPI CONTADOR_MES,12
	BRNE SALTO_FIN_ISR
	LDI CONTADOR_MES, 0
	RJMP FIN_ISR
	
FIN_INC_FECHA:
	STS CONTADOR_DIA, R16
	RJMP FIN_ISR

INC_ALARMA:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ INC_MIN_ALARMA

	LDS R16, ALARMA_HORA
	INC R16
	CPI R16,24
	BRNE FIN_INC_HORA

	CLR R16
	STS ALARMA_HORA, R16
	RJMP FIN_ISR
	
	INC_MIN_ALARMA:
	LDS R16, ALARMA_MIN
	INC R16
	CPI R16,60
	BRNE FIN_INC_MIN

	CLR R16
	STS ALARMA_MIN, R16
	RJMP FIN_ISR

	FIN_INC_HORA:
	STS ALARMA_HORA, R16
	RJMP FIN_ISR

	FIN_INC_MIN:
	STS ALARMA_MIN, R16
	RJMP FIN_ISR

// SE PRESIONÓ EL BOTÓN DE DECREMENTO
BOTON_DEC:
LDS R16, ALARMA_ACTIVA
CPI R16,1
BRNE CONTINUAR_BOTON_DEC

CLR R16
STS ALARMA_ACTIVA, R16
RJMP FIN_ISR

CONTINUAR_BOTON_DEC:


	SBRS R17, 4								; Si el bit 4 está en 1 significa que dejé de presionar el botón y ya no tengo que hacer nada
	RJMP CONTINUAR4
	RJMP FIN_ISR
	
CONTINUAR4:

	CPI MODE,0
	BREQ SALTO_FIN_ISR2

	CPI MODE,1
	BREQ SALTO_FIN_ISR2

	CPI MODE,2
	BREQ DEC_RELOJ

	CPI MODE,3
	BREQ DEC_FECHA

	CPI MODE,4
	BREQ DEC_ALARMA
	RJMP FIN_ISR

SALTO_FIN_ISR2:
RJMP FIN_ISR

DEC_RELOJ:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ DEC_MIN_RELOJ

	DEC CONTADOR_HORA
	CPI CONTADOR_HORA, 0xFF
	BRNE FIN_ISR
	LDI CONTADOR_HORA, 23
	
	DEC_MIN_RELOJ:
	DEC CONTADOR_MIN
	CPI CONTADOR_MIN,0xFF
	BRNE FIN_ISR
	LDI CONTADOR_MIN, 59
	
	RJMP FIN_ISR

DEC_FECHA:
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ DEC_MES_FECHA


	LDS R16, CONTADOR_DIA
	DEC R16
	CPI R16, 0
	BRNE FIN_DEC_FECHA
	LDI R16, 31
	STS CONTADOR_DIA, R16
	RJMP FIN_ISR
	
	DEC_MES_FECHA:
	DEC CONTADOR_MES
	CPI CONTADOR_MES, 0xFF
	BRNE FIN_ISR
	LDI CONTADOR_MES, 11
	RJMP FIN_ISR
	
FIN_DEC_FECHA:
	STS CONTADOR_DIA, R16
	RJMP FIN_ISR
	

DEC_ALARMA:
	
	LDS R16, SELECTOR_DIG
	CPI R16,0								; Si el selector es 0 entonces configuramos los dígitos de la derecha
	BREQ DEC_MIN_ALARMA

	LDS R16, ALARMA_HORA
	DEC R16
	CPI R16,0xFF
	BRNE FIN_DEC_HORA

	LDI R16, 23
	STS ALARMA_HORA, R16
	RJMP FIN_ISR
	
	DEC_MIN_ALARMA:
	LDS R16, ALARMA_MIN
	DEC R16
	CPI R16,0xFF
	BRNE FIN_DEC_MIN

	LDI R16, 59
	STS ALARMA_MIN, R16
	RJMP FIN_ISR

	FIN_DEC_HORA:
	STS ALARMA_HORA, R16
	RJMP FIN_ISR

	FIN_DEC_MIN:
	STS ALARMA_MIN, R16
	RJMP FIN_ISR


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
	LDI R16, (1<<TOV2)									; limpiar bandera overflow
	OUT TIFR2, R16
	
	LDS R16, ALARMA_ACTIVA
	CPI R16,1
	BRNE CONTINUAR_NORMAL
	
; =========================
; ALARMA ACTIVA
; =========================
	
	SBI PINC,0											; parpadeo fecha 
	SBI PINC,1											; parpadeo hora 
	
	RJMP FIN_T2
	
	CONTINUAR_NORMAL:

	LDI R16, T2VALUE									; Empieza a contar desde T2VALUE
	STS TCNT2, R16
	
	LDS R16, CONTEO_T2
	INC R16
	STS CONTEO_T2, R16

	CPI R16, 5
	BRNE FIN_T2
	CLR R16
	STS CONTEO_T2, R16
	SBI PINB, 5

	CPI MODE,0
	BREQ SIN_PARPADEAR0

	CPI MODE,1
	BREQ SIN_PARPADEAR1

	CPI MODE,2
	BREQ PARPADEO_HORA
	
	CPI MODE,3
	BREQ PARPADEO_FECHA

	CPI MODE,4
	BREQ SIN_PARPADEAR3
	
	RJMP FIN_T2
	
	PARPADEO_HORA:
	CBI PORTC, 0
	SBI PINC,1
	RJMP FIN_T2
	
	PARPADEO_FECHA:
	CBI PORTC, 1
	SBI PINC,0
	RJMP FIN_T2
	
	SIN_PARPADEAR0:
	CBI PORTC, 0
	SBI PORTC, 1
	RJMP FIN_T2

	SIN_PARPADEAR1:
	CBI PORTC, 1
	SBI PORTC, 0
	RJMP FIN_T2

	SIN_PARPADEAR3:
	SBI PORTC, 1
	SBI PORTC, 0


FIN_T2:


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

; avanzar dígito
INC DIGITO_ACTIVO
CPI DIGITO_ACTIVO,4
BRLO SIGAN_VIENDO									; Salta si es menor que 4
CLR DIGITO_ACTIVO

SIGAN_VIENDO:

CPI DIGITO_ACTIVO,0
BREQ MOSTRAR0

CPI DIGITO_ACTIVO,1
BREQ MOSTRAR1

CPI DIGITO_ACTIVO,2
BREQ MOSTRAR2

RJMP MOSTRAR3

MOSTRAR0:
IN R16, PORTB
ANDI R16, (1<<PB5)								; conservo PB5
OUT PORTB, R16

OUT PORTD,DIG0

IN R16, PORTB
ANDI R16, (1<<PB5)   
ORI R16, (1<<PB0)								; encender dígito
OUT PORTB, R16

RJMP FIN_MUX

MOSTRAR1:
IN R16, PORTB
ANDI R16, (1<<PB5)								; conservo PB5
OUT PORTB, R16

OUT PORTD,DIG1

ANDI R16, (1<<PB5)   
ORI R16, (1<<PB1)								; encender dígito
OUT PORTB, R16

RJMP FIN_MUX

MOSTRAR2:
IN R16, PORTB
ANDI R16, (1<<PB5)								; conservo PB5
OUT PORTB, R16

OUT PORTD,DIG2

ANDI R16, (1<<PB5)   
ORI R16, (1<<PB2)								; encender dígito
OUT PORTB, R16

RJMP FIN_MUX

MOSTRAR3:
IN R16, PORTB
ANDI R16, (1<<PB5)								; conservo PB5
OUT PORTB, R16

OUT PORTD,DIG3

ANDI R16, (1<<PB5)  
ORI R16, (1<<PB3)								; encender dígito
OUT PORTB, R16

FIN_MUX:

POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI
/****************************************/