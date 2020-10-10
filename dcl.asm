FIRST_LEGAL equ 49
FIRST_LEGALTWO equ 98
LAST_LEGAL equ 90
CYCLE equ 42
SYS_EXIT equ 60
BUFF_SIZE equ 128
L equ 76
R equ 82
T equ 84
section .bss
	str: resb 128
	Lperm: resb 42
	Rperm: resb 42
section .text

%macro _check_char 1		;sprawdza czy podany znak jest prawidlowy
	cmp %1, FIRST_LEGAL	;porownuje z 1. legalnym znakiem
	jb exit_err		;jesli mniejszy to koncze kodem 1
	cmp %1, LAST_LEGAL	;porownuje z ostatnim legalnym znakiem
	ja exit_err		;jesli wiekszy to koncze kodem 1 
%endmacro

%macro exit 1			;funkcja konczaca program
	mov edi, %1		;kod wyjscia
	mov eax, SYS_EXIT
	syscall
%endmacro

%macro permutate 2		;1. argument wartosc jaka permutuje, 2. - adres permutacji
	add %2, %1		;przesuwam wskaznik o wartosc do permutacji 
	sub %2, FIRST_LEGAL	;odejmuje wartosc 1. legalnego znaku
	movsx %1, byte [%2]	;zapisuje nowy znak w pierwszym rejestrze
%endmacro

%macro Qperm 2
	sub %1, FIRST_LEGAL	;odejmuje wartosc pierwszego legalnego znaku
	add %1, %2		;dodaje wartosc, na ktora wskazuje bebenek
	mov %2, %1		;w drugim rejestrze zapisuje wariant gdy trzeba odjac
	sub %2, CYCLE		;odejmuje cykl, zeby byc w przedziale
	cmp %1, LAST_LEGAL	;sprawdzam, czy nie wyszedlem za zakres
	cmova %1, %2		;jesli nie to wychodze z funkcji
%endmacro
	
%macro Qrev 2
	sub %2, FIRST_LEGAL	;odejmuje wartosc pierwszego legalnego znaku
				;zeby miec wartosc o jaka przesuwam
	sub %1, %2		;dodaje wartosc, na ktora wskazuje bebenek
	mov %2, %1		;w drugim rejestrze zapisuje wariant gdy trzeba odjac
	add %2, CYCLE		;dodaje cykl, zeby byc w przedziale
	cmp %1, FIRST_LEGAL	;sprawdzam, czy nie wyszedlem za zakres
	cmovb %1, %2		;jesli nie to wychodze z funkcji
%endmacro
global _start

_start:
	mov r8, [rsp]		;zapisuje w r8 liczbe podanych argumentow
	cmp r8, 5		;sprawdzam, czy jest poprawna
	jne exit_err		;jesli nie to koncze program kodem 1
	mov r12, [rsp+40]	;zapisuje w r12 string bedacy kluczem
	movsx edi, byte [r12]  	;do rdi zapisuje pierwszy znak
	_check_char edi		;sprawdzam czy jest poprawny

	movsx edi, byte [r12+1]	;w edi zapisuje drugi znak klucza
	_check_char edi		;sprawdzam czy jest poprawny

	movsx edi, byte [r12+2]	;w edi zapisuje bajt, ktory tam jest
	cmp edi, 0		;jesli nie jest rowny 0			
	jne exit_err		;to koncze program kodem 1

	mov rsi, [rsp+16]	;w rsi zapisuje adres argumentu L
	lea rbx, [Lperm]	;w rbx zapisuje adres pamieci,
				;do ktorej wpisze odwrotnosc lewej permutacji
	call _check_L_R		;funkcja, ktora zapisuje odwrotnosc permutacji
				;w pamieci i sprawdza czy jest poprawna

	mov rsi, [rsp+24]	; analogicznie dla permutacji R
	lea rbx, [Rperm]	;w rbx zapisuje adres pamieci,
				;do ktorej wpisze odwrotnosc prawej permutacji
	call _check_L_R
	
	mov rsi, [rsp+32]	;w rsi zapisuje adres permutacji T

_check_T:			;sprawdzam czy permutacja T jest poprawna
	xor r10d, r10d		;licznik do petli
loop_T:
	movsx edi, byte [rsi+r10] ;r10-aty bajt permutacji T zapisuje w ecx
	_check_char edi
	sub edi, FIRST_LEGAL	;znajduje, ktory z kolei w ciagu jest ten znak
	movsx edi, byte [rsi+rdi] ;znak po permutacji zapisuje w edi
	add r10d, FIRST_LEGAL	;zwiekszam wartosc r10 tak zeby byla poprawnym znakiem ASCII
	cmp edi, r10d		;sprawdzam czy ecx i r10d sa takie same tzn TT jest id 
	jne exit_err		;jesli nie koncze kodem 1
	sub r10d, FIRST_LEGAL	;przywracam r10 do funkcji licznika
	inc r10d		;zwiekszam licznik
	cmp r10d, CYCLE		;sprawdzam czy koniec petli
	jne loop_T		;jesli nie to skok do poczatku petli
	cmp byte [rsi+CYCLE], 0	;sprawdzam czy nie ma wiecej niz 42 znaki
	jne exit_err		;jesli sa to koncze kodem 1
	
set_read:
	xor eax, eax		;ustawiam rejestry do wywolania funkcji systemowej
	xor edi, edi		;czytania BUFF_SIZE znakow, ktore wczytuje
	mov esi, str		;do pamieci oznaczonej str
	mov edx, BUFF_SIZE	;liczba wczytywanych znakow
	syscall		
			
	mov r14d, eax		;w r14 zapisuje liczbe wczytanych znakow
	xor r15d, r15d		;r15 to licznik, ktory iteruje sie po wczytanych znakach

change_first:
	movsx eax, byte [str+r15d]	;zapisuje kolejne znaki z wejscia
	_check_char eax			;sprawdzam poprawnosc znaku
	
	inc byte [r12+1]		;obracam bebenkiem R
	cmp byte [r12+1], LAST_LEGAL	;sprawdzam, czy nie wyszedlem za zakres	
	jbe check_l		;jesli nie to sprawdzam bebenek L
	sub byte [r12+1], CYCLE	;jesli tak to odejmuje dl. cyklu znakow
check_l:
	cmp byte [r12+1], L	;jesli R jest na pozycji 'L'	
	je increase_l		;to zwiekszam bebenek L
	cmp byte [r12+1], R	;jesli R jest na pozycji 'R'
	je increase_l		;to zwiekszam bebenek L
	cmp byte [r12+1], T	;jesli R jest na pozycji 'T'
	je increase_l 		;to zwiekszam bebenek L
	jmp call_encode		;jesli nie jest na zadnej z ww. to szyfruje
increase_l:
	inc byte [r12]		;obracam bebenek L		
	cmp byte [r12], LAST_LEGAL	;sprawdzam, czy znak nie wyszedl poza zakres
	jbe call_encode		;jesli nie to szyfruje
	sub byte [r12], CYCLE 	;jesli tak to cofam o cykl
call_encode:			;znak przechodzi przez ciag permutacji z zadania
	movsx edi, byte [r12+1]	;w edi zapisuje prawy klucz
	Qperm eax, edi		;robie permutacje wczytanego znaku
	
	mov rdi, [rsp+24]	;w rdi zapisuje prawa permutacje
	permutate rax, rdi	

	movsx edi, byte [r12+1]	; edi zapisuje prawy klucz
	Qrev eax, edi		;w rax jest znak do zamiany

	movsx edi, byte [r12]	;w edi zapisuje lewy klucz
	Qperm eax, edi

	mov rdi, [rsp+16]	;w rdi zapisuje lewa permutacje
	permutate rax, rdi

	movsx edi, byte [r12]	;w edi zapisuje lewy klucz
	Qrev eax, edi

	mov rdi, [rsp+32]	; w rdi zapisuje permutacje T
	permutate rax, rdi

	movsx edi, byte [r12]	;w edi zapisuje lewy klucz
	Qperm eax, edi
	
	lea rdi, [Lperm]	;w rdi zapisuje adres odwroconej lewej permutacji
	permutate rax, rdi
	
	movsx edi, byte [r12]	;w edi zapisuje lewy klucz
	Qrev eax, edi

	movsx edi, byte [r12+1]	;w edi zapisuje prawy klucz
	Qperm eax, edi   	

	lea rdi, [Rperm]	;w rdi zapisuje odwrocona prawa permutacje	
	permutate rax, rdi

	movsx edi, byte [r12+1]	;w edi zapisuje prawy klucz
	Qrev eax, edi

save:
	mov byte [str+r15d], al		;zapisuje zakodowany znak na odp. miejscu w str
	inc r15d			;zwiekszam licznik r15
	cmp r15d, r14d		;porownuje licznik z liczba wczytanych znakow
	jb change_first		;jesli jest mniejszy to szyfruje w petli

print:
	mov eax, 1		;ustawiam rejestry tak, zeby wypisywaly na ekran
	mov edi, 1
	lea esi, [str]		;wypisuje na ekran zawartosc str
	mov edx, r14d		;wypisuje tyle znakow, ile wczytalem
	syscall
	cmp r14d, BUFF_SIZE	;jesli wczytalem 128 znakow tzn. ze moglem nie dokonczyc wczytywania
	je set_read		;wiec wykonuje dodatkowy obrot petli
exit_corr:				;funkcja konczaca program kodem 0
	exit 0
exit_err:			;funkcja konczaca program kodem 1
	exit 1

_check_L_R:
	xor r10, r10		;licznik petli

loop_L_R:			
	movsx edi, byte [rsi+r10] ;zapisuje r10-aty znak w edi
	_check_char edi		;sprawdzam czy jest poprawny
	sub edi, FIRST_LEGAL	;znajduje jego numer w ciagu
	cmp byte [rbx + rdi], 0
	jne exit_err
	add r10, FIRST_LEGAL
	add byte [rbx + rdi], r10b
	sub r10, FIRST_LEGAL
	inc r10			;zwiekszam licznik petli
	cmp r10, CYCLE		;sprawdzam czy koniec petli
	jne loop_L_R		;jesli nie to skok do poczatku petli
	cmp byte [rsi+r10], 0
	jne exit_err
	ret
	
