;
; Laboratorio_3.asm
;
; Created: 2/17/2026 4:35:34 PM
; Author : Joaquín Calderón     24268
;
; Descripción: 
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
RJMP START

.org PCI1addr								; habilito la interrupción para los pines del portC (botones)
RJMP IncDec_4leds

.org OVF0addr								; habilito la interrupción para el timer 0 (overflow)
RJMP OverflowT0

 /****************************************/
// Configuración de la pila
START:
CLI											; Deshabilito interrupciones 

LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:

// Oscilador a 1MHz
LDI R16, (1<<CLKPCE)						; Habilito la posibilidad de cambiar el oscilador
STS CLKPR, R16								; aquí escribo el valor en el registro CLKPR

LDI R16, 0b0000_0100						; Configuro el prescaler a 16 (16MHz/16 = 1MHz)
STS CLKPR, R16								; Escribo ese valor en el registro CLKPR y con eso ya cambié el oscilador.
//  

// Port B
LDI R16, 0b00001111							; Salidas en el port B para los 4 leds
OUT DDRB, R16
LDI R16, 0X00								; Leds apagadas
OUT PORTB, R16

// Port C
LDI R16, 0b00001100							; Botones en portC como entradas, y los transistores como salidas
OUT DDRC, R16
LDI R16, 0b00000011							; Activo el pull-up en A0 y A1, apago los transistores
OUT PORTC, R16

// Port D
LDI R16, 0b01111111							; Todos los pines del display como salidas
OUT DDRD, R16

LDI R16, 0xFF								; apagar display (anodo comun)
OUT PORTD, R16
						; 
// configurar interrupciones:

// Configurar PCINT1
LDI R16, (1<<PCIE1)							; habilito interrupciones del portC
STS PCICR, R16
LDI R16, (1<<PCINT8)|(1<<PCINT9)			; habilito interrupciones de los pines PC0 y PC1
STS PCMSK1, R16

// Configurar TCNT0
LDI R16, (1<<TOIE0)							; habilito interrupción del overflow
STS TIMSK0, R16

; para usar PD0 y PD1
LDI R16, 0x00
STS UCSR0B, R16


// CLEAR de mis contadores y variables 
CLR R1
CLR R20
CLR R21	
IN R21, PINC								; este es el estado previo de mis botones
CLR R22										; en este guardo el conteo del display
CLR R23										; En este guardo el conteo de overflows
CLR R24										; Aquí voy a guardar el contador de 1 segundo
CLR R25										; Aquí gurado el conteo de mis unidades
CLR R26										; Aquí guardo el conteo de mis decenas
CLR R27										; Este es para el alternador del multiplexado	

; ======================================
; CONFIGURAR TIMER0
; ======================================

LDI R16, 0x00
OUT TCCR0A, R16

LDI R16, (1<<CS01)|(1<<CS00)   ; prescaler 64
OUT TCCR0B, R16

; limpiar bandera overflow
LDI R16, (1<<TOV0)
OUT TIFR0, R16

Table7seg:
.db 0x40, 0x79, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E

// ACTIVO INTERRUPCIONES GLOBALES
SEI 
/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines:

// Interrupcion para prender leds
IncDec_4leds:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    IN   R16, PINC							 ; tenemos el estado actual del pinC
    MOV  R17, R16							 ; guardamos este valor para comparar después

    EOR  R16, R21							 ; detectar qué bits cambiaron ya que r21 tiene el estado inicial de los botones. si cambió entondes es 1.
											 
// Suma										 
    SBRS R16, 0								 ; si el bit 0 es 1, significa que ese botón de suma fue el que se presionó, salto la línea
    RJMP resta								 
    SBRS R17, 0								 ; Recordar que hay pull-up. Si es 1 significa que ya solté el botón, entonces me salto la línea para que no se incremente el valor
    INC  R20

resta:
// Resta
    SBRS R16, 1								 ; si el bit 1 es 1, significa que ese botón de resta fue el que se presionó, salto la línea
    RJMP mostrar_leds						 ; si no está presionado entonces mostramos las leds
    SBRS R17, 1								 ; Si es 1 significa que ya solté el botón, entonces me salto la línea para que no se decremente el valor
    DEC  R20								 ;

mostrar_leds:
    ANDI R20, 0x0F							 ; Me quedo con el primer nibble
    OUT  PORTB, R20

    MOV  R21, R17							; actualizar estado previo

    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI

// Interrupcion contador del delay
OverflowT0:
PUSH R16
PUSH R17
IN   R16, SREG
PUSH R16

LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)

INC R24											; incremento mi contador de overflow
CPI R24, 61										
BRNE MULTIPLEX

CLR R24											; si ya pasó 1 segundo, vuelvo a iniciar la cuenta de overflows

INC R25											; incremento mi contador de unidades hasta 10
CPI R25, 10
BRNE MULTIPLEX

CLR R25											; cuando llego a 10 reinicio la cuenta
INC R26											; incremento mi contador de decenas hasta 6

CPI R26, 6
BRNE MULTIPLEX

CLR R26											; cuando llego a 60 reinicio la cuenta



MULTIPLEX:										; Esto es para mostrar un display primero y luego el otro, en tiempos diferentes

INC R27
ANDI R27, 0x01


CBI PORTC, PC2									; apagamos el transistor del contador de unidades
CBI PORTC, PC3									; apagamos el transistor del contador de decenas

CPI R27, 0										; si r27 está en 0 mostramos las decenas, sino mostramos las unidades, nunca las dos a la vez
BREQ MOSTRAR_DECENAS
RJMP MOSTRAR_UNIDADES



MOSTRAR_DECENAS:

SBI PORTC, PC3									; Le decimos al transistor que habilite el display de las decenas

LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)
ADD ZL, R25										; mostramos lo que tenga mi contador de decenas
ADC ZH, R1

LPM R16, Z
OUT PORTD, R16

RJMP FIN_ISR


MOSTRAR_UNIDADES:

SBI PORTC, PC2									; Le decimos al transistor que habilite el display de las Unidades

LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)
ADD ZL, R26										; mostramos lo que tenga mi contador de unidades
ADC ZH, R1

LPM R16, Z
OUT PORTD, R16

FIN_ISR:
POP  R16
OUT  SREG, R16
POP  R17
POP  R16
RETI
/****************************************/