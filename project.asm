		.data
		# Wiadomosci tekstowe
f_open_err_msg:	.asciiz "Blad otwarcia pliku\n"
end_msg:	.asciiz "\n*** Koniec dzialania programu ***\n"
		# Dane plikow
plik_do_odcz:	.space 50
plik_do_zap:	.space 50
		#
buffer:		.space 1024
buffer_new:	.space 1024
temp_array: 	.space 4
	
		.text
		.globl main

main:
	li	$v0, 8	
	la	$a0, plik_do_odcz	# Odczytuje sciezke do pliku wejsciowego
	li	$a1, 50
	syscall
	
	li	$v0, 8	
	la	$a0, plik_do_zap	# Odczytuje sciezke do pliku wysciowego
	li	$a1, 50
	syscall
	
	la	$t0, plik_do_odcz
null_t:					# trzeba zrobic null-terminated string
	lb	$t1, ($t0)
	beq	$t1, '\n', nowa_linia
	sb	$t1, ($t0)
	addiu	$t0, $t0, 1
	j null_t
	
nowa_linia:
	move	$t1, $zero
	sb	$t1, ($t0)
	
	la	$t0, plik_do_zap
null_w:					# trzeba zrobic null-terminated string
	lb	$t1, ($t0)
	beq	$t1, '\n', nowa_linia_
	sb	$t1, ($t0)
	addiu	$t0, $t0, 1
	j null_w
	
nowa_linia_:
	move	$t1, $zero
	sb	$t1, ($t0)

	# Otwieram plik do odczytu
  	li 	$v0, 13
  	la 	$a0, plik_do_odcz
  	li 	$a1, 0
  	li 	$a2, 0
 	syscall
  	bltz 	$v0, f_open_err # Cos jest nie tak z odczytem pliku
  	move 	$s0, $v0 	# Pamietamy deskryptor $s0
  	
  	# Otwieram plik do zapisu
 	li	$v0, 13
 	la	$a0, plik_do_zap
 	li	$a1, 1
 	li	$a2, 0
 	syscall
 	bltz	$v0, f_open_err
 	move 	$s1, $v0 
  	
# Read Data from File
read_file:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s0	# Load File Descriptor
	la	$a1, buffer	# Load Buffer Address
	li	$a2, 1024	# Buffer Size
	syscall
	beq	$v0, 0, save_file
	move	$s2, $v0
	blt	$s2, 4, finished	# Bo w mniej niz 4 bajtach sie nie zmiesci
	addiu	$s3, $s2, -3
  	
	# Odczytuje po kolei symboli z bufora
	la	$t9, buffer_new	# Load new_Buffer Address
	la 	$t0, buffer	# Load Buffer Address
	la	$t3, temp_array	# Load Array Address
	li	$t8, 0		# Licznik odczytanych symboli
	li	$t7, 0		# Licznik zapisanych symboli
	
read_byte:
	bgt	$t8, $s3, finished	# Sprawdzam, czy nie trzeba juz konczyc
	lb	$t1, ($t0)		# Load Buffer Address Data
	beq	$t1, '0', zero_detected	# Jak wystapi zero
	sb	$t1, ($t9)		# Zapisz do nowego bufora
	addiu	$t9, $t9, 1		# adres nowego ++, czyli nast el-t
	addiu	$t7, $t7, 1		# Zwiekszam licznik zapisanych symboli
	addiu	$t0, $t0, 1		# Nie ma zera -> bufor address ++
	addiu	$t8, $t8, 1		# Zwiekszam licznik odczytanych symboli
	j	read_byte
	
zero_detected:
	# Sprawdzamy bajt po zerze ($t0 wskazuje na to zero)
	addiu	$t2, $t0, 1		# Odczytuje adres tego nast. bajta (do rej. $t2)
	lb	$t1, ($t2)		# Odczytuje wartosc bajta po zerze
	beq	$t1, 'x', hex_detected	# Jak jext to x, to wiemy ze mamy 0x, czyli liczbe 16.wa
	blt	$t1, '0', bad_number	#
	bgt	$t1, '7', bad_number	#

octal_detected:
	bgt	$t1, '1', bad_number	# Jak ta druga cyfra jest wieksza od jeden to nie pasuje
	addiu	$t4, $t2, 1
	lb	$t1, ($t4)
	beq	$t1, '\n', bad_number	# Read bait after 0[0..1][ten]
	beq	$t1, ',', bad_number	# 
	beq	$t1, ' ', bad_number	#
	addiu	$t4, $t2, 2
	lb	$t1, ($t4)
	beq	$t1, '\n', bad_number	# Read bait after 0[0..1]Z[ten]
	beq	$t1, ',', bad_number	# 
	beq	$t1, ' ', bad_number	#
	addiu	$t4, $t2, 3			# Read bait after 0[0..1]ZZ[ten]
	lb	$t1, ($t4)			#
	beq	$t1, '\n', octal_confirmed	# 
	beq	$t1, ',', octal_confirmed	# 
	beq	$t1, ' ', octal_confirmed	#
	j	bad_number

octal_confirmed:
	la	$t3, temp_array
	lb	$t1, ($t2)	# Odczytuje pierwsza wartosc po zerze 0[0albo1-TO]
	sb	$t1, ($t3)	# Przepisuje ja do temp_array
	addiu	$t3, $t3, 1	# Przesuwam Array adres ++ by nie zapisac powierch
	addiu	$t2, $t2, 1	# Przesuwam sie
	lb	$t1, ($t2)	# Odczytuje wartosc po 0[0..1][ten]
	sb	$t1, ($t3)	# Przepisujemy wartosc do temp array
	addiu	$t3, $t3, 1	# Przesuwam Array adres ++ by nie zapisac powierch
	addiu	$t2, $t2, 1	# Przesuwam wsk na nast wartosc
	lb	$t1, ($t2)	# Odczytuje ta druga wartosc 0[0..1]Z[ten]
	sb	$t1, ($t3)	# Przepisujemy wartosc do temp array
	la	$t3, temp_array	# Load Array Address
				# Mamy naszego octala
				# Przetwarzam go na postac dziesietna
	lb	$t1, ($t3)	# Odczytaj pierwszy symbol
	addiu	$t1, $t1, -48
	sll	$t5, $t1, 3
	sll	$t5, $t5, 3
	addiu	$t3, $t3, 1	# Odczytaj nast wartosc
	lb	$t1, ($t3)	#
	addiu	$t1, $t1, -48
	sll	$t6, $t1, 3	
	addu	$t5, $t5, $t6	# Dodaj do wyniku
	addiu	$t3, $t3, 1	# Odczytaj nast wartosc
	lb	$t1, ($t3)	#
	addiu	$t1, $t1, -48
	addu	$t5, $t5, $t1	# Dodaj do wyniku
	j	number_stored

	
hex_detected:
	addiu	$t2, $t2, 1	# Read bait after 0x
	lb	$t1, ($t2)
	blt	$t1, '3', bad_number	# Sprawdzam czy sie miesci w zakresie 0..Z
	bgt	$t1, '7', bad_number	#
	addiu	$t4, $t2, 2			# Sprawdzam trzeci symbol liczby
	lb	$t1, ($t4)			#
	beq	$t1, '\n', hex_confirmed	# 
	beq	$t1, ',', hex_confirmed		# 
	beq	$t1, ' ', hex_confirmed		#
	j	bad_number
hex_confirmed:		# Wszystkie warynki sa OK
	la	$t3, temp_array	
	lb	$t1, ($t2)	# Odczytuje wartosc po 0x
	sb	$t1, ($t3)	# Przepisujemy wartosc do temp array
	addiu	$t3, $t3, 1	# Przesuwam Array adres ++ by nie zapisac powierch
	addiu	$t2, $t2, 1	# Przesuwam wsk na nast wartosc
	lb	$t1, ($t2)	# Odczytuje ta druga wartosc
	sb	$t1, ($t3)	# Przepisujemy wartosc do temp array
	la	$t3, temp_array	# Load Array Address
				# Mamy naszego hex'a
				# Przetwarzam go na postac dziesietna
	lb	$t1, ($t3)	# Odczytaj pierwszy symbol
	addiu	$t1, $t1, -48	# Zamien wartosc na liczbe

count_hex:
	sll	$t5, $t1, 4
	addiu	$t3, $t3, 1	# Odczytaj nast wartosc
	lb	$t1, ($t3)	#
	bgt	$t1, 64, hex	# Jak to jest litera
	addiu	$t1, $t1, -48	# Jak jest to liczba, czyli zaden z powyzszych beq nie jest spelniony
count:	addu	$t5, $t5, $t1	# Dodaj do wyniku	
	j	number_stored	
hex:				#przetwarzamy litere
	subiu	$t1, $t1, 65
	addiu	$t1, $t1, 10
	j	count
	
bad_number:			# Nie pasuje, trzeba go przepisac jak jest
	lb	$t1, ($t0)	# Odczytaj wartosc bufora
	sb	$t1, ($t9)	# Zapisz do new_bufora
	addiu	$t0, $t0, 1	# Przesun sie na nastepny symbol
	addiu	$t9, $t9, 1	# Zwieksz adres new_buf
	addiu	$t7, $t7, 1	# Zwiekszam licznik zapisanych symboli
	addiu	$t8, $t8, 1	# Zwieksz licznik odczytanych symboli
	lb	$t1, ($t0)	# Odczytaj wartosc bufora
	beq	$t1, '\n', read_byte	# Jak przepisano juz cala liczbe
	beq	$t1, ',', read_byte	# 
	beq	$t1, ' ', read_byte	#
	j bad_number
	
number_stored:
					# Sprawdzam, czy wartosc odpowiada zakresowi 0..9A..Za..z
	blt	$t5, 48, bad_number				
					
	beq	$t5, 58, bad_number
	beq	$t5, 59, bad_number
	beq	$t5, 60, bad_number
	beq	$t5, 61, bad_number
	beq	$t5, 62, bad_number
	beq	$t5, 63, bad_number
	beq	$t5, 64, bad_number
		
	beq	$t5, 91, bad_number
	beq	$t5, 92, bad_number
	beq	$t5, 93, bad_number
	beq	$t5, 94, bad_number
	beq	$t5, 95, bad_number
	beq	$t5, 96, bad_number
	
	bgt	$t5, 122, bad_number
	
	li	$t4, 39		# Zaladuj ciapke do rejestru
	sb	$t4, ($t9)	# Zapisz na wyjsciu '
	addiu	$t9, $t9, 1	# przenies sie na nast miejsce
	sb	$t5, ($t9)	# Zapisz na wyjsciu wartosc ASCII
	addiu	$t9, $t9, 1	#
	sb	$t4, ($t9)	# Zapisz na wyjsciu '
	addiu	$t9, $t9, 1	# przenies sie na nast miejsce
	addiu	$t0, $t0, 4	# Przesuwamy wsk za nasza oct/hex wartosc
	addiu	$t7, $t7, 3	# Zwiekszam licznik zapisanych symboli
	addiu	$t8, $t8, 4	# Zwiekszam licznik odczyt symboli
	j	read_byte
	

finished:
	lb	$t1, ($t0)	#Zapisuje pozostale 3 wartosci do new_bufora
	sb	$t1, ($t9)	# Zapisz do nowego bufora
	addiu	$t9, $t9, 1	# adres nowego ++, czyli nast el-t
	addiu	$t0, $t0, 1	# Odczytuje nastepny bajt
	addiu	$t7, $t7, 1	# Zwiekszam licznik zapisanych symboli
	addiu	$t8, $t8, 1	# Zwiekszam licznik odczyt symboli
	beq	$t8, $s2, save_file	#
	j finished

# Zapisuje plik
save_file:
  	# Zapisuje do pliku
	li 	$v0, 15
	move 	$a0, $s1 
	la 	$a1, buffer_new
 	move 	$a2, $t7 		# Zapisujemy caly plik
 	syscall
 	
 	beq	$s2, 1024, read_file	# Jak podejrzewamy, ze plik byl odczytany nie calosciowo
 	
 	# Zamykam plik
 	li 	$v0, 16
 	move 	$a0, $s1
 	syscall
 	
 	li 	$v0, 16
 	move 	$a0, $s0
 	syscall
 	b 	end  	
  	
# Blad otwarcia pliku
f_open_err:
  	li 	$v0, 4 
  	la 	$a0, f_open_err_msg
  	syscall
    
# Zakonczenie programu
end:
  	li 	$v0, 4 
  	la 	$a0, end_msg 
  	syscall
  	li 	$v0, 10
  	syscall
