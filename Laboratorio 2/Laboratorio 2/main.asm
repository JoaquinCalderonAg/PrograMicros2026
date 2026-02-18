;
; Laboratorio 2.asm
;
; Created: 2/11/2026 9:30:23 AM
; Author : Joaquin calderon
; Descripción: Laboratorio 2, programación de micro controladores
; Un contador de 4 bits que suma cada 100ms y un display de 7 segmentos.

.include "M328PDEF.inc"

.dseg
.org SRAM_START

.cseg
.org 0x0000

; ======================================
; CONFIGURACION DE LA PILA
; ======================================

LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16

Table7seg:
.db 0x40, 0x79, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E
; ======================================
; SETUP
; ======================================
rjmp SETUP
SETUP:

LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)

; para usar PD0 y PD1
LDI R16, 0x00
STS UCSR0B, R16

; ----- Puerto B -----
; PB0..PB3 = LEDs contador
; PB5 = Alarma

LDI R16, 0b00101111
OUT DDRB, R16

LDI R16, 0x00
OUT PORTB, R16

; ----- Puerto C -----
; PC0 PC1 botones con pull-up b0= Incrementar    b1= Decrementar

LDI R16, 0b00000000
OUT DDRC, R16

LDI R16, 0b00000011
OUT PORTC, R16

; ----- Puerto D -----
; PD0..PD6 display 7 segmentos

LDI R16, 0b01111111
OUT DDRD, R16

LDI R16, 0xFF        ; apagar display (anodo comun)
OUT PORTD, R16

; ======================================
; CONFIGURAR TIMER0
; ======================================

LDI R16, 0x00
OUT TCCR0A, R16

LDI R16, 0b00000101   ; prescaler 1024
OUT TCCR0B, R16

; limpiar bandera overflow
LDI R16, (1<<TOV0)
OUT TIFR0, R16

; ======================================
; VARIABLES
; ======================================

CLR R20     ; En R20 voy a guardar el conteo de leds
CLR R21     ; cuenta overflows
CLR R22		; conteo de display
CLR R23		; cuenta overflows para 1s

; ======================================
; LOOP PRINCIPAL
; ======================================

MAIN_LOOP:
CALL ContadorDisplay7seg    ; Lo llamo antes porque de este dependen las 4 leds del contador.
; esperar overflow
WAIT_OVF:
IN  R17, TIFR0
SBRS R17, TOV0
RJMP WAIT_OVF

; Luego del overflow tengo que borrar la bandera
LDI R17, (1<<TOV0)
OUT TIFR0, R17

INC R21
CPI R21, 6                   ; aquí dejo que el timer cuente cada 100ms
BRNE MAIN_LOOP
CLR R21
INC R23						
CPI R23, 10					; Con esto cuento 10 overflows de 100ms para hacer 1s
BRNE MAIN_LOOP

CLR R23


; incrementar contador
INC R20
ANDI R20, 0x0F

MOV R19, R20
CP R19, R22
BRNE MOSTRAR_TODO
CLR R20

MOSTRAR_TODO:
CALL MostrarLEDs
CALL AlarmaCheck



RJMP MAIN_LOOP


; Sub rutina para mostrar los leds del puerto B
// --------------------------------------- //

MostrarLEDs:

MOV R18, R20
ANDI R18, 0x0F

IN  R19, PORTB
ANDI R19, 0b11010000    ; conservar PB4 y PB6..PB7
OR  R19, R18
OUT PORTB, R19

RET


; ALARMA EN PB5
// --------------------------------------- //

AlarmaCheck:

CLR R19
CP R19, R20
BRNE AlarmOff

; encender PB5
IN  R19, PORTB
ORI R19, 0b00100000
OUT PORTB, R19
RET

AlarmOff:
IN  R19, PORTB
ANDI R19, 0b11011111
OUT PORTB, R19
RET

// Sub rutina Contador Display
// --------------------------------------- //
ContadorDisplay7seg:
IN  R18, PINC								; Leo los botones del pinC
; RESTA
// --------------------------------------- //
SBRC R18, 1									; Si el bit 1 del PINC es 0V entonces me salto la siguiente línea (se presionó el botón)
RJMP RevisaSuma
CALL Restar								; Llamo a la sub rutina para restar

;SUMA
// --------------------------------------- //
RevisaSuma:
SBRC R18, 0									; Si el bit 0 del PINC es 0V entonces me salto la siguiente línea (se presionó el botón)
RJMP MostrarDisp								; Si no fue resta ni suma, muestro los leds que eran y vuelvo al main loop
CALL Sumar								; Llamo a la sub rutina para sumar

MostrarDisp:
CALL SetearZ0

ADD ZL, R22

LPM R19, Z
OUT PORTD, R19						
							
RET

// Sub rutina Resar Display
// --------------------------------------- //
Restar:
LDI R26, 1							
CALL DELAY									; este es el antirebote

IN R19, PINC								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 1									; Si sigue siendo 0 entonces salto y hago la resta. 
RET

DEC R22
ANDI R22, 0x0F

EsperaDec:									; No deja salir de aqui hasta que se deje de presionar el boton
IN R19, PINC
SBRC R19, 1
RET
RJMP EsperaDec

// Sub rutina Sumar Display
// --------------------------------------- //
Sumar:
LDI R26, 1
CALL DELAY

IN R19, PINC								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 0									; Si sigue siendo 0 entonces salto y hago la suma
RET											

INC R22										
ANDI R22, 0x0F

EsperaInc:									; No deja salir de aqui hasta que se deje de presionar el boton
IN R19, PINC
SBRC R19, 0
RET
RJMP EsperaInc


// Sub rutina Setear mi tabla7seg en 0
// --------------------------------------- //
SetearZ0:
LDI ZH, HIGH(Table7seg<<1)
LDI ZL, LOW(Table7seg<<1)
RET

// Sub rutina DELAY
// --------------------------------------- //
	DELAY:
    CLR R27
BUCLE:
    INC R27
    CPI R27, 0
    BRNE BUCLE
    DEC R26
    BRNE BUCLE
    RET