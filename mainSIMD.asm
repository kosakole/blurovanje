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

; 	citanje piksela
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

	MOV RSI, bitMap2
	MOV RDI, bitMap3

	PUSH R10
	
	; U registar R10d stavljam broj koji se dobije djeljenjem broja pixela sa 32. Zbog simd operacije
	MOV R9, 0
		MOV R9d, [numPix]
		MOV R10d, 32			
		MOV R8, 0
		loop2_start1:
			CMP R9d, R10d
			jbe loop2_end1
			SUB R9d, R10d
			ADD R8d, 1
			jmp loop2_start1
		loop2_end1:

	MOV R10, 0
	MOV R10d, R8d
	
	MOV RCX, 0
	loop_start1:

		CMP RCX, R10
		Jg loop_end2
		VMOVDQU ymm6, yword[RSI]
		VMOVDQU YMM7, yword[RSI+3]
		VMOVDQU YMM8, yword[RSI - 3]
		VPADDUSB YMM6, YMM7
		VPADDUSB YMM6, YMM8
		
		
		MOV RAX, 0
		MOV EAX, [width]
		MOV R11, -3
		IMUL r11
		MOV R11, 0
		MOV R11, RAX
		


		VMOVDQU YMM7, yword[RSI + R11 - 3]
		VMOVDQU YMM8, yword[RSI + R11]
		VMOVDQU YMM9, yword[RSI + R11 + 3]
		VPADDUSB YMM6, YMM7
		VPADDUSB YMM6, YMM8
		VPADDUSB YMM6, YMM9

		MOV RAX, 0
		MOV EAX, [width]
		MOV R11, -3
		IMUL r11
		MOV R11, 0
		MOV R11, RAX


		VMOVDQU YMM7, yword[RSI + R11 - 3]
		VMOVDQU YMM8, yword[RSI + R11]
		VMOVDQU YMM9, yword[RSI + R11 + 3]
		VPADDUSB YMM6, YMM7
		VPADDUSB YMM6, YMM8
		VPADDUSB YMM6, YMM9
		
		VMOVDQU yword[RDI], ymm6
		ADD RDI, 32
		ADD RSI, 32
		ADD RCX, 1
		JMP loop_start1

	loop_end2:

	POP R10
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
