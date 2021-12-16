; Projeto Assembly de Microcontroladores
; Grupo: Hiago Lopes, Luana Ferreira e Lucas Massa

.def andar_atual=r16
.def buzzer=r17
.def led=r18
.def open=r19
.def temp = r20
.def botoes_internos = r21
.def botoes_externos = r22
.def andar_internos = r23
.def andar_externos = r24

; definindo vetor de interrupções
.cseg
jmp RESET

.org $034

RESET: 
; inicializar pilha
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp

;criando o estado inicial: porta aberta com elevador parado e buzzer desligado
ldi andar_atual, 0
ldi buzzer, 0
ldi led, 1
ldi open, 1

; 4 ultimos bits da PORTB para servir de botoes internos
ldi temp,0b11110000
out DDRB,temp

; ultimo bit de PORTC para servir de botao fecha porta
ldi temp,0b11111110
out DDRC,temp

; 4 ultimos bits da PORTD para servir de botoes externos
ldi temp,0b11110000
out DDRD,temp

jmp PORTA_ABERTA

BIT_SIGNIFICATIVO_INTERNOS:
	mov temp, botoes_internos
	andi temp, 0b1000
	tst temp
	brne int_3

	mov temp, botoes_internos
	andi temp, 0b0100
	tst temp
	brne int_2

	mov temp, botoes_internos
	andi temp, 0b0010
	tst temp
	brne int_1

	mov temp, botoes_internos
	andi temp, 0b0001
	tst temp
	brne int_0

	int_3:
		ldi andar_internos, 3
		jmp BIT_SIGNIFICATIVO_INTERNOS_END
	int_2:
		ldi andar_internos, 2
		jmp BIT_SIGNIFICATIVO_INTERNOS_END
	int_1:
		ldi andar_internos, 1
		jmp BIT_SIGNIFICATIVO_INTERNOS_END
	int_0:
		ldi andar_internos, 0

	BIT_SIGNIFICATIVO_INTERNOS_END:
		ret

BIT_SIGNIFICATIVO_EXTERNOS:
	mov temp, botoes_externos
	andi temp, 0b1000
	tst temp
	brne ext_3

	mov temp, botoes_externos
	andi temp, 0b0100
	tst temp
	brne ext_2

	mov temp, botoes_externos
	andi temp, 0b0010
	tst temp
	brne ext_1

	mov temp, botoes_externos
	andi temp, 0b0001
	tst temp
	brne ext_0

	ext_3:
		ldi andar_externos, 3
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END
	ext_2:
		ldi andar_externos, 2
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END
	ext_1:
		ldi andar_externos, 1
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END
	ext_0:
		ldi andar_externos, 0
		
	BIT_SIGNIFICATIVO_EXTERNOS_END:
		ret

	
PORTA_FECHADA:
	in botoes_internos, PINB
	nop
	in botoes_externos, PIND
	nop

	call BIT_SIGNIFICATIVO_INTERNOS
	call BIT_SIGNIFICATIVO_EXTERNOS

	cp andar_atual, andar_externos
	brlo SUBIR_ANDAR
	cp andar_atual, andar_internos
	brlo SUBIR_ANDAR

	cp andar_atual, andar_externos
	breq PORTA_ABERTA
	cp andar_atual, andar_internos
	breq PORTA_ABERTA

	jmp DESCER_ANDAR
	
PORTA_ABERTA:
	in botoes_internos, PINB
	nop
	in botoes_externos, PIND
	nop
	in open, PINC
	nop

	mov temp, open
	tst temp
	brne PORTA_ABERTA
	jmp PORTA_FECHADA

SUBIR_ANDAR:
	inc andar_atual
	jmp PORTA_FECHADA

DESCER_ANDAR:
	dec andar_atual
	jmp PORTA_FECHADA