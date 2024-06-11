			.macro jeq adr
			bne *+5
			jmp adr
			.endmacro

			.macro jne adr
			beq *+5
			jmp adr
			.endmacro

			.macro jmi adr
			bpl *+5
			jmp adr
			.endmacro

			.macro jpl adr
			bmi *+5
			jmp adr
			.endmacro

			.macro jcc adr
			bcs *+5
			jmp adr
			.endmacro
			.macro jcs adr
			bcc *+5
			jmp adr
			.endmacro

			.macro rotate char
			ldy $3002 + char * 8
			ldx #2
:			lda $3001 + char * 8,x
			sta $3000 + char * 8,x
			inx
			cpx #6
			bne :-
			sty $3005 + char*8
			.endmacro

			joy_speed = 4;

			.import popax
			.import popa

