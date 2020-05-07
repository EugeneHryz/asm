.model small
.stack 100h

empty_segment SEGMENT    
empty_segment ENDS

.data

CMD_LINE_SIZE equ 126

command_line db CMD_LINE_SIZE dup(0)

MAX_PROGRAM_NUMBER equ 255

epb dw 7 dup(0)

program_name db "lab7.exe",0

SPACE equ 20h
TAB equ 9h
NEW_LINE equ 0Ah
CARRIAGE_RETURN equ 0Dh

error_message1 db "Unable to load and execute program.",13,10,'$'
error_message2 db "Unable to free memory.",13,10,'$'
error_message3 db "Invalid input.",13,10,'$'

start_message db " started...",13,10,'$'
end_message db " finished",13,10,'$'

program_number db 5 dup(' ')  

.code

show_str MACRO
    push ax
    
    mov ah,9
    int 21h
    
    pop ax
ENDM

free_memory PROC
    push ax bx dx
    
    mov ax,es
    mov bx,empty_segment
    sub bx,ax
    
    mov ah,4Ah
    int 21h
    
    jnc memory_freed
    mov dx,offset error_message2
    show_str
    memory_freed:
    
    pop dx bx ax
    ret
free_memory ENDP    

read_command_line PROC
    push cx si di
    
    xor cx,cx
    mov cl,ds:[0080h]
    mov bx,cx
   
    mov si,81h
    lea di,command_line
    
    rep movsb
    
    pop di si cx
    ret
read_command_line ENDP

load_and_execute_program PROC
    push ax bx dx 
    
    mov bx,offset epb
    mov ax,ds
    mov word ptr [bx+2],offset command_line
    mov [bx+4],ax
    mov ax,cs
    mov [bx+8],ax
    mov [bx+12],ax
    
    mov dx,offset program_name
    
    mov ax,4B00h
    int 21h
    
    jnc loaded_successfully
    mov dx,offset error_message1
    show_str
    loaded_successfully:
    
    pop dx bx ax
    ret
load_and_execute_program ENDP

is_delimiter PROC
    xor ah,ah
    
    cmp al,SPACE
    jne not_space
    mov ah,1
    not_space:
    
    cmp al,TAB
    jne not_tab
    mov ah,1
    not_tab:
    
    ret
is_delimiter ENDP

is_digit PROC
    xor ch,ch
    
    cmp cl,30h
    jge greater_than_zero
    jmp not_a_number
    greater_than_zero:
    
    cmp cl,39h
    jle less_than_nine
    jmp not_a_number
    less_than_nine:
    
    mov ch,1
    not_a_number:
    
    ret
is_digit ENDP

find_word PROC
    push bp
    mov bp,sp
    push ax cx si 
    
    mov si,[bp+4]
    
    handle_word:
    
    skip_delimiter:
    mov al,[si]
    call is_delimiter
    
    cmp ah,1
    je found_delimiter
    jmp stop_reading_string
    found_delimiter:
    
    cmp cx,0
    jne string_end_not_reached
    jmp stop_reading_string
    string_end_not_reached:
    
    inc si
    dec cx
    
    jmp handle_word
    stop_reading_string:
    
    mov bx,si
    sub bx,[bp+4]
    
    skip_character:
    
    mov al,[si]
    call is_delimiter
    
    cmp ah,1
    jne not_delimiter
    jmp word_read
    not_delimiter:
    
    cmp cx,0
    jne can_read_more
    jmp word_read
    can_read_more:
    
    cmp al,CARRIAGE_RETURN
    jne not_the_end
    jmp word_read
    not_the_end:

    inc si
    dec cx
    jmp skip_character
    
    word_read:
    
    mov di,si
    sub di,[bp+4]
    cmp bx,di
    je word_not_found
    dec dx
    word_not_found:
    
    cmp cx,0
    jne not_end_of_string
    jmp out_of_loop
    not_end_of_string:
    
    cmp dx,0
    jne not_this_word
    jmp out_of_loop
    not_this_word:
    
    cmp byte ptr [si],CARRIAGE_RETURN
    jne not_stop
    jmp out_of_loop
    not_stop:
    
    jmp handle_word
    
    out_of_loop:
    
    pop si cx ax bp
    ret
find_word ENDP

get_number_from_cmd_line PROC
    push bx cx dx si
    
    mov dx,1
    mov cx,bx
    push offset command_line
    call find_word
    add sp,2
    
    cmp dx,0
    jne invalid_input
    
    mov si,10
    xor ax,ax
    get_another_digit:
    
    mov cl,command_line[bx]
    
    cmp bx,di
    jne not_end_of_number
    jmp end_of_number
    not_end_of_number:
    
    call is_digit
    cmp ch,1
    je digit_read
    jmp invalid_input
    digit_read:
    
    mul si
    
    xor ch,ch
    sub cx,30h
    add ax,cx
    cmp ax,MAX_PROGRAM_NUMBER
    jle limit_not_reached
    jmp invalid_input
    limit_not_reached:
    
    inc bx
    jmp get_another_digit
    
    end_of_number:
    jmp proc_end 
    
    invalid_input:
    xor ax,ax
    
    proc_end:
    pop si dx cx bx
    ret
get_number_from_cmd_line ENDP

convert_int_to_char PROC
    push bp
    mov bp,sp
    mov di,[bp+4]
    push ax cx dx
    
    xor dx,dx
    mov bx,10
    xor cx,cx
    
    get_another_number:
    div bx
    push dx
    inc cx
    xor dx,dx
    
    cmp ax,0
    jne get_another_number
    
    mov bx,cx
    write_another_char:
    pop dx 
    mov al,dl
    add al,'0'
    stosb
    loop write_another_char
    
    pop dx cx ax bp
    ret
convert_int_to_char ENDP

check_int_handler_address PROC
    push ax bx
    mov ax,es
    push ax
    
    mov ax,35A1h
    int 21h
    
    mov cx,1
    cmp bx,0
    jne not_zero
    mov bx,es
    cmp bx,0
    jne not_zero
    
    xor cx,cx
    not_zero:
    
    pop es bx ax
    ret
check_int_handler_address ENDP

set_int_handler_address PROC
    push ax dx
    mov ax,ds
    push ax
    xor ax,ax
    mov ds,ax
    
    cli
    mov ax,25A1h
    int 21h
    sti
    
    pop ax
    mov ds,ax
    pop dx ax
    ret
set_int_handler_address ENDP    

start:
call free_memory
mov ax,@data 
mov es,ax

call read_command_line
mov ds,ax
mov command_line[bx],13

call get_number_from_cmd_line
cmp ax,0
je invalid_parameter

mov dx,2
mov cx,bx
push offset command_line
call find_word
add sp,2
cmp dx,0
je invalid_parameter

push offset program_number
call convert_int_to_char
mov program_number[bx],'$'

call check_int_handler_address
cmp cx,0
jne copy_program

mov dx,1
call set_int_handler_address
call load_and_execute_program
mov dx,0
call set_int_handler_address
jmp skip_output

copy_program:

cmp ax,1
jne not_last_copy
jmp _end
not_last_copy:

dec ax
push offset command_line+1
call convert_int_to_char
add sp,2
mov command_line[bx+1],0Dh

call load_and_execute_program
jmp _end

invalid_parameter:
mov dx,offset error_message3
show_str
jmp skip_output
_end:

mov dx,offset program_number
show_str
mov dx,offset start_message
show_str
mov dx,offset program_number
show_str
mov dx,offset end_message
show_str

skip_output:

mov ax,4c00h
int 21h

end start

    