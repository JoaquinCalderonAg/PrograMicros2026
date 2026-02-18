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

.org PCI1addr								; habilito la interrupción para los pines del portC
RJMP IncDec_4leds

 /****************************************/
// Configuración de la pila
START:
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
LDI R16, 0x00								; Botones en portC como entradas
OUT DDRC, R16
LDI R16, 0b00000011							; Activo el pull-up en A0 y A1
OUT PORTC, R16
						; 

// Configurar PCINT1
LDI R16, (1<<PCIE1)
STS PCICR, R16
LDI R16, (1<<PCINT8)|(1<<PCINT9)
STS PCMSK1, R16

// CLEAR de mis contadores y variables 
CLR R20
CLR R21	
IN R21, PINC								 ; este es el estado previo de mis botones

// ACTIVO INTERRUPCIONES GLOBALES
SEI 
/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

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



/****************************************/