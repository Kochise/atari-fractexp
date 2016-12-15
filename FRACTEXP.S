; ////////////////////////////////////
; /// Fractal Explorer - KOSS 1998 ///
; ////////////////////////////////////

	SECTION	TEXT		; Le programme

; /// On initialise ///

	movea.l	4(SP),A6		; Adresse de la BasePage
	move.l	$C(A6),D0		; Taille du SEGMENT TEXT
	add.l	$14(A6),D0		; Additionne la taille du SEGMENT DATA … D0
	add.l	$1C(A6),D0		; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0		; Additionne la taille de la BasePage … D0
	addi.l	#$400,D0		; Additionne la taille de la future PILE (Ici, 256 mots longs (1 Ko))
	move.l	D0,D1		; Copie D0 dans D1 (Taille … r‚server)
	add.l	A6,D1		; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1		; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	movea.l	D1,SP		; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	A6,4(SP)		; Adresse de la BasePage
	move.l	D0,-(SP)		; EmPILE la taille … reserver	\
	move.l	A6,-(SP)		; EmPILE l'adresse du programme |-> Rend le reste de la m‚moire au systŠme
	clr.w	-(SP)		; R‚serv‚                       |
	move.w	#$4A,-(SP)		; - M_SHRINK -                  |
	trap	#1		; *** GEMDOS ***                /
	lea	12(SP),SP

; /// On v‚rifie le TYPE du MONiteur ///

	move.w	#$59,-(SP)		; - MONTYPE -
	trap	#14		; *** XBIOS ***
	addq.l	#2,SP
	
	cmpi.w	#1,D0		; RGB
	BEQ	Next_Step


; /// C'est pas le bon TYPE de MONiteur ///
	
	pea	RGB_Text
	move.w	#9,-(SP)		; - C_CONWS -
	trap	#1		; *** GEMDOS ***
	addq.l	#6,SP
	
	BRA	Wait_Keys		; C'est juste avant la fin
	
; /// On cherche quelle r‚solution ///
	
Next_Step	move.w	#-1,-(SP)
	move.w	#$58,-(SP)		; - VSETMODE -
	trap	#14		; *** XBIOS ***
	addq.l	#4,SP
	
	move.w	D0,Old_Mode

; /// On sauvegarde de la m‚moire pour les ‚crans ///

	clr.w	-(SP)
	move.l	#$5A000,-(SP)
	move.w	#$44,-(SP)		; - M_XALLOC -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	
	tst.l	D0
	BEQ	Exit
	
	move.l	D0,Screen1
	add.l	#$2D000,D0
	move.l	D0,Screen2
	
; /// On initialise le bintz vid‚o ///	
	
	move.w	#%1000100,-(SP)
	move.w	#3,-(SP)
	move.l	Screen1,-(SP)
	move.l	Screen1,-(SP)
	move.w	#5,-(SP)		; - SETSCREEN -
	trap	#14		; *** XBIOS ***
	lea	(14,SP),SP
	
; /// On efface le premier "… la main" ///
	
	move.w	#$B3FF,D0
	move.l	Screen1,A0
Clear_Screen	clr.l	(A0)+
	DBF	D0,Clear_Screen
	
; /// On recopie le premier ‚cran fraichement effac‚ sur le second, via le Blitter ///
		
	clr.l	-(SP)
	move.w	#$20,-(SP)		; - SUPER -
	trap	#1		; *** GEMDOS ***
	addq.l	#6,SP
	
	move.l	D0,D6
	
	clr.l	$FFFF9800.w		; Fond noir

	clr.l	$FFFF8A00.w
	clr.l	$FFFF8A04.w
	clr.l	$FFFF8A08.w
	clr.l	$FFFF8A0C.w
	clr.l	$FFFF8A10.w
	clr.l	$FFFF8A14.w
	clr.l	$FFFF8A18.w
	clr.l	$FFFF8A1C.w
	move.w	#2,$FFFF8A20.w
	move.w	#0,$FFFF8A22.w
	move.l	Screen1,$FFFF8A24.w
	move.w	#-1,$FFFF8A28.w
	move.w	#-1,$FFFF8A2A.w
	move.w	#-1,$FFFF8A2C.w
	move.w	#2,$FFFF8A2E.w
	move.w	#0,$FFFF8A30.w
	move.l	Screen2,$FFFF8A32.w
	move.w	#383,$FFFF8A36.w
	move.w	#239,$FFFF8A38.w
	move.w	#$200,$FFFF8A3A.w
	move.w	#%1100000000000000,$FFFF8A3C.w
	
Blitter_Wait	btst.b	#7,$FFFF8A3C.w
	BNE	Blitter_Wait
	
	move.l	D6,-(SP)
	move.w	#$20,-(SP)		; - SUPER -
	trap	#1		; *** GEMDOS ***
	addq.l	#6,SP

; /// On calcul la fenetre de visualisation sur le plan complexe ///
	
XWin_Opt	fmove.x	XCENTER,FP0		; XCENTER
	fmove.x	FP0,FP1
	fmove.w	XPIX,FP2		; XPIX
	fmove.x	FP2,FP5
	fmove.x	ZOOMFACT,FP3		; ZOOMFACT
	fmove.b	#2,FP4
	fmul.x	FP4,FP3
	fdiv.x	FP3,FP2		; XPIX/(2*ZOOMFACT)
	fsub.x	FP2,FP0		; XCENTER-XZOOMRANGE
	fadd.x	FP2,FP1		; XCENTER+XZOOMRANGE
	fmove.x	FP0,XWINMIN		; XWINMIN
	fmove.x	FP1,XWINMAX		; XWINMAX
XPitch_Opt	fsub.x	FP0,FP1		; XWINMAX-XWINMIN
	fdiv.x	FP5,FP1		; XRANGE/XPIX
	fmove.x	FP1,XPITCH		; XPITCH
YWin_Opt	fmove.x	YCENTER,FP0		; YCENTER
	fmove.x	FP0,FP1
	fmove.w	YPIX,FP2		; YPIX
	fmove.x	FP2,FP5
	fdiv.x	FP3,FP2		; YPIX/(2*ZOOMFACT)
	fsub.x	FP2,FP0		; YCENTER-YZOOMRANGE
	fadd.x	FP2,FP1		; YCENTER+YZOOMRANGE
	fmove.x	FP0,YWINMIN		; YWINMIN
	fmove.x	FP1,YWINMAX		; YWINMAX
YPitch_Opt	fsub.x	FP0,FP1		; YWINMAX-YWINMIN
	fdiv.x	FP5,FP1		; YRANGE/YPIX
	fmove.x	FP1,YPITCH		; YPITCH

; /// On initialise le calcul de Julia-Mandel ///
	
	move.l	Screen1,A0
	move.l	#63,D5		; MAXITER
	
	move.w	XPIX,D2
	move.w	YPIX,D3
	clr.w	D6		; 1er pixel
	move.w	#239,D7		; 240 lignes … calculer
	
	BSR	Mandel_Calc
	
; /// On attend une touche pour quitter ///
	
	move.w	#7,-(SP)		; - C_RAWCIN -
	trap	#1		; *** GEMDOS ***
	addq.l	#2,SP

; /// On libŠre les deux ‚crans ///
	
	move.l	Screen1,-(SP)
	move.w	#$49,-(SP)		; - M_FREE -
	trap	#1		; *** GEMDOS ***
	addq.l	#6,SP

; /// On remet l'‚cran normalement ///

	move.w	Old_Mode,-(SP)
	move.w	#3,-(SP)
	clr.l	-(SP)
	clr.l	-(SP)
	move.w	#5,-(SP)		; - SETSCREEN -
	trap	#14		; *** XBIOS ***
	lea	(14,SP),SP

	BRA	Exit

; /// On attend une touche aprŠs que l'on sache que ce ne c'est pas le bon TYPE ///
	
Wait_Keys	move.w	#7,-(SP)		; - C_RAWCIN -
	trap	#1		; *** GEMDOS ***
	addq.l	#2,SP
	
; /// Ciao... ///
		
Exit	clr.w	-(SP)		; - P_TERM0 -
	trap	#1		; *** GEMDOS ***

; /// Le calcul de Julia ///	

Julia_Calc	clr.l	D4		; ITER
	fmove.x	XWINMIN,FP3
	fmove.x	YWINMIN,FP4
	fmove.w	D6,FP6		; XCALC
	fmove.x	XPITCH,FP5
	fmul.x	FP6,FP5
	fmove.x	FP3,FP0		; XWINMIN
	fadd.x	FP5,FP0		; XITER
	fmove.w	D7,FP6		; YCALC
	fmove.x	YPITCH,FP5
	fmul.x	FP6,FP5
	fmove.x	FP4,FP2		; YWINMIN
	fadd.x	FP5,FP2		; YITER
Julia_Iter	fmove.x	FP0,FP1		; XBUFF
	fmul.x	FP0,FP0
	fmove.x	FP2,FP5
	fmul.x	FP5,FP5
	fsub.x	FP5,FP0
	fmove.x	XSTART,FP5		; XSTART
	fadd.x	FP5,FP0
	fmove.b	#2,FP5
	fmul.x	FP5,FP1
	fmul.x	FP1,FP2
	fmove.x	YSTART,FP5		; YSTART
	fadd.x	FP5,FP2
	fmove.x	FP0,FP5
	fmul.x	FP5,FP5
	fmove.x	FP2,FP6
	fmul.x	FP6,FP6
	fadd.x	FP6,FP5
	fmove.b	#4,FP6
	fcmp.x	FP6,FP5
	FBGT	End_Julia
	cmp.l	D5,D4
	BGT	End_Julia
	addq.l	#1,D4
	BRA	Julia_Iter
End_Julia	move.w	D4,(A0)+

	addq.w	#1,D6		; Pixel suivant
	cmp.w	D6,D2
	BNE	Julia_Calc
	clr.w	D6
	DBF	D7,Julia_Calc		; Ligne suivante

	RTS

; /// Le calcul de Mandelbrot ///	

Mandel_Calc	clr.l	D4		; ITER
	fmove.x	XWINMIN,FP3
	fmove.x	YWINMIN,FP4
	fmove.w	D6,FP6		; XCALC
	fmove.x	XPITCH,FP5
	fmul.x	FP6,FP5
	fadd.x	FP5,FP3		; XITER+XWINMIN
	fmove.w	D7,FP6		; YCALC
	fmove.x	YPITCH,FP5
	fmul.x	FP6,FP5
	fadd.x	FP5,FP4		; YITER+YWINMIN
	fmove.x	XSTART,FP0		; XSTART
	fmove.x	YSTART,FP2		; YSTART
Mandel_Iter	fmove.x	FP0,FP1		; XBUFF
	fmul.x	FP0,FP0
	fmove.x	FP2,FP5
	fmul.x	FP5,FP5
	fsub.x	FP5,FP0
	fadd.x	FP3,FP0
	fmove.b	#2,FP5
	fmul.x	FP5,FP1
	fmul.x	FP1,FP2
	fadd.x	FP4,FP2
	fmove.x	FP0,FP5
	fmul.x	FP5,FP5
	fmove.x	FP2,FP6
	fmul.x	FP6,FP6
	fadd.x	FP6,FP5
	fmove.b	#4,FP6
	fcmp.x	FP6,FP5
	FBGE	End_Mandel
	cmp.l	D5,D4
	BGT	End_Mandel
	addq.l	#1,D4
	BRA	Mandel_Iter
End_Mandel	move.w	D4,(A0)+

	addq.w	#1,D6		; Pixel suivant
	cmp.w	D6,D2
	BNE	Mandel_Calc
	clr.w	D6
	DBF	D7,Mandel_Calc		; Ligne suivante
	
	RTS

	SECTION	DATA		; Les donn‚es
	
RGB_Text	dc.b	27,"E RGB Screen Only...",0
Null_Code	dc.w	0
Screen1	ds.l	1
Screen2	ds.l	1
Old_Mode	ds.w	1
ZOOMFACT	dc.x	80		; 10000,  1000000, 10000000
XPIX	dc.w	384
YPIX	dc.w	240
XCENTER	dc.x	0		;  0.23 ,  0.2305,  0.23054
YCENTER	dc.x	0		; -0.198, -0.1987, -0.1987
XSTART	dc.x	0
YSTART	dc.x	0
XWINMIN	dc.x	0
YWINMIN	dc.x	0
XWINMAX	dc.x	0
YWINMAX	dc.x	0
XPITCH	dc.x	0
YPITCH	dc.x	0

	SECTION	BSS		; Les variables