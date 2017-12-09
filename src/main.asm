Include ..\Irvine32.inc
		  
mImprimirEm MACRO X, Y, CARACTERE
	xor edx, edx
	xor eax, eax
	mov dl, X
	mov dh, Y
	call Gotoxy
	mov al, CARACTERE
	call WriteChar
ENDM   

mGerarAleatorio8 MACRO largura, dest
		xor eax,eax
		mov al, largura
		sub al, PADDING/2
		call Randomize
		call RandomRange ; de 0 até largura-padding
		add al, PADDING/2 ; Largura = Largura + padding/2
		mov dest,al
		mov  eax,50         
		call Delay    
endm

CARACTERE_PERSONAGEM = 254
CARACTERE_ESPACO = 32
CARACTERE_PRELAVA = 176
CARACTERE_LAVA = 177
NUMERO_LAVAS = 5
PADDING = 4

LavaP STRUCT
	posX	byte	5
	posY	byte	5
	Stage	byte	0 ;0 = Seta novas posições ; 1 = Fica Vermelho; 2 = Expande; 3 = Seta o Growing pra 0;
	Time	DWORD	0 ;0 = Começo; 50 = Estado 1; 100 = Estado 2; 200 = Estado 3; (valores sujeitos à alteração)
	Growing	byte	1 ;Se growing = 0; então decrementa o estado
LavaP ENDS


.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão

	;Player
	PosicaoX byte 20,1
	PosicaoY byte 14,1

	;Tela
	MaxX byte 60
	MaxY byte 28

	;Lava
	Lavas LavaP NUMERO_LAVAS DUP(<5,5,0,0,1>)

	; Relacionado ao cursor --------------------------------
	cursorInfo CONSOLE_CURSOR_INFO <>
	;-------------------------------------------------------

	; Relacionado à tela -----------------------------------
	outHandle dword ?
	;titleStr byte "The Floor is Lava", 0
	;_small_rect SMALL_RECT <0, 0, 84, 42>
	;-------------------------------------------------------

.code
main PROC
	call Inicio
LOOP_PRINCIPAL:
	mov  eax,20          
	call Delay           
	call Mover
	call ImprimirPersonagem
	call LoopLavas
	jmp LOOP_PRINCIPAL
	exit
	main endp

Inicio PROC USES EAX EDX
;----- esconder o cursor ---------------------------------------
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov    outHandle,eax
	INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
	mov    cursorInfo.bVisible,0
	INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
;---------------------------------------------------------------
 	;invoke getStdHandle, STD_OUTPUT_HANDLE
	;mov outHandle, eax
	;invoke setConsoleWindowInfo, outHandle, 1, addr _small_rect
	;invoke setConsoleTitle, addr titleStr	
	;call clrscr
	
;---------------------------------------------------------------
	; Salvando o X maximo 
	call GetMaxXY
	sub dl, 2 ; Padding de cada lado
	mov MaxX, dl ; Salva o x maximo
	; Colocar o player no meio da tela horizontalmente
	xor eax,eax 
	mov al, MaxX
	mov dl, 2
	div dl ; Divide a posicao maxima por 2
	mov PosicaoX, al
	call DesenharBordas
	mov ecx, NUMERO_LAVAS
	mov edi,0
	IniciandoLavas:
	mGerarAleatorio8 MaxY, (LavaP PTR Lavas[edi]).posY
	mGerarAleatorio8 MaxX, (LavaP PTR Lavas[edi]).posX
	mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_PRELAVA
	mov (LavaP PTR Lavas[edi]).Stage, 1
	mov (LavaP PTR Lavas[edi]).Growing, 1
	mov (LavaP PTR Lavas[edi]).Time, 1
	add edi,TYPE LavaP
	dec ecx
	jnz IniciandoLavas
	ret
Inicio endp

DesenharBordas PROC uses ECX EDX EAX

	xor ecx, ecx
	mov cl, MaxX	; Linhas Horizontais
	mov dl,1		; coluna
	xor dh,dh		; linha
	mov al, 205
	Horizontal:
		; Desenhar a linha do topo
		call Gotoxy
		call WriteChar
		; Desenhar a linha de baixo
		add dh, MaxY
		inc dh
		call Gotoxy
		call WriteChar
		; Resetar a linha
		xor dh, dh
		inc dl
		loop Horizontal
	mov cl, MaxY
	mov al, 186
	xor  dl,dl ; coluna
	mov  dh,1 ; linha
	Vertical:
		; Desenhar a linha do esquerda
		call Gotoxy
		call WriteChar
		; Desenhar a linha da direita
		add dl, MaxX
		inc dl
		call Gotoxy
		call WriteChar
		; Resetar a linha
		mov dl, 0
		inc dh
		loop Vertical
	ret
DesenharBordas endp

Mover PROC
	call ReadKey
	je FimMove
	
	cmp dx,VK_UP
	je MoverCima

	cmp dx,VK_DOWN
	je MoverBaixo

	cmp dx,VK_LEFT
	je MoverEsq

	cmp dx,VK_RIGHT
	je MexerDireita
	
	ret
	MoverCima:
		cmp PosicaoY, 2
		je FimMove
		dec PosicaoY
		ret
	MoverBaixo:
		mov dh, MaxY
		dec dh
		cmp dh, PosicaoY
		je FimMove
		inc PosicaoY
		ret
	MoverEsq:
		cmp PosicaoX, 2
		je FimMove
		dec PosicaoX
		ret
	MexerDireita:
		mov dl, MaxX
		dec dl
		cmp dl, PosicaoX
		je FimMove
		inc PosicaoX
		ret
	FimMove:
		ret
Mover endp
ImprimirPersonagem PROC USES EDX EAX
	;Pegando os dados pra checar se mudou a posição e pra apagar a posição antiga
	mov dl, PosicaoX[1]
	cmp dl, PosicaoX
	jne ImprimirEfetivamente ; Jump para imprimir caso tenha mudado mesmo a posição
	mov dh, PosicaoY[1]
	cmp dh, PosicaoY
	jne ImprimirEfetivamente ; Jump para imprimir caso tenha mudado mesmo a posição
	ret
	ImprimirEfetivamente:

	 	; Apagando a posicão antiga
		mImprimirEm PosicaoX[1], PosicaoY[1], CARACTERE_ESPACO
 		; Escrever na posição nova
		mImprimirEm PosicaoX, PosicaoY, CARACTERE_PERSONAGEM
 		; Salvar a posicao antiga
 		mov PosicaoX[1], dl
 		mov PosicaoY[1], dh
		 ret
ImprimirPersonagem endp

LoopLavas PROC uses ecx
	mov ecx, NUMERO_LAVAS
	mov edi, 0
	; inicio ------------------------------------------
	InicioLoop:
	cmp (LavaP PTR Lavas[edi]).Growing,0 ;Se está diminuindo
		je CadaLavaDiminuindo

	CadaLavaAumentando:
		inc (LavaP PTR Lavas[edi]).Time
		cmp (LavaP PTR Lavas[edi]).Time,700 ;decide se vai pro estagio 3
		ja Estagio3
		cmp (LavaP PTR Lavas[edi]).Time,400 ;decide se vai pro estagio 2
		ja Estagio2
		cmp (LavaP PTR Lavas[edi]).Time,200 ;decide se vai pro estagio 1
		ja Estagio1
		jmp FimCadaLavaAumentando
		Estagio1:
			; -- Pinta de vermelho
			mov  eax,red+(black*16)
			call SetTextColor
			mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_LAVA
			mov  eax,white+(black*16)
			call SetTextColor
			jmp FimCadaLavaAumentando

		Estagio2:
			; -- Explode
			jmp FimCadaLavaAumentando
		
		Estagio3:
			; -- Começa a diminuir
			mov (LavaP PTR Lavas[edi]).Growing, 0
			mov (LavaP PTR Lavas[edi]).Time, 0
		
	FimCadaLavaAumentando:
	add edi,TYPE LavaP
	dec ecx
	jnz InicioLoop
	ret

	; Lava Diminuindo --------------------------------
	CadaLavaDiminuindo:

	FimCadaLavaDiminuindo:
	add edi,TYPE LavaP
	dec ecx
	jnz InicioLoop
	ret
LoopLavas endp

end main