Include ..\Irvine32.inc
          

.data
	;mapa byte 119 DUP(32), 0 ; string de caracteres do chão

.code
main PROC

    mov  eax,50          ; sleep, to allow OS to time slice
    call Delay           ; (otherwise, some key presses are lost)
    call Mover
    int 3
    jmp main

    exit
    main endp
Mover PROC
    call ReadKey         ; look for keyboard input
    jz   main      ; no key pressed yet

    cmp dx,VK_UP  ; Indo pra cima?
        jne MexerBaixo
        mov eax, 1 ; pra teste
        ; Mover pra cima
        ret 
    MexerBaixo:
    cmp dx,VK_DOWN  ; Indo pra baixo?
        jne MexerEsq
        mov eax, 2
        ; Mover pra baixo
        ret 
    MexerEsq:
    cmp dx,VK_LEFT  ; Indo pra esquerda?
        jne MexerDireita
        mov eax, 3
        ; Mover esquerda 
        ret 
    MexerDireita:
    cmp dx,VK_RIGHT  ; Indo pra direita?
        jne FimMove
        mov eax, 4
        ; Mover pra direita
        FimMove:
        ret
Mover endp
end main