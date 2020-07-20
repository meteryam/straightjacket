;@string = internal global [5 x i8] [ i8 0, i8 0, i8 0, i8 0, i8 0 ]
;@printfarg = internal constant [4 x i8] c"%c\0A\00"
;@printfarg = internal constant [4 x i8] c"%llu"
;declare i32 @printf(i8*, ...) nounwind

@addr_int = internal global i32 0
declare i32 @puts(i8*)
;declare dllimport i32 @puts(i8*)
;declare i8* @malloc(i32) nounwind
;declare i32 @putchar(i8*)

define i32 @fun()
{
	%array = malloc [5 x i8]
	;%array = call i8* @malloc(i32 2)
	store [5 x i8] [ i8 104, i8 101, i8 108, i8 108, i8 111 ], [5 x i8]* %array ;hello
	%arrayaddr = getelementptr [5 x i8]* %array, i32 0, i32 0

	;call i32 @puts(i8* %arrayaddr)

	%addr_int = ptrtoint i8* %arrayaddr to i32
	store i32 %addr_int, i32* @addr_int

	ret i32 0
}

; define i32 @__writechar(i32 %n, i8*)
; {
	;; if n > length of array then print exception and halt
	; set num_chunks_traverse to the result of dividing n by 256
	; add 1 to num_chunks_traverse
	; set remainder to the remainder of dividing n by 256
	;; if the remainder = 0 then
		; subtract 1 from num_chunks_traverse
		; add 255 to remainder
	; convert the pointer to the first chunk to prev_int
	;; loop through each chunk until the final chunk is reached
		; convert prev_int to prev_point
		; use prev_point to set next_point
		; set prev_int2 to the integer value of next_point
	; convert prev_int2 to prev_point2
	; use prev_point2 to set array_point
	; use array_point to print the nth element of the array, where n = the remainder

	; ret i32 0
; }

define fastcc i32 @main()
{
enter:
	;store [5 x i8] [ i8 104, i8 101, i8 108, i8 108, i8 111 ], [5 x i8]* @string ;hello
	;%arraypointer = getelementptr [5 x i8]* @string, i64 0, i64 0
	;call i32 @puts(i8* %arraypointer)
	;%Q = add i64 0, 81000000
	;call i32 (i8*, ...)* @printf( i8* getelementptr ([4 x i8]* @printfarg, i32 0, i32 0), i64 %Q)

	call i32 @fun()
	%addr_int2 = load i32* @addr_int
	%back_to_ptr = inttoptr i32 %addr_int2 to i8*
	call i32 @puts(i8* %back_to_ptr)

	; call i32 @__writechar(%__var1)

	br label %exit
exit:
	ret i32 0
}
