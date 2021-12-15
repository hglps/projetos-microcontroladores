; Projeto Assembly de Microcontroladores
; Grupo: Hiago Lopes, Luana Ferreira e Lucas Massa

.def andar=r16
.def buzzer=r17
.def led=r18
.def open=r19
.def temp = r20

; definindo vetor de interrupções
.cseg
jmp RESET

.org $006
jmp pcint0_handle

.org $034

pcint0_handle:
	push r21
	in r21, SREG
	push r21
	ldi r31, $AA
	pop r21
	out SREG, r21
	pop r21
	reti

RESET: 
; inicializar pilha
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp

;criando o estado inicial: porta aberta com elevador parado e buzzer desligado
ldi andar, 0
ldi buzzer, 0
ldi led, 1
ldi open, 1

ldi temp,0x00
out DDRB,temp

; habilitando interrupcoes nos pinos da porta B
ldi temp,0b111
sts PCICR, temp
ldi temp, $FF
sts PCMSK0, temp

sei

MAIN_LOOP: ; definindo o loop principal
	jmp MAIN_LOOP