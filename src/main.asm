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


CARACTERE_PERSONAGEM = 254
CARACTERE_ESPACO = 32
CARACTERE_PRELAVA = 176
CARACTERE_LAVA = 177
CARACTERE_LAVA_CENTRO = 178
NUMERO_LAVAS = 60
PADDING = 4

LavaP STRUCT
	posX	byte	5
	posY	byte	5
	Stage	byte	0 ;0 = Seta novas posições ; 1 = Fica Vermelho; 2 = Expande; 3 = Seta o Growing pra 0;
	Growing	byte	1 ;Se growing = 0; então decrementa o estado
	Time	DWORD	0 ;0 = Começo; 50 = Estado 1; 100 = Estado 2; 200 = Estado 3; (valores sujeitos à alteração)
LavaP ENDS

ImprimirQuadradoEm	PROTO, :BYTE, :BYTE, :BYTE
GerarAleatorio8	PROTO, :BYTE
ColocarLavaEmPosicaoAleatoria PROTO,

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
	mov edi, 0
	Cada:
	INVOKE ColocarLavaEmPosicaoAleatoria
	add edi, TYPE LavaP
	loop cada
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
	mov ecx, NUMERO_LAVAS
	mov edi,0
	TestaMorte: 
		cmp (LavaP PTR Lavas[edi]).Stage, 1 ;Vê se a lava está em fase nociva
		jb FimTeste
		mov al, (LavaP PTR Lavas[edi]).posX
		cmp PosicaoX, al
		jnz FimTeste
		mov al, (LavaP PTR Lavas[edi]).posY
		cmp PosicaoY, al
		jz Morre ;Se está no mesmo x e y da lava, morre
		FimTeste:
			add edi,TYPE LavaP
			loop TestaMorte
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
		cmp PosicaoY, 7
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
	Morre:
		int 3
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
		cmp (LavaP PTR Lavas[edi]).Time,150 ;decide se vai pro estagio 3
		ja Estagio3Aumentando
		cmp (LavaP PTR Lavas[edi]).Time,100 ;decide se vai pro estagio 2
		ja Estagio2Aumentando
		cmp (LavaP PTR Lavas[edi]).Time,50 ;decide se vai pro estagio 1
		ja Estagio1Aumentando
		jmp FimCadaLavaAumentando
		Estagio1Aumentando:
			; -- Pinta de vermelho
			cmp (LavaP PTR Lavas[edi]).Stage, 1
			je FimCadaLavaAumentando
			mov  eax,red+(black*16)
			call SetTextColor
			mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_LAVA
			mov  eax,white+(black*16)
			call SetTextColor
			mov (LavaP PTR Lavas[edi]).Stage, 1
			jmp FimCadaLavaAumentando

		Estagio2Aumentando:
			; imprime o quadrado vermelho em volta
			cmp (LavaP PTR Lavas[edi]).Stage, 2	
			je FimCadaLavaAumentando
			mov  eax,red+(black*16)
			call SetTextColor
			mov dl, (LavaP PTR Lavas[edi]).posX
     		mov dh,(LavaP PTR Lavas[edi]).posY
			INVOKE ImprimirQuadradoEm, dl, dh, CARACTERE_LAVA
			mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_LAVA_CENTRO
			mov  eax,white+(black*16)
			call SetTextColor
			mov (LavaP PTR Lavas[edi]).Stage, 2
			jmp FimCadaLavaAumentando
		
		Estagio3Aumentando:
			; -- Começa a diminuir
			mov (LavaP PTR Lavas[edi]).Growing, 0
			mov (LavaP PTR Lavas[edi]).Stage, 0
			je FimCadaLavaAumentando
		
	FimCadaLavaAumentando:
	add edi,TYPE LavaP
	dec ecx
	jnz InicioLoop
	ret

	; Lava Diminuindo --------------------------------
	CadaLavaDiminuindo:
		sub (LavaP PTR Lavas[edi]).Time, 1
		jz ReiniciaLava
		cmp (LavaP PTR Lavas[edi]).Time,100 ;decide se vai pro estagio 2
		ja Estagio2Diminuindo
		jbe Estagio1Diminuindo
		jmp FimCadaLavaDiminuindo
		Estagio1Diminuindo:
			mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_PRELAVA
			jmp FimCadaLavaDiminuindo
			
		Estagio2Diminuindo:
			mov  eax,red+(black*16)
			call SetTextColor
			mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_LAVA ; Imprime a lava q foi apagada
			mov  eax,white+(black*16)
			call SetTextColor
			cmp (LavaP PTR Lavas[edi]).Stage,2
			je FimCadaLavaDiminuindo
			mov dl, (LavaP PTR Lavas[edi]).posX
     		mov dh,(LavaP PTR Lavas[edi]).posY
			INVOKE ImprimirQuadradoEm, dl, dh, CARACTERE_ESPACO ; Apaga o quadrado
			mov (LavaP PTR Lavas[edi]).Stage,2
			jmp FimCadaLavaDiminuindo
			
		ReiniciaLava:
			INVOKE ColocarLavaEmPosicaoAleatoria
	FimCadaLavaDiminuindo:
	add edi,TYPE LavaP
	dec ecx
	jnz InicioLoop
	ret
LoopLavas endp

GerarAleatorio8 PROC, largura:byte
	xor eax,eax
	mov al, largura
	sub al, (PADDING-1)*3
	call Randomize
	call RandomRange ; de 0 até largura-padding
	add al, (PADDING-1)*2 ; Largura = Largura + padding/
	ret
GerarAleatorio8 endp

ImprimirQuadradoEm PROC USES ecx edx eax, X:byte, Y:byte, CARACTERE:byte
	mov ebx, 3
	xor edx, edx
	xor eax, eax
	mov dl, X
	sub dl, bl
	mov dh, Y
	sub dh, bl
	inc dh
	mov ecx, 5
	mov al, CARACTERE
	CadaLinha:
	mov bl, dl
	call Gotoxy
	push ecx
	mov ecx, 7
	EscreverLinha:
	cmp PosicaoX, bl
	jne Continua
	cmp PosicaoY, dh
	je Morre
	Continua:
		call WriteChar
		inc bl
	loop EscreverLinha
	inc dh
	pop ecx
	loop CadaLinha
	ret
	Morre:
		int 3
ImprimirQuadradoEm endp   

ColocarLavaEmPosicaoAleatoria PROC 
		mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_ESPACO ; Apaga lava antiga
		INVOKE GerarAleatorio8, MaxY
		mov (LavaP PTR Lavas[edi]).posY, al
		mov eax, 1
		call Delay
		INVOKE GerarAleatorio8, MaxX
		mov (LavaP PTR Lavas[edi]).posX, al
		mov eax, 1
		call Delay
		mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_PRELAVA
		mov (LavaP PTR Lavas[edi]).Stage, 0
		mov (LavaP PTR Lavas[edi]).Growing, 1
		mov (LavaP PTR Lavas[edi]).Time, 0
		ret
ColocarLavaEmPosicaoAleatoria endp

end main