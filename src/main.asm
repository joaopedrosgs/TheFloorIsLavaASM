Include ..\Irvine32.inc
          

.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão
    PosicaoX byte 0,0
    PosicaoY byte 0,0

.code
main PROC

    mov  eax,20          
    call Delay           
    call Mover
    call ImprimirPersonagem
    jmp main

    exit
    main endp
Mover PROC
    call ReadKey         ; look for keyboard input
    je   FimMove      ; no key pressed yet
    cmp dx,VK_UP  ; Indo pra cima?
        jne MexerBaixo
        dec PosicaoY
        jmp FimMove
    MexerBaixo:
    cmp dx,VK_DOWN  ; Indo pra baixo?
        jne MexerEsq
        inc PosicaoY
        jmp FimMove
    MexerEsq:
    cmp dx,VK_LEFT  ; Indo pra esquerda?
        jne MexerDireita
        dec PosicaoX
        jmp FimMove
    MexerDireita:
    cmp dx,VK_RIGHT  ; Indo pra direita?
        jne FimMove
        inc PosicaoX
    FimMove:
    ret
Mover endp
ImprimirPersonagem PROC
    ;Apagar a posicão antiga
    mov dl, [PosicaoX+1]
    mov dh, [PosicaoY+1]
    call Gotoxy
    mov al, 32 
    call WriteChar
    ; Escrever na posição nova
    mov dl, PosicaoX
    mov dh, PosicaoY
    call Gotoxy
    mov al, 254
    call WriteChar
    ; Salvar a posicao antiga
    mov PosicaoX+1, dl
    mov PosicaoY+1, dh
    fimMove:
    ret
ImprimirPersonagem endp
end main