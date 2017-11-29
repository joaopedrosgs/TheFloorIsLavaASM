Include ..\Irvine32.inc
          

.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão
    PosicaoX byte 1,1
    PosicaoY byte 1,1
    MaxX byte 1
    MaxY byte 28

.code
main PROC
		call GetMaxXY
        sub dl, 2
        mov MaxX, dl
LOOP_PRINCIPAL:
    mov  eax,20          
    call Delay           
    call Mover
    call ImprimirPersonagem
    jmp LOOP_PRINCIPAL
    exit
    main endp
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
ImprimirPersonagem PROC
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
        mov al, 32 
        call WriteChar ; Apagando a posicão antiga
        ; Escrever na posição nova
        mov dl, PosicaoX
        mov dh, PosicaoY
        call Gotoxy
        mov al, 254
        call WriteChar
        ; Salvar a posicao antiga
        mov PosicaoX[1], dl
        mov PosicaoY[1], dh
        ret
ImprimirPersonagem endp
end main