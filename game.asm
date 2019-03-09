global main

; global set_input_mode
; global reset_input_mode

extern printf
extern fflush

section .data
	text1 			db "What is your name? "
	text2 			db "Hello, " 
	instr_text		db "User W, S, A, D to move UP, DOWN, LEFT, RIGHT respectively and Q to quit", 0
	score_text 		db "Your Score is:", 0
	time_text 		db "Time Passed:", 0
	empty	 		db "", 0
	fd 				dd 0
	my_figure 		db '@'
	space_figure 	db ' '
	border_figure	db '|'
	new_line 		db 10
	fmt    			db "%c", 0
	fmt_s    		db "%s",13, 10, 0
	fmt_sN    		db "%s",13, 0
	fmt_d   		db "%lld",13, 10, 0
	delay 			dq 0, 100000000
	passed_time		dq 0
	cls				db 033q, "[H", 033q, "[2J", 0
	my_positionx 	dq 18
	my_positiony 	dq 10
	beta_x		 	dq 18
	beta_y		 	dq 10
	my_score		dq 99
	real_time		dq 0
	input 			db 1

	maze	db 	"############E#######",10,\
				"########     #### P#",10,\
				"######## ######## ##",10,\
				"##       # ###### ##",10,\
				"## ####### ###### ##",10,\
				"## ### ###      # ##",10,\
				"##     ### ####   ##",10,\
				"######     #P ###  #",10,\
				"############# #### #",10,\
				"#P       #### ###  #",10,\
				"##### ##      ### ##",10,\
				"###   ## #### ###  #",10,\
				"### #### #### #### #",10,\
				"#   ####  ###    # #",10,\
				"# ##   ######### # #",10,\
				"# ## #  #####P## # #",10,\
				"#  # ## ##### ##   #",10,\
				"##   ##       ### ##",10,\
				"####P##### ######P##",10,\
				"####################",10


section .bss
	saved_attributes	resb 12
	cur_attributes		resb 12	
	c_lflag 			resb 4

section .text

%macro exit 0
	mov rax, 60
    mov rdi, 0
    syscall
%endmacro

GET 	equ 21505
SET 	equ 21506
ICANON	equ 2
ECHO 	equ 8 
;fist param GET or SET, second param place to store
%macro _tc_get_or_set 2
	mov rdx, %2
	mov rax, 16
    mov rdi, 0
    mov rsi, %1
    syscall
%endmacro


;uses rax, rdi, rsi, rdx
_poll_and_read:
	nop
	push rbx
    push rcx
    push rdx
    push rdi
    push rsi
	mov rax, 7
    mov rdi, fd
    mov rsi, 1
    mov rdx, 0 ;timeout
    syscall
    test rax, rax
    jz _end_read ; jump to place where poll didn't work
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 1
    syscall
    xor rax, rax
    mov al, byte[input]
_end_read:
	pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret


_print_check:
	mov	rdi, fmt
	mov	rsi, [my_figure]
	xor	rax, rax
	call printf
	ret

main:
	; call _print_check
	; call _print_score
	call set_input_mode
	mov rax, 18
	mov [my_positionx], rax
	mov rax, 10
	mov [my_positiony], rax

_start_game:
	mov rax, qword [my_positionx]
	mov qword [beta_x], rax
	mov rax, qword [my_positiony]
	mov qword [beta_y], rax
	call _poll_and_read
	; call _print_table
	cmp rax, 0
	je _no_move
	cmp rax, 'w'
	je _up
	cmp rax, 's'
	je _down
	cmp rax, 'a'
	je _left
	cmp rax, 'd'
	je _right
	cmp rax, 'q'
	je _quit
	_quit:
	mov qword [my_score], qword 0
	call _print_table
	jmp _end_programm

	jmp _no_move

_up:
	dec qword [beta_x]
	jmp _finished_input
_down:
	inc qword [beta_x]
	jmp _finished_input
_left:
	dec qword [beta_y]
	jmp _finished_input
_right:
	inc qword [beta_y]
	jmp _finished_input
_no_move:
	jmp _finished_input

;need to check out of bound
_finished_input:
	mov rax, qword [beta_x]
	mov rcx, 21
	mul rcx
	add rax, qword [beta_y]
	cmp byte [maze + rax], '#'
	je _wall
	cmp byte [maze + rax], 'P'
	je _points
	cmp byte [maze + rax], 'E'
	je _change_and_exitt
	jmp _change_pos

	_wall:
		jmp _resume
	_points:
		mov byte[maze + rax], ' '
		add qword [my_score], qword 5
		jmp _change_pos
	_change_pos:
		mov rax, qword[beta_x]
		mov [my_positionx], rax
		mov rax, qword[beta_y]
		mov [my_positiony], rax
		jmp _resume
	_change_and_exitt:
		mov rax, qword[beta_x]
		mov [my_positionx], rax
		mov rax, qword[beta_y]
		mov [my_positiony], rax
		call _print_table
		jmp _end_programm
	_resume:

	xor rax, rax
	inc qword [passed_time]
	cmp qword [passed_time], qword 10
	jne .continue
		mov qword [passed_time], qword 0
		inc qword [real_time]
		dec qword [my_score]
		cmp qword [my_score], qword 0
		jne .continue
			mov rax, 1
	.continue:
	push rax
	call _print_table
	pop rax
	cmp rax, 1
	je _end_programm
	; mov rax, 0
 ;    xor rdi, rdi
 ;    call fflush
	jmp _start_game

_end_programm:
	call reset_input_mode
	xor rax, rax
	ret
	
	

;table size 20*21
_print_table:
	; push rdi
	; xor qword [my_positiony], 1
	xor rdi, rdi
    mov rdi, cls
    xor rax, rax
    xor rsi, rsi
    call printf
    ; pop rdi
	xor rcx, rcx
	xor rdx, rdx;overal counter
	; push rdi
	.row_for:
		cmp rcx, 20
		je .end_row_for
		push rcx
		xor rbx, rbx
		.column_for:
			cmp rbx, 21
			je .end_column_for

			pop rcx
			cmp rcx, [my_positionx]
			push rcx
			jne .skip_if1
				cmp rbx, [my_positiony]
				jne .skip_if1
					mov	rdi, fmt
					mov	rsi, [my_figure]
					xor	rax, rax
					push rdx
					call printf
					jmp .end_if
			.skip_if1:

				pop rcx
				; pop rdi
				mov rsi, [maze + rdx]
				; push rdi
				push rcx
				mov	rdi, fmt
				xor	rax, rax
				push rdx
				call printf
				.end_if:
			pop rdx
			inc rbx
			inc rdx
			jmp .column_for 
		.end_column_for:

		mov	rdi, fmt_sN
		mov	rsi, empty
		xor	rax, rax
		push rdx
		call printf
		pop rdx

		pop rcx
		inc rcx
		jmp .row_for
	.end_row_for:
	call _print_score
	call _print_time
	; sleep a bit
	mov rax, 35
    mov rdi, delay
    xor rsi, rsi
    syscall
    ; pop rdi
	ret

_print_score:
	mov	rdi, fmt_s
	mov	rsi, instr_text
	xor	rax, rax
	call printf
	mov	rdi, fmt_s
	mov	rsi, score_text
	xor	rax, rax
	call printf
	mov	rdi, fmt_d
	mov	rsi, [my_score]
	xor	rax, rax
	call printf
	ret

_print_time:
	mov	rdi, fmt_s
	mov	rsi, time_text
	xor	rax, rax
	call printf
	mov	rdi, fmt_d
	mov	rsi, [real_time]
	xor	rax, rax
	call printf
	ret

reset_input_mode:
	_tc_get_or_set SET, saved_attributes
	ret

set_input_mode:
	;tcgetattr (STDIN_FILENO, &tattr)
	_tc_get_or_set GET, saved_attributes
	_tc_get_or_set GET, cur_attributes
	;tattr.c_lflag &= ~(ICANON|ECHO); /* Clear ICANON and ECHO. */
	and dword[c_lflag], (~ICANON)
	and dword[c_lflag], (~ECHO)
	; tattr.c_cc[VMIN] = 1
	; tattr.c_cc[VTIME] = 0
	; tcsetattr (STDIN_FILENO, TCSAFLUSH, &tattr)
	_tc_get_or_set SET, cur_attributes
	ret


;printf destroys rcx
;nasm -f elf64 -l game.lst  game.asm
;gcc -m64 -o game  game.o 
;./game