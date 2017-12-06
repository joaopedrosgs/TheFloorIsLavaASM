Include ..\Irvine32.inc
		  
CARACTERE_PERSONAGEM = 254
CARACTERE_ESPACO = 32
CARACTERE_PRELAVA = 205
NUMERO_LAVAS = 3

LAVA STRUCT
	TempoLava DWORD 0
	PosLava WORD 0
	LavaOn BYTE 0
LAVA ends

.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão
	PosicaoX byte 1,1
	PosicaoY byte 14,1
	MaxX byte 1
	MaxY byte 28
	lavaVet LAVA NUMERO_LAVAS DUP(<>)
	;11TempoLava dword 4 DUP(0)
	;11PosLava word 4 DUP (0)
	;11LavaOn byte 4 DUP (0)
	; Relacionado ao cursor --------------------------------
	cursorInfo CONSOLE_CURSOR_INFO <>
	outHandle  DWORD ?	
	;-------------------------------------------------------

.code
main PROC
	int 3 ;modificado
	call Inicio
LOOP_PRINCIPAL:
	mov  eax,20          
	call Delay           
	call Mover
	call ImprimirPersonagem
	call PontoDeLava
	call AvancaLava
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
	mov dh, PosicaoY[1]
	cmp dl, PosicaoX
	jne ImprimirEfetivamente ; Jump para imprimir caso tenha mudado mesmo a posição
	cmp dh, PosicaoY
	jne ImprimirEfetivamente ; Jump para imprimir caso tenha mudado mesmo a posição
	ret
	ImprimirEfetivamente:
		call Gotoxy
		mov al, CARACTERE_ESPACO
		call WriteChar ; Apagando a posicão antiga
		; Escrever na posição nova
		mov dl, PosicaoX
		mov dh, PosicaoY
		call Gotoxy
		mov al, CARACTERE_PERSONAGEM
		call WriteChar
		; Salvar a posicao antiga
		mov PosicaoX[1], dl
		mov PosicaoY[1], dh
		ret
ImprimirPersonagem endp
PontoDeLava PROC
	xor edi, edi
	mov ecx, NUMERO_LAVAS
	criapontos: ;Loop percorre todas as posições no vetor de lavas associando uma posição randômica dentro do range da tela para cada uma dessas lavas
		cmp (LAVA PTR lavaVet[edi]).LavaOn, 0
		ja fimp
		mov dx, (LAVA PTR lavaVet[edi]).PosLava
		call Gotoxy
		mov al, CARACTERE_ESPACO
		call WriteChar
		call Randomize
		mov eax, 21
		call RandomRange
		mov dh, al ;gera uma posição de altura
		add dh, 4	;tira das bordas
		call Radndomize
		mov eax, 75
		call RandomRange
		mov dl, al	;gera posição de largura
		add dl, 4	;tira das bordas
		mov (LAVA PTR lavaVet[edi]).PosLava, dx
		add edi, TYPE LAVA
		loop criapontos
	xor edi, edi
	mov ecx, NUMERO_LAVAS
	escrevepontoscriados: ;Imprime na tela cada uma das lavas do vetor de lavas à partir de suas posições
		mov dx, (LAVA PTR lavaVet[edi]).PosLava
		call Gotoxy
		mov eax, yellow
		call SetTextColor
		mov al, CARACTERE_PRELAVA
		call WriteChar
		mov eax, white
		call SetTextColor
		call GetMseconds
		mov (LAVA PTR lavaVet[edi]).TempoLava, eax
		mov (LAVA PTR lavaVet[edi]).LavaOn, 1
		fimp:
		add edi, TYPE LAVA
		loop escrevepontoscriados
		ret
PontoDeLava endp
AvancaLava PROC
	xor edi, edi
	mov ecx, NUMERO_LAVAS
	avanco:
		call GetMseconds
		sub eax, (LAVA PTR lavaVet[edi]).TempoLava
		cmp eax, 10000
		ja some
		cmp eax, 5000
		ja mudaCor
		add edi, TYPE LAVA
		loop avanco
		ret
		mudaCor:
			mov dx, (LAVA PTR lavaVet[edi]).PosLava
			call Gotoxy
			mov eax, red
			call SetTextColor
			mov al, CARACTERE_PRELAVA
			call WriteChar
			mov eax, white
			call SetTextColor
			mov (LAVA PTR lavaVet[edi]).LavaOn, 2
			add edi, TYPE LAVA
			loop avanco
			ret
		some:
			mov (LAVA PTR lavaVet[edi]).LavaOn, 0
			add edi, TYPE LAVA
			loop avanco
		ret
AvancaLava endp
end main
