;            ***********************************************
;            *                                             *
;            *          LASERMAX LASER controller          *
;            *                                             *
;            *                                             *
;            *    Created by Anthony Barrett, 22-Apr-93    *
;            *                                             *
;            *                 Version 1.30                *
;            *                                             *
;            ***********************************************




OpenDisplay:		jsr	SetupScreen
			tst.l	d0
			bne	.Error

			jsr	OpenLaserWindow
			tst.l	d0
			bne	.Error2

			movea.l	LaserWnd,a0
			move.l	a0,ReqFRTags+4
			move.l	50(a0),RastPortPtr

			moveq	#GD_Vol0Dn,d0
			bsr	FindGadPtr

			moveq	#25,d0

.Loop:			move.w	#3,14(a0)		;Enable gad down msg
			movea.l	(a0),a0
			dbf	d0,.Loop

			movea.l	LaserGadgets,a0
			lea	GadgetTable,a1

.Loop2:			move.l	(a1)+,40(a0)
			move.l	(a0),a0
			tst.l	(a1)
			bne.s	.Loop2

			tst.b	BigScreenFlag
			beq.s	.Skip

			addq.l	#4,a1

.Loop3:			move.l	(a1)+,40(a0)
			move.l	(a0),a0
			tst.l	(a1)
			bne.s	.Loop3

.Skip:			bsr	SetDrawMode		;Scope grafix
			bsr	BlankScope

			moveq	#2,d0
			bsr	SetAPen

			moveq	#ScopeX,d0
			moveq	#ScopeY,d1
			bsr	Move

			move.l	#ScopeX+262,d0
			moveq	#ScopeY,d1
			bsr	Draw

			tst.b	BigScreenFlag
			beq	.Skip2

			move.l	#ScopeX+262,d0
			move.l	#ScopeY+131+127,d1
			bsr	Draw

			moveq	#ScopeX,d0
			move.l	#ScopeY+131+127,d1
			bsr	Draw

			moveq	#ScopeX,d0
			moveq	#ScopeY,d1
			bsr	Draw

			move.l	#ScopeX+131,d0		;Marks
			moveq	#ScopeY-3,d1
			bsr	Move

			move.l	#ScopeX+131,d0
			moveq	#ScopeY-1,d1
			bsr	Draw

			move.l	#ScopeX+131,d0
			move.l	#ScopeY+132+127,d1
			bsr	Move

			move.l	#ScopeX+131,d0
			move.l	#ScopeY+134+127,d1
			bsr	Draw

			moveq	#ScopeX-5,d0
			move.l	#ScopeY+66+63,d1
			bsr	Move

			moveq	#ScopeX-1,d0
			move.l	#ScopeY+66+63,d1
			bsr	Draw

			move.l	#ScopeX+263,d0
			move.l	#ScopeY+66+63,d1
			bsr	Move

			move.l	#ScopeX+267,d0
			move.l	#ScopeY+66+63,d1
			bsr	Draw
			bra	.Skip3

.Skip2:			move.l	#ScopeX+262,d0
			move.l	#ScopeY+131,d1
			bsr	Draw

			moveq	#ScopeX,d0
			move.l	#ScopeY+131,d1
			bsr	Draw

			moveq	#ScopeX,d0
			moveq	#ScopeY,d1
			bsr	Draw

			moveq	#ScopeX+1,d0
			moveq	#ScopeY+1,d1
			bsr	Move

			moveq	#ScopeX+1,d0
			move.l	#ScopeY+130,d1
			bsr	Draw

			move.l	#ScopeX+261,d0
			moveq	#ScopeY+1,d1
			bsr	Move

			move.l	#ScopeX+261,d0
			move.l	#ScopeY+130,d1
			bsr	Draw

			move.l	#ScopeX+131,d0		;Marks
			moveq	#ScopeY-3,d1
			bsr	Move

			move.l	#ScopeX+131,d0
			moveq	#ScopeY-1,d1
			bsr	Draw

			move.l	#ScopeX+131,d0
			move.l	#ScopeY+132,d1
			bsr.s	Move

			move.l	#ScopeX+131,d0
			move.l	#ScopeY+134,d1
			bsr.s	Draw

			moveq	#ScopeX-5,d0
			moveq	#ScopeY+65,d1
			bsr.s	Move

			moveq	#ScopeX-1,d0
			moveq	#ScopeY+65,d1
			bsr.s	Draw

			move.l	#ScopeX+263,d0
			moveq	#ScopeY+65,d1
			bsr.s	Move

			move.l	#ScopeX+267,d0
			moveq	#ScopeY+65,d1
			bsr.s	Draw

.Skip3:			moveq	#1,d0
			rts

.Error2:		jsr	CloseDownScreen
.Error:			sub.l	d0,d0
			rts

SetDrawMode:		sub.l	d0,d0
SetDrawMode2:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVOSetDrMd(a6)
.End:			rts

SetAPen:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVOSetAPen(a6)
.End:			rts

Move:			tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVOMove(a6)
.End:			rts

Draw:			tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVODraw(a6)
.End:			rts

Pixel:			tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVOWritePixel(a6)
			move.b	#1,JustBlanked
.End:			rts

Pixel2:			tst.b	DirectFlag
			beq.s	Pixel

			tst.b	IconifyFlag
			bne.s	.End

			tst.b	JustBlanked
			beq.s	Pixel

			movea.l	Scr,a0
			movea.l	192(a0),a1		;Bit plane 0
			movea.l	196(a0),a2		;Bit plane 1

			moveq	#80,d2			;640 pixels wide
			mulu	d1,d2

			andi.l	#$ffff,d0
			divu	#8,d0
			add.w	d0,d2

			swap.w	d0
			moveq	#7,d1
			sub.w	d0,d1

			movea.l	RastPortPtr,a0
			move.b	25(a0),d0
			beq.s	.0

			cmpi.b	#3,d0
			beq.s	.3

			cmpi.b	#1,d0
			beq.s	.1

			bclr	d1,(a1,d2)
			bset	d1,(a2,d2)
			rts

.0			bclr	d1,(a1,d2)
			bclr	d1,(a2,d2)
			rts

.1:			bset	d1,(a1,d2)
			bclr	d1,(a2,d2)
			rts

.3:			bset	d1,(a1,d2)
			bset	d1,(a2,d2)
.End:			rts

ReadPixel:		movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVOReadPixel(a6)
			rts

ReadPixel2:		tst.b	DirectFlag
			beq.s	ReadPixel

			movea.l	Scr,a0
			movea.l	192(a0),a1		;Bit plane 0
			movea.l	196(a0),a2		;Bit plane 1

			moveq	#80,d2			;640 pixels wide
			mulu	d1,d2

			andi.l	#$ffff,d0
			divu	#8,d0
			add.w	d0,d2

			swap.w	d0
			moveq	#7,d1
			sub.w	d0,d1

			btst	d1,(a1,d2)
			beq.s	.Clr

			moveq	#1,d0
			btst	d1,(a2,d2)
			beq.s	.End

			moveq	#3,d0
			rts

.Clr:			sub.l	d0,d0
			btst	d1,(a2,d2)
			beq.s	.End

			moveq	#2,d0
.End:			rts

BlankScope:		tst.b	IconifyFlag
			bne.s	.End

			moveq	#1,d0
			bsr	SetAPen

			movea.l	RastPortPtr,a1
			moveq	#ScopeX+2,d0
			moveq	#ScopeY+1,d1
			move.l	#ScopeX+260,d2
			move.l	#ScopeY+130,d3
			tst.b	BigScreenFlag
			beq.s	.Skip
			addi.l	#127,d3
.Skip:			movea.l	GfxBase,a6
			jsr	_LVORectFill(a6)

.End:			clr.b	CursorFlag
			clr.b	LineFlag
			clr.b	ArcFlag
			clr.b	BoxFlag
			clr.b	EllipseFlag
			clr.b	TemplateFlag
			clr.b	RollFlag2
			clr.b	GridFlag2
			clr.b	JustBlanked
			clr.l	DBLastX
			rts

SetDrawMode3:		sub.l	d0,d0
SetDrawMode4:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr2,a1
			movea.l	GfxBase,a6
			jsr	_LVOSetDrMd(a6)
.End:			rts

SetAPen2:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr2,a1
			movea.l	GfxBase,a6
			jsr	_LVOSetAPen(a6)
.End:			rts

Move2:			tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr2,a1
			movea.l	GfxBase,a6
			jsr	_LVOMove(a6)
.End:			rts

Draw2:			tst.b	IconifyFlag
			bne.s	.End
			movea.l	RastPortPtr2,a1
			movea.l	GfxBase,a6
			jsr	_LVODraw(a6)
.End:			rts

BlankMagnifyGlass:	tst.b	IconifyFlag
			bne.s	.End

			moveq	#1,d0
			bsr.s	SetAPen2

			movea.l	RastPortPtr2,a1
			moveq	#16,d0
			moveq	#15,d1
			moveq	#81,d2
			moveq	#47,d3
			tst.b	BigScreenFlag
			beq.s	.Skip
			addi.w	#33,d3
.Skip:			movea.l	GfxBase,a6
			jsr	_LVORectFill(a6)
.End:			rts

DrawCrossHairs:		moveq	#2,d0
			bsr	SetAPen2

			tst.b	BigScreenFlag
			beq.s	.Skip

			moveq	#48,d0
			moveq	#41,d1
			bsr.s	Move2

			moveq	#48,d0
			moveq	#53,d1
			bsr.s	Draw2

			moveq	#42,d0
			moveq	#47,d1
			bsr	Move2

			moveq	#54,d0
			moveq	#47,d1
			bsr.s	Draw2
			rts

.Skip:			moveq	#48,d0
			moveq	#28,d1
			bsr	Move2

			moveq	#48,d0
			moveq	#34,d1
			bsr	Draw2

			moveq	#42,d0
			moveq	#31,d1
			bsr	Move2

			moveq	#54,d0
			moveq	#31,d1
			bsr	Draw2
			rts

FindGadPtr:		tst.b	IconifyFlag
			bne.s	.End

			lea	LaserGadgets,a0

.Loop:			movea.l	(a0),a0
			dbf	d0,.Loop
.End:			rts

ActivateGad:		suba.l	a2,a2
			movea.l	IntBase,a6
			jsr	_LVOActivateGadget(a6)
			rts

RefreshGads:		tst.b	IconifyFlag
			bne.s	.End

			movea.l	LaserWnd,a1
			suba.l	a2,a2
			movea.l	IntBase,a6
			jsr	_LVORefreshGadgets(a6)
.End:			rts

RefreshGads2:		suba.l	a2,a2
			movea.l	IntBase,a6
			jsr	_LVORefreshGadgets(a6)
			rts

GadDisable:		tst.b	IconifyFlag
			beq.s	.Skip
			rts

.Skip:			bset	#0,12(a0)
			bra.s	GadChg

GadEnable:		tst.b	IconifyFlag
			beq.s	.Skip
			rts

.Skip:			bclr	#0,12(a0)
			bra.s	GadChg

GadOff:			tst.b	IconifyFlag
			beq.s	.Skip
			rts

.Skip:			bclr	#7,13(a0)
			bra.s	GadChg

GadOn:			tst.b	IconifyFlag
			beq.s	.Skip
			rts

.Skip:			bset	#7,13(a0)

GadChg:			tst.b	IconifyFlag
			bne.s	.End
			move.l	(a0),-(sp)
			clr.l	(a0)
			move.l	a0,-(sp)
			bsr.s	RefreshGads
			movea.l	(sp)+,a0
			move.l	(sp)+,(a0)
.End:			rts

GadChg2:		tst.b	IconifyFlag
			bne.s	.End
			move.l	(a0),-(sp)
			clr.l	(a0)
			move.l	a0,-(sp)
			bsr.s	RefreshGads2
			movea.l	(sp)+,a0
			move.l	(sp)+,(a0)
.End:			rts

GetPrefsItem:		jsr	CheckIconify
			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	(a0),a0			;Preferences
			movea.l	18(a0),a0		;Item 1
			subq.l	#2,d0
			bmi.s	.End

.Loop:			movea.l	(a0),a0
			dbf	d0,.Loop
.End:			rts

GetSysPrefsItem:	jsr	CheckIconify
			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	(a0),a0			;Preferences
			movea.l	(a0),a0			;System prefs
			movea.l	18(a0),a0		;Item 1
			subq.l	#2,d0
			bmi.s	.End

.Loop:			movea.l	(a0),a0
			dbf	d0,.Loop
.End:			rts

ToggleItems:		bchg	#0,ItemsFlag

			tst.b	IconifyFlag
			bne.s	.End

			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	18(a0),a0		;Item 1
			movea.l	(a0),a0			;Item 2
			movea.l	(a0),a0			;Item 3
			movea.l	(a0),a0			;Item 4
			movea.l	(a0),a0			;Item 5
			movea.l	(a0),a0			;Item 6
			movea.l	(a0),a0			;Item 7
			movea.l	(a0),a0			;Item 8
			movea.l	(a0),a0			;Item 9
			movea.l	(a0),a0			;Item 10
			movea.l	(a0),a0			;Item 11
			bchg	#4,13(a0)
			movea.l	(a0),a0			;Item 12
			movea.l	(a0),a0			;Item 13
			movea.l	(a0),a0			;Item 14
			movea.l	(a0),a0			;Item 15
			bchg	#4,13(a0)

			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			bchg	#0,13(a0)
.End:			rts

SerialItemsOff:		tst.b	LASERfIREFlag
			bne.s	.Off

			tst.b	SerialFlag
			beq.s	.End

.Off:			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	18(a0),a0		;Item 1
			movea.l	(a0),a0			;Item 2
			movea.l	(a0),a0			;Item 3
			movea.l	(a0),a0			;Item 4
			bchg	#4,13(a0)
			movea.l	(a0),a0			;Item 5
			movea.l	(a0),a0			;Item 6
			bchg	#4,13(a0)
			movea.l	(a0),a0			;Item 7
			bchg	#4,13(a0)
			movea.l	(a0),a0			;Item 8
			movea.l	(a0),a0			;Item 9
			bchg	#4,13(a0)

			clr.b	StandbyFlag

			moveq	#GD_Standby,d0
			bsr	FindGadPtr
			bsr	GadOff

			moveq	#GD_Standby,d0
			bsr	FindGadPtr
			bsr	GadDisable
.End:			rts

ClearMenu:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	LaserWnd,a0
			movea.l	IntBase,a6
			jsr	_LVOClearMenuStrip(a6)
.End:			rts

OpenMenu:		tst.b	IconifyFlag
			bne.s	.End
			movea.l	LaserWnd,a0
			movea.l	LaserMenus,a1
			movea.l	IntBase,a6
			jsr	_LVOSetMenuStrip(a6)
.End:			rts

FlashScreen:		suba.l	a0,a0
			movea.l	IntBase,a6
			jsr	_LVODisplayBeep(a6)
			rts

GetWndMsg:		movea.l	86(a0),a0
			movea.l	(4).l,a6
			jsr	_LVOGetMsg(a6)
			tst.l	d0
			rts

SetGadget:		andi.l	#$ffff,d0
			movea.l	34(a0),a0
			move.l	d0,28(a0)
			movea.l	(a0),a0
			bsr	HEXtoASCII
			rts

PrintWinText:		tst.b	IconifyFlag
			bne.s	.End
			move.l	16(a1),-(sp)
			move.l	a1,-(sp)
			clr.l	16(a1)
			movea.l	LaserWnd,a0
			movea.l	50(a0),a0
			sub.l	d0,d0
			moveq	#11,d1
			movea.l	IntBase,a6
			jsr	_LVOPrintIText(a6)
			movea.l	(sp)+,a1
			move.l	(sp)+,16(a1)
.End:			rts

PtrDraw2:		tst.b	PtrDrawFlag
			beq.s	.End
			clr.b	PtrDrawFlag
			bra.s	PtrDraw
.End:			rts

PtrDraw:		tst.b	IconifyFlag
			bne.s	.End

			tst.b	PtrDrawFlag
			bne.s	.End

			move.b	#1,PtrDrawFlag

			move.l	d5,-(sp)
			move.l	d6,-(sp)

			movea.l	#DrawPtrImage,a1

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			movea.l	#DrawPtrImage2,a1

.TSkip:			movea.l	LaserWnd,a0
			moveq	#7,d0			;Height
			moveq	#7,d1			;Width
			moveq	#-4,d2			;X offset
			moveq	#-3,d3			;Y offset
			movea.l	IntBase,a6
			jsr	_LVOSetPointer(a6)

			move.l	(sp)+,d6
			move.l	(sp)+,d5
.End:			rts

PtrClear:		tst.b	IconifyFlag
			bne.s	.End

			tst.b	PtrDrawFlag
			beq.s	.End

			clr.b	PtrDrawFlag
			movea.l	LaserWnd,a0
			movea.l	IntBase,a6
			jsr	_LVOClearPointer(a6)
.End:			rts

Requester:		lea	WhoopsText,a3
Requester2:		sub.l	d0,d0
			sub.l	d1,d1
			sub.l	d2,d2
			sub.l	d3,d3
			movea.l	LaserWnd,a0
			movea.l	IntBase,a6
			jsr	_LVOAutoRequest(a6)
			tst.l	d0
			rts

ShortDelay:		moveq	#1,d1
			movea.l	DosBase,a6
			jsr	_LVODelay(a6)
			rts

LongDelay:		moveq	#50,d1			;1 sec
			movea.l	DosBase,a6
			jsr	_LVODelay(a6)
			rts

Echo:			tst.b	SerialFlag
			bne.s	.End

			move.b	d0,SerialByte
			movea.l	IORequestPtr,a1
			move.w	#3,28(a1)		;Command
			move.l	#1,36(a1)		:Length
			move.l	#SerialByte,40(a1)	;Data
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)
.End:			rts

Echo2:			tst.b	SerialFlag
			bne.s	.End

			movea.l	IORequestPtr,a1
			move.w	#3,28(a1)		;Command
			move.l	d0,36(a1)		:Length
			move.l	a0,40(a1)		;Data
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)
.End:			rts

GetByte:		tst.b	SerialFlag
			bne.s	.End

			movea.l	IORequestPtr,a1
			move.l	a1,-(sp)
			move.w	#9,28(a1)		;Query
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)
			movea.l	(sp)+,a1

			tst.l	32(a1)
			beq.s	.End

			move.w	#2,28(a1)		;Command
			move.l	#1,36(a1)		:Length
			move.l	#SerialByte2,40(a1)	;Data
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)
			sub.l	d0,d0
			move.b	SerialByte2,d0
.End:			rts

ClearSerial:		bsr.s	GetByte
			bne.s	ClearSerial
			rts

CalcMoveRate:		tst.l	d2
			bne.s	.Skip
			move.b	#1,FastMoveFlag
			rts

.Skip:			clr.b	FastMoveFlag

			cmpi.l	#20,d2
			blo.s	.Skip2

			subi.l	#19,d2
			moveq	#1,d1
			bra.s	.Skip3

.Skip2:			moveq	#21,d1
			sub.l	d2,d1
			moveq	#1,d2

.Skip3:			move.w	d1,MoveRate
			move.w	d2,MoveCount2

			move.w	XPos,d1
			move.w	XPosTemp,d0
			sub.w	d1,d0
			bpl.s	.Skip4
			neg.w	d0

.Skip4:			move.w	YPos,d2
			move.w	YPosTemp,d1
			sub.w	d2,d1
			bpl.s	.Skip5
			neg.w	d1

.Skip5:			cmp.w	d0,d1
			bls.s	.Skip6
			move.w	d1,d0

.Skip6:			move.w	d0,MoveDiff

			clr.w	MoveCount
			clr.w	MoveCount3
			move.w	XPos,XStartPos
			move.w	YPos,YStartPos
			rts

MoveLaser:		move.w	XPos,d0
			cmp.w	XPosTemp,d0
			bne.s	.Move

			move.w	YPos,d0
			cmp.w	YPosTemp,d0
			bne.s	.Move

			tst.l	FastMoveWait
			bpl.s	.End

			move.l	#-1,FastMoveWait
			clr.b	MoveStatus
			clr.b	WaitMoveFlag

			tst.b	MoveStatus2
			beq.s	.End

			clr.b	MoveStatus2
			move.b	#1,PrintPosSig
			move.w	XPos,XPosPrint
			move.w	YPos,YPosPrint
.End:			rts

.Move:			move.b	PirateFlag,d1
			ext.w	d1
			divs	d1,d0			;Pirate buster!

			tst.b	FastMoveFlag2
			bne.s	.FSkip

			tst.b	FastMoveFlag
			beq.s	.FSkip3

.FSkip:			move.w	XPosTemp,XPos
			move.w	YPosTemp,YPos
			bsr	CalcDCOffset

			tst.b	DrawMode2
			beq.s	.HSkip
			bsr	UpdateDCHires

.HSkip:			tst.b	FastMoveFlag
			bne.s	.FSkip2
			move.l	#3,FastMoveWait

.FSkip2:		tst.b	DrawMode2
			bne.s	.HSkip2
			move.l	#$01010101,AD0Update
.HSkip2:		bsr	SerialMove
			rts

.FSkip3:		move.w	MoveCount,d0
			cmp.w	MoveCount2,d0
			blo.s	.End

			clr.w	MoveCount

			move.w	MoveRate,d0
			add.w	d0,MoveCount3

			move.w	XPosTemp,d0
			cmp.w	XPos,d0
			beq.s	.YPos

			tst.b	DrawMode2
			bne.s	.HSkip3
			move.b	#1,AD0Update
			move.b	#1,AD3Update

.HSkip3:		move.w	MoveCount3,d1
			move.w	MoveDiff,d2
			cmp.w	d1,d2
			bhi.s	.Skip

			move.w	d0,XPos
			bra.s	.YPos

.Skip:			move.w	XStartPos,d3
			sub.w	d3,d0
			muls	d1,d0
			divs	d2,d0
			add.w	d0,d3
			move.w	d3,XPos

.YPos:			move.w	YPosTemp,d0
			cmp.w	YPos,d0
			beq.s	.Skip3

			tst.b	DrawMode2
			bne.s	.HSkip4
			move.b	#1,AD1Update
			move.b	#1,AD2Update

.HSkip4:		move.w	MoveCount3,d1
			move.w	MoveDiff,d2
			cmp.w	d1,d2
			bhi.s	.Skip2

			move.w	d0,YPos
			bra.s	.Skip3

.Skip2:			move.w	YStartPos,d3
			sub.w	d3,d0
			muls	d1,d0
			divs	d2,d0
			add.w	d0,d3
			move.w	d3,YPos

.Skip3:			move.w	XPos,d0
			subi.w	#XMax/2,d0
			add.w	XCenter,d0

			tst.b	SwapFlag
			beq.s	.Skip4
			neg.w	d0

.Skip4:			lsr.w	#1,d0
			bcc.s	.Skip5

			move.b	d0,DC0Offset
			addq.b	#1,DC0Offset
			bra.s	.Skip6

.Skip5:			move.b	d0,DC0Offset
.Skip6:			move.b	d0,DC3Offset

			move.w	YPos,d0
			subi.w	#YMax/2,d0
			add.w	YCenter,d0

			lsr.w	#1,d0
			bcc.s	.Skip7

			move.b	d0,DC1Offset
			addq.b	#1,DC1Offset
			bra.s	.Skip8

.Skip7:			move.b	d0,DC1Offset
.Skip8:			move.b	d0,DC2Offset

			tst.b	DrawMode2
			beq.s	.End2

			clr.b	DC0Offset
			clr.b	DC1Offset
			bsr	HiResDCOffset
			bsr	UpdateDCHires

.End2:			bsr.s	SerialMove
			rts

SerialMove:		tst.b	SendXYFlag
			beq	.End

			move.b	UnitNumber,d0
			cmp.b	SerialUnit,d0
			bne.s	.Skip

			sub.l	d0,d0
			move.w	XPos,d0
			divu	#16,d0
			bsr.s	.RoundOff
			cmp.b	SerialXPos,d0
			bne.s	.Skip

			sub.l	d0,d0
			move.w	YPos,d0
			divu	#14,d0
			bsr.s	.RoundOff
			cmp.b	SerialYPos,d0
			beq.s	.End

.Skip:			move.b	UnitNumber,SerialUnit
			bsr	SendUnitID

			move.b	#"M",d0
			bsr	Echo

			sub.l	d0,d0
			move.w	XPos,d0
			divu	#16,d0
			bsr.s	.RoundOff
			move.b	d0,SerialXPos
			bsr	Echo

			sub.l	d0,d0
			move.w	YPos,d0
			divu	#14,d0
			bsr.s	.RoundOff
			move.b	d0,SerialYPos
			bsr	Echo

			moveq	#2,d0
			bsr	Echo
.End:			rts

.RoundOff:		move.l	d0,d1
			swap	d1
			cmpi.w	#4,d1
			blo.s	.Skip2
			addq.b	#1,d0
.Skip2:			rts

CheckPosition:		move.w	XPos,d0
			cmp.w	XPosTemp,d0
			bne.s	.Move

			move.w	YPos,d0
			cmp.w	YPosTemp,d0
			bne.s	.Move
.End:			rts

.Move:			move.b	PirateFlag,d1
			ext.w	d1
			divs	d1,d0			;Pirate buster!

			tst.b	FastMoveFlag2
			bne.s	.Skip

			tst.b	FastMoveFlag
			beq.s	.End

.Skip:			move.w	XPosTemp,XPos
			move.w	YPosTemp,YPos

			tst.b	FastMoveFlag
			bne.s	.Skip2

			move.l	#3,FastMoveWait
.Skip2:			bsr	SerialMove
			rts

CalcDCOffset:		move.w	XPos,d0
			subi.w	#XMax/2,d0
			add.w	XCenter,d0

			tst.b	SwapFlag
			beq.s	.Skip
			neg.w	d0

.Skip:			lsr.w	#1,d0
			bcc.s	.Skip2

			move.b	d0,DC0Offset
			addq.b	#1,DC0Offset
			bra.s	.Skip3

.Skip2:			move.b	d0,DC0Offset
.Skip3:			move.b	d0,DC3Offset

			move.w	YPos,d0
			subi.w	#YMax/2,d0
			add.w	YCenter,d0

			lsr.w	#1,d0
			bcc.s	.Skip4

			move.b	d0,DC1Offset
			addq.b	#1,DC1Offset
			bra.s	.Skip5

.Skip4:			move.b	d0,DC1Offset
.Skip5:			move.b	d0,DC2Offset

			tst.b	DrawMode
			beq.s	.End

			tst.b	HiResFlag
			beq.s	.End

			clr.b	DC0Offset
			clr.b	DC1Offset
			bsr.s	HiResDCOffset
.End:			rts

HiResDCOffset:		move.w	YPos,d0
			subi.w	#YMax/2,d0
			add.w	YCenter,d0

			tst.b	InvertYFlag
			beq.s	.Skip
			neg.w	d0

.Skip:			move.l	d0,d1
			lsl.w	#8,d0
			or.b	d1,d0
			move.w	d0,HiResDCYOffset

			move.w	XPos,d0
			subi.w	#XMax/2,d0
			add.w	XCenter,d0

			tst.b	SwapFlag
			beq.s	.Skip2
			neg.w	d0

.Skip2:			tst.b	InvertXFlag
			beq.s	.Skip3
			neg.w	d0

.Skip3:			move.l	d0,d1
			lsl.w	#8,d0
			or.b	d1,d0
			move.w	d0,HiResDCXOffset
			rts

UpdateDCHires:		move.w	#$600,$dff09c		;Reset bit 9,10
			move.w	HiResDCYOffset,$dff0ca
			move.w	HiResDCXOffset,$dff0da
			rts

UpdateOutput:		tst.l	AD0Update2
			bne.s	.End

			move.l	AD0Update,AD0Update3
			beq.s	.End

			clr.l	AD0Update

			bsr	UpdateData

			tst.b	AD0Update3
			beq.s	.Skip
			bsr	Setup0Data

.Skip:			tst.b	AD1Update3
			beq.s	.Skip2
			bsr	Setup1Data

.Skip2:			tst.b	AD2Update3
			beq.s	.Skip3
			bsr	Setup2Data

.Skip3:			tst.b	AD3Update3
			beq.s	.Skip4
			bsr	Setup3Data

.Skip4:			tst.b	DMAFlag
			bne.s	.DMA

			move.l	AD0Update3,AD0Update2

			tst.b	DrawMode2
			beq.s	.End

			clr.w	AD2Update2
.End:			rts

.DMA:			tst.b	AD0Update3
			beq.s	.Skip5
			bsr	Setup0DMA2

.Skip5:			tst.b	AD1Update3
			beq.s	.Skip6
			bsr	Setup1DMA2

.Skip6:			tst.b	AD2Update3
			beq.s	.Skip7
			bsr	Setup2DMA2

.Skip7:			tst.b	AD3Update3
			beq.s	.Skip8
			bsr	Setup3DMA2

.Skip8:			bsr	SetDMA
			move.l	AD0Update3,AD0Update2

			tst.b	DrawMode2
			beq.s	.Skip9

			clr.w	AD2Update2

.Skip9:			move.l	Loc0PtrTemp,d0
			sub.l	Loc0Ptr,d0
			add.l	AD0MemPtr,d0
			move.l	d0,Loc0PtrTemp
			move.l	AD0MemPtr,Loc0Ptr

			move.l	Loc1PtrTemp,d0
			sub.l	Loc1Ptr,d0
			add.l	AD1MemPtr,d0
			move.l	d0,Loc1PtrTemp
			move.l	AD1MemPtr,Loc1Ptr

			move.l	Loc2PtrTemp,d0
			sub.l	Loc2Ptr,d0
			add.l	AD2MemPtr,d0
			move.l	d0,Loc2PtrTemp
			move.l	AD2MemPtr,Loc2Ptr

			move.l	Loc3PtrTemp,d0
			sub.l	Loc3Ptr,d0
			add.l	AD3MemPtr,d0
			move.l	d0,Loc3PtrTemp
			move.l	AD3MemPtr,Loc3Ptr
			rts

SetDMA:			movea.l	(4).l,a6
			jsr	_LVOForbid(a6)

			movea.l	DMA0Ptr,a0
			move.w	DMA0Len,d0
			movea.l	DMA1Ptr,a1
			move.w	DMA1Len,d1
			movea.l	DMA2Ptr,a2
			move.w	DMA2Len,d2
			movea.l	DMA3Ptr,a3
			move.w	DMA3Len,d3

			movea.l	#$dff000,a4

			move.l	a0,$a0(a4)		;Where 0
			move.l	a1,$b0(a4)		;Where 1
			move.l	a2,$c0(a4)		;Where 2
			move.l	a3,$d0(a4)		;Where 3

			move.w	d2,$c4(a4)		;Length 0
			move.w	d1,$b4(a4)		;Length 1
			move.w	d0,$a4(a4)		;Length 2
			move.w	d3,$d4(a4)		;Length 3

			movea.l	(4).l,a6
			jsr	_LVOPermit(a6)
			rts

UpdateData:		move.w	Vol0,Vol02
			move.w	Vol1,Vol12
			move.w	Vol2,Vol22
			move.w	Vol3,Vol32

			move.w	Spin0,Spin02
			move.w	Spin1,Spin12
			move.w	Spin2,Spin22
			move.w	Spin3,Spin32

			move.w	RotateAngle01,RotateAngle012
			move.w	RotateAngle23,RotateAngle232

			move.l	DrawingLen,DrawingLen2
			move.b	DrawingFlag,DrawingFlag2
			move.l	MorphStepsTemp,MorphStepsTemp2
			move.b	MorphFlag,MorphFlag2

			move.b	DrawMode,DrawMode3
			move.b	AutoRetraceFlag,AutoRetraceFlag3

UpdateData2:		tst.b	UpdateDataFlag
			beq.s	.Skip

			clr.b	UpdateDataFlag
			rts

.Skip:			move.w	Freq0,Freq02
			move.w	Freq1,Freq12
			move.w	Freq2,Freq22
			move.w	Freq3,Freq32

			move.w	Phase1,Phase12
			move.w	Phase2,Phase22
			move.w	Phase3,Phase32

			move.l	Len0,Len02
			move.l	Len1,Len12
			move.l	Len2,Len22
			move.l	Len3,Len32

			move.b	SkipFreq,SkipFreq2
			rts

CheckRestart:		tst.b	RestartFlag
			bne	RestartSound

			tst.b	Sync			;Phase sync
			bne.s	.SoftStart
			rts

.SoftStart:		tst.b	DMAFlag
			bne	RestartSound

.Wait:			tst.l	AD0Update2
			bne.s	.Wait

			move.w	#$780,$dff09a		;Disable all int
			bsr	StopDelay

			bsr	UpdateData2
			move.b	#1,UpdateDataFlag

			tst.b	SkipFreq2
			bne	.Ch1

			move.l	#35795465,d0
			move.l	Len02,d1
			mulu	Freq02,d1
			divu.l	d1,d0
			move.w	d0,$dff0a6
			move.w	d0,Speed0

			move.l	#35795465,d0
			move.l	Len12,d1
			mulu	Freq12,d1
			divu.l	d1,d0
			move.w	d0,$dff0b6
			move.w	d0,Speed1

			move.l	#35795465,d0
			move.l	Len22,d1
			mulu	Freq22,d1
			divu.l	d1,d0
			move.w	d0,$dff0c6
			move.w	d0,Speed2

			move.l	#35795465,d0
			move.l	Len32,d1
			mulu	Freq32,d1
			divu.l	d1,d0
			move.w	d0,$dff0d6
			move.w	d0,Speed3

.Ch1:			move.l	Len12,d0		;Ch1
			mulu	Phase12,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD1MemPtr2,d0
			move.l	d0,Loc1Ptr
			move.l	d0,d1

			add.l	Len12,d0
			move.l	d0,End1Ptr

			move.l	Loc1PtrTemp,d2
			cmp.l	d1,d2
			bhs.s	.Skip3
			add.l	Len12,d2
.Skip3:			cmp.l	d0,d2
			blo.s	.Skip4
			sub.l	Len12,d2
.Skip4:			move.l	d2,Loc1PtrTemp

			move.l	Len22,d0		;Ch2
			mulu	Phase22,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD2MemPtr2,d0
			move.l	d0,Loc2Ptr
			move.l	d0,d1

			add.l	Len22,d0
			move.l	d0,End2Ptr

			move.l	Loc2PtrTemp,d2
			cmp.l	d1,d2
			bhs.s	.Skip5
			add.l	Len22,d2
.Skip5:			cmp.l	d0,d2
			blo.s	.Skip6
			sub.l	Len22,d2
.Skip6:			move.l	d2,Loc2PtrTemp

			move.l	Len32,d0		;Ch3
			mulu	Phase32,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD3MemPtr2,d0
			move.l	d0,Loc3Ptr
			move.l	d0,d1

			add.l	Len32,d0
			move.l	d0,End3Ptr

			move.l	Loc3PtrTemp,d2
			cmp.l	d1,d2
			bhs.s	.Skip7
			add.l	Len32,d2
.Skip7:			cmp.l	d0,d2
			blo.s	.Skip8
			sub.l	Len32,d2
.Skip8:			move.l	d2,Loc3PtrTemp

			move.b	Sync,d1			;Ch1
			btst	#0,d1			;Sync with 0?
			beq.s	.Skip9

			bclr	#0,d1
			move.l	Loc0PtrTemp,d0
			sub.l	Loc0Ptr,d0
			bra.s	.Skip11

.Skip9:			btst	#3,d1			;Sync with 2?
			beq.s	.Skip10

			bclr	#3,d1
			move.l	Loc2PtrTemp,d0
			sub.l	Loc2Ptr,d0
			bra.s	.Skip11

.Skip10:		btst	#4,d1			;Sync with 3?
			beq.s	.Skip12

			bclr	#4,d1
			move.l	Loc3PtrTemp,d0
			sub.l	Loc3Ptr,d0

.Skip11:		add.l	Loc1Ptr,d0
			move.l	d0,Loc1PtrTemp

			tst.b	d1			;Ch2
			beq	RestartSound3

.Skip12:		btst	#1,d1			;Sync with 0?
			beq.s	.Skip13

			bclr	#1,d1
			move.l	Loc0PtrTemp,d0
			sub.l	Loc0Ptr,d0
			bra.s	.Skip14

.Skip13:		btst	#5,d1			;Sync with 3?
			beq.s	.Skip15

			bclr	#5,d1
			move.l	Loc3PtrTemp,d0
			sub.l	Loc3Ptr,d0

.Skip14:		add.l	Loc2Ptr,d0
			move.l	d0,Loc2PtrTemp

			tst.b	d1			;Ch3
			beq	RestartSound3

.Skip15:		move.l	Loc0PtrTemp,d0
			sub.l	Loc0Ptr,d0
			add.l	Loc3Ptr,d0
			move.l	d0,Loc3PtrTemp
			bra	RestartSound3

RestartSound:		bsr	CheckAutoDMA

.Wait:			tst.l	AD0Update2
			bne.s	.Wait

RestartSound2:		clr.l	AD0Update		;Hard start
			clr.b	RestartFlag
			clr.b	UpdateDataFlag

			bsr	UpdateData
			bsr	Setup0Data
			bsr	Setup1Data
			bsr	Setup2Data
			bsr	Setup3Data

			tst.b	NoWaitFlag
			bne.s	.NoStop

			bsr	CheckSmooth

			move.w	#$f,$dff096		;Stop DMA
			move.w	#$780,$dff09a		;Disable all int
			bsr	StopDelay

.NoStop:		clr.b	NoWaitFlag

			tst.b	DMAFlag
			bne.s	.DMA

			bsr	Setup0
			bsr	Setup1
			bsr	Setup2
			bsr	Setup3
			bra	.Skip

.DMA:			bsr	Setup0DMA
			bsr	Setup1DMA
			bsr	Setup2DMA
			bsr	Setup3DMA

			bsr	Setup0DMA2
			bsr	Setup1DMA2
			bsr	Setup2DMA2
			bsr	Setup3DMA2

			bsr	SetDMA

			move.l	AD0MemPtr,Loc0Ptr
			move.l	AD0MemPtr,Loc0PtrTemp
			move.l	AD1MemPtr,Loc1Ptr
			move.l	AD1MemPtr,Loc1PtrTemp
			move.l	AD2MemPtr,Loc2Ptr
			move.l	AD2MemPtr,Loc2PtrTemp
			move.l	AD3MemPtr,Loc3Ptr
			move.l	AD3MemPtr,Loc3PtrTemp

			clr.l	Speed0Temp
			clr.l	Speed2Temp

			bsr	GetLowestSpeed
			move.w	d1,LowSpeed

.Skip:			jsr	SetSoundVol2

RestartSound3:		move.w	#$780,$dff09c		;Reset bit 7,8,9,10

			tst.b	DMAFlag
			bne	.DMA

			movea.l	Loc0PtrTemp,a0
			move.w	(a0)+,Data0
			move.l	a0,Loc0PtrTemp
			cmpa.l	End0Ptr,a0
			blo.s	.Skip
			move.l	Loc0Ptr,Loc0PtrTemp

.Skip:			movea.l	Loc1PtrTemp,a0
			move.w	(a0)+,Data1
			move.l	a0,Loc1PtrTemp
			cmpa.l	End1Ptr,a0
			blo.s	.Skip2
			move.l	Loc1Ptr,Loc1PtrTemp

.Skip2:			movea.l	Loc2PtrTemp,a0
			move.w	(a0)+,Data2
			move.l	a0,Loc2PtrTemp
			cmpa.l	End2Ptr,a0
			blo.s	.Skip3
			move.l	Loc2Ptr,Loc2PtrTemp

.Skip3:			movea.l	Loc3PtrTemp,a0
			move.w	(a0)+,Data3
			move.l	a0,Loc3PtrTemp
			cmpa.l	End3Ptr,a0
			blo.s	.Skip4
			move.l	Loc3Ptr,Loc3PtrTemp

.Skip4:			movea.l	(4).l,a6
			jsr	_LVOForbid(a6)

			move.w	Data0,d0
			move.w	Data1,d1
			move.w	Data2,d2
			move.w	Data3,d3

			tst.b	DrawMode
			beq.s	.Skip5

			tst.b	HiResFlag
			beq.s	.Skip5

			move.b	#1,DrawMode2		;Ch 0 & 1 only
			move.w	HiResDCYOffset,d2
			move.w	HiResDCXOffset,d3

			move.w	#124,$dff0c6		;Go fast
			move.w	#124,Speed2
			move.w	#124,$dff0d6
			move.w	#124,Speed3

			move.w	#$8180,$dff09a		;Enable int
			move.w	d0,$dff0aa		;Start ints
			move.w	d1,$dff0ba
			move.w	d2,$dff0ca
			move.w	d3,$dff0da
			bra.s	.Skip6

.Skip5:			clr.b	DrawMode2		;All

			move.w	#$8780,$dff09a		;Enable int
			move.w	d0,$dff0aa		;Start ints
			move.w	d1,$dff0ba
			move.w	d2,$dff0ca
			move.w	d3,$dff0da

.Skip6:			movea.l	(4).l,a6
			jsr	_LVOPermit(a6)
			rts

.DMA:			tst.b	DrawMode
			beq.s	.Skip7

			tst.b	HiResFlag
			beq.s	.Skip7

			move.b	#1,DrawMode2		;Ch 0 & 1 only

			movea.l	(4).l,a6
			jsr	_LVOForbid(a6)

			move.w	HiResDCYOffset,d2
			move.w	HiResDCXOffset,d3

			move.w	#124,$dff0c6		;Go fast
			move.w	#124,Speed2
			move.w	#124,$dff0d6
			move.w	#124,Speed3

			move.w	#$8180,$dff09a		;Enable int
			move.w	#$8203,$dff096		;Start DMA
			move.w	d2,$dff0ca
			move.w	d3,$dff0da
			bra.s	.Skip6

.Skip7:			clr.b	DrawMode2		;All

			move.w	#$8780,$dff09a		;Enable int
			move.w	#$820f,$dff096		;Start DMA
			rts

CheckSmooth:		tst.b	SmoothChgFlag2
			bne.s	.Skip

			tst.b	SmoothChgFlag
			beq.s	.End

.Skip:			tst.b	NoWaitFlag
			bne.s	.End

			move.l	#$01010101,AD0Update2

			tst.b	DrawMode2
			beq.s	.Wait
			clr.w	AD2Update2

.Wait:			tst.l	AD0Update2
			bne.s	.Wait
.End:			rts

StopDelay:		bsr.s	GetLowestSpeed
			move.w	StopDelayCount,d2

.Wait:			move.w	d2,d0
.Loop:			dbf	d0,.Loop
			dbf	d1,.Wait
			rts

GetLowestSpeed:		move.w	Speed0,d1
			cmp.w	Speed1,d1
			bhs.s	.Skip
			move.w	Speed1,d1

.Skip:			tst.b	DrawMode
			beq.s	.Skip2

			tst.b	HiResFlag
			bne.s	.End

.Skip2:			cmp.w	Speed2,d1
			bhs.s	.Skip3
			move.w	Speed2,d1
.Skip3:			cmp.w	Speed3,d1
			bhs.s	.End
			move.w	Speed3,d1
.End:			rts

Setup0:			move.l	AD0MemPtr,d0
			move.l	d0,Loc0Ptr
			move.l	d0,Loc0PtrTemp

			move.l	Len02,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		add.l	d1,d0
			move.l	d0,End0Ptr

			tst.b	SkipFreq2
			bne.s	.Skip

			move.l	#35795465,d0		;Frequency
			mulu	Freq02,d1
			divu.l	d1,d0
			move.w	d0,$dff0a6		;Period (124 min!)
			move.w	d0,Speed0

.Skip:			clr.b	AD0Update2
			rts

Setup0DMA:		tst.b	SkipFreq2
			bne.s	.Skip

			move.l	Len02,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	#35795465,d0		;Frequency
			mulu	Freq02,d1
			divu.l	d1,d0
			move.w	d0,$dff0a6		;Period (124 min!)
			move.w	d0,Speed0

.Skip:			clr.b	AD0Update2
			rts

Setup0DMA2:		move.l	AD0MemPtr,DMA0Ptr	;Where

			move.l	Len02,d1

			tst.b	DrawMode3
			beq.s	.LSkip

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			lsr.l	#1,d1
			move.w	d1,DMA0Len		;Length
			rts

Setup0Data:		movea.l	OutputBufferPtr,a1
			subq.b	#1,BufferSwitch0
			bmi.s	.BSkip
			movea.l	OutputBufferPtr2,a1
			bne.s	.Skip
			movea.l	OutputBufferPtr3,a1
			bra.s	.Skip

.BSkip:			move.b	#2,BufferSwitch0

.Skip:			move.l	a1,AD0MemPtr

			tst.b	DrawMode
			beq.s	.Skip2
			move.l	a1,AD3MemPtr
			move.b	#1,AD3Update3		;Lock!

.Skip2:			movea.l	Loc0,a0
			move.l	Len02,d1

			tst.b	MorphFlag2
			beq.s	.Skip3
			movea.l	MorphMemPtr,a2
			bsr	MorphData
			movea.l	a1,a0

.Skip3:			move.w	RotateAngle012,d5
			beq.s	.Skip4

			tst.b	MorphFlag2
			beq.s	.Skip3a

			move.l	a0,-(sp)
			move.l	a1,-(sp)

			movea.l	ExtrasBufferPtr,a1
			adda.w	#MaxPoints,a1
			move.l	d1,d0
			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			move.l	(a0)+,(a1)+
			dbf	d0,.Loop

			movea.l	Loc1,a0
			movea.l	ExtrasBufferPtr,a1
			adda.w	#MaxPoints*2,a1
			movea.l	MorphMemPtr,a2
			adda.w	#MaxPoints,a2
			bsr	MorphData
			movea.l	a1,a2

			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			move.w	RotateAngle012,d5
			bra.s	.Skip3b

.Skip3a:		movea.l	Loc1,a2
.Skip3b:		bsr	RotateDataX
			movea.l	a1,a0

.Skip4:			move.w	Spin02,d5
			beq.s	.Skip7

			tst.b	DrawMode
			beq.s	.3DSkip

			tst.b	D3Flag
			beq.s	.3DSkip

			tst.b	MorphFlag2
			beq.s	.Skip5

			tst.b	MorphD3Flag
			beq.s	.Skip5

			move.l	a0,-(sp)
			move.l	a1,-(sp)

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			movea.l	ExtrasBufferPtr,a1
			adda.w	#MaxPoints*3,a1
			movea.l	MorphMemPtr,a2
			adda.w	#MaxPoints*2,a2
			bsr	MorphData
			movea.l	a1,a2

			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			move.w	Spin02,d5
			bra.s	.Skip6

.Skip5:			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2

.Skip6:			bsr	RotateDataX
			movea.l	a1,a0
			bra.s	.Skip7

.3DSkip:		bsr	SpinData
			movea.l	a1,a0

.Skip7:			move.b	DC0Offset,d2
			move.w	Vol02,d3
			move.b	InvertXFlag,d0
			bra	MoveData

Setup1:			move.l	AD1MemPtr,AD1MemPtr2

			move.l	Len12,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase12,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD1MemPtr,d0
			move.l	d0,Loc1Ptr
			move.l	d0,Loc1PtrTemp

			add.l	d1,d0
			move.l	d0,End1Ptr

			tst.b	SkipFreq2
			bne.s	.Skip

			move.l	#35795465,d0		;Frequency
			mulu	Freq12,d1
			divu.l	d1,d0
			move.w	d0,$dff0b6		;Period
			move.w	d0,Speed1

.Skip:			clr.b	AD1Update2
			rts

Setup1DMA:		tst.b	SkipFreq2
			bne.s	.Skip

			move.l	Len12,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	#35795465,d0		;Frequency
			mulu	Freq12,d1
			divu.l	d1,d0
			move.w	d0,$dff0b6		;Period
			move.w	d0,Speed1

.Skip:			clr.b	AD1Update2
			rts

Setup1DMA2:		move.l	Len12,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase12,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD1MemPtr,d0
			move.l	d0,DMA1Ptr		;Where

			lsr.l	#1,d1
			move.w	d1,DMA1Len		;Length
			rts

Setup1Data:		movea.l	OutputBufferPtr,a1
			subq.b	#1,BufferSwitch1
			bmi.s	.BSkip
			movea.l	OutputBufferPtr2,a1
			bne.s	.Skip
			movea.l	OutputBufferPtr3,a1
			bra.s	.Skip

.BSkip:			move.b	#2,BufferSwitch1

.Skip:			adda.w	#MaxPoints*4,a1
			move.l	a1,AD1MemPtr

			tst.b	DrawMode
			beq.s	.Skip2
			move.l	a1,AD2MemPtr
			move.b	#1,AD2Update3		;Lock!

.Skip2:			movea.l	Loc1,a0
			move.l	Len12,d1

			tst.b	MorphFlag2
			beq.s	.Skip3

			tst.w	RotateAngle012
			beq.s	.Skip3a

			move.l	a1,-(sp)

			movea.l	ExtrasBufferPtr,a0
			adda.w	#MaxPoints*2,a0
			move.l	d1,d0
			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			move.l	(a0)+,(a1)+
			dbf	d0,.Loop

			movea.l	(sp)+,a1
			movea.l	a1,a0

			move.w	RotateAngle012,d5
			movea.l	ExtrasBufferPtr,a2
			adda.w	#MaxPoints,a2
			bra.s	.Skip3b

.Skip3a:		movea.l	MorphMemPtr,a2
			adda.w	#MaxPoints,a2
			bsr	MorphData
			movea.l	a1,a0

.Skip3:			move.w	RotateAngle012,d5
			beq.s	.Skip4
			movea.l	Loc0,a2
.Skip3b:		bsr	RotateDataY
			movea.l	a1,a0

.Skip4:			move.w	Spin12,d5
			beq.s	.Skip7

			tst.b	DrawMode
			beq.s	.3DSkip

			tst.b	D3Flag
			beq.s	.3DSkip

			tst.b	MorphFlag2
			beq.s	.Skip5

			tst.b	MorphD3Flag
			beq.s	.Skip5

			movea.l	ExtrasBufferPtr,a2
			adda.w	#MaxPoints*3,a2
			bra.s	.Skip6

.Skip5:			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2

.Skip6:			bsr	RotateDataY
			movea.l	a1,a0
			bra.s	.Skip7

.3DSkip:		bsr	SpinData
			movea.l	a1,a0

.Skip7:			move.b	DC1Offset,d2
			move.w	Vol12,d3
			move.b	InvertYFlag,d0
			bra	MoveData

Setup2:			move.l	AD2MemPtr,AD2MemPtr2

			move.l	Len22,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase22,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD2MemPtr,d0
			move.l	d0,Loc2Ptr
			move.l	d0,Loc2PtrTemp

			add.l	d1,d0
			move.l	d0,End2Ptr

			tst.b	SkipFreq2
			bne.s	.Skip

			move.l	#35795465,d0		;Frequency
			mulu	Freq22,d1
			divu.l	d1,d0
			move.w	d0,$dff0c6		;Period
			move.w	d0,Speed2

.Skip:			clr.b	AD2Update2
			rts

Setup2DMA:		tst.b	SkipFreq2
			bne.s	.Skip

			move.l	Len22,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	#35795465,d0		;Frequency
			mulu	Freq22,d1
			divu.l	d1,d0
			move.w	d0,$dff0c6		;Period
			move.w	d0,Speed2

.Skip:			clr.b	AD2Update2
			rts

Setup2DMA2:		move.l	Len22,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase22,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD2MemPtr,d0
			move.l	d0,DMA2Ptr		;Where

			lsr.l	#1,d1
			move.w	d1,DMA2Len		;Length
			rts

Setup2Data:		tst.b	DrawMode
			beq.s	.Skip
			rts

.Skip:			movea.l	OutputBufferPtr,a1
			subq.b	#1,BufferSwitch2
			bmi.s	.BSkip
			movea.l	OutputBufferPtr2,a1
			bne.s	.Skip2
			movea.l	OutputBufferPtr3,a1
			bra.s	.Skip2

.BSkip:			move.b	#2,BufferSwitch2

.Skip2:			adda.l	#MaxPoints*8,a1
			move.l	a1,AD2MemPtr
			movea.l	Loc2,a0
			move.l	Len22,d1

			move.w	RotateAngle232,d5
			beq.s	.Skip3
			movea.l	Loc3,a2
			bsr	RotateDataY
			movea.l	a1,a0

.Skip3:			move.w	Spin22,d5
			beq.s	.Skip4
			bsr	SpinData
			movea.l	a1,a0

.Skip4:			move.b	DC2Offset,d2
			move.w	Vol22,d3
			move.b	InvertYFlag,d0
			bra	MoveData

Setup3:			move.l	AD3MemPtr,AD3MemPtr2

			move.l	Len32,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase32,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD3MemPtr,d0
			move.l	d0,Loc3Ptr
			move.l	d0,Loc3PtrTemp

			add.l	d1,d0
			move.l	d0,End3Ptr

			tst.b	SkipFreq2
			bne.s	.Skip

			move.l	#35795465,d0		;Frequency
			mulu	Freq32,d1
			divu.l	d1,d0
			move.w	d0,$dff0d6		;Period
			move.w	d0,Speed3

.Skip:			clr.b	AD3Update2
			rts

Setup3DMA:		tst.b	SkipFreq2
			bne.s	.Skip

			move.l	Len32,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	#35795465,d0		;Frequency
			mulu	Freq32,d1
			divu.l	d1,d0
			move.w	d0,$dff0d6		;Period
			move.w	d0,Speed3

.Skip:			clr.b	AD3Update2
			rts

Setup3DMA2:		move.l	Len32,d1

			tst.b	DrawMode3
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag3
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		move.l	d1,d0			;Phase
			mulu	Phase32,d0
			divu	#360,d0
			andi.l	#$ffff,d0
			add.l	AD3MemPtr,d0
			move.l	d0,DMA3Ptr		;Where

			lsr.l	#1,d1
			move.w	d1,DMA3Len		;Length
			rts

Setup3Data:		tst.b	DrawMode
			beq.s	.Skip
			rts

.Skip:			movea.l	OutputBufferPtr,a1
			subq.b	#1,BufferSwitch3
			bmi.s	.BSkip
			movea.l	OutputBufferPtr2,a1
			bne.s	.Skip2
			movea.l	OutputBufferPtr3,a1
			bra.s	.Skip2

.BSkip:			move.b	#2,BufferSwitch3

.Skip2:			adda.l	#MaxPoints*12,a1
			move.l	a1,AD3MemPtr
			movea.l	Loc3,a0
			move.l	Len32,d1

			move.w	RotateAngle232,d5
			beq.s	.Skip3
			movea.l	Loc2,a2
			bsr	RotateDataX
			movea.l	a1,a0

.Skip3:			move.w	Spin32,d5
			beq.s	.Skip4
			bsr	SpinData
			movea.l	a1,a0

.Skip4:			move.b	DC3Offset,d2
			move.w	Vol32,d3
			move.b	InvertXFlag,d0
			bra	MoveData

MorphData:		move.l	a1,-(sp)
			move.l	d1,-(sp)

			move.l	#32767,d3
			move.l	MorphStepsTemp2,d4
			move.l	MorphLen,d0

			cmp.l	d1,d0
			bhs.s	.Shrink

			move.l	d1,d6
			divu	d0,d6
			subq.w	#1,d6
			movea.w	d6,a3
			move.l	d6,d7
			swap	d7

			sub.l	d5,d5
			movea.l	d0,a4
			bra.s	.Loop

.Next:			addq.l	#1,a2
			move.w	a3,d6

.Loop:			move.b	(a2),d0
			move.b	(a0)+,d2
			ext.w	d0
			ext.w	d2
			sub.w	d0,d2
			muls	d4,d2
			divs	d3,d2
			add.b	d2,d0
			move.b	d0,(a1)+

			subq.l	#1,d1
			beq.s	.End

			dbf	d6,.Loop

			add.w	d7,d5
			cmp.w	a4,d5
			blo.s	.Next
			sub.w	a4,d5
			sub.w	d7,d5
			sub.l	d6,d6
			bra.s	.Loop

.Shrink:		move.l	d0,d6
			divu	d1,d6
			move.l	d6,d7
			swap	d7

			sub.l	d5,d5
			movea.l	d1,a3
			subq.l	#1,d1

.Loop2:			move.b	(a2),d0
			move.b	(a0)+,d2
			ext.w	d0
			ext.w	d2
			sub.w	d0,d2
			muls	d4,d2
			divs	d3,d2
			add.b	d2,d0
			move.b	d0,(a1)+

			adda.w	d6,a2
			add.w	d7,d5
			cmp.w	a3,d5
			blo.s	.Skip
			sub.w	a3,d5
			addq.l	#1,a2
.Skip:			dbf	d1,.Loop2

.End:			move.l	(sp)+,d1
			movea.l	(sp)+,a1
			rts

RotateDataX:		move.l	a1,-(sp)
			move.l	d1,-(sp)

			lea	SineData,a3
			lsl.w	#1,d5
			adda.w	d5,a3
			move.w	(a3),d6
			move.w	180(a3),d7
			move.l	#32767,d2
			subq.l	#1,d1

.Loop:			move.b	(a0)+,d0
			ext.w	d0
			muls	d7,d0
			divs	d2,d0

			move.l	d0,d3
			swap	d3
			bmi.s	.ROff

			cmpi.w	#16384,d3
			blo.s	.ROff2
			addq.w	#1,d0
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d3
			bhi.s	.ROff2
			tst.w	d3
			beq.s	.ROff2
			subq.w	#1,d0

.ROff2:			move.b	(a2)+,d5
			ext.w	d5
			muls	d6,d5
			divs	d2,d5

			move.l	d5,d3
			swap	d3
			bmi.s	.ROff3

			cmpi.w	#16384,d3
			blo.s	.ROff4
			addq.w	#1,d5
			bra.s	.ROff4

.ROff3:			cmpi.w	#-16384,d3
			bhi.s	.ROff4
			tst.w	d3
			beq.s	.ROff4
			subq.w	#1,d5

.ROff4:			sub.w	d5,d0
			move.b	d0,(a1)+
			dbf	d1,.Loop

			move.l	(sp)+,d1
			movea.l	(sp)+,a1
			rts

RotateDataY:		move.l	a1,-(sp)
			move.l	d1,-(sp)

			lea	SineData,a3
			lsl.w	#1,d5
			adda.w	d5,a3
			move.w	(a3),d6
			move.w	180(a3),d7
			move.l	#32767,d2
			subq.l	#1,d1

.Loop:			move.b	(a0)+,d0
			ext.w	d0
			muls	d7,d0
			divs	d2,d0

			move.l	d0,d3
			swap	d3
			bmi.s	.ROff

			cmpi.w	#16384,d3
			blo.s	.ROff2
			addq.w	#1,d0
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d3
			bhi.s	.ROff2
			tst.w	d3
			beq.s	.ROff2
			subq.w	#1,d0

.ROff2:			move.b	(a2)+,d5
			ext.w	d5
			muls	d6,d5
			divs	d2,d5

			move.l	d5,d3
			swap	d3
			bmi.s	.ROff3

			cmpi.w	#16384,d3
			blo.s	.ROff4
			addq.w	#1,d5
			bra.s	.ROff4

.ROff3:			cmpi.w	#-16384,d3
			bhi.s	.ROff4
			tst.w	d3
			beq.s	.ROff4
			subq.w	#1,d5

.ROff4:			add.w	d5,d0
			move.b	d0,(a1)+
			dbf	d1,.Loop

			move.l	(sp)+,d1
			movea.l	(sp)+,a1
			rts

SpinData:		move.l	a1,-(sp)
			move.l	d1,-(sp)

			lea	SineData,a3
			lsl.w	#1,d5
			adda.w	d5,a3
			move.w	180(a3),d7
			move.l	#32767,d2
			subq.l	#1,d1

.Loop:			move.b	(a0)+,d0
			ext.w	d0
			muls	d7,d0
			divs	d2,d0

			move.l	d0,d3
			swap	d3
			bmi.s	.ROff

			cmpi.w	#16384,d3
			blo.s	.ROff2
			addq.w	#1,d0
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d3
			bhi.s	.ROff2
			tst.w	d3
			beq.s	.ROff2
			subq.w	#1,d0

.ROff2:			move.b	d0,(a1)+
			dbf	d1,.Loop

			move.l	(sp)+,d1
			movea.l	(sp)+,a1
			rts

MoveData:		movea.l	a1,a3
			move.l	d1,d5
			move.l	d1,d6
			lsr.l	#1,d5
			moveq	#64,d4

			tst.b	d0
			bne	.Invert

			tst.b	DrawingFlag2
			beq.s	.Skip4

			cmpa.l	a0,a1
			bne.s	.Skip2

			movea.l	ExtrasBufferPtr,a4
			move.l	DrawingLen2,d0
			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			move.l	(a0)+,(a4)+
			dbf	d0,.Loop

			movea.l	ExtrasBufferPtr,a0

.Skip2:			movea.l	d6,a2

			move.l	d1,d6
			divu	DrawingLen2+2,d6
			subq.w	#1,d6
			movea.w	d6,a4
			move.l	d6,d7
			swap	d7

			suba.l	a5,a5
			movea.l	DrawingLen2,a6

.Next:			move.w	a4,d6

			move.b	(a0)+,d0
			ext.w	d0
			muls	d3,d0
			divs	d4,d0
			add.b	d2,d0

.Loop2:			move.b	d0,(a1)+
			subq.l	#1,d1
			beq.s	.Skip3
			dbf	d6,.Loop2

			adda.w	d7,a5
			cmpa.w	a6,a5
			blo.s	.Next
			suba.w	a6,a5
			suba.w	d7,a5
			sub.l	d6,d6
			bra.s	.Loop2

.Skip3:			move.l	a2,d6
			bra.s	.Skip5

.Skip4:			subq.l	#1,d1

.Loop3:			move.b	(a0)+,d0
			ext.w	d0
			muls	d3,d0
			divs	d4,d0
			add.b	d2,d0
			move.b	d0,(a1)+
			dbf	d1,.Loop3

.Skip5:			tst.b	DrawMode
			beq.s	.DoubleIt

			tst.b	AutoRetraceFlag
			bne.s	.Skip7

			btst	#0,d6			;Odd number?
			beq.s	.Skip6

			move.b	d0,(a1)+
			addq.l	#1,d6

.Skip6:			move.l	d6,d5
			lsr.l	#1,d5
			bra.s	.DoubleIt

.Skip7:			movea.l	a1,a2
			move.l	d6,d5
			subq.l	#1,d6

.Loop4:			move.b	-(a2),(a1)+
			dbf	d6,.Loop4

.DoubleIt:		addq.l	#1,d5
			lsr.l	#1,d5
			subq.l	#1,d5

.Loop5:			move.l	(a3)+,(a1)+
			dbf	d5,.Loop5
			rts

.Invert:		tst.b	DrawingFlag2
			beq.s	.ISkip4

			cmpa.l	a0,a1
			bne.s	.ISkip2

			movea.l	ExtrasBufferPtr,a4
			move.l	DrawingLen2,d0
			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.ILoop:			move.l	(a0)+,(a4)+
			dbf	d0,.ILoop

			movea.l	ExtrasBufferPtr,a0

.ISkip2:		movea.l	d6,a2

			move.l	d1,d6
			divu	DrawingLen2+2,d6
			subq.w	#1,d6
			movea.w	d6,a4
			move.l	d6,d7
			swap	d7

			suba.l	a5,a5
			movea.l	DrawingLen2,a6

.INext:			move.w	a4,d6

			move.b	(a0)+,d0
			ext.w	d0
			muls	d3,d0
			divs	d4,d0
			add.b	d2,d0
			neg.b	d0

.ILoop2:		move.b	d0,(a1)+
			subq.l	#1,d1
			beq	.Skip3
			dbf	d6,.ILoop2

			adda.w	d7,a5
			cmpa.w	a6,a5
			blo.s	.INext
			suba.w	a6,a5
			suba.w	d7,a5
			sub.l	d6,d6
			bra.s	.ILoop2

.ISkip4:		subq.l	#1,d1

.ILoop3:		move.b	(a0)+,d0
			ext.w	d0
			muls	d3,d0
			divs	d4,d0
			add.b	d2,d0
			neg.b	d0
			move.b	d0,(a1)+
			dbf	d1,.ILoop3
			bra	.Skip5

CheckSync:		clr.b	Sync

			tst.b	FreqSyncFlag
			beq.s	.Check

			move.w	Freq0,d0
			cmp.w	Freq0Sync,d0
			bne.s	.Check

			move.w	Freq1,d0
			cmp.w	Freq1Sync,d0
			bne.s	.Check

			move.w	Freq2,d0
			cmp.w	Freq2Sync,d0
			bne.s	.Check

			move.w	Freq3,d0
			cmp.w	Freq3Sync,d0
			bne.s	.Check
			rts

.Check:			sub.l	d0,d0
			move.w	Freq0,d0
			sub.l	d1,d1
			move.w	Freq1,d1
			sub.l	d2,d2
			bsr	.Compare

			sub.l	d0,d0
			move.w	Freq0,d0
			sub.l	d1,d1
			move.w	Freq2,d1
			moveq	#1,d2
			bsr.s	.Compare

			sub.l	d0,d0
			move.w	Freq0,d0
			sub.l	d1,d1
			move.w	Freq3,d1
			moveq	#2,d2
			bsr.s	.Compare

			btst	#0,Sync
			bne.s	.Skip

			sub.l	d0,d0
			move.w	Freq1,d0
			sub.l	d1,d1
			move.w	Freq2,d1
			moveq	#3,d2
			bsr.s	.Compare

			sub.l	d0,d0
			move.w	Freq1,d0
			sub.l	d1,d1
			move.w	Freq3,d1
			moveq	#4,d2
			bsr.s	.Compare

.Skip:			btst	#1,Sync
			bne.s	.Skip2

			btst	#3,Sync
			bne.s	.Skip2

			sub.l	d0,d0
			move.w	Freq2,d0
			sub.l	d1,d1
			move.w	Freq3,d1
			moveq	#5,d2
			bsr.s	.Compare
.Skip2:			rts

.Compare:		cmp.w	d0,d1
			bhi.s	.Skip3
			divu	d1,d0
			swap	d0
			tst.w	d0
			bra.s	.Skip4

.Skip3:			divu	d0,d1
			swap	d1
			tst.w	d1

.Skip4:			bne.s	.End
			bset	d2,Sync
.End:			rts

CRC:			bsr.s	.Mirror
 			not.l	d0

.Loop:			move.b	(a0)+,d2
			eor.b	d2,d0
			moveq	#7,d2

.Loop2:			lsr.l	#1,d0
			bcc.s	.Skip
			eori.l	#$edb88320,d0
.Skip:			dbf	d2,.Loop2
			dbf	d1,.Loop
			not.l	d0

.Mirror:		ror.w	#8,d0
			swap.w	d0
			ror.w	#8,d0
			rts

HEXtoASCII:		tst.l	d0
			bne.s	.Skip
			movea.l	a0,a1
			move.b	#$30,(a1)+
			clr.b	(a1)
			rts

.Skip:			lea	CBuff3,a1
			move.l	#$30303030,d1
			move.l	d1,(a1)+
			move.l	d1,(a1)+
			move.w	d1,(a1)
			suba.w	#28,a1
			move.l	d1,(a1)+
			move.l	d1,(a1)+
			move.w	#$3031,(a1)

.NextBit:		btst	#0,d0
			bne.s	.GoAddASCII
.Return:		lsr.l	#1,d0
			beq.s	.End
			lea	CBuff2,a1
			lea	CBuff,a2
			move.l	(a2)+,(a1)+
			move.l	(a2)+,(a1)+
			move.w	(a2),(a1)
			addq.l	#1,a1
			addq.l	#1,a2
			bsr.s	.AddASCII
			bra.s	.NextBit

.End:			lea	CBuff3,a2
.Loop:			cmpi.b	#$30,(a2)+
			beq.s	.Loop
			subq.l	#1,a2
			movea.l	a0,a1
.Loop2:			move.b	(a2)+,(a1)+
			bne.s	.Loop2
			subq.l	#1,a1
			rts

.GoAddASCII:		lea	CBuff+9,a1
			lea	CBuff3+9,a2
			bsr.s	.AddASCII
			bra.s	.Return

.AddASCII:		moveq	#9,d1
.Next:			move.b	(a1),d2
			subi.b	#$30,d2
			add.b	d2,(a2)
.Check:			cmpi.b	#$39,(a2)
			bhi.s	.Overflow
			subq.l	#1,a2
.Return2:		subq.l	#1,a1
			dbf	d1,.Next
			rts

.Overflow:		subi.b	#10,(a2)
			addq.b	#1,-(a2)
			move.l	a1,-(sp)
			move.l	a2,-(sp)
			move.l	d1,-(sp)
			sub.l	d1,d1
			bsr.s	.Check
			move.l	(sp)+,d1
			movea.l	(sp)+,a2
			movea.l	(sp)+,a1
			bra.s	.Return2

CBuff:			dcb.b	10,0
CBuff2:			dcb.b	10,0
CBuff3:			dcb.b	11,0
			even

ASCIItoHEX:		tst.b	(a0)
			bne.s	.Okay
			moveq	#-1,d0
			rts

.Okay:			movea.l	a0,a1
.Loop:			tst.b	(a0)+
			bne.s	.Loop

			sub.l	d0,d0
			sub.l	d2,d2
			subq.l	#1,a0
			moveq	#9,d5
			moveq	#1,d4

.Loop2:			move.b	-(a0),d2
			subi.b	#$30,d2
			move.l	d4,d1
			move.l	d4,d3
			mulu	d2,d1
			swap	d3
			mulu	d2,d3
			swap	d3
			clr.w	d3
			add.l	d3,d1
			add.l	d1,d0
			move.l	d4,d3
			mulu	#10,d4
			swap	d3
			mulu	#10,d3
			swap	d3
			clr.w	d3
			add.l	d3,d4
			cmpa.l	a0,a1
			beq.s	.End
			dbf	d5,.Loop2
.End:			rts

GetSqrRoot:		tst.l	d0
			beq.s	.End
			bpl.s	.Skip
			neg.l	d0

.Skip:			move.l	d0,d1
			sub.l	d2,d2
			move.l	d0,d3

.Loop:			move.l	d1,d4
			mulu	d4,d4
			cmp.l	d0,d4
			beq.s	.Found2
			blo.s	.Low

			move.l	d1,d3
			move.l	d3,d4
			sub.l	d2,d4
			lsr.l	#1,d4
			beq.s	.Found
			sub.l	d4,d1
			bra.s	.Loop

.Low:			move.l	d1,d2
			move.l	d3,d4
			sub.l	d2,d4
			lsr.l	#1,d4
			beq.s	.Found2
			add.l	d4,d1
			bra.s	.Loop

.Found:			subq.l	#1,d1
.Found2:		move.l	d1,d0
.End:			rts

MakeFileName:		move.l	a0,-(sp)
			lea	Dir,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			subq.l	#1,a1
			movea.l	(sp)+,a0
			bsr	MoveString
			rts

MakeFileName2:		move.l	a0,-(sp)
			lea	Dir2,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			subq.l	#1,a1
			movea.l	(sp)+,a0
			bsr	MoveString
			rts

MakeFilename3:		move.l	a0,-(sp)
			lea	Dir4,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			subq.l	#1,a1
			movea.l	(sp)+,a0
			bsr	MoveString
			rts

UpperByte:		cmpi.b	#$61,d0
			blo.s	.End
			cmpi.b	#$7a,d0
			bhi.s	.End
			subi.b	#$20,d0
.End:			rts

CmpString:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			tst.b	(a0)
			beq.s	.Yes

			move.b	(a1)+,d0
			bsr.s	UpperByte
			cmp.b	(a0)+,d0
			beq.s	.Loop
			sub.l	d0,d0

.End:			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

.Yes:			moveq	#1,d0
			bra.s	.End

CmpString2:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			tst.b	(a0)
			beq.s	.Yes

			move.b	(a1)+,d0
			bsr.s	UpperByte
			cmp.b	(a0)+,d0
			beq.s	.Loop

.No:			sub.l	d0,d0

.End:			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

.Yes:			tst.b	(a1)
			bne.s	.No

			moveq	#1,d0
			bra.s	.End

CmpString3:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			tst.b	(a0)
			beq.s	.Yes

			move.b	(a0)+,d0
			bsr.s	UpperByte
			move.b	d0,d1
			move.b	(a1)+,d0
			bsr.s	UpperByte
			cmp.b	d0,d1
			beq.s	.Loop

.No:			sub.l	d0,d0

.End:			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

.Yes:			tst.b	(a1)
			bne.s	.No

			moveq	#1,d0
			bra.s	.End

UpperString:		move.b	(a0)+,d0
			beq.s	.End
			bsr.s	UpperByte
			move.b	d0,(a1)+
			bra.s	UpperString
.End:			rts

MoveString:		move.b	(a0)+,(a1)+
			bne.s	MoveString
			rts

MoveString2:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			move.b	(a0)+,d5
			beq.s	.End
			cmpi.b	#$20,d5
			beq.s	.Loop
			move.b	d5,(a1)+
			bra.s	.Loop

.End:			clr.b	(a1)
			movea.l	a1,a5
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

MoveString3:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			move.b	(a0)+,d0
			beq.s	.End
			cmpi.b	#$20,d0
			beq.s	.Loop
			subq.l	#1,a0

.Loop2:			move.b	(a0)+,(a1)+
			bne.s	.Loop2
			subq.l	#1,a1

.Loop3:			cmpi.b	#$20,-(a1)
			beq.s	.Loop3
			addq.l	#1,a1

.End:			clr.b	(a1)
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

MoveString6:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			move.b	(a0)+,(a1)+
			beq.s	.Skip
			dbf	d0,.Loop
			clr.b	-1(a1)

.Skip:			movea.l	a1,a5
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

MoveString7:		move.l	a0,-(sp)
			move.l	a1,-(sp)

.Loop:			move.b	(a0)+,(a1)+
			beq.s	.Fill
			dbf	d0,.Loop

.Skip:			clr.b	-1(a1)
			movea.l	a1,a5
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

.Fill:			subq.l	#1,a1
.Loop2:			move.b	#" ",(a1)+
			dbf	d0,.Loop2
			bra.s	.Skip

CheckString:		move.b	(a1)+,d0
			beq.s	.End
			cmpi.b	#"/",d0
			beq.s	.FixIt
			cmpi.b	#":",d0
			bne.s	CheckString
.FixIt:			move.b	#"!",-1(a1)
			bra.s	CheckString
.End:			rts


;Req tools file requester subroutines:
;a0 - Filename, a1 - Dir, a2 - Okay text

ReqFile:		move.l	#1,ReqFRTags+16		;Ignore flags

ReqFile2:		move.l	a0,ReqFNPtr
			move.l	a1,ReqAttTags+4
			move.l	a2,ReqFRTags+12

			lea	ReqFN,a1
			bsr	MoveString

			move.l	ReqBase,d0
			bne.s	.Alloc

			lea	ReqToolsName,a1
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,ReqBase
			beq	.Missing

.Alloc:			movea.l	d0,a6
			sub.l	d0,d0			;File req
			suba.l	a0,a0
			jsr	_LVOrtAllocRequestA(a6)
			move.l	d0,FileRequestPtr
			beq.s	.End

			lea	ReqAttTags,a0
			movea.l	d0,a1
			movea.l	ReqBase,a6
			jsr	_LVOrtChangeReqAttrA(a6)

			movea.l	FileRequestPtr,a1
			lea	ReqFN,a2
			suba.l	a3,a3
			lea	ReqFRTags,a0
			movea.l	ReqBase,a6
			jsr	_LVOrtFileRequestA(a6)

			movea.l	FileRequestPtr,a2
			movea.l	ReqBase,a6

			tst.l	d0
			beq.s	.Abort

			movea.l	16(a2),a0		;Dir
			movea.l	ReqAttTags+4,a1
			moveq	#79,d0
			bsr	MoveString6
			movea.l	a1,a0
			bsr	MoveString3

			bsr.s	CheckDirString

			lea	ReqFN,a0		;Filename
			tst.b	(a0)
			beq.s	.Abort

			movea.l	ReqFNPtr,a1
			moveq	#40,d0
			bsr	MoveString6
			movea.l	a1,a0
			bsr	MoveString2

			movea.l	a2,a1
			jsr	_LVOrtFreeRequest(a6)
			moveq	#2,d0
.End:			rts

.Abort:			movea.l	a2,a1
			jsr	_LVOrtFreeRequest(a6)
			moveq	#1,d0
			rts

.Missing:		bsr	FlashScreen
			lea	Error23Text,a0
			bsr	PrintStatus
			moveq	#1,d0
			rts

CheckDirString:		tst.b	(a0)+
			beq.s	.End

.Loop:			tst.b	(a0)+
			bne.s	.Loop

			cmpi.b	#"/",-2(a0)
			beq.s	.End

			cmpi.b	#":",-2(a0)
			beq.s	.End

			move.b	#"/",-1(a0)
			clr.b	(a0)+
.End:			rts

CheckPreload:		lea	ASCIIBuffer,a1
			movea.l	a1,a2

.Loop:			tst.b	(a1)+
			bne.s	.Loop

.Loop2:			move.b	-(a1),d0
			cmpi.b	#"/",d0
			beq.s	.Skip
			cmpi.b	#":",d0
			beq.s	.Skip
			cmpa.l	a1,a2
			bne.s	.Loop2
			bra.s	.Next

.Skip:			addq.l	#1,a1
.Next:			lea	Preset1Filename,a0	;Check presets first
			lea	Preset1DrawPtr,a2
			moveq	#39,d2

.Loop3:			tst.l	(a2)
			beq.s	.Skip3
			bsr	CmpString3
			bne.s	.Found2
.Skip3:			addq.l	#8,a2
			adda.w	#41,a0
			dbf	d2,.Loop3

.Next2:			move.l	PreloadPtr,d1
			beq.s	.End

.Loop4:			movea.l	d1,a0
			addq.l	#8,a0
			bsr	CmpString2
			bne.s	.Found
			move.l	-8(a0),d1
			bne.s	.Loop4

.End:			sub.l	d0,d0
			rts

.Found:			tst.b	CheckOnlyFlag
			bne.s	.Skip4

			move.l	a0,-(sp)
			move.l	-4(a0),d0
			sub.l	d1,d1
			move.l	d0,FileMemSize
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FileMemPtr
			movea.l	(sp)+,a0
			beq.s	.Error

			adda.w	#42,a0
			movea.l	d0,a1
			move.l	FileMemSize,d0
			bsr	MoveMemBlock

.Skip4:			moveq	#1,d0
			rts

.Found2:		tst.b	CheckOnlyFlag
			bne.s	.Skip4

			move.l	a2,-(sp)
			move.l	4(a2),d0
			sub.l	d1,d1
			move.l	d0,FileMemSize
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FileMemPtr
			movea.l	(sp)+,a0
			beq.s	.Error

			movea.l	(a0),a0
			movea.l	d0,a1
			move.l	FileMemSize,d0
			bsr	MoveMemBlock
			bra.s	.Skip4

.Error:			clr.l	FileMemSize
			moveq	#2,d0
			rts


;Load file into mem:
;d0 = 1 - Can't allocate mem
;d0 = 2 - Can't Lock/Open/Read

LoadFile:		bsr	GetInfoMem
			beq	.Error
			bsr	GetLock
			beq	.Error2
			bsr	GetFileSize
			beq.s	.Error3

			tst.b	AddMemFlag
			beq.s	.Skip
			addi.l	#50,d0

.Skip:			sub.l	d1,d1
			move.l	d0,FileMemSize
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FileMemPtr
			beq.s	.Error6

			bsr	OpenFile
			beq.s	.Error4

			move.l	d0,d1			;Read file
			move.l	FileMemPtr,d2

			tst.b	AddMemFlag
			beq.s	.Skip2
			addi.l	#50,d2

.Skip2:			move.l	FileMemSize,d3
			movea.l	DosBase,a6
			jsr	_LVORead(a6)
			tst.l	d0
			bmi.s	.Error5

			bsr	CloseFile
			bsr	Unlock
			bsr.s	FreeInfoMem
			sub.l	d0,d0
			rts

.Error6:		clr.l	FileMemSize
			bsr	Unlock
			bsr.s	FreeInfoMem

.Error:			moveq	#1,d0
			rts

.Error5:		bsr	CloseFile
.Error4:		bsr.s	FreeFileMem
.Error3:		bsr.s	Unlock
.Error2:		bsr.s	FreeInfoMem
			moveq	#2,d0
			rts

FreeFileMem:		movea.l	FileMemPtr,a1
			move.l	FileMemSize,d0
			beq.s	.End
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	FileMemSize
.End:			rts

GetInfoMem:		move.l	#260,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FileInfoBlockPtr
			rts

FreeInfoMem:		movea.l	FileInfoBlockPtr,a1
			move.l	#260,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

GetLock:		moveq	#-2,d2
			move.l	#ASCIIBuffer,d1
			movea.l	DosBase,a6
			jsr	_LVOLock(a6)
			move.l	d0,FileLockPtr
			rts

Unlock:			move.l	FileLockPtr,d1
			movea.l	DosBase,a6
			jsr	_LVOUnLock(a6)
			rts

GetFileSize:		move.l	FileLockPtr,d1
			move.l	FileInfoBlockPtr,d2
			movea.l	DosBase,a6
			jsr	_LVOExamine(a6)
			tst.l	d0
			beq.s	.End
			movea.l	FileInfoBlockPtr,a0
			move.l	124(a0),d0
.End:			rts

OpenFile:		move.l	#1005,d2
OpenFile2:		move.l	#ASCIIBuffer,d1
			movea.l	DosBase,a6
			jsr	_LVOOpen(a6)
			move.l	d0,FilePtr
			rts

CloseFile:		move.l	FilePtr,d1
			movea.l	DosBase,a6
			jsr	_LVOClose(a6)
			rts

SaveFile:		move.l	#1006,d2
			bsr.s	OpenFile2
			beq.s	.Error

			move.l	d0,d1			;Write
			move.l	FileMemPtr,d2
			move.l	FileMemSize,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error2

			bsr.s	CloseFile
			sub.l	d0,d0
			rts

.Error2:		bsr.s	CloseFile
.Error:			moveq	#1,d0
			rts

DeleteFile:		move.l	#ASCIIBuffer,d1
			movea.l	DosBase,a6
			jsr	_LVODeleteFile(a6)
			tst.l	d0
			rts

GetOutputBuff:		sub.l	d1,d1
GetOutputBuff2:		move.l	d1,-(sp)

			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,OutputBufferPtr3Temp
			beq.s	.Error

			move.l	(sp),d1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,OutputBufferPtr2Temp
			beq.s	.Error2

			move.l	(sp),d1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,OutputBufferPtrTemp
			beq.s	.Error3
			addq.l	#4,sp
			rts

.Error3:		movea.l	OutputBufferPtr2Temp,a1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

.Error2:		movea.l	OutputBufferPtr3Temp,a1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

.Error:			addq.l	#4,sp
			sub.l	d0,d0
			rts

FreeOutputBuff:		movea.l	OutputBufferPtr,a1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

			movea.l	OutputBufferPtr2,a1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

			movea.l	OutputBufferPtr3,a1
			move.l	#MaxPoints*16,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

FreeSeqMem:		movea.l	SeqMemPtr,a1
			move.l	SeqMemSize,d0
			beq.s	.End
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	SeqMemSize
.End:			rts

FreeSeqMem2:		tst.l	(a0)
			beq.s	.End
			move.l	a0,-(sp)
			movea.l	(a1),a1
			move.l	(a0),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			movea.l	(sp)+,a0
			clr.l	(a0)
.End:			rts

FreeCharBSMem:		move.l	LastChrPtr,d0
			beq.s	.End

.Loop:			movea.l	d0,a1
			move.l	(a1),-(sp)
			moveq	#8,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			move.l	(sp)+,d0
			bne.s	.Loop
			clr.l	LastChrPtr
.End:			rts

FreePreloadMem:		move.l	PreloadPtr,d0
			beq.s	.End

			move.l	a0,-(sp)
.Loop:			movea.l	d0,a1
			move.l	(a1),-(sp)
			move.l	4(a1),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			move.l	(sp)+,d0
			bne.s	.Loop
			clr.l	PreloadPtr
			movea.l	(sp)+,a0
.End:			rts

FreeUndoMem:		move.l	UndoPtr,d0
			beq.s	.End

.Loop:			movea.l	d0,a1
			move.l	(a1),-(sp)
			move.l	8(a1),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			move.l	(sp)+,d0
			bne.s	.Loop
			clr.l	UndoPtr
			clr.l	UndoPtr2
.End:			rts

MoveMemBlock:		addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			move.l	(a0)+,(a1)+
			dbf	d0,.Loop
			rts

LASERfIRE:		tst.b	LASERfIREFlag		;Convert seq to LASERfIRE
			bne.s	.LfSkip
			rts

.LfSkip:		bsr	GetLASERfIREMem
			bne.s	.LfSkip2

			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus2
			bsr	LongDelay
			rts

.LfSkip2:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			movea.l	SeqMemPtr,a1
			movea.l	SeqMemPtr,a2
			adda.l	SeqMemSize,a2
			move.l	a1,SequencePtr
			move.l	a2,SequenceEnd

			move.b	#1,FromLASERfIRE
			tst.b	AutoPreloadFlag
			bne.l	APreload

LfPlay2:		lea	StatusLASERfIRE2,a0
			bsr	PrintStatus2

LfPlay:			move.l	LASERfIRESeqLen,d0
			cmpi.l	#MaxSeqSize,d0
			blo.s	.LfSkip

			bsr	FlashScreen
			lea	Error31Text,a0
			bsr	PrintStatus2
			bsr	LongDelay
			rts

.LfSkip:		movea.l	SequencePtr,a1
			movea.l	SequenceEnd,a2

			cmpa.l	SeqMemPtr,a1		;First?
			beq.s	.Skip

.Loop:			cmpi.b	#$a,(a1)+		;Find next
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop

.SendLf:		tst.l	LASERfIRESeqLen		;Any?
			beq.s	.End

			sub.l	d1,d1			;Mark last
			bsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen
			bsr	SendLASERfIRESeq
.End:			rts

.SkipLFSP:		addq.l	#1,a1
.Skip:			cmpa.l	a1,a2
			bls.s	.SendLf
			cmpi.b	#$a,(a1)
			beq.s	.SkipLFSP
			cmpi.b	#" ",(a1)
			beq.s	.SkipLFSP

ProcessLfCmd:		cmpi.b	#";",(a1)
			beq	.Comment

			lea	SetTrackCmd,a0
			bsr	CmpString
			bne	.SetTrack

			lea	SizeXCmd,a0
			bsr	CmpString
			bne	.SizeX

			lea	SizeYCmd,a0
			bsr	CmpString
			bne	.SizeY

			lea	RotateXYCmd,a0
			bsr	CmpString
			bne	.RotateXY

			lea	SpinXCmd,a0
			bsr	CmpString
			bne	.SpinX

			lea	SpinYCmd,a0
			bsr	CmpString
			bne	.SpinY

			lea	RollXCmd,a0
			bsr	CmpString
			bne	.RollX

			lea	RollYCmd,a0
			bsr	CmpString
			bne	.RollY

			lea	WaitASCmd,a0
			bsr	CmpString
			bne	.WaitAutoStop

			lea	FactoryLfCmd,a0
			bsr	CmpString
			bne	.Factory

			lea	FactoryLfCmd2,a0
			bsr	CmpString
			bne	.FactoryAll

			lea	LCCmd,a0
			bsr	CmpString
			bne	.LC

			lea	MoveCmd,a0
			bsr	CmpString
			bne	.Move

			lea	WaitCmd,a0
			bsr	CmpString
			bne	.Wait

			lea	WaitMoveCmd,a0
			bsr	CmpString
			bne	.WaitMove

			lea	FastMoveCmd,a0
			bsr	CmpString
			bne	.FastMove

			lea	FastMove2Cmd,a0
			bsr	CmpString
			bne	.FastMove2

			lea	ScreenCmd,a0
			bsr	CmpString
			bne	.Screen

			lea	ScreenCmd2,a0
			bsr	CmpString
			bne	.Screen2

			lea	MorphScreenCmd,a0
			bsr	CmpString
			bne	.MorphScreen

			lea	MorphScreenCmd2,a0
			bsr	CmpString
			bne	.MorphScreen2

			lea	DrawScreenCmd,a0
			bsr	CmpString
			bne	.DrawScreen

			lea	DrawScreenCmd2,a0
			bsr	CmpString
			bne	.DrawScreen2

			lea	DisolveScreenCmd,a0
			bsr	CmpString
			bne	.DisolveScreen

			lea	DisolveScreenCmd2,a0
			bsr	CmpString
			bne	.DisolveScreen2

			lea	ShutterCmd,a0
			bsr	CmpString
			bne	.Shutter

			lea	Shutter2Cmd,a0
			bsr	CmpString
			bne	.Shutter2

			lea	ColourCmd,a0
			bsr	CmpString
			bne	.Colour

			lea	FXCmd,a0
			bsr	CmpString
			bne	.FX

			lea	UseDefCmd,a0
			bsr	CmpString
			bne	.DefCmd

			lea	ReplayCmd,a0
			bsr	CmpString
			bne	.Replay

			lea	NextCmd,a0
			jsr	CmpString
			bne	.Next

			lea	StopCmd,a0
			bsr	CmpString
			bne	.Stop

			lea	PresetCmd2,a0
			bsr	CmpString
			bne	.Preset

			lea	PreloadCmd,a0
			bsr	CmpString
			bne.l	Preload

			lea	LoadPackCmd,a0
			bsr	CmpString
			bne.l	LoadPack

.Comment:		addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			bra	LfPlay

.SetTrack:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.STLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.STSkip
			cmpi.b	#" ",d0
			beq.s	.STSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.STSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.STLoop
			bra.l	Error2

.STSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#32,d0
			bhi.l	Error2

			moveq	#1,d1			;Set track cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Track
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.SizeX:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#2,d0			;Size X cmd

.Set:			move.l	d0,SetCmd
			move.l	a1,SequencePtr

			moveq	#-1,d0
			clr.l	SetTrack
			move.l	d0,SetValue
			move.l	d0,SetStep
			move.l	d0,SetCount
			move.l	d0,SetMax
			move.l	d0,SetMin
			move.l	d0,SetFlags

			bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip2

.SXLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.l	Error
			cmpi.b	#" ",d0
			beq.s	.SXSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop
			bra.l	Error2

.SXSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#32,d0
			bhi.l	Error2

			move.l	d0,SetTrack

.SXSkip2:		bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop2
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip4

.SXLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip3a
			cmpi.b	#" ",d0
			beq.s	.SXSkip3
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop2
			bra.l	Error2

.SXSkip3a:		subq.l	#1,a1

.SXSkip3:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#64,d0
			bhi.l	Error2

			move.l	d0,SetValue

.SXSkip4:		bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop3
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip6

.SXLoop3:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip5a
			cmpi.b	#" ",d0
			beq.s	.SXSkip5
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop3
			bra.l	Error2

.SXSkip5a:		subq.l	#1,a1

.SXSkip5:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#64,d0
			bhi.l	Error2

			move.l	d0,SetStep

.SXSkip6:		bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop4
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip8

.SXLoop4:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip7a
			cmpi.b	#" ",d0
			beq.s	.SXSkip7
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop4
			bra.l	Error2

.SXSkip7a:		subq.l	#1,a1

.SXSkip7:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#3000,d0
			bhi.l	Error2

			move.l	d0,SetCount

.SXSkip8:		bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop5
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip10

.SXLoop5:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip9a
			cmpi.b	#" ",d0
			beq.s	.SXSkip9
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop5
			bra.l	Error2

.SXSkip9a:		subq.l	#1,a1

.SXSkip9:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#64,d0
			bhi.l	Error2

			move.l	d0,SetMax

.SXSkip10:		bsr	.CheckEnd
			beq	.SXSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#"-",(a1)
			bne.s	.SXLoop6
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.SXSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.SXSkip12

.SXLoop6:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip11a
			cmpi.b	#" ",d0
			beq.s	.SXSkip11
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SXLoop6
			bra.l	Error2

.SXSkip11a:		subq.l	#1,a1

.SXSkip11:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#63,d0
			bhi.l	Error2

			move.l	d0,SetMin

.SXSkip12:		sub.l	d1,d1
			cmpi.b	#$a,(a1)
			beq.s	.SXSkip19
			cmpi.b	#"-",(a1)
			beq.s	.SXSkip19

.SXSkip13:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SXSkip18
			cmpi.b	#" ",d0
			beq.s	.SXSkip18
			bsr	UpperByte
			cmpi.b	#"O",d0
			beq.s	.SXSkip18
			cmpi.b	#"U",d0
			bne.s	.SXSkip14
			bset	#0,d1
.SXSkip14:		cmpi.b	#"D",d0
			bne.s	.SXSkip15
			bset	#1,d1
.SXSkip15:		cmpi.b	#"S",d0
			bne.s	.SXSkip16
			bset	#2,d1
.SXSkip16:		cmpi.b	#"A",d0
			bne.s	.SXSkip17
			bset	#3,d1
.SXSkip17:		cmpa.l	a1,a2
			bhi.s	.SXSkip13

.SXSkip18:		btst	#3,d1
			beq.s	.SXSkip18a
			move.b	d1,d0
			andi.b	#$3,d0
			beq.l	Error

.SXSkip18a:		move.l	d1,SetFlags

.SXSkip19:		move.l	SetMax,d0
			bmi.s	.SXSkip20
			move.l	SetMin,d1
			bmi.s	.SXSkip20
			cmp.l	d0,d1
			bhs.l	Error2

.SXSkip20:		move.l	SetCmd,d1
			bsr	AddLfCmd
			move.l	SetTrack,d0		;Track
			move.w	d0,6(a1)
			move.l	SetFlags,d0
			move.w	d0,8(a1)		;Flags
			move.l	SetValue,d0
			move.w	d0,10(a1)		;Value
			move.l	SetStep,d0
			move.w	d0,12(a1)		;Step
			move.l	SetCount,d0
			move.w	d0,14(a1)		;Count
			move.l	SetMax,d0
			move.w	d0,16(a1)		;Max
			move.l	SetMin,d0
			move.w	d0,18(a1)		;Min

			moveq	#20,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.CheckEnd:		move.b	(a1),d0
			bsr	UpperByte
			cmpi.b	#"O",d0
			beq.s	.SXSkip12f
			cmpi.b	#"U",d0
			beq.s	.SXSkip12f
			cmpi.b	#"D",d0
			beq.s	.SXSkip12f
			cmpi.b	#"S",d0
			beq.s	.SXSkip12f
			cmpi.b	#"A",d0
.SXSkip12f:		rts

.SizeY:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#3,d0			;Size Y cmd
			bra	.Set

.RotateXY:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#4,d0			;RotateXY cmd

.Set2:			move.l	d0,SetCmd
			move.l	a1,SequencePtr

			moveq	#-1,d0
			clr.l	SetTrack
			move.l	d0,SetValue
			move.l	d0,SetStep
			move.l	d0,SetCount
			move.l	d0,SetMax
			move.l	d0,SetMin
			move.l	d0,SetFlags
			move.l	d0,SetXOffset
			move.l	d0,SetYOffset

			bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip2

.RXYLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.l	Error
			cmpi.b	#" ",d0
			beq.s	.RXYSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop
			bra.l	Error2

.RXYSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#32,d0
			bhi.l	Error2

			move.l	d0,SetTrack

.RXYSkip2:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop2
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip4

.RXYLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip3a
			cmpi.b	#" ",d0
			beq.s	.RXYSkip3
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop2
			bra.l	Error2

.RXYSkip3a:		subq.l	#1,a1

.RXYSkip3:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#359,d0
			bhi.l	Error2

			move.l	d0,SetValue

.RXYSkip4:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop3
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip6

.RXYLoop3:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip5a
			cmpi.b	#" ",d0
			beq.s	.RXYSkip5
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop3
			bra.l	Error2

.RXYSkip5a:		subq.l	#1,a1

.RXYSkip5:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#359,d0
			bhi.l	Error2

			move.l	d0,SetStep

.RXYSkip6:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop4
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip8

.RXYLoop4:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip7a
			cmpi.b	#" ",d0
			beq.s	.RXYSkip7
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop4
			bra.l	Error2

.RXYSkip7a:		subq.l	#1,a1

.RXYSkip7:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#3000,d0
			bhi.l	Error2

			move.l	d0,SetCount

.RXYSkip8:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop5
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip10

.RXYLoop5:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip9a
			cmpi.b	#" ",d0
			beq.s	.RXYSkip9
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop5
			bra.l	Error2

.RXYSkip9a:		subq.l	#1,a1

.RXYSkip9:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#360,d0
			bhi.l	Error2

			move.l	d0,SetMax

.RXYSkip10:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop6
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip10a

.RXYLoop6:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip11c
			cmpi.b	#" ",d0
			beq.s	.RXYSkip11
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop6
			bra.l	Error2

.RXYSkip11c:		subq.l	#1,a1

.RXYSkip11:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#358,d0
			bhi.l	Error2

			move.l	d0,SetMin

.RXYSkip10a:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop6a
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip10b

.RXYLoop6a:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip11d
			cmpi.b	#" ",d0
			beq.s	.RXYSkip11a
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop6a
			bra.l	Error2

.RXYSkip11d:		subq.l	#1,a1

.RXYSkip11a:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#65534,d0
			bhi.l	Error2

			subi.l	#32767,d0
			move.l	d0,SetXOffset

.RXYSkip10b:		bsr	.CheckEnd
			beq	.RXYSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RXYLoop6b
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RXYSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RXYSkip12

.RXYLoop6b:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip11e
			cmpi.b	#" ",d0
			beq.s	.RXYSkip11b
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RXYLoop6b
			bra.l	Error2

.RXYSkip11e:		subq.l	#1,a1

.RXYSkip11b:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#65534,d0
			bhi.l	Error2

			subi.l	#32767,d0
			move.l	d0,SetYOffset

.RXYSkip12:		sub.l	d1,d1
			cmpi.b	#$a,(a1)
			beq.s	.RXYSkip19
			cmpi.b	#"-",(a1)
			beq.s	.RXYSkip19

.RXYSkip13:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RXYSkip18
			cmpi.b	#" ",d0
			beq.s	.RXYSkip18
			bsr	UpperByte
			cmpi.b	#"O",d0
			beq.s	.RXYSkip18
			cmpi.b	#"U",d0
			bne.s	.RXYSkip14
			bset	#0,d1
.RXYSkip14:		cmpi.b	#"D",d0
			bne.s	.RXYSkip15
			bset	#1,d1
.RXYSkip15:		cmpi.b	#"S",d0
			bne.s	.RXYSkip16
			bset	#2,d1
.RXYSkip16:		cmpi.b	#"A",d0
			bne.s	.RXYSkip17
			bset	#3,d1
.RXYSkip17:		cmpa.l	a1,a2
			bhi.s	.RXYSkip13

.RXYSkip18:		btst	#3,d1
			beq.s	.RXYSkip18a
			move.b	d1,d0
			andi.b	#$3,d0
			beq.l	Error

.RXYSkip18a:		move.l	d1,SetFlags

.RXYSkip19:		move.l	SetMax,d0
			bmi.s	.RXYSkip20
			move.l	SetMin,d1
			bmi.s	.RXYSkip20
			cmp.l	d0,d1
			bhs.l	Error2

.RXYSkip20:		move.l	SetCmd,d1
			bsr	AddLfCmd
			move.l	SetTrack,d0		;Track
			move.w	d0,6(a1)
			move.l	SetFlags,d0
			move.w	d0,8(a1)		;Flags
			move.l	SetValue,d0
			move.w	d0,10(a1)		;Value
			move.l	SetStep,d0
			move.w	d0,12(a1)		;Step
			move.l	SetCount,d0
			move.w	d0,14(a1)		;Count
			move.l	SetMax,d0
			move.w	d0,16(a1)		;Max
			move.l	SetMin,d0
			move.w	d0,18(a1)		;Min
			move.l	SetXOffset,20(a1)	;Offset
			move.l	SetYOffset,24(a1)	;Offset

			moveq	#28,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.SpinX:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#5,d0			;Spin X cmd
			bra	.Set2

.SpinY:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#6,d0			;Spin Y cmd
			bra	.Set2

.RollX:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#7,d0			;Roll X cmd

.Set3:			move.l	d0,SetCmd
			move.l	a1,SequencePtr

			moveq	#-1,d0
			clr.l	SetTrack
			move.l	d0,SetValue
			move.l	d0,SetStep
			move.l	d0,SetCount
			move.l	d0,SetMax
			move.l	d0,SetMin
			move.l	d0,SetFlags

			bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip2

.RollLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.l	Error
			cmpi.b	#" ",d0
			beq.s	.RollSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop
			bra.l	Error2

.RollSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#32,d0
			bhi.l	Error2

			move.l	d0,SetTrack

.RollSkip2:		bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop2
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip4

.RollLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip3a
			cmpi.b	#" ",d0
			beq.s	.RollSkip3
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop2
			bra.l	Error2

.RollSkip3a:		subq.l	#1,a1

.RollSkip3:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#65534,d0
			bhi.l	Error2

			move.l	d0,SetValue

.RollSkip4:		bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop3
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip6

.RollLoop3:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip5a
			cmpi.b	#" ",d0
			beq.s	.RollSkip5
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop3
			bra.l	Error2

.RollSkip5a:		subq.l	#1,a1

.RollSkip5:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#65534,d0
			bhi.l	Error2

			move.l	d0,SetStep

.RollSkip6:		bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop4
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip8

.RollLoop4:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip7a
			cmpi.b	#" ",d0
			beq.s	.RollSkip7
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop4
			bra.l	Error2

.RollSkip7a:		subq.l	#1,a1

.RollSkip7:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#3000,d0
			bhi.l	Error2

			move.l	d0,SetCount

.RollSkip8:		bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop5
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip10

.RollLoop5:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip9a
			cmpi.b	#" ",d0
			beq.s	.RollSkip9
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop5
			bra.l	Error2

.RollSkip9a:		subq.l	#1,a1

.RollSkip9:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#65534,d0
			bhi.l	Error2

			move.l	d0,SetMax

.RollSkip10:		bsr	.CheckEnd
			beq	.RollSkip12

			lea	ASCIIBuffer,a0
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#"-",(a1)
			bne.s	.RollLoop6
			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error
			cmpi.b	#$a,(a1)
			beq	.RollSkip19
			cmpi.b	#" ",(a1)+
			bne.l	Error
			cmpa.l	a1,a2
			bls.l	Error
			bra.s	.RollSkip12

.RollLoop6:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip11a
			cmpi.b	#" ",d0
			beq.s	.RollSkip11
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RollLoop6
			bra.l	Error2

.RollSkip11a:		subq.l	#1,a1

.RollSkip11:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#65533,d0
			bhi.l	Error2

			move.l	d0,SetMin

.RollSkip12:		sub.l	d1,d1
			cmpi.b	#$a,(a1)
			beq.s	.RollSkip19
			cmpi.b	#"-",(a1)
			beq.s	.RollSkip19

.RollSkip13:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RollSkip18
			cmpi.b	#" ",d0
			beq.s	.RollSkip18
			bsr	UpperByte
			cmpi.b	#"O",d0
			beq.s	.RollSkip18
			cmpi.b	#"U",d0
			bne.s	.RollSkip14
			bset	#0,d1
.RollSkip14:		cmpi.b	#"D",d0
			bne.s	.RollSkip15
			bset	#1,d1
.RollSkip15:		cmpi.b	#"S",d0
			bne.s	.RollSkip16
			bset	#2,d1
.RollSkip16:		cmpi.b	#"A",d0
			bne.s	.RollSkip17
			bset	#3,d1
.RollSkip17:		cmpa.l	a1,a2
			bhi.s	.RollSkip13

.RollSkip18:		btst	#3,d1
			beq.s	.RollSkip18a
			move.b	d1,d0
			andi.b	#$3,d0
			beq.l	Error

.RollSkip18a:		move.l	d1,SetFlags

.RollSkip19:		move.l	SetMax,d0
			bmi.s	.RollSkip20
			move.l	SetMin,d1
			bmi.s	.RollSkip20
			cmp.l	d0,d1
			bhs.l	Error2

.RollSkip20:		move.l	SetCmd,d1
			bsr	AddLfCmd
			move.l	SetTrack,d0		;Track
			move.w	d0,6(a1)
			move.l	SetFlags,d0
			move.w	d0,8(a1)		;Flags
			move.l	SetValue,10(a1)		;Value
			move.l	SetStep,14(a1)		;Step
			move.l	SetCount,d0
			move.w	d0,18(a1)		;Count
			move.l	SetMax,20(a1)		;Max
			move.l	SetMin,24(a1)		;Min

			moveq	#28,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.RollY:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			moveq	#8,d0			;Roll Y cmd
			bra	.Set3

.WaitAutoStop:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.WALoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.WASkip
			cmpi.b	#" ",d0
			beq.s	.WASkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.WASkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.WALoop
			bra.l	Error2

.WASkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			cmpi.l	#32,d0
			bhi.l	Error2

			moveq	#13,d1			;Wait Auto Stop cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Track
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Factory:		adda.w	#8,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.FacLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.FacSkip
			cmpi.b	#" ",d0
			beq.s	.FacSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.FacSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.FacLoop
			bra.l	Error2

.FacSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			cmpi.l	#32,d0
			bhi.l	Error2

			bsr	LfFactoryIt
			bra	LfPlay

.FactoryAll:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#28,d1			;Factory all cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.LC:			adda.w	#3,a1
			cmpa.l	a1,a2
			bls.l	Error

			cmpi.b	#'"',(a1)
			bne.s	.QSkip

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

.QSkip:			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.Loop			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip
			cmpi.b	#'"',d0
			beq.s	.Skip
			bsr	UpperByte
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop
			jmp	(Error).l

.Skip:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			bra	LfGetCommand

.Wait:			adda.w	#5,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.Loop3:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip4
			cmpi.b	#" ",d0
			beq.s	.Skip4
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip4
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop3
			bra.l	Error2

.Skip4:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#$ffff,d0
			bhi.l	Error2

			moveq	#11,d1			;Wait cmd
			bsr	AddLfCmd
			move.l	DefTrack,d1
			move.w	d1,6(a1)		;Track
			move.w	d0,8(a1)		;Wait count
			moveq	#10,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Move:			adda.w	#5,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.Loop4:			move.b	(a1)+,d0
			cmpi.b	#" ",d0
			beq.s	.Skip5
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop4
			bra.l	Error2

.Skip5:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#XMax,d0
			bhi.l	Error2

			move.w	d0,LfXPosTemp

			lea	ASCIIBuffer,a0

.Loop5:			move.b	(a1)+,d0
			cmpi.b	#" ",d0
			beq.s	.Skip6
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop5
			bra.l	Error2

.Skip6:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#YMax,d0
			bhi.l	Error2

			move.w	d0,LfYPosTemp

			lea	ASCIIBuffer,a0

.Loop6:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip7
			cmpi.b	#" ",d0
			beq.s	.Skip7
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip7
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop6
			bra.l	Error2

.Skip7:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			cmpi.l	#3000,d0
			bhi.l	Error2

			moveq	#10,d1			;Move cmd
			bsr	AddLfCmd
			move.l	DefTrack,d2
			move.w	d2,6(a1)		;Track
			move.w	LfXPosTemp,d1		;ToXpos
			mulu.w	#32767/(XMax/2),d1
			move.l	d1,8(a1)
			move.w	LfYPosTemp,d1		;ToYPos
			mulu.w	#32767/(YMax/2),d1
			move.l	d1,12(a1)
			move.w	d0,16(a1)		;Rate

			moveq	#18,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.WaitMove:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#12,d1			;Wait move cmd
			bsr	AddLfCmd
			move.l	DefTrack,d0
			move.w	d0,6(a1)		;Track
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.FastMove:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#14,d1			;Fastmove cmd
			bsr	AddLfCmd
			move.l	DefTrack,d0
			move.w	d0,6(a1)		;Track
			move.w	#1,8(a1)		;On
			moveq	#10,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.FastMove2:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#14,d1			;Fastmove cmd
			bsr	AddLfCmd
			move.l	DefTrack,d0
			move.w	d0,6(a1)		;Track
			clr.w	8(a1)			;Off
			moveq	#10,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Screen2:		addq.l	#1,a1
			move.b	#1,Preserve

.Screen:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.SLoop:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.SSkip
			cmpi.b	#$a,d0
			beq.s	.SSkip
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.SSkip
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.SLoop

.SSkip:			clr.b	(a0)

			bsr	CheckPreload
			beq.s	.PSkip

			cmpi.b	#2,d0
			beq.l	Error3
			bra.s	.PSkip2

.PSkip:			bsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq.s	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			bsr	CmpString
			beq.s	.Error3

.PSkip2:		movea.l	FileMemPtr,a0
			moveq	#15,d1			;Screen cmd
			bsr	LfAddScreen
			bsr	FreeFileMem
			bra	LfPlay

.Error2:		movea.l	StackPtr,sp
			bsr	FlashScreen
			lea	Error18Text,a0
			bsr	PrintStatus
			jmp	Scope

.Error3:		bsr	FreeFileMem
			bra.l	Error17

.MorphScreen2:		addq.l	#1,a1
			move.b	#1,Preserve

.MorphScreen:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.MSLoop:		move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.MSSkip
			cmpi.b	#$a,d0
			beq.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.MSLoop

.MSSkip:		clr.b	(a0)

			cmpi.b	#" ",(a1)+
			bne.l	Error

			cmpa.l	a1,a2
			bls.l	Error

			lea	ValueASCII,a0

.MSLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.MSSkip2
			cmpi.b	#" ",d0
			beq.s	.MSSkip2
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.MSSkip2
			cmpa.l	#ValueASCII+10,a0
			blo.s	.MSLoop2
			bra.l	Error2

.MSSkip2:		clr.b	(a0)
			lea	ValueASCII,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#$ffff,d0
			bhi.l	Error2

			move.l	d0,LfRate

			bsr	CheckPreload
			beq.s	.PSkip5

			cmpi.b	#2,d0
			beq.l	Error3
			bra.s	.PSkip6

.PSkip5:		bsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			bsr	CmpString
			beq	.Error3

.PSkip6:		movea.l	FileMemPtr,a0
			moveq	#16,d1			;Morph screen cmd
			bsr	LfAddScreen2
			bsr	FreeFileMem
			bra	LfPlay

.DrawScreen2:		addq.l	#1,a1
			move.b	#1,Preserve

.DrawScreen:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.DSLoop:		move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.DSSkip
			cmpi.b	#$a,d0
			beq.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.DSLoop

.DSSkip:		clr.b	(a0)

			cmpi.b	#" ",(a1)+
			bne.l	Error

			cmpa.l	a1,a2
			bls.l	Error

			lea	ValueASCII,a0

.DSLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.DSSkip2
			cmpi.b	#" ",d0
			beq.s	.DSSkip2
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.DSSkip2
			cmpa.l	#ValueASCII+10,a0
			blo.s	.DSLoop2
			bra.l	Error2

.DSSkip2:		clr.b	(a0)
			lea	ValueASCII,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#$ffff,d0
			bhi.l	Error2

			move.l	d0,LfRate

			bsr	CheckPreload
			beq.s	.PSkip3

			cmpi.b	#2,d0
			beq.l	Error3
			bra.s	.PSkip4

.PSkip3:		bsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			bsr	CmpString
			beq	.Error3

.PSkip4:		movea.l	FileMemPtr,a0
			moveq	#17,d1			;Draw screen cmd
			bsr	LfAddScreen2
			bsr	FreeFileMem
			bra	LfPlay

.DisolveScreen2:	addq.l	#1,a1
			move.b	#1,Preserve

.DisolveScreen:		adda.w	#16,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.DvSLoop:		move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.DvSSkip
			cmpi.b	#$a,d0
			beq.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.DvSLoop

.DvSSkip:		clr.b	(a0)

			cmpi.b	#" ",(a1)+
			bne.l	Error

			cmpa.l	a1,a2
			bls.l	Error

			lea	ValueASCII,a0

.DvSLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.DvSSkip2
			cmpi.b	#" ",d0
			beq.s	.DvSSkip2
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.DvSSkip2
			cmpa.l	#ValueASCII+10,a0
			blo.s	.DvSLoop2
			bra.l	Error2

.DvSSkip2:		clr.b	(a0)
			lea	ValueASCII,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			beq.l	Error2

			cmpi.l	#$ffff,d0
			bhi.l	Error2

			move.l	d0,LfRate

			bsr	CheckPreload
			beq.s	.DvPSkip3

			cmpi.b	#2,d0
			beq.l	Error3
			bra.s	.DvPSkip4

.DvPSkip3:		bsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			bsr	CmpString
			beq	.Error3

.DvPSkip4:		movea.l	FileMemPtr,a0
			moveq	#18,d1			;Draw screen cmd
			bsr	LfAddScreen2
			bsr	FreeFileMem
			bra	LfPlay

.Shutter:		adda.w	#8,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#19,d1			;Shutter cmd
			bsr	AddLfCmd
			move.w	#1,6(a1)		;On
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Shutter2:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#19,d1			;Shutter cmd
			bsr	AddLfCmd
			clr.w	6(a1)			;Off
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Colour:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.CLoop:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.CSkip
			cmpi.b	#" ",d0
			beq.s	.CSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.CSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.CLoop
			bra.l	Error2

.CSkip:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			cmpi.l	#63,d0
			bhi.l	Error2

			moveq	#20,d1			;Colour cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Value
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.FX:			adda.w	#3,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.FXLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.FXSkip
			cmpi.b	#" ",d0
			beq.s	.FXSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.FXSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.FXLoop
			bra.l	Error2

.FXSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			cmpi.l	#63,d0
			bhi.l	Error2

			moveq	#21,d1			;FX cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Value
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.DefCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			sub.l	d0,d0
			move.b	(a1),d0
			cmpi.b	#"1",d0
			blo.l	Error2
			cmpi.b	#"4",d0
			bhi.l	Error2

			subi.b	#"1",d0
			lea	ScrDef1,a0
			mulu	#8,d0
			adda.l	d0,a0

			moveq	#22,d1			;Screen def cmd
			bsr	AddLfCmd
			move.l	DefTrack,d0
			move.w	d0,6(a1)		;Track
			move.w	(a0)+,8(a1)		;Size X
			move.w	(a0)+,10(a1)		;Size Y
			move.w	(a0)+,d0
			mulu.w	#32767/(XMax/2),d0
			move.l	d0,12(a1)		;Pos X
			move.w	(a0),d0
			mulu.w	#32767/(YMax/2),d0
			move.l	d0,16(a1)		;Pos Y
			moveq	#20,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Replay:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			cmpi.b	#" ",(a1)
			bne	.RSkip2

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			lea	ASCIIBuffer,a0

.RLoop:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RSkip
			cmpi.b	#" ",d0
			beq.s	.RSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.l	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RLoop
			bra.l	Error2

.RSkip:			subq.l	#1,a1
			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			bsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi.l	Error

			cmpi.l	#1,d0
			bls.l	Error2

			cmpi.l	#$ffff,d0
			bhi.l	Error2

			moveq	#24,d1			;Replay next cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Next count
			moveq	#8,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.RSkip2:		moveq	#23,d1			;Replay cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Next:			adda.w	#4,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#25,d1			;Next cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Stop:			adda.w	#3,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			moveq	#26,d1			;Stop cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfPlay

.Preset:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls.l	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.PreLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.PreSkip
			cmpi.b	#" ",d0
			beq.s	.PreSkip
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.PreSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.PreLoop
			bra.l	Error2

.PreSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error

			subq.l	#1,d0
			cmpi.l	#39,d0
			bhi.l	Error2

			lea	Preset1DrawPtr,a0
			mulu	#8,d0
			adda.w	d0,a0

			tst.l	(a0)
			beq	LfPlay

			movea.l	(a0),a0
			moveq	#14,d1			;Screen cmd
			bsr.s	LfAddScreen
			bra	LfPlay

LfAddScreen:		bsr	AddLfCmd

			move.l	46(a0),d0		;Get size
			move.l	d0,d1
			add.l	d0,d1

			btst	#3,23(a0)		;3D?
			beq.s	.Skip
			add.l	d0,d1

.Skip:			bclr	#6,23(a0)		;Set invert flags
			tst.b	InvertXFlag
			beq.s	.ISkip
			bset	#6,23(a0)

.ISkip:			bclr	#7,23(a0)
			tst.b	InvertYFlag
			beq.s	.ISkip2
			bset	#7,23(a0)

.ISkip2:		btst	#0,d1			;Odd address?
			beq.s	.Skip2
			addq.l	#1,d1

.Skip2:			move.l	d1,d0
			addi.l	#62+10,d1		;Len
			move.l	d1,(a1)
			add.l	d1,LASERfIRESeqLen
			move.l	DefTrack,d1
			move.w	d1,6(a1)		;Track
			sub.l	d1,d1
			move.b	Preserve,d1
			move.w	d1,8(a1)		;Type

			lea	10(a1),a1
			addi.l	#62,d0
			bsr	MoveMemBlock
			clr.b	Preserve
			rts

LfAddScreen2:		bsr	AddLfCmd

			move.l	46(a0),d0		;Get size
			move.l	d0,d1
			add.l	d0,d1

			btst	#3,23(a0)		;3D?
			beq.s	.Skip
			add.l	d0,d1

.Skip:			bclr	#6,23(a0)		;Set invert flags
			tst.b	InvertXFlag
			beq.s	.ISkip
			bset	#6,23(a0)

.ISkip:			bclr	#7,23(a0)
			tst.b	InvertYFlag
			beq.s	.ISkip2
			bset	#7,23(a0)

.ISkip2:		btst	#0,d1			;Odd address?
			beq.s	.Skip2
			addq.l	#1,d1

.Skip2:			move.l	d1,d0
			addi.l	#62+12,d1		;Len
			move.l	d1,(a1)
			add.l	d1,LASERfIRESeqLen
			move.l	DefTrack,d1		;Track
			move.w	d1,6(a1)
			sub.l	d1,d1
			move.b	Preserve,d1
			move.w	d1,8(a1)		;Type
			move.l	LfRate,d1
			move.w	d1,10(a1)		;Rate

			lea	12(a1),a1
			addi.l	#62,d0
			bsr	MoveMemBlock
			clr.b	Preserve
			rts

AddLfCmd:		movea.l	LASERfIRECmdPtr,a1	;d1-cmd
			adda.l	(a1),a1			;Len
			move.l	a1,LASERfIRECmdPtr
			move.w	d1,4(a1)		;Cmd #
			rts

AddLfLCCmd:		bsr.s	AddLfCmd
			move.l	DefTrack,d2		;Track
			move.w	d2,6(a1)
			move.w	d3,8(a1)		;Flags
			move.w	d0,10(a1)		;Value
			move.w	d4,12(a1)		;Step
			move.w	d5,14(a1)		;Count
			move.w	d6,16(a1)		;Max
			move.w	d7,18(a1)		;Min

			moveq	#20,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			rts

AddLfLCCmd2:		bsr.s	AddLfCmd
			move.l	DefTrack,d2		;Track
			move.w	d2,6(a1)
			move.w	d3,8(a1)		;Flags
			move.w	d0,10(a1)		;Value
			move.w	d4,12(a1)		;Step
			move.w	d5,14(a1)		;Count
			move.w	d6,16(a1)		;Max
			move.w	d7,18(a1)		;Min
			move.l	#-1,20(a1)		;X Offset
			move.l	#-1,24(a1)		;Y Offset

			moveq	#28,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			rts

LfSendPos:		tst.b	RecordStatus
			bne	.NoLf

			tst.b	LASERfIREFlag
			beq	.NoLf

			bsr	GetLASERfIREMem
			bne.s	.LfSkip

			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus2
			bsr	ShortDelay
			bra.s	.NoLf

.LfSkip:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			moveq	#10,d1			;Move cmd
			bsr	AddLfCmd
			move.l	DefTrack,d2
			move.w	d2,6(a1)		;Track
			move.w	XPosTemp,d1		;ToXpos
			mulu.w	#32767/(XMax/2),d1
			move.l	d1,8(a1)
			move.w	YPosTemp,d1		;ToYPos
			mulu.w	#32767/(YMax/2),d1
			move.l	d1,12(a1)
			clr.w	16(a1)			;Rate
			moveq	#18,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			moveq	#26,d1			;Stop cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			sub.l	d1,d1			;Mark last
			bsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen
			bsr	SendLASERfIRESeq
.NoLf:			rts

LfGetCommand:		clr.l	NextCmdPtr
			clr.b	CommandSubCode
			clr.b	FromChannel
			clr.b	ToChannel
			clr.b	Value2

			move.b	(a0)+,d0
			beq.l	Error

			bsr	UpperByte

			cmpi.b	#"F",d0			;Factory?
			beq	LfFactory

			cmpi.b	#"L",d0			;Location?
			beq	LfNext

			cmpi.b	#"-",d0			;To?
			beq.s	.Skip

			subi.b	#"0",d0			;Channel #
			cmpi.b	#3,d0
			bhi.l	Error
			move.b	d0,FromChannel

			move.b	(a0)+,d0
			beq.l	Error

			cmpi.b	#"-",d0			;To?
			bne.s	.Skip3

.Skip:			move.b	(a0)+,d0
			beq.l	Error

			cmpi.b	#"0",d0
			blo.l	Error

			cmpi.b	#"3",d0
			bhi.s	.Skip2

			subi.b	#"0",d0			;Channel #
			move.b	d0,ToChannel

			move.b	(a0)+,d0
			beq.l	Error
			bra.s	.Skip3

.Skip2:			move.b	#3,ToChannel

.Skip3:			bsr	UpperByte

			sub.l	d1,d1			;Vol?
			cmpi.b	#"V",d0
			beq.s	.Okay

			moveq	#1,d1			;Freq?
			cmpi.b	#"F",d0
			beq.s	.Okay

			moveq	#2,d1			;Phase?
			cmpi.b	#"P",d0
			beq.s	.Okay

			moveq	#3,d1			;Spin?
			cmpi.b	#"S",d0
			beq.s	.Okay

			moveq	#4,d1			;Rotate?
			cmpi.b	#"R",d0
			bne.l	Error

.Okay:			move.b	d1,CommandCode

			move.b	(a0)+,d0		;Get sub command
			beq.l	Error

			bsr	UpperByte

			moveq	#1,d1			;Max
			cmpi.b	#"T",d0
			beq.s	.Okay2
			cmpi.b	#"H",d0
			beq.s	.Okay2

			moveq	#2,d1			;Min
			cmpi.b	#"B",d0
			beq.s	.Okay2
			cmpi.b	#"L",d0
			beq.s	.Okay2

			moveq	#3,d1			;Scan up
			cmpi.b	#"U",d0
			beq.s	.Okay2

			moveq	#4,d1			;Scan dn
			cmpi.b	#"D",d0
			beq.s	.Okay2

			moveq	#5,d1			;Scan up/dn
			cmpi.b	#"S",d0
			beq.s	.Okay2

			subq.l	#1,a0

.GetValue:		lea	ValueASCII,a1		;Get value

.Loop:			move.b	(a0)+,d0
			beq.s	.Done
			cmpi.b	#" ",d0
			beq.s	.StripSpaces
			cmpi.b	#".",d0
			beq.s	.Next2
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			move.b	d0,(a1)+
			cmpa.l	#ValueASCII+10,a1
			blo.s	.Loop
			bra.l	Error2

.Okay2:			move.b	d1,CommandSubCode
			bra.s	.GetValue

.Next2:			move.b	(a0)+,d0
			cmpi.b	#"0",d0
			blo.l	Error
			cmpi.b	#"9",d0
			bhi.l	Error
			subi.b	#"0",d0
			move.b	d0,Value2

			move.b	(a0)+,d0
			beq.s	.Done
			cmpi.b	#" ",d0
			bne.l	Error2

.StripSpaces:		move.b	(a0),d0
			beq.s	.Done
			cmpi.b	#" ",d0
			bne.s	.Next

			addq.l	#1,a0
			bra.s	.StripSpaces

.Next:			move.l	a0,NextCmdPtr

.Done:			clr.b	(a1)
			lea	ValueASCII,a0
			bsr	ASCIItoHEX
			tst.l	d0
			bmi.l	Error
			move.l	d0,Value

			move.b	FromChannel,d0

LfNextChannel:		move.b	d0,ChannelNumber

			sub.l	d0,d0
			move.b	CommandCode,d0

			sub.l	d1,d1
			move.b	CommandSubCode,d1
			beq.s	.Skip

			mulu	#5,d1
			add.l	d1,d0

.Skip:			mulu	#4,d0
			lea	LfCommandTable,a6
			movea.l	(a6,d0),a6
			jmp	(a6)

LfNext:			move.b	ChannelNumber,d0
			addq.b	#1,d0
			cmp.b	ToChannel,d0
			bls.s	LfNextChannel

			movea.l	NextCmdPtr,a0
			move.l	a0,d0
			bne	LfGetCommand
			bra	LfPlay

LfCommandTable:		dc.l	LfSetVolume
			dc.l	LfSetFreq
			dc.l	LfNext
			dc.l	LfSetSpin
			dc.l	LfSetRotate

			dc.l	LfSetVolumeMax
			dc.l	LfNext
			dc.l	LfNext
			dc.l	LfSetSpinMax
			dc.l	LfSetRotateMax

			dc.l	LfSetVolumeMin
			dc.l	LfNext
			dc.l	LfNext
			dc.l	LfSetSpinMin
			dc.l	LfSetRotateMin

			dc.l	LfSetVolumeUp
			dc.l	LfNext
			dc.l	LfNext
			dc.l	LfSetSpinAntiClock
			dc.l	LfSetRotateAntiClock

			dc.l	LfSetVolumeDown
			dc.l	LfNext
			dc.l	LfNext
			dc.l	LfSetSpinClockwise
			dc.l	LfSetRotateClockwise

			dc.l	LfSetVolumeScan
			dc.l	LfNext
			dc.l	LfNext
			dc.l	LfSetSpinRock
			dc.l	LfSetRotateRock

LfSetVolume:		move.l	Value,d0
			cmpi.l	#64,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSetFreq:		move.l	Value,d0
			cmpi.l	#1,d0
			blo.l	Error2
			cmpi.l	#$ffff,d0
			bhi.l	Error2

			tst.b	ChannelNumber
			bne	LfNext

			sub.l	d1,d1
			move.b	Value2,d1
			mulu	#10,d0
			add.w	d1,d0

			moveq	#9,d1			;Freq cmd
			bsr	AddLfCmd
			move.l	DefTrack,d1
			move.w	d1,6(a1)		;Track
			move.w	d0,8(a1)		;Freq
			moveq	#10,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			bra	LfNext

LfSetSpin:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotate:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#4,d1			;Rotate XY cmd
			moveq	#-1,d3			;Flags
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetVolumeMax:		move.l	Value,d6
			beq.l	Error2
			cmpi.l	#64,d6
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Size
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSetSpinMax:		move.l	Value,d6
			beq.l	Error2
			cmpi.l	#360,d6
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotateMax:		move.l	Value,d6
			beq.l	Error2
			cmpi.l	#360,d6
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#4,d1			;Rotate XY cmd
			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetVolumeMin:		move.l	Value,d7
			cmpi.l	#63,d7
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Size X
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			bsr	AddLfLCCmd
			bra	LfNext

LfSetSpinMin:		move.l	Value,d7
			cmpi.l	#358,d7
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotateMin:		move.l	Value,d7
			cmpi.l	#358,d7
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#4,d1			;Rotate XY cmd
			moveq	#-1,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetVolumeUp:		move.l	Value,d0
			beq	LfVolOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#64,d2
			bsr	LfCalcRate

			moveq	#1,d3			;Flags
			moveq	#-1,d0			;Size X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSetSpinAntiClock:	move.l	Value,d0
			beq	LfSpinOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#1,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotateAntiClock:	move.l	Value,d0
			beq	LfRotateOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#4,d1			;Rotate XY cmd
			moveq	#1,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetVolumeDown:	move.l	Value,d0
			beq	LfVolOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#64,d2
			bsr	LfCalcRate

			moveq	#2,d3			;Flags
			moveq	#-1,d0			;Size X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSetSpinClockwise:	move.l	Value,d0
			beq	LfSpinOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#2,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotateClockwise:	move.l	Value,d0
			beq	LfRotateOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#4,d1			;Rotate XY cmd
			moveq	#2,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetVolumeScan:	move.l	Value,d0
			beq	LfVolOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			moveq	#64,d2
			bsr	LfCalcRate

			moveq	#5,d3			;Flags
			moveq	#-1,d0			;Size X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSetSpinRock:		move.l	Value,d0
			beq	LfSpinOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#5,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfSetRotateRock:	move.l	Value,d0
			beq	LfRotateOff
			cmpi.l	#3000,d0
			bhi.l	Error2

			tst.b	Value2
			bne.l	Error2

			move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			move.l	#359,d2
			bsr	LfCalcRate

			moveq	#4,d1			;Rotate XY cmd
			moveq	#5,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfVolOff:		move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#2,d1			;Size X cmd
			add.b	d2,d1

			sub.l	d3,d3			;Flags
			moveq	#-1,d0			;Size X
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd
			bra	LfNext

LfSpinOff:		move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#5,d1			;Spin X cmd
			add.b	d2,d1

			sub.l	d3,d3			;Flags
			moveq	#-1,d0			;Spin X
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfRotateOff:		move.b	ChannelNumber,d2
			cmpi.b	#1,d2
			bhi	LfNext

			moveq	#4,d1			;Rotate XY cmd
			sub.l	d3,d3			;Flags
			moveq	#-1,d0			;Rotate XY
			moveq	#-1,d4			;Step
			moveq	#-1,d5			;Count
			moveq	#-1,d6			;Max
			moveq	#-1,d7			;Min
			bsr	AddLfLCCmd2
			bra	LfNext

LfCalcRate:		cmpi.l	#20,d0			;Old way
			blo.s	.Skip
			subi.l	#19,d0
			move.l	d0,d5
			moveq	#1,d4
			rts

.Skip:			moveq	#21,d4
			sub.l	d0,d4
			moveq	#1,d5
			rts

LfCalcRate2:		sub.l	d5,d5			;d4-step, d5-count
							;d0-time, d2-max
.Loop:			move.l	d2,d4			;New way!
			addq.l	#1,d5
			mulu.w	d5,d4
			divu.l	d0,d4
			beq.s	.Loop
			rts

LfFactory:		move.b	(a0)+,d0
			beq.s	.Skip
			cmpi.b	#" ",d0
			bne.l	Error

.StripSpaces:		move.b	(a0),d0
			beq.s	.Skip
			cmpi.b	#" ",d0
			bne.s	.Next

			addq.l	#1,a0
			bra.s	.StripSpaces

.Next:			move.l	a0,NextCmdPtr

.Skip:			move.l	DefTrack,d0
			bsr.s	LfFactoryIt
			bra	LfNext

LfFactoryIt:		moveq	#27,d1			;factory cmd
			bsr	AddLfCmd
			move.w	d0,6(a1)		;Track

			sub.l	d0,d0
			tst.b	InvertXFlag
			beq.s	.ISkip
			moveq	#1,d0

.ISkip:			tst.b	InvertYFlag
			beq.s	.ISkip2
			addq.l	#2,d0

.ISkip2:		move.w	d0,8(a1)		;Flags

			moveq	#10,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen
			rts

SendLASERfIRESeq:	movea.l	LASERfIREMemPtr,a0	;Calc checksum
			move.l	LASERfIRESeqLen,d0
			move.l	d0,d1
			addq.l	#8,d0
			move.l	d0,LASERfIREHeader

			sub.l	d0,d0
			sub.l	d2,d2

.Loop:			move.b	(a0)+,d2		;Note: large blocks
			add.l	d2,d0
			subq.l	#1,d1
			bne.s	.Loop

			move.l	d0,LASERfIREHeader+4	;CRC

			lea	LASERfIREHeader,a0
			moveq	#8,d0
			bsr	Echo2

			movea.l	LASERfIREMemPtr,a0
			move.l	LASERfIRESeqLen,d1
			bsr.s	DnldLASERfIRE
.End:			rts

DnldLASERfIRE:		moveq	#8,d2

.Loop:			move.l	a0,-(sp)
			move.l	d1,-(sp)
			move.l	d2,-(sp)
			bsr.s	PrintDnLASERfIRE
			move.l	(sp)+,d2
			move.l	(sp)+,d1
			movea.l	(sp)+,a0

			cmpi.l	#2048,d1
			bhi.s	.Block

			move.l	d1,d0
			add.l	d0,d2
			move.l	d2,-(sp)
			bsr	Echo2
			move.l	(sp)+,d2

			bsr.s	PrintDnLASERfIRE
			rts

.Block:			move.l	#2048,d0
			sub.l	d0,d1
			add.l	d0,d2
			move.l	a0,-(sp)
			move.l	d1,-(sp)
			move.l	d2,-(sp)
			bsr	Echo2
			move.l	(sp)+,d2
			move.l	(sp)+,d1
			movea.l	(sp)+,a0
			adda.w	#2048,a0
			bra.s	.Loop

PrintDnLASERfIRE:	lea	StatusLASERfIRE,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			lea	-1(a1),a0
			move.l	d2,-(sp)
			move.l	d2,d0
			move.l	LASERfIREHeader,d1
			mulu.l	#100,d0
			divu.l	d1,d0
			bsr	HEXtoASCII
			move.b	#"%",(a1)+
			move.b	#" ",(a1)+
			move.b	#"(",(a1)+
			movea.l	a1,a0
			move.l	(sp)+,d0
			bsr	HEXtoASCII
			move.b	#"/",(a1)+
			movea.l	a1,a0
			move.l	LASERfIREHeader,d0
			bsr	HEXtoASCII
			move.b	#")",(a1)+
			clr.b	(a1)
			lea	ASCIIBuffer,a0
			bsr	PrintStatus2
			rts

GetLASERfIREMem:	tst.l	LASERfIREMemPtr		;Get Seq Mem
			bne.s	.End

			sub.l	d1,d1
			move.l	#MaxSeqSize+(3*MaxPoints)+80,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,LASERfIREMemPtr
.End:			rts

FreeLASERfIREMem:	move.l	LASERfIREMemPtr,d0
			beq.s	.End

			movea.l	d0,a1
			move.l	#MaxSeqSize+(3*MaxPoints)+80,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	LASERfIREMemPtr
.End:			rts


;Handlers:

AD0Handler:		move.w	#$80,$9c(a0)		;Reset bit 7
			movea.l	(a1),a5
			move.w	(a5)+,$aa(a0)
			move.l	a5,(a1)

			cmpa.l	End0Ptr,a5
			blo.s	.End
			move.l	Loc0Ptr,(a1)

			tst.b	AD0Update2
			beq.s	.End
			bsr	Setup0
.End:			rts

AD0HandlerDMA:		move.w	#$80,$9c(a0)		;Reset bit 7
			tst.b	(a1)
			beq.s	.End
			bsr	Setup0DMA
.End:			rts

AD1Handler:		move.w	#$0100,$9c(a0)		;Reset bit 8
			movea.l	(a1),a5
			move.w	(a5)+,$ba(a0)
			move.l	a5,(a1)

			cmpa.l	End1Ptr,a5
			blo.s	.End
			move.l	Loc1Ptr,(a1)

			tst.b	AD1Update2
			beq.s	.End
			bsr	Setup1
.End:			rts

AD1HandlerDMA:		move.w	#$0100,$9c(a0)		;Reset bit 8
			tst.b	(a1)
			beq.s	.End
			bsr	Setup1DMA
.End:			rts

AD2Handler:		move.w	#$0200,$9c(a0)		;Reset bit 9
			movea.l	(a1),a5
			move.w	(a5)+,$ca(a0)
			move.l	a5,(a1)

			cmpa.l	End2Ptr,a5
			blo.s	.End
			move.l	Loc2Ptr,(a1)

			tst.b	AD2Update2
			beq.s	.End
			bsr	Setup2
.End:			rts

AD2HandlerDMA:		move.w	#$0200,$9c(a0)		;Reset bit 9
			tst.b	(a1)
			beq.s	.End
			bsr	Setup2DMA
.End:			rts

AD3Handler:		move.w	#$0400,$9c(a0)		;Reset bit 10
			movea.l	(a1),a5
			move.w	(a5)+,$da(a0)
			move.l	a5,(a1)

			cmpa.l	End3Ptr,a5
			blo.s	.End
			move.l	Loc3Ptr,(a1)

			tst.b	AD3Update2
			beq.s	.End
			bsr	Setup3
.End:			rts

AD3HandlerDMA:		move.w	#$0400,$9c(a0)		;Reset bit 10
			tst.b	(a1)
			beq.s	.End
			bsr	Setup3DMA
.End:			rts

VBServ:			subq.l	#1,WaitCount
			addq.l	#1,SequenceCountTrigTemp
			subq.l	#1,FastMoveWait
			addq.l	#1,DrawCountTemp
			addq.l	#1,MorphCountTemp
			addq.l	#1,AutoStopCount
			subq.l	#1,StatusCount
			addq.w	#1,MoveCount
			addq.b	#1,AutoGadCount
			addq.b	#1,JoyCount
			addq.b	#1,ClockCount
			addq.b	#1,StrobeCount
			addq.b	#1,TextCount
			addq.b	#1,SerialCount
			addq.b	#1,MiscCount
			addq.b	#1,MiscCount2
			addq.b	#1,MiscCount3
			addq.b	#1,MagCount
			addq.b	#1,XHairsCount

			tst.b	DrawingFlag
			beq.s	.Skip11

			move.l	DrawCount,d0
			cmp.l	DrawCountTemp,d0
			bhi.s	.Skip11

			clr.l	DrawCountTemp

			move.l	DrawRate,d0
			add.l	d0,DrawingLen
			move.l	#$01010101,AD0Update

			move.l	Len0,d0
			cmp.l	DrawingLen,d0
			bhi.s	.Skip11

			clr.b	DrawingFlag

.Skip11:		tst.b	MorphFlag
			beq.s	.Skip12

			move.l	MorphCount,d0
			cmp.l	MorphCountTemp,d0
			bhi.s	.Skip12

			clr.l	MorphCountTemp

			move.l	MorphSteps,d0
			add.l	d0,MorphStepsTemp
			move.l	#$01010101,AD0Update

			move.l	MorphStepsTemp,d0
			cmpi.l	#32767,d0
			blo.s	.Skip12

			clr.b	MorphFlag
;			jsr	FreeMorphMem

.Skip12:		move.w	AD0Funct,d0		;** Channel 0 **
			beq	.Chan1

			btst	#0,d0			;Down volume?
			beq.s	.UpVolume0

			subq.l	#1,VBCountV0Temp
			bne	.Freq0

			move.l	VBCountV0,VBCountV0Temp

			move.w	Vol0Min,d1
			add.w	VBRateV0+2,d1
			cmp.w	Vol0,d1
			bls.s	.DV0

			btst	#2,d0			;Change direction?
			beq.s	.DVAgain0

			bclr	#0,AD0Funct+1
			bset	#1,AD0Funct+1
			bra	.Freq0

.DVAgain0:		move.w	Vol0Max,Vol0
			move.b	#1,AD0Update
			bra	.Freq0

.DV0:			move.w	VBRateV0+2,d1
			sub.w	d1,Vol0
			move.b	#1,AD0Update
			bra.s	.Freq0

.UpVolume0:		btst	#1,d0
			beq.s	.Freq0

			subq.l	#1,VBCountV0Temp
			bne.s	.Freq0

			move.l	VBCountV0,VBCountV0Temp

			move.w	Vol0Max,d1
			sub.w	VBRateV0+2,d1
			cmp.w	Vol0,d1
			bhs.s	.UV0

			btst	#2,d0			;Change direction?
			beq.s	.UVAgain0

			bclr	#1,AD0Funct+1
			bset	#0,AD0Funct+1
			bra.s	.Freq0

.UVAgain0:		move.w	Vol0Min,Vol0
			move.b	#1,AD0Update
			bra.s	.Freq0

.UV0:			move.w	VBRateV0+2,d1
			add.w	d1,Vol0
			move.b	#1,AD0Update

.Freq0:			btst	#3,d0			;Down freq?
			beq.s	.UpFreq0

			subq.l	#1,VBCountF0Temp
			bne	.Spin0

			move.l	VBCountF0,VBCountF0Temp

			move.w	Freq0Min,d1
			add.w	VBRateF0+2,d1
			cmp.w	Freq0,d1
			bls.s	.DF0

			btst	#5,d0			;Change direction?
			beq.s	.DFAgain0

			bclr	#3,AD0Funct+1
			bset	#4,AD0Funct+1
			bra	.Spin0

.DFAgain0:		move.w	Freq0Max,Freq0
			move.b	#1,AD0Update
			bra	.Spin0

.DF0:			move.w	VBRateF0+2,d1
			sub.w	d1,Freq0
			move.b	#1,AD0Update
			bra.s	.Spin0

.UpFreq0:		btst	#4,d0
			beq.s	.Spin0

			subq.l	#1,VBCountF0Temp
			bne.s	.Spin0

			move.l	VBCountF0,VBCountF0Temp

			move.w	Freq0Max,d1
			sub.w	VBRateF0+2,d1
			cmp.w	Freq0,d1
			bhs.s	.UF0

			btst	#5,d0			;Change direction?
			beq.s	.UFAgain0

			bclr	#4,AD0Funct+1
			bset	#3,AD0Funct+1
			bra.s	.Spin0

.UFAgain0:		move.w	Freq0Min,Freq0
			move.b	#1,AD0Update
			bra.s	.Spin0

.UF0:			move.w	VBRateF0+2,d1
			add.w	d1,Freq0
			move.b	#1,AD0Update

.Spin0:			btst	#9,d0			;Down Spin?
			beq.s	.UpSpin0

			subq.l	#1,VBCountS0Temp
			bne	.Chan1

			move.l	VBCountS0,VBCountS0Temp

			move.w	Spin0Min,d1
			add.w	VBRateS0+2,d1
			cmp.w	Spin0,d1
			bls.s	.DS0

			btst	#11,d0			;Change direction?
			beq.s	.DSAgain0

			bclr	#1,AD0Funct
			bset	#2,AD0Funct
			bra	.Chan1

.DSAgain0:		move.w	Spin0Max,Spin0
			move.b	#1,AD0Update
			bra	.Chan1

.DS0:			move.w	VBRateS0+2,d1
			sub.w	d1,Spin0
			move.b	#1,AD0Update
			bra.s	.Chan1

.UpSpin0:		btst	#10,d0
			beq.s	.Chan1

			subq.l	#1,VBCountS0Temp
			bne.s	.Chan1

			move.l	VBCountS0,VBCountS0Temp

			move.w	Spin0Max,d1
			sub.w	VBRateS0+2,d1
			cmp.w	Spin0,d1
			bhs.s	.US0

			btst	#11,d0			;Change direction?
			beq.s	.USAgain0

			bclr	#2,AD0Funct
			bset	#1,AD0Funct
			bra.s	.Chan1

.USAgain0:		move.w	Spin0Min,Spin0
			move.b	#1,AD0Update
			bra.s	.Chan1

.US0:			move.w	VBRateS0+2,d1
			add.w	d1,Spin0
			move.b	#1,AD0Update

.Chan1:			move.w	AD1Funct,d0		;** Channel 1 **
			beq	.Chan2

			btst	#0,d0			;Down volume?
			beq.s	.UpVolume1

			subq.l	#1,VBCountV1Temp
			bne	.Freq1

			move.l	VBCountV1,VBCountV1Temp

			move.w	Vol1Min,d1
			add.w	VBRateV1+2,d1
			cmp.w	Vol1,d1
			bls.s	.DV1

			btst	#2,d0			;Change direction?
			beq.s	.DVAgain1

			bclr	#0,AD1Funct+1
			bset	#1,AD1Funct+1
			bra	.Freq1

.DVAgain1:		move.w	Vol1Max,Vol1
			move.b	#1,AD1Update
			bra	.Freq1

.DV1:			move.w	VBRateV1+2,d1
			sub.w	d1,Vol1
			move.b	#1,AD1Update
			bra.s	.Freq1

.UpVolume1:		btst	#1,d0
			beq.s	.Freq1

			subq.l	#1,VBCountV1Temp
			bne.s	.Freq1

			move.l	VBCountV1,VBCountV1Temp

			move.w	Vol1Max,d1
			sub.w	VBRateV1+2,d1
			cmp.w	Vol1,d1
			bhs.s	.UV1

			btst	#2,d0			;Change direction?
			beq.s	.UVAgain1

			bclr	#1,AD1Funct+1
			bset	#0,AD1Funct+1
			bra.s	.Freq1

.UVAgain1:		move.w	Vol1Min,Vol1
			move.b	#1,AD1Update
			bra.s	.Freq1

.UV1:			move.w	VBRateV1+2,d1
			add.w	d1,Vol1
			move.b	#1,AD1Update

.Freq1:			btst	#3,d0			;Down freq?
			beq.s	.UpFreq1

			subq.l	#1,VBCountF1Temp
			bne	.Phase1

			move.l	VBCountF1,VBCountF1Temp

			move.w	Freq1Min,d1
			add.w	VBRateF1+2,d1
			cmp.w	Freq1,d1
			bls.s	.DF1

			btst	#5,d0			;Change direction?
			beq.s	.DFAgain1

			bclr	#3,AD1Funct+1
			bset	#4,AD1Funct+1
			bra	.Phase1

.DFAgain1:		move.w	Freq1Max,Freq1
			move.b	#1,AD1Update
			bra	.Phase1

.DF1:			move.w	VBRateF1+2,d1
			sub.w	d1,Freq1
			move.b	#1,AD1Update
			bra.s	.Phase1

.UpFreq1:		btst	#4,d0
			beq.s	.Phase1

			subq.l	#1,VBCountF1Temp
			bne.s	.Phase1

			move.l	VBCountF1,VBCountF1Temp

			move.w	Freq1Max,d1
			sub.w	VBRateF1+2,d1
			cmp.w	Freq1,d1
			bhs.s	.UF1

			btst	#5,d0			;Change direction?
			beq.s	.UFAgain1

			bclr	#4,AD1Funct+1
			bset	#3,AD1Funct+1
			bra.s	.Phase1

.UFAgain1:		move.w	Freq1Min,Freq1
			move.b	#1,AD1Update
			bra.s	.Phase1

.UF1:			move.w	VBRateF1+2,d1
			add.w	d1,Freq1
			move.b	#1,AD1Update

.Phase1:		btst	#6,d0			;Down phase?
			beq.s	.UpPhase1

			subq.l	#1,VBCountP1Temp
			bne	.Spin1

			move.l	VBCountP1,VBCountP1Temp

			move.w	Phase1Min,d1
			add.w	VBRateP1+2,d1
			cmp.w	Phase1,d1
			bls.s	.DP1

			btst	#8,d0			;Change direction?
			beq.s	.DPAgain1

			bclr	#6,AD1Funct+1
			bset	#7,AD1Funct+1
			bra	.Spin1

.DPAgain1:		move.w	Phase1Max,Phase1
			move.b	#1,AD1Update
			bra	.Spin1

.DP1:			move.w	VBRateP1+2,d1
			sub.w	d1,Phase1
			move.b	#1,AD1Update
			bra.s	.Spin1

.UpPhase1:		btst	#7,d0
			beq.s	.Spin1

			subq.l	#1,VBCountP1Temp
			bne.s	.Spin1

			move.l	VBCountP1,VBCountP1Temp

			move.w	Phase1Max,d1
			sub.w	VBRateP1+2,d1
			cmp.w	Phase1,d1
			bhs.s	.UP1

			btst	#8,d0			;Change direction?
			beq.s	.UPAgain1

			bclr	#7,AD1Funct+1
			bset	#6,AD1Funct+1
			bra.s	.Spin1

.UPAgain1:		move.w	Phase1Min,Phase1
			move.b	#1,AD1Update
			bra.s	.Spin1

.UP1:			move.w	VBRateP1+2,d1
			add.w	d1,Phase1
			move.b	#1,AD1Update

.Spin1:			btst	#9,d0			;Down Spin?
			beq.s	.UpSpin1

			subq.l	#1,VBCountS1Temp
			bne	.Chan2

			move.l	VBCountS1,VBCountS1Temp

			move.w	Spin1Min,d1
			add.w	VBRateS1+2,d1
			cmp.w	Spin1,d1
			bls.s	.DS1

			btst	#11,d0			;Change direction?
			beq.s	.DSAgain1

			bclr	#1,AD1Funct
			bset	#2,AD1Funct
			bra	.Chan2

.DSAgain1:		move.w	Spin1Max,Spin1
			move.b	#1,AD1Update
			bra	.Chan2

.DS1:			move.w	VBRateS1+2,d1
			sub.w	d1,Spin1
			move.b	#1,AD1Update
			bra.s	.Chan2

.UpSpin1:		btst	#10,d0
			beq.s	.Chan2

			subq.l	#1,VBCountS1Temp
			bne.s	.Chan2

			move.l	VBCountS1,VBCountS1Temp

			move.w	Spin1Max,d1
			sub.w	VBRateS1+2,d1
			cmp.w	Spin1,d1
			bhs.s	.US1

			btst	#11,d0			;Change direction?
			beq.s	.USAgain1

			bclr	#2,AD1Funct
			bset	#1,AD1Funct
			bra.s	.Chan2

.USAgain1:		move.w	Spin1Min,Spin1
			move.b	#1,AD1Update
			bra.s	.Chan2

.US1:			move.w	VBRateS1+2,d1
			add.w	d1,Spin1
			move.b	#1,AD1Update

.Chan2:			move.w	AD2Funct,d0		;** Channel 2 **
			beq	.Chan3

			btst	#0,d0			;Down volume?
			beq.s	.UpVolume2

			subq.l	#1,VBCountV2Temp
			bne	.Freq2

			move.l	VBCountV2,VBCountV2Temp

			move.w	Vol2Min,d1
			add.w	VBRateV2+2,d1
			cmp.w	Vol2,d1
			bls.s	.DV2

			btst	#2,d0			;Change direction?
			beq.s	.DVAgain2

			bclr	#0,AD2Funct+1
			bset	#1,AD2Funct+1
			bra	.Freq2

.DVAgain2:		move.w	Vol2Max,Vol2
			move.b	#1,AD2Update
			bra	.Freq2

.DV2:			move.w	VBRateV2+2,d1
			sub.w	d1,Vol2
			move.b	#1,AD2Update
			bra.s	.Freq2

.UpVolume2:		btst	#1,d0
			beq.s	.Freq2

			subq.l	#1,VBCountV2Temp
			bne.s	.Freq2

			move.l	VBCountV2,VBCountV2Temp

			move.w	Vol2Max,d1
			sub.w	VBRateV2+2,d1
			cmp.w	Vol2,d1
			bhs.s	.UV2

			btst	#2,d0			;Change direction?
			beq.s	.UVAgain2

			bclr	#1,AD2Funct+1
			bset	#0,AD2Funct+1
			bra.s	.Freq2

.UVAgain2:		move.w	Vol2Min,Vol2
			move.b	#1,AD2Update
			bra.s	.Freq2

.UV2:			move.w	VBRateV2+2,d1
			add.w	d1,Vol2
			move.b	#1,AD2Update

.Freq2:			btst	#3,d0			;Down freq?
			beq.s	.UpFreq2

			subq.l	#1,VBCountF2Temp
			bne	.Phase2

			move.l	VBCountF2,VBCountF2Temp

			move.w	Freq2Min,d1
			add.w	VBRateF2+2,d1
			cmp.w	Freq2,d1
			bls.s	.DF2

			btst	#5,d0			;Change direction?
			beq.s	.DFAgain2

			bclr	#3,AD2Funct+1
			bset	#4,AD2Funct+1
			bra	.Phase2

.DFAgain2:		move.w	Freq2Max,Freq2
			move.b	#1,AD2Update
			bra	.Phase2

.DF2:			move.w	VBRateF2+2,d1
			sub.w	d1,Freq2
			move.b	#1,AD2Update
			bra.s	.Phase2

.UpFreq2:		btst	#4,d0
			beq.s	.Phase2

			subq.l	#1,VBCountF2Temp
			bne.s	.Phase2

			move.l	VBCountF2,VBCountF2Temp

			move.w	Freq2Max,d1
			sub.w	VBRateF2+2,d1
			cmp.w	Freq2,d1
			bhs.s	.UF2

			btst	#5,d0			;Change direction?
			beq.s	.UFAgain2

			bclr	#4,AD2Funct+1
			bset	#3,AD2Funct+1
			bra.s	.Phase2

.UFAgain2:		move.w	Freq2Min,Freq2
			move.b	#1,AD2Update
			bra.s	.Phase2

.UF2:			move.w	VBRateF2+2,d1
			add.w	d1,Freq2
			move.b	#1,AD2Update

.Phase2:		btst	#6,d0			;Down phase?
			beq.s	.UpPhase2

			subq.l	#1,VBCountP2Temp
			bne	.Spin2

			move.l	VBCountP2,VBCountP2Temp

			move.w	Phase2Min,d1
			add.w	VBRateP2+2,d1
			cmp.w	Phase2,d1
			bls.s	.DP2

			btst	#8,d0			;Change direction?
			beq.s	.DPAgain2

			bclr	#6,AD2Funct+1
			bset	#7,AD2Funct+1
			bra	.Spin2

.DPAgain2:		move.w	Phase2Max,Phase2
			move.b	#1,AD2Update
			bra	.Spin2

.DP2:			move.w	VBRateP2+2,d1
			sub.w	d1,Phase2
			move.b	#1,AD2Update
			bra.s	.Spin2

.UpPhase2:		btst	#7,d0
			beq.s	.Spin2

			subq.l	#1,VBCountP2Temp
			bne.s	.Spin2

			move.l	VBCountP2,VBCountP2Temp

			move.w	Phase2Max,d1
			sub.w	VBRateP2+2,d1
			cmp.w	Phase2,d1
			bhs.s	.UP2

			btst	#8,d0			;Change direction?
			beq.s	.UPAgain2

			bclr	#7,AD2Funct+1
			bset	#6,AD2Funct+1
			bra.s	.Spin2

.UPAgain2:		move.w	Phase2Min,Phase2
			move.b	#1,AD2Update
			bra.s	.Spin2

.UP2:			move.w	VBRateP2+2,d1
			add.w	d1,Phase2
			move.b	#1,AD2Update

.Spin2:			btst	#9,d0			;Down Spin?
			beq.s	.UpSpin2

			subq.l	#1,VBCountS2Temp
			bne	.Chan3

			move.l	VBCountS2,VBCountS2Temp

			move.w	Spin2Min,d1
			add.w	VBRateS2+2,d1
			cmp.w	Spin2,d1
			bls.s	.DS2

			btst	#11,d0			;Change direction?
			beq.s	.DSAgain2

			bclr	#1,AD2Funct
			bset	#2,AD2Funct
			bra	.Chan3

.DSAgain2:		move.w	Spin2Max,Spin2
			move.b	#1,AD2Update
			bra	.Chan3

.DS2:			move.w	VBRateS2+2,d1
			sub.w	d1,Spin2
			move.b	#1,AD2Update
			bra.s	.Chan3

.UpSpin2:		btst	#10,d0
			beq.s	.Chan3

			subq.l	#1,VBCountS2Temp
			bne.s	.Chan3

			move.l	VBCountS2,VBCountS2Temp

			move.w	Spin2Max,d1
			sub.w	VBRateS2+2,d1
			cmp.w	Spin2,d1
			bhs.s	.US2

			btst	#11,d0			;Change direction?
			beq.s	.USAgain2

			bclr	#2,AD2Funct
			bset	#1,AD2Funct
			bra.s	.Chan3

.USAgain2:		move.w	Spin2Min,Spin2
			move.b	#1,AD2Update
			bra.s	.Chan3

.US2:			move.w	VBRateS2+2,d1
			add.w	d1,Spin2
			move.b	#1,AD2Update

.Chan3:			move.w	AD3Funct,d0		;** Channel 3 **
			beq	.Rotate

			btst	#0,d0			;Down volume?
			beq.s	.UpVolume3

			subq.l	#1,VBCountV3Temp
			bne	.Freq3

			move.l	VBCountV3,VBCountV3Temp

			move.w	Vol3Min,d1
			add.w	VBRateV3+2,d1
			cmp.w	Vol3,d1
			bls.s	.DV3

			btst	#2,d0			;Change direction?
			beq.s	.DVAgain3

			bclr	#0,AD3Funct+1
			bset	#1,AD3Funct+1
			bra	.Freq3

.DVAgain3:		move.w	Vol3Max,Vol3
			move.b	#1,AD3Update
			bra	.Freq3

.DV3:			move.w	VBRateV3+2,d1
			sub.w	d1,Vol3
			move.b	#1,AD3Update
			bra.s	.Freq3

.UpVolume3:		btst	#1,d0
			beq.s	.Freq3

			subq.l	#1,VBCountV3Temp
			bne.s	.Freq3

			move.l	VBCountV3,VBCountV3Temp

			move.w	Vol3Max,d1
			sub.w	VBRateV3+2,d1
			cmp.w	Vol3,d1
			bhs.s	.UV3

			btst	#2,d0			;Change direction?
			beq.s	.UVAgain3

			bclr	#1,AD3Funct+1
			bset	#0,AD3Funct+1
			bra.s	.Freq3

.UVAgain3:		move.w	Vol3Min,Vol3
			move.b	#1,AD3Update
			bra.s	.Freq3

.UV3:			move.w	VBRateV3+2,d1
			add.w	d1,Vol3
			move.b	#1,AD3Update

.Freq3:			btst	#3,d0			;Down freq?
			beq.s	.UpFreq3

			subq.l	#1,VBCountF3Temp
			bne	.Phase3

			move.l	VBCountF3,VBCountF3Temp

			move.w	Freq3Min,d1
			add.w	VBRateF3+2,d1
			cmp.w	Freq3,d1
			bls.s	.DF3

			btst	#5,d0			;Change direction?
			beq.s	.DFAgain3

			bclr	#3,AD3Funct+1
			bset	#4,AD3Funct+1
			bra	.Phase3

.DFAgain3:		move.w	Freq3Max,Freq3
			move.b	#1,AD3Update
			bra	.Phase3

.DF3:			move.w	VBRateF3+2,d1
			sub.w	d1,Freq3
			move.b	#1,AD3Update
			bra.s	.Phase3

.UpFreq3:		btst	#4,d0
			beq.s	.Phase3

			subq.l	#1,VBCountF3Temp
			bne.s	.Phase3

			move.l	VBCountF3,VBCountF3Temp

			move.w	Freq3Max,d1
			sub.w	VBRateF3+2,d1
			cmp.w	Freq3,d1
			bhs.s	.UF3

			btst	#5,d0			;Change direction?
			beq.s	.UFAgain3

			bclr	#4,AD3Funct+1
			bset	#3,AD3Funct+1
			bra.s	.Phase3

.UFAgain3:		move.w	Freq3Min,Freq3
			move.b	#1,AD3Update
			bra.s	.Phase3

.UF3:			move.w	VBRateF3+2,d1
			add.w	d1,Freq3
			move.b	#1,AD3Update

.Phase3:		btst	#6,d0			;Down phase?
			beq.s	.UpPhase3

			subq.l	#1,VBCountP3Temp
			bne	.Spin3

			move.l	VBCountP3,VBCountP3Temp

			move.w	Phase3Min,d1
			add.w	VBRateP3+2,d1
			cmp.w	Phase3,d1
			bls.s	.DP3

			btst	#8,d0			;Change direction?
			beq.s	.DPAgain3

			bclr	#6,AD3Funct+1
			bset	#7,AD3Funct+1
			bra	.Spin3

.DPAgain3:		move.w	Phase3Max,Phase3
			move.b	#1,AD3Update
			bra	.Spin3

.DP3:			move.w	VBRateP3+2,d1
			sub.w	d1,Phase3
			move.b	#1,AD3Update
			bra.s	.Spin3

.UpPhase3:		btst	#7,d0
			beq.s	.Spin3

			subq.l	#1,VBCountP3Temp
			bne.s	.Spin3

			move.l	VBCountP3,VBCountP3Temp

			move.w	Phase3Max,d1
			sub.w	VBRateP3+2,d1
			cmp.w	Phase3,d1
			bhs.s	.UP3

			btst	#8,d0			;Change direction?
			beq.s	.UPAgain3

			bclr	#7,AD3Funct+1
			bset	#6,AD3Funct+1
			bra.s	.Spin3

.UPAgain3:		move.w	Phase3Min,Phase3
			move.b	#1,AD3Update
			bra.s	.Spin3

.UP3:			move.w	VBRateP3+2,d1
			add.w	d1,Phase3
			move.b	#1,AD3Update

.Spin3:			btst	#9,d0			;Down Spin?
			beq.s	.UpSpin3

			subq.l	#1,VBCountS3Temp
			bne	.Rotate

			move.l	VBCountS3,VBCountS3Temp

			move.w	Spin3Min,d1
			add.w	VBRateS3+2,d1
			cmp.w	Spin3,d1
			bls.s	.DS3

			btst	#11,d0			;Change direction?
			beq.s	.DSAgain3

			bclr	#1,AD3Funct
			bset	#2,AD3Funct
			bra	.Rotate

.DSAgain3:		move.w	Spin3Max,Spin3
			move.b	#1,AD3Update
			bra	.Rotate

.DS3:			move.w	VBRateS3+2,d1
			sub.w	d1,Spin3
			move.b	#1,AD3Update
			bra.s	.Rotate

.UpSpin3:		btst	#10,d0
			beq.s	.Rotate

			subq.l	#1,VBCountS3Temp
			bne.s	.Rotate

			move.l	VBCountS3,VBCountS3Temp

			move.w	Spin3Max,d1
			sub.w	VBRateS3+2,d1
			cmp.w	Spin3,d1
			bhs.s	.US3

			btst	#11,d0			;Change direction?
			beq.s	.USAgain3

			bclr	#2,AD3Funct
			bset	#1,AD3Funct
			bra.s	.Rotate

.USAgain3:		move.w	Spin3Min,Spin3
			move.b	#1,AD3Update
			bra.s	.Rotate

.US3:			move.w	VBRateS3+2,d1
			add.w	d1,Spin3
			move.b	#1,AD3Update

.Rotate:		tst.b	RotateFlag		;** Rotate **
			beq	.End

			btst	#0,RotateFlag		;Clockwise?
			beq.s	.AntiClockwise

			subq.l	#1,VBCountRot01Temp
			bne	.Rotate2

			move.l	VBCountRot01,VBCountRot01Temp

			move.w	RotateAngleMin01,d1
			add.w	VBRateRot01+2,d1
			cmp.w	RotateAngle01,d1
			bls.s	.Rot01

			btst	#2,RotateFlag		;Change direction?
			beq.s	.RotAgain01

			bclr	#0,RotateFlag
			bset	#1,RotateFlag
			bra	.Rotate2

.RotAgain01:		move.w	RotateAngleMax01,RotateAngle01
			move.w	#$0101,AD0Update
			bra	.Rotate2

.Rot01:			move.w	VBRateRot01+2,d1
			sub.w	d1,RotateAngle01
			move.w	#$0101,AD0Update
			bra.s	.Rotate2

.AntiClockwise:		btst	#1,RotateFlag		;AntiClockwise?
			beq.s	.Rotate2

			subq.l	#1,VBCountRot01Temp
			bne.s	.Rotate2

			move.l	VBCountRot01,VBCountRot01Temp

			move.w	RotateAngleMax01,d1
			sub.w	VBRateRot01+2,d1
			cmp.w	RotateAngle01,d1
			bhs.s	.Rot012

			btst	#2,RotateFlag		;Change direction?
			beq.s	.RotAgain012

			bclr	#1,RotateFlag
			bset	#0,RotateFlag
			bra.s	.Rotate2

.RotAgain012:		move.w	RotateAngleMin01,RotateAngle01
			move.w	#$0101,AD0Update
			bra.s	.Rotate2

.Rot012:		move.w	VBRateRot01+2,d1
			add.w	d1,RotateAngle01
			move.w	#$0101,AD0Update

.Rotate2:		btst	#3,RotateFlag		;Clockwise?
			beq.s	.AntiClockwise2

			subq.l	#1,VBCountRot23Temp
			bne	.End

			move.l	VBCountRot23,VBCountRot23Temp

			move.w	RotateAngleMin23,d1
			add.w	VBRateRot23+2,d1
			cmp.w	RotateAngle23,d1
			bls.s	.Rot23

			btst	#5,RotateFlag		;Change direction?
			beq.s	.RotAgain23

			bclr	#3,RotateFlag
			bset	#4,RotateFlag
			bra	.End

.RotAgain23:		move.w	RotateAngleMax23,RotateAngle23
			move.w	#$0101,AD2Update
			bra	.End

.Rot23:			move.w	VBRateRot23+2,d1
			sub.w	d1,RotateAngle23
			move.w	#$0101,AD2Update
			bra.s	.End

.AntiClockwise2:	btst	#4,RotateFlag		;AntiClockwise?
			beq.s	.End

			subq.l	#1,VBCountRot23Temp
			bne.s	.End

			move.l	VBCountRot23,VBCountRot23Temp

			move.w	RotateAngleMax23,d1
			sub.w	VBRateRot23+2,d1
			cmp.w	RotateAngle23,d1
			bhs.s	.Rot232

			btst	#5,RotateFlag		;Change direction?
			beq.s	.RotAgain232

			bclr	#4,RotateFlag
			bset	#3,RotateFlag
			bra.s	.End

.RotAgain232:		move.w	RotateAngleMin23,RotateAngle23
			move.w	#$0101,AD2Update
			bra.s	.End

.Rot232:		move.w	VBRateRot23+2,d1
			add.w	d1,RotateAngle23
			move.w	#$0101,AD2Update

.End:			sub.l	d0,d0
			rts


;Pointers etc:

StackPtr:		dc.l	0
TaskPtr:		dc.l	0
WBMsgPtr:		dc.l	0

DosBase:		dc.l	0
IntBase:		dc.l	0
GfxBase:		dc.l	0
GadBase:		dc.l	0
KeyBase:		dc.l	0
ReqBase:		dc.l	0

RastPortPtr:		dc.l	0
RastPortPtr2:		dc.l	0
MsgPortPtr:		dc.l	0
IORequestPtr:		dc.l	0
NextCmdPtr:		dc.l	0

OutputBufferPtr:	dc.l	0
OutputBufferPtr2:	dc.l	0
OutputBufferPtr3:	dc.l	0

OutputBufferPtrTemp:	dc.l	0
OutputBufferPtr2Temp:	dc.l	0
OutputBufferPtr3Temp:	dc.l	0

ExtrasBufferPtr:	dc.l	0

AD0MemPtr:		dc.l	0
AD1MemPtr:		dc.l	0
AD2MemPtr:		dc.l	0
AD3MemPtr:		dc.l	0

AD1MemPtr2:		dc.l	0
AD2MemPtr2:		dc.l	0
AD3MemPtr2:		dc.l	0

Loc0Ptr:		dc.l	0
Loc1Ptr:		dc.l	0
Loc2Ptr:		dc.l	0
Loc3Ptr:		dc.l	0

Loc0PtrTemp:		dc.l	0
Loc1PtrTemp:		dc.l	0
Loc2PtrTemp:		dc.l	0
Loc3PtrTemp:		dc.l	0

End0Ptr:		dc.l	0
End1Ptr:		dc.l	0
End2Ptr:		dc.l	0
End3Ptr:		dc.l	0

ReqFNPtr:		dc.l	0
FileRequestPtr:		dc.l	0

FileInfoBlockPtr:	dc.l	0
FileLockPtr:		dc.l	0
FilePtr:		dc.l	0
FileMemPtr:		dc.l	0
FileMemSize:		dc.l	0
FileMemSize2:		dc.l	0

SeqMemPtr:		dc.l	0
SeqMemSize:		dc.l	0

ViewMemPtr:		dc.l	0
ViewMemPtr2:		dc.l	0

ReplayPtr:		dc.l	0
ReplayPtr2:		dc.l	0

SequencePtr:		dc.l	0
SequenceEnd:		dc.l	0
WaitCount:		dc.l	0
SequenceCountTrig:	dc.l	0
SequenceCountTrigTemp:	dc.l	0
SequenceCountTrigTemp2:	dc.l	0

AddressPtr:		dc.l	0

RecordBuffPtr:		dc.l	0
BufferSize:		dc.l	0
BufferSize2:		dc.l	0

DataPtr:		dc.l	0
ConfigPtr:		dc.l	0

Preset1DrawPtr:		dc.l	0
Preset1DrawSize:	dc.l	0
Preset2DrawPtr:		dc.l	0
Preset2DrawSize:	dc.l	0
Preset3DrawPtr:		dc.l	0
Preset3DrawSize:	dc.l	0
Preset4DrawPtr:		dc.l	0
Preset4DrawSize:	dc.l	0
Preset5DrawPtr:		dc.l	0
Preset5DrawSize:	dc.l	0
Preset6DrawPtr:		dc.l	0
Preset6DrawSize:	dc.l	0
Preset7DrawPtr:		dc.l	0
Preset7DrawSize:	dc.l	0
Preset8DrawPtr:		dc.l	0
Preset8DrawSize:	dc.l	0
Preset9DrawPtr:		dc.l	0
Preset9DrawSize:	dc.l	0
Preset10DrawPtr:	dc.l	0
Preset10DrawSize:	dc.l	0

Preset11DrawPtr:	dc.l	0
Preset11DrawSize:	dc.l	0
Preset12DrawPtr:	dc.l	0
Preset12DrawSize:	dc.l	0
Preset13DrawPtr:	dc.l	0
Preset13DrawSize:	dc.l	0
Preset14DrawPtr:	dc.l	0
Preset14DrawSize:	dc.l	0
Preset15DrawPtr:	dc.l	0
Preset15DrawSize:	dc.l	0
Preset16DrawPtr:	dc.l	0
Preset16DrawSize:	dc.l	0
Preset17DrawPtr:	dc.l	0
Preset17DrawSize:	dc.l	0
Preset18DrawPtr:	dc.l	0
Preset18DrawSize:	dc.l	0
Preset19DrawPtr:	dc.l	0
Preset19DrawSize:	dc.l	0
Preset20DrawPtr:	dc.l	0
Preset20DrawSize:	dc.l	0

Preset21DrawPtr:	dc.l	0
Preset21DrawSize:	dc.l	0
Preset22DrawPtr:	dc.l	0
Preset22DrawSize:	dc.l	0
Preset23DrawPtr:	dc.l	0
Preset23DrawSize:	dc.l	0
Preset24DrawPtr:	dc.l	0
Preset24DrawSize:	dc.l	0
Preset25DrawPtr:	dc.l	0
Preset25DrawSize:	dc.l	0
Preset26DrawPtr:	dc.l	0
Preset26DrawSize:	dc.l	0
Preset27DrawPtr:	dc.l	0
Preset27DrawSize:	dc.l	0
Preset28DrawPtr:	dc.l	0
Preset28DrawSize:	dc.l	0
Preset29DrawPtr:	dc.l	0
Preset29DrawSize:	dc.l	0
Preset30DrawPtr:	dc.l	0
Preset30DrawSize:	dc.l	0

Preset31DrawPtr:	dc.l	0
Preset31DrawSize:	dc.l	0
Preset32DrawPtr:	dc.l	0
Preset32DrawSize:	dc.l	0
Preset33DrawPtr:	dc.l	0
Preset33DrawSize:	dc.l	0
Preset34DrawPtr:	dc.l	0
Preset34DrawSize:	dc.l	0
Preset35DrawPtr:	dc.l	0
Preset35DrawSize:	dc.l	0
Preset36DrawPtr:	dc.l	0
Preset36DrawSize:	dc.l	0
Preset37DrawPtr:	dc.l	0
Preset37DrawSize:	dc.l	0
Preset38DrawPtr:	dc.l	0
Preset38DrawSize:	dc.l	0
Preset39DrawPtr:	dc.l	0
Preset39DrawSize:	dc.l	0
Preset40DrawPtr:	dc.l	0
Preset40DrawSize:	dc.l	0

FactoryDrawPtr:		dc.l	0
FactoryDrawSize:	dc.l	0

SeqMemPtr1:		dc.l	0
SeqMemSize1:		dc.l	0
SeqMemPtr2:		dc.l	0
SeqMemSize2:		dc.l	0
SeqMemPtr3:		dc.l	0
SeqMemSize3:		dc.l	0
SeqMemPtr4:		dc.l	0
SeqMemSize4:		dc.l	0
SeqMemPtr5:		dc.l	0
SeqMemSize5:		dc.l	0
SeqMemPtr6:		dc.l	0
SeqMemSize6:		dc.l	0
SeqMemPtr7:		dc.l	0
SeqMemSize7:		dc.l	0
SeqMemPtr8:		dc.l	0
SeqMemSize8:		dc.l	0
SeqMemPtr9:		dc.l	0
SeqMemSize9:		dc.l	0
SeqMemPtr10:		dc.l	0
SeqMemSize10:		dc.l	0
SeqMemPtr11:		dc.l	0
SeqMemSize11:		dc.l	0
SeqMemPtr12:		dc.l	0
SeqMemSize12:		dc.l	0

SeqMemPtr13:		dc.l	0
SeqMemSize13:		dc.l	0
SeqMemPtr14:		dc.l	0
SeqMemSize14:		dc.l	0
SeqMemPtr15:		dc.l	0
SeqMemSize15:		dc.l	0
SeqMemPtr16:		dc.l	0
SeqMemSize16:		dc.l	0
SeqMemPtr17:		dc.l	0
SeqMemSize17:		dc.l	0
SeqMemPtr18:		dc.l	0
SeqMemSize18:		dc.l	0
SeqMemPtr19:		dc.l	0
SeqMemSize19:		dc.l	0
SeqMemPtr20:		dc.l	0
SeqMemSize20:		dc.l	0

SeqMemPtr21:		dc.l	0
SeqMemSize21:		dc.l	0
SeqMemPtr22:		dc.l	0
SeqMemSize22:		dc.l	0
SeqMemPtr23:		dc.l	0
SeqMemSize23:		dc.l	0
SeqMemPtr24:		dc.l	0
SeqMemSize24:		dc.l	0
SeqMemPtr25:		dc.l	0
SeqMemSize25:		dc.l	0
SeqMemPtr26:		dc.l	0
SeqMemSize26:		dc.l	0
SeqMemPtr27:		dc.l	0
SeqMemSize27:		dc.l	0
SeqMemPtr28:		dc.l	0
SeqMemSize28:		dc.l	0

SeqMemPtr29:		dc.l	0
SeqMemSize29:		dc.l	0
SeqMemPtr30:		dc.l	0
SeqMemSize30:		dc.l	0
SeqMemPtr31:		dc.l	0
SeqMemSize31:		dc.l	0
SeqMemPtr32:		dc.l	0
SeqMemSize32:		dc.l	0
SeqMemPtr33:		dc.l	0
SeqMemSize33:		dc.l	0
SeqMemPtr34:		dc.l	0
SeqMemSize34:		dc.l	0
SeqMemPtr35:		dc.l	0
SeqMemSize35:		dc.l	0
SeqMemPtr36:		dc.l	0
SeqMemSize36:		dc.l	0

SeqMemPtr37:		dc.l	0
SeqMemSize37:		dc.l	0
SeqMemPtr38:		dc.l	0
SeqMemSize38:		dc.l	0
SeqMemPtr39:		dc.l	0
SeqMemSize39:		dc.l	0
SeqMemPtr40:		dc.l	0
SeqMemSize40:		dc.l	0
SeqMemPtr41:		dc.l	0
SeqMemSize41:		dc.l	0
SeqMemPtr42:		dc.l	0
SeqMemSize42:		dc.l	0
SeqMemPtr43:		dc.l	0
SeqMemSize43:		dc.l	0
SeqMemPtr44:		dc.l	0
SeqMemSize44:		dc.l	0

SeqMemPtr45:		dc.l	0
SeqMemSize45:		dc.l	0
SeqMemPtr46:		dc.l	0
SeqMemSize46:		dc.l	0
SeqMemPtr47		dc.l	0
SeqMemSize47:		dc.l	0
SeqMemPtr48:		dc.l	0
SeqMemSize48:		dc.l	0
SeqMemPtr49:		dc.l	0
SeqMemSize49:		dc.l	0
SeqMemPtr50:		dc.l	0
SeqMemSize50:		dc.l	0
SeqMemPtr51:		dc.l	0
SeqMemSize51:		dc.l	0
SeqMemPtr52:		dc.l	0
SeqMemSize52:		dc.l	0

SeqMemPtr53:		dc.l	0
SeqMemSize53:		dc.l	0
SeqMemPtr54:		dc.l	0
SeqMemSize54:		dc.l	0
SeqMemPtr55:		dc.l	0
SeqMemSize55:		dc.l	0
SeqMemPtr56:		dc.l	0
SeqMemSize56:		dc.l	0
SeqMemPtr57:		dc.l	0
SeqMemSize57:		dc.l	0
SeqMemPtr58:		dc.l	0
SeqMemSize58:		dc.l	0
SeqMemPtr59:		dc.l	0
SeqMemSize59:		dc.l	0
SeqMemPtr60:		dc.l	0
SeqMemSize60:		dc.l	0

SeqMemPtr61:		dc.l	0
SeqMemSize61:		dc.l	0
SeqMemPtr62:		dc.l	0
SeqMemSize62:		dc.l	0
SeqMemPtr63:		dc.l	0
SeqMemSize63:		dc.l	0
SeqMemPtr64:		dc.l	0
SeqMemSize64:		dc.l	0
SeqMemPtr65:		dc.l	0
SeqMemSize65:		dc.l	0
SeqMemPtr66:		dc.l	0
SeqMemSize66:		dc.l	0
SeqMemPtr67:		dc.l	0
SeqMemSize67:		dc.l	0
SeqMemPtr68:		dc.l	0
SeqMemSize68:		dc.l	0

SeqMemPtr69:		dc.l	0
SeqMemSize69:		dc.l	0
SeqMemPtr70:		dc.l	0
SeqMemSize70:		dc.l	0
SeqMemPtr71:		dc.l	0
SeqMemSize71:		dc.l	0
SeqMemPtr72:		dc.l	0
SeqMemSize72:		dc.l	0
SeqMemPtr73:		dc.l	0
SeqMemSize73:		dc.l	0
SeqMemPtr74:		dc.l	0
SeqMemSize74:		dc.l	0
SeqMemPtr75:		dc.l	0
SeqMemSize75:		dc.l	0
SeqMemPtr76:		dc.l	0
SeqMemSize76:		dc.l	0

SeqMemPtr77:		dc.l	0
SeqMemSize77:		dc.l	0
SeqMemPtr78:		dc.l	0
SeqMemSize78:		dc.l	0
SeqMemPtr79:		dc.l	0
SeqMemSize79:		dc.l	0
SeqMemPtr80:		dc.l	0
SeqMemSize80:		dc.l	0
SeqMemPtr81:		dc.l	0
SeqMemSize81:		dc.l	0
SeqMemPtr82:		dc.l	0
SeqMemSize82:		dc.l	0
SeqMemPtr83:		dc.l	0
SeqMemSize83:		dc.l	0
SeqMemPtr84:		dc.l	0
SeqMemSize84:		dc.l	0

SeqMemPtr85:		dc.l	0
SeqMemSize85:		dc.l	0
SeqMemPtr86:		dc.l	0
SeqMemSize86:		dc.l	0
SeqMemPtr87:		dc.l	0
SeqMemSize87:		dc.l	0
SeqMemPtr88:		dc.l	0
SeqMemSize88:		dc.l	0
SeqMemPtr89:		dc.l	0
SeqMemSize89:		dc.l	0
SeqMemPtr90:		dc.l	0
SeqMemSize90:		dc.l	0
SeqMemPtr91:		dc.l	0
SeqMemSize91:		dc.l	0
SeqMemPtr92:		dc.l	0
SeqMemSize92:		dc.l	0

SeqMemPtr93:		dc.l	0
SeqMemSize93:		dc.l	0
SeqMemPtr94:		dc.l	0
SeqMemSize94:		dc.l	0
SeqMemPtr95:		dc.l	0
SeqMemSize95:		dc.l	0
SeqMemPtr96:		dc.l	0
SeqMemSize96:		dc.l	0
SeqMemPtr97:		dc.l	0
SeqMemSize97:		dc.l	0
SeqMemPtr98:		dc.l	0
SeqMemSize98:		dc.l	0
SeqMemPtr99:		dc.l	0
SeqMemSize99:		dc.l	0
SeqMemPtr100:		dc.l	0
SeqMemSize100:		dc.l	0

SeqMemPtr101:		dc.l	0
SeqMemSize101:		dc.l	0
SeqMemPtr102:		dc.l	0
SeqMemSize102:		dc.l	0
SeqMemPtr103:		dc.l	0
SeqMemSize103:		dc.l	0
SeqMemPtr104:		dc.l	0
SeqMemSize104:		dc.l	0
SeqMemPtr105:		dc.l	0
SeqMemSize105:		dc.l	0
SeqMemPtr106:		dc.l	0
SeqMemSize106:		dc.l	0
SeqMemPtr107:		dc.l	0
SeqMemSize107:		dc.l	0
SeqMemPtr108:		dc.l	0
SeqMemSize108:		dc.l	0

SeqMemPtr109:		dc.l	0
SeqMemSize109:		dc.l	0
SeqMemPtr110:		dc.l	0
SeqMemSize110:		dc.l	0
SeqMemPtr111:		dc.l	0
SeqMemSize111:		dc.l	0
SeqMemPtr112:		dc.l	0
SeqMemSize112:		dc.l	0
SeqMemPtr113:		dc.l	0
SeqMemSize113:		dc.l	0
SeqMemPtr114:		dc.l	0
SeqMemSize114:		dc.l	0
SeqMemPtr115:		dc.l	0
SeqMemSize115:		dc.l	0
SeqMemPtr116:		dc.l	0
SeqMemSize116:		dc.l	0

SeqMemPtr117:		dc.l	0
SeqMemSize117:		dc.l	0
SeqMemPtr118:		dc.l	0
SeqMemSize118:		dc.l	0
SeqMemPtr119:		dc.l	0
SeqMemSize119:		dc.l	0
SeqMemPtr120:		dc.l	0
SeqMemSize120:		dc.l	0
SeqMemPtr121:		dc.l	0
SeqMemSize121:		dc.l	0
SeqMemPtr122:		dc.l	0
SeqMemSize122:		dc.l	0
SeqMemPtr123:		dc.l	0
SeqMemSize123:		dc.l	0
SeqMemPtr124:		dc.l	0
SeqMemSize124:		dc.l	0

SeqMemPtr125:		dc.l	0
SeqMemSize125:		dc.l	0
SeqMemPtr126:		dc.l	0
SeqMemSize126:		dc.l	0
SeqMemPtr127:		dc.l	0
SeqMemSize127:		dc.l	0
SeqMemPtr128:		dc.l	0
SeqMemSize128:		dc.l	0
SeqMemPtr129:		dc.l	0
SeqMemSize129:		dc.l	0
SeqMemPtr130:		dc.l	0
SeqMemSize130:		dc.l	0
SeqMemPtr131:		dc.l	0
SeqMemSize131:		dc.l	0
SeqMemPtr132:		dc.l	0
SeqMemSize132:		dc.l	0

SeqMemPtr133:		dc.l	0
SeqMemSize133:		dc.l	0
SeqMemPtr134:		dc.l	0
SeqMemSize134:		dc.l	0
SeqMemPtr135:		dc.l	0
SeqMemSize135:		dc.l	0
SeqMemPtr136:		dc.l	0
SeqMemSize136:		dc.l	0
SeqMemPtr137:		dc.l	0
SeqMemSize137:		dc.l	0
SeqMemPtr138:		dc.l	0
SeqMemSize138:		dc.l	0
SeqMemPtr139:		dc.l	0
SeqMemSize139:		dc.l	0
SeqMemPtr140:		dc.l	0
SeqMemSize140:		dc.l	0

SeqMemPtr141:		dc.l	0
SeqMemSize141:		dc.l	0
SeqMemPtr142:		dc.l	0
SeqMemSize142:		dc.l	0
SeqMemPtr143:		dc.l	0
SeqMemSize143:		dc.l	0
SeqMemPtr144:		dc.l	0
SeqMemSize144:		dc.l	0
SeqMemPtr145:		dc.l	0
SeqMemSize145:		dc.l	0
SeqMemPtr146:		dc.l	0
SeqMemSize146:		dc.l	0
SeqMemPtr147:		dc.l	0
SeqMemSize147:		dc.l	0
SeqMemPtr148:		dc.l	0
SeqMemSize148:		dc.l	0

SeqMemPtr149:		dc.l	0
SeqMemSize149:		dc.l	0
SeqMemPtr150:		dc.l	0
SeqMemSize150:		dc.l	0
SeqMemPtr151:		dc.l	0
SeqMemSize151:		dc.l	0
SeqMemPtr152:		dc.l	0
SeqMemSize152:		dc.l	0
SeqMemPtr153:		dc.l	0
SeqMemSize153:		dc.l	0
SeqMemPtr154:		dc.l	0
SeqMemSize154:		dc.l	0
SeqMemPtr155:		dc.l	0
SeqMemSize155:		dc.l	0
SeqMemPtr156:		dc.l	0
SeqMemSize156:		dc.l	0

SeqMemPtr157:		dc.l	0
SeqMemSize157:		dc.l	0
SeqMemPtr158:		dc.l	0
SeqMemSize158:		dc.l	0
SeqMemPtr159:		dc.l	0
SeqMemSize159:		dc.l	0
SeqMemPtr160:		dc.l	0
SeqMemSize160:		dc.l	0
SeqMemPtr161:		dc.l	0
SeqMemSize161:		dc.l	0
SeqMemPtr162:		dc.l	0
SeqMemSize162:		dc.l	0
SeqMemPtr163:		dc.l	0
SeqMemSize163:		dc.l	0
SeqMemPtr164:		dc.l	0
SeqMemSize164:		dc.l	0

SeqMemPtr165:		dc.l	0
SeqMemSize165:		dc.l	0
SeqMemPtr166:		dc.l	0
SeqMemSize166:		dc.l	0
SeqMemPtr167:		dc.l	0
SeqMemSize167:		dc.l	0
SeqMemPtr168:		dc.l	0
SeqMemSize168:		dc.l	0
SeqMemPtr169:		dc.l	0
SeqMemSize169:		dc.l	0
SeqMemPtr170:		dc.l	0
SeqMemSize170:		dc.l	0
SeqMemPtr171:		dc.l	0
SeqMemSize171:		dc.l	0
SeqMemPtr172:		dc.l	0
SeqMemSize172:		dc.l	0

SeqMemPtr173:		dc.l	0
SeqMemSize173:		dc.l	0
SeqMemPtr174:		dc.l	0
SeqMemSize174:		dc.l	0
SeqMemPtr175:		dc.l	0
SeqMemSize175:		dc.l	0
SeqMemPtr176:		dc.l	0
SeqMemSize176:		dc.l	0
SeqMemPtr177:		dc.l	0
SeqMemSize177:		dc.l	0
SeqMemPtr178:		dc.l	0
SeqMemSize178:		dc.l	0
SeqMemPtr179:		dc.l	0
SeqMemSize179:		dc.l	0
SeqMemPtr180:		dc.l	0
SeqMemSize180:		dc.l	0

SeqMemPtr181:		dc.l	0
SeqMemSize181:		dc.l	0
SeqMemPtr182:		dc.l	0
SeqMemSize182:		dc.l	0
SeqMemPtr183:		dc.l	0
SeqMemSize183:		dc.l	0
SeqMemPtr184:		dc.l	0
SeqMemSize184:		dc.l	0
SeqMemPtr185:		dc.l	0
SeqMemSize185:		dc.l	0
SeqMemPtr186:		dc.l	0
SeqMemSize186:		dc.l	0
SeqMemPtr187:		dc.l	0
SeqMemSize187:		dc.l	0
SeqMemPtr188:		dc.l	0
SeqMemSize188:		dc.l	0

SeqMemPtr189:		dc.l	0
SeqMemSize189:		dc.l	0
SeqMemPtr190:		dc.l	0
SeqMemSize190:		dc.l	0
SeqMemPtr191:		dc.l	0
SeqMemSize191:		dc.l	0
SeqMemPtr192:		dc.l	0
SeqMemSize192:		dc.l	0
SeqMemPtr193:		dc.l	0
SeqMemSize193:		dc.l	0
SeqMemPtr194:		dc.l	0
SeqMemSize194:		dc.l	0
SeqMemPtr195:		dc.l	0
SeqMemSize195:		dc.l	0
SeqMemPtr196:		dc.l	0
SeqMemSize196:		dc.l	0

SeqMemPtr197:		dc.l	0
SeqMemSize197:		dc.l	0
SeqMemPtr198:		dc.l	0
SeqMemSize198:		dc.l	0
SeqMemPtr199:		dc.l	0
SeqMemSize199:		dc.l	0
SeqMemPtr200:		dc.l	0
SeqMemSize200:		dc.l	0
SeqMemPtr201:		dc.l	0
SeqMemSize201:		dc.l	0
SeqMemPtr202:		dc.l	0
SeqMemSize202:		dc.l	0
SeqMemPtr203:		dc.l	0
SeqMemSize203:		dc.l	0
SeqMemPtr204:		dc.l	0
SeqMemSize204:		dc.l	0

SeqMemPtr205:		dc.l	0
SeqMemSize205:		dc.l	0
SeqMemPtr206:		dc.l	0
SeqMemSize206:		dc.l	0
SeqMemPtr207:		dc.l	0
SeqMemSize207:		dc.l	0
SeqMemPtr208:		dc.l	0
SeqMemSize208:		dc.l	0
SeqMemPtr209:		dc.l	0
SeqMemSize209:		dc.l	0
SeqMemPtr210:		dc.l	0
SeqMemSize210:		dc.l	0
SeqMemPtr211:		dc.l	0
SeqMemSize211:		dc.l	0
SeqMemPtr212:		dc.l	0
SeqMemSize212:		dc.l	0

SeqMemPtr213:		dc.l	0
SeqMemSize213:		dc.l	0
SeqMemPtr214:		dc.l	0
SeqMemSize214:		dc.l	0
SeqMemPtr215:		dc.l	0
SeqMemSize215:		dc.l	0
SeqMemPtr216:		dc.l	0
SeqMemSize216:		dc.l	0
SeqMemPtr217:		dc.l	0
SeqMemSize217:		dc.l	0
SeqMemPtr218:		dc.l	0
SeqMemSize218:		dc.l	0
SeqMemPtr219:		dc.l	0
SeqMemSize219:		dc.l	0
SeqMemPtr220:		dc.l	0
SeqMemSize220:		dc.l	0

SeqMemPtr221:		dc.l	0
SeqMemSize221:		dc.l	0
SeqMemPtr222:		dc.l	0
SeqMemSize222:		dc.l	0
SeqMemPtr223:		dc.l	0
SeqMemSize223:		dc.l	0
SeqMemPtr224:		dc.l	0
SeqMemSize224:		dc.l	0
SeqMemPtr225:		dc.l	0
SeqMemSize225:		dc.l	0
SeqMemPtr226:		dc.l	0
SeqMemSize226:		dc.l	0
SeqMemPtr227:		dc.l	0
SeqMemSize227:		dc.l	0
SeqMemPtr228:		dc.l	0
SeqMemSize228:		dc.l	0

SeqMemPtr229:		dc.l	0
SeqMemSize229:		dc.l	0
SeqMemPtr230:		dc.l	0
SeqMemSize230:		dc.l	0
SeqMemPtr231:		dc.l	0
SeqMemSize231:		dc.l	0
SeqMemPtr232:		dc.l	0
SeqMemSize232:		dc.l	0
SeqMemPtr233:		dc.l	0
SeqMemSize233:		dc.l	0
SeqMemPtr234:		dc.l	0
SeqMemSize234:		dc.l	0
SeqMemPtr235:		dc.l	0
SeqMemSize235:		dc.l	0
SeqMemPtr236:		dc.l	0
SeqMemSize236:		dc.l	0

SeqMemPtr237:		dc.l	0
SeqMemSize237:		dc.l	0
SeqMemPtr238:		dc.l	0
SeqMemSize238:		dc.l	0
SeqMemPtr239:		dc.l	0
SeqMemSize239:		dc.l	0
SeqMemPtr240:		dc.l	0
SeqMemSize240:		dc.l	0
SeqMemPtr241:		dc.l	0
SeqMemSize241:		dc.l	0
SeqMemPtr242:		dc.l	0
SeqMemSize242:		dc.l	0
SeqMemPtr243:		dc.l	0
SeqMemSize243:		dc.l	0
SeqMemPtr244:		dc.l	0
SeqMemSize244:		dc.l	0

SeqMemPtr245:		dc.l	0
SeqMemSize245:		dc.l	0
SeqMemPtr246:		dc.l	0
SeqMemSize246:		dc.l	0
SeqMemPtr247:		dc.l	0
SeqMemSize247:		dc.l	0
SeqMemPtr248:		dc.l	0
SeqMemSize248:		dc.l	0
SeqMemPtr249:		dc.l	0
SeqMemSize249:		dc.l	0
SeqMemPtr250:		dc.l	0
SeqMemSize250:		dc.l	0
SeqMemPtr251:		dc.l	0
SeqMemSize251:		dc.l	0
SeqMemPtr252:		dc.l	0
SeqMemSize252:		dc.l	0

SeqMemPtr253:		dc.l	0
SeqMemSize253:		dc.l	0
SeqMemPtr254:		dc.l	0
SeqMemSize254:		dc.l	0
SeqMemPtr255:		dc.l	0
SeqMemSize255:		dc.l	0
SeqMemPtr256:		dc.l	0
SeqMemSize256:		dc.l	0
SeqMemPtr257:		dc.l	0
SeqMemSize257:		dc.l	0
SeqMemPtr258:		dc.l	0
SeqMemSize258:		dc.l	0
SeqMemPtr259:		dc.l	0
SeqMemSize259:		dc.l	0
SeqMemPtr260:		dc.l	0
SeqMemSize260:		dc.l	0

SeqMemPtr261:		dc.l	0
SeqMemSize261:		dc.l	0
SeqMemPtr262:		dc.l	0
SeqMemSize262:		dc.l	0
SeqMemPtr263:		dc.l	0
SeqMemSize263:		dc.l	0
SeqMemPtr264:		dc.l	0
SeqMemSize264:		dc.l	0
SeqMemPtr265:		dc.l	0
SeqMemSize265:		dc.l	0
SeqMemPtr266:		dc.l	0
SeqMemSize266:		dc.l	0
SeqMemPtr267:		dc.l	0
SeqMemSize267:		dc.l	0
SeqMemPtr268:		dc.l	0
SeqMemSize268:		dc.l	0

SeqMemPtr269:		dc.l	0
SeqMemSize269:		dc.l	0
SeqMemPtr270:		dc.l	0
SeqMemSize270:		dc.l	0
SeqMemPtr271:		dc.l	0
SeqMemSize271:		dc.l	0
SeqMemPtr272:		dc.l	0
SeqMemSize272:		dc.l	0
SeqMemPtr273:		dc.l	0
SeqMemSize273:		dc.l	0
SeqMemPtr274:		dc.l	0
SeqMemSize274:		dc.l	0
SeqMemPtr275:		dc.l	0
SeqMemSize275:		dc.l	0
SeqMemPtr276:		dc.l	0
SeqMemSize276:		dc.l	0

SeqMemPtr277:		dc.l	0
SeqMemSize277:		dc.l	0
SeqMemPtr278:		dc.l	0
SeqMemSize278:		dc.l	0
SeqMemPtr279:		dc.l	0
SeqMemSize279:		dc.l	0
SeqMemPtr280:		dc.l	0
SeqMemSize280:		dc.l	0
SeqMemPtr281:		dc.l	0
SeqMemSize281:		dc.l	0
SeqMemPtr282:		dc.l	0
SeqMemSize282:		dc.l	0
SeqMemPtr283:		dc.l	0
SeqMemSize283:		dc.l	0
SeqMemPtr284:		dc.l	0
SeqMemSize284:		dc.l	0

SeqMemPtr285:		dc.l	0
SeqMemSize285:		dc.l	0
SeqMemPtr286:		dc.l	0
SeqMemSize286:		dc.l	0
SeqMemPtr287:		dc.l	0
SeqMemSize287:		dc.l	0
SeqMemPtr288:		dc.l	0
SeqMemSize288:		dc.l	0
SeqMemPtr289:		dc.l	0
SeqMemSize289:		dc.l	0
SeqMemPtr290:		dc.l	0
SeqMemSize290:		dc.l	0
SeqMemPtr291:		dc.l	0
SeqMemSize291:		dc.l	0
SeqMemPtr292:		dc.l	0
SeqMemSize292:		dc.l	0

SeqMemPtr293:		dc.l	0
SeqMemSize293:		dc.l	0
SeqMemPtr294:		dc.l	0
SeqMemSize294:		dc.l	0
SeqMemPtr295:		dc.l	0
SeqMemSize295:		dc.l	0
SeqMemPtr296:		dc.l	0
SeqMemSize296:		dc.l	0
SeqMemPtr297:		dc.l	0
SeqMemSize297:		dc.l	0
SeqMemPtr298:		dc.l	0
SeqMemSize298:		dc.l	0
SeqMemPtr299:		dc.l	0
SeqMemSize299:		dc.l	0
SeqMemPtr300:		dc.l	0
SeqMemSize300:		dc.l	0

SeqMemPtr301:		dc.l	0
SeqMemSize301:		dc.l	0
SeqMemPtr302:		dc.l	0
SeqMemSize302:		dc.l	0
SeqMemPtr303:		dc.l	0
SeqMemSize303:		dc.l	0
SeqMemPtr304:		dc.l	0
SeqMemSize304:		dc.l	0
SeqMemPtr305:		dc.l	0
SeqMemSize305:		dc.l	0
SeqMemPtr306:		dc.l	0
SeqMemSize306:		dc.l	0
SeqMemPtr307:		dc.l	0
SeqMemSize307:		dc.l	0
SeqMemPtr308:		dc.l	0
SeqMemSize308:		dc.l	0

SeqMemPtr309:		dc.l	0
SeqMemSize309:		dc.l	0
SeqMemPtr310:		dc.l	0
SeqMemSize310:		dc.l	0
SeqMemPtr311:		dc.l	0
SeqMemSize311:		dc.l	0
SeqMemPtr312:		dc.l	0
SeqMemSize312:		dc.l	0
SeqMemPtr313:		dc.l	0
SeqMemSize313:		dc.l	0
SeqMemPtr314:		dc.l	0
SeqMemSize314:		dc.l	0
SeqMemPtr315:		dc.l	0
SeqMemSize315:		dc.l	0
SeqMemPtr316:		dc.l	0
SeqMemSize316:		dc.l	0

SeqMemPtr317:		dc.l	0
SeqMemSize317:		dc.l	0
SeqMemPtr318:		dc.l	0
SeqMemSize318:		dc.l	0
SeqMemPtr319:		dc.l	0
SeqMemSize319:		dc.l	0
SeqMemPtr320:		dc.l	0
SeqMemSize320:		dc.l	0
SeqMemPtr321:		dc.l	0
SeqMemSize321:		dc.l	0
SeqMemPtr322:		dc.l	0
SeqMemSize322:		dc.l	0
SeqMemPtr323:		dc.l	0
SeqMemSize323:		dc.l	0
SeqMemPtr324:		dc.l	0
SeqMemSize324:		dc.l	0

SeqMemPtr325:		dc.l	0
SeqMemSize325:		dc.l	0
SeqMemPtr326:		dc.l	0
SeqMemSize326:		dc.l	0
SeqMemPtr327:		dc.l	0
SeqMemSize327:		dc.l	0
SeqMemPtr328:		dc.l	0
SeqMemSize328:		dc.l	0
SeqMemPtr329:		dc.l	0
SeqMemSize329:		dc.l	0
SeqMemPtr330:		dc.l	0
SeqMemSize330:		dc.l	0
SeqMemPtr331:		dc.l	0
SeqMemSize331:		dc.l	0
SeqMemPtr332:		dc.l	0
SeqMemSize332:		dc.l	0

DrawMemPtr:		dc.l	0
DrawMemPtr2:		dc.l	0
XDataPtr:		dc.l	0
YDataPtr:		dc.l	0
ZDataPtr:		dc.l	0

FontPtr:		dc.l	0
FontSize:		dc.l	0

FireFlyPtr:		dc.l	0
FireFlyMemPtr:		dc.l	0

AquariusMemPtr		dc.l	0
AquariusSize:		dc.l	0

ScanMemPtr:		dc.l	0

LSDMemPtr:		dc.l	0
LSDMemSize:		dc.l	0
LSDDataPtr:		dc.l	0
LSDDataPtr2:		dc.l	0
LSDDataPtr3:		dc.l	0

ILDADataPtr:		dc.l	0
ILDAMemPtr:		dc.l	0
ILDAMemSize:		dc.l	0
ILDAMemPtr2:		dc.l	0
ILDAMemSize2:		dc.l	0

X29MemPtr:		dc.l	0
X29MemSize:		dc.l	0
X29Ptr:			dc.l	0

LD400Ptr:		dc.l	0
LD400Ptr2:		dc.l	0
LD400MemPtr:		dc.l	0
LD400MemSize:		dc.l	0

LDProPtr:		dc.l	0
LDProPtr2:		dc.l	0
LDProMemPtr:		dc.l	0
LDProMemSize:		dc.l	0

MorphMemPtr:		dc.l	0

BufferMemPtr:		dc.l	0
BufferMemSize:		dc.l	0

XDataTextPtr:		dc.l	0
XDataTextPtrTemp:	dc.l	0
XDataLinePtr:		dc.l	0
XDataArcPtr:		dc.l	0
XDataBoxPtr:		dc.l	0
XDataEllipsePtr:	dc.l	0
XDataMergePtr:		dc.l	0
XDataDragPtr:		dc.l	0
XDataDragPtrTemp:	dc.l	0
XDataLastPtr:		dc.l	0

XDataTextSize:		dc.l	0,0
XDataLineSize:		dc.l	0
XDataArcSize:		dc.l	0
XDataBoxSize:		dc.l	0
XDataEllipseSize:	dc.l	0
XDataMergeSize:		dc.l	0
XDataDragSize:		dc.l	0,0
XDataLastSize:		dc.l	0

XDataTextPtr2:		dc.l	0
XDataTextPtrTemp2:	dc.l	0
XDataLinePtr2:		dc.l	0
XDataArcPtr2:		dc.l	0
XDataBoxPtr2:		dc.l	0
XDataEllipsePtr2:	dc.l	0
XDataMergePtr2:		dc.l	0
XDataDragPtr2:		dc.l	0
XDataDragPtrTemp2:	dc.l	0
XDataLastPtr2:		dc.l	0

XDataTextSize2:		dc.l	0,0
XDataLineSize2:		dc.l	0
XDataArcSize2:		dc.l	0
XDataBoxSize2:		dc.l	0
XDataEllipseSize2:	dc.l	0
XDataMergeSize2:	dc.l	0
XDataDragSize2:		dc.l	0,0
XDataLastSize2:		dc.l	0

LastChrPtr:		dc.l	0

LastStartPtrTemp:	dc.l	0
LastStartSizeTemp:	dc.l	0

PreloadPtr:		dc.l	0
PreloadPtr2:		dc.l	0
PreloadPtr3:		dc.l	0

UndoPtr:		dc.l	0
UndoPtr2:		dc.l	0

XDrawPtr:		dc.l	0
YDrawPtr:		dc.l	0
ZDrawPtr:		dc.l	0

CommandTextPtr:		dc.l	0

ScrDefPtr:		dc.l	0

PackPtr:		dc.l	0
PackPtr2:		dc.l	0
PackPtr3:		dc.l	0
PackPtr4:		dc.l	0

DMA0Ptr:		dc.l	0
DMA1Ptr:		dc.l	0
DMA2Ptr:		dc.l	0
DMA3Ptr:		dc.l	0

InsertPtr:		dc.l	0
MovePtr:		dc.l	0

AuraMemPtr:		dc.l	0
AuraMemSize:		dc.l	0

RecAddPtr:		dc.l	0

LASERfIREMemPtr:	dc.l	0
LASERfIREScrPtr:	dc.l	0
LASERfIRECmdPtr:	dc.l	0


;Data space:

Value:			dc.l	0
FastMoveWait:		dc.l	0
Bytes:			dc.l	0

DrawCount:		dc.l	0
DrawCountTemp:		dc.l	0
DrawingLen:		dc.l	0
DrawingLen2:		dc.l	0
DrawRate:		dc.l	0
DrawRate2:		dc.l	200
Rate:			dc.l	0

MorphSteps:		dc.l	0
MorphStepsTemp:		dc.l	0
MorphStepsTemp2:	dc.l	0
MorphCount:		dc.l	0
MorphCountTemp:		dc.l	0
MorphLen:		dc.l	0
MorphRate:		dc.l	50

AutoStopCount:		dc.l	0

DragCount:		dc.l	0

DrawLen:		dc.l	0

LSDPoints:		dc.l	0

MaxPPS:			dc.l	288670

StatusCount:		dc.l	-1

OpenType:		dc.l	0

ScanMax:		dc.l	0

LASERfIRESeqLen:	dc.l	0
DefTrack:		dc.l	0
LfRate:			dc.l	0

SetCmd:			dc.l	0
SetTrack:		dc.l	0
SetFlags:		dc.l	0
SetValue:		dc.l	0
SetStep:		dc.l	0
SetCount:		dc.l	0
SetMax:			dc.l	0
SetMin:			dc.l	0
SetXOffset:		dc.l	0
SetYOffset:		dc.l	0

NextCount:		dc.l	0

DrawX:			dc.l	ScopeX+131
DrawY:			dc.l	ScopeY+65
EraseX:			dc.l	ScopeX+131
EraseY:			dc.l	ScopeY+65
DBLastX:		dc.l	0
DBLastY:		dc.l	0

VBCountV0:		dc.l	0
VBCountV1:		dc.l	0
VBCountV2:		dc.l	0
VBCountV3:		dc.l	0
VBCountV0Temp:		dc.l	0
VBCountV1Temp:		dc.l	0
VBCountV2Temp:		dc.l	0
VBCountV3Temp:		dc.l	0
VBRateV0:		dc.l	0
VBRateV1:		dc.l	0
VBRateV2:		dc.l	0
VBRateV3:		dc.l	0

VBCountF0:		dc.l	0
VBCountF1:		dc.l	0
VBCountF2:		dc.l	0
VBCountF3:		dc.l	0
VBCountF0Temp:		dc.l	0
VBCountF1Temp:		dc.l	0
VBCountF2Temp:		dc.l	0
VBCountF3Temp:		dc.l	0
VBRateF0:		dc.l	0
VBRateF1:		dc.l	0
VBRateF2:		dc.l	0
VBRateF3:		dc.l	0

VBCountP0:		dc.l	0			;Dummy
VBCountP1:		dc.l	0
VBCountP2:		dc.l	0
VBCountP3:		dc.l	0
VBCountP0Temp:		dc.l	0			;Dummy
VBCountP1Temp:		dc.l	0
VBCountP2Temp:		dc.l	0
VBCountP3Temp:		dc.l	0
VBRateP0:		dc.l	0			;Dummy
VBRateP1:		dc.l	0
VBRateP2:		dc.l	0
VBRateP3:		dc.l	0

VBCountS0:		dc.l	0
VBCountS1:		dc.l	0
VBCountS2:		dc.l	0
VBCountS3:		dc.l	0
VBCountS0Temp:		dc.l	0
VBCountS1Temp:		dc.l	0
VBCountS2Temp:		dc.l	0
VBCountS3Temp:		dc.l	0
VBRateS0:		dc.l	0
VBRateS1:		dc.l	0
VBRateS2:		dc.l	0
VBRateS3:		dc.l	0

VBCountRot01:		dc.l	0
VBCountRot23:		dc.l	0
VBCountRot01Temp:	dc.l	0
VBCountRot23Temp:	dc.l	0
VBRateRot01:		dc.l	0
VBRateRot23:		dc.l	0

Loc0:			dc.l	SineWave
Loc1:			dc.l	SineWave
Loc2:			dc.l	SineWave
Loc3:			dc.l	SineWave

Len0:			dc.l	90
Len1:			dc.l	90
Len2:			dc.l	90
Len3:			dc.l	90

Vol0:			dc.w	64
Vol1:			dc.w	64
Vol2:			dc.w	64
Vol3:			dc.w	64

Freq0:			dc.w	500
Freq1:			dc.w	500
Freq2:			dc.w	500
Freq3:			dc.w	500

Phase1:			dc.w	0
Phase2:			dc.w	0
Phase3:			dc.w	0

Spin0:			dc.w	0
Spin1:			dc.w	0
Spin2:			dc.w	0
Spin3:			dc.w	0

RotateAngle01:		dc.w	0
RotateAngle23:		dc.w	0

Len02:			dc.l	90
Len12:			dc.l	90
Len22:			dc.l	90
Len32:			dc.l	90

Vol02:			dc.w	64
Vol12:			dc.w	64
Vol22:			dc.w	64
Vol32:			dc.w	64

Freq02:			dc.w	500
Freq12:			dc.w	500
Freq22:			dc.w	500
Freq32:			dc.w	500

Phase12:		dc.w	0
Phase22:		dc.w	0
Phase32:		dc.w	0

Spin02:			dc.w	0
Spin12:			dc.w	0
Spin22:			dc.w	0
Spin32:			dc.w	0

RotateAngle012:		dc.w	0
RotateAngle232:		dc.w	0

AD0Funct:		dc.w	0
AD1Funct:		dc.w	0
AD2Funct:		dc.w	0
AD3Funct:		dc.w	0

Vol0Max:		dc.w	64
Vol1Max:		dc.w	64
Vol2Max:		dc.w	64
Vol3Max:		dc.w	64

Vol0Min:		dc.w	10
Vol1Min:		dc.w	10
Vol2Min:		dc.w	10
Vol3Min:		dc.w	10

Freq0Max:		dc.w	1000
Freq1Max:		dc.w	1000
Freq2Max:		dc.w	1000
Freq3Max:		dc.w	1000

Freq0Min:		dc.w	400
Freq1Min:		dc.w	400
Freq2Min:		dc.w	400
Freq3Min:		dc.w	400

Phase0Max:		dc.w	359			;Dummy
Phase1Max:		dc.w	359
Phase2Max:		dc.w	359
Phase3Max:		dc.w	359

Phase0Min:		dc.w	0			;Dummy
Phase1Min:		dc.w	0
Phase2Min:		dc.w	0
Phase3Min:		dc.w	0

Spin0Max:		dc.w	359
Spin1Max:		dc.w	359
Spin2Max:		dc.w	359
Spin3Max:		dc.w	359

Spin0Min:		dc.w	0
Spin1Min:		dc.w	0
Spin2Min:		dc.w	0
Spin3Min:		dc.w	0

RotateAngleMax01:	dc.w	359
RotateAngleMax23:	dc.w	359

RotateAngleMin01:	dc.w	0
RotateAngleMin23:	dc.w	0

Data0:			dc.w	0
Data1:			dc.w	0
Data2:			dc.w	0
Data3:			dc.w	0

Speed0:			dc.w	0
Speed1:			dc.w	0
Speed2:			dc.w	0
Speed3:			dc.w	0

Speed0Temp:		dc.w	0
Speed1Temp:		dc.w	0
Speed2Temp:		dc.w	0
Speed3Temp:		dc.w	0
LowSpeed:		dc.w	0

Freq0Sync:		dc.w	0
Freq1Sync:		dc.w	0
Freq2Sync:		dc.w	0
Freq3Sync:		dc.w	0

Vol0Print:		dc.w	64
Vol1Print:		dc.w	64
Vol2Print:		dc.w	64
Vol3Print:		dc.w	64

Freq0Print:		dc.w	500
Freq1Print:		dc.w	500
Freq2Print:		dc.w	500
Freq3Print:		dc.w	500

Phase1Print:		dc.w	0
Phase2Print:		dc.w	0
Phase3Print:		dc.w	0

Spin0Print:		dc.w	0
Spin1Print:		dc.w	0
Spin2Print:		dc.w	0
Spin3Print:		dc.w	0

RotateAngle01Print:	dc.w	0
RotateAngle23Print:	dc.w	0

PicCount:		dc.w	0
PicCount2:		dc.w	0

LaserCNT:		dc.w	87
BevelBox:		dc.w	142
BevelBox2:		dc.w	39

AutoPoints:		dc.w	30
PatSize:		dc.w	63
PatPoints:		dc.w	90
XHiResSize:		dc.w	64
YHiResSize:		dc.w	64
XOutSize:		dc.w	64
YOutSize:		dc.w	64

LinePoints:		dc.w	30
ArcPoints:		dc.w	30
ArcPoints2:		dc.w	0
ArcQuadrant:		dc.w	0
BoxPoints:		dc.w	121
XBoxPoints:		dc.w	0
YBoxPoints		dc.w	0
EllipsePoints:		dc.w	90
EllipsePoints2:		dc.w	0
RollCount:		dc.w	0
RollCount2:		dc.w	0
RotateAngle:		dc.w	0
RotateAngleTemp:	dc.w	0
SpinAngle:		dc.w	0

StopDelayCount:		dc.w	2

UndoCount:		dc.w	0
MaxUndos:		dc.w	50

MoveRate:		dc.w	0
MoveCount:		dc.w	0
MoveCount2:		dc.w	0
MoveCount3:		dc.w	0
MoveDiff:		dc.w	0

XPos:			dc.w	XMax/2
YPos:			dc.w	YMax/2
XPosTemp:		dc.w	XMax/2
YPosTemp:		dc.w	YMax/2
XPosPrint:		dc.w	XMax/2
YPosPrint:		dc.w	YMax/2
XStartPos:		dc.w	XMax/2
YStartPos:		dc.w	YMax/2
XCenter:		dc.w	0
YCenter:		dc.w	0
XNumber:		dc.w	0
YNumber:		dc.w	0

LfXPos:			dc.w	XMax/2
LfYPos:			dc.w	YMax/2
LfXPosTemp:		dc.w	XMax/2
LfYPosTemp:		dc.w	YMax/2

NextSelect:		dc.w	$ffff

LSDChannels:		dc.w	0
LSDFrameCount:		dc.w	0
LSDFrameCount2:		dc.w	0
LSDXPeriod:		dc.w	0
LSDYPeriod:		dc.w	0

ILDAPoints:		dc.w	0
ILDAFrame:		dc.w	0
ILDAFrame2:		dc.w	0
ILDATotal:		dc.w	0
ILDATotal2:		dc.w	0
ILDATotal3:		dc.w	0
ILDACount:		dc.w	0

X29Count:		dc.w	0
X29Count2:		dc.w	0

LD400Count:		dc.w	0
LD400Count2:		dc.w	0
LD400Points:		dc.w	0
LD400Type:		dc.w	0

LDProCount:		dc.w	0
LDProCount2:		dc.w	0
LDProPoints:		dc.w	0
LDProType:		dc.w	0

ScrDef1:		dc.w	64			;X Size
			dc.w	64			;Y Size
			dc.w	XMax/2			;X Pos
			dc.w	YMax/2			;Y Pos

ScrDef2:		dc.w	64			;X Size
			dc.w	64			;Y Size
			dc.w	XMax/2			;X Pos
			dc.w	YMax/2			;Y Pos

ScrDef3:		dc.w	64			;X Size
			dc.w	64			;Y Size
			dc.w	XMax/2			;X Pos
			dc.w	YMax/2			;Y Pos

ScrDef4:		dc.w	64			;X Size
			dc.w	64			;Y Size
			dc.w	XMax/2			;X Pos
			dc.w	YMax/2			;Y Pos

DefXSize:		dc.w	0
DefYSize:		dc.w	0
DefXPos:		dc.w	0
DefYPos:		dc.w	0

StackNumber:		dc.w	0
StackNumber2:		dc.w	1

HiResDCXOffset:		dc.w	0
HiResDCYOffset:		dc.w	0

PackCount:		dc.w	0
PackCount2:		dc.w	0
PackCount3:		dc.w	0

DMA0Len:		dc.w	0
DMA1Len:		dc.w	0
DMA2Len:		dc.w	0
DMA3Len:		dc.w	0

ScaleBend:		dc.w	0
BendAmount:		dc.w	50

PotOne:			dc.w	0
PotTwo:			dc.w	0
PotThree:		dc.w	0
PotFour:		dc.w	0

LoadNumber:		dc.w	0

AD0Update:		dc.b	0
AD1Update:		dc.b	0
AD2Update:		dc.b	0
AD3Update:		dc.b	0

AD0Update2:		dc.b	0
AD1Update2:		dc.b	0
AD2Update2:		dc.b	0
AD3Update2:		dc.b	0

AD0Update3:		dc.b	0
AD1Update3:		dc.b	0
AD2Update3:		dc.b	0
AD3Update3:		dc.b	0

DC0Offset:		dc.b	0
DC1Offset:		dc.b	0
DC2Offset:		dc.b	0
DC3Offset:		dc.b	0

FromChannel:		dc.b	0
ToChannel		dc.b	0
ChannelNumber:		dc.b	0
CommandCode:		dc.b	0
CommandSubCode:		dc.b	0
Sync:			dc.b	0
PlayStatus:		dc.b	0
TriggerFlag:		dc.b	0
TextCount:		dc.b	0
AutoGadCount:		dc.b	0
AutoGadStatus:		dc.b	0
RecordStatus:		dc.b	0
SerialByte:		dc.b	0
SerialByte2:		dc.b	0
MoveStatus:		dc.b	0
MoveStatus2:		dc.b	0
MoveStatus3:		dc.b	0
AttachStatus:		dc.b	0
PrintPosSig:		dc.b	0
JoyCount:		dc.b	0
ClockCount:		dc.b	0
StrobeCount:		dc.b	0
PresetMoveFlag:		dc.b	1
SeqMoveFlag:		dc.b	1
ShutterFlag:		dc.b	1
StandbyFlag:		dc.b	1
StrobeFlag:		dc.b	0
SoleniodFlag:		dc.b	0
FastMoveFlag:		dc.b	0
FastMoveFlag2:		dc.b	0
AutoManFlag:		dc.b	1
FastScopeFlag:		dc.b	0
FromPreset:		dc.b	0
Checksum:		dc.b	0
BlockCount:		dc.b	0
LCFlag:			dc.b	0
DrawMode:		dc.b	0
DrawMode2:		dc.b	0
DrawMode3:		dc.b	0
XMousePos:		dc.b	0
YMousePos:		dc.b	0
XMousePosTemp:		dc.b	0
YMousePosTemp:		dc.b	0
XMousePosTemp2:		dc.b	0
YMousePosTemp2:		dc.b	0
XMousePos3D:		dc.b	0
YMousePos3D:		dc.b	0
ZMousePos:		dc.b	0
MouseFlag:		dc.b	0
AutoRetraceFlag:	dc.b	0
AutoRetraceFlag3:	dc.b	0
SwapFlag:		dc.b	0
ShiftFlag:		dc.b	0
CtrlFlag:		dc.b	0
AltFlag:		dc.b	0
DMAFlag:		dc.b	0
FromConfig:		dc.b	0
TextMode:		dc.b	0
XTextPos:		dc.b	0
YTextPos:		dc.b	0
ZTextPos:		dc.b	0
XTextPos2:		dc.b	0
CursorFlag:		dc.b	0
SerialCount:		dc.b	0
SerialCount2:		dc.b	0
ShiftMode:		dc.b	0
ShiftFlag2:		dc.b	0
ShiftFlag3:		dc.b	0
RotateMode:		dc.b	0
RotateFlag:		dc.b	0
RotateFlag2:		dc.b	0
RotateFlag3:		dc.b	0
ResizeMode:		dc.b	0
AutoDMAFlag:		dc.b	1
XSizeMin:		dc.b	0
XSizeMax:		dc.b	0
YSizeMin:		dc.b	0
YSizeMax:		dc.b	0
XSizeMinTemp:		dc.b	0
XSizeMaxTemp:		dc.b	0
YSizeMinTemp:		dc.b	0
YSizeMaxTemp:		dc.b	0
TemplateFlag:		dc.b	0
EllipseMode:		dc.b	0
EllipseFlag:		dc.b	0
EllipseFlag2:		dc.b	0
MiscCount:		dc.b	0
MiscCount2:		dc.b	0
MiscCount3:		dc.b	0
XEllipsePos:		dc.b	0
YEllipsePos:		dc.b	0
ZEllipsePos:		dc.b	0
EllipseSize:		dc.b	0
EllipseSize2:		dc.b	0
IconifyFlag:		dc.b	0
Dummy:			dc.b	0
HiResFlag:		dc.b	0
BigScreenFlag:		dc.b	0
FreqSyncFlag:		dc.b	0
BufferSwitch0:		dc.b	0
BufferSwitch1:		dc.b	0
BufferSwitch2:		dc.b	0
BufferSwitch3:		dc.b	0
UpdateDataFlag:		dc.b	0
SkipFreq:		dc.b	0
SkipFreq2:		dc.b	0
StartDrawFlag:		dc.b	0
FilterFlag:		dc.b	1
FilterFlag2:		dc.b	1
XShiftPos:		dc.b	0
YShiftPos:		dc.b	0
ZShiftPos:		dc.b	0
XShiftPos2:		dc.b	0
YShiftPos2:		dc.b	0
ZShiftPos2:		dc.b	0
DrawingFlag:		dc.b	0
MorphFlag:		dc.b	0
DrawingFlag2:		dc.b	0
MorphFlag2:		dc.b	0
TextOffFlag:		dc.b	0
EllipseOffFlag:		dc.b	0
Preserve:		dc.b	0
AddMemFlag:		dc.b	0
CheckOnlyFlag:		dc.b	0
PreloadFlag:		dc.b	0
LineMode:		dc.b	0
LineFlag:		dc.b	0
XLinePos:		dc.b	0
YLinePos:		dc.b	0
XLinePos2:		dc.b	0
YLinePos2:		dc.b	0
ItemsFlag:		dc.b	1
MergeMode:		dc.b	0
DeleteMode:		dc.b	0
DeleteFlag:		dc.b	0
FromLoad:		dc.b	0
InvertXFlag:		dc.b	0
InvertYFlag:		dc.b	0
AutoPointsFlag:		dc.b	1
DragFlag:		dc.b	0
SerialFlag:		dc.b	0
PirateFlag:		dc.b	0
ParPort:		dc.b	$bf
BoxMode:		dc.b	0
BoxFlag:		dc.b	0
BoxOffFlag:		dc.b	0
XBoxPos:		dc.b	0
YBoxPos:		dc.b	0
ZBoxPos:		dc.b	0
XBoxPos2:		dc.b	0
YBoxPos2:		dc.b	0
RollMode:		dc.b	0
RollFlag:		dc.b	0
RollFlag2:		dc.b	0
RollFlag3:		dc.b	0
DragMode:		dc.b	0
RotateDCX:		dc.b	0
RotateDCY:		dc.b	0
LastFlag:		dc.b	0
AutoPreloadFlag:	dc.b	0
MagGlassFlag:		dc.b	0
MagCount:		dc.b	0
XHairsCount:		dc.b	0
PtrDrawFlag:		dc.b	0
DrawScopeFlag:		dc.b	0
DrawUpdateFlag:		dc.b	0
ArcMode:		dc.b	0
ArcFlag:		dc.b	0
ArcFlag2:		dc.b	0
XArcPos:		dc.b	0
YArcPos:		dc.b	0
XArcPos2:		dc.b	0
YArcPos2:		dc.b	0
XArcPos3:		dc.b	0
YArcPos3:		dc.b	0
ArcSize:		dc.b	0
ArcSize2:		dc.b	0
ArcDirection:		dc.b	0
ArcDirection2:		dc.b	0
InsertMode:		dc.b	0
InsertMode2:		dc.b	0
InsertFlag:		dc.b	0
InsertFlag2:		dc.b	0
KeyMapBuffer:		dc.b	0
GridFlag:		dc.b	0
GridFlag2:		dc.b	0
SendXYFlag:		dc.b	0
UnitNumber:		dc.b	0
SerialXPos:		dc.b	16
SerialYPos:		dc.b	18
SerialUnit:		dc.b	0
ForceRecMove:		dc.b	0
DirectFlag:		dc.b	0
JustBlanked:		dc.b	0
DefaultFreq:		dc.b	0
MorphStatus:		dc.b	0
DrawStatus:		dc.b	0
MDTwoFlag:		dc.b	0
RBufferFlag:		dc.b	0
SBufferFlag:		dc.b	0
SpeedNumber:		dc.b	0
PresetSpeed:		dc.b	0
MagXMousePos:		dc.b	0
MagYMousePos:		dc.b	0
ShowRSFlag:		dc.b	0
SlaveFlag:		dc.b	0
MasterFlag:		dc.b	0
LastSyncByte:		dc.b	0
FromPlay:		dc.b	0
WaitMoveFlag:		dc.b	0
LSDSaveFlag:		dc.b	0
PeriodFlag:		dc.b	0
PPSFlag:		dc.b	0
Value2:			dc.b	0
ILDAFormat:		dc.b	0
ILDASaveFlag:		dc.b	0
AutoSeqFlag:		dc.b	0
AutoAttachFlag:		dc.b	0
DrawBetweenFlag:	dc.b	0
UseScrDefFlag:		dc.b	0
SmoothChgFlag:		dc.b	0
SmoothChgFlag2:		dc.b	0
NoWaitFlag:		dc.b	1
RestartFlag:		dc.b	0
ForRealFlag:		dc.b	0
FirstTimeFlag:		dc.b	0
PackCheckFlag:		dc.b	0
NoDragFlag:		dc.b	0
D3Flag:			dc.b	0
D3FlagTemp:		dc.b	0
MorphD3Flag:		dc.b	0
TopViewFlag:		dc.b	0
XSizeMinBend:		dc.b	0
XCenterBend:		dc.b	0
MoveMode:		dc.b	0
MovePntXTemp:		dc.b	0
MovePntYTemp:		dc.b	0
MovePntZTemp:		dc.b	0
GotXFlag:		dc.b	0
GotYFlag:		dc.b	0
GotZFlag:		dc.b	0
TextAnchorFlag:		dc.b	0
XRotatePos:		dc.b	0
YRotatePos:		dc.b	0
ZRotatePos:		dc.b	0
X29SaveFlag:		dc.b	0
AddLfFlag:		dc.b	0
FromFreq:		dc.b	0
UpdateItFlag:		dc.b	0
Bank:			dc.b	0
LASERfIREFlag:		dc.b	0
FromLASERfIRE:		dc.b	0
X29Mode:		dc.b	0


;Library/Device names:

DosName:		dc.b	"dos.library",0
IntName:		dc.b	"intuition.library",0
GfxName:		dc.b	"graphics.library",0
GadName:		dc.b	"gadtools.library",0
KeyMapName:		dc.b	"keymap.library",0
ReqToolsName:		dc.b	"reqtools.library",0
SerialName:		dc.b	"serial.device",0


;Serial device msg port name:

MsgPortName:		dc.b	"LASERIORequest",0


;Space for scope table:

PixelTable:		dcb.l	TableSize,0


;Space for filenames & paths:

ReqFN:			dcb.b	108,0

Dir:			dc.b	"LASERMAX:Sequences/"
			dcb.b	81-(*-Dir),0

Dir2:			dc.b	"LASERMAX:Screens/"
			dcb.b	81-(*-Dir2),0

Dir3:			dc.b	"LASERMAX:Fonts/"
			dcb.b	81-(*-Dir3),0

Dir4:			dc.b	"LASERMAX:Configurations/"
			dcb.b	81-(*-Dir4),0

ObjDir:			dc.b	"LASERMAX:Asm/"
			dcb.b	81-(*-ObjDir),0

Filename:		dc.b	"LASERMAX"
			dcb.b	41-(*-Filename),0

Filename2:		dc.b	"NoName"
			dcb.b	41-(*-Filename2),0

Filename3:		dc.b	"LASERMAX"
			dcb.b	41-(*-Filename3),0

Filename4:		dc.b	"NoName"
			dcb.b	41-(*-Filename4),0

Filename5:		dc.b	"Basic"
			dcb.b	41-(*-Filename5),0

Filename6:		dc.b	"LASERMAX.config"
			dcb.b	41-(*-Filename6),0

Filename7:		dc.b	"NoName.config"
			dcb.b	41-(*-Filename7),0

Filename8:		dc.b	"NoName"
			dcb.b	41-(*-Filename8),0

Filename9:		dc.b	"NoName.ild"
			dcb.b	45-(*-Filename9),0

Filename10:		dc.b	"NoName.ild"
			dcb.b	41-(*-Filename10),0

ObjFilename:		dc.b	"Wym.object"
			dcb.b	41-(*-ObjFilename),0

ConfigFilename:		dc.b	"S:LASERMAX.config",0

StartSeqFilename:	dc.b	"StartSequence",0

EditFilename:		dc.b	"RAM:LASERMAXSequence",0
EditFilename2:		dc.b	"RAM:LASERMAXOutput",0

TestPatternFilename:	dc.b	"LASERMAX:Screens/HiSpeed/TestPattern"
			dcb.b	122-(*-TestPatternFilename),0

DefaultFilename:	dc.b	"NoName",0
DefaultFilename2:	dc.b	"NONAME",0
ILDAFilenameEnd:	dc.b	".ild",0

Preset1Filename:	dcb.b	41,0
Preset2Filename:	dcb.b	41,0
Preset3Filename:	dcb.b	41,0
Preset4Filename:	dcb.b	41,0
Preset5Filename:	dcb.b	41,0
Preset6Filename:	dcb.b	41,0
Preset7Filename:	dcb.b	41,0
Preset8Filename:	dcb.b	41,0
Preset9Filename:	dcb.b	41,0
Preset10Filename:	dcb.b	41,0

Preset11Filename:	dcb.b	41,0
Preset12Filename:	dcb.b	41,0
Preset13Filename:	dcb.b	41,0
Preset14Filename:	dcb.b	41,0
Preset15Filename:	dcb.b	41,0
Preset16Filename:	dcb.b	41,0
Preset17Filename:	dcb.b	41,0
Preset18Filename:	dcb.b	41,0
Preset19Filename:	dcb.b	41,0
Preset20Filename:	dcb.b	41,0

Preset21Filename:	dcb.b	41,0
Preset22Filename:	dcb.b	41,0
Preset23Filename:	dcb.b	41,0
Preset24Filename:	dcb.b	41,0
Preset25Filename:	dcb.b	41,0
Preset26Filename:	dcb.b	41,0
Preset27Filename:	dcb.b	41,0
Preset28Filename:	dcb.b	41,0
Preset29Filename:	dcb.b	41,0
Preset30Filename:	dcb.b	41,0

Preset31Filename:	dcb.b	41,0
Preset32Filename:	dcb.b	41,0
Preset33Filename:	dcb.b	41,0
Preset34Filename:	dcb.b	41,0
Preset35Filename:	dcb.b	41,0
Preset36Filename:	dcb.b	41,0
Preset37Filename:	dcb.b	41,0
Preset38Filename:	dcb.b	41,0
Preset39Filename:	dcb.b	41,0
Preset40Filename:	dcb.b	41,0

Sequence1Filename:	dcb.b	41,0
Sequence2Filename:	dcb.b	41,0
Sequence3Filename:	dcb.b	41,0
Sequence4Filename:	dcb.b	41,0
Sequence5Filename:	dcb.b	41,0
Sequence6Filename:	dcb.b	41,0
Sequence7Filename:	dcb.b	41,0
Sequence8Filename:	dcb.b	41,0
Sequence9Filename:	dcb.b	41,0
Sequence10Filename:	dcb.b	41,0
Sequence11Filename:	dcb.b	41,0
Sequence12Filename:	dcb.b	41,0

Sequence13Filename:	dcb.b	41,0
Sequence14Filename:	dcb.b	41,0
Sequence15Filename:	dcb.b	41,0
Sequence16Filename:	dcb.b	41,0
Sequence17Filename:	dcb.b	41,0
Sequence18Filename:	dcb.b	41,0
Sequence19Filename:	dcb.b	41,0
Sequence20Filename:	dcb.b	41,0

Sequence21Filename:	dcb.b	41,0
Sequence22Filename:	dcb.b	41,0
Sequence23Filename:	dcb.b	41,0
Sequence24Filename:	dcb.b	41,0
Sequence25Filename:	dcb.b	41,0
Sequence26Filename:	dcb.b	41,0
Sequence27Filename:	dcb.b	41,0
Sequence28Filename:	dcb.b	41,0

Sequence29Filename:	dcb.b	41,0
Sequence30Filename:	dcb.b	41,0
Sequence31Filename:	dcb.b	41,0
Sequence32Filename:	dcb.b	41,0
Sequence33Filename:	dcb.b	41,0
Sequence34Filename:	dcb.b	41,0
Sequence35Filename:	dcb.b	41,0
Sequence36Filename:	dcb.b	41,0

Sequence37Filename:	dcb.b	41,0
Sequence38Filename:	dcb.b	41,0
Sequence39Filename:	dcb.b	41,0
Sequence40Filename:	dcb.b	41,0
Sequence41Filename:	dcb.b	41,0
Sequence42Filename:	dcb.b	41,0
Sequence43Filename:	dcb.b	41,0
Sequence44Filename:	dcb.b	41,0

Sequence45Filename:	dcb.b	41,0
Sequence46Filename:	dcb.b	41,0
Sequence47Filename:	dcb.b	41,0
Sequence48Filename:	dcb.b	41,0
Sequence49Filename:	dcb.b	41,0
Sequence50Filename:	dcb.b	41,0
Sequence51Filename:	dcb.b	41,0
Sequence52Filename:	dcb.b	41,0

Sequence53Filename:	dcb.b	41,0
Sequence54Filename:	dcb.b	41,0
Sequence55Filename:	dcb.b	41,0
Sequence56Filename:	dcb.b	41,0
Sequence57Filename:	dcb.b	41,0
Sequence58Filename:	dcb.b	41,0
Sequence59Filename:	dcb.b	41,0
Sequence60Filename:	dcb.b	41,0

Sequence61Filename:	dcb.b	41,0
Sequence62Filename:	dcb.b	41,0
Sequence63Filename:	dcb.b	41,0
Sequence64Filename:	dcb.b	41,0
Sequence65Filename:	dcb.b	41,0
Sequence66Filename:	dcb.b	41,0
Sequence67Filename:	dcb.b	41,0
Sequence68Filename:	dcb.b	41,0

Sequence69Filename:	dcb.b	41,0
Sequence70Filename:	dcb.b	41,0
Sequence71Filename:	dcb.b	41,0
Sequence72Filename:	dcb.b	41,0
Sequence73Filename:	dcb.b	41,0
Sequence74Filename:	dcb.b	41,0
Sequence75Filename:	dcb.b	41,0
Sequence76Filename:	dcb.b	41,0

Sequence77Filename:	dcb.b	41,0
Sequence78Filename:	dcb.b	41,0
Sequence79Filename:	dcb.b	41,0
Sequence80Filename:	dcb.b	41,0
Sequence81Filename:	dcb.b	41,0
Sequence82Filename:	dcb.b	41,0
Sequence83Filename:	dcb.b	41,0
Sequence84Filename:	dcb.b	41,0

Sequence85Filename:	dcb.b	41,0
Sequence86Filename:	dcb.b	41,0
Sequence87Filename:	dcb.b	41,0
Sequence88Filename:	dcb.b	41,0
Sequence89Filename:	dcb.b	41,0
Sequence90Filename:	dcb.b	41,0
Sequence91Filename:	dcb.b	41,0
Sequence92Filename:	dcb.b	41,0

Sequence93Filename:	dcb.b	41,0
Sequence94Filename:	dcb.b	41,0
Sequence95Filename:	dcb.b	41,0
Sequence96Filename:	dcb.b	41,0
Sequence97Filename:	dcb.b	41,0
Sequence98Filename:	dcb.b	41,0
Sequence99Filename:	dcb.b	41,0
Sequence100Filename:	dcb.b	41,0

Sequence101Filename:	dcb.b	41,0
Sequence102Filename:	dcb.b	41,0
Sequence103Filename:	dcb.b	41,0
Sequence104Filename:	dcb.b	41,0
Sequence105Filename:	dcb.b	41,0
Sequence106Filename:	dcb.b	41,0
Sequence107Filename:	dcb.b	41,0
Sequence108Filename:	dcb.b	41,0

Sequence109Filename:	dcb.b	41,0
Sequence110Filename:	dcb.b	41,0
Sequence111Filename:	dcb.b	41,0
Sequence112Filename:	dcb.b	41,0
Sequence113Filename:	dcb.b	41,0
Sequence114Filename:	dcb.b	41,0
Sequence115Filename:	dcb.b	41,0
Sequence116Filename:	dcb.b	41,0

Sequence117Filename:	dcb.b	41,0
Sequence118Filename:	dcb.b	41,0
Sequence119Filename:	dcb.b	41,0
Sequence120Filename:	dcb.b	41,0
Sequence121Filename:	dcb.b	41,0
Sequence122Filename:	dcb.b	41,0
Sequence123Filename:	dcb.b	41,0
Sequence124Filename:	dcb.b	41,0

Sequence125Filename:	dcb.b	41,0
Sequence126Filename:	dcb.b	41,0
Sequence127Filename:	dcb.b	41,0
Sequence128Filename:	dcb.b	41,0
Sequence129Filename:	dcb.b	41,0
Sequence130Filename:	dcb.b	41,0
Sequence131Filename:	dcb.b	41,0
Sequence132Filename:	dcb.b	41,0

Sequence133Filename:	dcb.b	41,0
Sequence134Filename:	dcb.b	41,0
Sequence135Filename:	dcb.b	41,0
Sequence136Filename:	dcb.b	41,0
Sequence137Filename:	dcb.b	41,0
Sequence138Filename:	dcb.b	41,0
Sequence139Filename:	dcb.b	41,0
Sequence140Filename:	dcb.b	41,0

Sequence141Filename:	dcb.b	41,0
Sequence142Filename:	dcb.b	41,0
Sequence143Filename:	dcb.b	41,0
Sequence144Filename:	dcb.b	41,0
Sequence145Filename:	dcb.b	41,0
Sequence146Filename:	dcb.b	41,0
Sequence147Filename:	dcb.b	41,0
Sequence148Filename:	dcb.b	41,0

Sequence149Filename:	dcb.b	41,0
Sequence150Filename:	dcb.b	41,0
Sequence151Filename:	dcb.b	41,0
Sequence152Filename:	dcb.b	41,0
Sequence153Filename:	dcb.b	41,0
Sequence154Filename:	dcb.b	41,0
Sequence155Filename:	dcb.b	41,0
Sequence156Filename:	dcb.b	41,0

Sequence157Filename:	dcb.b	41,0
Sequence158Filename:	dcb.b	41,0
Sequence159Filename:	dcb.b	41,0
Sequence160Filename:	dcb.b	41,0
Sequence161Filename:	dcb.b	41,0
Sequence162Filename:	dcb.b	41,0
Sequence163Filename:	dcb.b	41,0
Sequence164Filename:	dcb.b	41,0

Sequence165Filename:	dcb.b	41,0
Sequence166Filename:	dcb.b	41,0
Sequence167Filename:	dcb.b	41,0
Sequence168Filename:	dcb.b	41,0
Sequence169Filename:	dcb.b	41,0
Sequence170Filename:	dcb.b	41,0
Sequence171Filename:	dcb.b	41,0
Sequence172Filename:	dcb.b	41,0

Sequence173Filename:	dcb.b	41,0
Sequence174Filename:	dcb.b	41,0
Sequence175Filename:	dcb.b	41,0
Sequence176Filename:	dcb.b	41,0
Sequence177Filename:	dcb.b	41,0
Sequence178Filename:	dcb.b	41,0
Sequence179Filename:	dcb.b	41,0
Sequence180Filename:	dcb.b	41,0

Sequence181Filename:	dcb.b	41,0
Sequence182Filename:	dcb.b	41,0
Sequence183Filename:	dcb.b	41,0
Sequence184Filename:	dcb.b	41,0
Sequence185Filename:	dcb.b	41,0
Sequence186Filename:	dcb.b	41,0
Sequence187Filename:	dcb.b	41,0
Sequence188Filename:	dcb.b	41,0

Sequence189Filename:	dcb.b	41,0
Sequence190Filename:	dcb.b	41,0
Sequence191Filename:	dcb.b	41,0
Sequence192Filename:	dcb.b	41,0
Sequence193Filename:	dcb.b	41,0
Sequence194Filename:	dcb.b	41,0
Sequence195Filename:	dcb.b	41,0
Sequence196Filename:	dcb.b	41,0

Sequence197Filename:	dcb.b	41,0
Sequence198Filename:	dcb.b	41,0
Sequence199Filename:	dcb.b	41,0
Sequence200Filename:	dcb.b	41,0
Sequence201Filename:	dcb.b	41,0
Sequence202Filename:	dcb.b	41,0
Sequence203Filename:	dcb.b	41,0
Sequence204Filename:	dcb.b	41,0

Sequence205Filename:	dcb.b	41,0
Sequence206Filename:	dcb.b	41,0
Sequence207Filename:	dcb.b	41,0
Sequence208Filename:	dcb.b	41,0
Sequence209Filename:	dcb.b	41,0
Sequence210Filename:	dcb.b	41,0
Sequence211Filename:	dcb.b	41,0
Sequence212Filename:	dcb.b	41,0

Sequence213Filename:	dcb.b	41,0
Sequence214Filename:	dcb.b	41,0
Sequence215Filename:	dcb.b	41,0
Sequence216Filename:	dcb.b	41,0
Sequence217Filename:	dcb.b	41,0
Sequence218Filename:	dcb.b	41,0
Sequence219Filename:	dcb.b	41,0
Sequence220Filename:	dcb.b	41,0

Sequence221Filename:	dcb.b	41,0
Sequence222Filename:	dcb.b	41,0
Sequence223Filename:	dcb.b	41,0
Sequence224Filename:	dcb.b	41,0
Sequence225Filename:	dcb.b	41,0
Sequence226Filename:	dcb.b	41,0
Sequence227Filename:	dcb.b	41,0
Sequence228Filename:	dcb.b	41,0

Sequence229Filename:	dcb.b	41,0
Sequence230Filename:	dcb.b	41,0
Sequence231Filename:	dcb.b	41,0
Sequence232Filename:	dcb.b	41,0
Sequence233Filename:	dcb.b	41,0
Sequence234Filename:	dcb.b	41,0
Sequence235Filename:	dcb.b	41,0
Sequence236Filename:	dcb.b	41,0

Sequence237Filename:	dcb.b	41,0
Sequence238Filename:	dcb.b	41,0
Sequence239Filename:	dcb.b	41,0
Sequence240Filename:	dcb.b	41,0
Sequence241Filename:	dcb.b	41,0
Sequence242Filename:	dcb.b	41,0
Sequence243Filename:	dcb.b	41,0
Sequence244Filename:	dcb.b	41,0

Sequence245Filename:	dcb.b	41,0
Sequence246Filename:	dcb.b	41,0
Sequence247Filename:	dcb.b	41,0
Sequence248Filename:	dcb.b	41,0
Sequence249Filename:	dcb.b	41,0
Sequence250Filename:	dcb.b	41,0
Sequence251Filename:	dcb.b	41,0
Sequence252Filename:	dcb.b	41,0

Sequence253Filename:	dcb.b	41,0
Sequence254Filename:	dcb.b	41,0
Sequence255Filename:	dcb.b	41,0
Sequence256Filename:	dcb.b	41,0
Sequence257Filename:	dcb.b	41,0
Sequence258Filename:	dcb.b	41,0
Sequence259Filename:	dcb.b	41,0
Sequence260Filename:	dcb.b	41,0

Sequence261Filename:	dcb.b	41,0
Sequence262Filename:	dcb.b	41,0
Sequence263Filename:	dcb.b	41,0
Sequence264Filename:	dcb.b	41,0
Sequence265Filename:	dcb.b	41,0
Sequence266Filename:	dcb.b	41,0
Sequence267Filename:	dcb.b	41,0
Sequence268Filename:	dcb.b	41,0

Sequence269Filename:	dcb.b	41,0
Sequence270Filename:	dcb.b	41,0
Sequence271Filename:	dcb.b	41,0
Sequence272Filename:	dcb.b	41,0
Sequence273Filename:	dcb.b	41,0
Sequence274Filename:	dcb.b	41,0
Sequence275Filename:	dcb.b	41,0
Sequence276Filename:	dcb.b	41,0

Sequence277Filename:	dcb.b	41,0
Sequence278Filename:	dcb.b	41,0
Sequence279Filename:	dcb.b	41,0
Sequence280Filename:	dcb.b	41,0
Sequence281Filename:	dcb.b	41,0
Sequence282Filename:	dcb.b	41,0
Sequence283Filename:	dcb.b	41,0
Sequence284Filename:	dcb.b	41,0

Sequence285Filename:	dcb.b	41,0
Sequence286Filename:	dcb.b	41,0
Sequence287Filename:	dcb.b	41,0
Sequence288Filename:	dcb.b	41,0
Sequence289Filename:	dcb.b	41,0
Sequence290Filename:	dcb.b	41,0
Sequence291Filename:	dcb.b	41,0
Sequence292Filename:	dcb.b	41,0

Sequence293Filename:	dcb.b	41,0
Sequence294Filename:	dcb.b	41,0
Sequence295Filename:	dcb.b	41,0
Sequence296Filename:	dcb.b	41,0
Sequence297Filename:	dcb.b	41,0
Sequence298Filename:	dcb.b	41,0
Sequence299Filename:	dcb.b	41,0
Sequence300Filename:	dcb.b	41,0

Sequence301Filename:	dcb.b	41,0
Sequence302Filename:	dcb.b	41,0
Sequence303Filename:	dcb.b	41,0
Sequence304Filename:	dcb.b	41,0
Sequence305Filename:	dcb.b	41,0
Sequence306Filename:	dcb.b	41,0
Sequence307Filename:	dcb.b	41,0
Sequence308Filename:	dcb.b	41,0

Sequence309Filename:	dcb.b	41,0
Sequence310Filename:	dcb.b	41,0
Sequence311Filename:	dcb.b	41,0
Sequence312Filename:	dcb.b	41,0
Sequence313Filename:	dcb.b	41,0
Sequence314Filename:	dcb.b	41,0
Sequence315Filename:	dcb.b	41,0
Sequence316Filename:	dcb.b	41,0

Sequence317Filename:	dcb.b	41,0
Sequence318Filename:	dcb.b	41,0
Sequence319Filename:	dcb.b	41,0
Sequence320Filename:	dcb.b	41,0
Sequence321Filename:	dcb.b	41,0
Sequence322Filename:	dcb.b	41,0
Sequence323Filename:	dcb.b	41,0
Sequence324Filename:	dcb.b	41,0

Sequence325Filename:	dcb.b	41,0
Sequence326Filename:	dcb.b	41,0
Sequence327Filename:	dcb.b	41,0
Sequence328Filename:	dcb.b	41,0
Sequence329Filename:	dcb.b	41,0
Sequence330Filename:	dcb.b	41,0
Sequence331Filename:	dcb.b	41,0
Sequence332Filename:	dcb.b	41,0


;Screen file header space:

			even
ScreenHeader:		dc.b	"LASERMAX screen v1.00",0
			dcb.b	40,0

PackHeader:		dc.b	"LASERMAX pack v1.00",0
			dcb.b	44,0

ILDALastHeader:		dc.b	"ILDA",0,0,0,0,"                ",0,0,0,0,0,1,0,0


;LASERfIRE data header:

			even
LASERfIREHeader:		dc.l	0
			dc.l	0


;THE ASCII buffer space:

ASCIIBuffer:		dcb.b	300,0

ValueASCII:		dcb.b	11,0

ILDAName:		dcb.b	9,0
ILDACompany:		dcb.b	9,0

ILDAName2:		dcb.b	17,0

X29Name:		dcb.b	20,0


;Space for record buffer:

RecordBuff:		dcb.b	200,0
RecordBuff2:		dcb.b	300,0


;File requester text:

LoadReqText:		dc.b	"Load",0
SaveReqText:		dc.b	"Save",0
DeleteReqText:		dc.b	"Delete",0
SendReqText:		dc.b	"Send",0
MergeReqText:		dc.b	"Merge",0
AppendReqText:		dc.b	"Append",0


;Command text:

EchoCmd:		dc.b	'ECHO "',0
MoveCmd:		dc.b	"MOVE ",0
LCCmd:			dc.b	"LC ",0
WaitCmd:		dc.b	"WAIT ",0
WaitMoveCmd:		dc.b	"WAITMOVE",0
ScreenCmd:		dc.b	'LOADSCREEN "',0
ScreenCmd2:		dc.b	'LOADSCREEN2 "',0
DrawScreenCmd:		dc.b	'DRAWSCREEN "',0
DrawScreenCmd2:		dc.b	'DRAWSCREEN2 "',0
MorphScreenCmd:		dc.b	'MORPHSCREEN "',0
MorphScreenCmd2:	dc.b	'MORPHSCREEN2 "',0
PreloadCmd:		dc.b	"PRELOAD",0
PreloadCmd2:		dc.b	"CREEN",0
LoadPackCmd:		dc.b	'LOADPACK "',0
ShutterCmd:		dc.b	"SHUTTERON",0
Shutter2Cmd:		dc.b	"SHUTTEROFF",0
StandbyCmd:		dc.b	"STANDBYON",0
Standby2Cmd:		dc.b	"STANDBYOFF",0
FastMoveCmd:		dc.b	"FASTMOVEON",0
FastMove2Cmd:		dc.b	"FASTMOVEOFF",0
StrobeCmd:		dc.b	"STROBEON",0
Strobe2Cmd:		dc.b	"STROBEOFF",0
ReplayCmd:		dc.b	"REPLAY",0
NextCmd:		dc.b	"NEXT",0
UnitCmd:		dc.b	"TALKTOUNIT ",0
ColourCmd:		dc.b	"COLOUR ",0
FXCmd:			dc.b	"FX ",0
SerialCmd:		dc.b	"SERIAL ",0
PresetCmd2:		dc.b	"PRESET",0
UseDefCmd:		dc.b	"USESCREENDEF",0
SmoothChgCmd2:		dc.b	"SMOOTHCHANGE",0
StopCmd:		dc.b	"STOP",0

SetTrackCmd:		dc.b	"TRACK ",0
SizeXCmd:		dc.b	"SIZEX ",0
SizeYCmd:		dc.b	"SIZEY ",0
RotateXYCmd:		dc.b	"ROTATE ",0
SpinXCmd:		dc.b	"SPINX ",0
SpinYCmd:		dc.b	"SPINY ",0
RollXCmd:		dc.b	"ROLLX ",0
RollYCmd:		dc.b	"ROLLY ",0
DisolveScreenCmd:	dc.b	'DISSOLVESCREEN "',0
DisolveScreenCmd2:	dc.b	'DISSOLVESCREEN2 "',0
WaitASCmd:		dc.b	"WAITA ",0
FactoryLfCmd:		dc.b	"FACTORY ",0
FactoryLfCmd2:		dc.b	"FACTORYALL",0

EchoCmd2:		dc.b	$a,$a,'Echo "',0
MoveCmd2:		dc.b	$a,$a,"Move ",0
LCCmd2:			dc.b	$a,"LC ",0
WaitCmd2:		dc.b	$a,"Wait ",0
ScreenCmd3:		dc.b	$a,'LoadScreen "',0
ScreenCmd4:		dc.b	$a,'LoadScreen2 "',0
MorphScreenCmd3:	dc.b	$a,'MorphScreen "',0
MorphScreenCmd4:	dc.b	$a,'MorphScreen2 "',0
DrawScreenCmd3:		dc.b	$a,'DrawScreen "',0
DrawScreenCmd4:		dc.b	$a,'DrawScreen2 "',0
ShutterCmd2:		dc.b	$a,"ShutterOn",0
Shutter2Cmd2:		dc.b	$a,"ShutterOff",0
StandbyCmd2:		dc.b	$a,"StandbyOn",0
Standby2Cmd2:		dc.b	$a,"StandbyOff",0
FastMoveCmd2:		dc.b	$a,"FastMoveOn",0
FastMove2Cmd2:		dc.b	$a,"FastMoveOff",0
StrobeCmd2:		dc.b	$a,"StrobeOn",0
Strobe2Cmd2:		dc.b	$a,"StrobeOff",0

LoadSeqCmd:		dc.b	"LOADSEQ",0
LoadScrCmd:		dc.b	"LOADSCR",0
SwapCmd:		dc.b	"SWAP",0
APreldCmd:		dc.b	"AUTOPRELOAD",0
FastScpCmd:		dc.b	"FASTSCOPE",0
InvXCmd:		dc.b	"INVERTX",0
InvYCmd:		dc.b	"INVERTY",0
DrScopeOffCmd:		dc.b	"DRAWSCOPEOFF",0
DMACmd:			dc.b	"DMAOUTPUT",0
IconifyCmd:		dc.b	"ICONIFY",0
BigScrCmd:		dc.b	"BIGSCREENOFF",0
FltCmd:			dc.b	"FILTER",0
DirectCmd:		dc.b	"DIRECTWRITE",0
NoSerCmd:		dc.b	"NOSERIAL",0
SetAPCmd:		dc.b	"SETAUTOPOINTS ",0
SetPatCmd:		dc.b	"SETPATSIZE ",0
SetPatCmd2:		dc.b	"SETPATPOINTS ",0
SetHiRCmd:		dc.b	"SETHIRESXSIZE ",0
SetHiRCmd2:		dc.b	"SETHIRESYSIZE ",0
SetOutCmd:		dc.b	"SETOUTPUTXSIZE ",0
SetOutCmd2:		dc.b	"SETOUTPUTYSIZE ",0
UndoCmd:		dc.b	"SETMAXUNDOS ",0
StopDlyCmd:		dc.b	"SETSTOPDELAY ",0
SetPresetCmd:		dc.b	"SETPRESET",0
SetSeqDirCmd:		dc.b	'SETSEQDIR "',0
SetScrDirCmd:		dc.b	'SETSCRDIR "',0
SetFontDirCmd:		dc.b	'SETFONTDIR "',0
SetConfigDirCmd:	dc.b	'SETCONFIGDIR "',0
SetEditCmdCmd:		dc.b	'SETEDITCMD "',0
SetTestPatCmd:		dc.b	'SETTESTPAT "',0
AutoAttachCmd:		dc.b	"AUTOATTACH",0
DrawBetweenCmd:		dc.b	"DRAWBTWPOINTS",0
SmoothChgCmd:		dc.b	"SMOOTHCHANGE",0
NoDragCmd:		dc.b	"NODRAWDRAG",0
MaxPPSCmd:		dc.b	"MAXPNTPERSEC ",0
MasterCmd:		dc.b	"MASTER",0
SlaveCmd:		dc.b	"SLAVE",0
SetDefXSizeCmd:		dc.b	"SETSCRDEFXSIZE",0
SetDefYSizeCmd:		dc.b	"SETSCRDEFYSIZE",0
SetDefXPosCmd:		dc.b	"SETSCRDEFXPOS",0
SetDefYPosCmd:		dc.b	"SETSCRDEFYPOS",0
SetLASERfIRECmd:		dc.b	"SETLASERFIRE",0

LoadSeqCmd2:		dc.b	$a,"LoadSeq",0
LoadScrCmd2:		dc.b	$a,"LoadScr",0
SetPresetCmd2:		dc.b	$a,"SetPreset",0

EditCmd:		dc.b	"C:Ed RAM:LASERMAXSequence"
			dcb.b	122-(*-EditCmd),0

AutoSeqText:		dc.b	";LASERMAX auto sequence"
			dc.b	$a,$a,';LoadPack "',0

AutoSeqTexta:		dc.b	'"',$a,$a,"Preload"
			dc.b	$a,$a,";SmoothChange"
			dc.b	$a,$a,"UseScreenDef1"
			dc.b	$a,$a,"Replay:"
			dc.b	$a,$a,'Echo "',0

AutoSeqTextb:		dc.b	'..."',0

AutoSeqText2:		dc.b	$a,$a,'LoadScreen "',0
AutoSeqText3:		dc.b	'"',$a,"Wait 4",0


;File ID strings:

ScreenString:		dc.b	"LASERMAX SCREEN V1.00",0
PackString:		dc.b	"LASERMAX PACK V1.00",0
FontString:		dc.b	"LASERMAX FONT V1.00",0

FireFlyString:		dc.b	"IMAGE.V1",0
FireFlyString2:		dc.b	"PACK.V1 ",0
ScanPicString:		dc.b	"PICTURE 1.20",0
ILDAFrameString:	dc.b	"ILDA",0
LD400FrameString:	dc.b	"LAZR",0
LDProFrameString:	dc.b	"PANGOLINOBJECT1)",0

ConfigString:		dc.b	".CONFIG",0


;Window text:

VolText:		dc.b	"Vol: ",0
VolText2:		dc.b	"Roto:",0
FreqText:		dc.b	"Freq:",0
FreqText2:		dc.b	"Spin:",0
FreqText3:		dc.b	"Perd:",0
FreqText4:		dc.b	"Pt/s:",0
ViewWTitle:		dc.b    'Sequence view: "'
			dcb.b	42,0


;Status text:

ManText:		dc.b	"(Man) ",0
PlayText:		dc.b	"(Play) ",0
PauseText:		dc.b	"(Paus) ",0
RecText:		dc.b	"(Rec) ",0

CheckLaser:		dc.b	"Looking for LASER...",0
CheckLaserOK:		dc.b	"LASER ready",0
CheckLaserBad:		dc.b	"No response from LASER!",0

CheckLaser2:		dc.b	"Looking for LASERfIRE...",0
CheckLaserOK2:		dc.b	"LASERfIRE ready",0
CheckLaserBad2:		dc.b	"No response from LASERfIRE!",0

StatusConfig:		dc.b	"Reading configuration",0
StatusLoad:		dc.b	"Loading...",0
StatusLoad2:		dc.b	"Loading screen...",0
StatusReady:		dc.b	"Sequence ready",0
StatusReady2:		dc.b	"Screen ready",0
StatusReady3:		dc.b	"Font ready",0
StatusReady4:		dc.b	"Imported FireFly image",0
StatusReady4a:		dc.b	"Imported Aquarius gframe",0
StatusReady4b:		dc.b	"Imported ScanPlus picture",0
StatusReady4c:		dc.b	"Imported LSD1000 frame",0
StatusReady4d:		dc.b	"Imported ILDA frame",0
StatusReady4e:		dc.b	"Imported X29 frame",0
StatusReady4f:		dc.b	"Imported Aura pic",0
StatusReady4g:		dc.b	"Imported LD400 frame",0
StatusReady4h:		dc.b	"Imported LD frame",0
StatusReady5:		dc.b	") Screen merged",0
StatusSave:		dc.b	"Saving sequence...",0
StatusSave2:		dc.b	"Saving screen...",0
StatusSave3:		dc.b	"Import & saving #: ",0
StatusSave3a:		dc.b	"Import & saving: ",0
StatusSave3b:		dc.b	"Saving screen: ",0
StatusSave3c:		dc.b	"Unpacking scrn: ",0
StatusSave4:		dc.b	"Saving configuration...",0
StatusSave6:		dc.b	"No screens in this sequence!",0
StatusSave7:		dc.b	"Saving scrn in ILDA format...",0
StatusDelete:		dc.b	"Deleting file...",0
StatusClear:		dc.b	"Sequenced removed",0
StatusClear2:		dc.b	"Screen removed",0
StatusClear3:		dc.b	"Nothing to clear!",0
StatusRecord:		dc.b	"Recording sequence...",0
StatusRecord2:		dc.b	"Adding to sequence...",0
StatusStart:		dc.b	"Playing:                     ",0
StatusScreen:		dc.b	"Screen:                      ",0
StatusPreload:		dc.b	"Preload:                     ",0
StatusStop:		dc.b	"Sequence stopped",0
StatusAutoStop:		dc.b	"Auto stopped sequence!",0
StatusPause:		dc.b	"Sequence paused...",0
StatusCenter:		dc.b	"LASER centered",0
StatusCenter2:		dc.b	"No change!",0
StatusAttach:		dc.b	"Select gadget or scrn def...",0
StatusAttach2:		dc.b	"Lissajous & position attached",0
StatusAttach3:		dc.b	"Sequence attached",0
StatusAttach4:		dc.b	"Screen & position attached",0
StatusAttach5:		dc.b	"Position attached",0
StatusReset:		dc.b	"Resetting LASER...",0
StatusRead:		dc.b	"Reading...",0
StatusCentered:		dc.b	"Already centered!",0
StatusDraw:		dc.b	"Draw mode...",0
StatusText:		dc.b	") Text",0
StatusLine:		dc.b	") Line",0
StatusArc:		dc.b	") Arc",0
StatusArc2:		dc.b	") Arc II",0
StatusBox:		dc.b	") Box",0
StatusEllipse:		dc.b	") Ellipse",0
StatusArrowKeys:	dc.b	") Use arrow keys...",0
StatusPointsCentered:	dc.b	") Points centered",0
StatusPointsCentered2:	dc.b	"Points already centered!",0
StatusRollPoints:	dc.b	") Roll: ",0
StatusResize:		dc.b	") Points resized",0
StatusRotate:		dc.b	") Rotated points ",0
StatusRotate2:		dc.b	") X axis spin ",0
StatusRotate3:		dc.b	") Y axis spin ",0
StatusRotate4:		dc.b	") Rotate/Spin center set",0
StatusRotate5:		dc.b	") Clk centr/Use arrow keys",0
StatusFlipX:		dc.b	") X axis flipped",0
StatusFlipY:		dc.b	") Y axis flipped",0
StatusFlipZ:		dc.b	") Z axis flipped",0
StatusAddPoints:	dc.b	") Points added",0
StatusSubPoints:	dc.b	") Points subtracted",0
StatusSmoothPoints:	dc.b	") Density smoothed",0
StatusWeightPoints:	dc.b	") Weight added",0
StatusRemFirst:		dc.b	") First point removed",0
StatusRemLast:		dc.b	") Last point removed",0
StatusInsertPoint:	dc.b	") Insert point...",0
StatusInsertPoint2:	dc.b	") Point inserted",0
StatusInsertPoint3:	dc.b	") Clk pnt to insert after...",0
StatusInsertPoint4:	dc.b	") That is the last point!",0
StatusDeletePoint:	dc.b	") Click point to delete...",0
StatusDeletePoint2:	dc.b	") Point deleted",0
StatusMovePoint:	dc.b	") Click point to move...",0
StatusMovePoint2:	dc.b	") Point moved",0
StatusUndo:		dc.b	") Undo changes",0
StatusUndo2:		dc.b	"Last undo",0
StatusUndo3:		dc.b	") Redo changes",0
StatusUndo4:		dc.b	"Last redo",0
StatusUndo5:		dc.b	"Nothing in undo buffer!",0
StatusMorph:		dc.b	"Select morph to screen...",0
StatusMorph2:		dc.b	"Morph:                       ",0
StatusDrawScreen:	dc.b	"Select screen to draw...",0
StatusDrawScreen2:	dc.b	"Draw:                        ",0
StatusWelcome:		dc.b	"Welcome back to LASERMAX!",0
StatusProcessing:	dc.b	"Processing...",0
StatusLoadPack:		dc.b	"Loading pack...",0
StatusBent:		dc.b	") Points bent",0
StatusRecSeq:		dc.b	"Rec seq: ",0
StatusScrDefSet:	dc.b	"Screen default set",0
StatusLASERfIRE:		dc.b	"Dnlding: ",0
StatusLASERfIRE2:	dc.b	"Processing data...",0
StatusBlank:		dc.b	" ",0

Error1Text:		dc.b	"Syntax error!",0
Error2Text:		dc.b	"Value out of range!",0
Error3Text:		dc.b	"Can't allocate memory!",0
Error4Text:		dc.b	"Can't load file!",0
Error5Text:		dc.b	"Can't save file!",0
Error6Text:		dc.b	"No sequence to save!",0
Error7Text:		dc.b	"No sequence in memory!",0
Error8Text:		dc.b	"Not playing sequence!",0
Error9Text:		dc.b	"No sequence attached!",0
Error10Text:		dc.b	"Communication error!",0
Error12Text:		dc.b	"Bad checksum!",0
Error13Text:		dc.b	"Bad config file!",0
Error14Text:		dc.b	"Can't load sequence!",0
Error16Text:		dc.b	"Too few points!",0
Error17Text:		dc.b	"Not a screen file!",0
Error18Text:		dc.b	"Can't load screen!",0
Error19Text:		dc.b	"Can't load font!",0
Error20Text:		dc.b	"Not a font file!",0
Error21Text:		dc.b	"I can't handle regions yet!",0
Error22Text:		dc.b	"Too many points!",0
Error23Text:		dc.b	"reqtools.library?!?",0
Error24Text:		dc.b	"No screen attached!",0
Error25Text:		dc.b	"Can't load pack!",0
Error26Text:		dc.b	"Not a pack file!",0
Error27Text:		dc.b	"Turn on 3D mode first!",0
Error28Text:		dc.b	"Bad file or unknown format!",0
Error29Text:		dc.b	"Can't load screen! Unpacked?",0
Error30Text:		dc.b	"Can't load test pattern scrn!",0
Error31Text:		dc.b	"LASERfIRE sequence to large!",0

PosText:		dc.b	"Position: X=",0
PosText2:		dc.b	", Y=",0

MousePosText:		dc.b	") X=",0
MousePosText2:		dc.b	", Y=",0
MousePosText3:		dc.b	", Z=",0

EllipsePosText:		dc.b	") X=",0
EllipsePosText2:	dc.b	", Y=",0
EllipsePosText3:	dc.b	", Z=",0
EllipseSizeText:	dc.b	" r=",0

ShiftPosText:		dc.b	") Shift: X=",0
ShiftPosText2:		dc.b	", Y=",0
ShiftPosText3:		dc.b	", Z=",0

SizeAdjustText:		dc.b	") Size: X=",0
SizeAdjustText2:	dc.b	"%, Y=",0
SizeAdjustText3:	dc.b	"%, Z=",0

MovePntPosText:		dc.b	") Move: X=",0
MovePntPosText2:	dc.b	", Y=",0
MovePntPosText3:	dc.b	", Z=",0

BytesText:		dc.b	"Xfer bytes: ",0
FinishedText:		dc.b	"Finished! (",0


;Date stamp:

Days:			dc.l	0
Mins:			dc.l	0
Ticks:			dc.l	0


;Time string buffer:

TimeStr:		dcb.b	20,0


;Preset command strings:

Preset1Cmd:		dc.b	"f 1-2p90",0			;Circle
			dcb.b	120-(*-Preset1Cmd),0

Preset2Cmd:		dc.b	"f 1p90 -1v55 2-3v0",0		;Small circle
			dcb.b	120-(*-Preset2Cmd),0

Preset3Cmd:		dc.b	"f 1-2p90 1-2pu20",0		;Mad circle
			dcb.b	120-(*-Preset3Cmd),0

Preset4Cmd:		dc.b	"f 1-2p90 -vd20",0		;Shrink circle
			dcb.b	120-(*-Preset4Cmd),0

Preset5Cmd:		dc.b	"f 1-2p90 -vu20",0		;Expand circle
			dcb.b	120-(*-Preset5Cmd),0

Preset6Cmd:		dc.b	"f 1-2p90 -vs20",0		;Shrink/expand circle
			dcb.b	120-(*-Preset6Cmd),0

Preset7Cmd:		dc.b	"f 1-2p90 2-3f48",0		;Wild circle
			dcb.b	120-(*-Preset7Cmd),0

Preset8Cmd:		dc.b	"f 1-2p90 2-3f45",0		;Target
			dcb.b	120-(*-Preset8Cmd),0

Preset9Cmd:		dc.b	"f 1-2v0",0			;Horiz line
			dcb.b	120-(*-Preset9Cmd),0

Preset10Cmd:		dc.b	"f 0v0 3v0",0			;Vert line
			dcb.b	120-(*-Preset10Cmd),0

Preset11Cmd:		dc.b	"f 1p90 2p270 2-3f48",0		;Clockwise flat
			dcb.b	120-(*-Preset11Cmd),0

Preset12Cmd:		dc.b	"f 1p90 2p270 2-3f52",0		;Anit-clock flat
			dcb.b	120-(*-Preset12Cmd),0

Preset13Cmd:		dc.b	"f 1p90 2p270 2-3f48 -rd20",0	;Wild flat
			dcb.b	120-(*-Preset13Cmd),0

Preset14Cmd:		dc.b	"f 1p90 2p270 2-3f74 -1v30",0	;Clockwise rotating beams
			dcb.b	120-(*-Preset14Cmd),0

Preset15Cmd:		dc.b	"f 1p90 2p270 2-3f76 -1v30",0	;Anti-clock rotating beams
			dcb.b	120-(*-Preset15Cmd),0

Preset16Cmd:		dc.b	"f 1p90 2p270 2-3f60",0		;Thin star
			dcb.b	120-(*-Preset16Cmd),0

Preset17Cmd:		dc.b	"f 1p90 2p270 2-3f75 2-3v35",0	;5 point star
			dcb.b	120-(*-Preset17Cmd),0

Preset18Cmd:		dc.b	"f 1p90 2p270 2-3f84 2-3v30",0	;6 point star
			dcb.b	120-(*-Preset18Cmd),0

Preset19Cmd:		dc.b	"f 1p90 2p270 -1f17 2-3f52",0	;Flower
			dcb.b	120-(*-Preset19Cmd),0

Preset20Cmd:		dc.b	"f 1-2p90 2-3f83",0		;Smoke beams
			dcb.b	120-(*-Preset20Cmd),0

Preset21Cmd:		dc.b	"f 1f51 2f52 3f53",0		;Nice pattern
			dcb.b	120-(*-Preset21Cmd),0

Preset22Cmd:		dc.b	"f 1f51 2-3f61",0		;Mad pattern
			dcb.b	120-(*-Preset22Cmd),0

Preset23Cmd:		dc.b	"f 1f70 2f62 3f61",0		;Wild pattern
			dcb.b	120-(*-Preset23Cmd),0

Preset24Cmd:		dc.b	"f 1f51 2-3fs23",0		;Change mad pattern
			dcb.b	120-(*-Preset24Cmd),0

Preset25Cmd:		dc.b	"f 1-2p90 1f49 2f51",0		;Rocker
			dcb.b	120-(*-Preset25Cmd),0

Preset26Cmd:		dc.b	"f 1p90 2p270 2-3f99 2-3v25",0	;Triangle
			dcb.b	120-(*-Preset26Cmd),0

Preset27Cmd:		dc.b	"0ft100 1ft99 2ft98 3ft97 -fs20",0	;Madness!
			dcb.b	120-(*-Preset27Cmd),0

Preset28Cmd:		dc.b	"f -v0",0			;Dot
			dcb.b	120-(*-Preset28Cmd),0

Preset29Cmd:		dc.b	"f 1p90 2p270 2-3f81 -v7",0	;Mirror ball 1
			dcb.b	120-(*-Preset29Cmd),0

Preset30Cmd:		dc.b	"f 1p90 2p270 2-3f81 -v7",0	;Mirror ball 2
			dcb.b	120-(*-Preset30Cmd),0

Preset31Cmd:		dc.b	"L",0				;Location 1
			dcb.b	120-(*-Preset31Cmd),0

Preset32Cmd:		dc.b	"L",0				;Location 2
			dcb.b	120-(*-Preset32Cmd),0

Preset33Cmd:		dc.b	"L",0				;Location 3
			dcb.b	120-(*-Preset33Cmd),0

Preset34Cmd:		dc.b	"L",0				;Location 4
			dcb.b	120-(*-Preset34Cmd),0

Preset35Cmd:		dc.b	"L",0				;Location 5
			dcb.b	120-(*-Preset35Cmd),0

Preset36Cmd:		dc.b	"L",0				;Location 6
			dcb.b	120-(*-Preset36Cmd),0

Preset37Cmd:		dc.b	"L",0				;Location 7
			dcb.b	120-(*-Preset37Cmd),0

Preset38Cmd:		dc.b	"L",0				;Location 8
			dcb.b	120-(*-Preset38Cmd),0

Preset39Cmd:		dc.b	"L",0				;Location 9
			dcb.b	120-(*-Preset39Cmd),0

Preset40Cmd:		dc.b	"L",0				;Location 10
			dcb.b	120-(*-Preset40Cmd),0

FactoryCmd:		dc.b	"f",0				;Factory reset

Preset1CmdText:		dc.b	"Circle",0
			dcb.b	24-(*-Preset1CmdText),0

Preset2CmdText:		dc.b	"Small circle",0
			dcb.b	24-(*-Preset2CmdText),0

Preset3CmdText:		dc.b	"Mad circle",0
			dcb.b	24-(*-Preset3CmdText),0

Preset4CmdText:		dc.b	"Shrinking circle",0
			dcb.b	24-(*-Preset4CmdText),0

Preset5CmdText:		dc.b	"Expanding circle",0
			dcb.b	24-(*-Preset5CmdText),0

Preset6CmdText:		dc.b	"Shrink/expanding circle",0
			dcb.b	24-(*-Preset6CmdText),0

Preset7CmdText:		dc.b	"Wild circle",0
			dcb.b	24-(*-Preset7CmdText),0

Preset8CmdText:		dc.b	"Target",0
			dcb.b	24-(*-Preset8CmdText),0

Preset9CmdText:		dc.b	"Horizontal line",0
			dcb.b	24-(*-Preset9CmdText),0

Preset10CmdText:	dc.b	"Vertical line",0
			dcb.b	24-(*-Preset10CmdText),0

Preset11CmdText:	dc.b	"Clockwise rotating flat",0
			dcb.b	24-(*-Preset11CmdText),0

Preset12CmdText:	dc.b	"Anticlock rotating flat",0
			dcb.b	24-(*-Preset12CmdText),0

Preset13CmdText:	dc.b	"Wild rotating flat",0
			dcb.b	24-(*-Preset13CmdText),0

Preset14CmdText:	dc.b	"Clockwise rotatng beams",0
			dcb.b	24-(*-Preset14CmdText),0

Preset15CmdText:	dc.b	"Anticlock rotatng beams",0
			dcb.b	24-(*-Preset15CmdText),0

Preset16CmdText:	dc.b	"Thin star",0
			dcb.b	24-(*-Preset16CmdText),0

Preset17CmdText:	dc.b	"Five point star",0
			dcb.b	24-(*-Preset17CmdText),0

Preset18CmdText:	dc.b	"Six point star",0
			dcb.b	24-(*-Preset18CmdText),0

Preset19CmdText:	dc.b	"Flower",0
			dcb.b	24-(*-Preset19CmdText),0

Preset20CmdText:	dc.b	"Smoke beams",0
			dcb.b	24-(*-Preset20CmdText),0

Preset21CmdText:	dc.b	"Nice pattern",0
			dcb.b	24-(*-Preset21CmdText),0

Preset22CmdText:	dc.b	"Mad pattern",0
			dcb.b	24-(*-Preset22CmdText),0

Preset23CmdText:	dc.b	"Wild pattern",0
			dcb.b	24-(*-Preset23CmdText),0

Preset24CmdText:	dc.b	"Changing mad pattern",0
			dcb.b	24-(*-Preset24CmdText),0

Preset25CmdText:	dc.b	"Rocker",0
			dcb.b	24-(*-Preset25CmdText),0

Preset26CmdText:	dc.b	"Triangle",0
			dcb.b	24-(*-Preset26CmdText),0

Preset27CmdText:	dc.b	"Madness!",0
			dcb.b	24-(*-Preset27CmdText),0

Preset28CmdText:	dc.b	"Dot",0
			dcb.b	24-(*-Preset28CmdText),0

Preset29CmdText:	dc.b	"Mirror ball 1",0
			dcb.b	24-(*-Preset29CmdText),0

Preset30CmdText:	dc.b	"Mirror ball 2",0
			dcb.b	24-(*-Preset30CmdText),0

Preset31CmdText:	dc.b	"Location 1",0
			dcb.b	24-(*-Preset31CmdText),0

Preset32CmdText:	dc.b	"Location 2",0
			dcb.b	24-(*-Preset32CmdText),0

Preset33CmdText:	dc.b	"Location 3",0
			dcb.b	24-(*-Preset33CmdText),0

Preset34CmdText:	dc.b	"Location 4",0
			dcb.b	24-(*-Preset34CmdText),0

Preset35CmdText:	dc.b	"Location 5",0
			dcb.b	24-(*-Preset35CmdText),0

Preset36CmdText:	dc.b	"Location 6",0
			dcb.b	24-(*-Preset36CmdText),0

Preset37CmdText:	dc.b	"Location 7",0
			dcb.b	24-(*-Preset37CmdText),0

Preset38CmdText:	dc.b	"Location 8",0
			dcb.b	24-(*-Preset38CmdText),0

Preset39CmdText:	dc.b	"Location 9",0
			dcb.b	24-(*-Preset39CmdText),0

Preset40CmdText:	dc.b	"Location 10",0
			dcb.b	24-(*-Preset40CmdText),0

FactoryCmdText:		dc.b	"Factory reset",0

PresetSpeed1:		dc.b	0
PresetSpeed2:		dc.b	0
PresetSpeed3:		dc.b	0
PresetSpeed4:		dc.b	0
PresetSpeed5:		dc.b	0
PresetSpeed6:		dc.b	0
PresetSpeed7:		dc.b	0
PresetSpeed8:		dc.b	0
PresetSpeed9:		dc.b	0

PresetSpeed10:		dc.b	0
PresetSpeed11:		dc.b	0
PresetSpeed12:		dc.b	0
PresetSpeed13:		dc.b	0
PresetSpeed14:		dc.b	0
PresetSpeed15:		dc.b	0
PresetSpeed16:		dc.b	0
PresetSpeed17:		dc.b	0
PresetSpeed18:		dc.b	0
PresetSpeed19:		dc.b	0

PresetSpeed20:		dc.b	0
PresetSpeed21:		dc.b	0
PresetSpeed22:		dc.b	0
PresetSpeed23:		dc.b	0
PresetSpeed24:		dc.b	0
PresetSpeed25:		dc.b	0
PresetSpeed26:		dc.b	0
PresetSpeed27:		dc.b	0
PresetSpeed28:		dc.b	0
PresetSpeed29:		dc.b	0			;Mirror 1
PresetSpeed30:		dc.b	0			;Mirror 2

PresetSpeed31:		dc.b	18			;Loc 1
PresetSpeed32:		dc.b	18			;Loc 2
PresetSpeed33:		dc.b	18			;Loc 3
PresetSpeed34:		dc.b	18			;Loc 4
PresetSpeed35:		dc.b	18			;Loc 5
PresetSpeed36:		dc.b	18			;Loc 6
PresetSpeed37:		dc.b	18			;Loc 7
PresetSpeed38:		dc.b	18			;Loc 8
PresetSpeed39:		dc.b	18			;Loc 9
PresetSpeed40:		dc.b	18			;Loc 10

FactorySpeed:		dc.b	0

Vol0UpText2:		dc.b	"Ch0 volume +1",0
Vol0DnText2:		dc.b	"Ch0 volume -1",0
Vol0SetCmd:		dc.b	"0v",0

Vol1UpText2:		dc.b	"Ch1 volume +1",0
Vol1DnText2:		dc.b	"Ch1 volume -1",0
Vol1SetCmd:		dc.b	"1v",0

Vol2UpText2:		dc.b	"Ch2 volume +1",0
Vol2DnText2:		dc.b	"Ch2 volume -1",0
Vol2SetCmd:		dc.b	"2v",0

Vol3UpText2:		dc.b	"Ch3 volume +1",0
Vol3DnText2:		dc.b	"Ch3 volume -1",0
Vol3SetCmd:		dc.b	"3v",0

Freq0UpText2:		dc.b	"Ch0 frequency +1",0
Freq0DnText2:		dc.b	"Ch0 frequency -1",0
Freq0SetCmd:		dc.b	"0f",0

Freq1UpText2:		dc.b	"Ch1 frequency +1",0
Freq1DnText2:		dc.b	"Ch1 frequency -1",0
Freq1SetCmd:		dc.b	"1f",0

Freq2UpText2:		dc.b	"Ch2 frequency +1",0
Freq2DnText2:		dc.b	"Ch2 frequency -1",0
Freq2SetCmd:		dc.b	"2f",0

Freq3UpText2:		dc.b	"Ch3 frequency +1",0
Freq3DnText2:		dc.b	"Ch3 frequency -1",0
Freq3SetCmd:		dc.b	"3f",0

Phase1UpText2:		dc.b	"Ch1 phase +1",0
Phase1DnText2:		dc.b	"Ch1 phase -1",0
Phase1SetCmd:		dc.b	"1p",0

Phase2UpText2:		dc.b	"Ch2 phase +1",0
Phase2DnText2:		dc.b	"Ch2 phase -1",0
Phase2SetCmd:		dc.b	"2p",0

Phase3UpText2:		dc.b	"Ch3 phase +1",0
Phase3DnText2:		dc.b	"Ch3 phase -1",0
Phase3SetCmd:		dc.b	"3p",0

RotateAngle01UpText2:	dc.b	"Ch0/Ch1 rotate angle +1",0
RotateAngle01DnText2:	dc.b	"Ch0/Ch1 rotate angle -1",0
RotateAngle01SetCmd:	dc.b	"0r",0

RotateAngle23UpText2:	dc.b	"Ch2/Ch3 rotate angle +1",0
RotateAngle23DnText2:	dc.b	"Ch2/Ch3 rotate angle -1",0
RotateAngle23SetCmd:	dc.b	"2r",0

Spin0UpText2:		dc.b	"Ch0 spin angle +1",0
Spin0DnText2:		dc.b	"Ch0 spin angle -1",0
Spin0SetCmd:		dc.b	"0s",0

Spin1UpText2:		dc.b	"Ch1 spin angle +1",0
Spin1DnText2:		dc.b	"Ch1 spin angle -1",0
Spin1SetCmd:		dc.b	"1s",0

Spin2UpText2:		dc.b	"Ch2 spin angle +1",0
Spin2DnText2:		dc.b	"Ch2 spin angle -1",0
Spin2SetCmd:		dc.b	"2s",0

Spin3UpText2:		dc.b	"Ch3 spin angle +1",0
Spin3DnText2:		dc.b	"Ch3 spin angle -1",0
Spin3SetCmd:		dc.b	"3s",0

ShutterText2:		dc.b	"Shutter on",0
ShutterText3:		dc.b	"Shutter off",0
StandbyText2:		dc.b	"Standby on",0
StandbyText3:		dc.b	"Standby off",0
FastMoveText2:		dc.b	"Fast move on",0
FastMoveText3:		dc.b	"Fast move off",0
StrobeText2:		dc.b	"Strobe on",0
StrobeText3:		dc.b	"Strobe off",0

			even
PresetPos1:		dc.w	XMax/2,YMax/2
PresetPos2:		dc.w	XMax/2,YMax/2
PresetPos3:		dc.w	XMax/2,YMax/2
PresetPos4:		dc.w	XMax/2,YMax/2
PresetPos5:		dc.w	XMax/2,YMax/2
PresetPos6:		dc.w	XMax/2,YMax/2
PresetPos7:		dc.w	XMax/2,YMax/2
PresetPos8:		dc.w	XMax/2,YMax/2
PresetPos9:		dc.w	XMax/2,YMax/2
PresetPos10:		dc.w	XMax/2,YMax/2

PresetPos11:		dc.w	XMax/2,YMax/2
PresetPos12:		dc.w	XMax/2,YMax/2
PresetPos13:		dc.w	XMax/2,YMax/2
PresetPos14:		dc.w	XMax/2,YMax/2
PresetPos15:		dc.w	XMax/2,YMax/2
PresetPos16:		dc.w	XMax/2,YMax/2
PresetPos17:		dc.w	XMax/2,YMax/2
PresetPos18:		dc.w	XMax/2,YMax/2
PresetPos19:		dc.w	XMax/2,YMax/2
PresetPos20:		dc.w	XMax/2,YMax/2

PresetPos21:		dc.w	XMax/2,YMax/2
PresetPos22:		dc.w	XMax/2,YMax/2
PresetPos23:		dc.w	XMax/2,YMax/2
PresetPos24:		dc.w	XMax/2,YMax/2
PresetPos25:		dc.w	XMax/2,YMax/2
PresetPos26:		dc.w	XMax/2,YMax/2
PresetPos27:		dc.w	XMax/2,YMax/2
PresetPos28:		dc.w	XMax/2,YMax/2
PresetPos29:		dc.w	XMax/2-40,380		;Mirror 1
PresetPos30:		dc.w	XMax/2+40,380		;Mirror 2

PresetPos31:		dc.w	202,306			;Loc 1
PresetPos32:		dc.w	330,254			;Loc 2
PresetPos33:		dc.w	178,228			;Loc 3
PresetPos34:		dc.w	254,216			;Loc 4
PresetPos35:		dc.w	292,190			;Loc 5
PresetPos36:		dc.w	330,306			;Loc 6
PresetPos37:		dc.w	254,280			;Loc 7
PresetPos38:		dc.w	216,228			;Loc 8
PresetPos39:		dc.w	330,242			;Loc 9
PresetPos40:		dc.w	178,202			;Loc 10

FactoryPos:		dc.w	XMax/2,YMax/2


;Preset gadget table:

			even
PresetGadTable:		dc.l	Preset1Text
			dc.w	GD_Preset1
			dc.l	Preset2Text
			dc.w	GD_Preset2
			dc.l	Preset3Text
			dc.w	GD_Preset3
			dc.l	Preset4Text
			dc.w	GD_Preset4
			dc.l	Preset5Text
			dc.w	GD_Preset5
			dc.l	Preset6Text
			dc.w	GD_Preset6
			dc.l	Preset7Text
			dc.w	GD_Preset7
			dc.l	Preset8Text
			dc.w	GD_Preset8
			dc.l	Preset9Text
			dc.w	GD_Preset9
			dc.l	Preset10Text
			dc.w	GD_Preset10
			dc.l	Preset11Text
			dc.w	GD_Preset11
			dc.l	Preset12Text
			dc.w	GD_Preset12
			dc.l	Preset13Text
			dc.w	GD_Preset13
			dc.l	Preset14Text
			dc.w	GD_Preset14
			dc.l	Preset15Text
			dc.w	GD_Preset15
			dc.l	Preset16Text
			dc.w	GD_Preset16
			dc.l	Preset17Text
			dc.w	GD_Preset17
			dc.l	Preset18Text
			dc.w	GD_Preset18
			dc.l	Preset19Text
			dc.w	GD_Preset19
			dc.l	Preset20Text
			dc.w	GD_Preset20
			dc.l	Preset21Text
			dc.w	GD_Preset21
			dc.l	Preset22Text
			dc.w	GD_Preset22
			dc.l	Preset23Text
			dc.w	GD_Preset23
			dc.l	Preset24Text
			dc.w	GD_Preset24
			dc.l	Preset25Text
			dc.w	GD_Preset25
			dc.l	Preset26Text
			dc.w	GD_Preset26
			dc.l	Preset27Text
			dc.w	GD_Preset27
			dc.l	Preset28Text
			dc.w	GD_Preset28
			dc.l	Preset29Text
			dc.w	GD_Preset29
			dc.l	Preset30Text
			dc.w	GD_Preset30
			dc.l	Preset31Text
			dc.w	GD_Preset31
			dc.l	Preset32Text
			dc.w	GD_Preset32
			dc.l	Preset33Text
			dc.w	GD_Preset33
			dc.l	Preset34Text
			dc.w	GD_Preset34
			dc.l	Preset35Text
			dc.w	GD_Preset35
			dc.l	Preset36Text
			dc.w	GD_Preset36
			dc.l	Preset37Text
			dc.w	GD_Preset37
			dc.l	Preset38Text
			dc.w	GD_Preset38
			dc.l	Preset39Text
			dc.w	GD_Preset39
			dc.l	Preset40Text
			dc.w	GD_Preset40



;Requestor text:

			even
SureText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	15			;Top edge
			dc.l	0			;Font ptr
			dc.l	SureTitle		;Title
			dc.l	0			;Next Ptr
SureTitle:		dc.b	"Are you sure you want to quit?",0
			even

SureText2:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	15			;Top edge
			dc.l	0			;Font ptr
			dc.l	SureTitle2		;Title
			dc.l	0			;Next Ptr
SureTitle2:		dc.b	"Are you sure you want to switch off DMA?",0
			even

SureText3:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	15			;Top edge
			dc.l	0			;Font ptr
			dc.l	ASCIIBuffer		;Title
			dc.l	0			;Next Ptr
SureTitle3:		dc.b	"There are ",0
SureTitle3a:		dc.b	" pics in this pack. Import & save all?",0
			even

SureText4:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	15			;Top edge
			dc.l	0			;Font ptr
			dc.l	ASCIIBuffer		;Title
			dc.l	0			;Next Ptr
SureTitle4:		dc.b	'Are you sure you want to delete "',0

SureTitle5:		dc.b	"There are ",0
SureTitle5a:		dc.b	" frames in this file. Import & save all?",0

SureTitle6:		dc.b	"Name: ",0
SureTitle6a:		dc.b	",  Frames: ",0
SureTitle6b:		dc.b	",  Import & save all?",0

SureTitle7:		dc.b	"There are ",0
SureTitle7a:		dc.b	" screens in this pack. Unpack & save all?",0

SureTitle8:		dc.b	"There are ",0
SureTitle8a:		dc.b	" frames in this scene. Import & save all?",0
			even

QuitText2:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	QuitTitle		;Title
			dc.l	0			;Next ptr
QuitTitle:		dc.b	"Quit",0
			even

DMAText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	DMATitle		;Title
			dc.l	0			;Next ptr
DMATitle:		dc.b	"DMA off",0
			even

SaveText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	SaveTitle		;Title
			dc.l	0			;Next ptr
SaveTitle:		dc.b	"Save all",0
			even

DeleteText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	DeleteTitle		;Title
			dc.l	0			;Next ptr
DeleteTitle:		dc.b	"Delete it!",0
			even

WhoopsText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	WhoopsTitle		;Title
			dc.l	0			;Next ptr
WhoopsTitle:		dc.b	"Whoops!",0
			even

SkipText:		dc.b	0			;Fore colour
			dc.b	1			;Back colour
			dc.b	0			;Draw mode
			dc.w	0			;Left edge
			dc.w	0			;Top edge
			dc.l	0			;Font ptr
			dc.l	SkipTitle		;Title
			dc.l	0			;Next ptr
SkipTitle:		dc.b	"Skip these frames",0
			even


;Audio 0 handler node structure:

AD0IntNode:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD0Name			;Name
			dc.l	Loc0PtrTemp		;Data
			dc.l	AD0Handler		;Code
AD0Name:		dc.b	"LASERAD0Handler",0


;Audio 1 handler node structure:

AD1IntNode:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD1Name			;Name
			dc.l	Loc1PtrTemp		;Data
			dc.l	AD1Handler		;Code
AD1Name:		dc.b	"LASERAD1Handler",0


;Audio 2 handler node structure:

AD2IntNode:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD2Name			;Name
			dc.l	Loc2PtrTemp		;Data
			dc.l	AD2Handler		;Code
AD2Name:		dc.b	"LASERAD2Handler",0


;Audio 3 handler node structure:

AD3IntNode:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD3Name			;Name
			dc.l	Loc3PtrTemp		;Data
			dc.l	AD3Handler		;Code
AD3Name:		dc.b	"LASERAD3Handler",0


;Audio 0 handler DMA node structure:

AD0IntNodeDMA:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD0Name			;Name
			dc.l	AD0Update2		;Data
			dc.l	AD0HandlerDMA		;Code


;Audio 1 handler DMA node structure:

AD1IntNodeDMA:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD1Name			;Name
			dc.l	AD1Update2		;Data
			dc.l	AD1HandlerDMA		;Code


;Audio 2 handler DMA node structure:

AD2IntNodeDMA:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD2Name			;Name
			dc.l	AD2Update2		;Data
			dc.l	AD2HandlerDMA		;Code


;Audio 3 handler DMA node structure:

AD3IntNodeDMA:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	1			;Priority
			dc.l	AD3Name			;Name
			dc.l	AD3Update2		;Data
			dc.l	AD3HandlerDMA		;Code


;VBlank interrupt node structure:

VBlankIntNode:		dc.l	0			;Successor
			dc.l	0			;Predecessor
			dc.b	2			;Type
			dc.b	0			;Priority
			dc.l	VBName			;Name
			dc.l	0			;Data
			dc.l	VBServ			;Code
VBName:			dc.b	"LASERVBServ",0


;Req tools attributes tag list:

ReqAttTags:		dc.l	$80000032		;RTFI_Dir
			dc.l	0			;Dir ptr
			dc.l	0			;End
			dc.l	0			;Pad


;Req tools file request tag list:

ReqFRTags:		dc.l	$80000001		;RT_Window
			dc.l	0			;Window ptr
			dc.l	$8000002a		;RTFI_OkText
			dc.l	0			;Ok text ptr
			dc.l	1			;RTFI_Flags (ignore)
			dc.l	2			;Flags Save = 2
			dc.l	0			;End
			dc.l	0			;Pad


;Iconify window structure:

IconWindow:		dc.w	300			;Left edge
			dc.w	0			;Top edge
			dc.w	264			;Width
			dc.w	10			;Height
			dc.b	0			;Detail pen
			dc.b	1			;Block pen
			dc.l	$0600			;IDCMP flags
			dc.l	$2100e			;Flags
			dc.l	0			;First gadget
			dc.l	0			;Checkmark
			dc.l	IconWindowTitle		;Title
			dc.l	0			;Screen prt
			dc.l	0			;Bitmap
			dc.w	0			;Min Width
			dc.w	0			;Min height
			dc.w	0			;Max Width
			dc.w	0			;Max height
			dc.w	1			;Type

IconWindowTitle:	dc.b	"LASERMAX LASER controller",0


;Input event structure:

InputEvent:		dc.l	0			;ie_NextEvent
			dc.b	1			;ie_Class
			dc.b	0			;ie_SubClass
			dc.w	0			;ie_Code
			dc.w	0			;ie_Qualifier
			dc.l	0			;ie_EventAddress
			dc.l	0			;ie_X
			dc.b	0			;ie_Prev1DownCode
			dc.b	0			;ie_Prev1DownQual
			dc.l	0			;ie_Y
			dc.b	0			;ie_Prev2DownCode
			dc.b	0			;ie_Prev2DownQual
			dc.l	0			;Days
			dc.l	0			;Mins
			dc.l	0			;Ticks

SN:			dc.l	SerialNumber		;Serial number!


;Sine wave data table:

			even
SineData:		dc.w	0,572,1144,1715,2286,2856,3425,3993
			dc.w	4560,5126,5690,6252,6813,7371,7927
			dc.w	8481,9032,9580,10126,10668,11207
			dc.w	11743,12275,12803,13328,13848,14364
			dc.w	14876,15383,15886,16384,16876,17364
			dc.w	17846,18323,18794,19260,19720,20173
			dc.w	20621,21062,21497,21925,22347,22762
			dc.w	23170,23571,23964,24351,24730,25101
			dc.w	25465,25821,26169,26509,26841,27165
			dc.w	27481,27788,28087,28377,28659,28932
			dc.w	29196,29451,29697,29934,30162,30381
			dc.w	30591,30791,30982,31163,31335,31498
			dc.w	31650,31794,31927,32051,32165,32269
			dc.w	32364,32448,32523,32587,32642,32687
			dc.w	32722,32747,32762,32767

			dc.w	32762,32747,32722,32687,32642,32587
			dc.w	32523,32448,32364,32269,32165,32051
			dc.w	31927,31794,31650,31498,31335,31163
			dc.w	30982,30791,30591,30381,30162,29934
			dc.w	29697,29451,29196,28932,28659,28377
			dc.w	28087,27788,27481,27165,26841,26509
			dc.w	26169,25821,25465,25101,24730,24351
			dc.w	23964,23571,23170,22762,22347,21925
			dc.w	21497,21062,20621,20173,19720,19260
			dc.w	18794,18323,17846,17364,16876,16384
			dc.w	15886,15383,14876,14364,13848,13328
			dc.w	12803,12275,11743,11207,10668,10126
			dc.w	9580,9032,8481,7927,7371,6813,6252
			dc.w	5690,5126,4560,3993,3425,2856,2286
			dc.w	1715,1144,572

			dc.w	0,-572,-1144,-1715,-2286,-2856,-3425,-3993
			dc.w	-4560,-5126,-5690,-6252,-6813,-7371,-7927
			dc.w	-8481,-9032,-9580,-10126,-10668,-11207
			dc.w	-11743,-12275,-12803,-13328,-13848,-14364
			dc.w	-14876,-15383,-15886,-16384,-16876,-17364
			dc.w	-17846,-18323,-18794,-19260,-19720,-20173
			dc.w	-20621,-21062,-21497,-21925,-22347,-22762
			dc.w	-23170,-23571,-23964,-24351,-24730,-25101
			dc.w	-25465,-25821,-26169,-26509,-26841,-27165
			dc.w	-27481,-27788,-28087,-28377,-28659,-28932
			dc.w	-29196,-29451,-29697,-29934,-30162,-30381
			dc.w	-30591,-30791,-30982,-31163,-31335,-31498
			dc.w	-31650,-31794,-31927,-32051,-32165,-32269
			dc.w	-32364,-32448,-32523,-32587,-32642,-32687
			dc.w	-32722,-32747,-32762,-32767

			dc.w	-32762,-32747,-32722,-32687,-32642,-32587
			dc.w	-32523,-32448,-32364,-32269,-32165,-32051
			dc.w	-31927,-31794,-31650,-31498,-31335,-31163
			dc.w	-30982,-30791,-30591,-30381,-30162,-29934
			dc.w	-29697,-29451,-29196,-28932,-28659,-28377
			dc.w	-28087,-27788,-27481,-27165,-26841,-26509
			dc.w	-26169,-25821,-25465,-25101,-24730,-24351
			dc.w	-23964,-23571,-23170,-22762,-22347,-21925
			dc.w	-21497,-21062,-20621,-20173,-19720,-19260
			dc.w	-18794,-18323,-17846,-17364,-16876,-16384
			dc.w	-15886,-15383,-14876,-14364,-13848,-13328
			dc.w	-12803,-12275,-11743,-11207,-10668,-10126
			dc.w	-9580,-9032,-8481,-7927,-7371,-6813,-6252
			dc.w	-5690,-5126,-4560,-3993,-3425,-2856,-2286
			dc.w	-1715,-1144,-572

			dc.w	0,572,1144,1715,2286,2856,3425,3993
			dc.w	4560,5126,5690,6252,6813,7371,7927
			dc.w	8481,9032,9580,10126,10668,11207
			dc.w	11743,12275,12803,13328,13848,14364
			dc.w	14876,15383,15886,16384,16876,17364
			dc.w	17846,18323,18794,19260,19720,20173
			dc.w	20621,21062,21497,21925,22347,22762
			dc.w	23170,23571,23964,24351,24730,25101
			dc.w	25465,25821,26169,26509,26841,27165
			dc.w	27481,27788,28087,28377,28659,28932
			dc.w	29196,29451,29697,29934,30162,30381
			dc.w	30591,30791,30982,31163,31335,31498
			dc.w	31650,31794,31927,32051,32165,32269
			dc.w	32364,32448,32523,32587,32642,32687
			dc.w	32722,32747,32762,32767


;Patterns sinewave:

SineWave:		dcb.b	362,0


;The stupid GadToolBox code:

_IntuitionBase:		equ	IntBase
_GadToolsBase:		equ	GadBase
_SysBase:		equ	4

			opt o+,ow-

			even

			include	"DH0:Asm/Laser.s"


;Image bit map data:

			section	BitMap,data_c

SN2:			dc.l	SerialNumber		;Serial number!

DrawPtrImage:		dc.w	$0000,$0000		;Sprite data
			dc.w	$1000,$0000
			dc.w	$1000,$0000
			dc.w	$0000,$0000
			dc.w	$c600,$0000
			dc.w	$0000,$0000
			dc.w	$1000,$0000
			dc.w	$1000,$0000
			dc.w	$0000,$0000
			dc.w	$0000,$0000

DrawPtrImage2:		dc.w	$0000,$0000		;Sprite data
			dc.w	$1000,$1000
			dc.w	$1000,$1000
			dc.w	$0000,$0000
			dc.w	$c600,$c600
			dc.w	$0000,$0000
			dc.w	$1000,$1000
			dc.w	$1000,$1000
			dc.w	$0000,$0000
			dc.w	$0000,$0000
