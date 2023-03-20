

openFile proc
    mov ah, 3Dh
    xor al, al
    int 21h
    jc cant_open
    mov [handle_file], ax
    ret
    cant_open:
    mov dx, offset error_prompt
    mov ah, 9h
    int 21h
    ret
openFile endp

getHeader proc
    mov ah,3fh
    mov bx, [handle_file]
    mov cx,54
    mov dx,offset bmp_header
    int 21h
    ret
getHeader endp

getPalette proc
    mov ah,3fh
    mov cx,400h
    mov dx,offset color_palette
    int 21h
    ret
getPalette endp

copyPallete proc

    
    mov si,offset color_palette
    mov cx,256
    mov dx,3C8h
    mov al,0

    out dx,al


    inc dx
    Get_Pal:


    mov al,[si+2] ; Get red color value.
    shr al,1
    shr al,1    

    out dx,al 
    mov al,[si+1] ; Get green color value.
    shr al,1
    shr al,1    
    out dx,al 
    mov al,[si] ; Get blue color value.
    shr al,1
    shr al,1    
    out dx,al 
    add si,4 


    loop Get_Pal
    ret
 copyPallete endp

 copyBitmapImage proc

    mov ax, 0A000h
    mov es, ax
    mov cx,200
    PrintBMPLoop:
    push cx

    mov di,cx
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1

    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1

    add di,cx


    mov ah,3fh
    mov cx,320
    mov dx,offset Output_lines
    int 21h

    cld 

    mov cx,320
    mov si,offset Output_lines
    rep movsb 

    pop cx
    loop PrintBMPLoop
    ret
 copyBitmapImage endp

 closeFile PROC
  mov  ah, 3Eh
  mov  bx, [handle_file]
  int  21h
  ret
 closeFile endp