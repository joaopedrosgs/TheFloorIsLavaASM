Include ..\Irvine32.inc
Include ..\winmm.inc		  
Includelib ..\winmm.lib
		  
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
CONS_TEMPO = 50

LavaP STRUCT
	posX	byte	5
	posY	byte	5
	Stage	byte	0 ;0 = Seta novas posições ; 1 = Fica Vermelho; 2 = Expande; 3 = Seta o Growing pra 0;
	Growing	byte	1 ;Se growing = 0; então decrementa o estado
	Time	DWORD	0 ;0 = Começo; 50 = Estado 1; 100 = Estado 2; 200 = Estado 3; (valores sujeitos à alteração)
LavaP ENDS

ImprimirQuadradoEm	PROTO, :BYTE, :BYTE, :BYTE
GerarAleatorio8	PROTO, :BYTE
ColocarLavaEmPosicaoAleatoria PROTO
LoopMenu PROTO
LoopEndGame PROTO
TocaSom PROTO, :BYTE
ChecarMorte PROTO
EscreverTempo PROTO

.data

	
	tempoAtual DWORD 0
	;som
	tocaUmaVez DWORD 00020001h
	efeito1 BYTE "Sounds\Estagio1_sfx.wav",0
	efeito2 BYTE "Sounds\Estagio2_sfx.wav",0
	efeito3 BYTE "Sounds\Death_sfx.wav",0
	somAtual BYTE 1
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão

	;Player
	PosicaoX byte 20,1
	PosicaoY byte 14,1
	flagMorte byte 0

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
	titleStr byte "The Floor is Lava", 0
	_small_rect SMALL_RECT <0, 0, 119,29>
	;-------------------------------------------------------

	;Relacionado ao menu -----------------------------------
	LinhaMorte BYTE "           VOCE MORREU!",0, "Aperte Enter para jogar novamente",0,"            Tempo: ",1
	LinhaMenu BYTE "              (  .      )",0, "          )           (              )",0,"                .  '   .   '  .  '  .",0,"       (    , )       (.   )  (   ',    )",0,"        .' ) ( . )    ,  ( ,     )   ( .",0,"     ). , ( .   (  ) ( , ')  .' (  ,    )",0,"    (_,) . ), ) _) _,')  (, ) '. )  ,. (' )",0," ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",0,0, "            Aperte ENTER para jogar",0,0,0,0,0,0,0,0,"Como Jogar:",0 ,"Seu personagem eh o ponto branco",0,"O objetivo e escapar da lava",1
	LinhaTempo BYTE "Tempo Atual: ",0
.code
main PROC
	call Inicio
LOOP_PRINCIPAL:
	mov  eax,20          
	call Delay
	call EscreverTempo           
	call Mover
	call ImprimirPersonagem
	call LoopLavas
	call ChecarMorte
	jmp LOOP_PRINCIPAL
	exit
	main endp

;	Procedimento que pega o tamanho da janela, desenha as bordas
;	Inicia o menu,
;	Seta o player no meio da tela e
;	Seta as lavas
Inicio PROC USES EAX EDX
;----- esconder o cursor ---------------------------------------
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov    outHandle,eax
	INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
	mov    cursorInfo.bVisible,0
	INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
;---------------------------------------------------------------
 	invoke getStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	invoke setConsoleWindowInfo, outHandle, 1, addr _small_rect
	invoke setConsoleTitle, addr titleStr	
	;call LimparTela
	
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
	mov  eax,yellow+(red*16)
    call SetTextColor
	call LimparTela
	call DesenharBordas
	call LoopMenu
	mov  eax,white+(black*16)
    call SetTextColor
	call LimparTela
	call DesenharBordas
	mov ecx, NUMERO_LAVAS
	mov edi, 0
	Cada:
	INVOKE ColocarLavaEmPosicaoAleatoria
	add edi, TYPE LavaP
	loop cada
	ret
Inicio endp

; Desenha as bordas da tela
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

	mov dl, MaxX
	inc dl
	mov dh, 0
	call Gotoxy
	mov al, 187
	call WriteChar ; Desenha a borda superior direita
	mov dh, MaxY
	inc dh
	call Gotoxy
	inc al
	call WriteChar; Desenha a borda inferior direita
	mov dl, 0
	mov al, 200
	call Gotoxy
	call WriteChar; Desenha a borda inferior esquerda
	inc al
	mov dh,0
	call Gotoxy
	call WriteChar; Desenha a borda superior esquerda
	ret
DesenharBordas endp

; Lê o input pra mover o personagem e detecta morte
Mover PROC
	mov ecx, NUMERO_LAVAS
	mov edi,0
	TestaMorte: 
		cmp (LavaP PTR Lavas[edi]).Stage, 1 ;Vê se a lava está em fase nociva
		jbe FimTeste
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
		sub dh,2
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
		mov flagMorte, 1
		ret
Mover endp

;Imprime o personagem na posição correta, apagando sua posição antiga
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

;Esse procedimento é o mais importante do jogo, ele da um loop no array de lavas checando em qual
;estagio cada uma delas está para agir corretamente
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
			mov somAtual, 2
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
	cmp (LavaP PTR Lavas[0]).Time, 1
	je barulho
	cmp (LavaP PTR Lavas[0]).Time, 101
	je barulho
	ret
	barulho:
		INVOKE TocaSom, somAtual
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
			mov somAtual, 1
			INVOKE ColocarLavaEmPosicaoAleatoria
	FimCadaLavaDiminuindo:
	add edi,TYPE LavaP
	dec ecx
	jnz InicioLoop
	ret
LoopLavas endp

; Esse procedimento Gera um numero aleatorio que não cause problemas na hora de imprimir um quadrado
GerarAleatorio8 PROC, largura:byte
	xor eax,eax
	mov al, largura
	sub al, (PADDING-1)*3
	call Randomize
	call RandomRange ; de 0 até largura-(PADDING-1)*3
	add al, (PADDING-1)*2 ; de (PADDING-1)*2 até largura-(PADDING-1)*3+(PADDING-1)*2
	ret
GerarAleatorio8 endp

; Esse procedimento imprime um quadrado de caracteres de diametro ebx*2+1
ImprimirQuadradoEm PROC USES ecx edx eax ebx, X:byte, Y:byte, CARACTERE:byte
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
	jne Continua
	mov flagMorte, 1 ;Omae wa mo shindeiru
	Continua:
		call WriteChar
		inc bl
	loop EscreverLinha
	inc dh
	pop ecx
	loop CadaLinha
	ret
ImprimirQuadradoEm endp   

;Esse Procedimento apaga a lava antiga e gera uma nova posição aleatoria para a mesma,
;também volta ela para o estagio 1 e em crescimento
ColocarLavaEmPosicaoAleatoria PROC
		mImprimirEm (LavaP PTR Lavas[edi]).posX, (LavaP PTR Lavas[edi]).posY, CARACTERE_ESPACO ; Apaga lava antiga
		INVOKE GerarAleatorio8, MaxY
		mov (LavaP PTR Lavas[edi]).posY, al
		mov eax, 1
		call Delay
		inc tempoAtual
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

 ; Esse procedimento lê um array de strings,
 ; pulando linha onde tem 0 e terminando a impressão onde tem 1
LoopMenu PROC uses edx edi eax
inicioLoopMenu:
	mov dl, 37
	mov dh, 6
	call Gotoxy
	mov ebx, OFFSET LinhaMenu
	mov edi, 0
	Imprimir:
	mov al, BYTE PTR LinhaMenu[edi]
	cmp al, 1	
	je Fim
	ja ContinuaImprimindo
	inc dh ; Pula linha
	call Gotoxy
	ContinuaImprimindo:
	cmp al,40
	jb ImprimeMesmo
	cmp al, 41
	ja ImprimeMesmo
	xor al, 00000001b ; Transforma ( em ) e vice versa
	mov BYTE PTR LinhaMenu[edi], al
	ImprimeMesmo:
	call WriteChar
	inc edi
	jmp Imprimir
	fim:
	mov eax, 500 ; Delay para o fogo mexer
	call Delay
	call ReadKey
	cmp dx,VK_RETURN ; Se apertou enter
	je retorna
	jmp inicioLoopMenu
	retorna:
	ret	
LoopMenu endp

LoopEndGame PROC
	mov dl, 43
	mov dh, 12
	call Gotoxy
	mov ebx, OFFSET LinhaMorte
	mov edi, 0
	Imprimir:
		mov al, BYTE PTR LinhaMorte[edi]
		cmp al, 1	
		je EsperandoJogarNovamente
		ja ContinuaImprimindo
		inc dh ; Pula linha
		call Gotoxy
		ContinuaImprimindo:
			call WriteChar
			inc edi
			jmp Imprimir
	EsperandoJogarNovamente:

		mov edx,0
		mov ecx, CONS_TEMPO
		mov eax, tempoAtual
		div ecx
		call WriteDec
		blablio:
		call ReadKey
		cmp dx,VK_RETURN ; Se apertou enter
		jne blablio
	ret
LoopEndGame endp

TocaSom PROC, qual:BYTE
	cmp qual, 3
	je toca3
	cmp qual, 2
	je toca2
	INVOKE PlaySound, OFFSET efeito1, NULL, tocaUmaVez
	ret
	toca2:
		INVOKE PlaySound, OFFSET efeito2, NULL, tocaUmaVez
		ret
	toca3:
		INVOKE PlaySound, OFFSET efeito3, NULL, tocaUmaVez
		mov eax, 2000
		call Delay
	ret
TocaSom endp

ChecarMorte PROC
	cmp flagMorte, 0
	je fim
	mov somAtual, 3
	INVOKE TocaSom, somAtual
	mov  eax,yellow+(red*16)
    call SetTextColor
	call LimparTela
	call DesenharBordas
	call LoopEndGame
	mov somAtual, 1
	mov flagMorte, 0
	mov tempoAtual, 0
	call Inicio
	fim:
	ret
ChecarMorte endp

EscreverTempo PROC
	mov edx,0
	mov ecx, CONS_TEMPO
	mov eax, tempoAtual
	div ecx
	mov dh, 2
	mov dl, MaxX
	sub dl, 65
	call Gotoxy
	mov edx, OFFSET LinhaTempo
	call WriteString
	call WriteDec
	inc tempoAtual
	ret
EscreverTempo endp

LimparTela PROC

	xor ecx, ecx
	mov al, CARACTERE_ESPACO
	mov dh, 0
	mov dl, 0
	call Gotoxy
	mov cl, MaxY
	add cl, 2
	CadaLinha:
	push ecx
	mov cl, MaxX
	CadaCaractere:
	call WriteChar
	loop CadaCaractere
	pop ecx
	loop CadaLinha
	ret

LimparTela endp

end main
