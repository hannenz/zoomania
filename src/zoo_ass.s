;---------------------------------------------------------------------------------------
;zoo mania assembler routines
;04/2004 hannenz
;---------------------------------------------------------------------------------------
;0			ingame 1
;1			ingame 2
;2			title screen
;3			level up
;4			time out
;5			hi score
;---------------------------------------------------------------------------------------
.export __check_matrix
.export _appear
.export _ass_setup
.export _bmp_data
.export _broesel
.export _check_moves
.export _clone
.export _colortab,_highscore,_matrix
.export _cue,_cue_max,_demo,_pl, _team, _tt
.export _cursor_on,_cursor_off
.export _delay
.export _display_time
.export _do_bar
.export _fill
.export _fill_matrix
.export _fld
.export _fld_done
.export _game_irq
.export _get_random_symb
.export _getfromcue
.export _getkey
.export _gfx_mode
.export _init_msx;
.export _interrupt_handler
.export _isstop
.export _key,_timer_delay,_stop,_time_out,_joker_tmp,_joker,_animals,_level
.export _kill_joker
.export _load_hs
.export _load_vector,_save_vector,_time1,_players,_joker_x,_joker_y
.export _move_matrix
.export _pet2scr
.export _plot2x2_xy
.export _plot_score
.export _pm_x1,_pm_x2,_pm_y1,_pm_y2
.export _print2x2_centered
.export _print3x3
.export _put2cue
.export _random
.export _save_hs
.export _screen_off, _screen_on
.export _setgfx
.export _title_irq
.export _txt_mode
.export _wait
.export _wait_for_key_or_joy
.export _xpos1,_xpos2,_ypos1,_ypos2,_xdir1,_xdir2,_ydir1,_ydir2
.export _yesno

; ---------------------------------------------------------------
			; include symbols for common c64 locations
			.include "c64.inc"
			.include "macros.inc"
; ---------------------------------------------------------------
			.segment "DAT"
; ---------------------------------------------------------------
			;include data (charsets, sprites, msx)
			; skip the first two bytes 
			; .segment DAT is at 0x0dc0 
			.incbin "data/zoo.dat", 2

_colortab:	.byte 1,1,2,5,6,4,7,3
_highscore:	.res 160
_matrix:	.res 64


; ---------------------------------------------------------------
			.segment "RODATA"
; ---------------------------------------------------------------
_bmp_data:	.incbin "data/zootitle.pic", 2


; ---------------------------------------------------------------
			.segment "CODE"
; ---------------------------------------------------------------

;---------------------------------------------
;void __fastcall__ init_msx(unsigned char);
;---------------------------------------------
_init_msx:	jmp $1000

;---------------------------------------------------
;void init_irq(void);
;---------------------------------------------------
;inits the irq running in-game


_game_irq:	sei
			lda #<_interrupt_handler
			ldx #>_interrupt_handler
			ldy #0
			sta IRQVec
			stx IRQVec + 1
			sty VIC_HLINE
			asl VIC_IRR
			lda #$18
			sta VIC_CTRL2
			lda #0
			sta VIC_BG_COLOR0
			lda #$1b
			sta VIC_CTRL1
			cli
			rts
;---------------------------------------------------
;void __fastcall__ fld(char at	_row);
;---------------------------------------------------
;little fld when scrolling out the main menu screen


_fld:		sei
			asl
			asl
			asl
			clc
			adc #$33	;line*8 + $33, start of fld
			sta VIC_HLINE
			sta fld_line+1
			lda #255
			sec
			sbc fld_line+1
			sta fld_tmp

			lda #$28
			jsr _setgfx
			ldx #0
			stx VIC_CTRL2
			stx VIC_BG_COLOR0
			stx _fld_done
			inx
			stx fld+1
			lda #<fld
			ldx #>fld
			sta IRQVec
			stx IRQVec + 1
			lda #$1b
			sta VIC_CTRL1
			asl VIC_IRR
			cli
			rts

fld:		ldx #1
@loop:		lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3
			and #7
			ora #$10
			sta VIC_CTRL1
			dex
			bne @loop

			lda #8
			ldx VIC_HLINE
			cpx VIC_HLINE
			beq *-3
			sta VIC_BG_COLOR0

			asl fld+1
			lda fld+1
			cmp fld_tmp
			bcc @skip
			sta _fld_done
			lda #0
			sta VIC_BORDERCOLOR

@skip:			asl VIC_IRR
			lda #<fld1
			ldx #>fld1
			ldy #255
			jmp out1

fld1:			lda #$1b
			sta VIC_CTRL1
			lda #0
			sta VIC_BG_COLOR0

			jsr $1003
			asl VIC_IRR
			lda #<fld
			ldx #>fld
fld_line:		ldy #0
			jmp out1

;---------------------------------------------------
;void setup_title_irq(void);
;---------------------------------------------------
;setup the irq runnnig in the main menu screen


_title_irq:		sei
			lda #$7f
			sta CIA1_ICR
			sta CIA2_ICR
			lda CIA1_ICR
			lda CIA2_ICR
			lda #1
			sta VIC_IMR
			lda #$1b
			sta VIC_CTRL1

			lda #<title_irq
			ldx #>title_irq
			ldy #$fa
			sta IRQVec
			stx IRQVec + 1
			sty VIC_HLINE
			asl VIC_IRR
			lda #<(scroll_text-1)
			ldx #>(scroll_text-1)
			sta $7a
			stx $7b
			cli
			rts
;---------------------------------------------------------
_inter_irq:		sei
			lda #<irq_x
			ldx #>irq_x
			ldy #$c2
			sta IRQVec
			stx IRQVec + 1
			sty VIC_HLINE
			lda #$1b
			sta VIC_CTRL1
			asl VIC_IRR
			cli
			rts
;---------------------------------------------------
;interrupt handler
;---------------------------------------------------
;in-game irq routine


_interrupt_handler:	;jsr __game_interrupt
			;jmp $ea31

__game_interrupt:	asl VIC_IRR		;acknoledge raster irq

			lda count
			beq get_joy

			lda VIC_SPR7_X		;move cursor
			clc
			adc _xdir1
			sta VIC_SPR7_X
			lda VIC_SPR7_Y
			clc
			adc _ydir1
			sta VIC_SPR7_Y

			lda _players
			beq @skip

			lda VIC_SPR6_X
			clc
			adc _xdir2
			sta VIC_SPR6_X
			lda VIC_SPR6_Y
			clc
			adc _ydir2
			sta VIC_SPR6_Y

@skip:			dec count
			jmp timer

get_joy:		ldy _tt
			lda CIA1,y		;get joystick
			and #$7f

			ldx _demo		;if in demo mode get movement from cue
			beq @skip
			ldx _cue_max
			jsr _getfromcue
			jeq timer		;nothing waiting in the cue, then skip

@skip:			ldx #0			;we will need a zero
			cmp #126
			bne @joy1
			lda _ypos1		;if ypos is 0 then up isn't possible
			beq @joy4		;so skip
			dec _ypos1		;decrease ypos
			lda #256 - joy_speed
			sta _ydir1		;load the value to add to the sprite y coordinate
			stx _xdir1		;.x is alwayx 0, no x-movement
			jmp @joy5		;skip the following

@joy1:			cmp #125
			bne @joy2
			lda _ypos1
			cmp #7
			beq @joy4
			inc _ypos1
			lda #joy_speed
			sta _ydir1
			stx _xdir1
			jmp @joy5

@joy2:			cmp #123
			bne @joy3
			lda _xpos1
			beq @joy4
			dec _xpos1
			lda #256 - joy_speed
			sta _xdir1
			stx _ydir1
			jmp @joy5

@joy3:			cmp #119
			bne @joy4
			lda _xpos1
			cmp #7
			beq @joy4
			inc _xpos1
			lda #joy_speed
			sta _xdir1
			stx _ydir1
			jmp @joy5

@joy4:			stx _xdir1		;no joy input from joy#1, then both dir's are 0
			stx _ydir1
			jmp get_joy2

@joy5:			lda #6			;counter for sprite movement (6*4 pixels => move 24 pixels)
			sta count

get_joy2:		lda _players		;only one player?
			beq timer		;then skip this...

			lda CIA1_PRB		;check joy#2, see above
			ldx #0

			cmp #254
			bne @joy1
			lda _ypos2
			beq @joy4
			dec _ypos2
			lda #256 - joy_speed
			sta _ydir2
			stx _xdir2
			jmp @joy5

@joy1:			cmp #253
			bne @joy2
			lda _ypos2
			cmp #7
			beq @joy4
			inc _ypos2
			lda #joy_speed
			sta _ydir2
			stx _xdir2
			jmp @joy5

@joy2:			cmp #251
			bne @joy3
			lda _xpos2
			beq @joy4
			dec _xpos2
			lda #256 - joy_speed
			sta _xdir2
			stx _ydir2
			jmp @joy5

@joy3:			cmp #247
			bne @joy4
			lda _xpos2
			cmp #7
			beq @joy4
			inc _xpos2
			lda #joy_speed
			sta _xdir2
			stx _ydir2
			jmp @joy5

@joy4:			stx _xdir2
			stx _ydir2
			jmp timer

@joy5:			lda #6
			sta count

			;timer

timer:			lda _stop		;if the stop flag
			bne joker		;don't do the timer stuff

			lda _time1		;if the timer is decremented to zero yet
			ora _time1 + 1
			bne do_timer

			lda #1
			sta _time_out		;set a flag for the main program
			bne joker		;and skip the following

do_timer:		dec del			;respect timer delay
			bne joker
			lda _timer_delay
			sta del

			lda _time1		;decrease timer...
			bne *+5
			dec _time1+1
			dec _time1

			jsr _display_time	;and display the bar

			;joker

joker:			lda _joker		;is there a joker running...??!
			jeq exit		;no, then skip

			dec joker_delay		;respect delay value
			lda joker_delay
			and #7			;every 8th frame...
			bne exit

			inc _joker_tmp		;increase the icon to display
			lda _joker_tmp
			cmp _animals		;if it is larger than possible animals in this level?
			bcc @skip
			lda #0			;then reset to zero
			sta _joker_tmp

@skip:			ldy _joker_y		;claculate screen ram adress to display the joker at

			lda ytab_hi,y
			sta $f5

			lda _joker_x
			asl
			clc
			adc _joker_x		;joker_x * 3 + xoffs
			clc
			adc ytab_lo,y
			bcc *+4
			inc $f5
			clc
			adc #2
			sta $f4
			bcc *+4
			inc $f5			;$f4/$f5 points to screen ram adress

			ldx _joker_tmp
			lda _colortab,x		;get proper color for the icon
			ora #8
			sta @col+1
			txa
			asl
			asl
			asl
			clc
			adc _joker_tmp		;multiply the icon code by 9 to get character code of first 3x3 char

			ldx #3			;count rows to draw

@lp2:			ldy #0
@lp1:			sta ($f4),y		;draw one character
			pha			;do color ram stuff..., remember accu value (character code)
			lda $f5			;(use current lo byte of pointer but alter hibyte to point to color ram)
			pha			;remember old hi byte
			and #3
			ora #$d8		;let it point to colorram
			sta $f5
@col:			lda #0			;plot color
			sta ($f4),y
			pla			;restore hibyte (screen ram)
			sta $f5
			pla			;restore accu (char code)
			clc
			adc #1			;and increase it
			iny
			cpy #3			;3 times in x-dir
			bne @lp1		;then goto next line
			pha
			lda $f4
			clc
			adc #$28		;(add 40 to pointer)
			sta $f4
			bcc *+4
			inc $f5
			pla
			dex			;and do 3 rows...
			bne @lp2

exit:			jsr $1003		;play that funky music :)
			dec rotate_delay	;rotate the chars of the timer bar
			lda rotate_delay	;each 4th frame
			and #3
			jne skip_rotate

			rotate 254
			rotate 253
			rotate 252
			rotate 251
			rotate 250
			rotate 249
			rotate 248
			rotate 247
skip_rotate:		jmp $ea31


;draw the timer bar

_display_time:		lda _time_out
			bne done
			lda _time1
			ldx _time1+1
			stx aux		;.A still has time1 lo byte
			lsr aux		;time1 is max. NMIVec + 1, so max. 1 bit set in Hibyte
			ror		;rotate right over 3 bytes (Hi,Lo,Remainder)
			ror rem
			lsr		;rotate right over 2 Bytes (Lo,Remainder)
			ror rem
			lsr
			ror rem
			tax		;time1 / 8
			lda rem 	;rotate rem right 5 times to get the remainder right
			lsr
			lsr
			lsr
			lsr
			lsr
			clc
			adc #$f6	;screen code of proper 'part' bar character
			sta $07c0,x
			lda #$fe	;screen code: 'full' bar char
l1:			dex
			bmi done
			sta $07c0,x
			jmp l1
done:			rts

;---------------------------------------------------------------------------------
;void print2x2_centered (char *string,char color1,char color2,char line);
;---------------------------------------------------------------------------------

_print2x2_centered:	sta line		;line
			jsr popa
			sta color2		;color2
			jsr popa
			sta color1
			jsr popax		;get strinf
			sta $fc
			stx $fd

			ldy line
			lda tab_lo,y
			sta $fe
			lda tab_hi,y
			sta $ff

			;calc length

			ldy #$ff
loop:			iny
			lda ($fc),y
			bne loop
			sty aux
			lda #20
			sec
			sbc aux
			clc
			adc $fe
			sta $fe
			bcc *+4
			inc $ff

			ldy #0
			sty tmp

loop2:			ldy tmp
			lda ($fc),y
			beq p2x2_done
			jsr plot2x2
			inc tmp
			jmp loop2

p2x2_done:		rts
;---------------------------------------------------------------------------------
;void __fastcall__ plot2x2_xy (char c,char x,char y,char color1,char color2);
;---------------------------------------------------------------------------------

_plot2x2_xy:		sta color2	;store 'low' color
			jsr popa	;get 'high' color
			sta color1	;store it
			jsr popa	;get y
			sta line	;store
			jsr popa	;get x
			ldy line
			clc
			adc tab_lo,y	;line * 40 + x
			sta $fe		;in pointer lo-byte
			lda tab_hi,y	;hi-byte
			adc #0		;respect carry from addition of x
			sta $ff		;into pointer hi-byte
			jsr popa	;get 'character' to plot

plot2x2:		ldy #0
			ldx #0

			jsr _pet2scr	;convert into screen code
			asl		;screen code * 4
			asl
			sta ($fe),y	;store fisrt char
			jsr docol	;color it
			clc
			adc #1		;increase screen code by 1
			iny
			sta ($fe),y
			jsr docol
			clc
			adc #1

			inx
			pha		;remember screen code
			lda $fe		;pointer to next line
			clc
			adc #40
			sta $fe
			bcc @skip
			inc $ff
@skip:			pla

			ldy #0
			sta ($fe),y
			jsr docol
			iny
			clc
			adc #1
			sta ($fe),y
			jsr docol
			lda $fe
			sec
			sbc #38
			sta $fe
			bcs *+4
			dec $ff
			rts

docol:			pha
			lda $ff
			pha
			and #3
			ora #$d8
			sta $ff
			lda color1,x
			sta ($fe),y
			pla
			sta $ff
			pla
			rts


;---------------------------------------------
;void __fastcall__ setgfx(unsigned int);
;---------------------------------------------

_setgfx:	ldx #4		; is this "hardcoded" hi-byte of the __AX__ ??
			ldy #0
			sty d1
			; d1 = 0
			; tmp = .A * 4
			asl
			rol d1
			asl
			rol d1
			sta tmp

			txa		; #4
			lsr
			lsr		; .X / 4
			ldx #4
loop1:		asl tmp		; tmp *= 8
			rol
			dex
			bne loop1
			sta VIC_VIDEO_ADR

			; Select VIC Bank
			lda CIA2_PRA		
			and #$fc
			ora d1
			eor #3
			sta CIA2_PRA
			rts

;---------------------------------------------
;void __fastcall__ wait(unsigned char raster);
;---------------------------------------------

_wait:		cmp VIC_HLINE
			bne _wait
			rts
;---------------------------------------------
;unsigned char random(void);
;---------------------------------------------

_random:	lda #0
			eor CIA1_TA
			eor CIA1_TA + 1
			eor CIA2_TA
			eor CIA2_TA + 1
			eor CIA2_TB
			eor CIA2_TB + 1
			sta _random+1
			rts

;---------------------------------------------
;unsigned char __fastcall__ pet2scr(unsigned char);
;---------------------------------------------

_pet2scr:	eor #$e0
			clc
			adc #$20
			bpl cont
			adc #$40
			bpl cont
			eor #$a0
cont:		rts

;------------------------------------------------
;unsigned char isstop(void)
;------------------------------------------------

_isstop:	lda #$7f
			sta CIA1
			cmp CIA1_PRB
			beq no
			lda #1
			rts
no:			lda #0
			rts

;----------------------------------------------------
;void wait_for_key_or_joy(void);
;----------------------------------------------------

_wait_for_key_or_joy:
	rts
			lda _demo
			bne @exit
			lda CIA1_PRA
			cmp #111
			beq @exit
			lda CIA1_PRB
			cmp #239
			bne _wait_for_key_or_joy
@exit:			rts

;--------------------------------------------------------------
;unsigned char _check_matrix(void);
;--------------------------------------------------------------
__check_matrix:
			;first we check horizontally

			lda #0
			sta cmxi		;count the rows
@loop2:			lda #0
			sta cmxj		;count the column
@loop1:			lda cmxi
			ldx cmxj
			jsr get_matrix		;.Y has index in _matrix of cmxi/cmxj, .A has value of _matrix,y
			cmp _matrix+1,y		;is it the same as its next neighbour?
			bne @no			;no then increas x position and try again
			cmp _matrix+2,y		;if we are here, two are same and testing the third neighbour
			bne @no_2		;if not equal we can advance by 2 in x dir !
			jmp @success		;three equal--> exit success
@no_2:			inc cmxj
@no:			inc cmxj
			lda cmxj
			cmp #6			;we need to test only up to xpos 5
			bcc @loop1
			inc cmxi		;next row
			lda cmxi
			cmp #8
			bne @loop2		;all 8 rows checked...?!

			;check vertically

			lda #0
			sta cmxj

@loop4:			lda #0
			sta cmxi
@loop3:			lda cmxi
			ldx cmxj
			jsr get_matrix
			cmp _matrix+8,y
			bne @no2
			cmp _matrix+16,y
			bne @no2
@success:
			lda #1
			rts
@no2:			inc cmxi
			lda cmxi
			cmp #6
			bne @loop3
			inc cmxj
			lda cmxj
			cmp #8
			bne @loop4

			lda #0
			rts

;-----------------------------------------------------------------------
title_irq:		ldx #1
			lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3

			stx VIC_BG_COLOR0

			lda #$f0
			cmp VIC_HLINE
			bne *-3

			dec scroll
			dec scroll
			lda scroll
			and #7
			sta VIC_CTRL2

			lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3

			ldx #7
barlp:			lda barcolor_tab,x
			ldy VIC_HLINE
			cpy VIC_HLINE
			beq *-3
			sta VIC_BG_COLOR0
			dex
			bpl barlp

			lda #$fc
			cmp VIC_HLINE
			bne *-3
			lda #0
			sta VIC_BG_COLOR0
			sta VIC_CTRL2

			asl VIC_IRR

			lda #0
			sta CIA2_PRA
			lda #$38
			sta VIC_VIDEO_ADR
			lda VIC_CTRL1
			ora #$20
			sta VIC_CTRL1
			lda #$10
			sta VIC_CTRL2
			jsr $1003

			dec bar_delay
			lda bar_delay
@xyz:			and #1
			sta bar_delay
			bne @skip


			ldx barcolor_tab	;4
			ldy #0			;2
@loop:			lda barcolor_tab+1,y	;4
			sta barcolor_tab,y	;4		;80
			iny			;6
			cpy #31			;4
			bne @loop		;3
			txa			;2
			sta barcolor_tab,y	;4		;99

@skip:			lda scroll
			and #7
			bne out2

			ldx #0
gklp:			lda $07c1,x
			sta $07c0,x
			lda $dbc1,x
			sta $dbc0,x
			inx
			cpx #$27
			bne gklp
			inc $7a
			bne *+4
			inc $7b
wrap:			ldy #0
			lda ($7a),y
			bne okok
			lda #<scroll_text
			ldx #>scroll_text
			ldy #1
			sty _demo
			sta $7a
			stx $7b
			jmp wrap
okok:			cmp #$10
			bcs okok1
			sta $dbc0+39
			bcc out2
okok1:			jsr _pet2scr
			ora #$80
			sta $07e7
out2:			lda #<title_irq2
			ldx #>title_irq2
			ldy #$ba - 2
out1:			sta IRQVec
			stx IRQVec + 1
			sty VIC_HLINE
out3:			pla
			tay
			pla
			tax
			pla
			rti



title_irq2:		ldx #1
			lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3
			stx VIC_BG_COLOR0
			ldx #$1b
			lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3
			stx VIC_CTRL1
			dex
			stx VIC_VIDEO_ADR
			ldx #3
			lda VIC_HLINE
			cmp VIC_HLINE
			beq *-3
			stx CIA2_PRA

			ldx #8
			lda #$bc
			cmp VIC_HLINE
			bne *-3
			stx VIC_BG_COLOR0

			lda #0
			sta VIC_CTRL2

			asl VIC_IRR
			lda #<title_irq
			ldx #>title_irq
			ldy #$f0 - 1
			sta IRQVec
			stx IRQVec + 1
			sty VIC_HLINE
			jmp out1
;---------------------------------------------------------------------------------
;void ass_setpu(void)
;---------------------------------------------------------------------------------

nmi:			pha
			lda #140
			sta _key
			pla
			rti


_ass_setup:
;			jsr $ff8a	;restore Vectors
;			jsr $e3bf	;init BASIC-RAM

			lda #<nmi
			ldx #>nmi
			sta NMIVec
			stx NMIVec + 1

			lda #11
			sta VIC_BG_COLOR1
			sta VIC_SPR_MCOLOR0
			lda #8
			sta VIC_BG_COLOR2
			sta VIC_SPR_MCOLOR1
			ldx #2
			stx VIC_SPR6_COLOR
			dex
			stx VIC_SPR7_COLOR
			dex
			stx VIC_BORDERCOLOR
			stx VIC_BG_COLOR0
			dex
			stx VIC_SPR_MCOLOR
			lda #39
			ldx #50
			sta VIC_SPR7_X
			stx VIC_SPR7_Y
			clc
			adc #24
			sta VIC_SPR6_X
			stx VIC_SPR6_Y
			lda #$3f
			sta $07ff
			sta $07fe
			rts

;---------------------------------------------------------------------------------
;void cursor_on(void);
;void cursor_off(void);
;---------------------------------------------------------------------------------

_cursor_on:		lda _players
			beq oneplayer_on
			lda #$c0
			.byte $2c
oneplayer_on:		lda #$80
			.byte $2c
_cursor_off:		lda #0
			sta VIC_SPR_ENA
			rts		;17

;------------------------------------------------
;void __fastcall__ clone(char i, char j,char s);
;------------------------------------------------

_clone:			sta sprite
			jsr popa
			sta tmp		;x-pos (j)
			jsr popa	;i
			pha
			asl
			asl
			asl
			clc
			adc tmp
			tay
			lda _matrix,y	; x = matrix[i][j];
			tax
			ldy sprite

			clc
			adc #$37
			sta $07f8,y
			lda _colortab,x
			sta VIC_SPR0_COLOR,y

			tya
			asl
			tay

			lda tmp
			jsr mult24	;j*24
			clc
			adc #40		;+8*XOFFS + 24
			sta VIC,y

			pla
			jsr mult24
			adc #50
			sta VIC_SPR0_Y,y
			lda sprite
			clc
			adc #1
			ora VIC_SPR_ENA
			sta VIC_SPR_ENA
			rts

mult24:			sta add+1
			asl
			clc
add:			adc #0
			asl
			asl
			asl
			rts



;---------------------------------------------------------------------------------
;void __fastcall__ print3x3(char symbol,char x,char y);
;---------------------------------------------------------------------------------

			;_print3x3: c-interface

_print3x3:		sta p3x3_y
			jsr popa
			sta p3x3_x
			jsr popa

			;p3x3: assembler-interface

p3x3:			ldx #0
			cmp #$ff	;code $ff --> blank!, then color = 10
			beq endif
			pha		;remember code
			and #7		;to get color just respect lower 3 bits
			tay
			pla		;restore code
			ldx _colortab,y	;get color code in .X
			sta p3x3_add+1	;store code for mult by 9
			asl
			asl
			asl		; *8
			clc
p3x3_add:		adc #0		;+1 --> multiplied by 9
endif:			stx p3x3_color	;store color

			tax		;remember start code

			ldy p3x3_y
			lda ytab_lo,y
			sta $fe
			lda ytab_hi,y	;y*24*3
			sta $ff
			lda p3x3_x
			asl
			clc
			adc p3x3_x
			adc #2		;+ x offset
			sta p3x3_x

			txa		;restore start code

			ldx #3
			stx tmp		;count rows
			ldy p3x3_x	;column to start
p3x3_lp1:		ldx #3		;count columns
p3x3_lp:		sta ($fe),y
			pha

			lda $ff
			pha
			and #3
			ora #$d8
			sta $ff
			lda p3x3_color
			ora #8
			sta ($fe),y
			pla
			sta $ff

			pla
			cmp #$ff
			beq p3x3_skip
			clc
			adc #1
p3x3_skip:		iny
			dex
			bne p3x3_lp
			pha
			tya
			clc
			adc #37
			tay
			pla
			dec tmp
			bne p3x3_lp1
			rts

;---------------------------------------------------------------------------------
;void broesel(void);
;---------------------------------------------------------------------------------

_broesel:		jsr _kill_joker
			lda #0
			sta VIC_SPR_ENA
			lda #64
			sta br_i

br_loop:		jsr _random
			and #7
			sta p3x3_x
			jsr _random
			and #7
			sta p3x3_y
			asl
			asl
			asl
			clc
			adc p3x3_x
			tax
			lda _matrix,x
			cmp #$ff
			beq br_loop

			lda #$ff
			sta _matrix,x
			jsr p3x3
			jsr _wait
			dec br_i
			bne br_loop
			rts
;---------------------------------------------------------------------------------
;void appear(void);
;---------------------------------------------------------------------------------

_appear:		lda #64
			sta br_i

app_loop:		jsr _random
			and #7
			sta p3x3_x
			asl
			clc
			adc p3x3_x
			adc #2
			tay
			jsr _random
			and #7
			sta p3x3_y
			tax
			lda ytab_lo,x
			sta $fe
			lda ytab_hi,x
			sta $ff

			lda ($fe),y
			cmp #$ff
			bne app_loop

			lda p3x3_y
			asl
			asl
			asl
			clc
			adc p3x3_x
			tax
			lda _matrix,x
			jsr p3x3
			jsr _wait

			dec br_i
			bne app_loop
			rts
;---------------------------------------------------------------------------------
;void fill(void);
;---------------------------------------------------------------------------------

_fill:			lda #$ff
			ldx #0
:			sta $0400,x
			sta $0500,x
			sta $0600,x
			sta $06e8,x
			inx
			bne :-
			rts
;---------------------------------------------------------------------------------
;vpod gfx_mode(void);
;---------------------------------------------------------------------------------

_gfx_mode:		jsr _fill
			lda #$18
			sta VIC_CTRL2
			lda #$30
			jmp _setgfx
;---------------------------------------------------------------------------------
;void txt_mode(void);
;---------------------------------------------------------------------------------

_txt_mode:		jsr _kill_joker
			lda #0
			sta VIC_SPR_ENA
			lda #8
			sta VIC_CTRL2
			lda #$1b
			sta VIC_CTRL1
			jsr _fill
			lda #$38
			jmp _setgfx
;---------------------------------------------------------------------------------
;void kill_joker(void);
;---------------------------------------------------------------------------------

_kill_joker:		lda _joker
			beq @end
			lda #0
			sta _joker
			lda _joker_y
			asl
			asl
			asl
			clc
			adc _joker_x
			sta kj_tmp

:			jsr _get_random_symb
			ldx kj_tmp
			sta _matrix,x
			jsr __check_matrix
			bne :-
			ldx kj_tmp
			lda _matrix,x
			ldx _joker_x
			ldy _joker_y
			stx p3x3_x
			sty p3x3_y
			jsr p3x3
@end:			rts

;---------------------------------------------------------------------------------
;unsigned char get_random_symb(void);
;---------------------------------------------------------------------------------

_get_random_symb:	jsr _random
			cmp _animals
			bcs _get_random_symb
			rts

;---------------------------------------------------------------------------------
;void fill_matrix(void);
;---------------------------------------------------------------------------------

_fill_matrix:		jsr _inter_irq

			ldx #0
@lp1:			lda text,x
			jsr _pet2scr
			ora #$80
			sta $0729-40,x
			lda #12
			sta $db29-40,x
			inx
			cpx #22
			bne @lp1

			lda #1
			sta VIC_SPR_ENA
			sta VIC_SPR_EXP_Y
			sta VIC_SPR_EXP_X
			ldx #160
			stx VIC_SPR0_X
			ldx #144
			stx VIC_SPR0_Y

@loop:			inc hugo
			lda hugo
			and #7
			tay
			ldx _colortab,y
			clc
			adc #$37
			sta $07f8
			stx VIC_SPR0_COLOR

			ldx #63
:			jsr _get_random_symb
			sta _matrix,x
			dex
			bpl :-
			jsr __check_matrix
			bne @loop
			jsr _check_moves
			beq @loop

			ldy _level
			dey
			tya
			and #7
			tay
			ldx _colortab,y
			clc
			adc #$37
			sta $07f8
			stx VIC_SPR0_COLOR

			ldx #$27
			lda #$ff
@lp2:			sta $0720-40,x
			dex
			bpl @lp2

			jsr _wait_for_key_or_joy
			lda #0
			sta VIC_SPR_ENA
			sta VIC_SPR_EXP_Y
			sta VIC_SPR_EXP_X
			jsr _fill
			jsr _game_irq
			jmp _gfx_mode


irq_x:		asl VIC_IRR

			lda #$1b
			sta VIC_VIDEO_ADR

			lda #255
			cmp VIC_HLINE
			bne *-3

			lda #$1f
			sta VIC_VIDEO_ADR

			jsr $1003
			jmp out3

;------------------------------------------------------------
;void __fastcall__ plot_score(unsigned int sc,char x,char y);
;------------------------------------------------------------

_plot_score:		tay
			lda tab_lo,y
			sta $fe
			lda tab_hi,y
			sta $ff

			jsr popa
			sta @tmp
			clc
			adc $fe
			sta $fe
			bcc *+4
			inc $ff

			jsr popax
			sta @value
			stx @value+1

			ldy #3
@lp1:			jsr @div10
			pha
			dey
			bne @lp1

@lp2:			pla
			clc
			adc #$ec
			sta ($fe),y

			lda $ff
			pha
			and #$03
			ora #$d8
			sta $ff
			lda _players
			beq @skip
			lda @tmp
			cmp #30
			bcs @skip
			ldx _pl
			lda ps_coltab2,x
			bne @do
@skip:			lda ps_coltab1,y
@do:			sta ($fe),y
			pla
			sta $ff

			iny
			cpy #3
			bne @lp2
			rts

@tmp:			.byte 0
@value:			.word 0

@div10:			ldx #$ff
@loop:			inx
			lda @value
			sec
			sbc #10
			sta @value
			lda @value+1
			sbc #0
			sta @value+1
			bcs @loop
			lda #0
			sta @value+1
			lda @value
			adc #10
			stx @value
			rts

ps_coltab1:		.byte 6,3,1
ps_coltab2:		.byte 1,2
;---------------------------------------------------------------------------------
;void load_hs(void);
;---------------------------------------------------------------------------------

_load_hs:		jmp (_load_vector)
			lda #1
			ldx #8
			ldy #0
			jsr $ffba
			lda #6
			ldx #<(fn+2)
			ldy #>(fn+2)
			jsr $ffbd
			lda #0
			ldx #<_highscore
			ldy #>_highscore
			jmp $ffd5
;---------------------------------------------------------------------------------
;void save_hs(void);
;---------------------------------------------------------------------------------

_save_hs:		jmp (_save_vector)
			lda #<_highscore
			ldx #>_highscore
			sta $fe
			stx $ff

			lda #1
			tay
			ldx #8
			jsr $ffba
			lda #8
			ldx #<fn
			ldy #>fn
			jsr $ffbd
			lda #$fe
			ldx #<(_highscore + 160)
			ldy #>(_highscore + 160)
			jmp $ffd8
;---------------------------------------------------------------------------------
;unsigned char yesno(void)
;---------------------------------------------------------------------------------

_yesno:		jsr $ffe4
			cmp #'l'
			beq ys_yes
			cmp #'r'
			bne _yesno
			lda #0
			rts
ys_yes:			lda #1
			rts
;--------------------------------------------------------------------
;void move_matrix(void)
;--------------------------------------------------------------------

_move_matrix:
			.proc move_matrix
			lda _joker
			sta jb		;jb = joker;

			lda #7
			sta rows	;i = 7;

@do:			lda #0		;for (j=0;j<8;++j)
			sta columns

@for_j_loop:		lda rows	;{
			ldx columns
			jsr get_matrix	;if (matrix[i][j] == BLACK)
			cmp #$ff
			jne @endif1
			lda #0		;yes
			sta depth
@while:			inc depth	;depth = 1
			lda rows
			sec
			sbc depth		;.A: i-depth
			bcc @endwhile	;(i-depth) < 0 --> exit while loop
			ldx columns
			jsr get_matrix	;matrix[i-depth][j]
			cmp #$ff	;==BLACK??
			beq @while	;yes, then increase depth and continue while loop

@endwhile:		lda #0		;s = 0;
			sta spr
			lda #$c0	;vic->spr_ena = 0xc0;
			sta VIC_SPR_ENA

			lda rows	;for (k=i;k!=255;--k)
			sta temp_k
@for_loop2:		lda temp_k	;if (k - depth) >= 0
			sec
			sbc depth
			bcc @else	;k-depth is less than 0, so do 'else'-case
			ldx columns
			jsr get_matrix	;get matrix[k-depth][j]
			pha		;remebmer
			lda temp_k
			ldx columns
			jsr get_matrix	;.Y to matrix[k][j]
			pla		;get symbol to copy to back
			sta _matrix,y	;this is: matrix[k][j] = matrix[k-depth][j]
			jmp @endif2

@else:			jsr _get_random_symb
			pha
			lda temp_k
			ldx columns
			jsr get_matrix
			pla
			sta _matrix,y	;matrix[k][j] = get_random_symb();

@endif2:		ldx columns
			ldy temp_k
			lda #$ff
			stx p3x3_x
			sty p3x3_y
			jsr p3x3	;print3x3(BLACK,j,k)

			lda spr		;if (s < 6){
			cmp #6
			bcs @endif3

			lda temp_k
			ldx columns
			jsr get_matrix
			cmp #$b0	;if (matrix[k][j] == JOKER_SYMB
			bne @else2
			ldy spr
			lda #$37
			sta $07f8,y	;spr_ptr[s] = 0x37;
			lda #1
			sta VIC_SPR0_COLOR,y	;*(char*)(0xd027 + s) = 1;
			lda #0
			sta _joker	;joker = 0;
			lda _joker_y
			clc
			adc depth
			sta _joker_y	;joker_y += depth;
			jmp @endif4
@else2:			lda temp_k
			ldx columns
			jsr get_matrix
			tax
			clc
			adc #$37
			ldy spr
			sta $07f8,y	;spr_ptr[s] = 0x37 + matrix[k][j];
			lda _colortab,x
			sta VIC_SPR0_COLOR,y	;*(char*)(0xd027+s) = colortab[matrix[k][j]];

@endif4:		lda spr
			asl
			tay
			lda columns
			jsr mult24	;j*24
			clc
			adc #40
			sta VIC,y	;*(char*)(0xd000 + 2*s) = 24+XOFFS*8+j*24;
			lda temp_k
			sec
			sbc depth
			php
			jsr mult24
			clc
			adc #50
			sta VIC_SPR0_Y,y	;*(char*)(0xd001 + 2*s) = 50 + (k - depth)*24;
			plp		;if (k-depth >= 0)
			bcc @endif3
			ldx spr
			lda #1
@loop:			dex
			bmi @ex
			asl
			jmp @loop
@ex:			ora VIC_SPR_ENA
			sta VIC_SPR_ENA	;vic->spr_ena = tab[s];

@endif3:		inc spr		;++s;
			dec temp_k
			jpl  @for_loop2

			;multiplexer

			lda #0
			sta temp_l
			lda #1
			sta spr		;now used to count 6es for mover

			lda depth
			asl
			clc
			adc depth
			asl		;depth*6
			sta @comp+1


@for_loop3:				;if (l%6 == 0)
			dec spr
			bne @endif5
			lda #6
			sta spr
			lda VIC_SPR_ENA
			asl
			ora #$c1
			sta VIC_SPR_ENA

@endif5:		lda VIC_SPR5_Y
			clc
			adc #4
			sta VIC_SPR5_Y
			lda VIC_SPR4_Y
			clc
			adc #4
			sta VIC_SPR4_Y
			lda VIC_SPR3_Y
			clc
			adc #4
			sta VIC_SPR3_Y
			lda VIC_SPR2_Y
			clc
			adc #4
			sta VIC_SPR2_Y
			lda VIC_SPR1_Y
			clc
			adc #4
			sta VIC_SPR1_Y
			lda VIC_SPR0_Y
			clc
			adc #4
			sta VIC_SPR0_Y

			lda VIC_SPR0_Y
			sta bck
			cmp #(50+5*24)	;if((bck1 = *(char*)0xd0019 >= 50+5*24)
			jcc  @else3
			ldx $07f8
			ldy VIC_SPR0_COLOR
			stx bck+1
			sty bck+2

			lda VIC_SPR1_Y
			ldx $07f9
			ldy VIC_SPR1_COLOR
			sta bck+3
			stx bck+4
			sty bck+5

			lda #255
			jsr _wait	;wait(255)

			ldx columns	;row0 --> spr0
			lda _matrix,x
			tax
			clc
			adc #$37
			sta $07f8	;spr_ptr[0] = matrix[0][j] + 0x37
			lda _colortab,x	;*(char*)0xd027 = colortab[matrix[0][j]];
			sta VIC_SPR0_COLOR

			lda rows
			cmp #7
			bne @plex7

			lda #8		;row1 --> spr1
			clc
			adc columns
			tax
			lda _matrix,x
			tax
			clc
			adc #$37
			sta $07f9
			lda _colortab,x
			sta VIC_SPR1_COLOR

			lda VIC_SPR0_Y
			sec
			sbc #(7*24)
			sta VIC_SPR0_Y
			lda VIC_SPR1_Y
			sec
			sbc #(5*24)
			sta VIC_SPR1_Y
			jmp @end_plex

@plex7:			lda VIC_SPR0_Y
			sec
			sbc #(6*24)
			sta VIC_SPR0_Y

@end_plex:		lda #120
			jsr _wait

			lda bck
			ldx bck+1
			ldy bck+2
			sta VIC_SPR0_Y
			stx $07f8
			sty VIC_SPR0_COLOR
			lda bck+3
			ldx bck+4
			ldy bck+5
			sta VIC_SPR1_Y
			stx $07f9
			sty VIC_SPR1_COLOR
			jmp @end_for
@else3:			lda #255
			jsr _wait

@end_for:		inc temp_l
			lda temp_l
@comp:			cmp #6
			jne @for_loop3

			lda #0
			sta temp_k

@for_loop4:		lda temp_k
			ldx columns
			sta p3x3_y
			stx p3x3_x
			jsr get_matrix
			cmp #$b0
			beq @end_for1
			jsr p3x3
@end_for1:		inc temp_k
			lda temp_k
			cmp rows
			beq @for_loop4
			bcc @for_loop4


@endif1:		inc columns	;end of (if (matrix[i][j] == BLACK), for_j_loop++
			lda columns
			cmp #8
			jne @for_j_loop

			dec rows
			bmi @end
			jmp @do
@end:			lda jb
			sta _joker
			jmp _cursor_on



.endproc

get_matrix:		stx @add+1
			asl
			asl
			asl
			clc
@add:			adc #0
			tay
			lda _matrix,y
			rts

_getkey:		jsr $ffcc
			jmp $ffe4

;---------------------------------------------------------------------------------
;unsigned char __fastcall__ check_moves(void);
;---------------------------------------------------------------------------------

_check_moves:

;we advance throug the matrix in x then y dir each time swapping with each the right neighbour and the lower
;neighbour, then calling __check_matrix to see if there are three or more...

			lda #1
			sta _stop		;stop timer

			lda #7
			sta cmi
for_i_loop:		lda #0
			sta cmj

for_j_loop:		ldx cmj
			cpx #7
			beq endif1		;we need only 0-6 since 6 will swap with 7
			lda cmi
			jsr swap_h		;swap (x) with (x+1)
			jsr __check_matrix	;check if this causes a three or more...
			pha			;remember result of check
			lda cmi
			ldx cmj
			jsr swap_h		;swap them back again to restore original matrix
			pla			;get result of check
			beq endif1		;=0, then check was negativ, go ahead

			ldx cmj			;we found a possible move, so
			stx _pm_x1		;store the x/y pos of both swappers in pm_x1/pm_y1 and pm_x2/pm_y2
			inx
			stx _pm_x2
			lda cmi
			sta _pm_y1
			sta _pm_y2
cm_exit:		lda #0			;free timer freeze
			sta _stop
			lda #1			;success
			rts			;return
endif1:
			lda cmi			;now swap vertically
			cmp #7			;again only 0-6 need to be swapped since 6 will swap with 7
			beq endif2
			ldx cmj
			jsr swap_v		;swap'em
			jsr __check_matrix	;check _matrix
			pha			;remember check result
			lda cmi
			ldx cmj
			jsr swap_v		;swap'em back
			pla			;re-get check result
			beq endif2		;0 = no success

			ldx cmi			;found, then store the result...
			stx _pm_y1
			inx
			stx _pm_y2
			lda cmj
			sta _pm_x1
			sta _pm_x2
			jmp cm_exit

endif2:			inc cmj			;advance in x-direction
			lda cmj
			cmp #8
			jne for_j_loop
			dec cmi
			jpl for_i_loop
			lda #0
			sta _stop
			rts


swap_h:			jsr get_matrix		;.A: matrix[i][j]
			iny
			ldx _matrix,y		;.X: matrix[i][j+1]
			sta _matrix,y		;matrix[i][j+1] = matrix[i][j]
			dey
			txa
			sta _matrix,y		;matrix[i][j] = matrix[i][j+1]
			rts

swap_v:			jsr get_matrix
			pha
			tya
			clc
			adc #8
			tay
			pla
			ldx _matrix,y
			sta _matrix,y
			tya
			sec
			sbc #8
			tay
			txa
			sta _matrix,y
			rts

;--------------------------------------------------------------------------
;void __fastcall__ put2cue(char);
;--------------------------------------------------------------------------

_put2cue:		ldx _cue_max
			cpx #16
			beq @exit
			sta _cue,x
			inc _cue_max
@exit:			rts
;--------------------------------------------------------------------------
;unsigned char getfromcue(void);
;--------------------------------------------------------------------------

_getfromcue:		lda _cue_max
			beq @exit
			ldy _cue
			dec _cue_max
			ldx #0
@lp:			cpx _cue_max
			beq @done
			lda _cue+1,x
			sta _cue,x
			inx
			bne @lp
@done:			tya
@exit:			rts

;---------------------------------------------------------------------------------
;void __fastcall__ do_bar(char);
;---------------------------------------------------------------------------------

_do_bar:		clc
			adc #(55+18*8)
			pha
			inc @delay
			lda @delay
			and #3
			bne @skip
			inc @tmp
@skip:			lda @tmp
			and #7
			tay
			ldx @tab,y
			pla
			cmp VIC_HLINE
			bne *-3
			stx VIC_BG_COLOR0
			clc
			adc #1
			ldx #8
			cmp VIC_HLINE
			bne *-3
			stx VIC_BG_COLOR0
			rts
@delay:			.byte 0
@tmp:			.byte 0
@tab:			.byte 0,11,12,15,1,15,12,11



_delay:			tax
			lda #100
@loop:			jsr _wait
			dex
			bne @loop
			rts

;---------------------------------------------------------------------------------
;void screen_off(void); void screen_on(void)
;---------------------------------------------------------------------------------

_screen_off:		lda #$0b
			.byte $2c
_screen_on:		lda #$1b
			sta VIC_CTRL1
			rts
;---------------------------------------------------------------------------------
;variables, tables, data...
;---------------------------------------------------------------------------------

bck:			.res 6
_cue:			.res 16
_fld_done:		.byte 0
fld_tmp:		.byte 0
_cue_max:		.byte 0
_demo:			.byte 0
_pl:			.byte 0
_pm_x1:			.byte 0
_pm_x2:			.byte 0
_pm_y1:			.byte 0
_pm_y2:			.byte 0
_key:			.byte 0
_xpos1:			.byte 0
_ypos1:			.byte 0
_xdir1:			.byte 0
_ydir1:			.byte 0
_xpos2:			.byte 0
_ypos2:			.byte 0
_xdir2:			.byte 0
_ydir2:			.byte 0
_timer_delay:		.byte 0
_stop:			.byte 0
_time_out:		.byte 0
_joker_tmp:		.byte 0
_joker:			.byte 0
_animals:		.byte 0
_level: 		.byte 0
_players:		.byte 0
_joker_x:		.byte 0
_joker_y:		.byte 0
_time1:			.word 0
_team:			.byte 0
_tt:			.byte 0

rotate_delay:		.byte 0
joker_delay:		.byte 0
scroll_delay:		.byte 0
bar_delay:		.byte 0
d1:			.byte 0
tmp:			.byte 0
count:			.byte 0
aux:			.byte 0
rem:			.byte 0
scroll:			.byte 0
del:			.byte 0
line:			.byte 0
color1:			.byte 0
color2:			.byte 0,0
cmxi:			.byte 0
cmxj:			.byte 0
key_delay:		.byte 0
sprite:			.byte 0
p3x3_color:		.byte 0
p3x3_x:			.byte 0
p3x3_y:			.byte 0
br_i:			.byte 0
kj_tmp:			.byte 0
rows:			.byte 0
columns:		.byte 0
temp_k:			.byte 0
temp_l:			.byte 0
depth:			.byte 0
spr:			.byte 0
jb:			.byte 0
cmi:			.byte 0
cmj:			.byte 0


_load_vector:		.word _load_hs+3
_save_vector:		.word _save_hs+3

ytab_lo:		.byte 0,120,240,<(9*40),<(12*40),<(15*40),<(18*40),<(21*40)
ytab_hi:		.byte 4,4,4,5,5,6,6,7

tab_lo:			.byte 0,40,80,120,160,200,240,<280,<320,<360,<400,<440,<480,<520,<560,<600,<640,<680,<720
			.byte <760,<800,<840,<880,<920,<960
tab_hi:			.byte 4,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,7,7

barcolor_tab:		.byte 2,10, 10,10,10,2,2, 9
			.byte 8, 8, 7, 7, 7, 7, 8, 8
			.byte 5, 5,13,13,13,13, 5, 5
			.byte 6, 6,14,14,14,14, 4,4

hugo:			.byte 0
text:			.byte "one moment, please...!",0
fn:			.byte "@:zoo.hi"

;modul_version	= 0;
.if .defined (modul_version)
scroll_text:
.byte 1,"no scroll text in cartridge version                    ",0

.else

scroll_text:
.byte 2,"Welcome to ",1,"ZOO MANIA.            ",3
.byte "After a long time here is one more release of this game. ",1,"I have to say explicitly that this is "
.byte "NOT THE FINAL VERSION "
.byte " since there is still a bug left, which i couldn't fix yet. ",12," Unfortunately it is a rather serious one:"
.byte 11,"It ",1,"MIGHT ",11,"happen that "
.byte "the game won't recognize a 'no more moves situation' so that you get stucked, since there ARE no more moves - "
.byte 1,"So be aware of this when playing!    ",7,"But now have fun with this one and here come the credits...          "
.byte 1,"code ",11,"hannenz ",1,"ingame gfx ",11,"crossbow ",1,"msx ",11,"fanta ",1,"title pic ",11,"scorp.ius ",1,"idea ",11,"bugjam ";,7,"published and released by ",1,"CRONOSOFT ",7,"2006.      ",1
.byte "       instructions ",11,"use ",1,"joy #2 ",11,"in single player mode or ",1,"joy #1 and #2 ",11,"in two player modes. try to ",1,"swap ",11,"the animals so that ",1,"rows or columns of three or more equal animals ",11,"occur."
.byte " there is a certain amount of animals to catch to proceed to the next level. ",1,"time ",11,"is your enemy.  "
.byte 1,"keys ",11,"hit ",1,"RUN/STOP ",11,"to pause the game ",1,"RESTORE ",11,"will get you back to the game menu. ",1,"have fun!     ",14,"hannenz@freenet.de                                        "
.byte 0

.endif
