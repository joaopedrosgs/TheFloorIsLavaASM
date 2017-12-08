Include ..\Irvine32.inc
		  
ImprimirEm MACRO X, Y, CARACTERE
	mov dl, X
	mov dh, Y
	call Gotoxy
	mov al, CARACTERE
	call WriteChar
ENDM   

CARACTERE_PERSONAGEM = 254
CARACTERE_ESPACO = 32
CARACTERE_PRELAVA = 205
NUMERO_LAVAS = 6

LavaP STRUCT
	posX	byte	?
	posY	byte	?
	Stage	byte	0 ;0 = Seta novas posições ; 1 = Fica Vermelho; 2 = Expande; 3 = Seta o Growing pra 0;
	Time	DWORD	0 ;0 = Começo; 50 = Estado 1; 100 = Estado 2; 200 = Estado 3; (valores sujeitos à alteração)
	Growing	byte	1 ;Se growing = 0; então decrementa o estado
LavaP ENDS

.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão

	;Player
	PosicaoX byte 1,1
	PosicaoY byte 14,1

	;Tela
	MaxX byte 129
	MaxY byte 28

	;Lava
	LavaOn byte 0
	Lavas LavaP NUMERO_LAVAS DUP(<>)

	; Relacionado ao cursor --------------------------------
	cursorInfo CONSOLE_CURSOR_INFO <>
	;-------------------------------------------------------

	; Relacionado à tela -----------------------------------
	outHandle dword ?
	titleStr byte "The Floor is Lava", 0
	_small_rect SMALL_RECT <0, 0, 120, 29>
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
 	invoke getStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	invoke setConsoleWindowInfo, outHandle, 1, addr _small_rect
	invoke setConsoleTitle, addr titleStr	
	call clrscr
	
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
		cmp PosicaoY, 1
		je FimMove
		dec PosicaoY
		ret
	MoverBaixo:
		mov dh, MaxY
		cmp dh, PosicaoY
		je FimMove
		inc PosicaoY
		ret
	MoverEsq:
		cmp PosicaoX, 1
		je FimMove
		dec PosicaoX
		ret
	MexerDireita:
		mov dl, MaxX
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
		ImprimirEm PosicaoX[1], PosicaoY[1], CARACTERE_ESPACO
		; Escrever na posição nova
		ImprimirEm PosicaoX, PosicaoY, CARACTERE_PERSONAGEM
		; Salvar a posicao antiga
		mov PosicaoX[1], dl
		mov PosicaoY[1], dh
		ret
ImprimirPersonagem endp

LoopLavas PROC uses ecx
	mov ecx, NUMERO_LAVAS
	CadaLava:
		test Lavas[ecx].Stage
		jnz Estagio1
		
		Estagio1:
		inc Lavas[ecx].Time;
	loop CadaLava
	ret
LoopLavas endp

end main