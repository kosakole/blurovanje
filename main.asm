global _start

SECTION .data
    NEMA DB 'Trazena datoteka ne postoji.', 10
	NEMALEN EQU $-NEMA
	PORUKA DB 'Unesite putanju do fajla: '
	PORUKALEN EQU $-PORUKA
	PORUKA2 DB 'Unesite putanju do izlaznog fajla: '
	PORUKALEN2 EQU $-PORUKA2
	; bitMap times 7372800 db 0

    ;inputFile db 'input.bmp', 0
	inputFile db 'input1.bmp', 0
	;inputFile db '1.bmp', 0
	;inputFile db 'LAND2.BMP', 0
    outputFile db 'output.bmp', 0

SECTION .bss
    
	header  resb 200
    width    resd 1
    height   resd 1

	startBitMap resd 1
	bitMap	 resb 7372800
	bitMap2	 resb 7372800
	bitMap3	 resb 7372800

	numPix	 resd 1

SECTION .text
_start: 

	MOV RAX, 1
	MOV RDI, 1
	MOV RSI, PORUKA
	MOV RDX, PORUKALEN
	syscall

; učitamo ulazni fajl
	MOV RAX, 0
	MOV RDI, 0
	MOV RSI, inputFile
	MOV RDX, 300
	syscall

; terminiramo putanju
	MOV RDI, inputFile
	MOV BYTE [RDI+RAX-1], 0


	MOV RAX, 1
	MOV RDI, 1
	MOV RSI, PORUKA2
	MOV RDX, PORUKALEN2
	syscall

; učitamo izlazni fajl
	MOV RAX, 0
	MOV RDI, 0
	MOV RSI, outputFile
	MOV RDX, 300
	syscall

; terminiramo putanju
	MOV RDI, outputFile
	MOV BYTE [RDI+RAX-1], 0



    ; open file
    MOV RAX, 2
    MOV RDI, inputFile
    MOV RSI, 0
    syscall
	CMP RAX, 0
	JL GRESKA

    ; pozicioniramo se na odgovarajući karakter
	PUSH RAX
	MOV RDI, RAX
	MOV RAX, 8
	MOV RSI, 0
	MOV RDX, 1
	syscall

; citamo dio header
	MOV RAX, 0
	POP RDI
	PUSH RDI
	MOV RSI, header
	MOV RDX, 200
	syscall

;   width
    MOV RAX, [header + 18]
	MOV [width], RAX
	
	

;   height
    MOV RAX, [header + 22]
	MOV [height], RAX
	

;   startBitMap
   	MOV RAX, [header + 10]
	MOV [startBitMap], RAX
	

	MOV RAX, 0
	MOV EAX, [width]
	MOV R9, 3
	MUL R9
	MOV R9, RAX
	MOV R10, [height]
	MUL R10
	MOV R10, RAX
	MOV [numPix], R10
	

; zatvorimo fajl
	MOV RAX, 3
	POP RDI
	syscall

; open file
    MOV RAX, 2
    MOV RDI, inputFile
    MOV RSI, 0
    syscall
	CMP RAX, 0
	JL GRESKA

    ; pozicioniramo se na odgovarajući karakter
	PUSH RAX
	MOV RDI, RAX
	MOV RAX, 8
	MOV RSI, 0
	MOV RDX, 1
	syscall

	MOV RAX, 0
	POP RDI
	PUSH RDI
	MOV RSI, header
	MOV RDX, 0
	MOV EDX, [startBitMap]
	syscall

; 	read pixels
	MOV RAX, 0
    POP RDI
    PUSH RDI
    MOV RSI, bitMap
	MOV RDX, 0
	MOV EDX, [numPix]
    syscall

; zatvorimo fajl
	MOV RAX, 3
	POP RDI
	syscall
	
; 	open file
	MOV RAX, 85
	MOV RDI, outputFile
	MOV RSI, 111111111b
	syscall
	

	;PUSH RDX
	MOV R8, RAX
	MOV RAX, 1
	MOV RDI, R8
	MOV RSI, header
	MOV RDX, 0
	MOV EDX, [startBitMap]
	SYSCALL
	

; 	svaki bit djelim sa 9, pa da kasnije mogu sabrati svaki susjedni
	MOV RAX, 0
	MOV RCX, 0
	MOV RSI, bitMap
	MOV RDI, bitMap2
	PUSH R8
	loop_start:
		CMP ECX, [numPix]
		jge loop_end
		lodsb
		MOV R9, 0
		MOV R9, RAX
		MOV R10, 9			; u R10 registru stavljam vrijednost sa kojom djelim
		MOV R8, 0
		loop2_start:
			CMP R9, R10
			jbe loop2_end
			SUB R9, R10
			ADD R8, 1
			jmp loop2_start
		loop2_end:
		MOV RAX, r8
		stosb
		ADD rcx, 1
		jmp loop_start
	loop_end: 
	POP R8


;	svaki bit sabiram sa susjednim
	PUSH R8
	MOV RAX, 0
	MOV EAX, [width]
	MOV R8, -3
	IMUL r8
	MOV R8, 0
	MOV R8, RAX
	
	MOV RAX, 0
	MOV EAX, [width]
	MOV R13, 3
	IMUL R13
	MOV R13, 0
	MOV R13, RAX

	MOV RAX, 0
	MOV EAX, [width]
	MOV R9, 3
	MUL R9
	MOV R9, rax
	MOV R10, 0
	MOV R10d, [height]
	SUB R10, 1
	MUL R10
	MOV R10, rax
	MOV RAX, 0
	MOV RCX, 0
	MOV R11, 1
	MOV R12, [numPix]

	MOV RSI, bitMap2
	MOV RDI, bitMap3
	
	loop3_start:
		CMP ECX, [numPix]
		jge loop3_end
		lodsb
		
		CMP ECX, [width]  		; rcx <= 3 * width
		
		jbe l1
		CMP R11, 1
		je l3
		MOV R9b, [RSI+R8-4]
		ADD al, R9b
		l3:
		MOV R9b, [RSI+R8-1]
		ADD al, R9b
		CMP R11, width
		jae l1
		MOV R9b, [RSI+R8+2]
		ADD al, R9b
		l1:
		CMP R11, 1
		je l4
		MOV R9b, [RSI-4]
		ADD al, R9b
		l4:
		CMP R11, width
		jae l7
		MOV R9b, [RSI+2]
		ADD al, r9b
		l7:
		CMP RCX, r10  		; rcx >= 3 * width * (height-1) 
		jae l2
		CMP R11, 1
		je l5
		MOV R9b, [RSI+R13-4]
		ADD al, R9b
		l5:
		MOV R9b, [RSI+R13-1]
		ADD al, R9b
		CMP R11, width
		jae l2
		MOV R9b, [RSI+R13+2]
		ADD al, R9b
		l2:
		stosb
		ADD RCX, 1
		CMP R11, width
		jb l6
		MOV R11d, 1
		l6:
		CMP R11, R13
		je l8
		ADD R11, 1
		jmp loop3_start
		l8:
		mov r11, 1
		jmp loop3_start
	loop3_end:	
	POP R8
	


	MOV RAX, 1
	MOV RDI, R8
	MOV RSI, bitMap3
	MOV RDX, 0
	MOV EDX, [numPix]
	
	
p5:
	SYSCALL

; zatvorimo fajl
	MOV RAX, 3
	;POP RDI
	q2:
	syscall
	JMP kraj
GRESKA:
	MOV RAX, 1
	MOV RDI, 1
	MOV RSI, NEMA
	MOV RDX, NEMALEN
	syscall
kraj:	
	MOV RAX, 60
	MOV RDI, 0
	syscall
