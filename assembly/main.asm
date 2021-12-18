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
.org OC1Aaddr
jmp TIMER_5us_IR
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

;faz setup para uso do timer de 5us
#define CLOCK 8.0e6 ;velodidade do clock: 8MHz
#define DELAY 5.0e-6 ;5 microssegundos
.equ PRESCALE = 0b001 ;/1 prescale
.equ PRESCALE_DIV = 1
.equ WGM = 0b0100 ;Waveform generation mode: CTC
;garante que nao passe de 65535
.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))
.if TOP > 65535
.error "TOP is out of range"
.endif

;On MEGA series, write high byte of 16-bit timer registers first
;valor a ser calculado
ldi temp, high(TOP) ;initialize compare value (TOP)
sts OCR1AH, temp
ldi temp, low(TOP)
sts OCR1AL, temp
ldi temp, ((WGM&0b11) << WGM10) ;lower 2 bits of WGM
sts TCCR1A, temp
;upper 2 bits of WGM and clock select
ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
sts TCCR1B, temp ;start counter
;TCCR1B: 000 01       001
;            WGM CTC; prescale 

;setup da IR de timer
lds temp, TIMSK1
sbr temp, 1 <<OCIE1A
sts TIMSK1, temp

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

; 2 ultimos bits da PORTD para servir de led(1) e buzzer(0), respectivamente
ldi temp,0b00000011
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
	push temp
	in temp, SREG
	push temp

	ldi closed, 1
	;in temp, TCCR1B
	; ultimos 3 bits definem prescale: 001 = /1 prescale
	;                                  000 = timer stopped
	;dec temp ; 001 => 000
	ldi temp, ((WGM>> 2) << WGM12)|(0 << CS10)
	sts TCCR1B, temp ;start counter
	;sts TCCR1B, temp ;start counter

	pop temp
	out SREG, temp
	pop temp
	reti

TIMER_5us_IR:
	push temp
	in temp, SREG
	push temp
	
	; verifica se PORTD[0] está ligado == 1
	;in temp, PORTD
	;nop
	tst buzzer ; se buzzer == 0, ligar_buzzer
	breq ligar_buzzer

	; desligando buzzer: ao desligar buzzer, porta fecha e led apaga tambem
	ldi temp, 0
	out PORTD, temp
	nop
	
	jmp TIMER_5us_IR_END

	ligar_buzzer:
		ldi buzzer, 1
		ldi temp, 0b11
		out PORTD, temp
		nop

	TIMER_5us_IR_END:
	
		pop temp
		out SREG, temp
		pop temp
		reti
	
	
PORTA_FECHADA:
	cli
	ldi led, 0 ; porta fechada
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
	; ativa led
	ldi led, 1 ; porta aberta
	;in temp, PORTD
	nop
	
	mov temp, buzzer
	or temp, 0b00000010
	out PORTD, temp
	nop

	; ativa interrupcao de timer de 5us
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp ;start counter
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
	cli
	call TIMER_5us
	call TIMER_5us
	inc andar_atual
	jmp PORTA_FECHADA

DESCER_ANDAR:
	cli
	call TIMER_5us
	call TIMER_5us
	dec andar_atual
	jmp PORTA_FECHADA

TIMER_5us:
	in temp, TIFR1 ;request status from timers
	andi temp, 1<<OCF1A ;isolate only timer 1's match
	; 0b1 << OCF1A = 0b1 << 1 = 0b00000010
	; andi --> 1 (OCF1A � um)	--> overflow
	; andi --> 0 (OCF1A � zero)	--> contando
	breq skipoverflow ;skip overflow handler
	;match handler - done once every DELAY seconds
	ldi temp, 1<<OCF1A ;write a 1 to clear the flag
	out TIFR1, temp
	jmp TIMER_5us_END

	;overflow event code goes here
	
	skipoverflow:
		;main application processing goes here
		nop
		rjmp TIMER_5us

	TIMER_5us_END:
		ret
