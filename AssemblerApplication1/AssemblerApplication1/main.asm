;
; Laboratorio_1_JoaquinCalderon.asm
;
; Created: 2/4/2026 9:36:31 AM
; Author : joaquin calderon
; Descripción: Laboratorio1, programación de microcontroladores. 
; SUMADOR DE 4 BITS

/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
// --------------------------------------- //
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
// --------------------------------------- //

// Configuracion MCU
// --------------------------------------- //
SETUP:
	LDI r16, 0x00							; Habilito los pines 0 y 1 del puerto D.
	STS UCSR0B, r16

	// Puerto B - Leds Resultado de Suma.
	LDI R16, 0xFF							; Usaré el portB para prender las leds, configuro salidas
	OUT DDRB, R16
	LDI R16, 0X00							; Las leds empiezan apagadas.
	OUT PORTB, R16

	// Puerto C - Leds contador 2, botón para sumar ambos contadores, led carry/overflow
	LDI R16, 0b00011111						; [3,0]Contador 2, [4]Led carry/overflow, [5]Entrada boton Sumar ambos contadores
	OUT DDRC, R16
	LDI R16, 0b00100000						; Configuro el boton con Pull-Up y leds apagadas
	OUT PORTC, R16

	// Puerto D - Leds contador 1, Botones Inc y Dec del contador 1, Botones Inc y Dec contador 2
	LDI R16, 0b00001111						; [3,0]Contador 1, [4]Inc Contador 1, [5]Dec Contador 1, [6]Dec Contador 2, [7]Inc Contador 2
	OUT DDRD, R16
	LDI R16, 0b11110000						; Configuro los botones con Pull-Up y leds apagadas
	OUT PORTD, R16
	
	

//  Modifico el oscilador a 1MHz para que mi delay dure mas tiempo
// --------------------------------------- //
LDI R16, (1<<CLKPCE)						; Habilito la posibilidad de cambiar el oscilador
STS CLKPR, R16								; aquí escribo el valor en el registro CLKPR

LDI R16, 0b0000_0100						; Configuro el prescaler a 16 (16MHz/16 = 1MHz)
STS CLKPR, R16								; Escribo ese valor en el registro CLKPR y con eso ya cambié el oscilador.
// --------------------------------------- //
	CLR R16
	CLR R18
	CLR R19
	CLR R20									; Conteo de bits contador 1
	CLR R22									; Conteo de bits contador 2
	CLR R24									; Conteo suma de ambos contadores
	
// LOOP PRINCIPAL
// --------------------------------------- //
MAIN_LOOP:
																	
    CALL Contador1								
    CALL Contador2
	CALL Sumador1_2

	RJMP MAIN_LOOP
    

// Sub rutina Contador 1
// --------------------------------------- //
Contador1:
IN  R18, PIND								; Leo los botones del pinD
; RESTA
// --------------------------------------- //
SBRC R18, 5									; Si el bit 5 del PIND es 0V entonces me salto la siguiente línea (se presionó el botón)
RJMP RevisaSuma
CALL RestarC1								; Llamo a la sub rutina para restar

;SUMA
// --------------------------------------- //
RevisaSuma:
SBRC R18, 4									; Si el bit 4 del PIND es 0V entonces me salto la siguiente línea (se presionó el botón)
RJMP MostrarC1								; Si no fue resta ni suma, muestro los leds que eran y vuelvo al main loop
CALL SumarC1								; Llamo a la sub rutina para sumar

MostrarC1:
MOV R21, R20
ANDI R21, 0x0F								; esto solo nos deja el primer nibble

IN R18, PORTD								; En R18 voy a guardar la configuración de mis botones
ANDI R18, 0b11110000						; conservo mis botones
OR   R18, R21								; inserto los 4 bits del contador
OUT PORTD, R18								; Escribo todo junto y mostramos en portD (los leds) lo que tenga R18
							
RET


// Sub rutina Contador 2
// --------------------------------------- //
Contador2:
IN R18, PIND								; Leo los botones del pinD
; RESTA
// --------------------------------------- //
SBRC R18, 6									; Si el bit 6 del PIND es 0V entonces me salto la siguiente línea (se presionó el botón)
RJMP RevisaSuma2							; Si no es 0 entonces llamo a la sub rutina de resta
CALL RestarC2

;SUMA
// --------------------------------------- //
RevisaSuma2:
SBRC R18, 7
RJMP MostrarC2
CALL SumarC2


MostrarC2:

MOV R21, R22
ANDI R21, 0x0F								; esto solo nos deja el primer nibble
IN  R18, PORTC	
ANDI R18, 0b11110000						; conservo mis botones
OR   R18, R21								; inserto los 4 bits del contador
OUT PORTC, R18								; Escribo todo junto y mostramos en portC (los leds) lo que tenga R18
RET

// Sub rutina Sumador Contador 1 + Contador 2 
// --------------------------------------- //
Sumador1_2:
IN R19, PINC
SBRC R19, 5
RET

LDI R26, 1
CALL DELAY

IN R19, PINC								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 5									; Si sigue siendo 0 entonces salto y vuelvo al contador1
RET											

MOV R24, R20
ADD R24, R22 

;overflow-
MOV R25, R24
ANDI R25, 0xF0
CPI R25, 0x00
BREQ NoOverflow

SBI PORTC, 4        ; encendido
RJMP MostrarSuma1_2

NoOverflow:
CBI PORTC, 4        ; apagado

MostrarSuma1_2:
MOV R21, R24
ANDI R21, 0x0F
OUT PORTB, R21
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

// Sub rutina Resar para el contador 1
// --------------------------------------- //
RestarC1:
LDI R26, 1							
CALL DELAY									; este es el antirebote

IN R19, PIND								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 5									; Si sigue siendo 0 entonces salto y vuelvo al contador1
RET

DEC R20
ANDI R20, 0x0F

EsperaDec:									; No deja salir de aqui hasta que se deje de presionar el boton
IN R19, PIND
SBRC R19, 5
RET
RJMP EsperaDec


// Sub rutina Sumar para el contador 1
// --------------------------------------- //
SumarC1:
LDI R26, 1
CALL DELAY

IN R19, PIND								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 4									; Si sigue siendo 0 entonces salto y vuelvo al contador1
RET											

INC R20										
ANDI R20, 0x0F

EsperaInc:									; No deja salir de aqui hasta que se deje de presionar el boton
IN R19, PIND
SBRC R19, 4
RET
RJMP EsperaInc


// Sub rutina Resar para el contador 2
// --------------------------------------- //
RestarC2:
LDI R26, 1
CALL DELAY									; este es el antirebote
IN R19, PIND								; Vuelvo a leer el pin para confirmar que no haya sido un rebote
SBRC R19, 6									; Si sigue siendo 0 entonces vuelvo al contador 2
RET

DEC R22
ANDI R22, 0x0F

EsperaDec2:									; No deja salir de aqui hasta que se deje de presionar el boton
IN R19, PIND
SBRC R19, 6
RET
RJMP EsperaDec2


// Sub rutina Sumar para el contador 2
// --------------------------------------- //
SumarC2:
LDI R26, 1
CALL DELAY
IN R19, PIND
SBRC R19, 7
RET

INC R22
ANDI R22, 0x0F

EsperaInc2:
IN R19, PIND
SBRC R19, 7
RET
RJMP EsperaInc2