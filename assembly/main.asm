; Projeto Assembly de Microcontroladores
; Grupo: Hiago Lopes, Luana Ferreira e Lucas Massa


; definindo nomes para os registradores
.def andar_atual=r16 ; guarda o andar atual
.def buzzer=r17 ; indica se o buzzer está ligado
.def led=r18 ; indica se o led está ligado
.def closed=r19 ; indica se a porta está fechada
.def temp = r20 ; registrador auxiliar

; os registradores abaixo guardam os botões que foram pressionados
; usam os 4 últimos bits no seguinte formato:
; andar 3 --- andar 2 --- andar 1 --- térreo
.def botoes_internos = r21 
.def botoes_externos = r22

; guardam o valor do andar prioritário a ir
; de acordo com os botões pressionados
; obtido através do bit mais significativo dos registradores acima
.def andar_internos = r23
.def andar_externos = r24

; definindo vetor de interrupcoes
.cseg

jmp RESET ; reset
jmp FECHAR_PORTA ; INT0
.org OC1Aaddr
jmp TIMER_5us_IR ; timer
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

; faz setup para uso do timer de 5us
#define CLOCK 8.0e6 ;velocidade do clock: 8MHz
#define DELAY 5.0e-6 ;5 microssegundos
.equ PRESCALE = 0b001 ;/1 prescale
.equ PRESCALE_DIV = 1
.equ WGM = 0b0100 ;WGM: 0100 => CTC
;garante que nao passe de 65535
.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))
.if TOP > 65535
.error "TOP is out of range"
.endif

;valor a ser calculado no timer (TOP)
ldi temp, high(TOP)
sts OCR1AH, temp
ldi temp, low(TOP)
sts OCR1AL, temp
ldi temp, ((WGM&0b11) << WGM10) ; 2 menores bits do WGM
sts TCCR1A, temp
; 2 maiores bits of WGM e selecao de clock
; 0 << CS10 : prescale de 0 => contador parado
ldi temp, ((WGM>> 2) << WGM12)|(0 << CS10)
sts TCCR1B, temp
;TCCR1B: 000  01       000
;        000; WGM CTC; prescale 0: contador pausado

;setup da IR de timer
lds temp, TIMSK1
sbr temp, 1 <<OCIE1A ; habilita interrupcao de match/ comparador
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

; inicializa com o led ligado, pois a porta está aberta no estado inicial	
ldi temp, 0b00000010
out PORTD, temp
nop

; pula para o loop do estado porta aberta
jmp PORTA_ABERTA

BIT_SIGNIFICATIVO_INTERNOS: ; rotina para extrair o bit mais significativo
	mov temp, botoes_internos
	andi temp, 0b1000 ; verifica se é o bit 4
	tst temp
	brne int_3

	mov temp, botoes_internos
	andi temp, 0b0100 ; verifica se é o bit 3
	tst temp
	brne int_2

	mov temp, botoes_internos
	andi temp, 0b0010 ; verifica se é o bit 2
	tst temp
	brne int_1

	mov temp, botoes_internos
	andi temp, 0b0001 ; verifica se é o bit 1
	tst temp
	brne int_0

	jmp int_0 ; se nenhum botão estiver pressionado, assume valor 0 por padrão

	int_3: ; caso seja o bit 4 atribui o valor 3
		ldi andar_internos, 3
		jmp BIT_SIGNIFICATIVO_INTERNOS_END

	int_2: ; caso seja o bit 3 atribui o valor 2
		ldi andar_internos, 2
		jmp BIT_SIGNIFICATIVO_INTERNOS_END

	int_1: ; caso seja o bit 2 atribui o valor 1
		ldi andar_internos, 1
		jmp BIT_SIGNIFICATIVO_INTERNOS_END

	int_0: ; caso seja o bit 1 atribui o valor 0 ou térreo
		ldi andar_internos, 0

	BIT_SIGNIFICATIVO_INTERNOS_END:
		ret

BIT_SIGNIFICATIVO_EXTERNOS: ; rotina para extrair o bit mais significativo
	mov temp, botoes_externos
	andi temp, 0b1000 ; verifica se é o bit 4
	tst temp
	brne ext_3

	mov temp, botoes_externos
	andi temp, 0b0100 ; verifica se é o bit 3
	tst temp
	brne ext_2

	mov temp, botoes_externos
	andi temp, 0b0010 ; verifica se é o bit 2
	tst temp
	brne ext_1

	mov temp, botoes_externos
	andi temp, 0b0001 ; verifica se é o bit 1
	tst temp
	brne ext_0

	jmp ext_0 ; se nenhum botão estiver pressionado, assume valor 0 por padrão

	ext_3: ; caso seja o bit 4 atribui o valor 3
		ldi andar_externos, 3
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END

	ext_2: ; caso seja o bit 3 atribui o valor 2
		ldi andar_externos, 2
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END

	ext_1: ; caso seja o bit 2 atribui o valor 1
		ldi andar_externos, 1
		jmp BIT_SIGNIFICATIVO_EXTERNOS_END

	ext_0: ; caso seja o bit 1 atribui o valor 0 ou térreo
		ldi andar_externos, 0
		
	BIT_SIGNIFICATIVO_EXTERNOS_END:
		ret

ANDAR_ATINGIDO: ; rotina que desativa o bit do registrador quando o andar prioritário á atingido
	cpi andar_atual, 3 ; verifica se parou no andar 3
	breq andar_3

	cpi andar_atual, 2 ; verifica se parou no andar 2
	breq andar_2

	cpi andar_atual, 1 ; verifica se parou no andar 1
	breq andar_1

	cpi andar_atual, 0 ; verifica se parou no andar 0 ou térreo
	breq andar_0
		
	andar_3: ; caso tenha parado no 3, desativa o bit 4 dos registradores
		andi botoes_internos, 0b00000111
		andi botoes_externos, 0b00000111
		jmp ANDAR_ATINGIDO_END

	andar_2: ; caso tenha parado no 2, desativa o bit 3 dos registradores
		andi botoes_internos, 0b00001011
		andi botoes_externos, 0b00001011
		jmp ANDAR_ATINGIDO_END
			
	andar_1: ; caso tenha parado no 1, desativa o bit 2 dos registradores
		andi botoes_internos, 0b00001101
		andi botoes_externos, 0b00001101
		jmp ANDAR_ATINGIDO_END

	andar_0: ; caso tenha parado no 0, desativa o bit 1 dos registradores
		andi botoes_internos, 0b00001110
		andi botoes_externos, 0b00001110
		jmp ANDAR_ATINGIDO_END

	ANDAR_ATINGIDO_END:
		ret

FECHAR_PORTA: ; interrupção que fecha a porta e prepara o elevador para entrar em movimento
	ldi r31, ((WGM>> 2) << WGM12)|(0 << CS10) ; desativa a contagem do timer
	sts TCCR1B, r31
	
	push temp
	in temp, SREG
	push temp

	ldi closed, 1 ; fecha a porta

	pop temp
	out SREG, temp
	pop temp
	reti

; rotina de interrupcao do timer de 5us
TIMER_5us_IR:
	; desativa a contagem do timer
	ldi r31, ((WGM>> 2) << WGM12)|(0 << CS10)
	sts TCCR1B, r31

	push temp
	in temp, SREG
	push temp
	
	tst buzzer ; se buzzer == 0 (desligado), liga buzzer
	breq ligar_buzzer

	; senao, desliga buzzer
	; desligando buzzer: ao desligar buzzer, 10us se passaram, entao fecha porta e apaga-se led tambem
	ldi temp, 0
	out PORTD, temp
	nop
	ldi closed, 1
	
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
		; ativa a contagem do timer
		ldi r31, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
		sts TCCR1B, r31

		reti
	
	
PORTA_FECHADA: ; loop do estado de porta fechada
	ldi led, 0 ; porta fechada
	in botoes_internos, PINB ; lê os botões internos pressionados
	nop
	in botoes_externos, PINC ; lê os botões externos pressionados
	nop

	; verifica os bits mais significativos para definir o andar prioritário
	call BIT_SIGNIFICATIVO_INTERNOS
	call BIT_SIGNIFICATIVO_EXTERNOS

	; se o andar atual for menor que o prioritario dos botões internos
	; ou que o prioritario dos botões externos, sobe andar
	cp andar_atual, andar_externos
	brlo SUBIR_ANDAR
	cp andar_atual, andar_internos
	brlo SUBIR_ANDAR

	; se o andar atual não for menor que o prioritario dos botões internos
	; ou que o prioritario dos botões externos, sendo igual a um dos dois, para no respectivo andar
	cp andar_atual, andar_externos
	breq ABRIR_PORTA
	cp andar_atual, andar_internos
	breq ABRIR_PORTA

	; se o andar atual não for menor nem igual ao prioritario dos botões internos
	; ou ao prioritario dos botões externos,  desce de andar
	jmp DESCER_ANDAR
	
PORTA_ABERTA: ; loop do estado de porta aberta
	; ativa contagem do timer
	ldi r31, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, r31
	sei ; ativa interrupções

	in botoes_internos, PINB ; lê os botões internos pressionados
	nop
	in botoes_externos, PINC ; lê os botões externos pressionados
	nop

	mov temp, closed
	tst temp ; verifica se a porta está fechada
	breq PORTA_ABERTA ; caso não esteja, segue no loop
	; caso estajs fechada:
	ldi r31, ((WGM>> 2) << WGM12)|(0 << CS10)  ; desativa a contagem do timer
	sts TCCR1B, r31
	cli ; desativa interrupções
	jmp PORTA_FECHADA ; vai para o estado porta fechada

SUBIR_ANDAR: ; rotina para simular a subida de andar
	call TIMER_5us ; dois delays de 5us para totalizar 10us
	call TIMER_5us
	inc andar_atual ; incrementa o andar atual
	jmp PORTA_FECHADA

DESCER_ANDAR: ; rotina para simular a descida de andar
	call TIMER_5us ; dois delays de 5us para totalizar 10us
	call TIMER_5us
	dec andar_atual ; decrementa o andar atual
	jmp PORTA_FECHADA

TIMER_5us: ; rotina para causa delay de 5us
	cli
	ldi r31, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, r31 ; inicializa contador : prescale => 001

	in temp, TIFR1 ; obtem informacao do valor final do contador
	andi temp, 1<<OCF1A ; verifica no bit OCF1A se deu overflow no contador
	; 0b1 << OCF1A = 0b1 << 1 = 0b00000010
	; andi --> 1 (OCF1A ? um)	--> overflow
	; andi --> 0 (OCF1A ? zero)	--> contando
	breq skipoverflow ; se nao deu overflow: flag zero == 0 => pula overflow e repete loop
	
	; se deu overflow: flag zero == 1 => finaliza contagem
	ldi temp, 1<<OCF1A ; escreve 1 para limpar flag
	out TIFR1, temp
	jmp TIMER_5us_END ; finaliza contagem

	
	skipoverflow:
		nop
		rjmp TIMER_5us

	TIMER_5us_END:
		ldi r31, ((WGM>> 2) << WGM12)|(0 << CS10) ; pausa contador
		sts TCCR1B, r31 ;
		ldi temp, high(0) ;reseta o timer
		sts TCNT1H, temp
		ldi temp, low(0)
		sts TCNT1L, temp
		ret


ABRIR_PORTA: ; rotina que prepara para voltar ao loop de porta aberta
	ldi closed, 0 ; abre porta
	call ANDAR_ATINGIDO ; desativa o bit do andar atingido
	call BIT_SIGNIFICATIVO_INTERNOS ; verificar os bits mais significativos
	call BIT_SIGNIFICATIVO_EXTERNOS
	; ativa led
	ldi led, 1 ; porta aberta
	
	 ; faz output do led aceso
	mov temp, buzzer
	ori temp, 0b00000010
	out PORTD, temp
	nop

	ldi temp, high(0) ;reseta o timer
	sts TCNT1H, temp
	ldi temp, low(0)
	sts TCNT1L, temp
	jmp PORTA_ABERTA