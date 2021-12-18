; Projeto Assembly de Microcontroladores
; Grupo: Hiago Lopes, Luana Ferreira e Lucas Massa

.def andar_atual=r16
.def buzzer=r17
.def led=r18
.def closed=r19
.def temp = r20
.def botoes_internos = r21
.def botoes_externos = r22
.def andar_internos = r23
.def andar_externos = r24

; definindo vetor de interrupcoes
.cseg
jmp RESET
jmp FECHAR_PORTA

.org $034

RESET:

; inicializar pilha
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp

; interrupcao em qualquer mudanca em INT0
ldi temp, 0b0000 | (0b01 << ISC00)
sts EICRA, temp

; habilita INT0
ldi temp, (1 << INT0)
out EIMSK, temp

;criando o estado inicial: porta aberta com elevador parado e buzzer desligado
ldi andar_atual, 0
ldi buzzer, 0
ldi led, 1
ldi closed, 0
ldi andar_internos, 0
ldi andar_externos, 0

; 4 ultimos bits da PORTB para servir de botoes internos
ldi temp,0b11110000
out DDRB,temp

; 4 ultimos bits da PORTC para servir de botoes externos
ldi temp,0b11110000
out DDRC,temp

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

	jmp int_0

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

	jmp ext_0

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

ANDAR_ATINGIDO:
	cpi andar_atual, 3
	breq andar_3

	cpi andar_atual, 2
	breq andar_2

	cpi andar_atual, 1
	breq andar_1

	cpi andar_atual, 0
	breq andar_0
		
	andar_3:
		andi botoes_internos, 0b00000111
		andi botoes_externos, 0b00000111
		jmp ANDAR_ATINGIDO_END
	andar_2:
		andi botoes_internos, 0b00001011
		andi botoes_externos, 0b00001011
		jmp ANDAR_ATINGIDO_END	
	andar_1:
		andi botoes_internos, 0b00001101
		andi botoes_externos, 0b00001101
		jmp ANDAR_ATINGIDO_END
	andar_0:
		andi botoes_internos, 0b00001110
		andi botoes_externos, 0b00001110
		jmp ANDAR_ATINGIDO_END

	ANDAR_ATINGIDO_END:
		ret
		

ABRIR_PORTA:	
	ldi closed, 0
	call ANDAR_ATINGIDO
	call BIT_SIGNIFICATIVO_INTERNOS
	call BIT_SIGNIFICATIVO_EXTERNOS
	jmp PORTA_ABERTA

FECHAR_PORTA:
	ldi closed, 1
	reti
	
PORTA_FECHADA:
	in botoes_internos, PINB
	nop
	in botoes_externos, PINC
	nop

	call BIT_SIGNIFICATIVO_INTERNOS
	call BIT_SIGNIFICATIVO_EXTERNOS

	cp andar_atual, andar_externos
	brlo SUBIR_ANDAR
	cp andar_atual, andar_internos
	brlo SUBIR_ANDAR

	cp andar_atual, andar_externos
	breq ABRIR_PORTA
	cp andar_atual, andar_internos
	breq ABRIR_PORTA

	jmp DESCER_ANDAR
	
PORTA_ABERTA:
	sei ;;;;;;;;;;;;;;;;;;;;;;;;;
	in botoes_internos, PINB
	nop
	in botoes_externos, PINC
	nop

	mov temp, closed
	tst temp
	breq PORTA_ABERTA
	jmp PORTA_FECHADA

SUBIR_ANDAR:
	inc andar_atual
	jmp PORTA_FECHADA

DESCER_ANDAR:
	dec andar_atual
	jmp PORTA_FECHADA