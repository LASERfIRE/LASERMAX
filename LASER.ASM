;            ***********************************************
;            *                                             *
;            *          LASERMAX LASER controller          *
;            *                                             *
;            *    Created by Anthony Barrett, 22-Apr-93    *
;            *                                             *
;            *                 Version 1.30                *
;            *                                             *
;            ***********************************************


			include	"DH0:Asm/Include/Misc/OffSets2.i"


SerialNumber:		equ	300
CRCNumber:		equ	$437021f5

ScopeX:			equ	16
ScopeY:			equ	21
TableSize:		equ	60

XMax:			equ	508
YMax:			equ	508

StrobeRate:		equ	3

MaxPoints:		equ	8000		;Max 14399! Mem = 48*!
						;3 Blocks. Must divide by 4!

MaxSeqSize:		equ	500000


			opt o+,ow+


			move.l	sp,StackPtr


;Check if from WorkBench:

CheckWB:		suba.l	a1,a1
			movea.l	(4).l,a6
			jsr	_LVOFindTask(a6)
			move.l	d0,TaskPtr
			movea.l	d0,a0
			tst.l	172(a0)
			bne.s	OpenLibs

			adda.w	#92,a0
			move.l	a0,-(sp)
			movea.l	(4).l,a6
			jsr	_LVOWaitPort(a6)

			movea.l	(sp)+,a0
			movea.l	(4).l,a6
			jsr	_LVOGetMsg(a6)
			move.l	d0,WBMsgPtr


;Open libraries:

OpenLibs:		lea	DosName,a1
			sub.l	d0,d0
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,DosBase
			beq.l	Exit

			lea	IntName,a1
			sub.l	d0,d0
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,IntBase
			beq.l	Exit2

			lea	GfxName,a1
			sub.l	d0,d0
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,GfxBase
			beq.l	Exit3

			lea	GadName,a1
			sub.l	d0,d0
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,GadBase
			beq.l	Exit4

			lea	KeyMapName,a1
			sub.l	d0,d0
			movea.l	(4).l,a6
			jsr	_LVOOpenLibrary(a6)
			move.l	d0,KeyBase
			beq.l	Exit5


;Stop any current sound:

			move.w	#$f,$dff096		;Stop DMA
			move.w	#$780,$dff09a		;Disable all int

			jsr	ShortDelay

			move.w	#$780,$dff09c		;Reset bit 7,8,9,10
			move.w	#$00ff,$dff09e


;Check about text:

CheckAbout:		sub.l	d0,d0
			lea	AboutIText0,a0
			move.l	#APointsIText0,d1
			sub.l	a0,d1
			subq.l	#3,d1
			jsr	CRC

			cmpi.l	#CRCNumber,d0
			bne.s	Audio

			move.b	#1,PirateFlag


;Set up audio handlers:

Audio:			moveq	#7,d0			;AD0 Handler
			lea	AD0IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#8,d0			;AD1 Handler
			lea	AD1IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#9,d0			;AD2 Handler
			lea	AD2IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#10,d0			;AD3 Handler
			lea	AD3IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)


;Set up VBlank int server:

			moveq	#5,d0
			lea	VBlankIntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOAddIntServer(a6)


;Setup output buffers & sine wave data:

			sub.l	d1,d1
			move.l	#MaxPoints*4,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,ExtrasBufferPtr
			beq.l	Exit6

			jsr	GetOutputBuff
			beq.l	Exit7

			move.l	OutputBufferPtrTemp,OutputBufferPtr
			move.l	OutputBufferPtr2Temp,OutputBufferPtr2
			move.l	OutputBufferPtr3Temp,OutputBufferPtr3

			move.l	OutputBufferPtr3,d0
			move.l	d0,AD0MemPtr
			addi.l	#MaxPoints*4,d0
			move.l	d0,AD1MemPtr
			addi.l	#MaxPoints*4,d0
			move.l	d0,AD2MemPtr
			addi.l	#MaxPoints*4,d0
			move.l	d0,AD3MemPtr

			jsr	SetSineWave

			clr.w	$dff0a8			;No output
			clr.w	$dff0b8
			clr.w	$dff0c8
			clr.w	$dff0d8

			bclr	#1,$bfe001		;Filter on

			move.b	#$ff,$bfe301		;ddrb output
			move.b	#$ff,$bfe101		;Clr output
			move.b	#$bf,$bfe101		;Clr output


;Open the serial device:

			moveq	#116,d0			;Mem for msg port & IOReq structure
			move.l	#$10001,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,MsgPortPtr
			beq.s	.Error

			movea.l	d0,a0
			adda.w	#34,a0
			move.l	a0,IORequestPtr
			move.b	#5,8(a0)
			move.l	d0,14(a0)
			move.w	#82,18(a0)

			moveq	#-1,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocSignal(a6)

			movea.l	MsgPortPtr,a1
			move.b	d0,15(a1)
			bmi.s	.Error2

			move.b	#4,8(a1)
			move.l	#MsgPortName,10(a1)
			move.l	TaskPtr,16(a1)

			movea.l	(4).l,a6
			jsr	_LVOAddPort(a6)

			lea	SerialName,a0
			movea.l	IORequestPtr,a1
			move.b	#$b0,79(a1)		;No XON/XOFF, Shared, Fast
			sub.l	d0,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOOpenDevice(a6)
			tst.b	d0
			beq.s	SetupSerial

			bsr.s	FreePort
			bsr.s	FreeSignal

.Error2:		bsr.s	FreeMsgIOMem
.Error:			move.b	#1,SerialFlag
			bra	Display

CloseSerial:		movea.l	IORequestPtr,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseDevice(a6)

			bsr.s	FreePort
			bsr.s	FreeSignal
			bsr.s	FreeMsgIOMem
			rts

FreeMsgIOMem:		moveq	#116,d0
			movea.l	MsgPortPtr,a1
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

FreeSignal:		sub.l	d0,d0
			movea.l	MsgPortPtr,a0
			move.b	15(a0),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeSignal(a6)
			rts

FreePort:		movea.l	MsgPortPtr,a1
			movea.l	(4).l,a6
			jsr	_LVORemPort(a6)
			rts


;Setup serial port:

SetupSerial:		movea.l	IORequestPtr,a1
			move.w	#11,28(a1)		;Command
			move.l	#9600,60(a1)		;Bps
			move.l	#250000,64(a1)		;Break time
			move.b	#8,76(a1)		;Rd bits
			move.b	#8,77(a1)		;Wr bits
			move.b	#1,78(a1)		;Stop bits
			move.b	#$b0,79(a1)		;No XON/XOFF, Shared, Fast
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)


;Open display:

Display:		bsr	ParShutterOn2

			move.l	#SerialNumber,d0	;Serial number!

			move.b	#1,FromConfig
			jsr	BigScreen
			clr.b	FromConfig


;Load config file:

Config:			lea	ConfigFilename+2,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			jsr	LoadFile
			tst.l	d0
			beq.s	Config2

			lea	ConfigFilename,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			jsr	LoadFile
			tst.l	d0
			bne	ConDone2

Config2:		lea	StatusConfig,a0
			jsr	PrintStatus

			move.l	FileMemPtr,ConfigPtr

ReadConfig:		movea.l	ConfigPtr,a1
			movea.l	FileMemPtr,a2
			add.l	FileMemSize,a2

			cmpa.l	FileMemPtr,a1
			bne.s	.Loop

			cmpi.b	#$a,(a1)
			bne.s	.Start

.Loop:			cmpi.b	#$a,(a1)+
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop
			bra	ConDone

.Skip:			cmpa.l	a1,a2
			bls	ConDone
			cmpi.b	#$a,(a1)+
			beq.s	.Skip

			subq.l	#1,a1

.Start:			cmpi.b	#";",(a1)
			beq	Comment

			lea	LoadSeqCmd,a0
			jsr	CmpString
			bne	LoadSequenceCmd

			lea	LoadScrCmd,a0
			jsr	CmpString
			bne	LoadScreenCmd

			lea	SwapCmd,a0
			jsr	CmpString
			bne	SwapLeftRightCmd

			lea	APreldCmd,a0
			jsr	CmpString
			bne	APreloadCmd

			lea	FastScpCmd,a0
			jsr	CmpString
			bne	FastScopeCmd

			lea	InvXCmd,a0
			jsr	CmpString
			bne	InvertXCmd

			lea	InvYCmd,a0
			jsr	CmpString
			bne	InvertYCmd

			lea	DrScopeOffCmd,a0
			jsr	CmpString
			bne	DrawScopeOffCmd

			lea	DMACmd,a0
			jsr	CmpString
			bne	DMAOutputCmd

			lea	IconifyCmd,a0
			jsr	CmpString
			bne	IconCmd

			lea	BigScrCmd,a0
			jsr	CmpString
			bne	BigScreenCmd

			lea	FltCmd,a0
			jsr	CmpString
			bne	FilterCmd

			lea	DirectCmd,a0
			jsr	CmpString
			bne	DirectWriteCmd

			lea	NoSerCmd,a0
			jsr	CmpString
			bne	NoSerialCmd

			lea	SetAPCmd,a0
			jsr	CmpString
			bne	SetAutoPointsCmd

			lea	SetPatCmd,a0
			jsr	CmpString
			bne	SetPatternCmd

			lea	SetPatCmd2,a0
			jsr	CmpString
			bne	SetPatternCmd2

			lea	SetHiRCmd,a0
			jsr	CmpString
			bne	SetHiResCmd

			lea	SetHiRCmd2,a0
			jsr	CmpString
			bne	SetHiResCmd2

			lea	SetOutCmd,a0
			jsr	CmpString
			bne	SetOutSizeCmd

			lea	SetOutCmd2,a0
			jsr	CmpString
			bne	SetOutSizeCmd2

			lea	UndoCmd,a0
			jsr	CmpString
			bne	SetUndoHisCmd

			lea	StopDlyCmd,a0
			jsr	CmpString
			bne	StopDelayCmd

			lea	SetPresetCmd,a0
			jsr	CmpString
			bne	PresetCmd

			lea	SetSeqDirCmd,a0
			jsr	CmpString
			bne	SeqDirCmd

			lea	SetScrDirCmd,a0
			jsr	CmpString
			bne	ScrDirCmd

			lea	SetFontDirCmd,a0
			jsr	CmpString
			bne	FontDirCmd

			lea	SetConfigDirCmd,a0
			jsr	CmpString
			bne	ConfigDirCmd

			lea	SetEditCmdCmd,a0
			jsr	CmpString
			bne	EditCmdCmd

			lea	SetTestPatCmd,a0
			jsr	CmpString
			bne	SetTestPat

			lea	AutoAttachCmd,a0
			jsr	CmpString
			bne	AutoAttCmd

			lea	DrawBetweenCmd,a0
			jsr	CmpString
			bne	DrawBetwnCmd

			lea	SmoothChgCmd,a0
			jsr	CmpString
			bne	SmoothChange

			lea	NoDragCmd,a0
			jsr	CmpString
			bne	NoDragPlease

			lea	MaxPPSCmd,a0
			jsr	CmpString
			bne	SetMaxPPS

			lea	MasterCmd,a0
			jsr	CmpString
			bne	Master2

			lea	SlaveCmd,a0
			jsr	CmpString
			bne	Slave2

			lea	SetDefXSizeCmd,a0
			jsr	CmpString
			bne	SetDefXSize

			lea	SetDefYSizeCmd,a0
			jsr	CmpString
			bne	SetDefYSize

			lea	SetDefXPosCmd,a0
			jsr	CmpString
			bne	SetDefXPos

			lea	SetDefYPosCmd,a0
			jsr	CmpString
			bne	SetDefYPos

			lea	SetLASERfIRECmd,a0
			jsr	CmpString
			bne	SetLASERfIRE
			bra.s	ConError

Comment:		addq.l	#1,a1
			cmpa.l	a1,a2
			bls.s	ConError

			move.l	a1,ConfigPtr
			bra	ReadConfig

ConError2:		move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			jsr	FlashScreen
			lea	Error3Text,a0
			jsr	PrintStatus
			bra	ReadConfig

ConError:		movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error13Text,a0
			jsr	PrintStatus
			jsr	LongDelay

ConDone:		jsr	FreeFileMem

			tst.b	FromLoad
			beq.s	.Skip2

			bsr	FactoryIt
			jsr	RestartSound

			btst	#0,ShutterFlag
			bne.s	.Skip

			bsr	SetSoundVol
			bsr	ParShutterOff2

.Skip			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Skip2:			lea	DefaultFilename,a0
			lea	Filename2,a1
			jsr	MoveString

			lea	DefaultFilename,a0
			lea	Filename4,a1
			jsr	MoveString

ConDone2:		bsr	FactoryIt
			jsr	RestartSound
			bra	LaserReady

LoadSequenceCmd:	bsr	GetLoadFilename
			lea	Filename2,a1
			moveq	#40,d0
			jsr	MoveString6

			cmpi.w	#331,LoadNumber
			bhi	ConError

			move.l	FileMemPtr,-(sp)	;Save config file
			move.l	FileMemSize,-(sp)

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	ConError2

			cmpi.b	#2,d0
			beq	.Error

			sub.l	d0,d0
			move.w	LoadNumber,d0
			subi.w	#12,d0
			bpl.s	.Skip
			sub.l	d0,d0
			bra.s	.Skip2

.Skip:			divu	#32,d0
.Skip2:			cmp.b	Bank,d0
			beq.s	.Skip3

			move.l	d0,-(sp)
			bsr	BankOff
			move.l	(sp)+,d0
			move.b	d0,Bank
			bsr	BankOn

.Skip3:			jsr	FreeSeqMem
			move.l	FileMemPtr,SeqMemPtr
			move.l	FileMemSize,SeqMemSize
			clr.l	FileMemSize

			move.w	LoadNumber,d0
			sub.l	d1,d1
			move.b	Bank,d1
			mulu	#32,d1
			sub.w	d1,d0
			mulu	#4,d0
			lea	SeqTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

			move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			bra	ReadConfig

.Error:			move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			jsr	FlashScreen
			lea	Error14Text,a0
			jsr	PrintStatus
			bra	ReadConfig

LoadScreenCmd:		bsr	GetLoadFilename
			lea	Filename4,a1
			moveq	#40,d0
			jsr	MoveString6

			cmpi.w	#39,LoadNumber
			bhi	ConError

			move.l	FileMemPtr,-(sp)	;Save config
			move.l	FileMemSize,-(sp)

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	ConError2

			cmpi.b	#2,d0
			beq.s	.Error

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			jsr	CmpString
			beq.s	.Error2

			movea.l	FileMemPtr,a0
			jsr	MakeScreen

			tst.b	DrawMode
			beq.s	.Skip

			move.w	LoadNumber,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.Skip:			jsr	FreeFileMem
			move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			bra	ReadConfig

.Error:			move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			jsr	FlashScreen
			lea	Error18Text,a0
			jsr	PrintStatus
			bra	ReadConfig

.Error2:		jsr	FreeFileMem
			move.l	(sp)+,FileMemSize
			move.l	(sp)+,FileMemPtr
			jsr	FlashScreen
			lea	Error17Text,a0
			jsr	PrintStatus
			bra	ReadConfig

SwapLeftRightCmd:	adda.w	#4,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	SwapFlag
			bne	ReadConfig

			jsr	CheckCenter
			bchg	#0,SwapFlag

			bsr.s	GetSwapItem
			bset	#0,12(a0)
			bra	ReadConfig

GetSwapItem:		moveq	#13,d0
			jsr	GetSysPrefsItem
			rts

APreloadCmd:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	AutoPreloadFlag
			bne	ReadConfig

			bchg	#0,AutoPreloadFlag

			bsr.s	GetAPreloadItem
			bset	#0,12(a0)
			bra	ReadConfig

GetAPreloadItem:	moveq	#11,d0
			jsr	GetSysPrefsItem
			rts

FastScopeCmd:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	FastScopeFlag
			bne	ReadConfig

			bchg	#0,FastScopeFlag
			jsr	BlankScope
			move.b	#1,DrawUpdateFlag

			bsr.s	GetFastScopeItem
			bset	#0,12(a0)
			bra	ReadConfig

GetFastScopeItem:	moveq	#2,d0
			jsr	GetSysPrefsItem
			rts

InvertXCmd:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	InvertXFlag
			bne	ReadConfig

			bchg	#0,InvertXFlag

			bsr.s	GetInvertXItem
			bset	#0,12(a0)
			bra	ReadConfig

GetInvertXItem:		moveq	#14,d0
			jsr	GetSysPrefsItem
			rts

InvertYCmd:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	InvertYFlag
			bne	ReadConfig

			bchg	#0,InvertYFlag

			bsr.s	GetInvertYItem
			bset	#0,12(a0)
			bra	ReadConfig

GetInvertYItem:		moveq	#15,d0
			jsr	GetSysPrefsItem
			rts

DrawScopeOffCmd:	adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	DrawScopeFlag
			bne	ReadConfig

			bchg	#0,DrawScopeFlag
			move.b	#1,DrawUpdateFlag

			bsr.s	GetDrawScopeOffItem
			bset	#0,12(a0)
			bra	ReadConfig

GetDrawScopeOffItem:	moveq	#3,d0
			jsr	GetSysPrefsItem
			rts

DMAOutputCmd:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	DMAFlag
			bne.s	.Skip

			move.b	#1,FromConfig
			jsr	DMA2
			clr.b	FromConfig

			tst.b	DMAFlag
			beq	ReadConfig

			bsr.s	GetDMAItem
			bset	#0,12(a0)

.Skip:			clr.b	AutoDMAFlag
			bsr.s	GetAutoDMAItem
			bclr	#0,12(a0)
			bra	ReadConfig

GetDMAItem:		moveq	#8,d0
			jsr	GetSysPrefsItem
			rts

GetAutoDMAItem:		moveq	#9,d0
			jsr	GetSysPrefsItem
			rts

IconCmd:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	IconifyFlag
			bne	ReadConfig

			move.b	#1,FromConfig
			jsr	Iconify
			clr.b	FromConfig
			bra	ReadConfig

BigScreenCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	BigScreenFlag
			beq	ReadConfig

			move.b	#1,FromConfig
			jsr	BigScreen
			clr.b	FromConfig

			bsr.s	GetBigScreenItem
			bclr	#0,12(a0)
			bra	ReadConfig

GetBigScreenItem:	moveq	#1,d0
			jsr	GetSysPrefsItem
			rts

FilterCmd:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	FilterFlag2
			beq	ReadConfig

			bchg	#0,FilterFlag
			bchg	#0,FilterFlag2
			bchg	#1,$bfe001

			bsr.s	GetFilterItem
			bchg	#0,12(a0)
			bra	ReadConfig

GetFilterItem:		moveq	#6,d0
			jsr	GetPrefsItem
			rts

DirectWriteCmd:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	DirectFlag
			bne	ReadConfig

			bchg	#0,DirectFlag
			jsr	BlankScope
			move.b	#1,DrawUpdateFlag

			bsr.s	GetDirectItem
			bset	#0,12(a0)
			bra	ReadConfig

GetDirectItem:		moveq	#18,d0
			jsr	GetSysPrefsItem
			rts

NoSerialCmd		adda.w	#8,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	SerialFlag
			bne	ReadConfig

			move.b	#1,SerialFlag

			bsr	CloseSerial
			jsr	SerialItemsOff

			clr.b	SlaveFlag
			clr.b	MasterFlag
			jsr	SetMenus3
			bra	ReadConfig

SetAutoPointsCmd:	adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			tst.l	d0
			beq	ConError

			cmpi.l	#100,d0
			bhi	ConError

			move.w	d0,AutoPoints
			bra	ReadConfig

SetPatternCmd:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#127,d0
			bhi	ConError

			cmpi.l	#10,d0
			blo	ConError

			move.w	d0,PatSize

			tst.b	DrawMode
			bne	ReadConfig

			jsr	SetSineWave
			bra	ReadConfig

SetPatternCmd2:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			bclr	#0,d0			;Even

			cmpi.l	#360,d0
			bhi	ConError

			cmpi.l	#4,d0
			blo	ConError

			move.w	d0,PatPoints

			tst.b	DrawMode
			bne	ReadConfig

			jsr	SetSineWave
			bra	ReadConfig

SetHiResCmd:		adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#64,d0
			bhi	ConError

			cmpi.l	#1,d0
			blo	ConError

			move.w	d0,XHiResSize
			bsr	SetSoundVol2
			bra	ReadConfig

SetHiResCmd2:		adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#64,d0
			bhi	ConError

			cmpi.l	#1,d0
			blo	ConError

			move.w	d0,YHiResSize
			bsr	SetSoundVol2
			bra	ReadConfig

SetOutSizeCmd:		adda.w	#15,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#64,d0
			bhi	ConError

			cmpi.l	#1,d0
			blo	ConError

			move.w	d0,XOutSize
			bsr	SetSoundVol2
			bra	ReadConfig

SetOutSizeCmd2:		adda.w	#15,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#64,d0
			bhi	ConError

			cmpi.l	#1,d0
			blo	ConError

			move.w	d0,YOutSize
			bsr	SetSoundVol2
			bra	ReadConfig

SetUndoHisCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			tst.l	d0
			beq	ConError

			cmpi.l	#3000,d0
			bhi	ConError

			move.w	d0,MaxUndos
			bra	ReadConfig

StopDelayCmd:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#3000,d0
			bhi	ConError

			move.w	d0,StopDelayCount
			bra	ReadConfig

PresetCmd:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			sub.l	d0,d0
			move.b	(a1)+,d0
			subi.b	#"0",d0
			cmpi.b	#9,d0
			bhi	ConError

			cmpa.l	a1,a2
			bls	ConError

			move.b	(a1),d1
			cmpi.b	#" ",d1
			beq.s	.GotIt

			subi.b	#"0",d1
			cmpi.b	#9,d1
			bhi	ConError

			mulu	#10,d0
			add.b	d1,d0
			addq.l	#1,a1

.GotIt:			subq.w	#1,d0
			move.w	d0,LoadNumber

			addq.l	#2,a1
			cmpa.l	a1,a2
			bls	ConError

			cmpi.b	#'"',-1(a1)
			bne	ConError

			move.l	a1,ConfigPtr

			cmpi.w	#39,LoadNumber
			bhi	ConError

			lea	ASCIIBuffer+20,a0

.Loop:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			cmpa.l	#ASCIIBuffer+139,a0
			blo.s	.Loop

.Skip:			clr.b	(a0)

			bsr	.FindNext

			cmpi.b	#'"',(a1)+
			bne	ConError

			cmpa.l	a1,a2
			bls	ConError
			move.l	a1,ConfigPtr

			lea	ASCIIBuffer+140,a0

.Loop2:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip2
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip2
			cmpa.l	#ASCIIBuffer+163,a0
			blo.s	.Loop2

.Skip2:			clr.b	(a0)

			bsr	.FindNext

			cmpi.b	#'"',(a1)+
			bne	ConError

			cmpa.l	a1,a2
			bls	ConError
			move.l	a1,ConfigPtr

			lea	ASCIIBuffer+164,a0

.Loop3:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip3
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip3
			cmpa.l	#ASCIIBuffer+173,a0
			blo.s	.Loop3

.Skip3:			clr.b	(a0)

			bsr	.FindNext

			cmpa.l	a1,a2
			bls	ConError
			move.l	a1,ConfigPtr

			bsr	GetNumber
			cmpi.l	#XMax,d0
			bhi	ConError
			move.w	d0,XNumber

			cmpi.b	#' ',-1(a1)
			bne	ConError

			cmpa.l	a1,a2
			bls	ConError
			move.l	a1,ConfigPtr

			bsr	GetNumber
			cmpi.l	#YMax,d0
			bhi	ConError
			move.w	d0,YNumber

			cmpi.b	#' ',-1(a1)
			bne	ConError

			cmpa.l	a1,a2
			bls	ConError
			move.l	a1,ConfigPtr

			bsr	GetNumber
			cmpi.l	#255,d0
			bhi	ConError
			move.b	d0,SpeedNumber

			lea	Preset1Cmd,a1
			move.w	LoadNumber,d0
			mulu	#120,d0
			adda.w	d0,a1
			lea	ASCIIBuffer+20,a0
			jsr	MoveString

			lea	Preset1CmdText,a1
			move.w	LoadNumber,d0
			mulu	#24,d0
			adda.w	d0,a1
			lea	ASCIIBuffer+140,a0
			jsr	MoveString

			lea	PresetPos1,a1
			move.w	LoadNumber,d0
			mulu	#4,d0
			move.w	XNumber,(a1,d0)
			move.w	YNumber,2(a1,d0)

			lea	PresetSpeed1,a1
			sub.l	d0,d0
			move.w	LoadNumber,d0
			move.b	SpeedNumber,(a1,d0)

			lea	PresetGadTable,a0
			move.w	LoadNumber,d0
			mulu	#6,d0
			movea.l	(a0,d0),a1
			sub.l	d2,d2
			move.w	4(a0,d0),d2

			lea	ASCIIBuffer+164,a0
			jsr	MoveString

			move.l	d2,d0
			jsr	FindGadPtr
			jsr	GadChg

			lea	Preset1DrawPtr,a0
			move.w	LoadNumber,d0
			mulu	#8,d0
			adda.w	d0,a0

			tst.l	(a0)
			beq	ReadConfig

			movea.l	(a0),a1
			clr.l	(a0)
			move.l	4(a0),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			bra	ReadConfig

.FindNext:		cmpi.b	#'"',-1(a1)
			beq.s	.Found

.Loop4:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Found
			cmpa.l	a1,a2
			bls	ConError
			bra.s	.Loop4

.Found:			cmpi.b	#' ',(a1)+
			bne	ConError
			rts

GetNumber:		lea	ASCIIBuffer,a0

.Loop:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip
			cmpi.b	#" ",d0
			beq.s	.Skip
			cmpi.b	#"0",d0
			blo	ConError
			cmpi.b	#"9",d0
			bhi	ConError
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop
			bra	ConError

.Skip:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			jsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi	ConError
			rts

SeqDirCmd:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	Dir,a0
			bsr.s	GetDir
			bra	ReadConfig

ScrDirCmd:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	Dir2,a0
			bsr.s	GetDir
			bra	ReadConfig

FontDirCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	Dir3,a0
			bsr.s	GetDir
			bra	ReadConfig

ConfigDirCmd:		adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	Dir4,a0
			bsr.s	GetDir
			bra	ReadConfig

GetDir:			move.l	a0,-(sp)
			moveq	#48,d0

.Loop:			move.b	(a1)+,d1
			cmpi.b	#'"',d1
			beq.s	.Skip
			cmpi.b	#$a,d1
			beq.s	.Skip
			move.b	d1,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			dbf	d0,.Loop

.Skip:			clr.b	(a0)
			movea.l	(sp)+,a0
			jsr	CheckDirString
			rts

EditCmdCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	EditCmd,a0

			moveq	#120,d0

.Loop:			move.b	(a1)+,d1
			cmpi.b	#'"',d1
			beq.s	.Skip
			cmpi.b	#$a,d1
			beq.s	.Skip
			move.b	d1,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			dbf	d0,.Loop

.Skip:			clr.b	(a0)
			bra	ReadConfig

SetTestPat:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			lea	TestPatternFilename,a0

			moveq	#120,d0

.Loop:			move.b	(a1)+,d1
			cmpi.b	#'"',d1
			beq.s	.Skip
			cmpi.b	#$a,d1
			beq.s	.Skip
			move.b	d1,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			dbf	d0,.Loop

.Skip:			clr.b	(a0)
			bra	ReadConfig

AutoAttCmd:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	AutoAttachFlag
			bne	ReadConfig

			bchg	#0,AutoAttachFlag

			bsr.s	GetAutoAttachItem
			bset	#0,12(a0)
			bra	ReadConfig

GetAutoAttachItem:	moveq	#12,d0
			jsr	GetSysPrefsItem
			rts

DrawBetwnCmd:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	DrawBetweenFlag
			bne	ReadConfig

			bchg	#0,DrawBetweenFlag
			move.b	#1,DrawUpdateFlag

			bsr.s	GetDrawBetweenItem
			bset	#0,12(a0)
			bra	ReadConfig

GetDrawBetweenItem:	moveq	#4,d0
			jsr	GetSysPrefsItem
			rts

SmoothChange:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	SmoothChgFlag
			bne	ReadConfig

			bchg	#0,SmoothChgFlag

			bsr.s	GetSmoothChgItem
			bset	#0,12(a0)
			bra	ReadConfig

GetSmoothChgItem:	moveq	#16,d0
			jsr	GetSysPrefsItem
			rts

NoDragPlease:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	NoDragFlag
			bne	ReadConfig

			bchg	#0,NoDragFlag

			bsr.s	GetNoDragItem
			bset	#0,12(a0)
			bra	ReadConfig

GetNoDragItem:		moveq	#17,d0
			jsr	GetSysPrefsItem
			rts

SetMaxPPS:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			bsr	GetNumber

			cmpi.l	#1000,d0
			blo	ConError

			cmpi.l	#28867,d0
			bhi	ConError

			mulu	#10,d0

			move.l	d0,MaxPPS
			bra	ReadConfig

Master2:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	SerialFlag
			bne	ReadConfig

			tst.b	LASERfIREFlag
			bne	ReadConfig

			tst.b	MasterFlag
			bne	ReadConfig

			bchg	#0,MasterFlag
			clr.b	SlaveFlag
			jsr	SetMenus3
			bra	ReadConfig

Slave2:			adda.w	#5,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	SerialFlag
			bne	ReadConfig

			tst.b	LASERfIREFlag
			bne	ReadConfig

			tst.b	SlaveFlag
			bne	ReadConfig

			bchg	#0,SlaveFlag
			clr.b	MasterFlag
			jsr	SetMenus3
			bra	ReadConfig

SetDefXSize:		adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			move.b	(a1)+,d0
			cmpi.b	#"1",d0
			blo	ConError
			cmpi.b	#"4",d0
			bhi	ConError

			cmpi.b	#" ",(a1)+
			bne	ConError

			subi.b	#"1",d0
			lea	ScrDef1,a0
			mulu	#8,d0
			adda.l	d0,a0
			move.l	a0,-(sp)
			bsr	GetNumber
			movea.l	(sp)+,a0

			cmpi.l	#64,d0
			bhi	ConError

			move.w	d0,(a0)
			bra	ReadConfig

SetDefYSize:		adda.w	#14,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			move.b	(a1)+,d0
			cmpi.b	#"1",d0
			blo	ConError
			cmpi.b	#"4",d0
			bhi	ConError

			cmpi.b	#" ",(a1)+
			bne	ConError

			subi.b	#"1",d0
			lea	ScrDef1,a0
			mulu	#8,d0
			adda.l	d0,a0
			move.l	a0,-(sp)
			bsr	GetNumber
			movea.l	(sp)+,a0

			cmpi.l	#64,d0
			bhi	ConError

			move.w	d0,2(a0)
			bra	ReadConfig

SetDefXPos:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			move.b	(a1)+,d0
			cmpi.b	#"1",d0
			blo	ConError
			cmpi.b	#"4",d0
			bhi	ConError

			cmpi.b	#" ",(a1)+
			bne	ConError

			subi.b	#"1",d0
			lea	ScrDef1,a0
			mulu	#8,d0
			adda.l	d0,a0
			move.l	a0,-(sp)
			bsr	GetNumber
			movea.l	(sp)+,a0

			cmpi.l	#XMax,d0
			bhi	ConError

			move.w	d0,4(a0)
			bra	ReadConfig

SetDefYPos:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			move.b	(a1)+,d0
			cmpi.b	#"1",d0
			blo	ConError
			cmpi.b	#"4",d0
			bhi	ConError

			cmpi.b	#" ",(a1)+
			bne	ConError

			subi.b	#"1",d0
			lea	ScrDef1,a0
			mulu	#8,d0
			adda.l	d0,a0
			move.l	a0,-(sp)
			bsr	GetNumber
			movea.l	(sp)+,a0

			cmpi.l	#YMax,d0
			bhi	ConError

			move.w	d0,6(a0)
			bra	ReadConfig

SetLASERfIRE:		adda.w	#11,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			tst.b	LASERfIREFlag
			bne	ReadConfig

			tst.b	SerialFlag
			bne	ReadConfig

			movea.l	IORequestPtr,a1
			move.w	#11,28(a1)		;Command
			move.l	#115200,60(a1)		;Bps
			move.l	#250000,64(a1)		;Break time
			move.b	#8,76(a1)		;Rd bits
			move.b	#8,77(a1)		;Wr bits
			move.b	#1,78(a1)		;Stop bits
			move.b	#$b4,79(a1)		;No XON/XOFF, Shared, Fast, CTS/RTS
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)

			lea	CheckLaser2,a0
			jsr	PrintStatus

			move.b	#$fa,d0
			jsr	Echo

			clr.l	SequenceCountTrigTemp

.Loop:			jsr	GetByte
			bne.s	.GotByte
			jsr	ShortDelay
			cmpi.l	#20,SequenceCountTrigTemp
			blo.s	.Loop

			movea.l	IORequestPtr,a1
			move.w	#11,28(a1)		;Command
			move.l	#9600,60(a1)		;Bps
			move.l	#250000,64(a1)		;Break time
			move.b	#8,76(a1)		;Rd bits
			move.b	#8,77(a1)		;Wr bits
			move.b	#1,78(a1)		;Stop bits
			move.b	#$b0,79(a1)		;No XON/XOFF, Shared, Fast
			movea.l	(4).l,a6
			jsr	_LVODoIO(a6)

			jsr	FlashScreen
			lea	CheckLaserBad2,a0
			jsr	PrintStatus
			jsr	LongDelay
			bra	ReadConfig

.GotByte:		cmpi.b	#"X",d0
			bne.s	.Loop

			move.b	#1,LASERfIREFlag

			jsr	SerialItemsOff

			clr.b	SlaveFlag
			clr.b	MasterFlag
			jsr	SetMenus3

			bsr	ParShutterOn2

			lea	CheckLaserOK2,a0
			jsr	PrintStatus
			jsr	ShortDelay
			bra	ReadConfig

GetLoadFilename:	adda.w	#7,a1
			cmpa.l	a1,a2
			bls	ConError

			move.l	a1,ConfigPtr

			sub.l	d0,d0
			move.b	(a1)+,d0
			subi.b	#"0",d0
			cmpi.b	#9,d0
			bhi	ConError

			cmpa.l	a1,a2
			bls	ConError

			sub.l	d1,d1
			move.b	(a1),d1
			cmpi.b	#" ",d1
			beq.s	.GotIt

			subi.b	#"0",d1
			cmpi.b	#9,d1
			bhi	ConError

			mulu	#10,d0
			add.b	d1,d0
			addq.l	#1,a1

			cmpa.l	a1,a2
			bls	ConError

			sub.l	d2,d2
			move.b	(a1),d2
			cmpi.b	#" ",d2
			beq.s	.GotIt

			subi.b	#"0",d2
			cmpi.b	#9,d2
			bhi	ConError

			sub.b	d1,d0
			mulu	#10,d0
			mulu	#10,d1
			add.w	d1,d0
			add.w	d2,d0
			addq.l	#1,a1

.GotIt:			subq.w	#1,d0
			move.w	d0,LoadNumber

			addq.l	#2,a1
			cmpa.l	a1,a2
			bls	ConError

			cmpi.b	#'"',-1(a1)
			bne	ConError
			move.l	a1,ConfigPtr

			lea	ASCIIBuffer,a0

.Loop:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip
			cmpi.b	#$a,d0
			beq.s	.Skip
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop

.Skip:			clr.b	(a0)
			lea	ASCIIBuffer,a1
			movea.l	a1,a0

.Loop2:			move.b	(a1)+,d0
			beq.s	.End
			cmpi.b	#"/",d0
			beq.s	.Skip2
			cmpi.b	#":",d0
			bne.s	.Loop2

.Skip2:			movea.l	a1,a0
			bra.s	.Loop2

.End:			rts


;Check if Laser is ready:

LaserReady:		;tst.b	SerialFlag
			;beq.s	.Skip

			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	StartSeq

.Skip:			lea	CheckLaser,a0
			jsr	PrintStatus

			move.b	#"C",d0
			jsr	Echo

			clr.l	SequenceCountTrigTemp

.Loop:			jsr	GetByte
			bne.s	.GotByte
			jsr	ShortDelay
			cmpi.l	#20,SequenceCountTrigTemp
			blo.s	.Loop

			jsr	FlashScreen
			lea	CheckLaserBad,a0
			jsr	PrintStatus
			jsr	LongDelay
			bra	StartSeq

.GotByte:		cmpi.b	#"X",d0
			bne.s	.Loop

			bsr.s	WaitIntroScreen

			move.b	#"W",d0			;Fans off
			jsr	Echo

			move.b	#"R",d0			;Shutter off
			jsr	Echo

			move.b	#"T",d0			;Stanby on
			jsr	Echo

			move.b	#$d,d0			;Center mirror
			jsr	Echo

			lea	CheckLaserOK,a0
			jsr	PrintStatus
			jsr	LongDelay
			bra.s	StartSeq


WaitIntroScreen:	clr.l	SequenceCountTrigTemp

.Loop:			jsr	GetByte
			bne.s	.Loop2
			jsr	ShortDelay
			cmpi.l	#30,SequenceCountTrigTemp
			blo.s	.Loop
			bra	Error10

.Loop2:			clr.l	SequenceCountTrigTemp
.Next:			jsr	GetByte
			bne.s	.Loop2
			jsr	ShortDelay
			cmpi.l	#2,SequenceCountTrigTemp
			bls.s	.Next
			rts


;Auto start sequence

StartSeq:		lea	StartSeqFilename,a0
			jsr	MakeFileName
			jsr	LoadFile
			tst.l	d0
			bne.s	Scope

			jsr	FreeSeqMem
			move.l	FileMemPtr,SeqMemPtr
			move.l	FileMemSize,SeqMemSize
			clr.l	FileMemSize

			lea	StartSeqFilename,a0
			lea	Filename2,a1
			jsr	MoveString
			bra	Start


;Update scope and check for commands:

Scope:			jsr	UpdateOutput
			bsr	Clock

			tst.b	DrawMode
			beq.s	.DSkip

			tst.b	DrawScopeFlag
			beq.s	.DSkip

			tst.l	DrawLen
			beq.s	.DSkip

			jsr	GridOff
			jsr	CursorOff
			jsr	LineLineOff
			jsr	ArcOutlineOff
			jsr	BoxOutlineOff
			jsr	EllipseOutlineOff
			jsr	TemplateOff
			jsr	RollDotOff
			bra.s	.DSkip2

.DSkip:			jsr	GridFlash
			jsr	CursorFlash
			jsr	LineLineFlash
			jsr	ArcOutlineFlash
			jsr	BoxOutlineFlash
			jsr	EllipseOutlineFlash
			jsr	TemplateFlash
			jsr	RollDotFlash

.DSkip2:		jsr	ShiftPos2
			jsr	UpdateMagGlass
			jsr	UpdateText

			move.b	PlayStatus,d0
			beq.s	Scope2

			cmpi.b	#3,d0			;Pause?
			bhs.s	Scope2

			tst.b	WaitMoveFlag
			beq.s	.Skip13

			tst.b	MoveStatus
			bne.s	Scope2

.Skip13:		tst.l	WaitCount
			bmi	Play

Scope2:			clr.l	AutoStopCount

			jsr	MoveLaser
			bsr	StrobeIt

			tst.b	IconifyFlag
			bne	CheckMsgs

			tst.b	DrawMode
			beq	.Scope

			tst.b	DrawScopeFlag
			beq	.Scope

			tst.b	DrawUpdateFlag
			beq.s	.DSkip

			clr.b	DrawUpdateFlag
			clr.l	DrawLen

			jsr	BlankScope

			movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq	CheckMsgs

			move.l	a0,XDrawPtr
			adda.w	#MaxPoints,a0
			move.l	a0,YDrawPtr
			adda.w	#MaxPoints,a0
			move.l	a0,ZDrawPtr

			move.l	Len0,DrawLen

.DSkip:			moveq	#3,d0
			jsr	SetAPen

			moveq	#10,d3

.DNext:			tst.l	DrawLen
			beq	CheckMsgs

			movea.l	XDrawPtr,a0		;X
			sub.l	d0,d0
			move.b	(a0)+,d0
			move.l	a0,XDrawPtr
			addi.b	#127,d0
			addi.w	#ScopeX+4,d0

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			movea.l	ZDrawPtr,a1		;Z
			sub.l	d2,d2
			move.b	(a1)+,d2
			move.l	a1,ZDrawPtr
			neg.b	d2
			bra.s	.TSkip2

.TSkip:			movea.l	YDrawPtr,a1		;Y
			sub.l	d2,d2
			move.b	(a1)+,d2
			move.l	a1,YDrawPtr

.TSkip2:		addi.b	#127,d2

			tst.b	BigScreenFlag
			beq.s	.DSkip2
			move.l	#ScopeY+129+127,d1
			bra.s	.DSkip3

.DSkip2:		addq.b	#1,d2
			lsr.b	#1,d2
			move.l	#ScopeY+129,d1

.DSkip3:		sub.w	d2,d1

			move.l	d3,-(sp)

			tst.b	DrawBetweenFlag
			beq	.DBSkip2

			tst.l	DBLastX
			bne.s	.DBSkip

			move.l	d0,DBLastX
			move.l	d1,DBLastY
			bra.s	.DBSkip2

.DBSkip:		move.l	DBLastX,d2
			move.l	DBLastY,d3

			sub.w	d0,d2
			bpl.s	.DBSSkip
			neg.w	d2

.DBSSkip:		cmpi.w	#2,d2
			bhs.s	.DBSSkip3

			sub.w	d1,d3
			bpl.s	.DBSSkip2
			neg.w	d3

.DBSSkip2:		cmpi.w	#2,d3
			blo.s	.DBSSkip4

.DBSSkip3:		move.l	d0,-(sp)
			move.l	d1,-(sp)
			sub.l	d0,d0
			jsr	SetAPen
			move.l	DBLastX,d0
			move.l	DBLastY,d1
			jsr	Move
			move.l	(sp),d1
			move.l	4(sp),d0
			jsr	Draw
			moveq	#3,d0
			jsr	SetAPen
			move.l	DBLastX,d0
			move.l	DBLastY,d1
			jsr	Pixel2
			move.l	(sp)+,d1
			move.l	(sp)+,d0

.DBSSkip4:		move.l	d0,DBLastX
			move.l	d1,DBLastY

.DBSkip2:		jsr	Pixel2
			move.l	(sp)+,d3
			subq.l	#1,DrawLen
			dbf	d3,.DNext
			bra	CheckMsgs

.Scope:			moveq	#1,d0
			jsr	SetAPen

			sub.l	d0,d0
			move.w	PixelTable,d0
			beq.s	.MoveTable
			sub.l	d1,d1
			move.w	PixelTable+2,d1

			tst.b	DrawMode
			bne.s	.FastScope

			tst.b	FastScopeFlag
			beq.s	.Skip

.FastScope:		jsr	Pixel2
			bra.s	.MoveTable

.Skip:			move.l	d0,-(sp)
			move.l	d1,-(sp)
			move.l	EraseX,d0
			move.l	EraseY,d1
			jsr	Move
			move.l	(sp)+,d1
			move.l	(sp)+,d0
			move.l	d0,EraseX
			move.l	d1,EraseY
			jsr	Draw

.MoveTable:		lea	PixelTable,a0
			lea	4(a0),a1
			moveq	#TableSize-2,d0

.Loop:			move.l	(a1)+,(a0)+
			dbf	d0,.Loop

			moveq	#3,d0
			jsr	SetAPen

			movea.l	Loc0PtrTemp,a0		;Location pointers
			movea.l	Loc1PtrTemp,a1
			movea.l	Loc2PtrTemp,a2
			movea.l	Loc3PtrTemp,a3

			tst.b	DMAFlag
			beq	.NotDMA

			sub.l	d0,d0			;Get X
			move.b	(a0),d0

			tst.b	InvertXFlag
			beq.s	.ISkip
			neg.b	d0

.ISkip:			addi.b	#128,d0
			lsr.b	#1,d0

			tst.b	DrawMode2
			beq.s	.HiSkip

			move.b	DC3Offset,d1
			lsl.b	#1,d1
			bra.s	.HiSkip2

.HiSkip:		move.l	Len32,d1
			mulu	Phase32,d1
			divu	#360,d1
			andi.w	#$fffe,d1
			move.b	(a3,d1),d1

			tst.b	InvertXFlag
			beq.s	.HiSkip2
			neg.b	d1

.HiSkip2:		addi.b	#128,d1
			lsr.b	#1,d1
			add.b	d1,d0
			addi.w	#ScopeX+4,d0

			move.l	Len12,d1		;Get Y
			mulu	Phase12,d1
			divu	#360,d1
			andi.w	#$fffe,d1
			sub.l	d3,d3
			move.b	(a1,d1),d3

			tst.b	InvertYFlag
			beq.s	.ISkip2
			neg.b	d3

.ISkip2:		addi.b	#128,d3
			lsr.b	#1,d3

			tst.b	DrawMode2
			beq.s	.HiSkip3

			move.b	DC2Offset,d2
			lsl.b	#1,d2
			bra.s	.HiSkip4

.HiSkip3:		move.l	Len22,d1
			mulu	Phase22,d1
			divu	#360,d1
			andi.w	#$fffe,d1
			move.b	(a2,d1),d2

			tst.b	InvertYFlag
			beq.s	.HiSkip4
			neg.b	d2

.HiSkip4:		addi.b	#128,d2
			lsr.b	#1,d2
			add.b	d2,d3

			tst.b	BigScreenFlag
			beq.s	.BSkip

			move.l	#ScopeY+129+127,d1
			bra.s	.BSkip2

.BSkip:			addq.b	#1,d3
			lsr.b	#1,d3
			move.l	#ScopeY+129,d1

.BSkip2:		sub.w	d3,d1

			move.w	LowSpeed,d2
			add.w	d2,Speed0Temp
			add.w	d2,Speed1Temp
			add.w	d2,Speed2Temp
			add.w	d2,Speed3Temp

.Speed0:		move.w	Speed0,d2
			cmp.w	Speed0Temp,d2
			bhi.s	.Speed1

			sub.l	d3,d3
			move.w	Speed0Temp,d3
			divu	d2,d3
			adda.w	d3,a0
			swap	d3
			move.w	d3,Speed0Temp

.Speed1:		move.w	Speed1,d2
			cmp.w	Speed1Temp,d2
			bhi.s	.Speed2

			sub.l	d3,d3
			move.w	Speed1Temp,d3
			divu	d2,d3
			adda.w	d3,a1
			swap	d3
			move.w	d3,Speed1Temp

.Speed2:		move.w	Speed2,d2
			cmp.w	Speed2Temp,d2
			bhi.s	.Speed3

			sub.l	d3,d3
			move.w	Speed2Temp,d3
			divu	d2,d3
			adda.w	d3,a2
			swap	d3
			move.w	d3,Speed2Temp

.Speed3:		move.w	Speed3,d2
			cmp.w	Speed3Temp,d2
			bhi.s	.Speed4

			sub.l	d3,d3
			move.w	Speed3Temp,d3
			divu	d2,d3
			adda.w	d3,a3
			swap	d3
			move.w	d3,Speed3Temp

.Speed4:		movea.l	Loc0Ptr,a4
			adda.l	Len02,a4
			cmpa.l	a4,a0
			blo.s	.Okay

			move.l	a0,d2
			movea.l	Loc0Ptr,a0
			sub.l	a0,d2
			divu	Len02+2,d2
			swap	d2
			adda.w	d2,a0

.Okay:			movea.l	Loc1Ptr,a4
			adda.l	Len12,a4
			cmpa.l	a4,a1
			blo.s	.Okay2

			move.l	a1,d2
			movea.l	Loc1Ptr,a1
			sub.l	a1,d2
			divu	Len12+2,d2
			swap	d2
			adda.w	d2,a1

.Okay2:			movea.l	Loc2Ptr,a4
			adda.l	Len22,a4
			cmpa.l	a4,a2
			blo.s	.Okay3

			move.l	a2,d2
			movea.l	Loc2Ptr,a2
			sub.l	a2,d2
			divu	Len22+2,d2
			swap	d2
			adda.w	d2,a2

.Okay3:			movea.l	Loc3Ptr,a4
			adda.l	Len32,a4
			cmpa.l	a4,a3
			blo.s	.Okay4

			move.l	a3,d2
			movea.l	Loc3Ptr,a3
			sub.l	a3,d2
			divu	Len32+2,d2
			swap	d2
			adda.w	d2,a3

.Okay4:			move.l	a0,Loc0PtrTemp
			move.l	a1,Loc1PtrTemp
			move.l	a2,Loc2PtrTemp
			move.l	a3,Loc3PtrTemp
			bra	.Skip2

.NotDMA:		sub.l	d0,d0			;Get X
			move.b	(a0),d0

			tst.b	InvertXFlag
			beq.s	.ISkip3
			neg.b	d0

.ISkip3:		addi.b	#128,d0
			lsr.b	#1,d0

			tst.b	DrawMode2
			beq.s	.HiSkip5

			move.b	DC3Offset,d1
			lsl.b	#1,d1
			bra.s	.HiSkip6

.HiSkip5:		move.b	(a3),d1

			tst.b	InvertXFlag
			beq.s	.HiSkip6
			neg.b	d1

.HiSkip6:		addi.b	#128,d1
			lsr.b	#1,d1
			add.b	d1,d0

			addi.w	#ScopeX+4,d0

			sub.l	d3,d3			;Get Y
			move.b	(a1),d3

			tst.b	InvertYFlag
			beq.s	.ISkip4
			neg.b	d3

.ISkip4:		addi.b	#128,d3
			lsr.b	#1,d3

			tst.b	DrawMode2
			beq.s	.HiSkip7

			move.b	DC2Offset,d2
			lsl.b	#1,d2
			bra.s	.HiSkip8

.HiSkip7:		move.b	(a2),d2

			tst.b	InvertYFlag
			beq.s	.HiSkip8
			neg.b	d2

.HiSkip8:		addi.b	#128,d2
			lsr.b	#1,d2
			add.b	d2,d3

			tst.b	BigScreenFlag
			beq.s	.BSkip3

			move.l	#ScopeY+129+127,d1
			bra.s	.BSkip4

.BSkip3:		addq.b	#1,d3
			lsr.b	#1,d3
			move.l	#ScopeY+129,d1

.BSkip4:		sub.w	d3,d1

.Skip2:			move.w	d0,PixelTable+(4*TableSize-4)
			move.w	d1,PixelTable+(4*TableSize-2)

			tst.b	DrawMode
			bne.s	.FastScope2

			tst.b	FastScopeFlag
			beq.s	.Skip3

.FastScope2:		jsr	ReadPixel2

			cmpi.b	#1,d0
			bne.s	.Miss

			sub.l	d0,d0
			move.w	PixelTable+(4*TableSize-4),d0
			sub.l	d1,d1
			move.w	PixelTable+(4*TableSize-2),d1

			move.l	d0,DrawX
			move.l	d1,DrawY
			jsr	Pixel2
			bra.s	CheckMsgs

.Miss:			clr.l	PixelTable+(4*TableSize-4)
			bra.s	CheckMsgs

.Skip3:			move.l	d0,-(sp)
			move.l	d1,-(sp)
			move.l	DrawX,d0
			move.l	DrawY,d1
			jsr	Move
			move.l	(sp)+,d1
			move.l	(sp)+,d0
			move.l	d0,DrawX
			move.l	d1,DrawY
			jsr	Draw

CheckMsgs:		move.w	NextSelect,d4
			cmpi.w	#$ffff,d4
			bne	.Menu2

			bsr	CheckSerial

			movea.l	LaserWnd,a0
			jsr	GetWndMsg
			beq	.Skip4

			movea.l	d0,a1

			move.w	$1a(a1),d7		;Qualifiers
			move.b	d7,d0
			andi.b	#$3,d0
			beq.s	.SSkip

			tst.b	ShiftFlag
			bne.s	.Skip

			move.b	#1,ShiftFlag

			tst.b	ShiftMode
			bne.s	.Skip

			clr.b	XShiftPos
			clr.b	YShiftPos
			clr.b	ZShiftPos
			bra.s	.Skip

.SSkip:			tst.b	ShiftFlag
			beq.s	.Skip

			clr.b	ShiftFlag
			jsr	ShiftOff

.Skip:			btst	#3,d7
			beq.s	.CSkip

			tst.b	CtrlFlag
			bne.s	.Skip2

			move.b	#1,CtrlFlag
			bra.s	.Skip2

.CSkip:			clr.b	CtrlFlag

.Skip2:			clr.b	AltFlag
			move.b	d7,d0
			andi.b	#$30,d0
			beq.s	.Skip3
			move.b	#1,AltFlag

.Skip3:			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Address
			move.w	$18(a1),d4		;Code
			move.w	$20(a1),d5		;Mouse X
			move.w	$22(a1),d6		;Mouse Y
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#4,d2			;MouseMove?
			bne.l	MouseMove

			btst	#3,d2			;MouseButton?
			bne.l	MouseButton

			clr.b	AutoGadStatus

			btst	#10,d2			;Raw key?
			bne	.RawKey

			btst	#8,d2			;Menu?
			bne	.Menu

			movea.l	d3,a0

			btst	#5,d2			;Gadget down?
			bne	.GadDown

			btst	#6,d2			;Gadget up?
			bne	.GadUp

			btst	#9,d2			;Close window?
			bne.l	Iconify

.Skip4:			move.b	AutoGadStatus,d0
			beq.s	.Skip6

			cmpi.b	#2,d0
			beq.s	.Skip5

			cmpi.b	#18,AutoGadCount
			blo.s	.Skip6

			clr.b	AutoGadCount
			move.b	#2,AutoGadStatus
			bra.s	.Skip6

.Skip5:			cmpi.b	#2,AutoGadCount
			blo.s	.Skip6

			clr.b	AutoGadCount

			tst.b	MasterFlag
			beq.s	.MSkip
			move.b	LastSyncByte,d0
			jsr	Echo

.MSkip:			movea.l	AddressPtr,a6
			jmp	(a6)

.Skip6:			cmpi.b	#1,JoyCount
			blo	Scope

			clr.b	JoyCount

			move.w	$dff00c,d0		;Joy1dat
			btst	#1,d0
			bne	East
			btst	#9,d0
			bne	West
			btst	#8,d0
			bne	North
			btst	#0,d0
			bne	South
			move.b	$bfe001,d0		;PA7
			btst	#7,d0
			beq	CenterIt
			bra	Scope

.RawKey:		lea	RawKeyTableShift,a0
			tst.b	ShiftFlag
			bne.s	.Loop
			lea	RawKeyTableCtrl,a0
			tst.b	CtrlFlag
			bne.s	.Loop
			lea	RawKeyTableAlt,a0
			tst.b	AltFlag
			bne.s	.Loop
			tst.b	ShiftMode
			bne.s	.RSkip
			tst.b	RollMode
			bne.s	.RSkip
			tst.b	ResizeMode
			bne.s	.RSkip
			tst.b	TextMode
			bne.l	TypingText

.RSkip:			lea	RawKeyTable,a0
			bra.s	.Loop

.Menu:			cmpi.w	#$ffff,d4
			beq	Scope

.Menu2:			jsr	GetNextSelect

			lea	MenuTable,a0

.Loop:			cmp.w	(a0),d4
			beq.s	.Found
			addq.l	#6,a0
			tst.w	(a0)
			bne.s	.Loop

			move.w	#$ffff,NextSelect
			bra	Scope

.Found:			movea.l	2(a0),a6
			jmp	(a6)

.GadDown:		move.l	40(a0),AddressPtr
			beq	Scope

			movea.l	40(a0),a6
			bsr.s	GetSyncByte

			move.b	#1,AutoGadStatus
			clr.b	AutoGadCount
			bra	Scope

.GadUp:			tst.l	40(a0)
			beq	Scope

			movea.l	40(a0),a6
			bsr.s	GetSyncByte
			beq.s	.Jmp

			move.l	a6,-(sp)
			jsr	Echo
			movea.l	(sp)+,a6

.Jmp:			jmp	(a6)

GetSyncByte:		tst.b	MasterFlag
			beq.s	.End

			lea	GadgetTable,a0

.Loop:			move.l	(a0)+,d0
			beq.s	.Skip
			cmpa.l	d0,a6
			bne.s	.Loop
			bra.s	.SyncByte

.Skip:			tst.b	BigScreenFlag
			beq.s	.End

.Loop2:			move.l	(a0)+,d0
			beq.s	.End
			cmpa.l	d0,a6
			bne.s	.Loop2

.SyncByte:		suba.l	#GadgetTable,a0
			move.l	a0,d0
			lsr.l	#2,d0
			addi.b	#129,d0
			move.b	d0,LastSyncByte
.End:			rts

Clock:			cmpi.b	#51,ClockCount
			blo	.End

			clr.b	ClockCount

			move.l	#Days,d1
			movea.l	DosBase,a6
			jsr	_LVODateStamp(a6)

			move.l	Mins,d1
			move.l	d1,d0
			divu	#60,d0
			andi.l	#$ffff,d0
			move.l	d0,d2
			cmpi.b	#12,d0
			beq.s	.Skip
			blo.s	.Skip2
			subi.b	#12,d0
.Skip:			moveq	#$70,d3
			bra.s	.Skip3
.Skip2:			moveq	#$61,d3
			tst.b	d0
			bne.s	.Skip3
			moveq	#12,d0
.Skip3:			lea	TimeStr,a0
			bsr.s	Convert
			move.b	#$3a,(a0)+
			move.l	d1,d0
			mulu	#60,d2
			sub.l	d2,d0
			bsr.s	Convert
			move.b	#$3a,(a0)+
			move.l	Ticks,d0
			divu	#50,d0
			andi.l	#$ffff,d0
			bsr.s	Convert
			move.b	#$20,(a0)+
			move.b	d3,(a0)+
			move.b	#$6d,(a0)+
			clr.b	(a0)

			lea	TimeStr,a0
			cmpi.b	#$30,(a0)
			bne.s	.Skip4
			addq.l	#1,a0

.Skip4:			lea	LaserIText21,a1
			move.b	#$20,10(a1)
			jsr	MoveString
			move.b	#$20,-(a1)

			lea	LaserText21,a1
			jsr	PrintWinText
.End:			rts

Convert:		divu	#10,d0
			addi.b	#$30,d0
			move.b	d0,(a0)+
			swap	d0
			addi.b	#$30,d0
			move.b	d0,(a0)+
			rts

CheckSerial:		tst.b	SerialFlag
			bne	.End

			tst.b	SlaveFlag
			beq.s	.Skip

			addi.b	#1,SerialCount2
			cmpi.b	#10,SerialCount2
			blo.s	.End

			clr.b	SerialCount2

.Next:			jsr	GetByte
			beq.s	.End

			subi.l	#130,d0
			cmpi.l	#119,d0
			bhi.s	.Next

			cmpi.b	#87,d0
			beq.s	.Next

			addq.l	#4,sp

			cmpi.b	#79,d0
			beq	ShutterRaw

			cmpi.b	#80,d0
			beq	StandbyRaw

			cmpi.b	#81,d0
			beq	FastMoveRaw

			cmpi.b	#82,d0
			beq	StrobeRaw

			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6
			jmp	(a6)

.Skip:			cmpi.b	#23,SerialCount
			blo.s	.End

			clr.b	SerialCount

			jsr	GetByte
			bne	Error10
.End:			rts

StrobeIt:		tst.b	StrobeFlag
			beq.s	.End

			cmpi.b	#StrobeRate,StrobeCount
			blo.s	.End

			clr.b	StrobeCount

			btst	#0,StrobeFlag
			beq.s	.Off

			bchg	#2,StrobeFlag
			bne.s	.Skip
			bsr	ParShutterOn
			rts

.Skip:			bsr.s	ParShutterOff
.End:			rts

.Off:			clr.b	StrobeFlag
			btst	#0,ShutterFlag
			bne.s	.On
			bsr.s	ParShutterOff
			bra.s	.Skip2

.On:			bsr	ParShutterOn
.Skip2:			bsr	CheckShutter
			rts

ParShutterOff:		jsr	SendUnitID
ParShutterOff2:		clr.b	SoleniodFlag
			bclr.b	#7,ParPort
			move.b	#$ff,$bfe301		;ddrb output
			move.b	ParPort,$bfe101

			move.b	UnitNumber,d0
			beq.s	.Skip3
			cmpi.b	#"4",d0
			bhi.s	.Skip3

			tst.b	MasterFlag
			beq.s	.MSkip
			bsr	AquariusDelay

.MSkip:			cmpi.b	#"1",d0
			bne.s	.Skip
			move.b	#$80,d0
			jsr	Echo
			move.b	#1,d0
			jsr	Echo
			rts

.Skip:			cmpi.b	#"2",d0
			bne.s	.Skip2
			move.b	#$90,d0
			jsr	Echo
			move.b	#1,d0
			jsr	Echo
			rts

.Skip2:			move.b	#$80,d0
			jsr	Echo
			move.b	#1,d0
			jsr	Echo
			bsr	AquariusDelay
			move.b	#$90,d0
			jsr	Echo
			move.b	#1,d0
			jsr	Echo
			rts

.Skip3:			move.b	#"R",d0
			jsr	Echo
			rts

ParShutterOn:		jsr	SendUnitID
ParShutterOn2:		move.b	#1,SoleniodFlag
			bset.b	#7,ParPort
			move.b	#$ff,$bfe301		;ddrb output
			move.b	ParPort,$bfe101

			move.b	UnitNumber,d0
			beq.s	.Skip3
			cmpi.b	#"4",d0
			bhi.s	.Skip3

			tst.b	MasterFlag
			beq.s	.MSkip
			bsr.s	AquariusDelay

.MSkip:			cmpi.b	#"1",d0
			bne.s	.Skip
			move.b	#$80,d0
			jsr	Echo
			move.b	#0,d0
			jsr	Echo
			rts

.Skip:			cmpi.b	#"2",d0
			bne.s	.Skip2
			move.b	#$90,d0
			jsr	Echo
			move.b	#0,d0
			jsr	Echo
			rts

.Skip2:			move.b	#$80,d0
			jsr	Echo
			move.b	#0,d0
			jsr	Echo
			bsr.s	AquariusDelay
			move.b	#$90,d0
			jsr	Echo
			move.b	#0,d0
			jsr	Echo
			rts

.Skip3:			move.b	#"E",d0
			jsr	Echo
			rts

AquariusDelay:		move.w	#500,d1
			move.w	StopDelayCount,d2

.Wait:			move.w	d2,d0
.Loop:			dbf	d0,.Loop
			dbf	d1,.Wait
			rts


;Process LASER commands:

GetCommand:		clr.b	Sync
			move.b	#1,FreqSyncFlag
			move.w	Freq0,Freq0Sync
			move.w	Freq1,Freq1Sync
			move.w	Freq2,Freq2Sync
			move.w	Freq3,Freq3Sync

NextCommand:		clr.l	NextCmdPtr
			clr.b	CommandSubCode
			clr.b	FromChannel
			clr.b	ToChannel
			clr.b	Value2

			move.b	(a0)+,d0
			beq	Error

			jsr	UpperByte

			cmpi.b	#"F",d0			;Factory?
			beq	Factory

			cmpi.b	#"L",d0			;Location?
			beq	Next

			cmpi.b	#"-",d0			;To?
			beq.s	.Skip

			subi.b	#"0",d0			;Channel #
			cmpi.b	#3,d0
			bhi	Error
			move.b	d0,FromChannel

			move.b	(a0)+,d0
			beq	Error

			cmpi.b	#"-",d0			;To?
			bne.s	.Skip3

.Skip:			move.b	(a0)+,d0
			beq	Error

			cmpi.b	#"0",d0
			blo	Error

			cmpi.b	#"3",d0
			bhi.s	.Skip2

			subi.b	#"0",d0			;Channel #
			move.b	d0,ToChannel

			move.b	(a0)+,d0
			beq	Error
			bra.s	.Skip3

.Skip2:			move.b	#3,ToChannel

.Skip3:			jsr	UpperByte

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
			bne	Error

.Okay:			move.b	d1,CommandCode

			move.b	(a0)+,d0		;Get sub command
			beq	Error

			jsr	UpperByte

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
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a1)+
			cmpa.l	#ValueASCII+10,a1
			blo.s	.Loop
			bra	Error2

.Okay2:			move.b	d1,CommandSubCode
			bra.s	.GetValue

.Next2:			move.b	(a0)+,d0
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			subi.b	#"0",d0
			move.b	d0,Value2

			move.b	(a0)+,d0
			beq.s	.Done
			cmpi.b	#" ",d0
			bne	Error2

.StripSpaces:		move.b	(a0),d0
			beq.s	.Done
			cmpi.b	#" ",d0
			bne.s	.Next

			addq.l	#1,a0
			bra.s	.StripSpaces

.Next:			move.l	a0,NextCmdPtr

.Done:			clr.b	(a1)
			lea	ValueASCII,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error
			move.l	d0,Value

			move.b	FromChannel,d0

NextChannel:		move.b	d0,ChannelNumber

			sub.l	d0,d0
			move.b	CommandCode,d0

			sub.l	d1,d1
			move.b	CommandSubCode,d1
			beq.s	.Skip

			mulu	#5,d1
			add.l	d1,d0

.Skip:			mulu	#4,d0
			lea	CommandTable,a6
			movea.l	(a6,d0),a6
			jmp	(a6)

Next:			move.b	ChannelNumber,d0
			addq.b	#1,d0
			cmp.b	ToChannel,d0
			bls.s	NextChannel

			movea.l	NextCmdPtr,a0
			move.l	a0,d0
			bne	NextCommand

			clr.b	FreqSyncFlag
			jsr	CheckRestart

			tst.b	FromPreset
			beq	Play

			clr.b	FromPreset
			bra	Scope

Error29:		jsr	FlashScreen
			lea	Error29Text,a0
			jsr	PrintStatus
			bra	Scope

Error22:		jsr	FlashScreen
			lea	Error22Text,a0
			jsr	PrintStatus
			bra	Scope

Error17:		movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error17Text,a0
			jsr	PrintStatus
			bra	Scope

Error16:		jsr	FlashScreen
			lea	Error16Text,a0
			jsr	PrintStatus
			bra	Scope

Error10:		movea.l	StackPtr,sp
			jsr	ClearSerial
			jsr	FlashScreen
			lea	Error10Text,a0
			jsr	PrintStatus
			bra	Scope

Error8:			jsr	FlashScreen
			lea	Error8Text,a0
			jsr	PrintStatus
			bra	Scope

Error7:			movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error7Text,a0
			jsr	PrintStatus
			bra	Scope

Error5:			jsr	FlashScreen
			lea	Error5Text,a0
			jsr	PrintStatus
			bra	Scope

Error4:			jsr	FlashScreen
			lea	Error4Text,a0
			jsr	PrintStatus
			bra	Scope

Error3:			clr.b	AddLfFlag
			jsr	FlashScreen
			lea	Error3Text,a0
			jsr	PrintStatus
			tst.b	FromConfig
			beq.s	.Skip
			rts

.Skip:			movea.l	StackPtr,sp
			bra	Scope

Error2:			movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error2Text,a0
			jsr	PrintStatus
			bra	Scope

Error:			movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error1Text,a0
			jsr	PrintStatus
			bra	Scope

CommandTable:		dc.l	SetVolume
			dc.l	SetFreq
			dc.l	SetPhase
			dc.l	SetSpin
			dc.l	SetRotate

			dc.l	SetVolumeMax
			dc.l	SetFreqMax
			dc.l	SetPhaseMax
			dc.l	SetSpinMax
			dc.l	SetRotateMax

			dc.l	SetVolumeMin
			dc.l	SetFreqMin
			dc.l	SetPhaseMin
			dc.l	SetSpinMin
			dc.l	SetRotateMin

			dc.l	SetVolumeUp
			dc.l	SetFreqUp
			dc.l	SetPhaseUp
			dc.l	SetSpinAntiClock
			dc.l	SetRotateAntiClock

			dc.l	SetVolumeDown
			dc.l	SetFreqDown
			dc.l	SetPhaseDown
			dc.l	SetSpinClockwise
			dc.l	SetRotateClockwise

			dc.l	SetVolumeScan
			dc.l	SetFreqScan
			dc.l	SetPhaseScan
			dc.l	SetSpinRock
			dc.l	SetRotateRock

SetVolume:		move.l	Value,d0
			cmpi.l	#64,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			bne.s	.Skip
			move.w	d0,Vol0
			move.b	#1,AD0Update
			bra	Next

.Skip:			cmpi.b	#1,d1
			bne.s	.Skip2
			move.w	d0,Vol1
			move.b	#1,AD1Update
			bra	Next

.Skip2:			cmpi.b	#2,d1
			bne.s	.Skip3
			move.w	d0,Vol2
			move.b	#1,AD2Update
			bra	Next

.Skip3:			move.w	d0,Vol3
			move.b	#1,AD3Update
			bra	Next

SetFreq:		move.l	Value,d0
			cmpi.l	#1,d0
			blo	Error2
			cmpi.l	#1000,d0
			bhi	Error2

			sub.l	d1,d1
			move.b	Value2,d1
			mulu	#10,d0
			add.w	d1,d0

			move.b	ChannelNumber,d1
			bne.s	.Skip
			move.w	d0,Freq0
			jsr	CheckFreq0
			move.b	#1,AD0Update
			jsr	CheckSync
			bra	Next

.Skip:			cmpi.b	#1,d1
			bne.s	.Skip2
			move.w	d0,Freq1
			jsr	CheckFreq1
			move.b	#1,AD1Update
			jsr	CheckSync
			bra	Next

.Skip2:			cmpi.b	#2,d1
			bne.s	.Skip3
			move.w	d0,Freq2
			jsr	CheckFreq2
			move.b	#1,AD2Update
			jsr	CheckSync
			bra	Next

.Skip3:			move.w	d0,Freq3
			jsr	CheckFreq3
			move.b	#1,AD3Update
			jsr	CheckSync
			bra	Next

SetPhase:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			beq	Error

			cmpi.b	#1,d1
			bne.s	.Skip2
			move.w	d0,Phase1
			move.b	#1,AD1Update
			bra	Next

.Skip2:			cmpi.b	#2,d1
			bne.s	.Skip3
			move.w	d0,Phase2
			move.b	#1,AD2Update
			bra	Next

.Skip3:			move.w	d0,Phase3
			move.b	#1,AD3Update
			bra	Next

SetSpin:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			bne.s	.Skip
			move.w	d0,Spin0
			move.b	#1,AD0Update
			bra	Next

.Skip:			cmpi.b	#1,d1
			bne.s	.Skip2
			move.w	d0,Spin1
			move.b	#1,AD1Update
			bra	Next

.Skip2:			cmpi.b	#2,d1
			bne.s	.Skip3
			move.w	d0,Spin2
			move.b	#1,AD2Update
			bra	Next

.Skip3:			move.w	d0,Spin3
			move.b	#1,AD3Update
			bra	Next

SetRotate:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			move.w	d0,RotateAngle01
			move.w	#$0101,AD0Update
			bra	Next

.Skip:			move.w	d0,RotateAngle23
			move.w	#$0101,AD2Update
			bra	Next

SetVolumeMax:		move.l	Value,d0
			cmpi.l	#64,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			lea	Vol0Max,a0
			bra	SetIt

SetFreqMax:		move.l	Value,d0
			cmpi.l	#1,d0
			blo	Error2
			cmpi.l	#1000,d0
			bhi	Error2

			sub.l	d1,d1
			move.b	Value2,d1
			mulu	#10,d0
			add.w	d1,d0

			lea	Freq0Max,a0
			bra	SetIt

SetPhaseMax:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			tst.b	ChannelNumber
			beq	Error

			lea	Phase0Max,a0
			bra	SetIt

SetSpinMax:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			lea	Spin0Max,a0
			bra	SetIt

SetRotateMax:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			move.w	d0,RotateAngleMax01
			bra	Next

.Skip:			move.w	d0,RotateAngleMax23
			bra	Next

SetVolumeMin:		move.l	Value,d0
			cmpi.l	#64,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			lea	Vol0Min,a0
			bra	SetIt

SetFreqMin:		move.l	Value,d0
			cmpi.l	#1,d0
			blo	Error2
			cmpi.l	#1000,d0
			bhi	Error2

			sub.l	d1,d1
			move.b	Value2,d1
			mulu	#10,d0
			add.w	d1,d0

			lea	Freq0Min,a0
			bra	SetIt

SetPhaseMin:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			tst.b	ChannelNumber
			beq	Error

			lea	Phase0Min,a0
			bra	SetIt

SetSpinMin:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			lea	Spin0Min,a0
			bra	SetIt

SetRotateMin:		move.l	Value,d0
			cmpi.l	#359,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			move.w	d0,RotateAngleMin01
			bra	Next

.Skip:			move.w	d0,RotateAngleMin23
			bra	Next

SetVolumeUp:		moveq	#1,d3
			sub.l	d4,d4
			moveq	#2,d5

			lea	VBCountV0,a0
			bra	SetIt2

SetFreqUp:		moveq	#4,d3
			moveq	#3,d4
			moveq	#5,d5

			lea	VBCountF0,a0
			bra	SetIt2

SetPhaseUp:		tst.b	ChannelNumber
			beq	Error

			moveq	#7,d3
			moveq	#6,d4
			moveq	#8,d5

			lea	VBCountP0,a0
			bra	SetIt2

SetSpinAntiClock:	moveq	#10,d3
			moveq	#9,d4
			moveq	#11,d5

			lea	VBCountS0,a0
			bra	SetIt2

SetRotateAntiClock:	move.l	Value,d0
			beq	RotateOff
			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			bsr	SetIt5

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			bclr	#0,RotateFlag
			bset	#1,RotateFlag
			bclr	#2,RotateFlag
			move.l	d0,VBCountRot01
			move.l	d0,VBCountRot01Temp
			move.l	d7,VBRateRot01
			bra	Next

.Skip:			bclr	#3,RotateFlag
			bset	#4,RotateFlag
			bclr	#5,RotateFlag
			move.l	d0,VBCountRot23
			move.l	d0,VBCountRot23Temp
			move.l	d7,VBRateRot23
			bra	Next

SetVolumeDown:		sub.l	d3,d3
			moveq	#1,d4
			moveq	#2,d5

			lea	VBCountV0,a0
			bra	SetIt2

SetFreqDown:		moveq	#3,d3
			moveq	#4,d4
			moveq	#5,d5

			lea	VBCountF0,a0
			bra	SetIt2

SetPhaseDown:		tst.b	ChannelNumber
			beq	Error

			moveq	#6,d3
			moveq	#7,d4
			moveq	#8,d5

			lea	VBCountP0,a0
			bra	SetIt2

SetSpinClockwise:	moveq	#9,d3
			moveq	#10,d4
			moveq	#11,d5

			lea	VBCountS0,a0
			bra	SetIt2

SetRotateClockwise:	move.l	Value,d0
			beq	RotateOff
			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			bsr	SetIt5

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			bset	#0,RotateFlag
			bclr	#1,RotateFlag
			bclr	#2,RotateFlag
			move.l	d0,VBCountRot01
			move.l	d0,VBCountRot01Temp
			move.l	d7,VBRateRot01
			bra	Next

.Skip:			bset	#3,RotateFlag
			bclr	#4,RotateFlag
			bclr	#5,RotateFlag
			move.l	d0,VBCountRot23
			move.l	d0,VBCountRot23Temp
			move.l	d7,VBRateRot23
			bra	Next

SetVolumeScan:		sub.l	d3,d3
			moveq	#2,d4
			moveq	#1,d5

			lea	VBCountV0,a0
			bra	SetIt3

SetFreqScan:		moveq	#3,d3
			moveq	#5,d4
			moveq	#4,d5

			lea	VBCountF0,a0
			bra	SetIt3

SetPhaseScan:		tst.b	ChannelNumber
			beq	Error

			moveq	#6,d3
			moveq	#8,d4
			moveq	#7,d5

			lea	VBCountP0,a0
			bra	SetIt3

SetSpinRock:		moveq	#9,d3
			moveq	#11,d4
			moveq	#10,d5

			lea	VBCountS0,a0
			bra	SetIt3

SetRotateRock:		move.l	Value,d0
			beq	RotateOff
			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			bsr	SetIt5

			move.b	ChannelNumber,d1
			cmpi.b	#1,d1
			bhi.s	.Skip

			bset	#0,RotateFlag
			bclr	#1,RotateFlag
			bset	#2,RotateFlag
			move.l	d0,VBCountRot01
			move.l	d0,VBCountRot01Temp
			move.l	d7,VBRateRot01
			bra	Next

.Skip:			bset	#3,RotateFlag
			bclr	#4,RotateFlag
			bset	#5,RotateFlag
			move.l	d0,VBCountRot23
			move.l	d0,VBCountRot23Temp
			move.l	d7,VBRateRot23
			bra	Next

SetIt:			sub.l	d1,d1
			move.b	ChannelNumber,d1
			mulu	#2,d1
			move.w	d0,(a0,d1)
			jsr	CheckFreq
			bra	Next

SetIt2:			move.l	Value,d0
			beq	ScanOff
			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			bsr.s	SetIt4
			bset	d3,d6
			bclr	d4,d6
			bclr	d5,d6
			move.w	d6,(a0,d2)
			bra	Next

SetIt3:			move.l	Value,d0
			beq.s	ScanOff
			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	Value2
			bne	Error2

			bsr.s	SetIt4
			bset	d3,d6
			bset	d4,d6
			bclr	d5,d6
			move.w	d6,(a0,d2)
			bra	Next

SetIt4:			bsr.s	SetIt5

			sub.l	d1,d1
			move.b	ChannelNumber,d1
			move.l	d1,d2
			mulu	#4,d1
			move.l	d0,(a0,d1)		;Count
			move.l	d0,16(a0,d1)		;Count temp
			move.l	d7,32(a0,d1)		;Rate

			lea	AD0Funct,a0
			mulu	#2,d2
			move.w	(a0,d2),d6
			rts

SetIt5:			cmpi.l	#20,d0
			blo.s	.Skip
			subi.l	#19,d0
			moveq	#1,d7
			rts

.Skip:			moveq	#21,d7
			sub.l	d0,d7
			moveq	#1,d0
			rts

ScanOff:		sub.l	d0,d0
			move.b	ChannelNumber,d0
			lea	AD0Funct,a0
			mulu	#2,d0
			clr.w	(a0,d0)
			bra	Next

RotateOff:		clr.b	RotateFlag
			bra	Next

Factory:		move.b	(a0)+,d0
			beq.s	.Skip
			cmpi.b	#" ",d0
			bne	Error

.StripSpaces:		move.b	(a0),d0
			beq.s	.Skip
			cmpi.b	#" ",d0
			bne.s	.Next

			addq.l	#1,a0
			bra.s	.StripSpaces

.Next:			move.l	a0,NextCmdPtr

.Skip:			bsr.s	FactoryIt
			bra	Next

FactoryIt:		tst.b	DrawMode
			beq.s	.Skip

			clr.b	DrawMode
			bsr	GetDrawModeItem
			bclr	#0,12(a0)
			move.b	#1,RestartFlag
			bsr	DrawOff
			rts

.Skip:			bsr.s	ResetAll
			move.l	#$01010101,AD0Update
			jsr	CheckSync
			rts

ResetAll:		clr.l	AD0Funct
			clr.l	AD2Funct
			clr.b	RotateFlag

			move.w	#64,Vol0
			move.w	#64,Vol1
			move.w	#64,Vol2
			move.w	#64,Vol3

			move.w	#500,Freq0
			move.w	#500,Freq1
			move.w	#500,Freq2
			move.w	#500,Freq3

			tst.b	DrawMode
			beq.s	.Skip

			move.w	#250,Freq0
			move.w	#250,Freq1
			move.w	#250,Freq2
			move.w	#250,Freq3

.Skip:			clr.w	Phase1
			clr.w	Phase2
			clr.w	Phase3

			clr.w	Spin0
			clr.w	Spin1
			clr.w	Spin2
			clr.w	Spin3

			clr.w	RotateAngle01
			clr.w	RotateAngle23

			move.w	#64,Vol0Max
			move.w	#64,Vol1Max
			move.w	#64,Vol2Max
			move.w	#64,Vol3Max

			move.w	#10,Vol0Min
			move.w	#10,Vol1Min
			move.w	#10,Vol2Min
			move.w	#10,Vol3Min

			move.w	#1000,Freq0Max
			move.w	#1000,Freq1Max
			move.w	#1000,Freq2Max
			move.w	#1000,Freq3Max

			move.w	#400,Freq0Min
			move.w	#400,Freq1Min
			move.w	#400,Freq2Min
			move.w	#400,Freq3Min

			move.w	#359,Phase1Max
			move.w	#359,Phase2Max
			move.w	#359,Phase3Max

			clr.w	Phase1Min
			clr.w	Phase2Min
			clr.w	Phase3Min

			move.w	#359,Spin0Max
			move.w	#359,Spin1Max
			move.w	#359,Spin2Max
			move.w	#359,Spin3Max

			clr.w	Spin0Min
			clr.w	Spin1Min
			clr.w	Spin2Min
			clr.w	Spin3Min

			move.w	#359,RotateAngleMax01
			move.w	#359,RotateAngleMax23

			clr.w	RotateAngleMin01
			clr.w	RotateAngleMin23
			jsr	CheckFreq
			rts


;Gadget routines:

GadgetTable:		dc.l	Preset1
			dc.l	Preset2
			dc.l	Preset3
			dc.l	Preset4
			dc.l	Preset5
			dc.l	Preset6
			dc.l	Preset7
			dc.l	Preset8
			dc.l	Preset9
			dc.l	Preset10
			dc.l	Preset11
			dc.l	Preset12
			dc.l	Preset13
			dc.l	Preset14
			dc.l	Preset15
			dc.l	Preset16
			dc.l	Preset17
			dc.l	Preset18
			dc.l	Preset19
			dc.l	Preset20
			dc.l	Preset21
			dc.l	Preset22
			dc.l	Preset23
			dc.l	Preset24
			dc.l	Preset25
			dc.l	Preset26
			dc.l	Preset27
			dc.l	Preset28
			dc.l	Preset29
			dc.l	Preset30
			dc.l	Preset31
			dc.l	Preset32
			dc.l	Preset33
			dc.l	Preset34
			dc.l	Preset35
			dc.l	Preset36
			dc.l	Preset37
			dc.l	Preset38
			dc.l	Preset39
			dc.l	Preset40

			dc.l	Vol0Dn
			dc.l	Vol0Up
			dc.l	Freq0Dn
			dc.l	Freq0Up
			dc.l	Vol1Dn
			dc.l	Vol1Up
			dc.l	Freq1Dn
			dc.l	Freq1Up
			dc.l	Phase1Dn
			dc.l	Phase1Up
			dc.l	Vol2Dn
			dc.l	Vol2Up
			dc.l	Freq2Dn
			dc.l	Freq2Up
			dc.l	Phase2Dn
			dc.l	Phase2Up
			dc.l	Vol3Dn
			dc.l	Vol3Up
			dc.l	Freq3Dn
			dc.l	Freq3Up
			dc.l	Phase3Dn
			dc.l	Phase3Up

			dc.l	North
			dc.l	South
			dc.l	East
			dc.l	West
			dc.l	CenterIt

			dc.l	Sequence1
			dc.l	Sequence2
			dc.l	Sequence3
			dc.l	Sequence4
			dc.l	Sequence5
			dc.l	Sequence6
			dc.l	Sequence7
			dc.l	Sequence8
			dc.l	Sequence9
			dc.l	Sequence10
			dc.l	Sequence11
			dc.l	Sequence12

			dc.l	Shutter
			dc.l	Standby
			dc.l	FastMove
			dc.l	Strobe

			dc.l	Special
			dc.l	GMorph
			dc.l	GDraw
			dc.l	Trigger
			dc.l	0

			dc.l	Sequence13
			dc.l	Sequence14
			dc.l	Sequence15
			dc.l	Sequence16
			dc.l	Sequence17
			dc.l	Sequence18
			dc.l	Sequence19
			dc.l	Sequence20

			dc.l	Sequence21
			dc.l	Sequence22
			dc.l	Sequence23
			dc.l	Sequence24
			dc.l	Sequence25
			dc.l	Sequence26
			dc.l	Sequence27
			dc.l	Sequence28

			dc.l	Sequence29
			dc.l	Sequence30
			dc.l	Sequence31
			dc.l	Sequence32
			dc.l	Sequence33
			dc.l	Sequence34
			dc.l	Sequence35
			dc.l	Sequence36

			dc.l	Sequence37
			dc.l	Sequence38
			dc.l	Sequence39
			dc.l	Sequence40
			dc.l	Sequence41
			dc.l	Sequence42
			dc.l	Sequence43
			dc.l	Sequence44

			dc.l	Bank0
			dc.l	Bank1
			dc.l	Bank2
			dc.l	Bank3
			dc.l	Bank4
			dc.l	Bank5
			dc.l	Bank6
			dc.l	Bank7
			dc.l	Bank8
			dc.l	Bank9
			dc.l	0

RawKeyTable:		dc.w	$4c
			dc.l	North
			dc.w	$4d
			dc.l	South
			dc.w	$4e
			dc.l	East
			dc.w	$4f
			dc.l	West
			dc.w	$44
			dc.l	CenterIt
			dc.w	$45
			dc.l	EscShift

			dc.w	$50
			dc.l	Sequence1
			dc.w	$51
			dc.l	Sequence2
			dc.w	$52
			dc.l	Sequence3
			dc.w	$53
			dc.l	Sequence4
			dc.w	$54
			dc.l	Sequence5
			dc.w	$55
			dc.l	Sequence6
			dc.w	$56
			dc.l	Sequence7
			dc.w	$57
			dc.l	Sequence8
			dc.w	$58
			dc.l	Sequence9
			dc.w	$59
			dc.l	Sequence10
			dc.w	$43
			dc.l	Trigger
			dc.w	$01
			dc.l	Preset1
			dc.w	$02
			dc.l	Preset2
			dc.w	$03
			dc.l	Preset3
			dc.w	$04
			dc.l	Preset4
			dc.w	$05
			dc.l	Preset5
			dc.w	$06
			dc.l	Preset6
			dc.w	$07
			dc.l	Preset7
			dc.w	$08
			dc.l	Preset8
			dc.w	$09
			dc.l	Preset9
			dc.w	$0a
			dc.l	Preset10
			dc.w	$10
			dc.l	Preset11
			dc.w	$11
			dc.l	Preset12
			dc.w	$12
			dc.l	Preset13
			dc.w	$13
			dc.l	Preset14
			dc.w	$14
			dc.l	Preset15
			dc.w	$15
			dc.l	Preset16
			dc.w	$16
			dc.l	Preset17
			dc.w	$17
			dc.l	Preset18
			dc.w	$18
			dc.l	Preset19
			dc.w	$19
			dc.l	Preset20
			dc.w	$20
			dc.l	Preset21
			dc.w	$21
			dc.l	Preset22
			dc.w	$22
			dc.l	Preset23
			dc.w	$23
			dc.l	Preset24
			dc.w	$24
			dc.l	Preset25
			dc.w	$25
			dc.l	Preset26
			dc.w	$26
			dc.l	Preset27
			dc.w	$27
			dc.l	Preset28
			dc.w	$28
			dc.l	Preset29
			dc.w	$29
			dc.l	Preset30
			dc.w	$31
			dc.l	Preset31
			dc.w	$32
			dc.l	Preset32
			dc.w	$33
			dc.l	Preset33
			dc.w	$34
			dc.l	Preset34
			dc.w	$35
			dc.l	Preset35
			dc.w	$36
			dc.l	Preset36
			dc.w	$37
			dc.l	Preset37
			dc.w	$38
			dc.l	Preset38
			dc.w	$39
			dc.l	Preset39
			dc.w	$3a
			dc.l	Preset40
			dc.w	$40
			dc.l	ShutterRaw
			dc.w	$5a
			dc.l	ShutterRaw
			dc.w	$5b
			dc.l	StandbyRaw
			dc.w	$5c
			dc.l	FastMoveRaw
			dc.w	$5d
			dc.l	StrobeRaw
			dc.w	0

RawKeyTableShift:	dc.w	$4c
			dc.l	ShiftNorth
			dc.w	$4d
			dc.l	ShiftSouth
			dc.w	$4e
			dc.l	ShiftEast
			dc.w	$4f
			dc.l	ShiftWest
			dc.w	$44
			dc.l	ShiftCenterIt

			dc.w	$50
			dc.l	Sequence11
			dc.w	$51
			dc.l	Sequence12
			dc.w	$52
			dc.l	Sequence13
			dc.w	$53
			dc.l	Sequence14
			dc.w	$54
			dc.l	Sequence15
			dc.w	$55
			dc.l	Sequence16
			dc.w	$56
			dc.l	Sequence17
			dc.w	$57
			dc.l	Sequence18
			dc.w	$58
			dc.l	Sequence19
			dc.w	$59
			dc.l	Sequence20
			dc.w	0

RawKeyTableCtrl:	dc.w	$4c
			dc.l	RollEast
			dc.w	$4d
			dc.l	RollWest
			dc.w	$4e
			dc.l	RollEast
			dc.w	$4f
			dc.l	RollWest

			dc.w	$50
			dc.l	Sequence21
			dc.w	$51
			dc.l	Sequence22
			dc.w	$52
			dc.l	Sequence23
			dc.w	$53
			dc.l	Sequence24
			dc.w	$54
			dc.l	Sequence25
			dc.w	$55
			dc.l	Sequence26
			dc.w	$56
			dc.l	Sequence27
			dc.w	$57
			dc.l	Sequence28
			dc.w	$58
			dc.l	Sequence29
			dc.w	$59
			dc.l	Sequence30
			dc.w	0

RawKeyTableAlt:		dc.w	$50
			dc.l	Sequence31
			dc.w	$51
			dc.l	Sequence32
			dc.w	$52
			dc.l	Sequence33
			dc.w	$53
			dc.l	Sequence34
			dc.w	$54
			dc.l	Sequence35
			dc.w	$55
			dc.l	Sequence36
			dc.w	$56
			dc.l	Sequence37
			dc.w	$57
			dc.l	Sequence38
			dc.w	$58
			dc.l	Sequence39
			dc.w	$59
			dc.l	Sequence40
			dc.w	0

SeqTable:		dc.l	Sequence1
			dc.l	Sequence2
			dc.l	Sequence3
			dc.l	Sequence4
			dc.l	Sequence5
			dc.l	Sequence6
			dc.l	Sequence7
			dc.l	Sequence8
			dc.l	Sequence9
			dc.l	Sequence10
			dc.l	Sequence11
			dc.l	Sequence12

			dc.l	Sequence13
			dc.l	Sequence14
			dc.l	Sequence15
			dc.l	Sequence16
			dc.l	Sequence17
			dc.l	Sequence18
			dc.l	Sequence19
			dc.l	Sequence20

			dc.l	Sequence21
			dc.l	Sequence22
			dc.l	Sequence23
			dc.l	Sequence24
			dc.l	Sequence25
			dc.l	Sequence26
			dc.l	Sequence27
			dc.l	Sequence28

			dc.l	Sequence29
			dc.l	Sequence30
			dc.l	Sequence31
			dc.l	Sequence32
			dc.l	Sequence33
			dc.l	Sequence34
			dc.l	Sequence35
			dc.l	Sequence36

			dc.l	Sequence37
			dc.l	Sequence38
			dc.l	Sequence39
			dc.l	Sequence40
			dc.l	Sequence41
			dc.l	Sequence42
			dc.l	Sequence43
			dc.l	Sequence44

Preset1:		lea	Preset1CmdText,a0
			lea	Preset1Cmd,a1
			lea	PresetPos1,a2
			move.b	PresetSpeed1,d1
			lea	Preset1DrawPtr,a3
			lea	Preset1Filename,a4
			lea	Preset1Text,a5
			moveq	#GD_Preset1,d2
			bra	LoadPreset

Preset2:		lea	Preset2CmdText,a0
			lea	Preset2Cmd,a1
			lea	PresetPos2,a2
			move.b	PresetSpeed2,d1
			lea	Preset2DrawPtr,a3
			lea	Preset2Filename,a4
			lea	Preset2Text,a5
			moveq	#GD_Preset2,d2
			bra	LoadPreset

Preset3:		lea	Preset3CmdText,a0
			lea	Preset3Cmd,a1
			lea	PresetPos3,a2
			move.b	PresetSpeed3,d1
			lea	Preset3DrawPtr,a3
			lea	Preset3Filename,a4
			lea	Preset3Text,a5
			moveq	#GD_Preset3,d2
			bra	LoadPreset

Preset4:		lea	Preset4CmdText,a0
			lea	Preset4Cmd,a1
			lea	PresetPos4,a2
			move.b	PresetSpeed4,d1
			lea	Preset4DrawPtr,a3
			lea	Preset4Filename,a4
			lea	Preset4Text,a5
			moveq	#GD_Preset4,d2
			bra	LoadPreset

Preset5:		lea	Preset5CmdText,a0
			lea	Preset5Cmd,a1
			lea	PresetPos5,a2
			move.b	PresetSpeed5,d1
			lea	Preset5DrawPtr,a3
			lea	Preset5Filename,a4
			lea	Preset5Text,a5
			moveq	#GD_Preset5,d2
			bra	LoadPreset

Preset6:		lea	Preset6CmdText,a0
			lea	Preset6Cmd,a1
			lea	PresetPos6,a2
			move.b	PresetSpeed6,d1
			lea	Preset6DrawPtr,a3
			lea	Preset6Filename,a4
			lea	Preset6Text,a5
			moveq	#GD_Preset6,d2
			bra	LoadPreset

Preset7:		lea	Preset7CmdText,a0
			lea	Preset7Cmd,a1
			lea	PresetPos7,a2
			move.b	PresetSpeed7,d1
			lea	Preset7DrawPtr,a3
			lea	Preset7Filename,a4
			lea	Preset7Text,a5
			moveq	#GD_Preset7,d2
			bra	LoadPreset

Preset8:		lea	Preset8CmdText,a0
			lea	Preset8Cmd,a1
			lea	PresetPos8,a2
			move.b	PresetSpeed8,d1
			lea	Preset8DrawPtr,a3
			lea	Preset8Filename,a4
			lea	Preset8Text,a5
			moveq	#GD_Preset8,d2
			bra	LoadPreset

Preset9:		lea	Preset9CmdText,a0
			lea	Preset9Cmd,a1
			lea	PresetPos9,a2
			move.b	PresetSpeed9,d1
			lea	Preset9DrawPtr,a3
			lea	Preset9Filename,a4
			lea	Preset9Text,a5
			moveq	#GD_Preset9,d2
			bra	LoadPreset

Preset10:		lea	Preset10CmdText,a0
			lea	Preset10Cmd,a1
			lea	PresetPos10,a2
			move.b	PresetSpeed10,d1
			lea	Preset10DrawPtr,a3
			lea	Preset10Filename,a4
			lea	Preset10Text,a5
			moveq	#GD_Preset10,d2
			bra	LoadPreset

Preset11:		lea	Preset11CmdText,a0
			lea	Preset11Cmd,a1
			lea	PresetPos11,a2
			move.b	PresetSpeed11,d1
			lea	Preset11DrawPtr,a3
			lea	Preset11Filename,a4
			lea	Preset11Text,a5
			moveq	#GD_Preset11,d2
			bra	LoadPreset

Preset12:		lea	Preset12CmdText,a0
			lea	Preset12Cmd,a1
			lea	PresetPos12,a2
			move.b	PresetSpeed12,d1
			lea	Preset12DrawPtr,a3
			lea	Preset12Filename,a4
			lea	Preset12Text,a5
			moveq	#GD_Preset12,d2
			bra	LoadPreset

Preset13:		lea	Preset13CmdText,a0
			lea	Preset13Cmd,a1
			lea	PresetPos13,a2
			move.b	PresetSpeed13,d1
			lea	Preset13DrawPtr,a3
			lea	Preset13Filename,a4
			lea	Preset13Text,a5
			moveq	#GD_Preset13,d2
			bra	LoadPreset

Preset14:		lea	Preset14CmdText,a0
			lea	Preset14Cmd,a1
			lea	PresetPos14,a2
			move.b	PresetSpeed14,d1
			lea	Preset14DrawPtr,a3
			lea	Preset14Filename,a4
			lea	Preset14Text,a5
			moveq	#GD_Preset14,d2
			bra	LoadPreset

Preset15:		lea	Preset15CmdText,a0
			lea	Preset15Cmd,a1
			lea	PresetPos15,a2
			move.b	PresetSpeed15,d1
			lea	Preset15DrawPtr,a3
			lea	Preset15Filename,a4
			lea	Preset15Text,a5
			moveq	#GD_Preset15,d2
			bra	LoadPreset

Preset16:		lea	Preset16CmdText,a0
			lea	Preset16Cmd,a1
			lea	PresetPos16,a2
			move.b	PresetSpeed16,d1
			lea	Preset16DrawPtr,a3
			lea	Preset16Filename,a4
			lea	Preset16Text,a5
			moveq	#GD_Preset16,d2
			bra	LoadPreset

Preset17:		lea	Preset17CmdText,a0
			lea	Preset17Cmd,a1
			lea	PresetPos17,a2
			move.b	PresetSpeed17,d1
			lea	Preset17DrawPtr,a3
			lea	Preset17Filename,a4
			lea	Preset17Text,a5
			moveq	#GD_Preset17,d2
			bra	LoadPreset

Preset18:		lea	Preset18CmdText,a0
			lea	Preset18Cmd,a1
			lea	PresetPos18,a2
			move.b	PresetSpeed18,d1
			lea	Preset18DrawPtr,a3
			lea	Preset18Filename,a4
			lea	Preset18Text,a5
			moveq	#GD_Preset18,d2
			bra	LoadPreset

Preset19:		lea	Preset19CmdText,a0
			lea	Preset19Cmd,a1
			lea	PresetPos19,a2
			move.b	PresetSpeed19,d1
			lea	Preset19DrawPtr,a3
			lea	Preset19Filename,a4
			lea	Preset19Text,a5
			moveq	#GD_Preset19,d2
			bra	LoadPreset

Preset20:		lea	Preset20CmdText,a0
			lea	Preset20Cmd,a1
			lea	PresetPos20,a2
			move.b	PresetSpeed20,d1
			lea	Preset20DrawPtr,a3
			lea	Preset20Filename,a4
			lea	Preset20Text,a5
			moveq	#GD_Preset20,d2
			bra	LoadPreset

Preset21:		lea	Preset21CmdText,a0
			lea	Preset21Cmd,a1
			lea	PresetPos21,a2
			move.b	PresetSpeed21,d1
			lea	Preset21DrawPtr,a3
			lea	Preset21Filename,a4
			lea	Preset21Text,a5
			moveq	#GD_Preset21,d2
			bra	LoadPreset

Preset22:		lea	Preset22CmdText,a0
			lea	Preset22Cmd,a1
			lea	PresetPos22,a2
			move.b	PresetSpeed22,d1
			lea	Preset22DrawPtr,a3
			lea	Preset22Filename,a4
			lea	Preset22Text,a5
			moveq	#GD_Preset22,d2
			bra	LoadPreset

Preset23:		lea	Preset23CmdText,a0
			lea	Preset23Cmd,a1
			lea	PresetPos23,a2
			move.b	PresetSpeed23,d1
			lea	Preset23DrawPtr,a3
			lea	Preset23Filename,a4
			lea	Preset23Text,a5
			moveq	#GD_Preset23,d2
			bra	LoadPreset

Preset24:		lea	Preset24CmdText,a0
			lea	Preset24Cmd,a1
			lea	PresetPos24,a2
			move.b	PresetSpeed24,d1
			lea	Preset24DrawPtr,a3
			lea	Preset24Filename,a4
			lea	Preset24Text,a5
			moveq	#GD_Preset24,d2
			bra	LoadPreset

Preset25:		lea	Preset25CmdText,a0
			lea	Preset25Cmd,a1
			lea	PresetPos25,a2
			move.b	PresetSpeed25,d1
			lea	Preset25DrawPtr,a3
			lea	Preset25Filename,a4
			lea	Preset25Text,a5
			moveq	#GD_Preset25,d2
			bra	LoadPreset

Preset26:		lea	Preset26CmdText,a0
			lea	Preset26Cmd,a1
			lea	PresetPos26,a2
			move.b	PresetSpeed26,d1
			lea	Preset26DrawPtr,a3
			lea	Preset26Filename,a4
			lea	Preset26Text,a5
			moveq	#GD_Preset26,d2
			bra	LoadPreset

Preset27:		lea	Preset27CmdText,a0
			lea	Preset27Cmd,a1
			lea	PresetPos27,a2
			move.b	PresetSpeed27,d1
			lea	Preset27DrawPtr,a3
			lea	Preset27Filename,a4
			lea	Preset27Text,a5
			moveq	#GD_Preset27,d2
			bra	LoadPreset

Preset28:		lea	Preset28CmdText,a0
			lea	Preset28Cmd,a1
			lea	PresetPos28,a2
			move.b	PresetSpeed28,d1
			lea	Preset28DrawPtr,a3
			lea	Preset28Filename,a4
			lea	Preset28Text,a5
			moveq	#GD_Preset28,d2
			bra	LoadPreset

Preset29:		lea	Preset29CmdText,a0
			lea	Preset29Cmd,a1
			lea	PresetPos29,a2
			move.b	PresetSpeed29,d1
			lea	Preset29DrawPtr,a3
			lea	Preset29Filename,a4
			lea	Preset29Text,a5
			moveq	#GD_Preset29,d2
			bra	LoadPreset

Preset30:		lea	Preset30CmdText,a0
			lea	Preset30Cmd,a1
			lea	PresetPos30,a2
			move.b	PresetSpeed30,d1
			lea	Preset30DrawPtr,a3
			lea	Preset30Filename,a4
			lea	Preset30Text,a5
			moveq	#GD_Preset30,d2
			bra	LoadPreset

Preset31:		lea	Preset31CmdText,a0
			lea	Preset31Cmd,a1
			lea	PresetPos31,a2
			move.b	PresetSpeed31,d1
			lea	Preset31DrawPtr,a3
			lea	Preset31Filename,a4
			lea	Preset31Text,a5
			moveq	#GD_Preset31,d2
			bra	LoadPreset

Preset32:		lea	Preset32CmdText,a0
			lea	Preset32Cmd,a1
			lea	PresetPos32,a2
			move.b	PresetSpeed32,d1
			lea	Preset32DrawPtr,a3
			lea	Preset32Filename,a4
			lea	Preset32Text,a5
			moveq	#GD_Preset32,d2
			bra	LoadPreset

Preset33:		lea	Preset33CmdText,a0
			lea	Preset33Cmd,a1
			lea	PresetPos33,a2
			move.b	PresetSpeed33,d1
			lea	Preset33DrawPtr,a3
			lea	Preset33Filename,a4
			lea	Preset33Text,a5
			moveq	#GD_Preset33,d2
			bra	LoadPreset

Preset34:		lea	Preset34CmdText,a0
			lea	Preset34Cmd,a1
			lea	PresetPos34,a2
			move.b	PresetSpeed34,d1
			lea	Preset34DrawPtr,a3
			lea	Preset34Filename,a4
			lea	Preset34Text,a5
			moveq	#GD_Preset34,d2
			bra	LoadPreset

Preset35:		lea	Preset35CmdText,a0
			lea	Preset35Cmd,a1
			lea	PresetPos35,a2
			move.b	PresetSpeed35,d1
			lea	Preset35DrawPtr,a3
			lea	Preset35Filename,a4
			lea	Preset35Text,a5
			moveq	#GD_Preset35,d2
			bra	LoadPreset

Preset36:		lea	Preset36CmdText,a0
			lea	Preset36Cmd,a1
			lea	PresetPos36,a2
			move.b	PresetSpeed36,d1
			lea	Preset36DrawPtr,a3
			lea	Preset36Filename,a4
			lea	Preset36Text,a5
			moveq	#GD_Preset36,d2
			bra	LoadPreset

Preset37:		lea	Preset37CmdText,a0
			lea	Preset37Cmd,a1
			lea	PresetPos37,a2
			move.b	PresetSpeed37,d1
			lea	Preset37DrawPtr,a3
			lea	Preset37Filename,a4
			lea	Preset37Text,a5
			moveq	#GD_Preset37,d2
			bra	LoadPreset

Preset38:		lea	Preset38CmdText,a0
			lea	Preset38Cmd,a1
			lea	PresetPos38,a2
			move.b	PresetSpeed38,d1
			lea	Preset38DrawPtr,a3
			lea	Preset38Filename,a4
			lea	Preset38Text,a5
			moveq	#GD_Preset38,d2
			bra	LoadPreset

Preset39:		lea	Preset39CmdText,a0
			lea	Preset39Cmd,a1
			lea	PresetPos39,a2
			move.b	PresetSpeed39,d1
			lea	Preset39DrawPtr,a3
			lea	Preset39Filename,a4
			lea	Preset39Text,a5
			moveq	#GD_Preset39,d2
			bra	LoadPreset

Preset40:		lea	Preset40CmdText,a0
			lea	Preset40Cmd,a1
			lea	PresetPos40,a2
			move.b	PresetSpeed40,d1
			lea	Preset40DrawPtr,a3
			lea	Preset40Filename,a4
			lea	Preset40Text,a5
			moveq	#GD_Preset40,d2
			bra	LoadPreset

AllOff:			jsr	RollOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			jsr	ArcOff
			jsr	BoxOff
			jsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag

OtherHalfOff:		jsr	ShiftOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode
			rts

MoreOff:		clr.b	AttachStatus
MoreOff2:		clr.b	TriggerFlag
			clr.b	MorphStatus
			clr.b	DrawStatus
			rts

LoadPreset:		clr.b	TriggerFlag
			bsr	AllOff

			tst.b	AutoManFlag		;Stop playing?
			beq.s	.DSkip
			tst.b	FromPlay
			bne.s	.DSkip
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2

.DSkip:			tst.b	AttachStatus
			beq	.Skip3

			clr.b	AttachStatus

			move.w	XPosTemp,(a2)		;Position
			move.w	YPosTemp,2(a2)

			tst.b	DrawMode
			beq	.Skip2

			move.l	a4,-(sp)
			move.l	a5,-(sp)
			move.l	d2,-(sp)
			move.l	a3,-(sp)

			tst.l	(a3)
			beq.s	.Skip

			movea.l	(a3),a1
			clr.l	(a3)
			move.l	4(a3),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

.Skip:			movea.l	(sp),a0
			move.l	Len0,d0
			add.l	Len1,d0

			tst.b	D3Flag
			beq.s	.3DSkip
			add.l	Len0,d0

.3DSkip:		addi.l	#62,d0
			move.l	d0,4(a0)

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	.Error

			movea.l	(sp)+,a0
			move.l	d0,(a0)

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString
			movea.l	a1,a0
			jsr	MakeHeader

			movea.l	DrawMemPtr,a1		;X data
			move.l	Len0,d0
			subq.l	#1,d0

.Loop:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop

			movea.l	DrawMemPtr,a1		;Y data
			adda.w	#MaxPoints,a1
			move.l	Len1,d0
			subq.l	#1,d0

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop2

			tst.b	D3Flag
			beq.s	.3DSkip2

			movea.l	DrawMemPtr,a1		;Z data
			adda.w	#MaxPoints*2,a1
			move.l	Len0,d0
			subq.l	#1,d0

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop3

.3DSkip2:		jsr	CheckNewScreen

			move.l	(sp)+,d2
			movea.l	(sp)+,a5

			lea	Filename4,a0
			movea.l	(sp)+,a1
			jsr	MoveString

			lea	Filename4,a0
			movea.l	a5,a1
			moveq	#9,d0
			jsr	MoveString7

			move.l	d2,d0
			jsr	FindGadPtr
			jsr	GadChg

			tst.b	FromConfig
			beq.s	.CSkip
			rts

.CSkip:			lea	StatusAttach4,a0
			jsr	PrintStatus
			bra	Scope

.Skip2:			move.w	d2,LoadNumber		;Attach lissajous
			move.l	a1,CommandTextPtr

			lea	ASCIIBuffer,a1
			move.b	#"f",(a1)+
			move.b	#" ",(a1)+

			cmpi.w	#64,Vol0
			beq.s	.ASkip

			move.w	Vol0,d0
			cmp.w	Vol1,d0
			bne.s	.USkip
			move.b	#"-",(a1)+
			bra.s	.ASkip

.USkip:			move.b	#"0",(a1)+
			move.b	#"v",(a1)+
			bsr	.Convert

.ASkip:			cmpi.w	#64,Vol1
			beq.s	.ASkip2

			move.w	Vol1,d0
			cmp.w	Vol2,d0
			bne.s	.USkip2

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip2
			move.b	#"1",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip2

.USkip2:		move.b	#"1",(a1)+
			move.b	#"v",(a1)+
			bsr	.Convert

.ASkip2:		cmpi.w	#64,Vol2
			beq.s	.ASkip3

			move.w	Vol2,d0
			cmp.w	Vol3,d0
			bne.s	.USkip3

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip3
			move.b	#"2",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip3

.USkip3:		move.b	#"2",(a1)+
			move.b	#"v",(a1)+
			bsr	.Convert

.ASkip3:		cmpi.w	#64,Vol3
			beq.s	.ASkip4

			cmpi.b	#"-",-1(a1)
			beq.s	.USkip4
			move.b	#"3",(a1)+

.USkip4:		move.b	#"v",(a1)+
			move.w	Vol3,d0
			bsr	.Convert

.ASkip4:		cmpi.w	#500,Freq0
			beq.s	.ASkip5

			move.w	Freq0,d0
			cmp.w	Freq1,d0
			bne.s	.USkip5
			move.b	#"-",(a1)+
			bra.s	.ASkip5

.USkip5:		move.b	#"0",(a1)+
			move.b	#"f",(a1)+
			bsr	.Convert2

.ASkip5:		cmpi.w	#500,Freq1
			beq.s	.ASkip6

			move.w	Freq1,d0
			cmp.w	Freq2,d0
			bne.s	.USkip6

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip6
			move.b	#"1",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip6

.USkip6:		move.b	#"1",(a1)+
			move.b	#"f",(a1)+
			bsr	.Convert2

.ASkip6:		cmpi.w	#500,Freq2
			beq.s	.ASkip7

			move.w	Freq2,d0
			cmp.w	Freq3,d0
			bne.s	.USkip7

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip7
			move.b	#"2",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip7

.USkip7:		move.b	#"2",(a1)+
			move.b	#"f",(a1)+
			bsr	.Convert2

.ASkip7:		cmpi.w	#500,Freq3
			beq.s	.ASkip8

			cmpi.b	#"-",-1(a1)
			beq.s	.USkip8
			move.b	#"3",(a1)+

.USkip8:		move.b	#"f",(a1)+
			move.w	Freq3,d0
			bsr	.Convert2

.ASkip8:		tst.w	Phase1
			beq.s	.ASkip9

			move.w	Phase1,d0
			cmp.w	Phase2,d0
			bne.s	.USkip9
			move.b	#"1",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip9

.USkip9:		move.b	#"1",(a1)+
			move.b	#"p",(a1)+
			bsr	.Convert

.ASkip9:		tst.w	Phase2
			beq.s	.ASkip10

			move.w	Phase2,d0
			cmp.w	Phase3,d0
			bne.s	.USkip10

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip10
			move.b	#"2",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip10

.USkip10:		move.b	#"2",(a1)+
			move.b	#"p",(a1)+
			bsr	.Convert

.ASkip10:		tst.w	Phase3
			beq.s	.ASkip11

			cmpi.b	#"-",-1(a1)
			beq.s	.USkip11
			move.b	#"3",(a1)+

.USkip11:		move.b	#"p",(a1)+
			move.w	Phase3,d0
			bsr	.Convert

.ASkip11:		tst.w	RotateAngle01
			beq.s	.ASkip12

			move.w	RotateAngle01,d0
			cmp.w	RotateAngle23,d0
			bne.s	.USkip12
			move.b	#"-",(a1)+
			bra.s	.ASkip12

.USkip12:		move.b	#"0",(a1)+
			move.b	#"r",(a1)+
			bsr	.Convert

.ASkip12:		tst.w	RotateAngle23
			beq.s	.ASkip13

			cmpi.b	#"-",-1(a1)
			beq.s	.USkip13
			move.b	#"2",(a1)+

.USkip13:		move.b	#"r",(a1)+
			move.w	RotateAngle23,d0
			bsr	.Convert

.ASkip13:		tst.w	Spin0
			beq.s	.ASkip14

			move.w	Spin0,d0
			cmp.w	Spin1,d0
			bne.s	.USkip14
			move.b	#"-",(a1)+
			bra.s	.ASkip14

.USkip14:		move.b	#"0",(a1)+
			move.b	#"s",(a1)+
			bsr	.Convert

.ASkip14:		tst.w	Spin1
			beq.s	.ASkip15

			move.w	Spin1,d0
			cmp.w	Spin2,d0
			bne.s	.USkip15

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip15
			move.b	#"1",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip15

.USkip15:		move.b	#"1",(a1)+
			move.b	#"s",(a1)+
			bsr	.Convert

.ASkip15:		tst.w	Spin2
			beq.s	.ASkip16

			move.w	Spin2,d0
			cmp.w	Spin3,d0
			bne.s	.USkip16

			cmpi.b	#"-",-1(a1)
			beq.s	.ASkip16
			move.b	#"2",(a1)+
			move.b	#"-",(a1)+
			bra.s	.ASkip16

.USkip16:		move.b	#"2",(a1)+
			move.b	#"s",(a1)+
			bsr	.Convert

.ASkip16:		tst.w	Spin3
			beq.s	.ASkip17

			cmpi.b	#"-",-1(a1)
			beq.s	.USkip17
			move.b	#"3",(a1)+

.USkip17:		move.b	#"s",(a1)+
			move.w	Spin3,d0
			bsr	.Convert

.ASkip17:		clr.b	-1(a1)

			jsr	ClearMenu

			lea	PresetGadTable,a0
			move.w	LoadNumber,d0
			mulu	#6,d0
			movea.l	(a0,d0),a0
			lea	NameString,a1
			jsr	MoveString

			sub.l	d0,d0
			jsr	OpenNameWindow
			tst.l	d0
			bne	.AAbort2

			movea.l	NameGadgets,a0
			movea.l	NameWnd,a1
			jsr	ActivateGad
			bra.s	.ANext

.AWait:			jsr	Clock
			jsr	ShortDelay

.ANext:			movea.l	NameWnd,a0
			jsr	GetWndMsg
			beq.s	.AWait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.AAbort

			btst	#6,d2			;Gadget up?
			beq.s	.ANext

			lea	ASCIIBuffer,a0
			movea.l	CommandTextPtr,a1
			jsr	MoveString

			lea	Preset1CmdText,a1
			move.w	LoadNumber,d0
			mulu	#24,d0
			adda.w	d0,a1
			movea.l	NameGadgets,a0
			movea.l	34(a0),a0
			movea.l	(a0),a0
			moveq	#23,d0
			jsr	MoveString6

			lea	PresetGadTable,a0
			move.w	LoadNumber,d0
			mulu	#6,d0
			movea.l	(a0,d0),a1
			sub.l	d2,d2
			move.w	4(a0,d0),d2

			movea.l	NameGadgets,a0
			movea.l	34(a0),a0
			movea.l	(a0),a0
			moveq	#9,d0
			jsr	MoveString7

			move.l	d2,d0
			jsr	FindGadPtr
			jsr	GadChg

			jsr	CloseNameWindow
			jsr	OpenMenu

			lea	StatusAttach2,a0
			jsr	PrintStatus
			bra	Scope

.AAbort:		jsr	CloseNameWindow
.AAbort2:		jsr	OpenMenu
			lea	StatusAttach5,a0
			jsr	PrintStatus
			bra	Scope

.Convert:		andi.l	#$ffff,d0
			movea.l	a1,a0
			jsr	HEXtoASCII
			move.b	#" ",(a1)+
			rts

.Convert2:		andi.l	#$ffff,d0
			divu	#10,d0
			move.l	d0,d1
			swap	d1
			move.l	d1,-(sp)
			andi.l	#$ffff,d0
			movea.l	a1,a0
			jsr	HEXtoASCII
			move.l	(sp)+,d0
			tst.w	d0
			beq.s	.End
			move.b	#".",(a1)+
			addi.b	#"0",d0
			move.b	d0,(a1)+

.End:			move.b	#" ",(a1)+
			rts

.Error:			adda.w	#16,sp
			bra	Error3

.Skip3:			clr.b	PresetSpeed

			tst.b	PresetMoveFlag
			beq.s	.Skip4

			move.w	(a2),XPosTemp
			move.w	2(a2),YPosTemp

			move.w	XPos,d0			;Move?
			cmp.w	XPosTemp,d0
			bne.s	.Move

			move.w	YPos,d0
			cmp.w	YPosTemp,d0
			beq.s	.Skip4

.Move:			sub.l	d2,d2
			move.b	d1,d2
			move.b	d2,PresetSpeed
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos

.Skip4:			tst.b	MorphStatus		;Morph?
			bne	.Morph

			tst.b	DrawStatus		;Draw?
			bne	.Draw

			tst.l	(a3)			;Screen?
			bne.s	.Screen

			move.l	a0,-(sp)
			move.l	a1,-(sp)
			bsr	RecordUpdate
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			bsr	RecordMake

			move.l	a1,-(sp)
			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip5
			tst.b	FromPlay
			bne.s	.Skip5
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip5:			jsr	PrintStatus2
			movea.l	(sp)+,a0
			clr.b	FromPlay
			move.b	#1,FromPreset
			bra	GetCommand

.Screen:		move.l	a4,-(sp)		;Screen
			move.l	a3,-(sp)
			bsr	RecordUpdate
			movea.l	(sp)+,a3
			movea.l	(a3),a0
			move.b	ShiftFlag,Preserve
			move.l	a0,LASERfIREScrPtr
			jsr	MakeScreen

			tst.b	RecordStatus
			beq.s	.Skip8

			lea	ScreenCmd4,a0
			tst.b	ShiftFlag
			bne.s	.SSkip
			lea	ScreenCmd3,a0

.SSkip:			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Dir2,a0
			jsr	MoveString
			subq.l	#1,a1
			movea.l	(sp),a0
			jsr	MoveString
			move.b	#'"',-(a1)
			clr.b	1(a1)

			movea.l	(sp),a0
			lea	ASCIIBuffer,a1
			move.b	#1,LCFlag
			bsr	RecordMake
			clr.b	LCFlag

.Skip8:			movea.l	(sp)+,a4
			movea.l	a4,a0
			lea	Filename4,a1
			jsr	MoveString

			tst.b	DrawMode
			beq	Scope

			movea.l	a4,a0
			lea	StatusScreen+8,a1
			moveq	#21,d0
			jsr	MoveString6

			tst.b	FromPlay
			bne	.Skip9

			tst.b	RecordStatus
			bne	.NoLf

			tst.b	LASERfIREFlag
			beq	.NoLf

			jsr	GetLASERfIREMem
			bne.s	.LfSkip

			jsr	FlashScreen
			lea	Error3Text,a0
			jsr	PrintStatus2
			jsr	LongDelay
			bra	.NoLf

.LfSkip:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			moveq	#10,d1			;Move cmd
			jsr	AddLfCmd
			move.l	DefTrack,d2
			move.w	d2,6(a1)		;Track
			move.w	XPosTemp,d1		;ToXpos
			mulu.w	#32767/(XMax/2),d1
			move.l	d1,8(a1)
			move.w	YPosTemp,d1		;ToYPos
			mulu.w	#32767/(YMax/2),d1
			move.l	d1,12(a1)
			sub.l	d0,d0
			move.b	PresetSpeed,d0
			move.w	d0,16(a1)		;Rate
			moveq	#18,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			move.b	ShiftFlag,Preserve
			movea.l	LASERfIREScrPtr,a0
			moveq	#15,d1			;Load Screen cmd
			jsr	LfAddScreen

			moveq	#26,d1			;Stop cmd
			jsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			sub.l	d1,d1			;Mark last
			jsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen
			jsr	SendLASERfIRESeq

.NoLf:			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip9
			tst.b	FromPlay
			bne.s	.Skip9
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip9:			lea	StatusScreen,a0
			jsr	PrintStatus2
			clr.b	FromPlay
			bra	Scope

.Morph:			clr.b	MorphStatus

			tst.l	(a3)			;Screen?
			beq	.NoScrn

			move.l	a4,-(sp)
			move.l	a3,-(sp)

			move.l	MorphRate,Rate		;Get rate
			bsr	GetRate
			bne	.Abort
			move.l	Rate,d0
			move.l	d0,MorphRate

			move.l	d0,LfRate

			clr.b	MorphFlag		;Stop updates

			bsr	CalcMorphRate

			bsr	FreeMorphMem
			move.l	DrawMemPtr,MorphMemPtr
			move.l	Len0,MorphLen
			move.b	D3Flag,MorphD3Flag

			bsr	GetDrawMem
			beq	.Error2

			clr.l	MorphCountTemp
			clr.l	MorphStepsTemp
			move.b	#1,MorphFlag

			bsr	RecordUpdate

			move.b	MDTwoFlag,Preserve
			clr.b	DrawingFlag
			movea.l	(sp)+,a3
			movea.l	(a3),a0
			move.l	a0,LASERfIREScrPtr
			jsr	MakeScreen2

			tst.b	RecordStatus
			beq.s	.Skip10

			lea	MorphScreenCmd4,a0
			tst.b	MDTwoFlag
			bne.s	.MSSkip2
			lea	MorphScreenCmd3,a0

.MSSkip2:		lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Dir2,a0
			jsr	MoveString
			subq.l	#1,a1
			movea.l	(sp),a0
			jsr	MoveString
			move.b	#'"',-(a1)
			move.b	#' ',1(a1)

			lea	2(a1),a0
			move.l	MorphRate,d0
			jsr	HEXtoASCII

			movea.l	(sp),a0
			lea	ASCIIBuffer,a1
			move.b	#1,LCFlag
			bsr	RecordMake
			clr.b	LCFlag

.Skip10:		movea.l	(sp)+,a4
			movea.l	a4,a0
			lea	Filename4,a1
			jsr	MoveString

			tst.b	DrawMode
			beq	Scope

			movea.l	a4,a0
			lea	StatusMorph2+7,a1
			moveq	#22,d0
			jsr	MoveString6

			tst.b	RecordStatus
			bne	.MNoLf

			tst.b	LASERfIREFlag
			beq	.MNoLf

			jsr	GetLASERfIREMem
			bne.s	.MLfSkip

			jsr	FlashScreen
			lea	Error3Text,a0
			jsr	PrintStatus2
			jsr	LongDelay
			bra	.MNoLf

.MLfSkip:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			moveq	#10,d1			;Move cmd
			jsr	AddLfCmd
			move.l	DefTrack,d2
			move.w	d2,6(a1)		;Track
			move.w	XPosTemp,d1		;ToXpos
			mulu.w	#32767/(XMax/2),d1
			move.l	d1,8(a1)
			move.w	YPosTemp,d1		;ToYPos
			mulu.w	#32767/(YMax/2),d1
			move.l	d1,12(a1)
			sub.l	d0,d0
			move.b	PresetSpeed,d0
			move.w	d0,16(a1)		;Rate
			moveq	#18,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			move.b	MDTwoFlag,Preserve
			movea.l	LASERfIREScrPtr,a0
			moveq	#16,d1			;Morph Screen cmd
			jsr	LfAddScreen2

			moveq	#26,d1			;Stop cmd
			jsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			sub.l	d1,d1			;Mark last
			jsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen
			jsr	SendLASERfIRESeq

.MNoLf:			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip11
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip11:		lea	StatusMorph2,a0
			jsr	PrintStatus2
			bra	Scope

.Abort:			addq.l	#8,sp
			lea	StatusBlank,a0
			jsr	PrintStatus2
			bra	Scope

.NoScrn:		move.l	a0,-(sp)
			move.l	a1,-(sp)
			bsr	RecordUpdate
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			bsr	RecordMake

			move.l	a1,-(sp)
			jsr	FlashScreen
			lea	Error24Text,a0
			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip12
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip12:		jsr	PrintStatus2
			movea.l	(sp)+,a0
			move.b	#1,FromPreset
			bra	GetCommand

.Error2:		clr.b	DrawMode
			bsr	GetDrawModeItem
			bclr	#0,12(a0)
			bsr	DrawOff
			bra	Error3

.Draw:			clr.b	DrawStatus

			tst.l	(a3)			;Screen?
			beq.s	.NoScrn

			move.l	a4,-(sp)
			move.l	a3,-(sp)

			move.l	DrawRate2,Rate		;Get rate
			bsr	GetRate
			bne	.Abort
			move.l	Rate,d0
			move.l	d0,DrawRate2

			move.l	d0,LfRate

			movea.l	(sp),a0
			movea.l	(a0),a0
			move.l	46(a0),d1
			bsr	CalcDrawRate
			bsr	RecordUpdate

			move.l	#1,DrawingLen

			move.b	MDTwoFlag,Preserve
			clr.b	MorphFlag
			bsr	FreeMorphMem
			movea.l	(sp)+,a3
			movea.l	(a3),a0
			move.b	#1,DrawingFlag
			move.l	a0,LASERfIREScrPtr
			jsr	MakeScreen2
			clr.b	DrawingFlag

			tst.b	RecordStatus
			beq.s	.Skip13

			lea	DrawScreenCmd4,a0
			tst.b	MDTwoFlag
			bne.s	.DSSkip2
			lea	DrawScreenCmd3,a0

.DSSkip2:		lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Dir2,a0
			jsr	MoveString
			subq.l	#1,a1
			movea.l	(sp),a0
			jsr	MoveString
			move.b	#'"',-(a1)
			move.b	#' ',1(a1)

			lea	2(a1),a0
			move.l	DrawRate2,d0
			jsr	HEXtoASCII

			movea.l	(sp),a0
			lea	ASCIIBuffer,a1
			move.b	#1,LCFlag
			bsr	RecordMake
			clr.b	LCFlag

.Skip13:		movea.l	(sp)+,a4
			movea.l	a4,a0
			lea	Filename4,a1
			jsr	MoveString

			tst.b	DrawMode
			beq	Scope

			movea.l	a4,a0
			lea	StatusDrawScreen2+6,a1
			moveq	#23,d0
			jsr	MoveString6

			tst.b	RecordStatus
			bne	.DNoLf

			tst.b	LASERfIREFlag
			beq	.DNoLf

			jsr	GetLASERfIREMem
			bne.s	.DLfSkip

			jsr	FlashScreen
			lea	Error3Text,a0
			jsr	PrintStatus2
			jsr	LongDelay
			bra	.DNoLf

.DLfSkip:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			moveq	#10,d1			;Move cmd
			jsr	AddLfCmd
			move.l	DefTrack,d2
			move.w	d2,6(a1)		;Track
			move.w	XPosTemp,d1		;ToXpos
			mulu.w	#32767/(XMax/2),d1
			move.l	d1,8(a1)
			move.w	YPosTemp,d1		;ToYPos
			mulu.w	#32767/(YMax/2),d1
			move.l	d1,12(a1)
			sub.l	d0,d0
			move.b	PresetSpeed,d0
			move.w	d0,16(a1)		;Rate
			moveq	#18,d0			;Cmd len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			move.b	MDTwoFlag,Preserve
			movea.l	LASERfIREScrPtr,a0
			moveq	#17,d1			;Draw Screen cmd
			jsr	LfAddScreen2

			moveq	#26,d1			;Stop cmd
			jsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			sub.l	d1,d1			;Mark last
			jsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen
			jsr	SendLASERfIRESeq

.DNoLf:			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip14
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip14:		lea	StatusDrawScreen2,a0
			jsr	PrintStatus2

			clr.l	DrawCountTemp
			move.b	#1,DrawingFlag
			bra	Scope

Vol0Up:			tst.b	ShowRSFlag
			bne.s	RotateAngle01Up

			cmp.w	#64,Vol0
			bne.s	.Skip
			clr.w	Vol0
			bra.s	.Skip2
.Skip:			addq.w	#1,Vol0
.Skip2:			move.b	#1,AD0Update

			lea	Vol0UpText2,a0
			lea	Vol0SetCmd,a1
			move.w	Vol0,d0
			bsr	RecordGadget

			jsr	PrintVol0
			tst.b	ShiftFlag
			bne	Vol1Up
			bra	Scope

RotateAngle01Up:	cmp.w	#359,RotateAngle01
			bne.s	.Skip
			clr.w	RotateAngle01
			bra.s	.Skip2
.Skip:			addq.w	#1,RotateAngle01
.Skip2:			move.w	#$0101,AD0Update

			lea	RotateAngle01UpText2,a0
			lea	RotateAngle01SetCmd,a1
			move.w	RotateAngle01,d0
			bsr	RecordGadget

			jsr	PrintRotateAngle01
			tst.b	ShiftFlag
			bne	RotateAngle23Up
			bra	Scope

Vol0Dn:			tst.b	ShowRSFlag
			bne.s	RotateAngle01Dn

			tst.w	Vol0
			bne.s	.Skip
			move.w	#64,Vol0
			bra.s	.Skip2
.Skip:			subq.w	#1,Vol0
.Skip2:			move.b	#1,AD0Update

			lea	Vol0DnText2,a0
			lea	Vol0SetCmd,a1
			move.w	Vol0,d0
			bsr	RecordGadget

			jsr	PrintVol0
			tst.b	ShiftFlag
			bne	Vol1Dn
			bra	Scope

RotateAngle01Dn:	tst.w	RotateAngle01
			bne.s	.Skip
			move.w	#359,RotateAngle01
			bra.s	.Skip2
.Skip:			subq.w	#1,RotateAngle01
.Skip2:			move.w	#$0101,AD0Update

			lea	RotateAngle01DnText2,a0
			lea	RotateAngle01SetCmd,a1
			move.w	RotateAngle01,d0
			bsr	RecordGadget

			jsr	PrintRotateAngle01
			tst.b	ShiftFlag
			bne	RotateAngle23Dn
			bra	Scope

Vol1Up:			tst.b	ShowRSFlag
			bne	RotateAngle01Up

			cmp.w	#64,Vol1
			bne.s	.Skip
			clr.w	Vol1
			bra.s	.Skip2
.Skip:			addq.w	#1,Vol1
.Skip2:			move.b	#1,AD1Update

			lea	Vol1UpText2,a0
			lea	Vol1SetCmd,a1
			move.w	Vol1,d0
			bsr	RecordGadget

			jsr	PrintVol1
			tst.b	ShiftFlag
			bne.s	Vol2Up
			bra	Scope

Vol1Dn:			tst.b	ShowRSFlag
			bne	RotateAngle01Dn

			tst.w	Vol1
			bne.s	.Skip
			move.w	#64,Vol1
			bra.s	.Skip2
.Skip:			subq.w	#1,Vol1
.Skip2:			move.b	#1,AD1Update

			lea	Vol1DnText2,a0
			lea	Vol1SetCmd,a1
			move.w	Vol1,d0
			bsr	RecordGadget

			jsr	PrintVol1
			tst.b	ShiftFlag
			bne	Vol2Dn
			bra	Scope

Vol2Up:			tst.b	ShowRSFlag
			bne.s	RotateAngle23Up

			cmp.w	#64,Vol2
			bne.s	.Skip
			clr.w	Vol2
			bra.s	.Skip2
.Skip:			addq.w	#1,Vol2
.Skip2:			move.b	#1,AD2Update

			lea	Vol2UpText2,a0
			lea	Vol2SetCmd,a1
			move.w	Vol2,d0
			bsr	RecordGadget

			jsr	PrintVol2
			tst.b	ShiftFlag
			bne	Vol3Up
			bra	Scope

RotateAngle23Up:	cmp.w	#359,RotateAngle23
			bne.s	.Skip
			clr.w	RotateAngle23
			bra.s	.Skip2
.Skip:			addq.w	#1,RotateAngle23
.Skip2:			move.w	#$0101,AD2Update

			lea	RotateAngle23UpText2,a0
			lea	RotateAngle23SetCmd,a1
			move.w	RotateAngle23,d0
			bsr	RecordGadget

			jsr	PrintRotateAngle23
			bra	Scope

Vol2Dn:			tst.b	ShowRSFlag
			bne.s	RotateAngle23Dn

			tst.w	Vol2
			bne.s	.Skip
			move.w	#64,Vol2
			bra.s	.Skip2
.Skip:			subq.w	#1,Vol2
.Skip2:			move.b	#1,AD2Update

			lea	Vol2DnText2,a0
			lea	Vol2SetCmd,a1
			move.w	Vol2,d0
			bsr	RecordGadget

			jsr	PrintVol2
			tst.b	ShiftFlag
			bne	Vol3Dn
			bra	Scope

RotateAngle23Dn:	tst.w	RotateAngle23
			bne.s	.Skip
			move.w	#359,RotateAngle23
			bra.s	.Skip2
.Skip:			subq.w	#1,RotateAngle23
.Skip2:			move.w	#$0101,AD2Update

			lea	RotateAngle23DnText2,a0
			lea	RotateAngle23SetCmd,a1
			move.w	RotateAngle23,d0
			bsr	RecordGadget

			jsr	PrintRotateAngle23
			bra	Scope

Vol3Up:			tst.b	ShowRSFlag
			bne	RotateAngle23Up

			cmp.w	#64,Vol3
			bne.s	.Skip
			clr.w	Vol3
			bra.s	.Skip2
.Skip:			addq.w	#1,Vol3
.Skip2:			move.b	#1,AD3Update

			lea	Vol3UpText2,a0
			lea	Vol3SetCmd,a1
			move.w	Vol3,d0
			bsr	RecordGadget

			jsr	PrintVol3
			bra	Scope

Vol3Dn:			tst.b	ShowRSFlag
			bne	RotateAngle23Dn

			tst.w	Vol3
			bne.s	.Skip
			move.w	#64,Vol3
			bra.s	.Skip2
.Skip:			subq.w	#1,Vol3
.Skip2:			move.b	#1,AD3Update

			lea	Vol3DnText2,a0
			lea	Vol3SetCmd,a1
			move.w	Vol3,d0
			bsr	RecordGadget

			jsr	PrintVol3
			bra	Scope

Freq0Up:		tst.b	ShowRSFlag
			bne	Spin0Up

			move.l	Len0,d1
			move.w	#10000,d0		;Max
			cmpi.l	#28,d1
			bls.s	.Skip

			move.l	#288670,d0
			divu	d1,d0

.Skip:			cmp.w	Freq0,d0
			bhi.s	.Skip2

			move.w	#1,Freq0		;Min
			cmpi.l	#547,d1
			bhs.s	.Skip3

			move.l	#547,d0
			divu	d1,d0
			move.w	d0,Freq0

			swap	d0
			tst.w	d0
			beq.s	.Skip3

.Skip2:			addq.w	#1,Freq0
.Skip3:			move.b	#1,AD0Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq0UpText2,a0
			lea	Freq0SetCmd,a1
			move.w	Freq0,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq0
			tst.b	ShiftFlag
			bne	Freq1Up
			bra	Scope

Spin0Up:		cmp.w	#359,Spin0
			bne.s	.Skip
			clr.w	Spin0
			bra.s	.Skip2
.Skip:			addq.w	#1,Spin0
.Skip2:			move.b	#1,AD0Update

			lea	Spin0UpText2,a0
			lea	Spin0SetCmd,a1
			move.w	Spin0,d0
			bsr	RecordGadget

			jsr	PrintSpin0
			tst.b	ShiftFlag
			bne	Spin1Up
			bra	Scope

Freq0Dn:		tst.b	ShowRSFlag
			bne	Spin0Dn

			move.l	Len0,d1
			move.w	#1,d0
			cmpi.l	#547,d1
			bhs.s	.Skip

			move.l	#547,d0
			divu	d1,d0

			move.l	d0,d2
			swap	d2
			tst.w	d2
			beq.s	.Skip
			addq.w	#1,d0

.Skip:			cmp.w	Freq0,d0
			blo.s	.Skip2

			move.w	#10000,Freq0
			cmpi.l	#28,d1
			bls.s	.Skip3

			move.l	#288670,d0
			divu	d1,d0
			move.w	d0,Freq0
			bra.s	.Skip3

.Skip2:			subq.w	#1,Freq0
.Skip3:			move.b	#1,AD0Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq0DnText2,a0
			lea	Freq0SetCmd,a1
			move.w	Freq0,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq0
			tst.b	ShiftFlag
			bne	Freq1Dn
			bra	Scope

Spin0Dn:		tst.w	Spin0
			bne.s	.Skip
			move.w	#359,Spin0
			bra.s	.Skip2
.Skip:			subq.w	#1,Spin0
.Skip2:			move.b	#1,AD0Update

			lea	Spin0DnText2,a0
			lea	Spin0SetCmd,a1
			move.w	Spin0,d0
			bsr	RecordGadget

			jsr	PrintSpin0
			tst.b	ShiftFlag
			bne	Spin1Dn
			bra	Scope

Freq1Up:		tst.b	ShowRSFlag
			bne	Spin1Up

			move.l	Len1,d1
			move.w	#10000,d0
			cmpi.l	#28,d1
			bls.s	.Skip

			move.l	#288670,d0
			divu	d1,d0

.Skip:			cmp.w	Freq1,d0
			bhi.s	.Skip2

			move.w	#1,Freq1
			cmpi.l	#547,d1
			bhs.s	.Skip3

			move.l	#547,d0
			divu	d1,d0
			move.w	d0,Freq1

			swap	d0
			tst.w	d0
			beq.s	.Skip3

.Skip2:			addq.w	#1,Freq1
.Skip3:			move.b	#1,AD1Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq1UpText2,a0
			lea	Freq1SetCmd,a1
			move.w	Freq1,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq1
			tst.b	ShiftFlag
			bne	Freq2Up
			bra	Scope

Spin1Up:		cmp.w	#359,Spin1
			bne.s	.Skip
			clr.w	Spin1
			bra.s	.Skip2
.Skip:			addq.w	#1,Spin1
.Skip2:			move.b	#1,AD1Update

			lea	Spin1UpText2,a0
			lea	Spin1SetCmd,a1
			move.w	Spin1,d0
			bsr	RecordGadget

			jsr	PrintSpin1
			tst.b	ShiftFlag
			bne	Spin2Up
			bra	Scope

Freq1Dn:		tst.b	ShowRSFlag
			bne	Spin1Dn

			move.l	Len1,d1
			move.w	#1,d0
			cmpi.l	#547,d1
			bhs.s	.Skip

			move.l	#547,d0
			divu	d1,d0

			move.l	d0,d2
			swap	d2
			tst.w	d2
			beq.s	.Skip
			addq.w	#1,d0

.Skip:			cmp.w	Freq1,d0
			blo.s	.Skip2

			move.w	#10000,Freq1
			cmpi.l	#28,d1
			bls.s	.Skip3

			move.l	#288670,d0
			divu	d1,d0
			move.w	d0,Freq1
			bra.s	.Skip3

.Skip2:			subq.w	#1,Freq1
.Skip3:			move.b	#1,AD1Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq1DnText2,a0
			lea	Freq1SetCmd,a1
			move.w	Freq1,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq1
			tst.b	ShiftFlag
			bne	Freq2Dn
			bra	Scope

Spin1Dn:		tst.w	Spin1
			bne.s	.Skip
			move.w	#359,Spin1
			bra.s	.Skip2
.Skip:			subq.w	#1,Spin1
.Skip2:			move.b	#1,AD1Update

			lea	Spin1DnText2,a0
			lea	Spin1SetCmd,a1
			move.w	Spin1,d0
			bsr	RecordGadget

			jsr	PrintSpin1
			tst.b	ShiftFlag
			bne	Spin2Dn
			bra	Scope

Freq2Up:		tst.b	ShowRSFlag
			bne	Spin2Up

			move.l	Len2,d1
			move.w	#10000,d0
			cmpi.l	#28,d1
			bls.s	.Skip

			move.l	#288670,d0
			divu	d1,d0

.Skip:			cmp.w	Freq2,d0
			bhi.s	.Skip2

			move.w	#1,Freq2
			cmpi.l	#547,d1
			bhs.s	.Skip3

			move.l	#547,d0
			divu	d1,d0
			move.w	d0,Freq2

			swap	d0
			tst.w	d0
			beq.s	.Skip3

.Skip2:			addq.w	#1,Freq2
.Skip3:			move.b	#1,AD2Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq2UpText2,a0
			lea	Freq2SetCmd,a1
			move.w	Freq2,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq2
			tst.b	ShiftFlag
			bne	Freq3Up
			bra	Scope

Spin2Up:		cmp.w	#359,Spin2
			bne.s	.Skip
			clr.w	Spin2
			bra.s	.Skip2
.Skip:			addq.w	#1,Spin2
.Skip2:			move.b	#1,AD2Update

			lea	Spin2UpText2,a0
			lea	Spin2SetCmd,a1
			move.w	Spin2,d0
			bsr	RecordGadget

			jsr	PrintSpin2
			tst.b	ShiftFlag
			bne	Spin3Up
			bra	Scope

Freq2Dn:		tst.b	ShowRSFlag
			bne	Spin2Dn

			move.l	Len2,d1
			move.w	#1,d0
			cmpi.l	#547,d1
			bhs.s	.Skip

			move.l	#547,d0
			divu	d1,d0

			move.l	d0,d2
			swap	d2
			tst.w	d2
			beq.s	.Skip
			addq.w	#1,d0

.Skip:			cmp.w	Freq2,d0
			blo.s	.Skip2

			move.w	#10000,Freq2
			cmpi.l	#28,d1
			bls.s	.Skip3

			move.l	#288670,d0
			divu	d1,d0
			move.w	d0,Freq2
			bra.s	.Skip3

.Skip2:			subq.w	#1,Freq2
.Skip3:			move.b	#1,AD2Update

			tst.b	ShiftFlag
			bne.s	.Skip4
			jsr	CheckSync
			jsr	CheckRestart

.Skip4:			lea	Freq2DnText2,a0
			lea	Freq2SetCmd,a1
			move.w	Freq2,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq2
			tst.b	ShiftFlag
			bne	Freq3Dn
			bra	Scope

Spin2Dn:		tst.w	Spin2
			bne.s	.Skip
			move.w	#359,Spin2
			bra.s	.Skip2
.Skip:			subq.w	#1,Spin2
.Skip2:			move.b	#1,AD2Update

			lea	Spin2DnText2,a0
			lea	Spin2SetCmd,a1
			move.w	Spin2,d0
			bsr	RecordGadget

			jsr	PrintSpin2
			tst.b	ShiftFlag
			bne	Spin3Dn
			bra	Scope

Freq3Up:		tst.b	ShowRSFlag
			bne	Spin3Up

			move.l	Len3,d1
			move.w	#10000,d0
			cmpi.l	#28,d1
			bls.s	.Skip

			move.l	#288670,d0
			divu	d1,d0

.Skip:			cmp.w	Freq3,d0
			bhi.s	.Skip2

			move.w	#1,Freq3
			cmpi.l	#547,d1
			bhs.s	.Skip3

			move.l	#547,d0
			divu	d1,d0
			move.w	d0,Freq3

			swap	d0
			tst.w	d0
			beq.s	.Skip3

.Skip2:			addq.w	#1,Freq3
.Skip3:			move.b	#1,AD3Update
			jsr	CheckSync
			jsr	CheckRestart

			lea	Freq3UpText2,a0
			lea	Freq3SetCmd,a1
			move.w	Freq3,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq3
			bra	Scope

Spin3Up:		cmp.w	#359,Spin3
			bne.s	.Skip
			clr.w	Spin3
			bra.s	.Skip2
.Skip:			addq.w	#1,Spin3
.Skip2:			move.b	#1,AD3Update

			lea	Spin3UpText2,a0
			lea	Spin3SetCmd,a1
			move.w	Spin3,d0
			bsr	RecordGadget

			jsr	PrintSpin3
			bra	Scope

Freq3Dn:		tst.b	ShowRSFlag
			bne	Spin3Dn

			move.l	Len3,d1
			move.w	#1,d0
			cmpi.l	#547,d1
			bhs.s	.Skip

			move.l	#547,d0
			divu	d1,d0

			move.l	d0,d2
			swap	d2
			tst.w	d2
			beq.s	.Skip
			addq.w	#1,d0

.Skip:			cmp.w	Freq3,d0
			blo.s	.Skip2

			move.w	#10000,Freq3
			cmpi.l	#28,d1
			bls.s	.Skip3

			move.l	#288670,d0
			divu	d1,d0
			move.w	d0,Freq3
			bra.s	.Skip3

.Skip2:			subq.w	#1,Freq3
.Skip3:			move.b	#1,AD3Update
			jsr	CheckSync
			jsr	CheckRestart

			lea	Freq3DnText2,a0
			lea	Freq3SetCmd,a1
			move.w	Freq3,d0
			move.b	#1,FromFreq
			bsr	RecordGadget

			jsr	PrintFreq3
			bra	Scope

Spin3Dn:		tst.w	Spin3
			bne.s	.Skip
			move.w	#359,Spin3
			bra.s	.Skip2
.Skip:			subq.w	#1,Spin3
.Skip2:			move.b	#1,AD3Update

			lea	Spin3DnText2,a0
			lea	Spin3SetCmd,a1
			move.w	Spin3,d0
			bsr	RecordGadget

			jsr	PrintSpin3
			bra	Scope

Phase1Up:		cmp.w	#359,Phase1
			bne.s	.Skip
			clr.w	Phase1
			bra.s	.Skip2
.Skip:			addq.w	#1,Phase1
.Skip2:			move.b	#1,AD1Update

			lea	Phase1UpText2,a0
			lea	Phase1SetCmd,a1
			move.w	Phase1,d0
			bsr	RecordGadget

			jsr	PrintPhase1
			tst.b	ShiftFlag
			bne.s	Phase2Up
			bra	Scope

Phase1Dn:		tst.w	Phase1
			bne.s	.Skip
			move.w	#359,Phase1
			bra.s	.Skip2
.Skip:			subq.w	#1,Phase1
.Skip2:			move.b	#1,AD1Update

			lea	Phase1DnText2,a0
			lea	Phase1SetCmd,a1
			move.w	Phase1,d0
			bsr	RecordGadget

			jsr	PrintPhase1
			tst.b	ShiftFlag
			bne.s	Phase2Dn
			bra	Scope

Phase2Up:		cmp.w	#359,Phase2
			bne.s	.Skip
			clr.w	Phase2
			bra.s	.Skip2
.Skip:			addq.w	#1,Phase2
.Skip2:			move.b	#1,AD2Update

			lea	Phase2UpText2,a0
			lea	Phase2SetCmd,a1
			move.w	Phase2,d0
			bsr	RecordGadget

			jsr	PrintPhase2
			tst.b	ShiftFlag
			bne.s	Phase3Up
			bra	Scope

Phase2Dn:		tst.w	Phase2
			bne.s	.Skip
			move.w	#359,Phase2
			bra.s	.Skip2
.Skip:			subq.w	#1,Phase2
.Skip2:			move.b	#1,AD2Update

			lea	Phase2DnText2,a0
			lea	Phase2SetCmd,a1
			move.w	Phase2,d0
			bsr	RecordGadget

			jsr	PrintPhase2
			tst.b	ShiftFlag
			bne.s	Phase3Dn
			bra	Scope

Phase3Up:		cmp.w	#359,Phase3
			bne.s	.Skip
			clr.w	Phase3
			bra.s	.Skip2
.Skip:			addq.w	#1,Phase3
.Skip2:			move.b	#1,AD3Update

			lea	Phase3UpText2,a0
			lea	Phase3SetCmd,a1
			move.w	Phase3,d0
			bsr.s	RecordGadget

			jsr	PrintPhase3
			bra	Scope

Phase3Dn:		tst.w	Phase3
			bne.s	.Skip
			move.w	#359,Phase3
			bra.s	.Skip2
.Skip:			subq.w	#1,Phase3
.Skip2:			move.b	#1,AD3Update

			lea	Phase3DnText2,a0
			lea	Phase3SetCmd,a1
			move.w	Phase3,d0
			bsr.s	RecordGadget

			jsr	PrintPhase3
			bra	Scope

RecordGadget:		bsr	MoreOff
			bsr	AllOff

			move.l	a0,-(sp)
			move.l	a1,-(sp)
			move.l	d0,-(sp)

			bsr	RecordUpdate

			move.l	(sp)+,d0
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			tst.b	RecordStatus
			beq.s	.Skip

			move.l	a0,-(sp)
			lea	ASCIIBuffer,a0

.Loop:			move.b	(a1)+,(a0)+
			bne.s	.Loop

			subq.l	#1,a0
			andi.l	#$ffff,d0

			tst.b	FromFreq
			beq.s	.FSkip

			divu	#10,d0
			move.l	d0,-(sp)
			andi.l	#$ffff,d0
			jsr	HEXtoASCII
			move.l	(sp)+,d0
			swap	d0
			tst.w	d0
			beq.s	.FSkip2

			move.b	#".",(a1)+
			addi.b	#"0",d0
			move.b	d0,(a1)+
			clr.b	(a1)
			bra.s	.FSkip2

.FSkip:			jsr	HEXtoASCII

.FSkip2:		movea.l	(sp),a0
			lea	ASCIIBuffer,a1

			bsr	RecordMake
			movea.l	(sp)+,a0

.Skip:			tst.b	AutoManFlag		;Stop playing?
			beq.s	.Skip2
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
.Skip2:			jsr	PrintStatus2
			clr.b	FromFreq
			rts

Sequence1:		lea	SeqMemSize1,a0
			lea	SeqMemPtr1,a1
			lea	Sequence1Filename,a2
			lea	Sequence1Text,a3
			moveq	#GD_Sequence1,d0
			bra	LoadSequence

Sequence2:		lea	SeqMemSize2,a0
			lea	SeqMemPtr2,a1
			lea	Sequence2Filename,a2
			lea	Sequence2Text,a3
			moveq	#GD_Sequence2,d0
			bra	LoadSequence

Sequence3:		lea	SeqMemSize3,a0
			lea	SeqMemPtr3,a1
			lea	Sequence3Filename,a2
			lea	Sequence3Text,a3
			moveq	#GD_Sequence3,d0
			bra	LoadSequence

Sequence4:		lea	SeqMemSize4,a0
			lea	SeqMemPtr4,a1
			lea	Sequence4Filename,a2
			lea	Sequence4Text,a3
			moveq	#GD_Sequence4,d0
			bra	LoadSequence

Sequence5:		lea	SeqMemSize5,a0
			lea	SeqMemPtr5,a1
			lea	Sequence5Filename,a2
			lea	Sequence5Text,a3
			moveq	#GD_Sequence5,d0
			bra	LoadSequence

Sequence6:		lea	SeqMemSize6,a0
			lea	SeqMemPtr6,a1
			lea	Sequence6Filename,a2
			lea	Sequence6Text,a3
			moveq	#GD_Sequence6,d0
			bra	LoadSequence

Sequence7:		lea	SeqMemSize7,a0
			lea	SeqMemPtr7,a1
			lea	Sequence7Filename,a2
			lea	Sequence7Text,a3
			moveq	#GD_Sequence7,d0
			bra	LoadSequence

Sequence8:		lea	SeqMemSize8,a0
			lea	SeqMemPtr8,a1
			lea	Sequence8Filename,a2
			lea	Sequence8Text,a3
			moveq	#GD_Sequence8,d0
			bra	LoadSequence

Sequence9:		lea	SeqMemSize9,a0
			lea	SeqMemPtr9,a1
			lea	Sequence9Filename,a2
			lea	Sequence9Text,a3
			moveq	#GD_Sequence9,d0
			bra	LoadSequence

Sequence10:		lea	SeqMemSize10,a0
			lea	SeqMemPtr10,a1
			lea	Sequence10Filename,a2
			lea	Sequence10Text,a3
			moveq	#GD_Sequence10,d0
			bra	LoadSequence

Sequence11:		lea	SeqMemSize11,a0
			lea	SeqMemPtr11,a1
			lea	Sequence11Filename,a2
			lea	Sequence11Text,a3
			moveq	#GD_Sequence11,d0
			bra	LoadSequence

Sequence12:		lea	SeqMemSize12,a0
			lea	SeqMemPtr12,a1
			lea	Sequence12Filename,a2
			lea	Sequence12Text,a3
			moveq	#GD_Sequence12,d0
			bra	LoadSequence

Sequence13:		lea	SeqMemSize13,a0
			lea	SeqMemPtr13,a1
			lea	Sequence13Filename,a2
			lea	Sequence13Text,a3
			moveq	#GD_Sequence13,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence14:		lea	SeqMemSize14,a0
			lea	SeqMemPtr14,a1
			lea	Sequence14Filename,a2
			lea	Sequence14Text,a3
			moveq	#GD_Sequence14,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence15:		lea	SeqMemSize15,a0
			lea	SeqMemPtr15,a1
			lea	Sequence15Filename,a2
			lea	Sequence15Text,a3
			moveq	#GD_Sequence15,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence16:		lea	SeqMemSize16,a0
			lea	SeqMemPtr16,a1
			lea	Sequence16Filename,a2
			lea	Sequence16Text,a3
			moveq	#GD_Sequence16,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence17:		lea	SeqMemSize17,a0
			lea	SeqMemPtr17,a1
			lea	Sequence17Filename,a2
			lea	Sequence17Text,a3
			moveq	#GD_Sequence17,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence18:		lea	SeqMemSize18,a0
			lea	SeqMemPtr18,a1
			lea	Sequence18Filename,a2
			lea	Sequence18Text,a3
			moveq	#GD_Sequence18,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence19:		lea	SeqMemSize19,a0
			lea	SeqMemPtr19,a1
			lea	Sequence19Filename,a2
			lea	Sequence19Text,a3
			moveq	#GD_Sequence19,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence20:		lea	SeqMemSize20,a0
			lea	SeqMemPtr20,a1
			lea	Sequence20Filename,a2
			lea	Sequence20Text,a3
			moveq	#GD_Sequence20,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence21:		lea	SeqMemSize21,a0
			lea	SeqMemPtr21,a1
			lea	Sequence21Filename,a2
			lea	Sequence21Text,a3
			moveq	#GD_Sequence21,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence22:		lea	SeqMemSize22,a0
			lea	SeqMemPtr22,a1
			lea	Sequence22Filename,a2
			lea	Sequence22Text,a3
			moveq	#GD_Sequence22,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence23:		lea	SeqMemSize23,a0
			lea	SeqMemPtr23,a1
			lea	Sequence23Filename,a2
			lea	Sequence23Text,a3
			moveq	#GD_Sequence23,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence24:		lea	SeqMemSize24,a0
			lea	SeqMemPtr24,a1
			lea	Sequence24Filename,a2
			lea	Sequence24Text,a3
			moveq	#GD_Sequence24,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence25:		lea	SeqMemSize25,a0
			lea	SeqMemPtr25,a1
			lea	Sequence25Filename,a2
			lea	Sequence25Text,a3
			moveq	#GD_Sequence25,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence26:		lea	SeqMemSize26,a0
			lea	SeqMemPtr26,a1
			lea	Sequence26Filename,a2
			lea	Sequence26Text,a3
			moveq	#GD_Sequence26,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence27:		lea	SeqMemSize27,a0
			lea	SeqMemPtr27,a1
			lea	Sequence27Filename,a2
			lea	Sequence27Text,a3
			moveq	#GD_Sequence27,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence28:		lea	SeqMemSize28,a0
			lea	SeqMemPtr28,a1
			lea	Sequence28Filename,a2
			lea	Sequence28Text,a3
			moveq	#GD_Sequence28,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence29:		lea	SeqMemSize29,a0
			lea	SeqMemPtr29,a1
			lea	Sequence29Filename,a2
			lea	Sequence29Text,a3
			moveq	#GD_Sequence29,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence30:		lea	SeqMemSize30,a0
			lea	SeqMemPtr30,a1
			lea	Sequence30Filename,a2
			lea	Sequence30Text,a3
			moveq	#GD_Sequence30,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence31:		lea	SeqMemSize31,a0
			lea	SeqMemPtr31,a1
			lea	Sequence31Filename,a2
			lea	Sequence31Text,a3
			moveq	#GD_Sequence31,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence32:		lea	SeqMemSize32,a0
			lea	SeqMemPtr32,a1
			lea	Sequence32Filename,a2
			lea	Sequence32Text,a3
			moveq	#GD_Sequence32,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence33:		lea	SeqMemSize33,a0
			lea	SeqMemPtr33,a1
			lea	Sequence33Filename,a2
			lea	Sequence33Text,a3
			moveq	#GD_Sequence33,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence34:		lea	SeqMemSize34,a0
			lea	SeqMemPtr34,a1
			lea	Sequence34Filename,a2
			lea	Sequence34Text,a3
			moveq	#GD_Sequence34,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence35:		lea	SeqMemSize35,a0
			lea	SeqMemPtr35,a1
			lea	Sequence35Filename,a2
			lea	Sequence35Text,a3
			moveq	#GD_Sequence35,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence36:		lea	SeqMemSize36,a0
			lea	SeqMemPtr36,a1
			lea	Sequence36Filename,a2
			lea	Sequence36Text,a3
			moveq	#GD_Sequence36,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence37:		lea	SeqMemSize37,a0
			lea	SeqMemPtr37,a1
			lea	Sequence37Filename,a2
			lea	Sequence37Text,a3
			moveq	#GD_Sequence37,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence38:		lea	SeqMemSize38,a0
			lea	SeqMemPtr38,a1
			lea	Sequence38Filename,a2
			lea	Sequence38Text,a3
			moveq	#GD_Sequence38,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence39:		lea	SeqMemSize39,a0
			lea	SeqMemPtr39,a1
			lea	Sequence39Filename,a2
			lea	Sequence39Text,a3
			moveq	#GD_Sequence39,d0
			bsr	CheckBank
			bra	LoadSequence

Sequence40:		lea	SeqMemSize40,a0
			lea	SeqMemPtr40,a1
			lea	Sequence40Filename,a2
			lea	Sequence40Text,a3
			moveq	#GD_Sequence40,d0
			bsr	CheckBank
			bra.s	LoadSequence

Sequence41:		lea	SeqMemSize41,a0
			lea	SeqMemPtr41,a1
			lea	Sequence41Filename,a2
			lea	Sequence41Text,a3
			moveq	#GD_Sequence41,d0
			bsr	CheckBank
			bra.s	LoadSequence

Sequence42:		lea	SeqMemSize42,a0
			lea	SeqMemPtr42,a1
			lea	Sequence42Filename,a2
			lea	Sequence42Text,a3
			moveq	#GD_Sequence42,d0
			bsr	CheckBank
			bra.s	LoadSequence

Sequence43:		lea	SeqMemSize43,a0
			lea	SeqMemPtr43,a1
			lea	Sequence43Filename,a2
			lea	Sequence43Text,a3
			moveq	#GD_Sequence43,d0
			bsr	CheckBank
			bra.s	LoadSequence

Sequence44:		lea	SeqMemSize44,a0
			lea	SeqMemPtr44,a1
			lea	Sequence44Filename,a2
			lea	Sequence44Text,a3
			bsr	CheckBank
			moveq	#GD_Sequence44,d0

LoadSequence:		clr.b	TriggerFlag
			clr.b	MorphStatus
			clr.b	DrawStatus
			bsr	AllOff

			tst.b	RecordStatus
			beq	.RSkip

			movem.l	d0/a0-a3,-(sp)
			bsr	RecordUpdate
			movem.l	(sp)+,d0/a0-a3

			move.l	a2,-(sp)
			move.l	(a1),RecAddPtr
			move.l	(a0),BufferSize

			movea.l	(a1),a1			;Remove stop cmd
			movea.l	a1,a2
			adda.l	(a0),a1
			movea.l	a1,a3
			subq.l	#1,a3

.RLoop:			cmpi.b	#$a,-(a1)
			beq.s	.RMaybe
			cmpa.l	a1,a2
			blo.s	.RLoop
			bra.s	.RDone

.RMaybe:		cmpa.l	a1,a3
			beq.s	.RLoop

			cmpi.b	#$a,1(a1)
			beq.s	.RLoop

			addq.l	#1,a1
			lea	StopCmd,a0
			jsr	CmpString
			beq.s	.RDone

			suba.l	a1,a3
			move.l	a3,d0
			addq.l	#2,d0
			sub.l	d0,BufferSize

.RDone:			tst.l	SeqMemSize
			beq.s	.SSkip

			addq.l	#2,BufferSize
			move.b	#1,AddLfFlag

.SSkip:			bsr	RecordAdd
			clr.b	AddLfFlag

			lea	WaitCmd2,a0
			lea	RecordBuff,a1
			jsr	MoveString
			subq.l	#1,a1
			move.l	a1,RecordBuffPtr

			move.l	#-1,SequenceCountTrigTemp
			move.b	#2,RecordStatus

			movea.l	(sp)+,a2
			lea	StatusRecSeq,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			movea.l	a2,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bra	Scope

.RSkip:			tst.b	AttachStatus
			beq	.Skip2

			clr.b	AttachStatus

			move.l	d0,-(sp)
			move.l	a3,-(sp)
			move.l	a2,-(sp)
			move.l	a1,-(sp)
			move.l	a0,-(sp)

			move.l	SeqMemSize,d0
			beq	Error7

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	.Error

			movea.l	(sp),a0
			movea.l	4(sp),a1
			move.l	d0,-(sp)
			jsr	FreeSeqMem2

			move.l	(sp)+,d0
			movea.l	(sp)+,a0
			movea.l	(sp)+,a1

			move.l	d0,(a1)
			move.l	SeqMemSize,(a0)

			movea.l	d0,a1
			movea.l	SeqMemPtr,a0
			move.l	SeqMemSize,d0
			jsr	MoveMemBlock

			jsr	CheckNewSequence

			lea	Filename2,a0
			movea.l	(sp)+,a1
			jsr	MoveString

			lea	Filename2,a0
			movea.l	(sp)+,a1
			moveq	#9,d0
			jsr	MoveString7

			move.l	(sp)+,d0
			cmpi.l	#GD_Sequence12,d0
			bls.s	.Okay

			tst.b	BigScreenFlag
			beq.s	.Miss

.Okay:			jsr	FindGadPtr
			jsr	GadChg

.Miss:			tst.b	FromConfig
			beq.s	.Skip
			rts

.Skip:			lea	StatusAttach3,a0
			jsr	PrintStatus
			bra	Scope

.Error:			adda.w	#20,sp
			bra	Error3

.Error2:		jsr	FlashScreen
			lea	Error9Text,a0
			jsr	PrintStatus
			bra	Scope

.Skip2:			move.l	(a0),d0
			beq.s	.Error2

			move.l	a2,-(sp)
			move.l	a1,-(sp)
			move.l	a0,-(sp)

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	Error3

			move.l	d0,-(sp)
			jsr	FreeSeqMem
			move.l	(sp)+,d0
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			move.l	d0,SeqMemPtr
			move.l	(a1),SeqMemSize

			movea.l	(a0),a0
			movea.l	d0,a1
			move.l	SeqMemSize,d0
			jsr	MoveMemBlock

			movea.l	(sp)+,a0
			lea	Filename2,a1
			jsr	MoveString

			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PreloadFlag
			jsr	FreePreloadMem
			bra	Start

Trigger:		clr.b	AttachStatus
			clr.b	MorphStatus
			clr.b	DrawStatus
			bsr	RecordUpdate
			clr.b	RecordStatus
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			bchg	#0,TriggerFlag
			bne.s	.Start

			move.l	#-1,SequenceCountTrigTemp
			bra	Scope

.Start:			move.l	SequenceCountTrigTemp,SequenceCountTrig
			move.l	SequenceCountTrigTemp,WaitCount

			tst.b	PlayStatus
			beq.s	.Skip

			move.b	#2,PlayStatus
			bra	Scope

.Skip:			move.b	#2,PlayStatus
			bra	Start2

North:			bsr	MoreOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode

			tst.b	ShiftMode
			bne	ShiftNorth

			tst.b	RollMode
			bne	RollEast

			tst.b	ResizeMode
			beq.s	.Skip

			cmpi.b	#254,YSizeMaxTemp
			bhs	Scope

			tst.b	YSizeMinTemp
			beq	Scope

			jsr	TemplateOff
			addq.b	#1,YSizeMaxTemp
			subq.b	#1,YSizeMinTemp
			jsr	TemplateOn
			jsr	PrintSizeAdjust
			bra	Scope

.Skip:			tst.b	RotateMode
			beq.s	.Skip7

			tst.b	D3Flag
			beq	Scope

			cmpi.w	#359,SpinAngle
			bne.s	.RSkip
			move.w	#-1,SpinAngle

.RSkip:			addq.w	#1,SpinAngle
			jmp	RotateIt

.Skip7:			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			clr.b	MergeMode
			clr.b	LastFlag

			tst.b	LineMode
			beq.s	.Skip2

			cmpi.b	#127,YLinePos
			beq	Scope

			bsr	LineLineOff
			addq.b	#1,YLinePos
			move.b	YLinePos,YMousePos
			bsr	LineLineOn
			bsr	ShowPXY
			bra	Scope

.Skip2:			tst.b	ArcMode
			beq.s	.Skip3

			cmpi.b	#127,YArcPos
			beq	Scope

			bsr	ArcOutlineOff
			addq.b	#1,YArcPos
			move.b	YArcPos,YMousePos
			bsr	ArcOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip3:			tst.b	BoxMode
			beq.s	.Skip4

			tst.b	BoxOffFlag
			beq.s	.BSkip

			cmpi.b	#127,YBoxPos2
			beq	Scope

			bsr	BoxOutlineOff
			addq.b	#1,YBoxPos2
			move.b	YBoxPos2,YMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.BSkip:			cmpi.b	#127,YBoxPos
			beq	Scope

			bsr	BoxOutlineOff
			addq.b	#1,YBoxPos
			move.b	YBoxPos,YBoxPos2
			move.b	YBoxPos,YMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip4:			tst.b	EllipseMode
			beq	.Skip5

			tst.b	EllipseOffFlag
			bne.s	.CSkip2

			cmpi.b	#125,YEllipsePos
			beq	Scope

			sub.l	d1,d1
			move.b	EllipseSize2,d0
			add.b	YEllipsePos,d0
			cmpi.b	#127,d0
			bne.s	.CSkip
			moveq	#1,d1

.CSkip:			move.l	d1,-(sp)
			bsr	EllipseOutlineOff
			move.l	(sp)+,d0
			sub.b	d0,EllipseSize2
			addq.b	#1,YEllipsePos
			move.b	YEllipsePos,YMousePos
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.CSkip2:		move.b	EllipseSize2,d0
			add.b	YEllipsePos,d0
			cmpi.b	#127,d0
			beq	Scope

			sub.l	d0,d0
			sub.b	EllipseSize2,d0
			add.b	YEllipsePos,d0
			cmpi.b	#-127,d0
			beq	Scope

			bsr	EllipseOutlineOff
			addq.b	#1,EllipseSize2
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.Skip5:			tst.b	MoveMode
			beq.s	.Skip6

			cmpi.b	#2,MoveMode
			bne	Scope

			movea.l	MovePtr,a0
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0
			cmpi.b	#-127,(a0)
			beq	Scope

			subq.b	#1,(a0)
			bra.s	.TSkip2

.TSkip:			cmpi.b	#127,(a0)
			beq	Scope

			addq.b	#1,(a0)
			move.b	#1,AD1Update
			move.b	#1,AD2Update

.TSkip2:		move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintMovePntPos
			bra	Scope

.Skip6:			bsr	Mouse3DOff

			cmpi.w	#YMax,YPosTemp
			beq	Scope

			addq.w	#1,YPosTemp
			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			bsr	RecordMove
			jsr	LfSendPos
			bra	Scope

SeqStuffOff:		bsr	MoreOff
			bsr	RecordUpdate
			clr.b	RecordStatus
			rts

ShiftNorth:		bsr.s	SeqStuffOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Vol0Up

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			move.b	#1,ShiftMode

			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a0

.ZLoop:			cmpi.b	#-127,(a0)+
			beq	Scope
			dbf	d0,.ZLoop

			bsr.s	GetLastStartPtr
			adda.w	#MaxPoints*2,a0

.ZLoop2:		subq.b	#1,(a0)+
			dbf	d0,.ZLoop2

			subq.b	#1,ZShiftPos
			subq.b	#1,ZShiftPos2
			move.l	#$01010101,AD0Update
			bra.s	.Skip

.Loop:			cmpi.b	#127,(a0)+
			beq	Scope
			dbf	d0,.Loop

			bsr.s	GetLastStartPtr
			adda.w	#MaxPoints,a0

.Loop2:			addq.b	#1,(a0)+
			dbf	d0,.Loop2

			addq.b	#1,YShiftPos
			addq.b	#1,YShiftPos2
			move.b	#1,AD1Update
			move.b	#1,AD2Update

.Skip:			move.b	#1,ShiftFlag3
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintShiftPos
			bra	Scope

GetLastStartPtr:	tst.b	MergeMode
			beq.s	.Skip
			movea.l	XDataMergePtr,a0
			move.l	XDataMergeSize,d0
			bra	.Ptr

.Skip:			tst.b	EllipseMode
			beq.s	.Skip2
			movea.l	XDataEllipsePtr,a0
			move.l	XDataEllipseSize,d0
			bra	.Ptr

.Skip2:			tst.b	BoxMode
			beq.s	.Skip3
			movea.l	XDataBoxPtr,a0
			move.l	XDataBoxSize,d0
			bra.s	.Ptr

.Skip3:			tst.b	ArcMode
			beq.s	.Skip4
			movea.l	XDataArcPtr,a0
			move.l	XDataArcSize,d0
			bra.s	.Ptr

.Skip4:			tst.b	LineMode
			beq.s	.Skip5
			movea.l	XDataLinePtr,a0
			move.l	XDataLineSize,d0
			bra.s	.Ptr

.Skip5:			tst.b	TextMode
			beq.s	.Skip6
			movea.l	XDataTextPtr,a0
			move.l	XDataTextSize,d0
			bra.s	.Ptr

.Skip6:			tst.b	DragMode
			beq.s	.Skip7
			movea.l	XDataDragPtr,a0
			move.l	XDataDragSize,d0
			bra.s	.Ptr

.Skip7:			tst.b	LastFlag
			beq.s	.Start
			movea.l	XDataLastPtr,a0
			move.l	XDataLastSize,d0

.Ptr:			tst.l	a0
			beq.s	.Start
			subq.l	#1,d0
			rts

.Start:			movea.l	DrawMemPtr,a0
			move.l	Len0,d0
			subq.l	#1,d0
			rts

South:			bsr	MoreOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode

			tst.b	ShiftMode
			bne	ShiftSouth

			tst.b	RollMode
			bne	RollWest

			tst.b	ResizeMode
			beq.s	.Skip

			move.b	YSizeMaxTemp,d0
			subq.b	#1,d0
			move.b	YSizeMinTemp,d1
			addq.b	#1,d1
			cmp.b	d0,d1
			bhs	Scope

			jsr	TemplateOff
			subq.b	#1,YSizeMaxTemp
			addq.b	#1,YSizeMinTemp
			jsr	TemplateOn
			jsr	PrintSizeAdjust
			bra	Scope

.Skip:			tst.b	RotateMode
			beq.s	.Skip7

			tst.b	D3Flag
			beq	Scope

			tst.w	SpinAngle
			bne.s	.RSkip
			move.w	#360,SpinAngle

.RSkip:			subq.w	#1,SpinAngle
			jmp	RotateIt

.Skip7:			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			clr.b	MergeMode
			clr.b	LastFlag

			tst.b	LineMode
			beq.s	.Skip2

			cmpi.b	#-127,YLinePos
			beq	Scope

			bsr	LineLineOff
			subq.b	#1,YLinePos
			move.b	YLinePos,YMousePos
			bsr	LineLineOn
			bsr	ShowPXY
			bra	Scope

.Skip2:			tst.b	ArcMode
			beq.s	.Skip3

			cmpi.b	#-127,YArcPos
			beq	Scope

			bsr	ArcOutlineOff
			subq.b	#1,YArcPos
			move.b	YArcPos,YMousePos
			bsr	ArcOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip3:			tst.b	BoxMode
			beq.s	.Skip4

			tst.b	BoxOffFlag
			beq.s	.BSkip

			cmpi.b	#-127,YBoxPos2
			beq	Scope

			bsr	BoxOutlineOff
			subq.b	#1,YBoxPos2
			move.b	YBoxPos2,YMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.BSkip:			cmpi.b	#-127,YBoxPos
			beq	Scope

			bsr	BoxOutlineOff
			subq.b	#1,YBoxPos
			move.b	YBoxPos,YBoxPos2
			move.b	YBoxPos,YMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip4:			tst.b	EllipseMode
			beq.s	.Skip5

			tst.b	EllipseOffFlag
			bne.s	.CSkip2

			cmpi.b	#-125,YEllipsePos
			beq	Scope

			sub.l	d1,d1
			sub.l	d0,d0
			sub.b	EllipseSize2,d0
			add.b	YEllipsePos,d0
			cmpi.b	#-127,d0
			bne.s	.CSkip
			moveq	#1,d1

.CSkip:			move.l	d1,-(sp)
			bsr	EllipseOutlineOff
			move.l	(sp)+,d0
			sub.b	d0,EllipseSize2
			subq.b	#1,YEllipsePos
			move.b	YEllipsePos,YMousePos
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.CSkip2:		cmpi.b	#2,EllipseSize2
			beq	Scope

			bsr	EllipseOutlineOff
			subq.b	#1,EllipseSize2
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.Skip5:			tst.b	MoveMode
			beq.s	.Skip6

			cmpi.b	#2,MoveMode
			bne	Scope

			movea.l	MovePtr,a0
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0
			cmpi.b	#127,(a0)
			beq	Scope

			addq.b	#1,(a0)
			bra.s	.TSkip2

.TSkip:			cmpi.b	#-127,(a0)
			beq	Scope

			subq.b	#1,(a0)
			move.b	#1,AD1Update
			move.b	#1,AD2Update

.TSkip2:		move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintMovePntPos
			bra	Scope

.Skip6:			bsr	Mouse3DOff

			tst.w	YPosTemp
			beq	Scope

			subq.w	#1,YPosTemp
			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			bsr	RecordMove
			jsr	LfSendPos
			bra	Scope

ShiftSouth:		bsr	SeqStuffOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Vol0Dn

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			move.b	#1,ShiftMode

			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a0

.ZLoop:			cmpi.b	#127,(a0)+
			beq	Scope
			dbf	d0,.ZLoop

			bsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0

.ZLoop2:		addq.b	#1,(a0)+
			dbf	d0,.ZLoop2

			addq.b	#1,ZShiftPos
			addq.b	#1,ZShiftPos2
			move.l	#$01010101,AD0Update
			bra.s	.Skip

.Loop:			cmpi.b	#-127,(a0)+
			beq	Scope
			dbf	d0,.Loop

			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

.Loop2:			subq.b	#1,(a0)+
			dbf	d0,.Loop2

			subq.b	#1,YShiftPos
			subq.b	#1,YShiftPos2
			move.b	#1,AD1Update
			move.b	#1,AD2Update

.Skip:			move.b	#1,ShiftFlag3
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintShiftPos
			bra	Scope

East:			bsr	MoreOff
			clr.b	InsertMode

			tst.b	ShiftMode
			bne	ShiftEast

			tst.b	RollMode
			bne	RollEast

			tst.b	ResizeMode
			beq.s	.Skip

			cmpi.b	#254,XSizeMaxTemp
			bhs	Scope

			tst.b	XSizeMinTemp
			beq	Scope

			jsr	TemplateOff
			addq.b	#1,XSizeMaxTemp
			subq.b	#1,XSizeMinTemp
			jsr	TemplateOn
			jsr	PrintSizeAdjust
			bra	Scope

.Skip:			tst.b	RotateMode
			beq.s	.Skip8

			cmpi.w	#359,RotateAngle
			bne.s	.RSkip
			move.w	#-1,RotateAngle

.RSkip:			addq.w	#1,RotateAngle
			jmp	RotateIt

.Skip8:			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			clr.b	MergeMode
			clr.b	LastFlag

			tst.b	LineMode
			beq.s	.Skip2

			cmpi.b	#127,XLinePos
			beq	Scope

			bsr	LineLineOff
			addq.b	#1,XLinePos
			move.b	XLinePos,XMousePos
			bsr	LineLineOn
			bsr	ShowPXY
			bra	Scope

.Skip2:			tst.b	ArcMode
			beq.s	.Skip3

			cmpi.b	#127,XArcPos
			beq	Scope

			bsr	ArcOutlineOff
			addq.b	#1,XArcPos
			move.b	XArcPos,XMousePos
			bsr	ArcOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip3:			tst.b	BoxMode
			beq.s	.Skip4

			tst.b	BoxOffFlag
			beq.s	.BSkip

			cmpi.b	#127,XBoxPos2
			beq	Scope

			bsr	BoxOutlineOff
			addq.b	#1,XBoxPos2
			move.b	XBoxPos2,XMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.BSkip:			cmpi.b	#127,XBoxPos
			beq	Scope

			bsr	BoxOutlineOff
			addq.b	#1,XBoxPos
			move.b	XBoxPos,XBoxPos2
			move.b	XBoxPos,XMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip4:			tst.b	EllipseMode
			beq	.Skip5

			tst.b	EllipseOffFlag
			bne.s	.CSkip2

			cmpi.b	#125,XEllipsePos
			beq	Scope

			sub.l	d1,d1
			move.b	EllipseSize,d0
			add.b	XEllipsePos,d0
			cmpi.b	#127,d0
			bne.s	.CSkip
			moveq	#1,d1

.CSkip:			move.l	d1,-(sp)
			bsr	EllipseOutlineOff
			move.l	(sp)+,d0
			sub.b	d0,EllipseSize
			addq.b	#1,XEllipsePos
			move.b	XEllipsePos,XMousePos
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.CSkip2:		move.b	EllipseSize,d0
			add.b	XEllipsePos,d0
			cmpi.b	#127,d0
			beq	Scope

			sub.l	d0,d0
			sub.b	EllipseSize,d0
			add.b	XEllipsePos,d0
			cmpi.b	#-127,d0
			beq	Scope

			bsr	EllipseOutlineOff
			addq.b	#1,EllipseSize
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.Skip5:			tst.b	MoveMode
			beq.s	.Skip6

			cmpi.b	#2,MoveMode
			bne.s	.Skip6

			movea.l	MovePtr,a0

			cmpi.b	#127,(a0)
			beq	Scope

			addq.b	#1,(a0)

			move.b	#1,AD0Update
			move.b	#1,AD3Update

			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintMovePntPos
			bra	Scope

.Skip6:			tst.b	MagGlassFlag
			beq.s	.Skip7

			move.w	StackNumber,d0
			cmpi.w	#1,d0
			bls.s	.Skip7

			cmp.w	StackNumber2,d0
			bls	Scope

			addq.w	#1,StackNumber2
			jsr	PrintStack
			bra	Scope

.Skip7:			tst.b	MoveMode
			bne	Scope

			bsr	Mouse3DOff
			clr.b	InsertMode2
			clr.b	DeleteMode

			cmpi.w	#XMax,XPosTemp
			beq	Scope

			addq.w	#1,XPosTemp
			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			bsr	RecordMove
			jsr	LfSendPos
			bra	Scope

ShiftEast:		bsr	SeqStuffOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Freq0Up

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			move.b	#1,ShiftMode

			bsr	GetLastStartPtr

.Loop:			cmpi.b	#127,(a0)+
			beq	Scope
			dbf	d0,.Loop

			bsr	GetLastStartPtr

.Loop2:			addq.b	#1,(a0)+
			dbf	d0,.Loop2

			addq.b	#1,XShiftPos
			addq.b	#1,XShiftPos2
			move.b	#1,ShiftFlag3
			move.b	#1,AD0Update
			move.b	#1,AD3Update
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintShiftPos
			bra	Scope

RollEast:		bsr	SeqStuffOff
			jsr	ShiftOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Scope

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			bsr	GetLastStartPtr
			beq	Error16

			tst.b	RollMode
			bne.s	.Skip

			move.b	#1,RollMode
			jsr	CheckCenter
			jsr	TurnItOff2
			clr.b	RollFlag

.Skip:			jsr	RollDotOff

			bsr	GetLastStartPtr		;X
			jsr	SetRollCount
			lea	1(a0),a1
			move.b	(a0),d1
			subq.l	#1,d0

.Loop:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop
			move.b	d1,(a0)

			bsr	GetLastStartPtr		;Y
			adda.w	#MaxPoints,a0
			lea	1(a0),a1
			move.b	(a0),d1
			subq.l	#1,d0

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop2
			move.b	d1,(a0)

			tst.b	D3Flag
			beq.s	.D3Skip

			bsr	GetLastStartPtr		;Z
			adda.w	#MaxPoints*2,a0
			lea	1(a0),a1
			move.b	(a0),d1
			subq.l	#1,d0

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop3
			move.b	d1,(a0)

.D3Skip:		bsr	GetLastStartPtr
			cmpa.l	DrawMemPtr,a0
			bne.s	.Skip2

			move.l	Len0,d1
			subq.l	#1,d1
			cmp.l	d0,d1
			bne.s	.Skip2

			jsr	FreeCharBSMem
			bsr	ClrLastPtrs

.Skip2:			jsr	RollDotOn
			move.b	#1,RollFlag3

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.l	#$01010101,AD0Update
			addq.w	#1,RollCount
			jsr	PrintRollCount
			bra	Scope

West:			bsr	MoreOff
			clr.b	InsertMode

			tst.b	ShiftMode
			bne	ShiftWest

			tst.b	RollMode
			bne	RollWest

			tst.b	ResizeMode
			beq.s	.Skip

			move.b	XSizeMaxTemp,d0
			subq.b	#1,d0
			move.b	XSizeMinTemp,d1
			addq.b	#1,d1
			cmp.b	d0,d1
			bhs	Scope

			jsr	TemplateOff
			subq.b	#1,XSizeMaxTemp
			addq.b	#1,XSizeMinTemp
			jsr	TemplateOn
			jsr	PrintSizeAdjust
			bra	Scope

.Skip:			tst.b	RotateMode
			beq.s	.Skip8

			tst.w	RotateAngle
			bne.s	.RSkip
			move.w	#360,RotateAngle

.RSkip:			subq.w	#1,RotateAngle
			jmp	RotateIt

.Skip8:			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			clr.b	MergeMode
			clr.b	LastFlag

			tst.b	LineMode
			beq.s	.Skip2

			cmpi.b	#-127,XLinePos
			beq	Scope

			bsr	LineLineOff
			subq.b	#1,XLinePos
			move.b	XLinePos,XMousePos
			bsr	LineLineOn
			bsr	ShowPXY
			bra	Scope

.Skip2:			tst.b	ArcMode
			beq.s	.Skip3

			cmpi.b	#-127,XArcPos
			beq	Scope

			bsr	ArcOutlineOff
			subq.b	#1,XArcPos
			move.b	XArcPos,XMousePos
			bsr	ArcOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip3:			tst.b	BoxMode
			beq.s	.Skip4

			tst.b	BoxOffFlag
			beq.s	.BSkip

			cmpi.b	#-127,XBoxPos2
			beq	Scope

			bsr	BoxOutlineOff
			subq.b	#1,XBoxPos2
			move.b	XBoxPos2,XMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.BSkip:			cmpi.b	#-127,XBoxPos
			beq	Scope

			bsr	BoxOutlineOff
			subq.b	#1,XBoxPos
			move.b	XBoxPos,XBoxPos2
			move.b	XBoxPos,XMousePos
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip4:			tst.b	EllipseMode
			beq.s	.Skip5

			tst.b	EllipseOffFlag
			bne.s	.CSkip2

			cmpi.b	#-125,XEllipsePos
			beq	Scope

			sub.l	d1,d1
			sub.l	d0,d0
			sub.b	EllipseSize,d0
			add.b	XEllipsePos,d0
			cmpi.b	#-127,d0
			bne.s	.CSkip
			moveq	#1,d1

.CSkip:			move.l	d1,-(sp)
			bsr	EllipseOutlineOff
			move.l	(sp)+,d0
			sub.b	d0,EllipseSize
			subq.b	#1,XEllipsePos
			move.b	XEllipsePos,XMousePos
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.CSkip2:		cmpi.b	#2,EllipseSize
			beq	Scope

			bsr	EllipseOutlineOff
			subq.b	#1,EllipseSize
			bsr	EllipseOutlineOn
			bsr	PrintEllipseInfo
			bra	Scope

.Skip5:			tst.b	MoveMode
			beq.s	.Skip6

			cmpi.b	#2,MoveMode
			bne.s	.Skip6

			movea.l	MovePtr,a0

			cmpi.b	#-127,(a0)
			beq	Scope

			subq.b	#1,(a0)

			move.b	#1,AD0Update
			move.b	#1,AD3Update

			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintMovePntPos
			bra	Scope

.Skip6:			tst.b	MagGlassFlag
			beq.s	.Skip7

			cmpi.w	#1,StackNumber
			bls.s	.Skip7

			cmpi.w	#1,StackNumber2
			beq	Scope

			subq.w	#1,StackNumber2
			jsr	PrintStack
			bra	Scope

.Skip7:			tst.b	MoveMode
			bne	Scope

			bsr	Mouse3DOff
			clr.b	InsertMode2
			clr.b	DeleteMode

			tst.w	XPosTemp
			beq	Scope

			subq.w	#1,XPosTemp
			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			bsr	RecordMove
			jsr	LfSendPos
			bra	Scope

ShiftWest:		bsr	SeqStuffOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Freq0Dn

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			move.b	#1,ShiftMode

			bsr	GetLastStartPtr

.Loop:			cmpi.b	#-127,(a0)+
			beq	Scope
			dbf	d0,.Loop

			bsr	GetLastStartPtr

.Loop2:			subq.b	#1,(a0)+
			dbf	d0,.Loop2

			subq.b	#1,XShiftPos
			subq.b	#1,XShiftPos2
			move.b	#1,ShiftFlag3
			move.b	#1,AD0Update
			move.b	#1,AD3Update
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			jsr	PrintShiftPos
			bra	Scope

RollWest:		bsr	SeqStuffOff
			jsr	ShiftOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Scope

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			bsr	GetLastStartPtr
			beq	Error16

			tst.b	RollMode
			bne.s	.Skip

			move.b	#1,RollMode
			jsr	CheckCenter
			jsr	TurnItOff2
			clr.b	RollFlag

.Skip:			jsr	RollDotOff

			bsr	GetLastStartPtr		;X
			jsr	SetRollCount
			adda.l	d0,a0
			addq.l	#1,a0
			lea	-1(a0),a1
			move.b	(a1),d1
			subq.l	#1,d0

.Loop:			move.b	-(a1),-(a0)
			dbf	d0,.Loop
			move.b	d1,-(a0)

			bsr	GetLastStartPtr		;Y
			adda.w	#MaxPoints,a0
			adda.l	d0,a0
			addq.l	#1,a0
			lea	-1(a0),a1
			move.b	(a1),d1
			subq.l	#1,d0

.Loop2:			move.b	-(a1),-(a0)
			dbf	d0,.Loop2
			move.b	d1,-(a0)

			tst.b	D3Flag
			beq.s	.D3Skip

			bsr	GetLastStartPtr		;Z
			adda.w	#MaxPoints*2,a0
			adda.l	d0,a0
			addq.l	#1,a0
			lea	-1(a0),a1
			move.b	(a1),d1
			subq.l	#1,d0

.Loop3:			move.b	-(a1),-(a0)
			dbf	d0,.Loop3
			move.b	d1,-(a0)

.D3Skip:		bsr	GetLastStartPtr
			cmpa.l	DrawMemPtr,a0
			bne.s	.Skip2

			move.l	Len0,d1
			subq.l	#1,d1
			cmp.l	d0,d1
			bne.s	.Skip2

			jsr	FreeCharBSMem
			bsr	ClrLastPtrs

.Skip2:			jsr	RollDotOn
			move.b	#1,RollFlag3

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.l	#$01010101,AD0Update
			subq.w	#1,RollCount
			jsr	PrintRollCount
			bra	Scope

CenterIt:		bsr	MoreOff
			clr.b	InsertMode
			clr.b	DeleteMode

			tst.b	ShiftMode
			bne	ShiftCenterIt

			tst.b	RollMode
			beq.s	.Skip

			jsr	RollOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Skip:			tst.b	ResizeMode
			bne.l	ResizeIt

			tst.b	RotateMode
			beq.s	.Skip6

			tst.w	SpinAngle
			bne.s	.RSkip

			tst.w	RotateAngle
			beq	Scope

.RSkip:			clr.w	SpinAngle
			clr.w	RotateAngle
			jmp	RotateIt

.Skip6:			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			clr.b	MergeMode
			clr.b	LastFlag

			tst.b	LineMode
			bne	LineIt2

			tst.b	ArcMode
			beq.s	.ASkip

			bsr	GetMousePos3D2
			move.b	XMousePos3D,XMousePosTemp2
			move.b	YMousePos3D,YMousePosTemp2
			bsr	ArcPos2
			bra	ArcIt2

.ASkip:			tst.b	BoxMode
			beq.s	.Skip2

			tst.b	BoxOffFlag
			bne	BoxIt2
			bsr	GetMousePos3D2
			move.b	#1,BoxOffFlag
			move.b	ZMousePos,ZBoxPos
			bsr	BoxOutlineOff
			move.b	XMousePos3D,XBoxPos
			move.b	YMousePos3D,YBoxPos
			move.b	XMousePos,XBoxPos2
			move.b	YMousePos,YBoxPos2
			bsr	BoxOutlineOn
			bsr	ShowPXY
			bra	Scope

.Skip2:			tst.b	EllipseMode
			beq.s	.Skip3

			tst.b	EllipseOffFlag
			bne	EllipseIt2
			bsr	GetMousePos3D2
			move.b	ZMousePos,ZEllipsePos
			move.b	XMousePos3D,XMousePosTemp2
			move.b	YMousePos3D,YMousePosTemp2
			bsr	EllipsePos2
			move.b	#1,EllipseOffFlag
			bra	Scope

.Skip3:			tst.b	MoveMode
			beq.s	.Skip4

			cmpi.b	#2,MoveMode
			bne.l	MoveIt

			clr.b	MoveMode
			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Skip4:			tst.b	InsertMode2
			beq.s	.Skip5

			cmpi.b	#2,InsertMode2
			bne.l	InsertIt4

			clr.b	InsertMode2
			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Skip5:			bsr	Mouse3DOff

			cmpi.w	#XMax/2,XPosTemp
			bne.s	.Move

			cmpi.w	#YMax/2,YPosTemp
			bne.s	.Move

			jsr	FlashScreen
			lea	StatusCentered,a0
			jsr	PrintStatus2
			bra	Scope

.Move:			bsr.s	MoveToCenter
			bsr	RecordMove
			jsr	LfSendPos
			bra	Scope

MoveToCenter:		move.w	#XMax/2,XPosTemp
			move.w	#YMax/2,YPosTemp
			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			rts

ShiftCenterIt:		bsr	SeqStuffOff
			jsr	RollOff
			jsr	ResizeOff
			jsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			tst.b	DrawMode
			beq	Scope

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			bsr	GetLastStartPtr
			jsr	FindCenter

			bsr	GetLastStartPtr

.Loop:			sub.b	d1,(a0)+
			dbf	d0,.Loop
			move.l	d1,-(sp)

			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			jsr	FindCenter

			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

.Loop2:			sub.b	d1,(a0)+
			dbf	d0,.Loop2
			move.l	d1,-(sp)

			tst.b	D3Flag
			beq.s	.Skip

			bsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			jsr	FindCenter

			bsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0

.Loop3:			sub.b	d1,(a0)+
			dbf	d0,.Loop3

.Skip:			move.l	(sp)+,d2
			move.l	(sp)+,d0

			tst.b	d2
			bne.s	.Done

			tst.b	d0
			bne.s	.Done

			tst.b	d1
			beq.s	.Already

.Done:			move.b	#1,ShiftMode
			move.b	#1,ShiftFlag3
			jsr	ShiftOff
			move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag

			clr.b	XShiftPos
			clr.b	YShiftPos
			clr.b	ZShiftPos

			bsr	ShowPoints
			lea	StatusPointsCentered,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bra	Scope

.Already:		clr.b	ShiftMode		;No undo
			clr.b	ShiftFlag2
			clr.b	ShiftFlag3
			jsr	FlashScreen
			lea	StatusPointsCentered2,a0
			jsr	PrintStatus
			bra	Scope

EscShift:		bsr	SeqStuffOff
			jsr	TurnItOff2
			bsr	Mouse3DOff

			tst.b	ShiftFlag3
			bne	.Skip

			tst.b	DragMode
			bne	.Off

			tst.b	TextMode
			bne	.Off

			tst.b	LineMode
			bne	.Off

			tst.b	ArcMode
			bne	.Off

			tst.b	BoxMode
			bne	.Off

			tst.b	EllipseMode
			bne	.Off

			tst.b	MergeMode
			bne	.Off

			tst.b	ShiftMode
			bne	.Off

			tst.b	RollMode
			bne.s	.Off

			tst.b	ResizeMode
			bne.s	.Off

			tst.b	RotateMode
			bne.s	.Off

			tst.b	InsertMode
			bne.s	.Off

			tst.b	InsertMode2
			bne.s	.Off

			tst.b	DeleteMode
			bne.s	.Off

			tst.b	MoveMode
			beq	Scope

			cmpi.b	#2,MoveMode
			bne.s	.Off

			movea.l	MovePtr,a0
			move.b	MovePntXTemp,(a0)
			adda.w	#MaxPoints,a0
			move.b	MovePntYTemp,(a0)
			adda.w	#MaxPoints,a0
			move.b	MovePntZTemp,(a0)

			move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag

.Off:			bsr	AllOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Skip:			clr.b	ShiftFlag3
			bsr	OtherHalfOff

			tst.b	DrawMode
			beq	Scope

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			bsr	GetLastStartPtr
			move.b	XShiftPos,d1
			beq.s	.Skip2

.Loop:			sub.b	d1,(a0)+
			dbf	d0,.Loop

.Skip2:			bsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			move.b	YShiftPos,d1
			beq.s	.Skip3

.Loop2:			sub.b	d1,(a0)+
			dbf	d0,.Loop2

.Skip3:			bsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			move.b	ZShiftPos,d1
			beq.s	.Skip4

.Loop3:			sub.b	d1,(a0)+
			dbf	d0,.Loop3

.Skip4:			move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag
			clr.b	ShiftFlag2

			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

RecordMove:		bsr	RecordUpdate
			move.b	#1,MoveStatus3
			bsr	RecordMake
			clr.b	MoveStatus3
			rts

ShutterRaw:		moveq	#GD_Shutter,d0
			jsr	FindGadPtr

			tst.b	ShutterFlag
			beq.s	.On
			jsr	GadOff
			bra.s	Shutter

.On:			jsr	GadOn

Shutter:		bsr	MoreOff
			bsr	AllOff

			bsr.s	ShutterIt
			lea	ShutterText2,a0
			lea	ShutterCmd2,a1
			lea	ShutterFlag,a2
			lea	ShutterText3,a3
			lea	Shutter2Cmd2,a4
			bsr	RecordToggle
			bra	Scope

ShutterIt:		bchg	#0,ShutterFlag

			btst	#0,StrobeFlag
			bne.s	.End

			btst	#0,ShutterFlag
			bne.s	.Skip
			bsr	ParShutterOff
			bra.s	.Skip2

.Skip:			bsr	ParShutterOn
.Skip2:			bsr.s	CheckShutter
.End:			rts

CheckShutter:		tst.b	SoleniodFlag
			beq.s	SetSoundVol

			jsr	ShortDelay
			jsr	ShortDelay

			clr.w	$dff0a8
			clr.w	$dff0b8
			clr.w	$dff0c8
			clr.w	$dff0d8
			rts

SetSoundVol2:		tst.b	SoleniodFlag
			beq.s	SetSoundVol
			rts

SetSoundVol:		tst.b	DrawMode
			beq.s	.Skip3

			tst.b	HiResFlag
			beq.s	.Skip3

			move.w	XHiResSize,d0
			tst.b	UseScrDefFlag
			beq.s	.Skip
			move.w	DefXSize,d0

.Skip:			mulu	XOutSize,d0
			divu	#64,d0
			move.w	d0,$dff0a8

			move.w	YHiResSize,d0
			tst.b	UseScrDefFlag
			beq.s	.Skip2
			move.w	DefYSize,d0

.Skip2:			mulu	YOutSize,d0
			divu	#64,d0
			move.w	d0,$dff0b8
			bra.s	.Skip4

.Skip3:			move.w	XOutSize,$dff0a8
			move.w	YOutSize,$dff0b8

.Skip4:			move.w	YOutSize,$dff0c8
			move.w	XOutSize,$dff0d8
			rts

StandbyRaw:		tst.b	SerialFlag
			bne	Scope

			moveq	#GD_Standby,d0
			jsr	FindGadPtr

			tst.b	StandbyFlag
			beq.s	.On
			jsr	GadOff
			bra.s	Standby

.On:			jsr	GadOn

Standby:		bsr	MoreOff
			bsr	AllOff

			bsr.s	StandbyIt
			lea	StandbyText2,a0
			lea	StandbyCmd2,a1
			lea	StandbyFlag,a2
			lea	StandbyText3,a3
			lea	Standby2Cmd2,a4
			bsr	RecordToggle
			bra	Scope

StandbyIt:		tst.b	LASERfIREFlag		;LASERfIRE?
			beq.s	.LfSkip
			rts

.LfSkip:		jsr	SendUnitID

			bchg	#0,StandbyFlag
			bne.s	.Skip

			move.b	#"T",d0
			bra.s	.Skip2

.Skip:			move.b	#"Y",d0
.Skip2:			jsr	Echo
			rts

FastMoveRaw:		moveq	#GD_FastMove,d0
			jsr	FindGadPtr

			tst.b	FastMoveFlag2
			beq.s	.On
			jsr	GadOff
			bra.s	FastMove

.On:			jsr	GadOn

FastMove:		bsr	MoreOff
			bsr	AllOff

			bchg	#0,FastMoveFlag2
			lea	FastMoveText2,a0
			lea	FastMoveCmd2,a1
			lea	FastMoveFlag2,a2
			lea	FastMoveText3,a3
			lea	FastMove2Cmd2,a4
			bsr.s	RecordToggle
			bra	Scope

StrobeRaw:		moveq	#GD_Strobe,d0
			jsr	FindGadPtr

			btst	#0,StrobeFlag
			beq.s	.On
			jsr	GadOff
			bra.s	Strobe

.On:			jsr	GadOn

Strobe:			bsr	MoreOff
			bsr	AllOff

			bchg	#0,StrobeFlag
			bset	#1,StrobeFlag
			bsr	SetSoundVol

			lea	StrobeText2,a0
			lea	StrobeCmd2,a1
			lea	StrobeFlag,a2
			lea	StrobeText3,a3
			lea	Strobe2Cmd2,a4
			bsr.s	RecordToggle
			bra	Scope

RecordToggle:		btst	#0,(a2)
			bne.s	.Skip
			movea.l	a3,a0
			movea.l	a4,a1

.Skip:			move.l	a0,-(sp)
			move.l	a1,-(sp)
			bsr	RecordUpdate
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0

			move.b	#1,LCFlag
			bsr	RecordMake
			clr.b	LCFlag
			rts

Special:		bsr	MoreOff
			bsr	AllOff

			btst	#0,AutoManFlag
			bne.s	.Off

			btst	#0,PresetMoveFlag
			beq.s	.On

.Off:			bclr	#0,AutoManFlag
			bclr	#0,PresetMoveFlag

			bsr.s	GetAutoManItem
			bclr	#0,12(a0)

			bsr.s	GetPresetMvItem
			bclr	#0,12(a0)
			bsr.s	CheckSpecial
			bra	Scope

.On:			bset	#0,AutoManFlag
			bset	#0,PresetMoveFlag

			bsr.s	GetAutoManItem
			bset	#0,12(a0)

			bsr.s	GetPresetMvItem
			bset	#0,12(a0)
			bsr.s	CheckSpecial
			bra	Scope

CheckSpecial:		move.b	#"*",SpecialText

			btst	#0,AutoManFlag
			bne.s	.Chg

			btst	#0,PresetMoveFlag
			bne.s	.Chg

			move.b	#"-",SpecialText

.Chg:			moveq	#GD_Special,d0
			jsr	FindGadPtr
			jsr	GadChg
			bra	Scope

GetAutoManItem:		moveq	#1,d0
			jsr	GetPrefsItem
			rts

GetPresetMvItem:	moveq	#2,d0
			jsr	GetPrefsItem
			rts

GMorph:			move.b	ShiftFlag,MDTwoFlag

			clr.b	AttachStatus
			clr.b	TriggerFlag
			clr.b	DrawStatus
			bsr	AllOff

			tst.b	DrawMode
			beq	Scope

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	Error16

			bchg	#0,MorphStatus
			beq.s	.On

			lea	StatusBlank,a0
			jsr	PrintStatus2
			bra	Scope

.On:			lea	StatusMorph,a0
			jsr	PrintStatus2
			bra	Scope

GetRate:		move.l	SequenceCountTrigTemp,SequenceCountTrigTemp2

			tst.b	IconifyFlag
			bne	.Special

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenRateWindow
			tst.l	d0
			bne	.Done

			movea.l	RateGadgets,a0
			move.l	Rate,d0
			jsr	SetGadget

			movea.l	RateGadgets,a0
			movea.l	RateWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	UpdateOutput
			bsr	Clock

			tst.b	SlaveFlag
			beq.s	.Next
			jsr	GetByte
			bne.s	.Skip

.Next:			movea.l	RateWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	RateGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0
			beq.s	.Bad

			cmpi.l	#3000,d0
			bls.s	.Skip

.Bad:			jsr	FlashScreen
			bra.s	.NoChange

.Skip:			move.l	d0,Rate

			tst.b	MasterFlag
			beq.s	.NoChange
			jsr	Echo

.NoChange:		jsr	CloseRateWindow
			jsr	OpenMenu

.Exit:			move.l	SequenceCountTrigTemp2,SequenceCountTrigTemp
			sub.l	d0,d0
			rts

.Abort:			jsr	CloseRateWindow
.Done:			jsr	OpenMenu
			move.l	SequenceCountTrigTemp2,SequenceCountTrigTemp
			moveq	#1,d0
			rts

.Special:		tst.b	SlaveFlag
			beq.s	.Exit

.Wait2:			jsr	ShortDelay
			jsr	GetByte
			beq.s	.Wait2

			move.l	d0,Rate
			bra.s	.Exit

GDraw:			move.b	ShiftFlag,MDTwoFlag

			clr.b	AttachStatus
			clr.b	TriggerFlag
			clr.b	MorphStatus
			bsr	AllOff

			bchg	#0,DrawStatus
			beq.s	.On

			lea	StatusBlank,a0
			jsr	PrintStatus2
			bra	Scope

.On:			lea	StatusDrawScreen,a0
			jsr	PrintStatus2
			bra	Scope

Bank0:			bsr	MoreOff2
			bsr	AllOff

			tst.b	Bank
			beq	Scope

			bsr.s	BankOff
			clr.b	Bank
			bsr.s	BankOn
			bra	Scope

BankOff:		sub.l	d0,d0
			move.b	Bank,d0
			move.l	d0,d1
			addi.b	#"0",d0
			lea	Bank0Text,a0
			lsl.l	#1,d1
			adda.w	d1,a0
			move.b	d0,(a0)
			rts

BankOn:			sub.l	d0,d0
			move.b	Bank,d0
			lea	Bank0Text,a0
			lsl.l	#1,d0
			adda.w	d0,a0
			move.b	#"*",(a0)

			lea	Sequence13Filename,a0
			lea	Sequence13Text,a1
			moveq	#31,d1

			sub.l	d0,d0
			move.b	Bank,d0
			beq.s	.Loop

			mulu	#32*41,d0
			adda.w	d0,a0

.Loop:			moveq	#9,d0
			jsr	MoveString7
			adda.w	#41,a0
			adda.w	#10,a1
			dbf	d1,.Loop

			moveq	#GD_Sequence13,d0
			jsr	FindGadPtr
			jsr	RefreshGads
			rts

CheckBank:		sub.l	d1,d1
			move.b	Bank,d1
			beq.s	.End

			move.l	d1,d2
			mulu	#32*8,d2
			adda.w	d2,a0
			adda.w	d2,a1

			mulu	#32*41,d1
			adda.w	d1,a2
.End:			rts

Bank1:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#1,Bank
			beq	Scope

			bsr	BankOff
			move.b	#1,Bank
			bsr	BankOn
			bra	Scope

Bank2:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#2,Bank
			beq	Scope

			bsr	BankOff
			move.b	#2,Bank
			bsr	BankOn
			bra	Scope

Bank3:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#3,Bank
			beq	Scope

			bsr	BankOff
			move.b	#3,Bank
			bsr	BankOn
			bra	Scope

Bank4:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#4,Bank
			beq	Scope

			bsr	BankOff
			move.b	#4,Bank
			bsr	BankOn
			bra	Scope

Bank5:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#5,Bank
			beq	Scope

			bsr	BankOff
			move.b	#5,Bank
			bsr	BankOn
			bra	Scope

Bank6:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#6,Bank
			beq	Scope

			bsr	BankOff
			move.b	#6,Bank
			bsr	BankOn
			bra	Scope

Bank7:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#7,Bank
			beq	Scope

			bsr	BankOff
			move.b	#7,Bank
			bsr	BankOn
			bra	Scope

Bank8:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#8,Bank
			beq	Scope

			bsr	BankOff
			move.b	#8,Bank
			bsr	BankOn
			bra	Scope

Bank9:			bsr	MoreOff2
			bsr	AllOff

			cmpi.b	#9,Bank
			beq	Scope

			bsr	BankOff
			move.b	#9,Bank
			bsr	BankOn
			bra	Scope


;Menu pick routines:

MenuTable:		dc.w	$f800			;Project
			dc.l	Load
			dc.w	$f820
			dc.l	Save
			dc.w	$f840
			dc.l	Delete

			dc.w	$f880
			dc.l	Clear
			dc.w	$f8a0
			dc.l	Record
			dc.w	$f8c0
			dc.l	View
			dc.w	$f8e0
			dc.l	Edit

			dc.w	$f920
			dc.l	Start
			dc.w	$f940
			dc.l	Stop
			dc.w	$f960
			dc.l	Pause

			dc.w	$f9a0
			dc.l	GetConfig
			dc.w	$f9c0
			dc.l	SaveConfig

			dc.w	$fa00
			dc.l	Factory2
			dc.w	$fa20
			dc.l	About
			dc.w	$fa40
			dc.l	Iconify
			dc.w	$fa60
			dc.l	Quit

			dc.w	$f801			;Draw
			dc.l	DrawIt
			dc.w	$f821
			dc.l	Text
			dc.w	$f841
			dc.l	Line
			dc.w	$f861
			dc.l	Arc
			dc.w	$f881
			dc.l	Arc2
			dc.w	$f8a1
			dc.l	Box
			dc.w	$f8c1
			dc.l	Ellipse

			dc.w	$f901
			dc.l	LoadScreen
			dc.w	$f921
			dc.l	MergeScreen
			dc.w	$f941
			dc.l	SaveScreen
			dc.w	$f961
			dc.l	SavePack
			dc.w	$f981
			dc.l	DeleteScreen
			dc.w	$f9c1
			dc.l	SaveILDA
			dc.w	$f9e1
			dc.l	SaveILDAPack
			dc.w	$fa01
			dc.l	AppendILDAPack

			dc.w	$0002			;Points
			dc.l	ShiftAll
			dc.w	$0802
			dc.l	ShiftLast

			dc.w	$0022
			dc.l	RollAll
			dc.w	$0822
			dc.l	RollLast

			dc.w	$0042
			dc.l	ResizeAll
			dc.w	$0842
			dc.l	ResizeLast

			dc.w	$0062
			dc.l	RotateAll
			dc.w	$0862
			dc.l	RotateLast

			dc.w	$0082
			dc.l	FlipXAll
			dc.w	$0882
			dc.l	FlipXLast

			dc.w	$00a2
			dc.l	FlipYAll
			dc.w	$08a2
			dc.l	FlipYLast

			dc.w	$00c2
			dc.l	FlipZAll
			dc.w	$08c2
			dc.l	FlipZLast

			dc.w	$00e2
			dc.l	AddPointsAll
			dc.w	$08e2
			dc.l	AddPointsLast

			dc.w	$0102
			dc.l	SubPointsAll
			dc.w	$0902
			dc.l	SubPointsLast

			dc.w	$0122
			dc.l	SmoothPointsAll
			dc.w	$0922
			dc.l	SmoothPointsLast

			dc.w	$0142
			dc.l	AddWeightAll
			dc.w	$0942
			dc.l	AddWeightLast

			dc.w	$0162
			dc.l	RemFirstAll
			dc.w	$0962
			dc.l	RemFirstLast

			dc.w	$0182
			dc.l	RemLastAll
			dc.w	$0982
			dc.l	RemLastLast

			dc.w	$01a2
			dc.l	BendAll
			dc.w	$09a2
			dc.l	BendLast

			dc.w	$f9c2
			dc.l	InsertPoint
			dc.w	$f9e2
			dc.l	InsertPoint2
			dc.w	$fa02
			dc.l	DeletePoint
			dc.w	$fa22
			dc.l	MovePoint
			dc.w	$fa42
			dc.l	ClearPoints
			dc.w	$fa62
			dc.l	Undo
			dc.w	$fa82
			dc.l	Redo

			dc.w	$f803			;Special
			dc.l	Attach
			dc.w	$f823
			dc.l	Center
			dc.w	$f863
			dc.l	SendObject

			dc.w	$00a3
			dc.l	AllUnits
			dc.w	$08a3
			dc.l	Unit5
			dc.w	$10a3
			dc.l	Unit6
			dc.w	$18a3
			dc.l	Unit7
			dc.w	$20a3
			dc.l	Unit8
			dc.w	$28a3
			dc.l	Unit9

			dc.w	$38a3
			dc.l	Aquarius1
			dc.w	$40a3
			dc.l	Aquarius2
			dc.w	$48a3
			dc.l	Aquarius12

			dc.w	$f8c3
			dc.l	SendXYMove

			dc.w	$0103
			dc.l	Master
			dc.w	$0903
			dc.l	Slave

			dc.w	$f804			;Preferences
			dc.l	AutoMan
			dc.w	$f824
			dc.l	PresetMove
			dc.w	$f844
			dc.l	SeqMove
			dc.w	$f864
			dc.l	HiRes
			dc.w	$f884
			dc.l	AutoRetrace
			dc.w	$f8a4
			dc.l	Filter
			dc.w	$f8c4
			dc.l	MagnifyingGlass
			dc.w	$f8e4
			dc.l	Grid
			dc.w	$f904
			dc.l	ZAxis
			dc.w	$f924
			dc.l	TopView

			dc.w	$f805			;System prefs
			dc.l	BigScreen
			dc.w	$f825
			dc.l	FastScope
			dc.w	$f845
			dc.l	DrawScopeOff
			dc.w	$f865
			dc.l	DrawBetweenPoints
			dc.w	$f885
			dc.l	ShowRotateSpin
			dc.w	$f8a5
			dc.l	ShowPPS
			dc.w	$f8c5
			dc.l	ShowPeriod
			dc.w	$f8e5
			dc.l	DMA
			dc.w	$f905
			dc.l	AutoDMA
			dc.w	$f925
			dc.l	APoints
			dc.w	$f945
			dc.l	AutoPreload
			dc.w	$f965
			dc.l	AutoAttach
			dc.w	$f985
			dc.l	Swap
			dc.w	$f9a5
			dc.l	InvertX
			dc.w	$f9c5
			dc.l	InvertY
			dc.w	$f9e5
			dc.l	SmoothChg
			dc.w	$fa05
			dc.l	NoDrag
			dc.w	$fa25
			dc.l	DirectWrite

			dc.w	$f806			;Settings
			dc.l	SetAutoPoints
			dc.w	$f826
			dc.l	SetPattern
			dc.w	$f846
			dc.l	SetHiResSize
			dc.w	$f866
			dc.l	SetOutputSize

			dc.w	$0086
			dc.l	SetDef1
			dc.w	$0886
			dc.l	SetDef2
			dc.w	$1086
			dc.l	SetDef3
			dc.w	$1886
			dc.l	SetDef4
			dc.w	0


;Project menu:

Load:			bsr	MoreOff
			bsr	AllOff

			lea	Filename,a0
			lea	Dir,a1
			lea	LoadReqText,a2
			jsr	ReqFile
			beq	Error3

			cmpi.b	#1,d0
			beq	Scope

			clr.b	RecordStatus

			lea	StatusLoad,a0
			jsr	PrintStatus

			lea	Filename,a0
			jsr	MakeFileName
			jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	Error4

			movea.l	FileMemPtr,a1		;Screen?
			lea	ScreenString,a0
			jsr	CmpString
			bne	.Screen

			adda.w	#34,a1			;Font?
			lea	FontString,a0
			jsr	CmpString
			bne	.Font

			lea	Filename,a0		;Config?
			movea.l	a0,a1
.Loop:			tst.b	(a1)+
			bne.s	.Loop

			subq.l	#8,a1
			cmpa.l	a0,a1
			blo.s	.Skip

			lea	ConfigString,a0
			jsr	CmpString
			beq.s	.Skip

			lea	Filename,a0
			lea	Filename7,a1
			jsr	MoveString

			bsr	ParShutterOn2
			bsr	CheckShutter
			jsr	ShortDelay
			jsr	CheckCenter
			move.b	#1,FromLoad
			bra	Config2

.Skip:			jsr	FreeSeqMem
			move.l	FileMemPtr,SeqMemPtr
			move.l	FileMemSize,SeqMemSize
			clr.l	FileMemSize

			lea	Filename,a0
			lea	Filename2,a1
			jsr	MoveString

			lea	StatusReady,a0
			jsr	PrintStatus
			bra	Scope

.Screen:		movea.l	FileMemPtr,a0
			bsr	MakeScreen
			jsr	FreeFileMem

			tst.b	DrawMode
			beq	Scope

			lea	Filename,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady2,a0
			jsr	PrintStatus
			bra	Scope

.Font:			lea	Filename,a0
			lea	Filename5,a1
			jsr	MoveString

			bsr	FreeFontMem
			move.l	FileMemPtr,FontPtr
			move.l	FileMemSize,FontSize
			clr.l	FileMemSize

			lea	StatusReady3,a0
			jsr	PrintStatus
			bra	Scope

Save:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq.s	.Error

			lea	Filename2,a0
			lea	Dir,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq	Error3

			cmpi.b	#1,d0
			beq	Scope

			lea	StatusSave,a0
			jsr	PrintStatus

			lea	Filename2,a0
			jsr	MakeFileName

			move.l	SeqMemPtr,FileMemPtr
			move.l	SeqMemSize,FileMemSize
			jsr	SaveFile
			clr.l	FileMemSize

			cmpi.b	#1,d0
			beq	Error5

			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Error:			jsr	FlashScreen
			lea	Error6Text,a0
			jsr	PrintStatus
			bra	Scope

Delete:			bsr	SeqStuffOff
			bsr	AllOff

			lea	Filename2,a0
			lea	Dir,a1
			lea	DeleteReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq	Error3

			cmpi.b	#1,d0
			beq	Scope

			lea	Filename2,a0
			jsr	MakeFileName
			jsr	GetLock
			beq	Scope
			jsr	Unlock

			lea	SureTitle4,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename2,a0
			jsr	MoveString
			subq.l	#1,a1
			move.b	#'"',(a1)+
			move.b	#"?",(a1)+
			clr.b	(a1)

			lea	SureText4,a1
			lea	DeleteText,a2
			jsr	Requester
			beq	Scope

			lea	StatusDelete,a0
			jsr	PrintStatus

			lea	Filename2,a0
			jsr	MakeFileName
			jsr	DeleteFile

			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

Clear:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			jsr	FreeSeqMem

			lea	DefaultFilename,a0
			lea	Filename2,a1
			jsr	MoveString

			lea	StatusClear,a0
			jsr	PrintStatus
			bra	Scope

Record:			bsr	MoreOff
			bsr	AllOff

			tst.b	RecordStatus
			beq.s	.Start

			bsr.s	RecordUpdate
			clr.b	RecordStatus

			lea	StatusBlank,a0
			jsr	PrintStatus
			bra	Scope

.Start:			move.b	#1,RecordStatus

			tst.l	SeqMemSize
			beq.s	.Skip

			clr.b	ForceRecMove
			lea	StatusRecord2,a0
			jsr	PrintStatus
			bra	Scope

.Skip:			move.b	#1,ForceRecMove
			lea	StatusRecord,a0
			jsr	PrintStatus
			bra	Scope

RecordUpdate:		cmpi.b	#2,RecordStatus
			bne.s	.End

			move.l	SequenceCountTrigTemp,d0
			move.l	#-1,SequenceCountTrigTemp

			tst.l	d0
			bmi.s	.Skip
			bne.s	.Skip2

.Skip:			moveq	#1,d0

.Skip2:			movea.l	RecordBuffPtr,a0
			jsr	HEXtoASCII

			suba.l	#RecordBuff,a1
			move.l	a1,BufferSize
			move.l	#RecordBuff,RecAddPtr
			bsr.s	RecordAdd
.End:			rts

RecordAdd:		move.l	SeqMemSize,d0
			beq.s	.Create

			add.l	BufferSize,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	Error3

			move.l	d0,-(sp)

			movea.l	d0,a1			;Copy mem
			movea.l	SeqMemPtr,a0
			move.l	SeqMemSize,d0
			jsr	MoveMemBlock

.CopyBuff:		movea.l	RecAddPtr,a0
			movea.l	(sp),a1
			adda.l	SeqMemSize,a1
			move.l	BufferSize,d0

			tst.b	AddLfFlag
			beq.s	.Skip

			move.b	#$a,(a1)+
			move.b	#$a,(a1)+
			subq.l	#2,d0

.Skip:			subq.l	#1,d0

.Loop2:			move.b	(a0)+,(a1)+
			dbf	d0,.Loop2

			move.l	SeqMemSize,-(sp)
			jsr	FreeSeqMem

			move.l	(sp)+,d0
			add.l	BufferSize,d0
			move.l	d0,SeqMemSize
			move.l	(sp)+,SeqMemPtr
			rts

.Create:		move.l	BufferSize,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	Error3

			move.l	d0,-(sp)
			bra.s	.CopyBuff

RecordMake:		move.b	RecordStatus,d0
			beq	.End

			move.l	a0,-(sp)
			move.l	a1,-(sp)

			cmpi.b	#2,d0
			beq.s	.Skip

			move.l	#-1,SequenceCountTrigTemp

.Skip:			lea	RecordBuff,a1

			tst.b	MoveStatus3
			bne	.Move2

			lea	EchoCmd2,a0		;Echo " "

			tst.l	SeqMemSize
			bne.s	.Skip2

			addq.l	#2,a0

.Skip2:			jsr	MoveString
			subq.l	#1,a1
			movea.l	4(sp),a0
			jsr	MoveString
			subq.l	#1,a1
			move.b	#'"',(a1)+

			tst.b	ForceRecMove
			bne.s	.Move

			move.w	XPos,d0			;Move?
			cmp.w	XPosTemp,d0
			bne.s	.Move

			move.w	YPos,d0
			cmp.w	YPosTemp,d0
			bne.s	.Move

.Skip3:			tst.b	MoveStatus3
			bne.s	.Skip5

			tst.b	LCFlag			;Want "LC"?
			bne.s	.Skip4

			movea.l	(sp),a0			;Location?
			cmpi.b	#"L",(a0)
			beq.s	.Skip5

			lea	LCCmd2,a0		;LC
			jsr	MoveString
			subq.l	#1,a1

.Skip4:			movea.l	(sp),a0
			jsr	MoveString
			subq.l	#1,a1

.Skip5:			lea	WaitCmd2,a0		;Wait
			jsr	MoveString
			subq.l	#1,a1
			move.l	a1,RecordBuffPtr

			move.b	#2,RecordStatus

			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
.End:			rts

.Move:			lea	MoveCmd2+1,a0
			bra.s	.Move3

.Move2:			lea	MoveCmd2,a0

			tst.l	SeqMemSize
			bne.s	.Move3

			addq.l	#2,a0

.Move3:			jsr	MoveString
			subq.l	#1,a1

			movea.l	a1,a0
			sub.l	d0,d0
			move.w	XPosTemp,d0
			jsr	HEXtoASCII

			movea.l	a1,a0
			move.b	#" ",(a0)+
			sub.l	d0,d0
			move.w	YPosTemp,d0
			jsr	HEXtoASCII

			move.b	#" ",(a1)+

			tst.b	ForceRecMove
			bne.s	.Skip6

			tst.b	FastMoveFlag
			bne.s	.Skip6

			tst.b	FastMoveFlag2
			bne.s	.Skip6

			movea.l	a1,a0
			sub.l	d0,d0
			move.b	PresetSpeed,d0
			jsr	HEXtoASCII
			bra	.Skip3

.Skip6:			move.b	#"0",(a1)+
			clr.b	ForceRecMove
			bra	.Skip3

View:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			lea	Filename2,a0
			lea	ViewWTitle+16,a1
			jsr	MoveString
			move.b	#'"',-1(a1)
			clr.b	(a1)

			jsr	ClearMenu

			move.w	#400,ViewHeight

			tst.b	BigScreenFlag
			bne.s	.BSkip

			move.w	#256,ViewHeight

.BSkip:			sub.l	d0,d0
			jsr	OpenViewWindow
			tst.l	d0
			bne.s	.Done

			movea.l	ViewGadgets,a0
			move.l	#.PageUp,40(a0)
			move.l	(a0),a0
			move.l	#.PageDn,40(a0)

			move.l	SeqMemPtr,ViewMemPtr

			bsr	MakeText
			bra.s	.Next

.Wait:			bsr	Clock
			jsr	ShortDelay

.Next:			movea.l	ViewWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#6,d2			;Gadget up?
			bne.s	.GadUp

			btst	#9,d2			;Close gad?
			bne.s	.Close
			bra.s	.Next

.GadUp:			movea.l	d3,a0
			tst.l	40(a0)
			beq.s	.Next

			movea.l	40(a0),a6
			jmp	(a6)

.Close:			jsr	CloseViewWindow

.Done:			jsr	OpenMenu
			bra	Scope

.PageUp:		movea.l	ViewMemPtr,a0
			movea.l	SeqMemPtr,a1
			cmpa.l	a0,a1
			beq.s	.Whoops

			sub.l	d0,d0

.Next2:			sub.l	d1,d1

.Loop:			cmpa.l	a0,a1
			bhs.s	.Found

			move.b	-(a0),d2
			cmpi.b	#$a,d2
			beq.s	.eol

			cmpi.b	#$20,d2
			blo.s	.Loop
			cmpi.b	#$7e,d2
			bhi.s	.Loop

			addq.l	#1,d1
			cmpi.l	#76,d1
			bne.s	.Loop

.eol:			addq.l	#1,d0

			tst.b	BigScreenFlag
			bne.s	.Skip

			cmpi.w	#31,d0
			bne.s	.Next2
			bra.s	.Found

.Skip:			cmpi.w	#47,d0
			bne.s	.Next2

.Found:			cmpa.l	a0,a1
			beq.s	.Skip2

			cmpi.b	#$a,(a0)
			bne.s	.Skip2
			addq.l	#1,a0

.Skip2:			move.l	a0,ViewMemPtr
			bsr.s	MakeText
			bra	.Next

.PageDn:		tst.l	ViewMemPtr2
			beq.s	.Whoops
			move.l	ViewMemPtr2,ViewMemPtr
			bsr.s	MakeText
			bra	.Next

.Whoops:		jsr	FlashScreen
			bra	.Next

MakeText:		sub.l	d0,d0			;Blank
			movea.l	ViewWnd,a0
			movea.l	50(a0),a1
			movea.l	GfxBase,a6
			jsr	_LVOSetAPen(a6)

			movea.l	ViewWnd,a0
			movea.l	50(a0),a1
			moveq	#5,d0
			moveq	#12,d1
			move.l	#618,d2
			move.l	#250,d3
			tst.b	BigScreenFlag
			beq.s	.BSkip
			move.l	#378,d3
.BSkip:			movea.l	GfxBase,a6
			jsr	_LVORectFill(a6)

			movea.l	SeqMemPtr,a0
			movea.l	a0,a1
			adda.l	SeqMemSize,a1
			movea.l	ViewMemPtr,a0
			moveq	#1,d0

.Next:			lea	ViewIText0,a2

.Loop:			move.b	(a0)+,d1
			cmpi.b	#$a,d1
			beq.s	.eol
			cmpi.b	#$20,d1
			blo.s	.Skip
			cmpi.b	#$7e,d1
			bhi.s	.Skip
			move.b	d1,(a2)+
.Skip:			cmpa.l	a0,a1
			bls.s	.eol
			cmpa.l	#ViewIText0+76,a2
			bne.s	.Loop

.eol:			clr.b	(a2)

			move.l	d0,-(sp)
			move.l	a0,-(sp)
			move.l	a1,-(sp)

			lea	ViewText0,a1
			movea.l	ViewWnd,a0
			movea.l	50(a0),a0
			moveq	#10,d1
			add.l	d0,d1
			sub.l	d0,d0
			movea.l	IntBase,a6
			jsr	_LVOPrintIText(a6)

			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			move.l	(sp)+,d0

			cmpa.l	a0,a1
			bhi.s	.Skip2

			clr.l	ViewMemPtr2
			rts

.Skip2:			addi.w	#8,d0

			tst.b	BigScreenFlag
			bne.s	.Skip3

			cmpi.w	#241,d0
			bne.s	.Next
			move.l	a0,ViewMemPtr2
			rts

.Skip3:			cmpi.w	#369,d0
			bne	.Next
			move.l	a0,ViewMemPtr2
			rts

Edit:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			lea	EditFilename,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString

			move.l	SeqMemPtr,FileMemPtr
			move.l	SeqMemSize,FileMemSize
			jsr	SaveFile
			clr.l	FileMemSize

			cmpi.b	#1,d0
			beq	Error3

			move.b	#1,FromConfig
			bsr	Iconify
			clr.b	FromConfig

			lea	EditFilename2,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString

			move.l	#1006,d2
			jsr	OpenFile2
			beq.s	.Error

			move.l	d0,d3

			move.l	#EditCmd,d1
			sub.l	d2,d2
			movea.l	DosBase,a6
			jsr	_LVOExecute(a6)

			jsr	CloseFile
			jsr	DeleteFile

.Error:			move.b	#1,FromConfig
			bsr	Iconify
			clr.b	FromConfig

			lea	EditFilename,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	Error4

			jsr	FreeSeqMem
			move.l	FileMemPtr,SeqMemPtr
			move.l	FileMemSize,SeqMemSize
			clr.l	FileMemSize

			jsr	DeleteFile

			lea	StatusWelcome,a0
			jsr	PrintStatus
			bra	Scope

Start:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			jsr	LASERfIRE

			move.b	#1,PlayStatus
			move.l	#-1,WaitCount

Start2:			clr.b	MoveStatus
			clr.b	WaitMoveFlag
			clr.b	MoveStatus2
			clr.b	FromLASERfIRE
			clr.l	AutoStopCount
			clr.l	NextCount
			clr.l	ReplayPtr2

			move.l	SeqMemPtr,ReplayPtr

			lea	Filename2,a0
			lea	StatusStart+9,a1
			moveq	#20,d0
			jsr	MoveString6
			lea	StatusStart,a0
			jsr	PrintStatus2

Replay:			movea.l	ReplayPtr,a1
Replay2:		movea.l	SeqMemPtr,a2
			adda.l	SeqMemSize,a2

			move.l	a1,SequencePtr
			move.l	a2,SequenceEnd

			cmpi.l	#600,AutoStopCount
			bhi	AutoStop

			tst.b	AutoPreloadFlag
			bne	APreload

Play:			movea.l	SequencePtr,a1
			movea.l	SequenceEnd,a2

			cmpa.l	SeqMemPtr,a1		;First?
			beq.s	.Skip

.Loop:			cmpi.b	#$a,(a1)+		;Find next
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop
			bra.s	Replay

.SkipLFSP:		addq.l	#1,a1
.Skip:			cmpa.l	a1,a2
			bls.s	Replay
			cmpi.b	#$a,(a1)
			beq.s	.SkipLFSP
			cmpi.b	#" ",(a1)
			beq.s	.SkipLFSP

ProcessCmd:		cmpi.b	#";",(a1)
			beq	.Comment

			lea	MoveCmd,a0
			jsr	CmpString
			bne	.Move

			lea	LCCmd,a0
			jsr	CmpString
			bne	.LC

			lea	EchoCmd,a0
			jsr	CmpString
			bne	.Echo

			lea	ScreenCmd,a0
			jsr	CmpString
			bne	.Screen

			lea	ScreenCmd2,a0
			jsr	CmpString
			bne	.Screen2

			lea	DrawScreenCmd,a0
			jsr	CmpString
			bne	.DrawScreen

			lea	DrawScreenCmd2,a0
			jsr	CmpString
			bne	.DrawScreen2

			tst.b	LASERfIREFlag
			beq	.LfSkip

			lea	SetTrackCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	SizeXCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	SizeYCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	RotateXYCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	SpinXCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	SpinYCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	RollXCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	RollYCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	WaitASCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	FactoryLfCmd,a0
			jsr	CmpString
			bne	.Comment

			lea	FactoryLfCmd2,a0
			jsr	CmpString
			bne	.Comment

			lea	DisolveScreenCmd,a0
			jsr	CmpString
			bne	.DisScreen

			lea	DisolveScreenCmd2,a0
			jsr	CmpString
			bne	.DisScreen2

.LfSkip:		lea	MorphScreenCmd,a0
			jsr	CmpString
			bne	.MorphScreen

			lea	MorphScreenCmd2,a0
			jsr	CmpString
			bne	.MorphScreen2

			lea	PreloadCmd,a0
			jsr	CmpString
			bne	Preload

			lea	LoadPackCmd,a0
			jsr	CmpString
			bne	LoadPack

			lea	ShutterCmd,a0
			jsr	CmpString
			bne	.Shutter

			lea	Shutter2Cmd,a0
			jsr	CmpString
			bne	.Shutter2

			lea	StandbyCmd,a0
			jsr	CmpString
			bne	.Standby

			lea	Standby2Cmd,a0
			jsr	CmpString
			bne	.Standby2

			lea	FastMoveCmd,a0
			jsr	CmpString
			bne	.FastMove

			lea	FastMove2Cmd,a0
			jsr	CmpString
			bne	.FastMove2

			lea	StrobeCmd,a0
			jsr	CmpString
			bne	.Strobe

			lea	Strobe2Cmd,a0
			jsr	CmpString
			bne	.Strobe2

			lea	ReplayCmd,a0
			jsr	CmpString
			bne	.Replay

			lea	NextCmd,a0
			jsr	CmpString
			bne	.Next

			lea	UnitCmd,a0
			jsr	CmpString
			bne	.Unit

			lea	ColourCmd,a0
			jsr	CmpString
			bne	.Colour

			lea	FXCmd,a0
			jsr	CmpString
			bne	.FX

			lea	SerialCmd,a0
			jsr	CmpString
			bne	.Serial

			lea	PresetCmd2,a0
			jsr	CmpString
			bne	.Preset

			lea	UseDefCmd,a0
			jsr	CmpString
			bne	.DefCmd

			lea	SmoothChgCmd2,a0
			jsr	CmpString
			bne	.SmoothCmd

			lea	WaitCmd,a0
			jsr	CmpString
			bne	.Wait

			lea	WaitMoveCmd,a0
			jsr	CmpString
			bne	.WaitMove

			lea	StopCmd,a0
			jsr	CmpString
			bne	Stop
			bra	Error

.Comment:		addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr
			bra	Play

.Move:			tst.b	MoveStatus		;Moving?
			bne	Scope2

			adda.w	#5,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.Loop4:			move.b	(a1)+,d0
			cmpi.b	#" ",d0
			beq.s	.Skip5
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop4
			bra	Error2

.Skip5:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			jsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi	Error

			cmpi.l	#XMax,d0
			bhi	Error2

			tst.b	SeqMoveFlag
			beq.s	.DSkip

			cmp.w	XPosTemp,d0
			beq.s	.DSkip

			move.b	#1,MoveStatus2		;Print pos
			move.w	d0,XPosTemp

.DSkip:			lea	ASCIIBuffer,a0

.Loop5:			move.b	(a1)+,d0
			cmpi.b	#" ",d0
			beq.s	.Skip6
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop5
			bra	Error2

.Skip6:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			jsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi	Error

			cmpi.l	#YMax,d0
			bhi	Error2

			tst.b	SeqMoveFlag
			beq.s	.DSkip2

			cmp.w	YPosTemp,d0
			beq.s	.DSkip2

			move.b	#1,MoveStatus2		;Print pos
			move.w	d0,YPosTemp

.DSkip2:		lea	ASCIIBuffer,a0

.Loop6:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip7
			cmpi.b	#" ",d0
			beq.s	.Skip7
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip7
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop6
			bra	Error2

.Skip7:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error

			cmpi.l	#3000,d0
			bhi	Error2

			tst.b	SeqMoveFlag
			beq	Scope2

			move.l	d0,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus
			bra	Play

.LC:			adda.w	#3,a1
			cmpa.l	a1,a2
			bls	Error

			cmpi.b	#'"',(a1)
			bne.s	.QSkip

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

.QSkip:			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.Loop			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip
			cmpi.b	#'"',d0
			beq.s	.Skip
			jsr	UpperByte
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop
			bra	Error

.Skip:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			bra	GetCommand

.Echo:			adda.w	#6,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.Loop2:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip2
			cmpi.b	#$a,d0
			beq.s	.Skip2
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip2
			cmpa.l	#ASCIIBuffer+23,a0
			blo.s	.Loop2

.Skip2:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	PrintStatus2
			bra	Play

.DisScreen2:		addq.l	#4,a1
			bra.s	.Screen2

.DisScreen:		addq.l	#4,a1
			bra.s	.Screen

.Screen2:		addq.l	#1,a1
			move.b	#1,Preserve

.Screen:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	Error

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

			jsr	CheckPreload
			beq.s	.PSkip

			cmpi.b	#2,d0
			beq	Error3
			bra.s	.PSkip2

.PSkip:			jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq.s	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			jsr	CmpString
			beq.s	.Error3

.PSkip2:		movea.l	FileMemPtr,a0
			bsr	MakeScreen
			jsr	FreeFileMem
			bsr	GetScrnFilename
			bra	Play

.Error2:		jsr	FlashScreen
			lea	Error18Text,a0
			jsr	PrintStatus
			bra	Scope

.Error3:		jsr	FreeFileMem
			bra	Error17

.DrawScreen2:		addq.l	#1,a1
			move.b	#1,Preserve

.DrawScreen:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.DSLoop:		move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.DSSkip
			cmpi.b	#$a,d0
			beq.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.DSLoop

.DSSkip:		clr.b	(a0)

			cmpi.b	#" ",(a1)+
			bne	Error

			cmpa.l	a1,a2
			bls	Error

			lea	ValueASCII,a0

.DSLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.DSSkip2
			cmpi.b	#" ",d0
			beq.s	.DSSkip2
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.DSSkip2
			cmpa.l	#ValueASCII+10,a0
			blo.s	.DSLoop2
			bra	Error2

.DSSkip2:		clr.b	(a0)
			lea	ValueASCII,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error
			beq	Error2

			move.l	d0,Rate

			jsr	CheckPreload
			beq.s	.PSkip3

			cmpi.b	#2,d0
			beq	Error3
			bra.s	.PSkip4

.PSkip3:		jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			jsr	CmpString
			beq	.Error3

.PSkip4:		clr.b	MorphFlag
			bsr	FreeMorphMem
			clr.l	DrawCountTemp
			move.l	#1,DrawingLen
			move.b	#1,DrawingFlag
			movea.l	FileMemPtr,a0
			bsr	MakeScreen2
			clr.b	DrawingFlag
			jsr	FreeFileMem
			bsr	GetScrnFilename

			tst.b	DrawMode
			beq	Play

			move.l	Rate,d0
			movea.l	FileMemPtr,a0
			move.l	46(a0),d1
			bsr	CalcDrawRate
			clr.l	DrawCountTemp
			move.b	#1,DrawingFlag
			bra	Play

.MorphScreen2:		addq.l	#1,a1
			move.b	#1,Preserve

.MorphScreen:		adda.w	#13,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr
			lea	ASCIIBuffer,a0

.MSLoop:		move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.MSSkip
			cmpi.b	#$a,d0
			beq.l	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.MSLoop

.MSSkip:		clr.b	(a0)

			cmpi.b	#" ",(a1)+
			bne	Error

			cmpa.l	a1,a2
			bls	Error

			lea	ValueASCII,a0

.MSLoop2:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.MSSkip2
			cmpi.b	#" ",d0
			beq.s	.MSSkip2
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.MSSkip2
			cmpa.l	#ValueASCII+10,a0
			blo.s	.MSLoop2
			bra	Error2

.MSSkip2:		clr.b	(a0)
			lea	ValueASCII,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error
			beq	Error2

			bsr	CalcMorphRate

			jsr	CheckPreload
			beq.s	.PSkip5

			cmpi.b	#2,d0
			beq	Error3
			bra.s	.PSkip6

.PSkip5:		jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	ScreenString,a0
			jsr	CmpString
			beq	.Error3

.PSkip6:		clr.b	MorphFlag		;Stop updates

			tst.b	DrawMode
			beq.s	.MSSkip3

			bsr	FreeMorphMem
			move.l	DrawMemPtr,MorphMemPtr
			move.l	Len0,MorphLen
			move.b	D3Flag,MorphD3Flag

			bsr	GetDrawMem
			beq.s	.MSError

			clr.l	MorphCountTemp
			clr.l	MorphStepsTemp
			move.b	#1,MorphFlag		;Start updates

.MSSkip3:		clr.b	DrawingFlag
			movea.l	FileMemPtr,a0
			bsr	MakeScreen2
			jsr	FreeFileMem
			bsr	GetScrnFilename
			bra	Play

.MSError:		clr.b	DrawMode
			bsr	GetDrawModeItem
			bclr	#0,12(a0)
			bsr	DrawOff
			jsr	FreeFileMem
			bra	Error3

.Shutter:		adda.w	#8,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,ShutterFlag
			bne	Play

			tst.b	LASERfIREFlag
			bne	Play

			moveq	#GD_Shutter,d0
			jsr	FindGadPtr
			jsr	GadOn

.ShutterIt:		bsr	ShutterIt
			bra	Play

.Shutter2:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,ShutterFlag
			beq	Play

			tst.b	LASERfIREFlag
			bne	Play

			moveq	#GD_Shutter,d0
			jsr	FindGadPtr
			jsr	GadOff
			bra.s	.ShutterIt

.Standby:		adda.w	#8,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,StandbyFlag
			bne	Play

			moveq	#GD_Standby,d0
			jsr	FindGadPtr
			jsr	GadOn

.StandbyIt:		bsr	StandbyIt
			bra	Play

.Standby2:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,StandbyFlag
			beq	Play

			moveq	#GD_Standby,d0
			jsr	FindGadPtr
			jsr	GadOff
			bra.s	.StandbyIt

.FastMove:		adda.w	#9,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,FastMoveFlag2
			bne	Play

			moveq	#GD_FastMove,d0
			jsr	FindGadPtr
			jsr	GadOn

.FastMoveIt:		bchg	#0,FastMoveFlag2
			bra	Play

.FastMove2:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,FastMoveFlag2
			beq	Play

			moveq	#GD_FastMove,d0
			jsr	FindGadPtr
			Jsr	GadOff
			bra.s	.FastMoveIt

.Strobe:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,StrobeFlag
			bne	Play

			moveq	#GD_Strobe,d0
			jsr	FindGadPtr
			jsr	GadOn

.StrobeIt:		bchg	#0,StrobeFlag
			bset	#1,StrobeFlag
			bra	Play

.Strobe2:		adda.w	#8,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			btst	#0,StrobeFlag
			beq		Play

			moveq	#GD_Strobe,d0
			jsr	FindGadPtr
			jsr	GadOff
			bra.s	.StrobeIt

.Replay:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			cmpi.b	#" ",(a1)
			bne	.RSkip2

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

			lea	ASCIIBuffer,a0

.RLoop:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.RSkip
			cmpi.b	#" ",d0
			beq.s	.RSkip
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.RLoop
			bra	Error2

.RSkip:			subq.l	#1,a1
			clr.b	(a0)
			lea	ASCIIBuffer,a0
			move.l	a1,-(sp)
			jsr	ASCIItoHEX
			movea.l	(sp)+,a1
			tst.l	d0
			bmi	Error

			cmpi.l	#1,d0
			bls	Error2

			cmpi.l	#$ffff,d0
			bhi	Error2

			subq.l	#1,d0
			move.l	d0,NextCount
			move.l	a1,ReplayPtr2
			bra	Play

.RSkip2:		clr.l	NextCount
			clr.l	ReplayPtr2

			move.l	a1,ReplayPtr
			bra	Play

.Next:			adda.w	#4,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			tst.l	NextCount
			beq	Play

			tst.l	ReplayPtr2
			beq	Play

			subq.l	#1,NextCount
			movea.l	ReplayPtr2,a1
			bra	Replay2

.Unit:			adda.w	#11,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			move.b	(a1),d0
			cmpi.b	#"0",d0
			bne.s	.USkip

			clr.b	UnitNumber
			bra.s	.USkip2

.USkip:			cmpi.b	#"5",d0
			blo	Error2

			cmpi.b	#"9",d0
			bhi	Error2

			move.b	d0,UnitNumber

.USkip2:		jsr	SetMenus2
			bra	Play

.Colour:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.CLoop:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.CSkip
			cmpi.b	#" ",d0
			beq.s	.CSkip
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.CSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.CLoop
			bra	Error2

.CSkip:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error

			cmpi.l	#63,d0
			bhi	Error2

			move.b	ParPort,d1
			move.b	d1,d2
			andi.b	#$80,d1
			not.b	d0
			andi.b	#$3f,d0
			or.b	d1,d0
			bclr	#6,d2
			move.b	d0,ParPort

			move.b	#$ff,$bfe301		;ddrb output
			move.b	d2,$bfe101		;Set bit first
			move.b	ParPort,$bfe101
			bra	Play

.FX:			adda.w	#3,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.FXLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.FXSkip
			cmpi.b	#" ",d0
			beq.s	.FXSkip
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.FXSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.FXLoop
			bra	Error2

.FXSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error

			cmpi.l	#63,d0
			bhi	Error2

			move.b	ParPort,d1
			move.b	d1,d2
			andi.b	#$80,d1
			not.b	d0
			andi.b	#$3f,d0
			or.b	d1,d0
			bset	#6,d0
			bset	#6,d2
			move.b	d0,ParPort

			move.b	#$ff,$bfe301		;ddrb output
			move.b	d2,$bfe101
			move.b	ParPort,$bfe101
			bra	Play

.Serial:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			tst.b	SerialFlag
			bne	Play

.SerNext:		lea	ASCIIBuffer,a0

.SerLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.SerSkip
			cmpi.b	#" ",d0
			beq.s	.SerSkip
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.SerSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.SerLoop
			bra	Error2

.SerSkip:		subq.l	#1,a1
			move.l	a1,SequencePtr

			clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error

			cmpi.l	#255,d0
			bhi	Error2
			jsr	Echo

			movea.l	SequencePtr,a1
			cmpi.b	#" ",(a1)+
			bne	Play

			cmpi.b	#"0",(a1)
			blo	Play
			cmpi.b	#"9",(a1)
			bhi	Play
			bra	.SerNext

.Preset:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			lea	ASCIIBuffer,a0

.PreLoop:		move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.PreSkip
			cmpi.b	#" ",d0
			beq.s	.PreSkip
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.PreSkip
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.PreLoop
			bra	Error2

.PreSkip:		clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error

			subq.l	#1,d0
			cmpi.l	#39,d0
			bhi	Error2

			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6
			move.b	#1,FromPlay
			jmp	(a6)

.DefCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			sub.l	d0,d0
			move.b	(a1),d0
			cmpi.b	#"1",d0
			blo	Error2
			cmpi.b	#"4",d0
			bhi	Error2

			subi.b	#"1",d0
			lea	ScrDef1,a0

			mulu	#8,d0
			adda.l	d0,a0

			move.w	(a0),DefXSize
			move.w	2(a0),DefYSize
			move.w	4(a0),d0
			move.w	6(a0),d1

			cmp.w	XPosTemp,d0
			beq.s	.DefSkip
			move.b	#1,MoveStatus2		;Print pos
			move.w	d0,XPosTemp

.DefSkip:		cmp.w	YPosTemp,d1
			beq.s	.DefSkip2
			move.b	#1,MoveStatus2		;Print pos
			move.w	d1,YPosTemp

.DefSkip2:		sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus
			move.b	#1,UseScrDefFlag
			bra	Play

.SmoothCmd:		adda.w	#12,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			move.b	#1,SmoothChgFlag2
			bra	Play

.Wait:			adda.w	#5,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			cmpi.b	#2,PlayStatus		;Trigger?
			bne.s	.Skip3

			move.l	SequenceCountTrig,WaitCount
			jmp	Scope2

.Skip3:			lea	ASCIIBuffer,a0

.Loop3:			move.b	(a1)+,d0
			cmpi.b	#$a,d0
			beq.s	.Skip4
			cmpi.b	#" ",d0
			beq.s	.Skip4
			cmpi.b	#"0",d0
			blo	Error
			cmpi.b	#"9",d0
			bhi	Error
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip4
			cmpa.l	#ASCIIBuffer+10,a0
			blo.s	.Loop3
			bra	Error2

.Skip4:			clr.b	(a0)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			bmi	Error
			beq	Error2

			subq.l	#1,d0
			move.l	d0,WaitCount
			jmp	Scope2

.WaitMove:		adda.w	#7,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			tst.b	MoveStatus
			beq	Play

			move.b	#1,WaitMoveFlag
			jmp	Scope2

Preload:		adda.w	#6,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

APreload:		tst.b	PreloadFlag
			beq.s	.LfSkip

			tst.b	FromLASERfIRE
			bne.l	LfPlay
			bra	Play

.LfSkip:		move.b	#1,PreloadFlag

.Loop:			move.b	(a1)+,d0
			cmpi.b	#"S",d0
			beq.s	.Skip
			cmpi.b	#"s",d0
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop

			tst.b	FromLASERfIRE
			bne.l	LfPlay2
			bra	Play

.Skip:			lea	PreloadCmd2,a0
			jsr	CmpString
			beq.s	.Loop

			adda.w	#5,a1
			cmpa.l	a1,a2
			bls	Error

			cmpi.b	#"2",(a1)
			bne.s	.Skip2

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

.Skip2:			cmpi.b	#" ",(a1)
			bne.s	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

			cmpi.b	#'"',(a1)
			bne.s	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls	Error

			lea	ASCIIBuffer,a0

.Loop2:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip3
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip3
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop2

.Skip3:			clr.b	(a0)

			move.l	a1,PreloadPtr2
			move.l	a2,PreloadPtr3

			move.b	#1,CheckOnlyFlag
			jsr	CheckPreload
			clr.b	CheckOnlyFlag
			tst.l	d0
			bne	.Skip4

			move.b	#1,AddMemFlag
			jsr	LoadFile
			clr.b	AddMemFlag
			cmpi.b	#1,d0
			beq	Error3
			cmpi.b	#2,d0
			beq.s	.Error2

			movea.l	FileMemPtr,a1
			adda.w	#50,a1
			lea	ScreenString,a0
			jsr	CmpString
			beq	.Error3

			movea.l	FileMemPtr,a0
			move.l	PreloadPtr,(a0)
			move.l	FileMemSize,4(a0)
			move.l	a0,PreloadPtr
			clr.l	FileMemSize

			movea.l	PreloadPtr,a1
			addq.l	#8,a1
			move.l	a1,-(sp)
			bsr	GetScrnFilename2

			move.l	(sp),a0
			lea	StatusPreload+9,a1
			moveq	#20,d0
			jsr	MoveString6
			lea	StatusPreload,a0
			jsr	PrintStatus2

			movea.l	(sp)+,a0
			movea.l	a0,a1
			jsr	UpperString

.Skip4:			movea.l	PreloadPtr2,a1
			movea.l	PreloadPtr3,a2
			bra	.Loop

.Error2:		movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error18Text,a0
			jsr	PrintStatus
			jmp	Scope

.Error3:		jsr	FreeFileMem
			bra	Error17

LoadPack:		adda.w	#10,a1
			cmpa.l	a1,a2
			bls	Error

			move.l	a1,SequencePtr

			tst.b	PreloadFlag
			beq.s	.LfSkip

			tst.b	FromLASERfIRE
			bne.l	LfPlay
			bra	Play

.LfSkip:		move.b	#1,PreloadFlag

			lea	ASCIIBuffer,a0

.Loop:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls	Error
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop

.Skip:			clr.b	(a0)

			lea	StatusLoadPack,a0
			jsr	PrintStatus2

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1
			lea	PackString,a0
			jsr	CmpString
			beq	.Error3

			move.w	20(a1),PackCount3
			adda.w	#22,a1
			move.l	a1,PackPtr4

.Loop2:			movea.l	PackPtr4,a1
			adda.w	#42,a1
			movea.l	FileMemPtr,a0
			adda.l	FileMemSize,a0
			cmpa.l	a1,a0
			bls	.Unknown

			lea	ScreenString,a0
			jsr	CmpString
			beq	.Unknown

			movea.l	PackPtr4,a0
			move.l	88(a0),d0
			add.l	92(a0),d0

			btst	#3,65(a0)
			beq.s	.3DSkip
			add.l	88(a0),d0

.3DSkip:		addi.l	#112,d0

			move.l	d0,-(sp)
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	(sp)+,d1
			tst.l	d0
			beq	.Error4

			movea.l	d0,a1
			move.l	PreloadPtr,(a1)
			move.l	d1,4(a1)
			move.l	a1,PreloadPtr
			addq.l	#8,a1

			movea.l	PackPtr4,a0
			move.l	d1,d0
			subq.l	#8,d0
			jsr	MoveMemBlock

			movea.l	PreloadPtr,a0
			addq.l	#8,a0
			movea.l	a0,a1
			jsr	UpperString

			movea.l	PackPtr4,a0
			move.l	88(a0),d0
			add.l	92(a0),d0

			btst	#3,65(a0)
			beq.s	.3DSkip2
			add.l	88(a0),d0

.3DSkip2:		adda.l	d0,a0
			adda.w	#104,a0
			move.l	a0,PackPtr4

			subq.w	#1,PackCount3
			bne	.Loop2

			jsr	FreeFileMem

			tst.b	FromLASERfIRE
			bne.l	LfPlay2
			bra	Play

.Error2:		movea.l	StackPtr,sp
			jsr	FlashScreen
			lea	Error25Text,a0
			jsr	PrintStatus
			jmp	Scope

.Error3:		movea.l	StackPtr,sp
			jsr	FreeFileMem
			lea	Error26Text,a0
			jsr	PrintStatus
			jmp	Scope

.Error4:		jsr	FreeFileMem
			bra	Error3

.Unknown:		jsr	FreeFileMem
			bra	Error17

CalcDrawRate:		moveq	#1,d2
			move.l	d1,d3

.Loop:			move.l	d3,d1
			addq.l	#1,d2
			mulu.w	d2,d1
			divu.l	d0,d1
			beq.s	.Loop

			move.l	d1,DrawRate
			move.l	d2,DrawCount
			rts

CalcMorphRate:		moveq	#1,d2

.Loop:			move.l	#32767,d1
			addq.l	#1,d2
			mulu.w	d2,d1
			divu.l	d0,d1
			beq.s	.Loop

			move.l	d1,MorphSteps
			move.l	d2,MorphCount
			rts

GetScrnFilename:	lea	Filename4,a1
GetScrnFilename2:	lea	ASCIIBuffer,a0
			movea.l	a0,a2

.Loop:			tst.b	(a0)+
			bne.s	.Loop

.Loop2:			move.b	-(a0),d0
			cmpi.b	#"/",d0
			beq.s	.Skip
			cmpi.b	#":",d0
			beq.s	.Skip
			cmpa.l	a0,a2
			bne.s	.Loop2
			bra.s	.Skip2

.Skip:			addq.l	#1,a0
.Skip2:			moveq	#40,d0
			jsr	MoveString6
			rts

AutoStop:		jsr	FlashScreen
			lea	StatusAutoStop,a0
			jsr	PrintStatus
			jmp	Scope

Stop:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			tst.b	PlayStatus
			beq	Error8

			lea	StatusStop,a0
			jsr	PrintStatus
			jmp	Scope

Pause:			bsr	SeqStuffOff
			bsr	AllOff

			tst.l	SeqMemSize
			beq	Error7

			tst.b	PlayStatus
			beq	Error8

			cmpi.b	#3,PlayStatus		;Pause?
			bhs.s	.Start

			addq.b	#2,PlayStatus
			lea	StatusPause,a0
			jsr	PrintStatus2
			jmp	Scope

.Start:			subq.b	#2,PlayStatus
			lea	StatusBlank,a0
			jsr	PrintStatus2
			jmp	Scope

GetConfig:		bsr	MoreOff
			bsr	AllOff

			lea	Filename6,a0
			lea	Dir4,a1
			lea	LoadReqText,a2
			jsr	ReqFile
			beq	Error3

			cmpi.b	#1,d0
			beq.l	Scope

			clr.b	RecordStatus

			lea	StatusLoad,a0
			jsr	PrintStatus

			lea	Filename6,a0
			jsr	MakeFilename3

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	Error3

			cmpi.b	#2,d0
			beq	Error4

			lea	Filename6,a0
			lea	Filename7,a1
			jsr	MoveString

			bsr	ParShutterOn2
			bsr	CheckShutter
			jsr	ShortDelay
			jsr	CheckCenter
			move.b	#1,FromLoad
			jmp	Config2

SaveConfig:		bsr	SeqStuffOff
			bsr	AllOff

			lea	Preset1DrawPtr,a0	;Screens
			lea	Preset1Filename,a1
			sub.l	d0,d0
			moveq	#39,d1

			lea	Dir2,a2
			movea.l	a2,a3

.Loop:			tst.b	(a3)+
			bne.s	.Loop

			suba.l	a2,a3
			adda.w	#10,a3

.Loop2:			tst.l	(a0)
			beq.s	.Skip

			movea.l	a1,a2

.Loop3:			tst.b	(a2)+
			bne.s	.Loop3

			suba.l	a1,a2
			add.l	a2,d0
			add.l	a3,d0

			cmpi.b	#30,d1
			bhi.s	.Skip
			addq.l	#1,d0

.Skip:			adda.w	#8,a0
			adda.w	#41,a1
			dbf	d1,.Loop2

			lea	SeqMemSize1,a0		;Sequences
			lea	Sequence1Filename,a1
			move.l	#331,d1

			lea	Dir,a2
			movea.l	a2,a3

.Loop4:			tst.b	(a3)+
			bne.s	.Loop4

			suba.l	a2,a3
			adda.w	#10,a3

.Loop5:			tst.l	(a0)
			beq.s	.ASkip

			movea.l	a1,a2

.Loop6:			tst.b	(a2)+
			bne.s	.Loop6

			suba.l	a1,a2
			add.l	a2,d0
			add.l	a3,d0

			cmpi.w	#322,d1
			bhi.s	.Skip2
			addq.l	#1,d0

.Skip2:			cmpi.w	#232,d1
			bhi.s	.ASkip
			addq.l	#1,d0

.ASkip:			adda.w	#8,a0
			adda.w	#41,a1
			dbf	d1,.Loop5

			lea	Preset1Cmd,a0		;Presets
			lea	Preset1CmdText,a1
			lea	PresetGadTable,a2
			lea	PresetPos1,a3
			lea	PresetSpeed1,a4

			moveq	#39,d1

.PNext:			movea.l	a0,a5

.PLoop:			tst.b	(a5)+
			bne.s	.PLoop

			suba.l	a0,a5
			add.l	a5,d0
			addi.l	#23,d0

			cmpi.b	#30,d1
			bhi.s	.PSkip
			addq.l	#1,d0

.PSkip:			movea.l	a1,a5

.PLoop2:		tst.b	(a5)+
			bne.s	.PLoop2

			suba.l	a1,a5
			add.l	a5,d0

			movea.l	(a2),a5

.PLoop3:		tst.b	(a5)+
			bne.s	.PLoop3

			suba.l	(a2),a5
			add.l	a5,d0

			move.w	(a3)+,d2
			bsr	.AddNumber

			move.w	(a3)+,d2
			bsr	.AddNumber

			sub.l	d2,d2
			move.b	(a4)+,d2
			bsr	.AddNumber

			adda.w	#120,a0
			adda.w	#24,a1
			addq.l	#6,a2
			dbf	d1,.PNext

			move.l	d0,FileMemSize2

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FileMemPtr
			beq	Error3

			move.l	FileMemSize2,FileMemSize

			lea	Filename7,a0
			lea	Dir4,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq	.Error

			cmpi.b	#1,d0
			beq	.Scope

			lea	StatusSave4,a0
			jsr	PrintStatus

			movea.l	FileMemPtr,a1		;Make file

			lea	Preset1Cmd,a2		;Presets
			lea	Preset1CmdText,a3
			lea	PresetGadTable,a4
			lea	PresetPos1,a5
			lea	PresetSpeed1,a6
			moveq	#1,d0
			moveq	#39,d1

.Loop9:			lea	SetPresetCmd2,a0

			cmpa.l	FileMemPtr,a1
			bne.s	.Skip7
			addq.l	#1,a0

.Skip7:			bsr	.MoveString

			movea.l	a2,a0
			jsr	MoveString
			move.b	#'"',-1(a1)
			move.b	#' ',(a1)+
			move.b	#'"',(a1)+

			movea.l	a3,a0
			jsr	MoveString
			move.b	#'"',-1(a1)
			move.b	#' ',(a1)+
			move.b	#'"',(a1)+

			movea.l	(a4),a0
			jsr	MoveString
			move.b	#'"',-1(a1)
			move.b	#' ',(a1)+

			movem.l	d0-d1/a2,-(sp)
			movea.l	a1,a0
			sub.l	d0,d0
			move.w	(a5)+,d0
			jsr	HEXtoASCII
			move.b	#" ",(a1)+

			movea.l	a1,a0
			sub.l	d0,d0
			move.w	(a5)+,d0
			jsr	HEXtoASCII
			move.b	#" ",(a1)+

			movea.l	a1,a0
			sub.l	d0,d0
			move.b	(a6)+,d0
			jsr	HEXtoASCII
			movem.l	(sp)+,d0-d1/a2

			adda.w	#120,a2
			adda.w	#24,a3
			addq.l	#6,a4
			addq.l	#1,d0
			dbf	d1,.Loop9

			lea	Preset1DrawPtr,a2	;Screens
			lea	Preset1Filename,a3
			moveq	#1,d0
			moveq	#39,d1

.Loop7:			tst.l	(a2)
			beq.s	.Skip4

			lea	LoadScrCmd2,a0

			cmpa.l	FileMemPtr,a1
			bne.s	.Skip3
			addq.l	#1,a0

.Skip3:			bsr	.MoveString

			lea	Dir2,a0
			jsr	MoveString
			subq.l	#1,a1
			movea.l	a3,a0
			jsr	MoveString
			move.b	#'"',-1(a1)

.Skip4:			adda.w	#8,a2
			adda.w	#41,a3
			addq.l	#1,d0
			dbf	d1,.Loop7

			lea	SeqMemSize1,a2		;Sequences
			lea	Sequence1Filename,a3
			moveq	#1,d0
			move.l	#331,d1

.Loop8:			tst.l	(a2)
			beq.s	.Skip6

			lea	LoadSeqCmd2,a0

			cmpa.l	FileMemPtr,a1
			bne.s	.Skip5
			addq.l	#1,a0

.Skip5:			bsr.s	.MoveString

			lea	Dir,a0
			jsr	MoveString
			subq.l	#1,a1
			movea.l	a3,a0
			jsr	MoveString
			move.b	#'"',-1(a1)

.Skip6:			adda.w	#8,a2
			adda.w	#41,a3
			addq.l	#1,d0
			dbf	d1,.Loop8

			lea	Filename7,a0		;Save it
			jsr	MakeFilename3

			subq.l	#1,FileMemSize
			jsr	SaveFile
			addq.l	#1,FileMemSize

			cmpi.b	#1,d0
			beq.s	.Error2

			lea	StatusBlank,a0
			jsr	PrintStatus

.Scope:			jsr	FreeFileMem
			jmp	Scope

.MoveString:		jsr	MoveString
			lea	-1(a1),a0
			movem.l	d0-d1/a2,-(sp)
			jsr	HEXtoASCII
			movem.l	(sp)+,d0-d1/a2
			move.b	#" ",(a1)+
			move.b	#'"',(a1)+
			rts

.Error:			jsr	FreeFileMem
			bra	Error3

.Error2:		jsr	FreeFileMem
			bra	Error5

.AddNumber:		cmpi.w	#9,d2
			bls.s	.NSkip
			addq.l	#1,d0
			cmpi.w	#99,d2
			bls.s	.NSkip
			addq.l	#1,d0
.NSkip:			rts

Factory2:		clr.b	AttachStatus
			clr.b	MorphStatus
			clr.b	DrawStatus
			lea	FactoryCmdText,a0
			lea	FactoryCmd,a1
			lea	FactoryPos,a2
			move.b	FactorySpeed,d1
			lea	FactoryDrawPtr,a3
			bra	LoadPreset

About:			bsr	SeqStuffOff
			bsr	AllOff

			moveq	#2,d1
			movea.l	(4).l,a6
			jsr	_LVOAvailMem(a6)
			lea	AboutIText6+6,a0
			jsr	HEXtoASCII

			moveq	#4,d1
			movea.l	(4).l,a6
			jsr	_LVOAvailMem(a6)
			lea	AboutIText7+6,a0
			jsr	HEXtoASCII

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenAboutWindow
			tst.l	d0
			bne.s	.Done
			bra.s	.Next

.Wait:			jsr	Clock
			jsr	ShortDelay

.Next:			movea.l	AboutWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			beq.s	.Next

			jsr	CloseAboutWindow

.Done:			jsr	OpenMenu
			jmp	Scope

Iconify:		bsr	SeqStuffOff
			bsr	AllOff

			bchg	#0,IconifyFlag
			beq.s	.On

			movea.l	LaserWnd,a0
			movea.l	IntBase,a6
			jsr	_LVOCloseWindow(a6)

.OpenD:			jsr	OpenDisplay
			beq.l	Exit9

			bsr	SetGadgets
			jsr	SetMenus2
			jsr	SetMenus3
			bsr.s	SetMenus
			jsr	OpenMagnifyGlass
			move.b	#1,DrawUpdateFlag
			clr.b	GridFlag2
			bra.s	.Done

.On:			jsr	CloseMagnifyGlassWindow
			jsr	CloseLaserWindow
			jsr	CloseDownScreen
			move.w	#$ffff,NextSelect
			clr.b	PtrDrawFlag

			lea	IconWindow,a0
			movea.l	IntBase,a6
			jsr	_LVOOpenWindow(a6)
			move.l	d0,LaserWnd
			bne.s	.Done

			clr.b	IconifyFlag
			bra.s	.OpenD

.Done:			tst.b	FromConfig
			beq.l	Scope
			rts

SetMenus:		bsr	GetDrawModeItem		;Draw
			move.b	DrawMode,d0
			bsr	.SetMenu

			jsr	GetSendXYItem		;Special
			move.b	SendXYFlag,d0
			bsr	.SetMenu

			bsr	GetAutoManItem		;Preference
			move.b	AutoManFlag,d0
			bsr	.SetMenu
			move.b	PresetMoveFlag,d0
			bsr	.SetMenu
			move.b	SeqMoveFlag,d0
			bsr	.SetMenu
			move.b	HiResFlag,d0
			bsr	.SetMenu
			move.b	AutoRetraceFlag,d0
			bsr	.SetMenu
			move.b	FilterFlag,d0
			bsr	.SetMenu
			move.b	MagGlassFlag,d0
			bsr	.SetMenu
			move.b	GridFlag,d0
			bsr	.SetMenu
			move.b	D3Flag,d0
			bsr	.SetMenu

			tst.b	D3Flag
			beq.s	.D3Skip
			bset	#4,13(a0)

.D3Skip:		move.b	TopViewFlag,d0
			bsr	.SetMenu

			jsr	GetBigScreenItem	;Sys prefs
			move.b	BigScreenFlag,d0
			bsr	.SetMenu
			move.b	FastScopeFlag,d0
			bsr	.SetMenu
			move.b	DrawScopeFlag,d0
			bsr	.SetMenu
			move.b	DrawBetweenFlag,d0
			bsr	.SetMenu
			move.b	ShowRSFlag,d0
			bsr	.SetMenu
			move.b	PPSFlag,d0
			bsr.s	.SetMenu
			move.b	PeriodFlag,d0
			bsr.s	.SetMenu
			move.b	DMAFlag,d0
			bsr.s	.SetMenu
			move.b	AutoDMAFlag,d0
			bsr.s	.SetMenu
			move.b	AutoPointsFlag,d0
			bsr.s	.SetMenu
			move.b	AutoPreloadFlag,d0
			bsr.s	.SetMenu
			move.b	AutoAttachFlag,d0
			bsr.s	.SetMenu
			move.b	SwapFlag,d0
			bsr.s	.SetMenu
			move.b	InvertXFlag,d0
			bsr.s	.SetMenu
			move.b	InvertYFlag,d0
			bsr.s	.SetMenu
			move.b	SmoothChgFlag,d0
			bsr.s	.SetMenu
			move.b	NoDragFlag,d0
			bsr.s	.SetMenu
			move.b	DirectFlag,d0
			bsr.s	.SetMenu

			jsr	SerialItemsOff

			tst.b	ItemsFlag
			bne.s	.End
			jsr	ToggleItems
			clr.b	ItemsFlag
.End:			rts

.SetMenu:		bclr	#0,12(a0)
			tst.b	d0
			beq.s	.Skip
			bset	#0,12(a0)
.Skip:			movea.l	(a0),a0			;Next item
			rts

SetGadgets:		moveq	#GD_Shutter,d0
			move.b	ShutterFlag,d1
			bsr.s	.SetGad

			moveq	#GD_Standby,d0
			move.b	StandbyFlag,d1
			bsr.s	.SetGad

			moveq	#GD_FastMove,d0
			move.b	FastMoveFlag2,d1
			bsr.s	.SetGad

			moveq	#GD_Strobe,d0
			move.b	StrobeFlag,d1
			bsr.s	.SetGad

			tst.b	DrawMode
			beq.s	.End

			moveq	#GD_Morph,d0
			jsr	FindGadPtr
			jsr	GadEnable
.End:			rts

.SetGad:		jsr	FindGadPtr
			tst.b	d1
			bne.s	.On
			jsr	GadOff
			rts

.On:			jsr	GadOn
			rts

CheckIconify:		tst.b	IconifyFlag
			bne.s	.Skip
			rts

.Skip:			addq.l	#4,sp
			lea	Dummy-12,a0
			rts


;Draw menu:

DrawIt:			bsr	SeqStuffOff

			bchg	#0,DrawMode
			beq.s	.On

			bsr	AllOff
			bsr	DrawOff

			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			jsr	CheckCenter
			bsr	TurnItOff2
			bsr	GetDrawMem
			beq	.Error

			movea.l	XDataPtr,a0
			clr.b	(a0)

			move.l	YDataPtr,a0
			clr.b	(a0)

			move.l	ZDataPtr,a0
			clr.b	(a0)

			move.l	#1,Len0
			move.l	#1,Len1
			move.l	#1,Len2
			move.l	#1,Len3

			bsr	ResetAll
			bsr.s	DrawOn

			clr.b	HiResFlag
			jsr	GetHiResItem
			bclr	#0,12(a0)

			clr.b	AutoRetraceFlag
			bsr	GetAutoRetraceItem
			bclr	#0,12(a0)

			clr.b	D3Flag
			jsr	GetD3Item
			movea.l	(a0),a2
			bclr	#0,12(a0)
			bclr	#4,13(a2)

			jsr	RestartSound

			move.b	#1,DefaultFreq

			lea	StatusDraw,a0
			jsr	PrintStatus
			jmp	Scope

.Error:			clr.b	DrawMode
			bsr	GetDrawModeItem
			bclr	#0,12(a0)
			jmp	Error3

DrawOn:			jsr	BlankScope
			jsr	CheckPosition
			jsr	CalcDCOffset
			jsr	ToggleItems

			moveq	#GD_Morph,d0
			jsr	FindGadPtr
			jsr	GadEnable

			move.l	#-1,Vol2Print
			clr.l	Freq0Print
			clr.l	Freq2Print
			move.l	#-1,Phase2Print
			move.w	#-1,RotateAngle23Print
			move.l	#-1,Spin2Print
			rts

DrawOff:		clr.b	MorphFlag
			clr.b	DrawingFlag
			jsr	SetSineWave
			bsr	ResetAll
			jsr	CheckPosition
			jsr	CalcDCOffset

			tst.b	RestartFlag
			bne.s	.Skip
			jsr	RestartSound

.Skip:			jsr	SetFilter
			jsr	BlankScope
			bsr	FreeDrawMem
			bsr	FreeMorphMem
			jsr	ToggleItems
			clr.l	DrawLen

			lea	DefaultFilename,a0
			lea	Filename4,a1
			jsr	MoveString

			moveq	#GD_Morph,d0
			jsr	FindGadPtr
			jsr	GadDisable

			move.l	#-1,Vol2Print
			clr.l	Freq0Print
			clr.l	Freq2Print
			move.l	#-1,Phase2Print
			move.w	#-1,RotateAngle23Print
			move.l	#-1,Spin2Print
			rts

GetDrawModeItem:	bsr	CheckIconify
			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	18(a0),a0		;Item 1
			rts

GetDrawMem:		sub.l	d1,d1
			move.l	#MaxPoints*3,d0
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,DrawMemPtr
			beq.s	.End

			move.l	d0,Loc0
			move.l	d0,Loc3
			move.l	d0,XDataPtr
			move.l	d0,XDrawPtr
			addi.l	#MaxPoints,d0
			move.l	d0,Loc1
			move.l	d0,Loc2
			move.l	d0,YDataPtr
			move.l	d0,YDrawPtr
			addi.l	#MaxPoints,d0
			move.l	d0,ZDataPtr
			move.l	d0,ZDrawPtr
.End:			rts

FreeDrawMem:		bsr.s	ClrLastPtrs
			clr.b	RBufferFlag
			clr.b	SBufferFlag

FreeDrawMem2:		move.l	DrawMemPtr,d0
			beq.s	.End
			movea.l	d0,a1
			move.l	#MaxPoints*3,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	DrawMemPtr
.End:			rts

ClrLastPtrs:		clr.l	XDataTextPtr
			clr.l	XDataLinePtr
			clr.l	XDataArcPtr
			clr.l	XDataBoxPtr
			clr.l	XDataEllipsePtr
			clr.l	XDataMergePtr
			clr.l	XDataDragPtr
			clr.l	XDataLastPtr
			rts

FreeMorphMem:		move.l	MorphMemPtr,d0
			beq.s	.End
			movea.l	d0,a1
			move.l	#MaxPoints*3,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	MorphMemPtr
.End:			rts

MouseMove:		clr.w	StackNumber
			move.w	#1,StackNumber2

			cmpi.w	#ScopeX+4,d5
			blo	.Off

			cmpi.w	#ScopeX+258,d5
			bhi	.Off

			cmpi.w	#ScopeY+2,d6
			blo	.Off

			tst.b	BigScreenFlag
			beq.s	.Skip

			cmpi.w	#ScopeY+129+127,d6
			bra.s	.Skip2

.Skip:			cmpi.w	#ScopeY+129,d6
.Skip2:			bhi	.Off

			jsr	PtrDraw

			tst.b	ShiftMode
			bne	ShiftPos

			tst.b	ResizeMode
			bne	ResizePos

			tst.b	TextMode
			bne	TextPos

			tst.b	LineMode
			bne	LinePos

			tst.b	ArcMode
			bne	ArcPos

			tst.b	BoxMode
			bne	BoxPos

			tst.b	EllipseMode
			bne	EllipsePos

			tst.b	InsertMode
			bne.l	InsertPos

			tst.b	InsertMode2
			bne.l	InsertPos2

			tst.b	DeleteMode
			bne.l	DeletePos

			tst.b	MoveMode
			bne.l	MovePntPos

			tst.b	DrawMode
			bne.s	.Drawing
			bra	MovePattern

.Off:			bsr	MouseButtonOff
			jsr	PtrClear
			jmp	Scope

.Drawing:		tst.b	NoDragFlag
			bne.s	.Skip3

			tst.b	MouseFlag
			bne	AddPoint

.Skip3:			bsr.s	GetMousePos
			bsr	ShowPXY
			jmp	Scope

GetMousePos:		subi.w	#ScopeX+4,d5
			subi.b	#127,d5
			move.b	d5,XMousePos

			tst.b	BigScreenFlag
			beq.s	.Skip

			move.w	#ScopeY+129+127,d0
			sub.w	d6,d0
			bra.s	.Skip2

.Skip:			move.w	#ScopeY+129,d0
			sub.w	d6,d0
			lsl.b	#1,d0

.Skip2:			subi.b	#127,d0
			move.b	d0,YMousePos
			rts

GetMousePos3D:		bsr.s	GetMousePos
GetMousePos3D2:		tst.b	GotXFlag
			bne.s	.XSkip
			move.b	XMousePos,XMousePos3D
			move.b	#1,GotXFlag

.XSkip:			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			move.b	YMousePos,ZMousePos
			neg.b	ZMousePos
			move.b	#1,GotZFlag

			clr.b	TopViewFlag
			jsr	GetTopViewItem
			bclr	#0,12(a0)
			move.b	#1,DrawUpdateFlag
			jsr	PtrDraw2
			bsr	ShowPXY

			tst.b	GotYFlag
			bne.s	.End

.GetIt:			movea.l	StackPtr,sp
			jmp	Scope

.TSkip:			move.b	YMousePos,YMousePos3D
			move.b	#1,GotYFlag

			tst.b	GotZFlag
			bne.s	.ZSkip
			clr.b	ZMousePos

.ZSkip:			tst.b	DrawScopeFlag
			beq.s	.End

			tst.b	D3Flag
			beq.s	.End

			move.b	#1,TopViewFlag
			jsr	GetTopViewItem
			bset	#0,12(a0)
			move.b	#1,DrawUpdateFlag
			jsr	PtrDraw2
			bsr	ShowPXY

			tst.b	GotZFlag
			beq.s	.GetIt

.End:			clr.b	GotXFlag
			clr.b	GotYFlag
			clr.b	GotZFlag
			rts

Mouse3DOff:		tst.b	GotXFlag
			beq.s	.End

			clr.b	GotXFlag

			movem.l	d0-d7/a0-a6,-(sp)
			clr.b	TopViewFlag
			jsr	GetTopViewItem
			bclr	#0,12(a0)

			tst.b	GotZFlag
			beq.s	.Skip
			move.b	#1,TopViewFlag
			jsr	GetTopViewItem
			bset	#0,12(a0)

.Skip:			move.b	#1,DrawUpdateFlag
			jsr	PtrDraw2
			bsr.s	ShowPXY
			movem.l	(sp)+,d0-d7/a0-a6

			clr.b	GotYFlag
			clr.b	GotZFlag
.End:			rts

ShowPXY:		tst.l	StatusCount
			bpl	.End

			move.l	#-1,StatusCount

			bsr	ShowPoints

			lea	MousePosText,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	XMousePos,d0
			bsr	ConvertCordinate

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			lea	MousePosText3,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	YMousePos,d0
			neg.b	d0
			bsr	ConvertCordinate
			bra.s	.TSkip2

.TSkip:			lea	MousePosText2,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	YMousePos,d0
			bsr	ConvertCordinate

.TSkip2:		movea.l	a1,a0
			move.b	#$20,(a0)+
			move.b	#"(",(a0)+

			move.b	XMousePos,d0
			ext.w	d0
			movea.l	DrawMemPtr,a1
			move.l	Len0,d1
			move.b	-1(a1,d1),d1
			ext.w	d1
			sub.w	d1,d0
			bsr	ConvertCordinate2

			movea.l	a1,a0
			move.b	#",",(a0)+

			tst.b	DrawScopeFlag
			beq.s	.TSkip3

			tst.b	D3Flag
			beq.s	.TSkip3

			tst.b	TopViewFlag
			beq.s	.TSkip3

			move.b	YMousePos,d0
			ext.w	d0
			neg.w	d0
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			move.l	Len0,d1
			move.b	-1(a1,d1),d1
			ext.w	d1
			sub.w	d1,d0
			bsr	ConvertCordinate2
			bra.s	.TSkip4

.TSkip3:		move.b	YMousePos,d0
			ext.w	d0
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			move.l	Len1,d1
			move.b	-1(a1,d1),d1
			ext.w	d1
			sub.w	d1,d0
			bsr.s	ConvertCordinate2

.TSkip4:		move.b	#")",(a1)+
			clr.b	(a1)

			lea	ASCIIBuffer,a0
			jsr	PrintStatus3
.End:			rts

ShowPoints:		lea	ASCIIBuffer,a0
			move.b	#"(",(a0)+

			tst.b	DrawMode
			bne.s	.Skip

			move.b	#"-",(a0)+
			movea.l	a0,a1
			clr.b	(a0)+
			rts

.Skip:			move.l	XDataPtr,d0
			sub.l	DrawMemPtr,d0
			jsr	HEXtoASCII
			rts

ConvertCordinate:	tst.b	d0
			bpl.s	.Skip
			move.b	#"-",(a0)+
			neg.b	d0
.Skip:			andi.l	#$ff,d0
			jsr	HEXtoASCII
			rts

ConvertCordinate2:	tst.w	d0
			bpl.s	.Skip
			move.b	#"-",(a0)+
			neg.w	d0
.Skip:			andi.l	#$ffff,d0
			jsr	HEXtoASCII
			rts

MovePattern:		tst.b	MouseFlag		;Button down only
			beq.l	Scope

MousePattern:		bsr	GetMousePos
			move.b	XMousePos,d0
			ext.w	d0
			muls	#2,d0
			addi.w	#XMax/2,d0
			move.w	d0,XPosTemp

			move.b	YMousePos,d0
			ext.w	d0
			muls	#2,d0
			addi.w	#YMax/2,d0
			move.w	d0,YPosTemp

			sub.l	d2,d2
			jsr	CalcMoveRate
			move.b	#1,MoveStatus2		;Print pos
			bsr	RecordMove
			jmp	Scope

MouseButtonOff:		clr.b	MouseFlag

			tst.b	StartDrawFlag
			beq.s	.Skip
			clr.b	StartDrawFlag
			clr.b	SkipFreq
			jsr	RestartSound

.Skip:			tst.b	InsertFlag
			beq.s	.Skip2
			clr.b	InsertFlag
			clr.b	InsertMode

.Skip2:			tst.b	InsertFlag2
			beq.s	.ISkip
			clr.b	InsertFlag2
			clr.b	InsertMode2

.ISkip:			tst.b	DeleteFlag
			beq.s	.Skip3
			clr.b	DeleteFlag
			clr.b	DeleteMode

.Skip3:			tst.b	DragFlag
			beq.s	.End
			clr.b	DragFlag
			jsr	UndoUpdate
			cmpi.l	#2,DragCount
			blo.s	.Skip4
			move.b	#1,DragMode
.Skip4:			clr.l	DragCount
			move.l	XDataPtr,XDataDragPtrTemp
.End:			rts

MouseButton:		bsr	MouseButtonOff

			cmpi.b	#$68,d4			;Mouse down?
			bne.l	Scope

			cmpi.w	#ScopeX+4,d5
			blo.l	Scope

			cmpi.w	#ScopeX+258,d5
			bhi.l	Scope

			cmpi.w	#ScopeY+2,d6
			blo.l	Scope

			tst.b	BigScreenFlag
			beq.s	.Skip

			cmpi.w	#ScopeY+129+127,d6
			bra.s	.Skip2

.Skip:			cmpi.w	#ScopeY+129,d6
.Skip2:			bhi.l	Scope

			move.b	#1,MouseFlag

			sub.l	d1,d1
			move.b	PirateFlag,d1
			divs	d1,d6			;Pirate buster!

			tst.b	ShiftMode
			bne	ShiftPosOff

			tst.b	ResizeMode
			bne	ResizeIt

			tst.b	RotateMode
			bne	RotatePos

			tst.b	TextMode
			bne	TextPosOff

			tst.b	LineMode
			bne	LineIt

			tst.b	ArcMode
			bne	ArcIt

			tst.b	BoxMode
			bne	BoxPosOff

			tst.b	EllipseMode
			bne	EllipsePosOff

			tst.b	InsertMode
			bne.l	InsertIt

			tst.b	InsertMode2
			bne.l	InsertIt3

			tst.b	DeleteMode
			bne.l	DeleteIt

			tst.b	MoveMode
			bne.l	MoveIt

			tst.b	DrawMode
			beq	MousePattern

AddPoint:		bsr	GetMousePos
			tst.b	ShiftFlag
			bne.s	.DelSkip
			bsr	GetMousePos3D2

.DelSkip:		jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			jsr	FreePreloadMem
			bsr	RollOff

			tst.b	ShiftFlag
			bne.l	DeleteIt2

			tst.b	CtrlFlag
			bne.l	InsertIt2a

			tst.l	XDataDragPtrTemp
			beq.s	.DSkip

			tst.l	XDataDragPtr
			bne.s	.DSkip2

.DSkip:			move.l	XDataPtr,XDataDragPtrTemp
.DSkip2:		move.l	XDataDragPtrTemp,XDataDragPtr
			move.l	XDataDragPtrTemp,XDataLastPtr

			movea.l	XDataPtr,a0		;X
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			cmpa.l	a0,a1
			bhi.s	.Skip

			moveq	#1,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a0
			lea	1(a0),a1
			move.l	#MaxPoints-2,d0

.Loop:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop

.Skip:			move.b	XMousePos3D,(a0)+
			move.l	a0,XDataPtr

			movea.l	YDataPtr,a0		;Y
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip2

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints,a0
			lea	1(a0),a1
			move.l	#MaxPoints-2,d0

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop2

.Skip2:			move.b	YMousePos3D,(a0)+
			move.l	a0,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip

			movea.l	ZDataPtr,a0		;Z
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			cmpa.l	a0,a1
			bhi.s	.Skip3

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			lea	1(a0),a1
			move.l	#MaxPoints-2,d0

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop3

.Skip3:			move.b	ZMousePos,(a0)+
			move.l	a0,ZDataPtr

.D3Skip:		bsr	GetDrawLen
			jsr	CheckDefault
			bsr	CheckFreq

			move.l	XDataPtr,d0
			sub.l	XDataDragPtr,d0
			move.l	d0,XDataDragSize
			move.l	d0,XDataDragSize+4
			move.l	d0,XDataLastSize

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.b	#1,DragFlag
			addq.l	#1,DragCount
			addq.l	#1,DrawLen

			move.w	Speed0,d0
			cmpi.w	#156,d0
			bls.s	.Skip4

			mulu	Len0+2,d0
			cmpi.l	#170000,d0
			blo.s	.Skip4

			clr.b	StartDrawFlag
			clr.b	SkipFreq
			jsr	RestartSound
			bsr	ShowPXY
			jmp	Scope

.Skip4:			move.b	#1,StartDrawFlag
			move.b	#1,SkipFreq
			move.l	#$01010101,AD0Update
			bsr	ShowPXY
			jmp	Scope

GetDrawLen:		move.l	XDataPtr,d0
			sub.l	DrawMemPtr,d0
			move.l	d0,Len0
			move.l	d0,Len3

			move.l	YDataPtr,d0
			sub.l	DrawMemPtr,d0
			subi.l	#MaxPoints,d0
			move.l	d0,Len1
			move.l	d0,Len2
			rts

CheckFreq:		sub.l	d3,d3
			bsr.s	CheckFreq0
			bsr.s	CheckFreq1
			bsr.s	CheckFreq2
			bsr.s	CheckFreq3

			clr.l	Freq0Print
			clr.l	Freq2Print
			rts

CheckFreq0:		move.l	Len0,d0
			lea	Freq0,a0
			lea	Freq0Max,a1
			lea	Freq0Min,a2
			bsr.s	CheckFreqIt
			rts

CheckFreq1:		move.l	Len1,d0
			lea	Freq1,a0
			lea	Freq1Max,a1
			lea	Freq1Min,a2
			bsr.s	CheckFreqIt
			rts

CheckFreq2:		move.l	Len2,d0
			lea	Freq2,a0
			lea	Freq2Max,a1
			lea	Freq2Min,a2
			bsr.s	CheckFreqIt
			rts

CheckFreq3:		move.l	Len3,d0
			lea	Freq3,a0
			lea	Freq3Max,a1
			lea	Freq3Min,a2
			bsr.s	CheckFreqIt
			rts

CheckFreqIt:		cmpi.l	#4,d0
			bls.s	.Okay2

			move.l	MaxPPS,d1		;Max = pps/len
			divu	d0,d1
			cmp.w	(a0),d1
			bhs.s	.Okay
			move.w	d1,(a0)
			move.w	d1,(a1)
			moveq	#1,d3
			rts

.Okay:			cmp.w	(a1),d1
			bhs.s	.Okay2
			move.w	d1,(a1)

.Okay2:			move.l	#547,d1			;Min = 547/len
			divu	d0,d1
			move.l	d1,d2
			swap	d2
			tst.w	d2
			beq.s	.Skip
			addq.w	#1,d1

.Skip:			cmp.w	(a0),d1
			bls.s	.Okay3
			move.w	d1,(a0)
			move.w	d1,(a2)
			moveq	#1,d3
			rts

.Okay3:			cmp.w	(a2),d1
			bls.s	.End
			move.w	d1,(a2)
.End:			rts

Text:			bsr	SeqStuffOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	LineOff
			bsr	ArcOff
			bsr	BoxOff
			bsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			bchg	#0,TextMode
			beq.s	.On

			clr.l	XDataTextPtrTemp
			bsr	CursorOff
			jsr	FreeCharBSMem
			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			tst.l	FontSize
			bne.s	.Skip

			lea	Dir3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename5,a0
			jsr	MoveString

			jsr	LoadFile
			cmpi.b	#1,d0
			beq	.Error

			cmpi.b	#2,d0
			beq	.Error2

			move.l	FileMemPtr,FontPtr
			move.l	FileMemSize,FontSize
			clr.l	FileMemSize

			movea.l	FontPtr,a1
			adda.w	#34,a1
			lea	FontString,a0
			jsr	CmpString
			beq	.Error3

.Skip:			jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	TextOffFlag
			move.b	#-58,XTextPos
			move.b	#-58,XTextPos2
			move.b	#-12,YTextPos
			clr.b	ZTextPos

			jsr	TopViewOff
			bsr	ShowPoints
			lea	StatusText,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bsr	CursorOn
			jmp	Scope

.Error:			clr.b	TextMode
			jmp	Error3

.Error2:		clr.b	TextMode
			jsr	FlashScreen
			lea	Error19Text,a0
			jsr	PrintStatus
			jmp	Scope

.Error3:		bsr.s	FreeFontMem
			clr.b	TextMode
			jsr	FlashScreen
			lea	Error20Text,a0
			jsr	PrintStatus
			jmp	Scope

TextOff:		tst.b	TextMode
			beq.s	.End
			clr.b	TextMode
			clr.l	XDataTextPtrTemp
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	CursorOff
			jsr	FreeCharBSMem
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

FreeFontMem:		move.l	FontSize,d0
			beq.s	.End
			movea.l	FontPtr,a1
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	FontSize
.End:			rts

TextPosOff:		bsr	GetMousePos3D
			move.b	#1,TextOffFlag
			move.b	XMousePos3D,XMousePos
			move.b	YMousePos3D,YMousePos
			move.b	ZMousePos,ZTextPos
			bra.s	TextPos3

TextPos:		tst.b	TextOffFlag
			beq.s	TextPos2
			bsr	GetMousePos
			bsr	ShowPXY
			jmp	Scope

TextPos2:		bsr	GetMousePos
TextPos3:		bsr	CursorOff

			movea.l	FontPtr,a0
			move.w	54(a0),d1
			move.b	#254,d0
			sub.b	d1,d0
			move.b	XMousePos,d1
			addi.b	#127,d1
			cmp.b	d0,d1
			bhi.s	.Skip

			move.b	XMousePos,XTextPos
			move.b	XMousePos,XTextPos2

.Skip:			move.w	56(a0),d1
			move.b	#254,d0
			sub.b	d1,d0
			move.b	YMousePos,d1
			addi.b	#127,d1
			cmp.b	d0,d1
			bhi.s	.Skip2

			move.b	YMousePos,YTextPos

.Skip2:			bsr.s	CursorOn
			bsr	ShowPXY
			jmp	Scope

CursorFlash:		tst.b	TextMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount
			blo.s	.End

			moveq	#2,d0
			bchg	#0,CursorFlag
			beq.s	Cursor
			moveq	#1,d0
			bra.s	Cursor

CursorOff:		tst.b	CursorFlag
			beq.s	.End
			clr.b	CursorFlag
			moveq	#1,d0
			bra.s	Cursor
.End:			rts

CursorOn:		move.b	#1,CursorFlag
			moveq	#2,d0

Cursor:			jsr	CheckDrawMode

			move.b	XTextPos,d0
			bsr	CheckHiResX
			move.b	YTextPos,d2
			addq.b	#2,d2
			bsr	CheckHiResY
			move.l	d1,-(sp)
			move.l	d0,-(sp)
			jsr	Move

			move.l	(sp)+,d0
			movea.l	FontPtr,a0
			move.w	54(a0),d1
			subq.w	#4,d1
			tst.b	DrawScopeFlag
			bne.s	.Skip
			tst.b	HiResFlag
			beq.s	.Skip
			addq.w	#1,d1
			lsr.w	#1,d1

.Skip:			add.w	d1,d0
			move.l	(sp)+,d1
			jsr	Draw
			jsr	CheckDrawMode2
			clr.b	MiscCount
			rts

TypingText:		cmpi.b	#$4f,d4
			bhi.l	Scope

			move.b	#1,TextOffFlag

			cmpi.b	#$40,d4
			beq	.Space

			cmpi.b	#$41,d4
			beq	.BS

			cmpi.b	#$44,d4
			beq	.CR

			cmpi.b	#$45,d4
			beq	EscShift

			cmpi.b	#$4c,d4
			beq	.North

			cmpi.b	#$4d,d4
			beq	.South

			cmpi.b	#$4e,d4
			beq	.Space

			cmpi.b	#$4f,d4
			beq	.West

			lea	InputEvent,a0
			move.w	d4,6(a0)		;Code
			move.w	d7,8(a0)		;Qualifier
			move.l	d3,10(a0)		;Address

			lea	KeyMapBuffer,a1
			moveq	#1,d1
			suba.l	a2,a2
			movea.l	KeyBase,a6
			jsr	_LVOMapRawKey(a6)
			tst.l	d0
			bmi.l	Scope
			beq.l	Scope

			sub.l	d0,d0
			move.b	KeyMapBuffer,d0

			movea.l	FontPtr,a0
			adda.w	#58,a0
			move.b	(a0)+,d1
			cmp.b	d1,d0
			blo.l	Scope

			cmp.b	(a0)+,d0
			bhi.l	Scope

			sub.b	d1,d0
			movea.l	a0,a1

.Loop:			adda.w	(a1)+,a0
			dbf	d0,.Loop

			sub.l	d0,d0			;Data len
			move.w	(a1),d0

			cmpi.w	#4,d0
			bls.l	Scope

			tst.b	DrawMode
			bne.s	.DrawOn

			move.l	a0,-(sp)
			move.l	d0,-(sp)
			bsr	MakeDrawOn
			move.l	(sp)+,d0
			movea.l	(sp)+,a0

			tst.b	DrawMode
			beq.l	Scope

			move.l	a0,-(sp)
			move.l	d0,-(sp)
			jsr	ResetAll
			move.l	(sp)+,d0
			movea.l	(sp)+,a0

.DrawOn:		tst.l	XDataTextPtrTemp
			beq.s	.DSkip

			tst.l	XDataTextPtr
			bne.s	.DSkip2

.DSkip:			move.l	XDataPtr,XDataTextPtrTemp
.DSkip2:		move.l	XDataTextPtrTemp,XDataTextPtr
			move.l	XDataTextPtrTemp,XDataLastPtr

			lsr.l	#1,d0
			move.l	d0,d2

			clr.b	TextAnchorFlag
			move.l	XDataPtr,d3
			cmp.l	XDataTextPtrTemp,d3
			bne.s	.ASkip

			addq.l	#3,d2
			move.b	#1,TextAnchorFlag

.ASkip:			subq.l	#1,d0
			move.l	d0,d1

			movea.l	XDataPtr,a1		;X data
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints,a2
			suba.w	d2,a2
			cmpa.l	a1,a2
			bhi.s	.ASkip2

			move.l	a1,d3
			move.l	a1,d7
			sub.l	a2,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a1
			lea	(a1,d7),a2
			sub.l	a2,d3
			subq.l	#1,d3

.Loop3:			move.b	(a2)+,(a1)+
			dbf	d3,.Loop3

.ASkip2:		tst.b	TextAnchorFlag
			beq.s	.Loop4

			move.b	(a0),d3
			add.b	XTextPos,d3
			move.b	d3,(a1)+
			move.b	d3,(a1)+
			move.b	d3,(a1)+

.Loop4:			move.b	(a0)+,d3
			add.b	XTextPos,d3
			move.b	d3,(a1)+
			dbf	d0,.Loop4
			move.l	a1,XDataPtr

			movea.l	YDataPtr,a1		;Y data
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2
			suba.w	d2,a2
			move.l	d1,d0
			cmpa.l	a1,a2
			bhi.s	.ASkip3

			move.l	a1,d3
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			lea	(a1,d7),a2
			sub.l	a2,d3
			subq.l	#1,d3

.Loop5:			move.b	(a2)+,(a1)+
			dbf	d3,.Loop5

.ASkip3:		tst.b	TextAnchorFlag
			beq.s	.Loop6

			move.b	(a0),d3
			add.b	YTextPos,d3
			move.b	d3,(a1)+
			move.b	d3,(a1)+
			move.b	d3,(a1)+

.Loop6:			move.b	(a0)+,d3
			add.b	YTextPos,d3
			move.b	d3,(a1)+
			dbf	d1,.Loop6
			move.l	a1,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip

			movea.l	ZDataPtr,a1		;Z data
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*3,a2
			suba.w	d2,a2
			cmpa.l	a1,a2
			bhi.s	.ASkip4

			move.l	a1,d3
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			lea	(a1,d7),a2
			sub.l	a2,d3
			subq.l	#1,d3

.Loop7:			move.b	(a2)+,(a1)+
			dbf	d3,.Loop7

.ASkip4:		tst.b	TextAnchorFlag
			beq.s	.Loop8

			move.b	ZTextPos,(a1)+
			move.b	ZTextPos,(a1)+
			move.b	ZTextPos,(a1)+

.Loop8:			move.b	ZTextPos,(a1)+
			dbf	d0,.Loop8
			move.l	a1,ZDataPtr

.D3Skip:		add.w	d2,DrawLen+2

			moveq	#8,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq.s	.Skip8

			movea.l	d0,a0
			move.l	LastChrPtr,(a0)
			move.l	d0,LastChrPtr

			move.b	XTextPos,4(a0)
			move.b	YTextPos,5(a0)
			move.w	d2,6(a0)

.Skip8:			bsr	GetDrawLen
			jsr	CheckDefault
			bsr	CheckFreq
			jsr	RestartSound

			move.l	XDataPtr,d0
			sub.l	XDataTextPtr,d0
			move.l	d0,XDataTextSize
			move.l	d0,XDataTextSize+4
			move.l	d0,XDataLastSize
			jsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusText,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus

.Space:			bsr	CursorOff
			movea.l	FontPtr,a0
			move.w	54(a0),d1
			move.w	#254,d0
			sub.b	d1,d0
			sub.l	d2,d2
			move.b	XTextPos,d2
			addi.b	#127,d2
			add.w	d1,d2
			cmp.w	d0,d2
			bhi.s	.Skip9
			add.b	d1,XTextPos
			bra.s	.Skip10
.Skip9:			move.b	XTextPos2,XTextPos
			move.w	56(a0),d1
			sub.l	d2,d2
			move.b	YTextPos,d2
			addi.b	#127,d2
			sub.w	d1,d2
			bmi.s	.Skip10
			sub.b	d1,YTextPos
.Skip10:		bsr	CursorOn
			jmp	Scope

.BS:			move.l	LastChrPtr,d0
			bne.s	.BSSkip
			jsr	FlashScreen
			jmp	Scope

.BSSkip:		move.l	d0,-(sp)
			bsr	CursorOff
			movea.l	(sp)+,a1

			move.l	(a1),LastChrPtr
			move.b	4(a1),XTextPos
			move.b	5(a1),YTextPos
			sub.l	d0,d0
			move.w	6(a1),d0

			sub.l	d0,XDataPtr
			sub.l	d0,YDataPtr
			sub.l	d0,ZDataPtr

			tst.l	XDataTextSize
			beq.s	.LSkip

			sub.l	d0,XDataTextSize
			bne.s	.LSkip2

.LSkip:			clr.l	XDataTextPtr
			clr.l	XDataLastPtr

.LSkip2:		moveq	#8,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

			bsr	GetDrawLen

			tst.l	Len0
			bne.s	.Skip11

			movea.l	XDataPtr,a0
			move.l	a0,XDrawPtr
			clr.b	(a0)

			movea.l	YDataPtr,a0
			move.l	a0,YDrawPtr
			clr.b	(a0)

			movea.l	ZDataPtr,a0
			move.l	a0,ZDrawPtr
			clr.b	(a0)

			move.l	#1,Len0
			move.l	#1,Len1
			move.l	#1,Len2
			move.l	#1,Len3

			bsr	ClrLastPtrs

.Skip11:		bsr	CheckFreq
			jsr	RestartSound
			jsr	UndoUpdate
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	CursorOn
			bsr	ShowPoints
			lea	StatusText,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			jmp	Scope

.CR:			bsr	CursorOff
			move.b	XTextPos2,XTextPos
			movea.l	FontPtr,a0
			move.w	56(a0),d1
			sub.l	d2,d2
			move.b	YTextPos,d2
			addi.b	#127,d2
			sub.w	d1,d2
			bmi.s	.Skip12
			sub.b	d1,YTextPos
.Skip12:		bsr	CursorOn
			move.l	XDataPtr,XDataTextPtrTemp
			jmp	Scope

.North:			bsr	CursorOff
			movea.l	FontPtr,a0
			move.w	56(a0),d1
			move.w	#254,d0
			sub.b	d1,d0
			sub.l	d2,d2
			move.b	YTextPos,d2
			addi.b	#127,d2
			add.w	d1,d2
			cmp.w	d0,d2
			bhi.s	.Skip13
			add.b	d1,YTextPos
.Skip13:		bsr	CursorOn
			jmp	Scope

.South:			bsr	CursorOff
			movea.l	FontPtr,a0
			move.w	56(a0),d1
			sub.l	d2,d2
			move.b	YTextPos,d2
			addi.b	#127,d2
			sub.w	d1,d2
			bmi.s	.Skip14
			sub.b	d1,YTextPos
.Skip14:		bsr	CursorOn
			jmp	Scope

.West:			bsr	CursorOff
			movea.l	FontPtr,a0
			move.w	54(a0),d1
			sub.l	d2,d2
			move.b	XTextPos,d2
			addi.b	#127,d2
			sub.w	d1,d2
			bmi.s	.Skip15
			sub.b	d1,XTextPos
.Skip15:		bsr	CursorOn
			jmp	Scope

AdjustLastPtrs:		movem.l	d0-d1/a0,-(sp)

			lea	XDataTextPtr,a0
			moveq	#9,d0
			move.l	DrawMemPtr,d1

.Loop:			tst.l	(a0)
			beq.s	.Skip
			sub.l	d7,(a0)
			cmp.l	(a0),d1
			bls.s	.Skip
			clr.l	(a0)

.Skip:			addq.l	#4,a0
			dbf	d0,.Loop

			movem.l	(sp)+,d0-d1/a0
			rts

Line:			bsr	SeqStuffOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	ArcOff
			bsr	BoxOff
			bsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			bchg	#0,LineMode
			beq.s	.On

			bsr	LineLineOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	XLinePos
			clr.b	YLinePos
			clr.b	XMousePos
			clr.b	YMousePos
			clr.b	ZMousePos

			bsr	ShowPoints
			lea	StatusLine,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bsr.s	LineLineOn
			jmp	Scope

LineOff:		tst.b	LineMode
			beq.s	.End
			clr.b	LineMode
			movem.l	d0-d7/a0-a6,-(sp)
			bsr.s	LineLineOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

LinePos:		bsr	GetMousePos
			bsr.s	LineLineOff
			move.b	XMousePos,XLinePos
			move.b	YMousePos,YLinePos
			bsr.s	LineLineOn
			bsr	ShowPXY
			jmp	Scope

LineLineFlash:		tst.b	LineMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount
			blo.s	.End

			bchg	#0,LineFlag
			beq.s	LineLine
			moveq	#1,d0
			bra.s	LineLine2

LineLineOff:		tst.b	LineFlag
			beq.s	.End
			clr.b	LineFlag
			moveq	#1,d0
			bra.s	LineLine2
.End:			rts

LineLineOn:		move.b	#1,LineFlag

LineLine:		clr.b	XLinePos2
			clr.b	YLinePos2

			tst.b	DrawMode
			beq.s	.Skip

			movea.l	XDataPtr,a0
			cmpa.l	DrawMemPtr,a0
			beq.s	.Skip

			move.b	-(a0),XLinePos2
			movea.l	YDataPtr,a0
			move.b	-(a0),YLinePos2

			tst.b	DrawScopeFlag
			beq.s	.Skip

			tst.b	D3Flag
			beq.s	.Skip

			tst.b	TopViewFlag
			beq.s	.Skip

			movea.l	ZDataPtr,a0
			move.b	-(a0),YLinePos2
			neg.b	YLinePos2

.Skip:			moveq	#2,d0

LineLine2:		jsr	CheckDrawMode

			move.b	XLinePos2,d0
			bsr.s	CheckHiResX
			move.b	YLinePos2,d2
			bsr.s	CheckHiResY
			jsr	Move

			move.b	XLinePos,d0
			bsr.s	CheckHiResX
			move.b	YLinePos,d2
			bsr.s	CheckHiResY
			jsr	Draw
			jsr	CheckDrawMode2
			clr.b	MiscCount
			rts

CheckHiResX:		tst.b	DrawMode
			beq.s	.Skip
			tst.b	DrawScopeFlag
			bne.s	.Skip
			tst.b	HiResFlag
			beq.s	.Skip
			ext.w	d0
			ext.l	d0
			divs	#2,d0

.Skip:			addi.b	#127,d0
			andi.l	#$ff,d0
			addi.w	#ScopeX+4,d0
			rts

CheckHiResY:		tst.b	DrawMode
			beq.s	.Skip
			tst.b	DrawScopeFlag
			bne.s	.Skip
			tst.b	HiResFlag
			beq.s	.Skip
			ext.w	d2
			ext.l	d2
			divs	#2,d2

.Skip:			addi.b	#127,d2
			andi.w	#$ff,d2
			tst.b	BigScreenFlag
			beq.s	.Skip2
			move.w	#ScopeY+129+127,d1
			bra.s	.Skip3

.Skip2:			addq.b	#1,d2
			lsr.b	#1,d2
			move.w	#ScopeY+129,d1

.Skip3:			sub.w	d2,d1
			rts

LineIt:			bsr	GetMousePos
			bsr	MouseButtonOff

LineIt2:		bsr	GetMousePos3D2

			tst.b	AutoPointsFlag
			bne	.ASkip

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenPointsWindow
			tst.l	d0
			bne	.Done

			movea.l	PointsGadgets,a0
			move.w	LinePoints,d0
			jsr	SetGadget

			movea.l	PointsGadgets,a0
			movea.l	PointsWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			jsr	ShortDelay

.Next:			movea.l	PointsWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	PointsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			tst.l	d0
			beq.s	.Bad

			cmpi.l	#254,d0
			bls.s	.Skip

.Bad:			jsr	FlashScreen
			bra.s	.NoChange

.Skip:			move.w	d0,LinePoints

.NoChange:		jsr	ClosePointsWindow

.Done:			jsr	OpenMenu

.ASkip:			tst.b	DrawMode
			bne.s	.DrawOn

			bsr	MakeDrawOn

			tst.b	DrawMode
			beq.l	Scope

			jsr	ResetAll

.DrawOn:		movea.l	XDataPtr,a0
			move.l	a0,XDataLinePtr
			move.l	a0,XDataLastPtr
			cmpa.l	DrawMemPtr,a0
			bne.s	.Skip2

			sub.l	d0,d0
			sub.l	d2,d2
			sub.l	d4,d4
			bra.s	.Skip3

.Skip2:			move.b	-1(a0),d0
			movea.l	YDataPtr,a0
			move.b	-(a0),d2
			movea.l	ZDataPtr,a0
			move.b	-(a0),d4

.Skip3:			move.b	XMousePos3D,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1

			move.b	YMousePos3D,d3
			ext.w	d2
			ext.w	d3
			sub.w	d2,d3

			tst.b	D3Flag
			beq.s	.D3Skip

			move.b	ZMousePos,d5
			ext.w	d4
			ext.w	d5
			sub.w	d4,d5

			move.l	d4,-(sp)
			move.l	d5,-(sp)

.D3Skip:		move.l	d2,-(sp)
			move.l	d3,-(sp)

			tst.b	AutoPointsFlag
			beq.s	.ASkip3

			move.l	d0,-(sp)
			move.l	d1,-(sp)

			muls	d1,d1
			muls	d3,d3
			add.l	d3,d1
			move.l	d1,d0
			jsr	GetSqrRoot

			move.l	d0,d2
			mulu	AutoPoints,d2
			divu	#100,d2
			andi.l	#$ffff,d2
			bne.s	.ASkip2
			moveq	#1,d2

.ASkip2:		move.l	(sp)+,d1
			move.l	(sp)+,d0
			bra.s	.ASkip4

.ASkip3:		move.w	LinePoints,d2

.ASkip4:		movea.l	XDataPtr,a0		;X data
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			suba.w	d2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip4

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop

.Skip4:			bsr	CalcLine
			move.l	a0,XDataPtr

			movea.l	YDataPtr,a0		;Y data
			move.l	(sp)+,d1
			move.l	(sp)+,d0

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			suba.w	d2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip7

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop2

.Skip7:			bsr	CalcLine
			move.l	a0,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip2

			movea.l	ZDataPtr,a0		;Z data
			move.l	(sp)+,d1
			move.l	(sp)+,d0

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			suba.w	d2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip8

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop3

.Skip8:			bsr	CalcLine
			move.l	a0,ZDataPtr

.D3Skip2:		add.w	d2,DrawLen+2

			bsr	GetDrawLen
			bsr	CheckDefault
			bsr	CheckFreq
			jsr	RestartSound

			move.l	XDataPtr,d0
			sub.l	XDataLinePtr,d0
			move.l	d0,XDataLineSize
			move.l	d0,XDataLastSize
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

.Abort2:		bsr	LineLineOff
			move.b	XMousePos,XLinePos
			move.b	YMousePos,YLinePos
			clr.b	ZMousePos

			bsr	ShowPoints
			lea	StatusLine,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			jmp	Scope

.Abort:			jsr	ClosePointsWindow
			jsr	OpenMenu
			bra.s	.Abort2

CalcLine:		move.w	d2,d4
			subq.w	#1,d4
			moveq	#1,d3

			move.l	d2,d6
			addq.w	#1,d6
			lsr.w	#1,d6
			suba.l	a1,a1
			suba.w	d6,a1

.Loop:			move.b	d0,(a0)
			move.w	d1,d5
			muls	d3,d5
			divs	d2,d5

			move.l	d5,d7
			swap	d7
			bmi.s	.ROff

			cmp.w	d6,d7
			blo.s	.ROff2
			addq.b	#1,d5
			bra.s	.ROff2

.ROff:			cmp.w	a1,d7
			bhi.s	.ROff2
			tst.w	d7
			beq.s	.ROff2
			subq.b	#1,d5

.ROff2:			add.b	d5,(a0)+
			addq.w	#1,d3
			dbf	d4,.Loop
			rts

Arc:			sub.l	d0,d0
			tst.b	ArcMode
			beq.s	Arc3

			tst.b	ArcDirection
			beq.s	Arc3

			bsr	ArcOutlineOff
			clr.b	ArcDirection
			bsr	ArcOutlineOn
			bsr	PrintArcStatus
			jmp	Scope

Arc2:			moveq	#1,d0
			tst.b	ArcMode
			beq.s	Arc3

			tst.b	ArcDirection
			bne.s	Arc3

			bsr	ArcOutlineOff
			move.b	#1,ArcDirection
			bsr	ArcOutlineOn
			bsr	PrintArcStatus
			jmp	Scope

Arc3:			move.b	d0,ArcDirection

			bsr	SeqStuffOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			bsr	BoxOff
			bsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			bchg	#0,ArcMode
			beq.s	.On

			clr.b	ArcFlag2
			bsr	ArcOutlineOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	XArcPos
			clr.b	YArcPos
			clr.b	XMousePos
			clr.b	YMousePos
			clr.b	ZMousePos

			bsr	PrintArcStatus
			bsr	ArcOutlineOn
			jmp	Scope

ArcOff:			tst.b	ArcMode
			beq.s	.End
			clr.b	ArcMode
			clr.b	ArcFlag2
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	ArcOutlineOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

ArcPos:			bsr	GetMousePos
			move.b	XMousePos,XMousePosTemp2
			move.b	YMousePos,YMousePosTemp2
			move.b	#1,ArcFlag2
			bsr	ShowPXY
			jmp	Scope

ArcPos2:		clr.b	ArcFlag2
			bsr.s	ArcOutlineOff
			move.b	XMousePosTemp2,XArcPos
			move.b	YMousePosTemp2,YArcPos
			bsr.s	ArcOutlineOn
			clr.b	MiscCount
			rts

ArcOutlineFlash:	tst.b	ArcMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount
			blo.s	.End

			tst.b	ArcFlag2
			bne.s	ArcPos2

			bchg	#0,ArcFlag
			beq.s	ArcOutline
			moveq	#1,d0
			bra.s	ArcOutline2

ArcOutlineOff:		tst.b	ArcFlag
			beq.s	.End
			clr.b	ArcFlag
			moveq	#1,d0
			bra.s	ArcOutline2
.End:			rts

ArcOutlineOn:		move.b	#1,ArcFlag

ArcOutline:		clr.b	XArcPos2
			clr.b	YArcPos2

			tst.b	DrawMode
			beq.s	.Skip

			movea.l	XDataPtr,a0
			cmpa.l	DrawMemPtr,a0
			beq.s	.Skip

			move.b	-(a0),XArcPos2
			movea.l	YDataPtr,a0
			move.b	-(a0),YArcPos2

			tst.b	DrawScopeFlag
			beq.s	.Skip

			tst.b	D3Flag
			beq.s	.Skip

			tst.b	TopViewFlag
			beq.s	.Skip

			movea.l	ZDataPtr,a0
			move.b	-(a0),YArcPos2
			neg.b	YArcPos2

.Skip:			moveq	#2,d0

ArcOutline2:		jsr	CheckDrawMode

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			move.b	XArcPos2,d0
			bsr	CheckHiResX
			move.b	YArcPos2,d2
			bsr	CheckHiResY
			jsr	Move

			move.b	XArcPos,d0
			bsr	CheckHiResX
			move.b	YArcPos,d2
			bsr	CheckHiResY
			jsr	Draw
			bra	.TSkip2

.TSkip:			tst.b	ArcDirection
			beq	.DSkip

			move.b	XArcPos,d0
			move.b	YArcPos2,d4
			move.w	#542,ArcQuadrant
			clr.b	ArcDirection2

			move.b	XArcPos,d2
			ext.w	d2
			move.b	XArcPos2,d7
			ext.w	d7
			sub.w	d7,d2
			bpl.s	.Skipa
			neg.w	d2
			move.w	#2,ArcQuadrant
			move.b	#1,ArcDirection2

.Skipa:			move.b	YArcPos,d3
			ext.w	d3
			move.b	YArcPos2,d7
			ext.w	d7
			sub.w	d7,d3
			bpl	.Skip3
			neg.w	d3
			cmpi.w	#2,ArcQuadrant
			beq.s	.Skip2a
			move.w	#362,ArcQuadrant
			move.b	#1,ArcDirection2
			bra	.Skip3
.Skip2a:		move.w	#182,ArcQuadrant
			clr.b	ArcDirection2
			bra	.Skip3

.DSkip:			move.b	XArcPos2,d0
			move.b	YArcPos,d4
			move.w	#182,ArcQuadrant
			move.b	#1,ArcDirection2

			move.b	XArcPos,d2
			ext.w	d2
			move.b	XArcPos2,d7
			ext.w	d7
			sub.w	d7,d2
			bpl.s	.Skip
			neg.w	d2
			move.w	#362,ArcQuadrant
			clr.b	ArcDirection2

.Skip:			move.b	YArcPos,d3
			ext.w	d3
			move.b	YArcPos2,d7
			ext.w	d7
			sub.w	d7,d3
			bpl.s	.Skip3
			neg.w	d3
			cmpi.w	#182,ArcQuadrant
			bne.s	.Skip2
			move.w	#2,ArcQuadrant
			clr.b	ArcDirection2
			bra.s	.Skip3
.Skip2:			move.w	#542,ArcQuadrant
			move.b	#1,ArcDirection2

.Skip3:			move.w	d2,d5
			move.b	d3,d6

			move.b	d0,XArcPos3
			move.b	d4,YArcPos3
			move.b	d2,ArcSize
			move.b	d3,ArcSize2

			bsr	CalcEllipseData

			cmp.b	d6,d5
			bhs.s	.Skip4
			move.b	d6,d5

.Skip4:			mulu	#503,d5
			divu	#320,d5
			mulu	#30,d5
			divu	#100,d5
			andi.l	#$ffff,d5
			bne.s	.Skip5
			moveq	#1,d5
.Skip5:			cmpi.w	#90,d5
			bls.s	.Skip6
			moveq	#90,d5

.Skip6:			movea.w	d5,a4
			move.w	d5,d4

			lea	SineData,a0
			adda.w	ArcQuadrant,a0

			tst.b	ArcDirection2
			beq.s	.ASkip
			subq.l	#2,a0

.ASkip:			moveq	#90,d5
			divu	d4,d5
			lsl.w	#1,d5
			move.l	d5,d6
			swap	d6

			movea.w	d5,a1
			movea.w	d6,a2
			suba.l	a3,a3
			subq.w	#1,d4

.Loop:			move.w	(a0),d5			;Get X
			muls	d2,d5
			divs	#32767,d5

			move.l	d5,d6
			swap	d6
			bmi.s	.ROff

			cmpi.w	#16384,d6
			blo.s	.ROff2
			addq.w	#1,d5
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d6
			bhi.s	.ROff2
			tst.w	d6
			beq.s	.ROff2
			subq.w	#1,d5

.ROff2:			move.w	180(a0),d6		;Get Y
			muls	d3,d6
			divs	#32767,d6

			move.l	d6,d7
			swap	d7
			bmi.s	.ROff3

			cmpi.w	#16384,d7
			blo.s	.ROff4
			addq.w	#1,d6
			bra.s	.ROff4

.ROff3:			cmpi.w	#-16384,d7
			bhi.s	.ROff4
			tst.w	d7
			beq.s	.ROff4
			subq.w	#1,d6

.ROff4:			movem.l	d0-d4/a0-a4,-(sp)
			add.w	d5,d0
			neg.w	d6
			add.w	d6,d1
			jsr	Pixel
			movem.l	(sp)+,d0-d4/a0-a4
			adda.w	a1,a0
			adda.w	a2,a3
			cmpa.w	a4,a3
			blo.s	.ESkip
			suba.w	a4,a3
			addq.l	#2,a0
.ESkip:			dbf	d4,.Loop

.TSkip2:		jsr	CheckDrawMode2
			clr.b	MiscCount
			rts

PrintArcStatus:		bsr	ShowPoints
			lea	StatusArc,a0
			tst.b	ArcDirection
			beq.s	.Skip
			lea	StatusArc2,a0
.Skip:			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			rts

ArcIt:			bsr	GetMousePos3D
			move.b	XMousePos3D,XMousePosTemp2
			move.b	YMousePos3D,YMousePosTemp2
			bsr	ArcPos2
			bsr	MouseButtonOff

ArcIt2:			tst.b	AutoPointsFlag
			bne	.ASkip

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenPointsWindow
			tst.l	d0
			bne	.Done

			movea.l	PointsGadgets,a0
			move.w	ArcPoints,d0
			jsr	SetGadget

			movea.l	PointsGadgets,a0
			movea.l	PointsWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			jsr	ShortDelay

.Next:			movea.l	PointsWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	PointsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			tst.l	d0
			beq.s	.Bad

			cmpi.l	#90,d0
			bls.s	.Skip

.Bad:			jsr	FlashScreen
			bra.s	.NoChange

.Skip:			move.w	d0,ArcPoints

.NoChange:		jsr	ClosePointsWindow

.Done:			jsr	OpenMenu

.ASkip:			tst.b	DrawMode
			bne.s	.DrawOn

			bsr	MakeDrawOn

			tst.b	DrawMode
			beq.l	Scope

			jsr	ResetAll

.DrawOn:		move.w	ArcPoints,d1
			tst.b	AutoPointsFlag
			beq.s	.ASkip4

			sub.l	d1,d1
			move.b	ArcSize,d1
			move.b	ArcSize2,d0

			cmp.b	d0,d1
			bhs.s	.ASkip2
			move.b	d0,d1

.ASkip2:		mulu	#503,d1
			divu	#320,d1
			mulu	AutoPoints,d1
			divu	#100,d1
			andi.l	#$ffff,d1
			bne.s	.ASkip3
			moveq	#1,d1
.ASkip3:		cmpi.w	#90,d1
			bls.s	.ASkip4
			move.w	#90,d1

.ASkip4:		move.w	d1,ArcPoints2

			sub.l	d2,d2			;X data
			move.b	ArcSize,d2

			lea	SineData,a0
			adda.w	ArcQuadrant,a0
			movea.l	XDataPtr,a1
			move.l	a1,XDataArcPtr
			move.l	a1,XDataLastPtr

			moveq	#90,d3
			divu	d1,d3
			lsl.w	#1,d3
			move.l	d3,d5
			swap	d5

			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints,a2
			suba.w	d1,a2
			cmpa.l	a1,a2
			bhi.s	.Skip2

			move.l	a1,d4
			move.l	a1,d7
			sub.l	a2,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a1
			lea	(a1,d7),a2
			sub.l	a2,d4
			subq.l	#1,d4

.Loop:			move.b	(a2)+,(a1)+
			dbf	d4,.Loop

.Skip2:			subq.w	#1,d1
			beq.s	.XDone

			move.w	d1,d7
			subq.w	#1,d1
			sub.l	d6,d6

			tst.b	ArcDirection2
			beq.s	.Loop2

			adda.w	#176,a0

.Loop2a:		move.w	(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	XArcPos3,d0
			move.b	d0,(a1)+
			suba.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkipa
			sub.w	d7,d6
			subq.l	#2,a0
.ESkipa:		dbf	d1,.Loop2a
			bra.s	.XDone

.Loop2:			move.w	(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	XArcPos3,d0
			move.b	d0,(a1)+
			adda.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip
			sub.w	d7,d6
			addq.l	#2,a0
.ESkip:			dbf	d1,.Loop2

.XDone:			move.b	XArcPos,(a1)+
			move.l	a1,XDataPtr

			move.w	ArcPoints2,d1		;Y data

			sub.l	d2,d2
			move.b	ArcSize2,d2

			lea	SineData,a0
			adda.w	ArcQuadrant,a0
			movea.l	YDataPtr,a1

			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2
			suba.w	d1,a2
			cmpa.l	a1,a2
			bhi.s	.Skip3

			move.l	a1,d4
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			lea	(a1,d7),a2
			sub.l	a2,d4
			subq.l	#1,d4

.Loop3:			move.b	(a2)+,(a1)+
			dbf	d4,.Loop3

.Skip3:			subq.w	#1,d1
			beq.s	.YDone

			move.w	d1,d7
			subq.w	#1,d1
			sub.l	d6,d6

			tst.b	ArcDirection2
			beq.s	.Loop4

			adda.w	#176,a0

.Loop4a:		move.w	180(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	YArcPos3,d0
			move.b	d0,(a1)+
			suba.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip2a
			sub.w	d7,d6
			subq.l	#2,a0
.ESkip2a:		dbf	d1,.Loop4a
			bra.s	.YDone

.Loop4:			move.w	180(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	YArcPos3,d0
			move.b	d0,(a1)+
			adda.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip2
			sub.w	d7,d6
			addq.l	#2,a0
.ESkip2:		dbf	d1,.Loop4

.YDone:			move.b	YArcPos,(a1)+
			move.l	a1,YDataPtr

			move.w	ArcPoints2,d0
			add.w	d0,DrawLen+2

			tst.b	D3Flag
			beq.s	.D3Skip

			movea.l	ZDataPtr,a0		;Z data

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			bne.s	.ZSkip

			sub.l	d0,d0
			bra.s	.ZSkip2

.ZSkip:			move.b	-1(a0),d0
.ZSkip2:		move.b	ZMousePos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1

			move.w	ArcPoints2,d2

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			suba.w	d2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip4

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop5:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop5

.Skip4:			bsr	CalcLine
			move.l	a0,ZDataPtr

.D3Skip:		bsr	GetDrawLen
			bsr	CheckDefault
			bsr	CheckFreq
			jsr	RestartSound

			move.l	XDataPtr,d0
			sub.l	XDataArcPtr,d0
			move.l	d0,XDataArcSize
			move.l	d0,XDataLastSize
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

.Abort2:		bsr	ArcOutlineOff
			move.b	XMousePos,XArcPos
			move.b	YMousePos,YArcPos
			clr.b	ZMousePos

			bsr	PrintArcStatus
			jmp	Scope

.Abort:			jsr	ClosePointsWindow
			jsr	OpenMenu
			bra.s	.Abort2

Box:			bsr	SeqStuffOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			bsr	ArcOff
			bsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			bchg	#0,BoxMode
			beq.s	.On

			bsr	BoxOutlineOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	BoxOffFlag
			clr.b	ZBoxPos

			movea.l	XDataPtr,a0
			cmpa.l	DrawMemPtr,a0
			beq.s	.Skip

			tst.b	DrawMode
			beq.s	.Skip

			move.b	-1(a0),XBoxPos
			move.b	-1(a0),XBoxPos2
			movea.l	YDataPtr,a0
			move.b	-1(a0),YBoxPos
			move.b	-1(a0),YBoxPos2
			bra.s	.Skip2

.Skip:			clr.b	XBoxPos
			clr.b	YBoxPos
			clr.b	XBoxPos2
			clr.b	YBoxPos2

.Skip2:			move.b	XBoxPos,XMousePos
			move.b	YBoxPos,YMousePos

			jsr	TopViewOff
			bsr	ShowPoints
			lea	StatusBox,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bsr	BoxOutlineOn
			jmp	Scope

BoxOff:			tst.b	BoxMode
			beq.s	.End
			clr.b	BoxMode
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	BoxOutlineOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

BoxPosOff:		tst.b	BoxOffFlag
			bne	BoxIt
			bsr	GetMousePos3D
			move.b	#1,BoxOffFlag
			move.b	ZMousePos,ZBoxPos
			bsr	BoxOutlineOff
			move.b	XMousePos3D,XBoxPos
			move.b	YMousePos3D,YBoxPos
			move.b	XMousePos,XBoxPos2
			move.b	YMousePos,YBoxPos2
			bsr	BoxOutlineOn
			bsr	ShowPXY
			jmp	Scope

BoxPos:			tst.b	BoxOffFlag
			beq.s	BoxPos2

			bsr	GetMousePos
			bsr.s	BoxOutlineOff
			move.b	XMousePos,XBoxPos2
			move.b	YMousePos,YBoxPos2
			bsr.s	BoxOutlineOn
			bsr	ShowPXY
			jmp	Scope

BoxPos2:		bsr	GetMousePos
			bsr.s	BoxOutlineOff
			move.b	XMousePos,XBoxPos
			move.b	YMousePos,YBoxPos
			move.b	XMousePos,XBoxPos2
			move.b	YMousePos,YBoxPos2
			bsr.s	BoxOutlineOn
			bsr	ShowPXY
			jmp	Scope

BoxOutlineFlash:	tst.b	BoxMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount
			blo.s	.End

			moveq	#2,d0
			bchg	#0,BoxFlag
			beq.s	BoxOutline
			moveq	#1,d0
			bra.s	BoxOutline

BoxOutlineOff:		tst.b	BoxFlag
			beq.s	.End
			clr.b	BoxFlag
			moveq	#1,d0
			bra.s	BoxOutline
.End:			rts

BoxOutlineOn:		move.b	#1,BoxFlag
			moveq	#2,d0

BoxOutline:		jsr	CheckDrawMode

			move.b	XBoxPos,d0
			bsr	CheckHiResX
			move.b	YBoxPos,d2
			bsr	CheckHiResY
			jsr	Move

			move.b	XBoxPos,d0
			bsr	CheckHiResX
			move.b	YBoxPos2,d2
			bsr	CheckHiResY
			jsr	Draw

			move.b	XBoxPos2,d0
			bsr	CheckHiResX
			move.b	YBoxPos2,d2
			bsr	CheckHiResY
			jsr	Draw

			move.b	XBoxPos2,d0
			bsr	CheckHiResX
			move.b	YBoxPos,d2
			bsr	CheckHiResY
			jsr	Draw

			move.b	XBoxPos,d0
			bsr	CheckHiResX
			move.b	YBoxPos,d2
			bsr	CheckHiResY
			jsr	Draw
			jsr	CheckDrawMode2
			clr.b	MiscCount
			rts

BoxIt:			bsr	GetMousePos
			bsr	MouseButtonOff

BoxIt2:			tst.b	AutoPointsFlag
			bne	.ASkip

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenPointsWindow
			tst.l	d0
			bne	.Done

			movea.l	PointsGadgets,a0
			move.w	BoxPoints,d0
			jsr	SetGadget

			movea.l	PointsGadgets,a0
			movea.l	PointsWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			jsr	ShortDelay

.Next:			movea.l	PointsWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	PointsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#5,d0
			bhs.s	.Skip

			jsr	FlashScreen
			bra.s	.NoChange

.Skip:			subq.w	#1,d0
			andi.w	#$fffc,d0
			addq.w	#1,d0
			move.w	d0,BoxPoints

.NoChange:		jsr	ClosePointsWindow

.Done:			jsr	OpenMenu

.ASkip:			tst.b	DrawMode
			bne.s	.DrawOn

			bsr	MakeDrawOn

			tst.b	DrawMode
			beq.l	Scope

			jsr	ResetAll

.DrawOn:		tst.b	AutoPointsFlag
			beq.s	.ASkip6

			move.b	XBoxPos,d0
			move.b	XMousePos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bpl.s	.ASkip2
			neg.w	d1

.ASkip2:		mulu	AutoPoints,d1
			divu	#100,d1
			andi.l	#$ffff,d1
			bne.s	.ASkip3
			moveq	#1,d1

.ASkip3:		move.w	d1,XBoxPoints

			move.b	YBoxPos,d0
			move.b	YMousePos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bpl.s	.ASkip4
			neg.w	d1

.ASkip4:		mulu	AutoPoints,d1
			divu	#100,d1
			andi.l	#$ffff,d1
			bne.s	.ASkip5
			moveq	#1,d1

.ASkip5:		move.w	d1,YBoxPoints
			add.w	d1,d1
			add.w	XBoxPoints,d1
			add.w	XBoxPoints,d1
			addq.w	#1,d1
			bra.s	.ASkip7

.ASkip6:		move.w	BoxPoints,d0
			move.w	d0,d1
			subq.w	#1,d0
			lsr.w	#2,d0
			move.w	d0,XBoxPoints
			move.w	d0,YBoxPoints

.ASkip7:		movea.l	XDataPtr,a0		;X Data
			move.l	a0,XDataBoxPtr
			move.l	a0,XDataLastPtr

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			suba.w	d1,a1
			cmpa.l	a0,a1
			bhi.s	.Skip2

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop

.Skip2:			move.b	XBoxPos,(a0)+

			move.w	XBoxPoints,d2
			move.b	XBoxPos,d0
			move.b	XMousePos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bsr	CalcLine

			move.w	YBoxPoints,d4
			subq.w	#1,d4

.Loop2:			move.b	XMousePos,(a0)+
			dbf	d4,.Loop2

			move.w	XBoxPoints,d2
			move.b	XMousePos,d0
			move.b	XBoxPos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bsr	CalcLine

			move.w	YBoxPoints,d4
			subq.w	#1,d4

.Loop3:			move.b	XBoxPos,(a0)+
			dbf	d4,.Loop3
			move.l	a0,XDataPtr

			move.w	XBoxPoints,d1		;Y data
			add.w	d1,d1
			add.w	YBoxPoints,d1
			add.w	YBoxPoints,d1
			addq.w	#1,d1
			add.w	d1,DrawLen+2

			movea.l	YDataPtr,a0
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			suba.w	d1,a1
			cmpa.l	a0,a1
			bhi.s	.Skip3

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop4:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop4

.Skip3:			move.b	YBoxPos,(a0)+

			move.w	XBoxPoints,d4
			subq.w	#1,d4

.Loop5:			move.b	YBoxPos,(a0)+
			dbf	d4,.Loop5

			move.w	YBoxPoints,d2
			move.b	YBoxPos,d0
			move.b	YMousePos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bsr	CalcLine

			move.w	XBoxPoints,d4
			subq.w	#1,d4

.Loop6:			move.b	YMousePos,(a0)+
			dbf	d4,.Loop6

			move.w	YBoxPoints,d2
			move.b	YMousePos,d0
			move.b	YBoxPos,d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1
			bsr	CalcLine

			move.l	a0,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip

			move.w	XBoxPoints,d1		;Z data
			add.w	d1,d1
			add.w	YBoxPoints,d1
			add.w	YBoxPoints,d1
			addq.w	#1,d1

			movea.l	ZDataPtr,a0
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			suba.w	d1,a1
			cmpa.l	a0,a1
			bhi.s	.Skip4

			move.l	a0,d3
			move.l	a0,d7
			sub.l	a1,d7

			movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			lea	(a0,d7),a1
			sub.l	a1,d3
			subq.l	#1,d3

.Loop7:			move.b	(a1)+,(a0)+
			dbf	d3,.Loop7

.Skip4:			move.b	ZBoxPos,(a0)+
			subq.w	#2,d1

.Loop8:			move.b	ZBoxPos,(a0)+
			dbf	d1,.Loop8
			move.l	a0,ZDataPtr

.D3Skip:		bsr	GetDrawLen
			bsr	CheckDefault
			bsr	CheckFreq
			jsr	RestartSound

			move.l	XDataPtr,d0
			sub.l	XDataBoxPtr,d0
			move.l	d0,XDataBoxSize
			move.l	d0,XDataLastSize
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

.Abort2:		bsr	BoxOutlineOff
			clr.b	BoxOffFlag
			move.b	XMousePos,XBoxPos
			move.b	YMousePos,YBoxPos
			move.b	XMousePos,XBoxPos2
			move.b	YMousePos,YBoxPos2
			clr.b	ZBoxPos

			bsr	ShowPoints
			lea	StatusBox,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			jmp	Scope

.Abort:			jsr	ClosePointsWindow
			jsr	OpenMenu
			bra.s	.Abort2

Ellipse:		bsr	SeqStuffOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			bsr	ArcOff
			bsr	BoxOff
			clr.b	MergeMode
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			bchg	#0,EllipseMode
			beq.s	.On

			clr.b	EllipseFlag2
			bsr	EllipseOutlineOff
			lea	StatusBlank,a0
			jsr	PrintStatus
			jmp	Scope

.On:			jsr	CheckCenter
			bsr	TurnItOff2
			clr.b	EllipseOffFlag
			clr.b	XEllipsePos
			clr.b	YEllipsePos
			clr.b	ZEllipsePos
			move.b	#50,EllipseSize
			move.b	#50,EllipseSize2
			clr.b	XMousePos
			clr.b	YMousePos

			bsr	TopViewOff
			bsr	ShowPoints
			lea	StatusEllipse,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
			bsr	EllipseOutlineOn
			jmp	Scope

EllipseOff:		tst.b	EllipseMode
			beq.s	.End
			clr.b	EllipseMode
			clr.b	EllipseFlag2
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	EllipseOutlineOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

EllipsePosOff:		tst.b	EllipseOffFlag
			bne	EllipseIt
			bsr	GetMousePos3D
			move.b	ZMousePos,ZEllipsePos
			move.b	XMousePos3D,XMousePosTemp2
			move.b	YMousePos3D,YMousePosTemp2
			bsr.s	EllipsePos2
			move.b	#1,EllipseOffFlag
			jmp	Scope

EllipsePos:		bsr	GetMousePos
			move.b	XMousePos,XMousePosTemp2
			move.b	YMousePos,YMousePosTemp2
			move.b	#1,EllipseFlag2
			jmp	Scope

EllipsePos2:		clr.b	EllipseFlag2

			tst.b	EllipseOffFlag
			beq	EllipsePos3

			move.b	XEllipsePos,d2
			ext.w	d2
			move.b	XMousePosTemp2,d1
			ext.w	d1
			sub.w	d2,d1
			bpl.s	.Skip
			neg.w	d1

.Skip:			move.b	YEllipsePos,d4
			ext.w	d4
			move.b	YMousePosTemp2,d3
			ext.w	d3
			sub.w	d4,d3
			bpl.s	.Skip2
			neg.w	d3

.Skip2:			cmpi.b	#127,d1
			bls.s	.Skip3
			move.b	#127,d1

.Skip3:			cmpi.b	#2,d1
			bhs.s	.Skip4
			move.b	#2,d1

.Skip4:			cmpi.b	#127,d3
			bls.s	.Skip5
			move.b	#127,d3

.Skip5:			cmpi.b	#2,d3
			bhs.s	.Skip6
			move.b	#2,d3

.Skip6:			sub.l	d2,d2
			sub.b	d1,d2

			sub.l	d4,d4
			sub.b	d3,d4

			move.b	#127,d0
			sub.b	XEllipsePos,d0
			cmp.b	d1,d0
			bhs.s	.Skip7
			move.b	d0,d1

.Skip7:			move.b	#127,d0
			sub.b	YEllipsePos,d0
			cmp.b	d3,d0
			bhs.s	.Skip8
			move.b	d0,d3

.Skip8:			move.b	#-127,d0
			sub.b	XEllipsePos,d0
			cmp.b	d2,d0
			bls.s	.Skip9
			move.b	d0,d2

.Skip9:			move.b	#-127,d0
			sub.b	YEllipsePos,d0
			cmp.b	d4,d0
			bls.s	.Skip10
			move.b	d0,d4

.Skip10:		neg.b	d2
			cmp.b	d1,d2
			bls.s	.Skip11
			move.b	d1,d2

.Skip11:		neg.b	d4
			cmp.b	d3,d4
			bls.s	.Skip12
			move.b	d3,d4

.Skip12:		cmp.b	EllipseSize,d2
			bne.s	.Skip13

			cmp.b	EllipseSize2,d4
			beq.s	.Skip14

.Skip13:		move.l	d2,-(sp)
			move.l	d4,-(sp)
			bsr	EllipseOutlineOff
			move.l	(sp)+,d1
			move.l	(sp)+,d0
			move.b	d0,EllipseSize
			move.b	d1,EllipseSize2
			bsr	EllipseOutlineOn

.Skip14:		bsr	PrintEllipseInfo
			clr.b	MiscCount
			rts

EllipsePos3:		move.b	XMousePosTemp2,d0
			addi.b	#127,d0
			cmpi.b	#252,d0
			bhi	.End
			cmpi.b	#2,d0
			blo	.End

			move.b	YMousePosTemp2,d0
			addi.b	#127,d0
			cmpi.b	#252,d0
			bhi	.End
			cmpi.b	#2,d0
			blo	.End

			move.b	EllipseSize,d1
			sub.l	d2,d2
			sub.b	d1,d2

			move.b	EllipseSize2,d3
			sub.l	d4,d4
			sub.b	d3,d4

			move.b	#127,d0
			sub.b	XMousePosTemp2,d0
			cmp.b	d1,d0
			bhs.s	.Skip
			move.b	d0,d1

.Skip:			move.b	#127,d0
			sub.b	YMousePosTemp2,d0
			cmp.b	d3,d0
			bhs.s	.Skip2
			move.b	d0,d3

.Skip2:			move.b	#-127,d0
			sub.b	XMousePosTemp2,d0
			cmp.b	d2,d0
			bls.s	.Skip3
			move.b	d0,d2

.Skip3:			move.b	#-127,d0
			sub.b	YMousePosTemp2,d0
			cmp.b	d4,d0
			bls.s	.Skip4
			move.b	d0,d4

.Skip4:			neg.b	d2
			cmp.b	d1,d2
			bls.s	.Skip5
			move.b	d1,d2

.Skip5:			neg.b	d4
			cmp.b	d3,d4
			bls.s	.Skip6
			move.b	d3,d4

.Skip6:			move.l	d2,-(sp)
			move.l	d4,-(sp)
			bsr.s	EllipseOutlineOff
			move.l	(sp)+,d1
			move.l	(sp)+,d0
			move.b	d0,EllipseSize
			move.b	d1,EllipseSize2
			move.b	XMousePosTemp2,XEllipsePos
			move.b	YMousePosTemp2,YEllipsePos
			bsr.s	EllipseOutlineOn
			bsr	PrintEllipseInfo
.End:			clr.b	MiscCount
			rts

EllipseOutlineFlash:	tst.b	EllipseMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount
			blo.s	.End

			tst.b	EllipseFlag2
			bne	EllipsePos2

			moveq	#2,d0
			bchg	#0,EllipseFlag
			beq.s	EllipseOutline
			moveq	#1,d0
			bra.s	EllipseOutline

EllipseOutlineOff:	tst.b	EllipseFlag
			beq.s	.End
			clr.b	EllipseFlag
			moveq	#1,d0
			bra.s	EllipseOutline
.End:			rts

EllipseOutlineOn:	move.b	#1,EllipseFlag
			moveq	#2,d0

EllipseOutline:		bsr	CheckDrawMode

			move.b	XEllipsePos,d0
			move.b	YEllipsePos,d4

			sub.l	d2,d2
			move.b	EllipseSize,d2

			sub.l	d3,d3
			move.b	EllipseSize2,d3

			bsr.s	CalcEllipseData

			movea.l	RastPortPtr,a1
			movea.l	GfxBase,a6
			jsr	_LVODrawEllipse(a6)

			move.b	XEllipsePos,d0		;Center dot
			bsr	CheckHiResX
			move.b	YEllipsePos,d2
			bsr	CheckHiResY
			jsr	Pixel
			bsr	CheckDrawMode2
			clr.b	MiscCount
			rts

CalcEllipseData:	tst.b	DrawMode
			beq.s	.Skip
			tst.b	DrawScopeFlag
			bne.s	.Skip
			tst.b	HiResFlag
			beq.s	.Skip

			ext.w	d0
			ext.l	d0
			divs	#2,d0

			ext.w	d4
			ext.l	d4
			divs	#2,d4

			addq.b	#1,d2
			lsr.b	#1,d2

			addq.b	#1,d3
			lsr.b	#1,d3

.Skip:			addi.b	#127,d0
			andi.l	#$ff,d0
			addi.w	#ScopeX+4,d0

			addi.b	#127,d4
			andi.l	#$ff,d4

			tst.b	BigScreenFlag
			beq.s	.Skip2
			move.w	#ScopeY+129+127,d1
			bra.s	.Skip3

.Skip2:			addq.b	#1,d3
			lsr.b	#1,d3

			addq.b	#1,d4
			lsr.b	#1,d4
			move.w	#ScopeY+129,d1

.Skip3:			sub.w	d4,d1
			rts

PrintEllipseInfo:	tst.l	StatusCount
			bpl	.End

			move.l	#-1,StatusCount

			bsr	ShowPoints
			lea	EllipsePosText,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	XEllipsePos,d0
			bsr	ConvertCordinate

			lea	EllipseSizeText,a0
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.b	EllipseSize,d0

			move.l	#SerialNumber+1,d1	;Serial number!

			jsr	HEXtoASCII

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			lea	EllipsePosText3,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	YEllipsePos,d0
			neg.b	d0
			bsr	ConvertCordinate
			bra.s	.TSkip2

.TSkip:			lea	EllipsePosText2,a0
			jsr	MoveString
			lea	-1(a1),a0
			move.b	YEllipsePos,d0
			bsr	ConvertCordinate

.TSkip2:		lea	EllipseSizeText,a0
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.b	EllipseSize2,d0
			jsr	HEXtoASCII

			lea	ASCIIBuffer,a0
			jsr	PrintStatus3
.End:			rts

EllipseIt:		bsr	GetMousePos
			move.b	XMousePos,XMousePosTemp2
			move.b	YMousePos,YMousePosTemp2
			bsr	EllipsePos2
			bsr	MouseButtonOff

EllipseIt2:		tst.b	AutoPointsFlag
			bne	.ASkip

			jsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenPointsWindow
			tst.l	d0
			bne	.Done

			movea.l	PointsGadgets,a0
			move.w	EllipsePoints,d0
			jsr	SetGadget

			movea.l	PointsGadgets,a0
			movea.l	PointsWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			jsr	ShortDelay

.Next:			movea.l	PointsWnd,a0
			jsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	PointsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#1,d0
			bls.s	.Bad

			cmpi.l	#361,d0
			bls.s	.Skip

.Bad:			jsr	FlashScreen
			bra.s	.NoChange

.Skip:			move.w	d0,EllipsePoints

.NoChange:		jsr	ClosePointsWindow

.Done:			jsr	OpenMenu

.ASkip:			tst.b	DrawMode
			bne.s	.DrawOn

			bsr	MakeDrawOn

			tst.b	DrawMode
			beq	.Scope

			jsr	ResetAll

.DrawOn:		move.w	EllipsePoints,d1
			tst.b	AutoPointsFlag
			beq.s	.ASkip4

			sub.l	d1,d1
			move.b	EllipseSize,d1
			move.b	EllipseSize2,d0

			cmp.b	d0,d1
			bhs.s	.ASkip2
			move.b	d0,d1

.ASkip2:		mulu	#503,d1
			divu	#80,d1
			mulu	AutoPoints,d1
			divu	#100,d1
			andi.l	#$ffff,d1
			bne.s	.ASkip3
			moveq	#1,d1
.ASkip3:		addq.w	#1,d1
			cmpi.w	#361,d1
			bls.s	.ASkip4
			move.w	#361,d1

.ASkip4:		move.w	d1,EllipsePoints2
			subq.w	#1,d1

			sub.l	d2,d2			;X data
			move.b	EllipseSize,d2

			lea	SineData,a0
			movea.l	XDataPtr,a1
			move.l	a1,XDataEllipsePtr
			move.l	a1,XDataLastPtr

			move.l	#360,d3
			divu	d1,d3
			lsl.w	#1,d3
			move.l	d3,d5
			swap	d5

			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints,a2
			suba.w	EllipsePoints2,a2
			cmpa.l	a1,a2
			bhi.s	.Skip2

			move.l	a1,d4
			move.l	a1,d7
			sub.l	a2,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a1
			lea	(a1,d7),a2
			sub.l	a2,d4
			subq.l	#1,d4

.Loop:			move.b	(a2)+,(a1)+
			dbf	d4,.Loop

.Skip2:			movea.l	a1,a2
			move.w	d1,d7
			subq.w	#1,d1
			sub.l	d6,d6

.Loop2:			move.w	(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	XEllipsePos,d0
			move.b	d0,(a1)+
			adda.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip
			sub.w	d7,d6
			addq.l	#2,a0
.ESkip:			dbf	d1,.Loop2

			move.b	(a2),(a1)+		;Copy first
			move.l	a1,XDataPtr

			move.w	EllipsePoints2,d1	;Y data
			subq.w	#1,d1

			sub.l	d2,d2
			move.b	EllipseSize2,d2

			lea	SineData,a0
			movea.l	YDataPtr,a1

			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2
			suba.w	EllipsePoints2,a2
			cmpa.l	a1,a2
			bhi.s	.Skip3

			move.l	a1,d4
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			lea	(a1,d7),a2
			sub.l	a2,d4
			subq.l	#1,d4

.Loop3:			move.b	(a2)+,(a1)+
			dbf	d4,.Loop3

.Skip3:			movea.l	a1,a2
			move.w	d1,d7
			subq.w	#1,d1
			sub.l	d6,d6

.Loop4:			move.w	180(a0),d0
			muls	d2,d0
			divs	#32767,d0
			bsr	RoundOff
			add.b	YEllipsePos,d0
			move.b	d0,(a1)+
			adda.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip2
			sub.w	d7,d6
			addq.l	#2,a0
.ESkip2:		dbf	d1,.Loop4

			move.b	(a2),(a1)+		;Copy first
			move.l	a1,YDataPtr

			addq.w	#1,d7
			add.w	d7,DrawLen+2

			tst.b	D3Flag
			beq.s	.D3Skip

			move.w	EllipsePoints2,d1	;Z data
			subq.w	#1,d1

			movea.l	ZDataPtr,a1
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*3,a2
			suba.w	EllipsePoints2,a2
			cmpa.l	a1,a2
			bhi.s	.Loop6

			move.l	a1,d4
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			lea	(a1,d7),a2
			sub.l	a2,d4
			subq.l	#1,d4

.Loop5:			move.b	(a2)+,(a1)+
			dbf	d4,.Loop5

.Loop6:			move.b	ZEllipsePos,(a1)+
			dbf	d1,.Loop6
			move.l	a1,ZDataPtr

.D3Skip:		bsr	GetDrawLen
			bsr	CheckDefault
			bsr	CheckFreq
			jsr	RestartSound

			move.l	XDataPtr,d0
			sub.l	XDataEllipsePtr,d0
			move.l	d0,XDataEllipseSize
			move.l	d0,XDataLastSize
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

.Abort2:		bsr	EllipseOutlineOff
			clr.b	EllipseOffFlag
			clr.b	XEllipsePos
			clr.b	YEllipsePos
			clr.b	ZEllipsePos
			clr.b	XMousePos
			clr.b	YMousePos

			bsr	ShowPoints
			lea	StatusEllipse,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus
.Scope:			jmp	Scope

.Abort:			jsr	ClosePointsWindow
			jsr	OpenMenu
			bra.s	.Abort2

RoundOff:		move.l	d0,d4
			swap	d4
			bmi.s	.ROff

			cmpi.w	#16384,d4
			blo.s	.REnd
			addq.b	#1,d0
			rts

.ROff:			cmpi.w	#-16384,d4
			bhi.s	.REnd
			tst.w	d4
			beq.s	.REnd
			subq.b	#1,d0
.REnd:			rts

LoadScreen:		clr.b	MergeMode

LoadScreen2:		jsr	MoreOff
			clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			bsr	ArcOff
			bsr	BoxOff
			bsr	EllipseOff
			clr.b	LastFlag
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			lea	Filename3,a0
			lea	Dir2,a1

			lea	LoadReqText,a2
			tst.b	MergeMode
			beq.s	.MergSkip
			lea	MergeReqText,a2

.MergSkip:		jsr	ReqFile
			beq.l	Error3

			cmpi.b	#1,d0
			beq	.Scope

			bsr	RecordUpdate
			clr.b	RecordStatus

			lea	StatusLoad2,a0
			jsr	PrintStatus

			lea	Filename3,a0
			jsr	MakeFileName2

			jsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq.l	Error4

			movea.l	FileMemPtr,a1		;Screen?
			lea	ScreenString,a0
			jsr	CmpString
			bne	.Screen

			tst.b	MergeMode
			bne	.MergeUnknown

			lea	PackString,a0		;Pack?
			jsr	CmpString
			bne	.Pack

			adda.w	#34,a1			;Font?
			lea	FontString,a0
			jsr	CmpString
			bne	.Font
			suba.w	#34,a1

			lea	FireFlyString,a0	;FireFly?
			jsr	CmpString
			bne	.FireFlyPack

			lea	FireFlyString2,a0
			jsr	CmpString
			bne	.FireFlyImage

			lea	ScanPicString,a0	;ScanPlus?
			jsr	CmpString
			bne	.ScanPlus

			lea	ILDAFrameString,a0	;ILDA?
			jsr	CmpString
			bne	.ILDA

			lea	LD400FrameString,a0	;LD400?
			jsr	CmpString
			bne	.LD400

			lea	LDProFrameString,a0	;LDPro?
			jsr	CmpString
			bne	.LDPro

			sub.l	d0,d0			;Aquarius?
			move.b	(a1),d0
			sub.l	d1,d1
			move.b	1(a1),d1
			lsl.w	#8,d1
			or.w	d0,d1
			move.l	d1,d0
			lsl.l	#2,d1
			addq.l	#4,d1
			cmp.l	FileMemSize,d1
			bne.s	.SSkip

			movea.l	a1,a0
			adda.l	FileMemSize,a0
			tst.w	-2(a0)
			beq	.Aquarius

.SSkip:			lea	Filename3,a0		;Aura?

.NameLoop:		tst.b	(a0)+
			bne.s	.NameLoop

			subq.l	#5,a0
			cmpa.l	#Filename3,a0
			blo.s	.TryX29

			cmpi.b	#".",(a0)+
			bne.s	.TryX29
			move.b	(a0)+,d0
			jsr	UpperByte
			cmpi.b	#"D",d0
			bne.s	.TryX29
			move.b	(a0)+,d0
			jsr	UpperByte
			cmpi.b	#"E",d0
			bne.s	.TryX29
			cmpi.b	#"3",(a0)+
			bne.s	.TryX29

			move.l	FileMemSize,d0
			andi.l	#$3,d0
			beq	.Aura

.TryX29:		cmpi.w	#$3200,(a1)		;X29?
			beq	.X29

			bra	.LSD1000		;LSD1000?

.MergeUnknown:		jsr	FreeFileMem
			jmp	Error17

.Unknown:		jsr	FreeFileMem
			jsr	FlashScreen
			lea	Error28Text,a0
			jsr	PrintStatus
			jmp	Scope

.Screen:		tst.b	DrawMode		;* LASERMAX screen *
			beq.s	.MSkip

			tst.b	MergeMode
			bne	.MergeIt

.MSkip:			movea.l	FileMemPtr,a0
			bsr	MakeScreen
			jsr	FreeFileMem

			tst.b	DrawMode
			beq	.Scope

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady2,a0
			jsr	PrintStatus
			bra	.Scope

.Pack:			move.w	20(a1),PackCount	;* LASERMAX pack *
			adda.w	#22,a1
			move.l	a1,PackPtr

			cmpi.w	#1,PackCount
			beq.s	.PNext

			clr.b	AutoSeqFlag
			clr.w	PackCount2

			lea	SureTitle7,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	PackCount,d0
			jsr	HEXtoASCII
			lea	SureTitle7a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.PNext

			move.w	#1,PackCount

.PNext:			movea.l	PackPtr,a1
			adda.w	#42,a1
			movea.l	FileMemPtr,a0
			adda.l	FileMemSize,a0
			cmpa.l	a1,a0
			bls	.Unknown

			lea	ScreenString,a0
			jsr	CmpString
			beq	.Unknown

			movea.l	PackPtr,a0
			adda.w	#42,a0
			bsr	MakeScreen

			tst.b	DrawMode
			beq	.PDone

			movea.l	PackPtr,a0
			lea	Filename4,a1
			jsr	MoveString

			cmpi.w	#1,PackCount
			beq	.PDone

			addq.w	#1,PackCount2

			lea	StatusSave3c,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename4,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			jsr	PrintStatus

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.PError

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.PError2

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.PError2

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.PError2

			tst.b	D3Flag			;2D or 3D?
			beq.s	.P3DSkip

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.PError2

.P3DSkip:		jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.PSkip

			move.w	PackCount2,d0
			cmpi.w	#40,d0
			bhi.s	.PSkip

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.PSkip:			move.w	PackCount2,d0
			cmp.w	PackCount,d0
			beq.s	.PDone

			movea.l	PackPtr,a0
			move.l	88(a0),d0
			add.l	92(a0),d0

			tst.b	D3Flag
			beq.s	.P3DSkip2
			add.l	88(a0),d0

.P3DSkip2:		adda.l	d0,a0
			adda.w	#104,a0
			move.l	a0,PackPtr
			bra	.PNext

.PDone:			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.PScope

			lea	StatusReady2,a0
			jsr	PrintStatus
.PScope:		jmp	Scope

.PError2:		jsr	CloseFile
.PError:		jsr	FreeFileMem
			jmp	Error5

.Font:			lea	Filename3,a0
			lea	Filename5,a1
			jsr	MoveString

			bsr	FreeFontMem
			move.l	FileMemPtr,FontPtr
			move.l	FileMemSize,FontSize
			clr.l	FileMemSize

			lea	StatusReady3,a0
			jsr	PrintStatus
			bra	.Scope

.FireFlyImage:		adda.w	#12,a1			;Skip header
			bra.s	.GetPic

.FireFlyPack:		adda.l	8(a1),a1		;Skip script stuff
			adda.w	#16,a1

.GetPic:		move.l	a1,FireFlyPtr		;* FireFly format *

			move.l	#(2*MaxPoints)+62,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,FireFlyMemPtr
			beq	.Error3

			movea.l	FireFlyPtr,a0		;Get pic count
			move.w	(a0)+,PicCount
			beq	.Error

			move.l	a0,FireFlyPtr

			cmpi.w	#1,PicCount
			beq.s	.NextPic

			clr.b	AutoSeqFlag
			clr.w	PicCount2

			lea	SureTitle3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	PicCount,d0
			jsr	HEXtoASCII
			lea	SureTitle3a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.NextPic

			move.w	#1,PicCount

.NextPic:		movea.l	FireFlyPtr,a0
			move.w	(a0)+,d0		;Period
			cmpi.w	#124,d0
			blo	.Error

			move.w	(a0)+,d1		;# of regions
			cmpi.w	#1,d1
			bne	.Error4

			sub.l	d2,d2			;# of points
			move.w	(a0)+,d2
			beq	.Error
			cmpi.w	#MaxPoints,d2
			bhi	.Error5

			move.l	#35795465,d3		;Calc frequency
			move.w	d0,d1
			mulu	d2,d1
			divu.l	d1,d3

			move.l	a0,-(sp)
			lea	ScreenHeader,a0
			movea.l	FireFlyMemPtr,a1
			jsr	MoveString
			movea.l	(sp)+,a0

			move.w	#2,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	d3,(a1)+
			move.w	d3,(a1)+
			move.w	d3,(a1)+
			move.w	d3,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			lsl.l	#1,d2
			subq.l	#1,d2

.Loop:			move.b	(a0)+,(a1)		;X/Y data
			neg.b	(a1)+
			dbf	d2,.Loop

			addq.l	#4,a0
			move.l	a0,FireFlyPtr

			movea.l	FireFlyMemPtr,a0
			bsr	MakeScreen

			tst.b	DrawMode
			beq	.Skip

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			cmpi.w	#1,PicCount
			beq	.Skip

			addq.w	#1,PicCount2

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	PicCount2,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			jsr	PrintStatus

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	PicCount2,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error6

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error7

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error7

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error7

			jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip

			move.w	PicCount2,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip:		move.w	PicCount2,d0
			cmp.w	PicCount,d0
			bne	.NextPic

.Skip:			bsr.s	.FreeMem
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope

			lea	StatusReady4,a0
			jsr	PrintStatus
.Scope:			jmp	Scope

.Error:			bsr.s	.FreeMem
			bra	.Unknown

.Error3:		jsr	FreeFileMem
			jmp	Error3

.Error4:		bsr.s	.FreeMem
			jsr	FreeFileMem
			jsr	FlashScreen
			lea	Error21Text,a0
			jsr	PrintStatus
			jmp	Scope

.Error5:		bsr.s	.FreeMem
			jsr	FreeFileMem
			jmp	Error22

.Error7:		jsr	CloseFile

.Error6:		bsr.s	.FreeMem
			jsr	FreeFileMem
			jmp	Error5

.FreeMem:		movea.l	FireFlyMemPtr,a1
			move.l	#(2*MaxPoints)+62,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.Aquarius:		cmpi.l	#MaxPoints,d0		;* Aquarius format *
			bhi	.Unknown

			tst.l	d0
			beq	.Unknown

			move.l	a1,-(sp)
			lsl.l	#1,d0
			addi.l	#62,d0
			move.l	d0,AquariusSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			movea.l	(sp)+,a0
			move.l	d0,AquariusMemPtr
			beq	.Error3

			move.l	a0,-(sp)
			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString
			movea.l	(sp)+,a0

			sub.l	d0,d0			;Get X & Y size
			move.b	(a0)+,d0
			sub.l	d2,d2
			move.b	(a0)+,d2
			lsl.w	#8,d2
			or.w	d0,d2

			move.w	#2,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2

			subq.l	#1,d2

.QLoop:			move.b	(a0)+,d0		:Get X
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			divs	#16,d1
			move.b	d1,(a1)+

			move.b	(a0)+,d0		;Get Y
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			divs	#16,d1
			move.b	d1,(a2)+
			dbf	d2,.QLoop

			movea.l	AquariusMemPtr,a0
			bsr	MakeScreen
			bsr.s	.FreeMem2
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope2

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady4a,a0
			jsr	PrintStatus
.Scope2:		jmp	Scope

.FreeMem2:		movea.l	AquariusMemPtr,a1
			move.l	AquariusSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.ScanPlus:		move.l	FileMemSize,d0		;* ScanPlus format *
			divu	#14,d0
			cmpi.w	#2,d0
			blo	.Unknown
			swap	d0
			tst.w	d0
			bne	.Unknown

			cmpi.w	#$0d1a,12(a1)
			bne	.Unknown

			move.l	a1,-(sp)
			move.l	#(MaxPoints*3)+62,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			movea.l	(sp)+,a0
			move.l	d0,ScanMemPtr
			beq	.Error3

			move.l	a0,-(sp)
			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString
			movea.l	(sp)+,a0

			move.w	#$000a,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#160,(a1)+
			move.w	#160,(a1)+
			move.w	#160,(a1)+
			move.w	#160,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	#2,(a1)+
			move.l	#2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			move.l	FileMemSize,d0		;Get # X, Y & Z vectors
			divu	#14,d0
			subq.w	#2,d0

			lea	14(a0),a2
			movea.l	a1,a3
			movea.l	a1,a4
			adda.w	#MaxPoints,a4
			movea.l	a4,a5
			adda.w	#MaxPoints,a5
			move.l	a5,ScanMax

			move.b	(a2),(a3)+		;First X
			move.b	2(a2),(a4)		;First Y
			neg.b	(a4)+
			move.b	4(a2),(a5)+		;First Z

			move.b	(a2),(a3)+		;First X *2
			move.b	2(a2),(a4)		;First Y *2
			neg.b	(a4)+
			move.b	4(a2),(a5)+		;First Z *2

.ScLoop:		move.l	d0,-(sp)

			move.b	(a2),d0			;Get X
			move.b	6(a2),d1
			ext.w	d0
			ext.w	d1
			sub.w	d0,d1

			move.b	2(a2),d2		;Get Y
			move.b	8(a2),d3
			ext.w	d2
			neg.w	d2
			ext.w	d3
			neg.w	d3
			sub.w	d2,d3

			move.b	4(a2),d4		;Get Z
			move.b	10(a2),d5
			ext.w	d4
			ext.w	d5
			sub.w	d4,d5

			cmp.b	-1(a3),d0		;Same as last?
			bne.s	.ScSkip

			cmp.b	-1(a4),d2
			bne.s	.ScSkip

			cmp.b	-1(a5),d4
			beq.s	.ScSkip2

.ScSkip:		move.b	d0,(a3)+		;First X
			move.b	d2,(a4)+		;First Y
			move.b	d4,(a5)+		;First Z

			move.b	d0,(a3)+		;First X *2
			move.b	d2,(a4)+		;First Y *2
			move.b	d4,(a5)+		;First Z *2

.ScSkip2:		move.l	d4,-(sp)
			move.l	d5,-(sp)

			move.l	d2,-(sp)
			move.l	d3,-(sp)

			move.l	d0,-(sp)
			move.l	d1,-(sp)

			muls	d1,d1
			muls	d3,d3
			add.l	d3,d1
			move.l	d1,d0
			jsr	GetSqrRoot

			move.l	d0,d2
			mulu	AutoPoints,d2
			divu	#100,d2
			andi.l	#$ffff,d2
			bne.s	.ScSkip3
			moveq	#1,d2

.ScSkip3:		move.l	(sp)+,d1
			move.l	(sp)+,d0

			movea.l	a3,a0
			bsr	CalcLine
			movea.l	a0,a3

			move.l	(sp)+,d1
			move.l	(sp)+,d0

			movea.l	a4,a0
			bsr	CalcLine
			movea.l	a0,a4

			move.l	(sp)+,d1
			move.l	(sp)+,d0

			cmpa.l	ScanMax,a4
			bhs.s	.Error8

			movea.l	a5,a0
			bsr	CalcLine
			movea.l	a0,a5

			adda.w	#14,a2

			move.l	(sp)+,d0
			dbf	d0,.ScLoop

			movea.l	ScanMemPtr,a0
			movea.l	a0,a1
			adda.w	#MaxPoints+62,a0
			movea.l	a0,a2
			adda.w	#MaxPoints,a2
			suba.l	a0,a4
			move.l	a4,d0
			move.l	d0,46(a1)
			move.l	d0,50(a1)
			subq.l	#1,d0
			move.l	d0,d1

.ScLoop2:		move.b	(a0)+,(a3)+
			dbf	d0,.ScLoop2

.ScLoop3:		move.b	(a2)+,(a3)+
			dbf	d1,.ScLoop3

			movea.l	ScanMemPtr,a0
			bsr	MakeScreen
			bsr.s	.FreeMem3
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope3

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady4b,a0
			jsr	PrintStatus
.Scope3:		jmp	Scope

.Error8:		addq.l	#4,sp
			bsr.s	.FreeMem3
			jsr	FreeFileMem
			jmp	Error22

.FreeMem3:		movea.l	ScanMemPtr,a1
			move.l	#(MaxPoints*3)+62,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.LSD1000:		movea.l	a1,a0			;* LSD1000 format *
			adda.l	FileMemSize,a1

			bsr	.GetLSValue		;Get # of channels
			bmi	.Unknown

			move.w	d0,LSDChannels		;or ID?

			cmpi.l	#2,d0
			beq.s	.LSDSkip

			cmpi.l	#12,d0
			beq.s	.LSDSkip
			bra	.Unknown

.LSDSkip:		bsr	.GetLSValue		;Get # of frames
			bmi	.Unknown
			cmpi.l	#10000,d0		;My maximum
			bhi	.Unknown
			move.w	d0,LSDFrameCount
			move.w	d0,LSDFrameCount2
			beq	.Unknown

			bsr	.GetLSValue		;Get # of points
			bmi	.Unknown
			cmpi.l	#MaxPoints,d0
			bhi	.Unknown
			move.l	d0,LSDPoints
			beq	.Unknown

			move.l	a0,LSDDataPtr
			move.l	a1,LSDDataPtr2

			lsl.l	#1,d0			;Allocate mem
			addi.l	#62,d0
			move.l	d0,LSDMemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,LSDMemPtr
			beq	.Error3

			clr.b	LSDSaveFlag
			cmpi.w	#1,LSDFrameCount
			beq.s	.LSDSkip2

			clr.b	AutoSeqFlag
			move.b	#1,LSDSaveFlag
			move.w	#1,LSDFrameCount

			lea	SureTitle5,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LSDFrameCount2,d0
			jsr	HEXtoASCII
			lea	SureTitle5a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.LSDSkip2

			clr.b	LSDSaveFlag

.LSDSkip2:		movea.l	LSDDataPtr,a0		;Find data start
			movea.l	LSDDataPtr2,a1
			move.w	LSDFrameCount2,d0
			subq.w	#1,d0

.LSDLoop:		move.l	d0,-(sp)

			bsr	.GetLSValue		;Get X period
			bmi	.Unknown2
			cmpi.l	#65524,d0
			bhi	.Unknown2
			cmpi.l	#124,d0
			blo	.Unknown2

			bsr	.GetLSValue		;Get Y period
			bmi	.Unknown2
			cmpi.l	#65524,d0
			bhi	.Unknown2
			cmpi.l	#124,d0
			blo	.Unknown2

			move.l	(sp)+,d0
			dbf	d0,.LSDLoop
			move.l	a0,LSDDataPtr3

.LSDNext:		movea.l	LSDDataPtr,a0
			movea.l	LSDDataPtr2,a1
			move.w	LSDFrameCount,d0
			subq.w	#1,d0

.LSDLoop2:		move.l	d0,-(sp)

			bsr	.GetLSValue		;Get X period
			move.w	d0,LSDXPeriod

			bsr	.GetLSValue		;Get Y period
			move.w	d0,LSDYPeriod

			move.l	(sp)+,d0
			dbf	d0,.LSDLoop2

			lea	ScreenHeader,a0		;Create LASERMAX scn
			movea.l	LSDMemPtr,a1
			jsr	MoveString

			move.l	#35795465,d0		;Calc X Frequency
			move.w	LSDXPeriod,d2
			mulu	LSDPoints+2,d2
			divu.l	d2,d0

			move.l	#35795465,d1		;Calc Y Frequency
			move.w	LSDYPeriod,d2
			mulu	LSDPoints+2,d2
			divu.l	d2,d1

			move.w	#2,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	d0,(a1)+
			move.w	d1,(a1)+
			move.w	d1,(a1)+
			move.w	d0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	LSDPoints,(a1)+
			move.l	LSDPoints,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	LSDDataPtr3,a0
			move.l	LSDPoints,d0
			subq.l	#1,d0

			cmpi.w	#2,LSDChannels
			beq.s	.Old

			move.l	d0,d1

			move.w	LSDFrameCount,d2	;Point to start
			subq.w	#1,d2
			move.l	LSDPoints,d3
			mulu	d3,d2
			adda.l	d2,a0
			movea.l	a0,a2

			move.w	LSDFrameCount2,d2
			mulu	d3,d2
			adda.l	d2,a2

.LSDLoop3:		move.b	(a0)+,d2		;Get X
			addq.b	#1,d2
			cmpi.b	#$80,d2
			bne.s	.OSkip
			move.b	#$7f,d2
.OSkip:			neg.b	d2
			move.b	d2,(a1)+
			dbf	d0,.LSDLoop3

.LSDLoop4:		move.b	(a2)+,d2		;Get Y
			addq.b	#1,d2
			cmpi.b	#$80,d2
			bne.s	.OSkip2
			move.b	#$7f,d2
.OSkip2:		move.b	d2,(a1)+
			dbf	d1,.LSDLoop4
			bra.s	.LSDMake

.Old:			move.w	LSDFrameCount,d2	;Point to start
			subq.w	#1,d2
			move.l	LSDPoints,d3
			mulu	d3,d2
			lsl.l	#1,d2
			adda.l	d2,a0

			movea.l	a1,a2
			adda.l	LSDPoints,a2

.LSDLoop5:		move.b	(a0)+,d2		;Get X & Y
			addq.b	#1,d2
			cmpi.b	#$80,d2
			bne.s	.OSkip3
			move.b	#$7f,d2
.OSkip3:		neg.b	d2
			move.b	d2,(a1)+
			move.b	(a0)+,d2
			addq.b	#1,d2
			cmpi.b	#$80,d2
			bne.s	.OSkip4
			move.b	#$7f,d2
.OSkip4:		move.b	d2,(a2)+
			dbf	d0,.LSDLoop5

.LSDMake:		movea.l	LSDMemPtr,a0
			bsr	MakeScreen

			tst.b	DrawMode
			beq	.LSDSkip5

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			tst.b	LSDSaveFlag
			beq	.LSDSkip5

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LSDFrameCount,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			jsr	PrintStatus

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	LSDFrameCount,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error10

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error11

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error11

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error11

			jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip2

			move.w	LSDFrameCount,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip2

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip2:		move.w	LSDFrameCount,d0
			cmp.w	LSDFrameCount2,d0
			beq.s	.LSDSkip5

			addq.w	#1,LSDFrameCount
			bra	.LSDNext

.LSDSkip5:		bsr.s	.FreeMem4
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope4

			lea	StatusReady4c,a0
			jsr	PrintStatus
.Scope4:		jmp	Scope

.Unknown2:		bsr.s	.FreeMem4
			bra	.Unknown

.Error11:		jsr	CloseFile

.Error10:		bsr.s	.FreeMem4
			jsr	FreeFileMem
			jmp	Error5

.FreeMem4:		movea.l	LSDMemPtr,a1
			move.l	LSDMemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.GetLSValue:		lea	ASCIIBuffer,a2

.LSLoop9:		cmpi.b	#$20,(a0)
			bne.s	.LSLoop10
			addq.l	#1,a0
			cmpa.l	a0,a1
			bhi.s	.LSLoop9
			bra.s	.LSBad

.LSLoop10:		move.b	(a0)+,d0
			cmpi.b	#$a,d0
			beq.s	.LSDone
			cmpi.b	#$20,d0
			beq.s	.LSDone2
			cmpi.b	#"0",d0
			blo.s	.LSBad
			cmpi.b	#"9",d0
			bhi.s	.LSBad
			move.b	d0,(a2)+
			cmpa.l	#ASCIIBuffer+10,a2
			bhi.s	.LSBad
			cmpa.l	a0,a1
			bhi.s	.LSLoop10

.LSBad:			moveq	#-1,d0
			rts

.LSDone2:		cmpi.b	#$a,(a0)
			bne.s	.LSDone
			addq.l	#1,a0
			cmpa.l	a0,a1
			bls.s	.LSBad

.LSDone:		clr.b	(a2)

			move.l	a0,-(sp)
			move.l	a1,-(sp)
			lea	ASCIIBuffer,a0
			jsr	ASCIItoHEX
			tst.l	d0
			movea.l	(sp)+,a1
			movea.l	(sp)+,a0
			rts

.ILDA:			move.l	a1,ILDADataPtr		;* ILDA format *
			clr.w	ILDATotal2

.ILDANext:		move.w	ILDACount,d0
			cmp.w	ILDATotal,d0
			bne.s	.ILDANext2
			clr.w	ILDATotal2

.ILDANext2:		movea.l	ILDADataPtr,a1		;Check ILDA header
			lea	ILDAFrameString,a0
			jsr	CmpString
			beq	.Unknown

			addq.l	#4,a1
			tst.w	(a1)+
			bne	.Unknown
			tst.b	(a1)+
			bne	.Unknown

			move.b	(a1)+,ILDAFormat	;3D or 2D?

			movea.l	a1,a0			;Frame name
			move.l	a0,-(sp)
			lea	ILDAName,a1
			moveq	#8,d0
			jsr	MoveString6
			movea.l	a1,a0
			jsr	MoveString3

			movea.l	(sp),a0			;Company name
			addq.l	#8,a0
			lea	ILDACompany,a1
			moveq	#8,d0
			jsr	MoveString6
			movea.l	a1,a0
			jsr	MoveString3

			movea.l	(sp)+,a0
			adda.w	#16,a0

			move.w	(a0)+,ILDAPoints	;Points
			beq	.ILDALast

			move.w	ILDAPoints,d0
			cmpi.w	#MaxPoints,d0
			bhi	.ILDATooBig

			move.w	(a0)+,ILDAFrame		;Frame number

			move.w	(a0)+,ILDATotal		;Total frames
			beq	.Unknown

			addq.l	#2,a0			;Skip scanner & future

			move.l	a0,ILDADataPtr

			movea.l	FileMemPtr,a1		;Quick check
			adda.l	FileMemSize,a1
			cmpa.l	a0,a1
			bls	.Unknown

			move.b	ILDAFormat,d0
			cmpi.b	#1,d0
			bls.s	.ILDAOkay

			move.w	ILDAPoints,d0		;Skip colour table
			mulu	#6,d0
			add.l	d0,ILDADataPtr
			bra	.ILDANext

.ILDAOkay:		move.w	ILDATotal,d0
			cmp.w	ILDATotal2,d0
			beq	.ILDASkip

			move.w	ILDATotal,ILDATotal2
			clr.w	ILDACount

			cmpi.w	#1,ILDATotal
			bne.s	.ILDATSkip

			clr.b	ILDASaveFlag

			movea.l	ILDADataPtr,a0
			move.w	ILDAPoints,d0

			tst.b	ILDAFormat
			beq.s	.ILDAFSkip
			mulu	#6,d0
			bra.s	.ILDAFSkip2

.ILDAFSkip:		mulu	#8,d0
.ILDAFSkip2:		adda.l	d0,a0
			adda.w	#24,a0

			cmpa.l	a0,a1
			bls	.ILDASkip

			tst.w	(a0)
			beq	.ILDASkip

.ILDATSkip:		clr.b	AutoSeqFlag
			move.b	#1,ILDASaveFlag

			lea	SureTitle6,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	ILDAName,a0
			jsr	MoveString
			subq.l	#1,a1
;			move.b	#$20,(a1)+
			lea	ILDACompany,a0
			jsr	MoveString

			subq.l	#1,a1
			lea	SureTitle6a,a0
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	ILDATotal,d0
			jsr	HEXtoASCII
			lea	SureTitle6b,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			lea	SkipText,a3
			jsr	Requester2
			bne.s	.ILDASkip

			clr.b	ILDASaveFlag

.ILDASkip:		sub.l	d0,d0
			move.w	ILDAPoints,d0
			move.l	d0,d1
			lsl.l	#1,d0
			addi.l	#62,d0

			tst.b	ILDAFormat		;2D or 3D?
			bne.s	.ILDA3DSkip
			add.l	d1,d0

.ILDA3DSkip:		move.l	d0,ILDAMemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,ILDAMemPtr
			beq	.Error3

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString

			sub.l	d0,d0
			move.w	ILDAPoints,d0

			move.w	#2,(a1)+

			tst.b	ILDAFormat		;2D or 3D?
			bne.s	.ILDA3DSkip2
			bset.b	#3,-1(a1)

.ILDA3DSkip2:		move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d0,(a1)+
			move.l	d0,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d0,a2
			movea.l	a2,a3
			adda.l	d0,a3

			movea.l	ILDADataPtr,a0
			subq.l	#1,d0

.ILDALoop:		move.w	(a0)+,d1		;Get X
			ext.l	d1
			divs	#256,d1
			cmpi.b	#$80,d1
			bne.s	.USkip
			move.b	#$81,d1
.USkip:			move.b	d1,(a1)+

			move.w	(a0)+,d1		;Get Y
			ext.l	d1
			divs	#256,d1
			cmpi.b	#$80,d1
			bne.s	.USkip2
			move.b	#$81,d1
.USkip2:		move.b	d1,(a2)+

			tst.b	ILDAFormat		;2D or 3D?
			bne.s	.ILDASkip2

			move.w	(a0)+,d1		;Get Z
			ext.l	d1
			divs	#256,d1
			cmpi.b	#$80,d1
			bne.s	.USkip3
			move.b	#$81,d1
.USkip3:		move.b	d1,(a3)+

.ILDASkip2:		move.w	(a0)+,d1		;Colour & status
			btst	#15,d1
			beq.s	.ILDASkip3

			tst.w	d0
			beq.s	.ILDASkip4
			bra	.Unknown3

.ILDASkip3:		dbf	d0,.ILDALoop

.ILDASkip4:		move.l	a0,ILDADataPtr

			tst.w	ILDACount
			beq.s	.FTSkip

			tst.b	ILDASaveFlag
			beq.s	.FTSkip2

.FTSkip:		movea.l	ILDAMemPtr,a0
			bsr	MakeScreen

			lea	ILDAName,a0
			lea	Filename4,a1
			jsr	MoveString2
			jsr	CheckString
			movea.l	a5,a1
			lea	ILDACompany,a0
			jsr	MoveString2
			jsr	CheckString

.FTSkip2:		bsr	.FreeMem5

			tst.b	DrawMode
			beq	.ILDALast

			addq.w	#1,ILDACount

			tst.b	ILDASaveFlag
			beq	.ILDANext

			lea	StatusSave3a,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename4,a0
			jsr	MoveString
			move.b	#$20,-1(a1)
			move.b	#"(",(a1)+
			movea.l	a1,a0
			sub.l	d0,d0
			move.w	ILDAFrame,d0
			jsr	HEXtoASCII
			move.b	#")",(a1)+
			clr.b	(a1)
			lea	ASCIIBuffer,a0
			jsr	(PrintStatus).l

			lea	Filename4,a1
.AALoop:		tst.b	(a1)+
			bne.s	.AALoop
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	ILDAFrame,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error12

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error13

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error13

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error13

			tst.b	D3Flag			;2D or 3D?
			beq.s	.ILDA3DSkip3

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error13

.ILDA3DSkip3:		jsr	CloseFile

			tst.b	AutoAttachFlag
			beq	.ILDANext

			move.w	ILDAFrame,d0
			cmpi.w	#39,d0
			bhi	.ILDANext

			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig
			bra	.ILDANext

.ILDALast:		jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope5

			lea	StatusReady4d,a0
			bsr	PrintStatus
.Scope5:		jmp	Scope

.ILDATooBig:		jsr	FreeFileMem
			jmp	Error22

.Unknown3:		bsr.s	.FreeMem5
			bra	.Unknown

.Error13:		jsr	CloseFile
.Error12:		jsr	FreeFileMem
			jmp	Error5

.FreeMem5:		movea.l	ILDAMemPtr,a1
			move.l	ILDAMemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.X29:			sub.l	d0,d0			;* X29 format *
			move.b	3(a1),d0
			lsl.w	#8,d0
			move.b	2(a1),d0
			move.l	d0,d1
			mulu	#9,d1
			addi.l	#8,d1
			cmp.l	FileMemSize,d1
			bne	.X29Scene

			tst.l	d0
			beq	.Unknown

			cmpi.l	#MaxPoints,d0
			bhi	.Unknown

			move.l	a1,-(sp)
			move.l	d0,d1
			add.l	d1,d0
			add.l	d1,d0
			addi.l	#62,d0
			move.l	d0,X29MemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			movea.l	(sp)+,a0
			move.l	d0,X29MemPtr
			beq	.Error3

			move.l	a0,-(sp)
			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString
			movea.l	(sp)+,a0

			sub.l	d2,d2			;Get X & Y size
			move.b	3(a0),d2
			lsl.w	#8,d2
			move.b	2(a0),d2

			move.w	#$000a,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d2,a3

			subq.l	#1,d2
			adda.w	#10,a0

.X29Loop:		move.b	(a0)+,d0		:Get X
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			subi.l	#250,d1
			divs	#2,d1
			move.b	d1,(a1)+

			move.b	(a0)+,d0		;Get Y
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			subi.l	#170,d1
			divs	#2,d1
			neg.b	d1
			move.b	d1,(a2)+

			move.b	(a0)+,d0		;Get Z
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			divs	#2,d1
			move.b	d1,(a3)+

			addq.l	#3,a0			;Skip C and colour
			dbf	d2,.X29Loop

			movea.l	X29MemPtr,a0
			bsr	MakeScreen
			bsr.s	.FreeMem6
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope6

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady4e,a0
			bsr	PrintStatus
.Scope6:		jmp	Scope

.FreeMem6:		movea.l	X29MemPtr,a1
			move.l	X29MemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.X29Scene:		move.l	a1,X29Ptr		;* X29 Scene format *
			addq.l	#8,X29Ptr

			move.w	d0,X29Count
			beq	.X29Show

			subq.l	#1,d0
			moveq	#8,d2

.X29SLoop:		addq.l	#8,d2			;Check file & points
			addq.l	#8,a1

			sub.l	d1,d1
			move.b	3(a1),d1
			lsl.w	#8,d1
			move.b	2(a1),d1

			tst.l	d1
			beq.s	.X292D

			cmpi.l	#MaxPoints,d1
			bhi.s	.X292D

			mulu	#7,d1
			add.l	d1,d2
			add.l	d1,a1
			dbf	d0,.X29SLoop

			cmp.l	FileMemSize,d2
			beq.s	.X293D

.X292D:			movea.l	X29Ptr,a1
			subq.l	#8,a1
			move.w	X29Count,d0
			subq.w	#1,d0
			moveq	#8,d2

.X29SLoopa:		addq.l	#8,d2			;Check file & points
			addq.l	#8,a1

			sub.l	d1,d1
			move.b	3(a1),d1
			lsl.w	#8,d1
			move.b	2(a1),d1

			tst.l	d1
			beq	.X29Show

			cmpi.l	#MaxPoints,d1
			bhi	.X29Show

			mulu	#5,d1
			add.l	d1,d2
			add.l	d1,a1
			dbf	d0,.X29SLoopa

			cmp.l	FileMemSize,d2
			bne	.X29Show

			move.b	#1,X29Mode
			bra.s	.X29Go

.X293D:			clr.b	X29Mode

.X29Go:			cmpi.w	#1,X29Count
			beq.s	.X29Next

			clr.b	AutoSeqFlag
			clr.w	X29Count2

			lea	SureTitle8,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	X29Count,d0
			jsr	HEXtoASCII
			lea	SureTitle8a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.X29Next

			move.w	#1,X29Count

.X29Next:		movea.l	X29Ptr,a0		;Get mem
			sub.l	d0,d0
			move.b	3(a0),d0
			lsl.w	#8,d0
			move.b	2(a0),d0
			move.l	d0,d1
			add.l	d1,d0

			tst.b	X29Mode
			bne.s	.X29MSkip
			add.l	d1,d0

.X29MSkip:		addi.l	#62,d0
			move.l	d0,X29MemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,X29MemPtr
			beq	.Error3

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString

			movea.l	X29Ptr,a0		;Get X & Y size
			sub.l	d2,d2
			move.b	3(a0),d2
			lsl.w	#8,d2
			move.b	2(a0),d2

			addq.l	#8,X29Ptr		;Point to next
			move.l	d2,d0
			moveq	#7,d1

			tst.b	X29Mode
			beq.s	.X29MSkip2
			moveq	#5,d1

.X29MSkip2:		mulu	d1,d0
			add.l	d0,X29Ptr

			move.w	#$000a,(a1)+

			tst.b	X29Mode
			beq.s	.X29MSkip3
			move.b	#2,-1(a1)

.X29MSkip3:		move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d2,a3

			subq.l	#1,d2
			addq.l	#8,a0

.X29SLoop2:		move.b	(a0)+,d0		:Get X
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			subi.l	#250,d1
			divs	#2,d1
			move.b	d1,(a1)+

			move.b	(a0)+,d0		;Get Y
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			subi.l	#170,d1
			divs	#2,d1
			neg.b	d1
			move.b	d1,(a2)+

			tst.b	X29Mode
			bne.s	.X29MSkip4

			move.b	(a0)+,d0		;Get Z
			move.b	(a0)+,d1
			lsl.w	#8,d1
			or.b	d0,d1
			ext.l	d1
			divs	#2,d1
			move.b	d1,(a3)+

.X29MSkip4:		dbf	d2,.X29SLoop2

			movea.l	X29MemPtr,a0
			bsr	MakeScreen
			bsr	.FreeMem6

			tst.b	DrawMode
			beq	.X29Skip

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			cmpi.w	#1,X29Count
			beq	.X29Skip

			addq.w	#1,X29Count2

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	X29Count2,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	X29Count2,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error14

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			tst.b	X29Mode
			bne.s	.X29MSkip5

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

.X29MSkip5:		jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip3

			move.w	X29Count2,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip3

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip3:		move.w	X29Count2,d0
			cmp.w	X29Count,d0
			bne	.X29Next

			movea.l	X29Ptr,a0
			suba.l	FileMemSize,a0
			cmpa.l	FileMemPtr,a0
			bne	.Unknown

.X29Skip:		jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope7

			lea	StatusReady4e,a0
			bsr	PrintStatus
.Scope7:		jmp	Scope

.Error15:		jsr	CloseFile
.Error14:		jsr	FreeFileMem
			jmp	Error5

.X29Show:						;* X29 Show format *

.X29Again:		movea.l	X29Ptr,a0		;Get scene name
			addq.l	#2,a0
			lea	X29Name,a1
			moveq	#16,d0
			jsr	MoveString6
			movea.l	a1,a0
			jsr	MoveString3
			addi.l	#184,X29Ptr

			movea.l	X29Ptr,a0		;Get # of frames
			move.b	1(a0),d0
			lsl.w	#8,d0
			move.b	(a0),d0
			move.w	d0,X29Count
			beq	.Unknown
			addq.l	#2,X29Ptr

			clr.b	AutoSeqFlag
			clr.w	X29Count2
			move.b	#1,X29SaveFlag

			lea	SureTitle6,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	X29Name,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	SureTitle6a,a0
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	X29Count,d0
			jsr	HEXtoASCII
			lea	SureTitle6b,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			lea	SkipText,a3
			jsr	Requester2
			bne.s	.X29Next2

			clr.b	X29SaveFlag

.X29Next2:		movea.l	X29Ptr,a0		;Get points
			sub.l	d0,d0
			move.b	1(a0),d0
			lsl.w	#8,d0
			move.b	(a0),d0

			tst.l	d0
			beq	.Unknown

			cmpi.l	#MaxPoints,d0
			bhi	.Unknown

			lsl.l	#1,d0			;Get mem
			addi.l	#62,d0
			move.l	d0,X29MemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,X29MemPtr
			beq	.Error3

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString

			movea.l	X29Ptr,a0		;Get X & Y size
			sub.l	d2,d2
			move.b	1(a0),d2
			lsl.w	#8,d2
			move.b	(a0),d2

			addq.l	#6,X29Ptr		;Point to next
			move.l	d2,d0
			mulu	#3,d0
			add.l	d0,X29Ptr

			move.w	#2,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2

			subq.l	#1,d2
			addq.l	#6,a0

.X29SLoop3:		sub.l	d1,d1			;Get X
			btst	#4,2(a0)
			beq.s	.X29OverSkip
			move.l	#$100,d1

.X29OverSkip:		move.b	(a0)+,d1
			subi.l	#250,d1
			divs	#2,d1
			move.b	d1,(a1)+

			sub.l	d1,d1			;Get Y
			btst	#6,1(a0)
			beq.s	.X29OverSkip2
			move.l	#$100,d1

.X29OverSkip2:		move.b	(a0)+,d1
			subi.l	#170,d1
			divs	#2,d1
			neg.b	d1
			move.b	d1,(a2)+

			addq.l	#1,a0			;Skip colour
			dbf	d2,.X29SLoop3

			tst.w	X29Count2
			beq.s	.FTXSkip

			tst.b	X29SaveFlag
			beq.s	.FTXSkip2

.FTXSkip:		movea.l	X29MemPtr,a0
			bsr	MakeScreen

			lea	X29Name,a0
			lea	Filename4,a1
			jsr	MoveString2
			jsr	CheckString

.FTXSkip2:		addq.w	#1,X29Count2
			bsr	.FreeMem6

			tst.b	DrawMode
			beq	.X29Skip2

			tst.b	X29SaveFlag
			beq	.AASkip4

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	X29Count2,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename4,a1
.AALoop2:		tst.b	(a1)+
			bne.s	.AALoop2
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	X29Count2,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error14

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error15

			jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip4

			move.w	X29Count2,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip4

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip4:		move.w	X29Count2,d0
			cmp.w	X29Count,d0
			bne	.X29Next2

			movea.l	X29Ptr,a0
			suba.l	FileMemPtr,a0
			cmpa.l	FileMemSize,a0
			blo	.X29Again

.X29Skip2:		jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope8

			lea	StatusReady4e,a0
			bsr	PrintStatus
.Scope8:		jmp	Scope

.Aura:			move.l	FileMemSize,d0		;* Aura format *
			lsr.l	#2,d0

			move.l	a1,-(sp)
			mulu	#3,d0
			addi.l	#62,d0
			move.l	d0,AuraMemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			movea.l	(sp)+,a0
			move.l	d0,AuraMemPtr
			beq	.Error3

			move.l	a0,-(sp)
			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString
			movea.l	(sp)+,a0

			move.l	FileMemSize,d2		;Get # of points
			lsr.l	#2,d2
			move.l	d2,d1
			subq.l	#1,d1
			movea.l	a0,a2

.AuraLoop:		addq.l	#3,a2
			move.b	(a2)+,d0		;(Colour) End?
			cmpi.b	#$95,d0
			beq.s	.AuraLast
			cmpi.b	#$b3,d0
			beq.s	.AuraLast
			dbf	d1,.AuraLoop
			bra.s	.AuraDone

.AuraLast:		sub.l	d1,d2

.AuraDone:		tst.l	d2
			beq	.AuraBad

			cmpi.l	#MaxPoints,d2
			bhi	.AuraBad

			move.w	#$000a,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d2,a3

			subq.l	#1,d2

.AuraLoop2:		move.b	(a0)+,(a1)+		;Get X

			move.b	(a0)+,(a2)+		;Get Y

			move.b	(a0)+,(a3)+		;Get Z

			addq.l	#1,a0			;Skip colour
			dbf	d2,.AuraLoop2

			movea.l	AuraMemPtr,a0
			bsr	MakeScreen
			bsr.s	.FreeMem7
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope9

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusReady4f,a0
			bsr	PrintStatus
.Scope9:		jmp	Scope

.AuraBad:		bsr.s	.FreeMem7
			bra	.Unknown

.FreeMem7:		movea.l	AuraMemPtr,a1
			move.l	AuraMemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.LD400:			move.w	4(a1),d0		;* LD400 format * (Almost ILDA!)
			move.w	d0,LD400Count
			addq.l	#6,a1
			move.l	a1,LD400Ptr
			mulu	#$24,d0
			adda.l	d0,a1
			move.l	a1,LD400Ptr2

			cmpi.w	#1,LD400Count
			beq.s	.LD400Next

			clr.b	AutoSeqFlag
			clr.w	LD400Count2

			lea	SureTitle5,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LD400Count,d0
			jsr	HEXtoASCII
			lea	SureTitle5a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.LD400Next

			move.w	#1,LD400Count

.LD400Next:		movea.l	LD400Ptr,a0
			sub.l	d0,d0
			move.w	4(a0),d0
			move.w	d0,LD400Points
			beq	.Unknown

			move.w	6(a0),LD400Type
			beq.s	.LD400Okay

			cmpi.w	#1,LD400Type
			bne	.Unknown

.LD400Okay:		cmpi.w	#MaxPoints,d0
			bhi	.Unknown

			move.l	d0,d1
			add.l	d1,d0

			tst.w	LD400Type		;3D?
			bne.s	.LD4003D
			add.l	d1,d0

.LD4003D:		addi.l	#62,d0
			move.l	d0,LD400MemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,LD400MemPtr
			beq	.Error3

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString

			sub.l	d2,d2
			move.w	LD400Points,d2

			move.w	#$000a,(a1)+
			tst.w	LD400Type		;3D?
			beq.s	.LD4003D2
			move.w	#2,-2(a1)

.LD4003D2:		move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d2,a3

			subq.l	#1,d2

			movea.l	LD400Ptr2,a0

.LD400Loop:		move.w	(a0)+,d0		;Get X
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip4
			move.b	#$81,d0
.USkip4:		move.b	d0,(a1)+

			move.w	(a0)+,d0		;Get Y
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip5
			move.b	#$81,d0
.USkip5:		move.b	d0,(a2)+

			tst.w	LD400Type		;3D?
			bne.s	.LD4003D3

			move.w	(a0)+,d0		;Get Z
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip6
			move.b	#$81,d0
.USkip6:		move.b	d0,(a3)+

.LD4003D3:		addq.l	#2,a0			;Skip colour/Status
			dbf	d2,.LD400Loop

			movea.l	LD400MemPtr,a0
			bsr	MakeScreen
			bsr	.FreeMem8

			tst.b	DrawMode
			beq	.LD400Skip

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			cmpi.w	#1,LD400Count
			beq	.LD400Skip

			addq.w	#1,LD400Count2

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LD400Count2,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	LD400Count2,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error16

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error17

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error17

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error17

			tst.b	D3Flag
			beq.s	.LD4003D4

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error17

.LD4003D4:		jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip5

			move.w	LD400Count2,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip5

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip5:		addi.l	#$24,LD400Ptr
			move.w	LD400Points,d0

			tst.w	LD400Type
			bne.s	.LD4003D5
			mulu	#8,d0
			bra.s	.LD4003D6

.LD4003D5:		mulu	#6,d0

.LD4003D6:		add.l	d0,LD400Ptr2

			move.w	LD400Count2,d0
			cmp.w	LD400Count,d0
			bne	.LD400Next

			movea.l	LD400Ptr2,a0
			suba.l	FileMemSize,a0
			cmpa.l	FileMemPtr,a0
			bne	.Unknown

.LD400Skip:		jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope10

			lea	StatusReady4g,a0
			bsr	PrintStatus
.Scope10:		jmp	Scope

.Error17:		jsr	CloseFile
.Error16:		jsr	FreeFileMem
			jmp	Error5

.FreeMem8:		movea.l	LD400MemPtr,a1
			move.l	LD400MemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.LDPro:			move.w	16(a1),d0		;* LD pro format *
			move.w	d0,LDProCount
			mulu	#72,d0
			adda.w	#60,a1

			sub.l	d1,d1			;Guessing competition
			movea.l	FileMemPtr,a4
			adda.l	FileMemSize,a4

.LDProGLoop:		addq.l	#1,d1
			move.l	d1,d2
			mulu	#4,d2
			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d0,a3

			move.w	LDProCount,d4
			subq.w	#1,d4

.LDProGLoop2:		move.b	5(a2),d2		;Get points
			lsl.w	#8,d2
			move.b	6(a2),d2

			move.b	7(a2),d3		;Get type
			lsl.w	#8,d3
			move.b	8(a2),d3

			tst.w	d3
			bne.s	.LDProG3D

			mulu	#8,d2
			bra.s	.LDProG3D2

.LDProG3D:		mulu	#6,d2

.LDProG3D2:		adda.l	d2,a3
			adda.w	#72,a2
			dbf	d4,.LDProGLoop2

			addq.l	#1,a3
			cmpa.l	a3,a4
			beq.s	.LDProFound

			cmpi.l	#500,d1
			bls.s	.LDProGLoop
			bra	.Unknown		;I give up!

.LDProFound:		mulu	#4,d1
			adda.l	d1,a1
			move.l	a1,LDProPtr

			adda.l	d0,a1
			move.l	a1,LDProPtr2

			cmpi.w	#1,LDProCount
			beq.s	.LDProNext

			clr.b	AutoSeqFlag
			clr.w	LDProCount2

			lea	SureTitle5,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LDProCount,d0
			jsr	HEXtoASCII
			lea	SureTitle5a,a0
			jsr	MoveString

			jsr	FlashScreen
			lea	SureText3,a1
			lea	SaveText,a2
			jsr	Requester
			bne.s	.LDProNext

			move.w	#1,LDProCount

.LDProNext:		movea.l	LDProPtr,a0
			sub.l	d0,d0
			move.b	5(a0),d0
			lsl.w	#8,d0
			move.b	6(a0),d0
			move.w	d0,LDProPoints

			move.b	7(a0),d1
			lsl.w	#8,d1
			move.b	8(a0),d1
			move.w	d1,LDProType
			beq.s	.LDProOkay

			cmpi.w	#1,LDProType
			bne	.Unknown

.LDProOkay:		tst.w	d0
			bne.s	.LDProOkay2

			addq.w	#1,LDProCount2
			bra	.AASkip6

.LDProOkay2:		cmpi.w	#MaxPoints,d0
			bhi	.Unknown

			move.l	d0,d1
			add.l	d1,d0

			tst.w	LDProType		;3D?
			bne.s	.LDPro3D
			add.l	d1,d0

.LDPro3D:		addi.l	#62,d0
			move.l	d0,LDProMemSize
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,LDProMemPtr
			beq	.Error3

			lea	ScreenHeader,a0
			movea.l	d0,a1
			jsr	MoveString

			sub.l	d2,d2
			move.w	LDProPoints,d2

			move.w	#$000a,(a1)+
			tst.w	LDProType		;3D?
			beq.s	.LDPro3D2
			move.w	#2,-2(a1)

.LDPro3D2:		move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#64,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#240,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.w	#0,(a1)+
			move.l	d2,(a1)+
			move.l	d2,(a1)+
			clr.l	(a1)+
			clr.l	(a1)+

			movea.l	a1,a2
			adda.l	d2,a2
			movea.l	a2,a3
			adda.l	d2,a3

			subq.l	#1,d2

			movea.l	LDProPtr2,a0

.LDProLoop:		move.b	(a0)+,d1		;Get X
			move.b	(a0)+,d0
			lsl.w	#8,d0
			move.b	d1,d0
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip7
			move.b	#$81,d0
.USkip7:		move.b	d0,(a1)+

			move.b	(a0)+,d1		;Get Y
			move.b	(a0)+,d0
			lsl.w	#8,d0
			move.b	d1,d0
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip8
			move.b	#$81,d0
.USkip8:		move.b	d0,(a2)+

			tst.w	LDProType		;3D?
			bne.s	.LDPro3D3

			move.b	(a0)+,d1		;Get Z
			move.b	(a0)+,d0
			lsl.w	#8,d0
			move.b	d1,d0
			ext.l	d0
			divs	#256,d0
			cmpi.b	#$80,d0
			bne.s	.USkip9
			move.b	#$81,d0
.USkip9:		move.b	d0,(a3)+

.LDPro3D3:		addq.l	#2,a0			;Skip colour/Status
			dbf	d2,.LDProLoop

			movea.l	LDProMemPtr,a0
			bsr	MakeScreen
			bsr	.FreeMem9

			tst.b	DrawMode
			beq	.LDProSkip

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString

			cmpi.w	#1,LDProCount
			beq	.LDProSkip

			addq.w	#1,LDProCount2

			lea	StatusSave3,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	LDProCount2,d0
			jsr	HEXtoASCII
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename3,a0
			lea	Filename4,a1
			jsr	MoveString
			lea	-1(a1),a0
			move.b	#".",(a0)+
			sub.l	d0,d0
			move.w	LDProCount2,d0
			jsr	HEXtoASCII

			lea	Filename4,a0
			jsr	MakeFileName2

			bsr	AutoScrSequence

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error18

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error19

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error19

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error19

			tst.b	D3Flag
			beq.s	.LDPro3D4

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error19

.LDPro3D4:		jsr	CloseFile

			tst.b	AutoAttachFlag
			beq.s	.AASkip6

			move.w	LDProCount2,d0
			cmpi.w	#40,d0
			bhi.s	.AASkip6

			subq.w	#1,d0
			mulu	#4,d0
			lea	GadgetTable,a0
			movea.l	(a0,d0),a6

			move.b	#1,AttachStatus
			move.b	#1,FromConfig
			jsr	(a6)
			clr.b	FromConfig

.AASkip6:		addi.l	#72,LDProPtr
			move.w	LDProPoints,d0

			tst.w	LDProType
			bne.s	.LDPro3D5
			mulu	#8,d0
			bra.s	.LDPro3D6

.LDPro3D5:		mulu	#6,d0

.LDPro3D6:		add.l	d0,LDProPtr2

			move.w	LDProCount2,d0
			cmp.w	LDProCount,d0
			bne	.LDProNext

.LDProSkip:		jsr	FreeFileMem

			tst.b	DrawMode
			beq.s	.Scope11

			lea	StatusReady4h,a0
			bsr	PrintStatus
.Scope11:		jmp	Scope

.Error19:		jsr	CloseFile
.Error18:		jsr	FreeFileMem
			jmp	Error5

.FreeMem9:		movea.l	LDProMemPtr,a1
			move.l	LDProMemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.MergeIt:		bsr	TurnItOff2

			movea.l	FileMemPtr,a0
			adda.w	#46,a0
			move.l	(a0)+,d0
			move.l	(a0)+,d1
			addq.l	#8,a0

			cmpi.l	#MaxPoints,d0
			bhs	.TooBig

			add.l	d0,DrawLen
			move.l	d0,d3

			movea.l	XDataPtr,a1		;X data
			move.l	a1,XDataMergePtr
			move.l	a1,XDataLastPtr

			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints,a2
			suba.l	d0,a2
			cmpa.l	a1,a2
			bhi.s	.Skip2

			move.l	a1,d2
			move.l	a1,d7
			sub.l	a2,d7
			bsr	AdjustLastPtrs
			move.b	#1,DrawUpdateFlag

			movea.l	DrawMemPtr,a1
			lea	(a1,d7),a2
			sub.l	a2,d2
			subq.l	#1,d2

.Loop2:			move.b	(a2)+,(a1)+
			dbf	d2,.Loop2

.Skip2:			subq.l	#1,d0

.Loop3:			move.b	(a0)+,(a1)+
			dbf	d0,.Loop3
			move.l	a1,XDataPtr

			movea.l	YDataPtr,a1		;Y data
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*2,a2
			suba.l	d1,a2
			cmpa.l	a1,a2
			bhi.s	.Skip3

			move.l	a1,d2
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			lea	(a1,d7),a2
			sub.l	a2,d2
			subq.l	#1,d2

.Loop4:			move.b	(a2)+,(a1)+
			dbf	d2,.Loop4

.Skip3:			subq.l	#1,d1

.Loop5:			move.b	(a0)+,(a1)+
			dbf	d1,.Loop5
			move.l	a1,YDataPtr

			movea.l	FileMemPtr,a1
			btst	#3,23(a1)		;3D?
			beq.s	.Skip5

			tst.b	D3Flag
			beq.s	.Skip5

			movea.l	ZDataPtr,a1		;Z data
			movea.l	DrawMemPtr,a2
			adda.w	#MaxPoints*3,a2
			suba.l	d3,a2
			cmpa.l	a1,a2
			bhi.s	.Skip4

			move.l	a1,d2
			move.l	a1,d7
			sub.l	a2,d7

			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			lea	(a1,d7),a2
			sub.l	a2,d2
			subq.l	#1,d2

.Loop6:			move.b	(a2)+,(a1)+
			dbf	d2,.Loop6

.Skip4:			subq.l	#1,d3

.Loop7:			move.b	(a0)+,(a1)+
			dbf	d3,.Loop7
			move.l	a1,ZDataPtr

.Skip5:			jsr	FreeFileMem

			bsr	GetDrawLen
			bsr	CheckDefault
			bsr	CheckFreq
			jsr	(RestartSound).l

			move.l	XDataPtr,d0
			sub.l	XDataMergePtr,d0
			move.l	d0,XDataMergeSize
			move.l	d0,XDataLastSize
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusReady5,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.TooBig:		jsr	FreeFileMem
			jmp	Error22

AutoScrSequence:	lea	RecordBuff2,a1

			tst.b	AutoSeqFlag
			bne.s	.Skip

			move.b	#1,AutoSeqFlag

			jsr	FreeSeqMem

			lea	Filename3,a0
			lea	Filename2,a1
			jsr	MoveString

			lea	AutoSeqText,a0
			lea	RecordBuff2,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Dir2,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename3,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	AutoSeqTexta,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename3,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	AutoSeqTextb,a0
			jsr	MoveString
			subq.l	#1,a1

.Skip:			lea	AutoSeqText2,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	ASCIIBuffer,a0
			jsr	MoveString
			subq.l	#1,a1
			lea	AutoSeqText3,a0
			jsr	MoveString
			subq.l	#1,a1
			suba.l	#RecordBuff2,a1
			move.l	a1,BufferSize2

			move.l	SeqMemSize,d0
			beq.s	.Create

			add.l	a1,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq.s	.Error

			move.l	d0,-(sp)		;Copy mem
			movea.l	d0,a1

			movea.l	SeqMemPtr,a0
			move.l	SeqMemSize,d0
			jsr	MoveMemBlock

.CopyBuff:		lea	RecordBuff2,a0
			movea.l	(sp),a1
			adda.l	SeqMemSize,a1

			move.l	BufferSize2,d0
			subq.l	#1,d0

.Loop:			move.b	(a0)+,(a1)+
			dbf	d0,.Loop

			move.l	SeqMemSize,-(sp)
			jsr	FreeSeqMem

			move.l	(sp)+,d0
			add.l	BufferSize2,d0
			move.l	d0,SeqMemSize
			move.l	(sp)+,SeqMemPtr
			rts

.Create:		move.l	a1,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq.s	.Error

			move.l	d0,-(sp)
			bra.s	.CopyBuff

.Error:			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			rts

MakeScreen:		move.l	a0,-(sp)
			bsr	FreeMorphMem
			movea.l	(sp)+,a0
			clr.b	MorphFlag
			clr.b	DrawingFlag

MakeScreen2:		movea.l	a0,a1

			clr.b	AutoRetraceFlag
			bsr	GetAutoRetraceItem
			bclr	#0,12(a0)

			btst	#0,23(a1)
			beq.s	.Skip

			move.b	#1,AutoRetraceFlag
			bset	#0,12(a0)

.Skip:			clr.b	HiResFlag
			bsr	GetHiResItem
			bclr	#0,12(a0)

			btst	#1,23(a1)
			beq.s	.Skip2

			move.b	#1,HiResFlag
			bset	#0,12(a0)

.Skip2:			move.b	#1,FilterFlag
			jsr	GetFilterItem
			bset	#0,12(a0)

			btst	#2,23(a1)		;Filter?
			beq.s	.Skip3

			clr.b	FilterFlag
			bclr	#0,12(a0)

.Skip3:			clr.b	D3Flag
			bsr	GetD3Item
			bclr	#0,12(a0)

			tst.b	IconifyFlag
			bne.s	.ISkip
			movea.l	(a0),a2
			bclr	#4,13(a2)

.ISkip:			btst	#3,23(a1)		;3D?
			beq.s	.Skip4

			move.b	#1,D3Flag
			bset	#0,12(a0)

			tst.b	IconifyFlag
			bne.s	.Skip4
			bset	#4,13(a2)

.Skip4:			tst.b	Preserve
			bne.s	.PSkip
			bsr	TurnItOff

.PSkip:			clr.b	Preserve
			bsr	ClrLastPtrs
			clr.b	RBufferFlag
			clr.b	SBufferFlag

			lea	24(a1),a0
			move.w	(a0)+,Vol0
			move.w	(a0)+,Vol1
			move.w	(a0)+,Vol2
			move.w	(a0)+,Vol3
			move.w	(a0)+,Freq0
			move.w	(a0)+,Freq1
			move.w	(a0)+,Freq2
			move.w	(a0)+,Freq3
			move.w	(a0)+,Phase1
			move.w	(a0)+,Phase2
			move.w	(a0)+,Phase3

			move.l	(a0)+,d0
			move.l	d0,Len0
			move.l	d0,Len3

			move.l	(a0)+,d0
			move.l	d0,Len1
			move.l	d0,Len2

			addq.l	#8,a0

			move.l	a0,-(sp)
			move.b	D3Flag,D3FlagTemp
			bsr	MakeDrawOn
			move.b	D3FlagTemp,D3Flag
			movea.l	(sp)+,a0

			tst.b	DrawMode
			beq	.Skip5

			movea.l	DrawMemPtr,a1		;X data
			move.l	Len0,d0
			move.l	a1,XDataPtr
			add.l	d0,XDataPtr
			movea.l	a0,a2

			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			move.l	(a0)+,(a1)+
			dbf	d0,.Loop

			movea.l	DrawMemPtr,a1		;Y data
			adda.w	#MaxPoints,a1
			move.l	Len1,d0
			move.l	a1,YDataPtr
			add.l	d0,YDataPtr
			movea.l	a2,a0
			adda.l	Len0,a0
			subq.l	#1,d0

.Loop2:			move.b	(a0)+,(a1)+
			dbf	d0,.Loop2

			tst.b	D3Flag
			beq.s	.3DSkip

			movea.l	DrawMemPtr,a1		;Z data
			adda.w	#MaxPoints*2,a1
			move.l	Len0,d0
			move.l	a1,ZDataPtr
			add.l	d0,ZDataPtr
			subq.l	#1,d0

.Loop3:			move.b	(a0)+,(a1)+
			dbf	d0,.Loop3

.3DSkip:		move.l	#-1,Phase2Print
			bsr	CheckFreq
			bsr	CheckPosition
			bsr	CalcDCOffset
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag
			clr.b	DefaultFreq

.Skip5:			tst.b	FilterFlag
			beq.s	.Off
			bclr	#1,$bfe001
			rts

.Off:			bset	#1,$bfe001
			rts

TurnItOff2:		bsr	FreeMorphMem
			clr.b	MorphFlag
			clr.b	DrawingFlag
			move.l	#$01010101,AD0Update

TurnItOff:		clr.l	AD0Funct
			clr.l	AD2Funct
			clr.b	RotateFlag
			clr.w	Spin0
			clr.w	Spin1
			clr.w	Spin2
			clr.w	Spin3
			clr.w	RotateAngle01
			clr.w	RotateAngle23
			rts

MakeDrawOn:		tst.b	DrawMode
			bne.s	.End
			bsr	GetDrawMem
			beq.s	.Error
			move.b	#1,DrawMode
			bsr	GetDrawModeItem
			bset	#0,12(a0)
			bsr	DrawOn
.End:			rts

.Error:			bsr	SetSineWave		;Len!
			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			rts

GetAutoRetraceItem:	moveq	#5,d0
			bsr	GetPrefsItem
			rts

MergeScreen:		move.b	#1,MergeMode
			bra	LoadScreen2

SaveScreen:		jsr	SeqStuffOff
			jsr	AllOff

			lea	Filename4,a0
			lea	Dir2,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			move.l	SN,d2
			move.l	SN2,d1
			cmp.l	d1,d2
			beq.s	.Cool

			clr.b	PirateFlag

.Cool:			cmpi.b	#1,d0
			beq.l	Scope

			lea	StatusSave2,a0
			bsr	PrintStatus

			lea	Filename4,a0
			jsr	MakeFileName2

			lea	ScreenHeader+22,a0
			bsr	MakeHeader

			move.l	#1006,d2
			jsr	OpenFile2
			beq.l	Error5

			move.l	d0,d1			;Header
			move.l	#ScreenHeader,d2
			moveq	#62,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error

			move.l	FilePtr,d1		;X data
			move.l	DrawMemPtr,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error

			move.l	FilePtr,d1		;Y data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints,d2
			move.l	Len1,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error

			tst.b	D3Flag			;2D or 3D?
			beq.s	.3DSkip

			move.l	FilePtr,d1		;Z data
			move.l	DrawMemPtr,d2
			addi.l	#MaxPoints*2,d2
			move.l	Len0,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error

.3DSkip:		jsr	CloseFile

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.Error:			jsr	CloseFile
			jmp	Error5

MakeHeader:		clr.w	(a0)+

			tst.b	AutoRetraceFlag
			beq.s	.Skip

			bset	#0,-1(a0)

.Skip:			tst.b	HiResFlag
			beq.s	.Skip2

			bset	#1,-1(a0)

.Skip2:			tst.b	FilterFlag
			bne.s	.Skip3

			bset	#2,-1(a0)

.Skip3:			tst.b	D3Flag
			beq.s	.Skip4

			bset	#3,-1(a0)

.Skip4:			move.w	Vol0,(a0)+
			move.w	Vol1,(a0)+
			move.w	Vol2,(a0)+
			move.w	Vol3,(a0)+
			move.w	Freq0,(a0)+
			move.w	Freq1,(a0)+
			move.w	Freq2,(a0)+
			move.w	Freq3,(a0)+
			move.w	Phase1,(a0)+
			move.w	Phase2,(a0)+
			move.w	Phase3,(a0)+
			move.l	Len0,(a0)+
			move.l	Len1,(a0)+
			clr.l	(a0)+
			clr.l	(a0)+
			rts

SavePack:		jsr	SeqStuffOff
			jsr	AllOff

			tst.l	SeqMemSize
			beq.l	Error7

			lea	Filename8,a0
			lea	Dir2,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			cmpi.b	#1,d0
			beq.l	Scope

			clr.w	PackCount
			clr.b	ForRealFlag
			clr.b	FirstTimeFlag
			clr.b	PackCheckFlag

.Next:			lea	StatusProcessing,a0
			bsr	PrintStatus

			movea.l	SeqMemPtr,a1		;Find screens
			movea.l	a1,a2
			adda.l	SeqMemSize,a2

.Loop:			move.b	(a1)+,d0
			cmpi.b	#"S",d0
			beq.s	.Skip
			cmpi.b	#"s",d0
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop

			tst.b	PackCheckFlag
			bne	.Okay

			tst.b	ForRealFlag
			bne	.Done

			tst.w	PackCount
			beq.s	.None

			move.b	#1,ForRealFlag
			move.w	PackCount,PackHeader+20
			bra.s	.Next

.None:			bsr	FlashScreen
			lea	StatusSave6,a0
			bsr	PrintStatus
			jmp	Scope

.Skip:			lea	PreloadCmd2,a0
			jsr	CmpString
			beq.s	.Loop

			movea.l	a1,a3
			subq.l	#2,a3

			adda.w	#5,a1
			cmpa.l	a1,a2
			bls.l	Error

			cmpi.b	#"2",(a1)
			bne.s	.Skip2

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

.Skip2:			cmpi.b	#" ",(a1)
			bne	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			cmpi.b	#'"',(a1)
			bne	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			lea	ASCIIBuffer,a0

.Loop2:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip3
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip3
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop2

.Skip3:			clr.b	(a0)

			tst.b	PackCheckFlag
			beq.s	.Skip4

			move.l	a1,-(sp)
			move.l	a2,-(sp)
			lea	ASCIIBuffer+100,a0
			lea	ASCIIBuffer,a1
			jsr	CmpString2
			movea.l	(sp)+,a2
			movea.l	(sp)+,a1
			beq	.Loop

			clr.b	PackCheckFlag
			bra	.Skip8

.Skip4:			move.l	a1,PackPtr2
			move.l	a2,PackPtr3

			lea	ASCIIBuffer,a0
			lea	ASCIIBuffer+200,a1
			jsr	MoveString

			lea	ASCIIBuffer,a0
			lea	ASCIIBuffer+100,a1
			jsr	UpperString
			clr.b	(a1)

			move.b	#1,PackCheckFlag
			movea.l	a3,a2
			movea.l	SeqMemPtr,a1
			bra	.Loop

.Okay:			clr.b	PackCheckFlag

			tst.b	ForRealFlag
			bne.s	.Skip5

			addq.w	#1,PackCount
			bra	.Skip8

.Skip5:			lea	StatusLoad2,a0
			bsr	PrintStatus

			lea	ASCIIBuffer+200,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString

			jsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq.l	Error29

			lea	ScreenString,a0		;Screen?
			movea.l	FileMemPtr,a1
			jsr	CmpString
			beq	.Error

			lea	ASCIIBuffer,a0		;Find filename
			movea.l	a0,a1

.Loop3:			tst.b	(a0)+
			bne.s	.Loop3

.Loop4:			move.b	-(a0),d0
			cmpi.b	#"/",d0
			beq.s	.Found
			cmpi.b	#":",d0
			beq.s	.Found
			cmpa.l	a0,a1
			blo.s	.Loop4
			bra.s	.Found2

.Found:			addq.l	#1,a0
.Found2:		lea	PackHeader+22,a1
			moveq	#40,d0
			jsr	MoveString6

			movea.l	FileMemPtr,a0
			bsr	MakeScreen

			lea	PackHeader+22,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusSave3b,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	PackHeader+22,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename8,a0
			jsr	MakeFileName2

			tst.b	FirstTimeFlag
			bne.s	.Skip6

			move.b	#1,FirstTimeFlag

			move.l	#1006,d2
			jsr	OpenFile2
			beq	.Error2

			move.l	d0,d1			;Header
			move.l	#PackHeader,d2
			moveq	#22,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi	.Error3
			bra.s	.Skip7

.Skip6:			jsr	OpenFile
			beq	.Error2

			move.l	d0,d1			;Move last
			sub.l	d2,d2
			moveq	#1,d3
			movea.l	DosBase,a6
			jsr	_LVOSeek(a6)
			tst.l	d0
			bmi.s	.Error3

.Skip7:			move.l	FilePtr,d1		;Filename
			move.l	#PackHeader+22,d2
			moveq	#42,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error3

			move.l	FilePtr,d1		;Screen
			move.l	FileMemPtr,d2
			move.l	FileMemSize,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error3

			jsr	CloseFile
			jsr	FreeFileMem

.Skip8:			move.l	PackPtr2,a1
			move.l	PackPtr3,a2
			bra	.Loop

.Done:			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.Error3:		jsr	CloseFile
.Error2:		jsr	FreeFileMem
			jmp	Error5

.Error:			jsr	FreeFileMem
			jmp	Error17

DeleteScreen:		jsr	SeqStuffOff
			jsr	AllOff

			lea	Filename4,a0
			lea	Dir2,a1
			lea	DeleteReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			cmpi.b	#1,d0
			beq.l	Scope

			lea	Filename4,a0
			jsr	MakeFileName2
			jsr	GetLock
			beq.s	.Scope
			jsr	Unlock

			lea	SureTitle4,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	Filename4,a0
			jsr	MoveString
			subq.l	#1,a1
			move.b	#'"',(a1)+
			move.b	#"?",(a1)+
			clr.b	(a1)

			lea	SureText4,a1
			lea	DeleteText,a2
			bsr	Requester
			beq.s	.Scope

			lea	StatusDelete,a0
			bsr	PrintStatus

			lea	Filename4,a0
			jsr	MakeFileName2
			jsr	DeleteFile

			lea	StatusBlank,a0
			bsr	PrintStatus
.Scope:			jmp	Scope

SaveILDA:		move.l	#1006,OpenType
			jsr	SeqStuffOff
			jsr	AllOff

			lea	Filename4,a0
			lea	Filename9,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	ILDAFilenameEnd,a0
			jsr	MoveString

			lea	Filename9,a0
			lea	Dir2,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			move.l	SN,d2
			move.l	SN2,d1
			cmp.l	d1,d2
			beq.s	.Cool

			clr.b	PirateFlag

.Cool:			cmpi.b	#1,d0
			beq.l	Scope

			lea	StatusSave7,a0
			bsr	PrintStatus

			lea	Filename9,a0
			jsr	MakeFileName2

			lea	Filename4,a0
			lea	ILDAName2,a1
			moveq	#16,d0
			jsr	MoveString6

			clr.w	ILDAFrame2
			move.w	#1,ILDATotal3

			bsr.s	SaveILDAIt
			cmpi.b	#1,d0
			beq.l	Error5
			cmpi.b	#2,d0
			beq.l	Error3

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

SaveILDAIt:		move.l	#1006,OpenType
SaveILDAIt2:		move.l	Len0,d0			;Get mem
			lsl.l	#1,d0			;X

			move.l	Len1,d1			;Y
			lsl.l	#1,d1
			add.l	d1,d0

			tst.b	D3Flag
			beq.s	.3DSkip
			move.l	Len0,d1			;Z
			lsl.l	#1,d1
			add.l	d1,d0

.3DSkip:		move.l	Len0,d1			;Status
			lsl.l	#1,d1
			add.l	d1,d0
			addi.l	#32,d0
			move.l	d0,ILDAMemSize2

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,ILDAMemPtr2
			beq	.Error

			lea	ILDAFrameString,a0	;Make header
			movea.l	d0,a1			;ID
			jsr	MoveString
			clr.b	(a1)+
			clr.b	(a1)+

			move.b	#1,(a1)+		;2D

			tst.b	D3Flag
			beq.s	.3DSkip2
			clr.b	-1(a1)

.3DSkip2:		movea.l	a1,a2			;Name
			move.l	#$20202020,(a1)+
			move.l	#$20202020,(a1)+
			move.l	#$20202020,(a1)+
			move.l	#$20202020,(a1)+
			movea.l	a2,a1

			lea	ILDAName2,a0
			jsr	MoveString
			move.b	#$20,-(a1)

			movea.l	a2,a1			;Points
			adda.w	#16,a1
			move.w	Len0+2,(a1)+

			move.w	ILDAFrame2,(a1)+	;Frame

			move.w	ILDATotal3,(a1)+	;Total

			clr.b	(a1)+			;Scanner

			clr.b	(a1)+			;Future

			movea.l	DrawMemPtr,a0
			movea.l	a0,a2
			adda.w	#MaxPoints,a2
			movea.l	a2,a3
			adda.w	#MaxPoints,a3
			move.l	Len0,d0
			subq.l	#1,d0

.Loop:			move.b	(a0)+,d1		;X
			ext.w	d1
			muls	#256,d1
			move.w	d1,(a1)+

			move.b	(a2)+,d1		;Y
			ext.w	d1
			muls	#256,d1
			move.w	d1,(a1)+

			tst.b	D3Flag
			beq.s	.3DSkip3

			move.b	(a3)+,d1		;Z
			ext.w	d1
			muls	#256,d1
			move.w	d1,(a1)+

.3DSkip3:		move.w	#$0001,(a1)+		;Colour & status
			dbf	d0,.Loop

			move.w	#$8000,-(a1)		;Last

			move.l	OpenType,d2		;Open file
			jsr	OpenFile2
			beq	.Error2

			cmpi.l	#1006,OpenType		;New?
			beq.s	.Skip

			move.l	d0,d1			;Move last
			moveq	#-32,d2
			moveq	#1,d3
			movea.l	DosBase,a6
			jsr	_LVOSeek(a6)
			tst.l	d0
			bmi.s	.Error3

.Skip:			move.l	FilePtr,d1		;Header & data
			move.l	ILDAMemPtr2,d2
			move.l	ILDAMemSize2,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error3

			move.l	FilePtr,d1		;End header
			move.l	#ILDALastHeader,d2
			moveq	#32,d3
			movea.l	DosBase,a6
			jsr	_LVOWrite(a6)
			tst.l	d0
			bmi.s	.Error3

			jsr	CloseFile
			bsr.s	.FreeMem
			sub.l	d0,d0
			rts

.FreeMem:		movea.l	ILDAMemPtr2,a1
			move.l	ILDAMemSize2,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

.Error3:		jsr	CloseFile
.Error2:		bsr.s	.FreeMem
			moveq	#1,d0
			rts

.Error:			moveq	#2,d0
			rts

SaveILDAPack:		jsr	SeqStuffOff
			jsr	AllOff

			tst.l	SeqMemSize
			beq.l	Error7

			lea	Filename10,a0
			lea	Dir2,a1
			lea	SaveReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			cmpi.b	#1,d0
			beq.l	Scope

			clr.b	FirstTimeFlag

SaveILDAPack2:		clr.w	PackCount
			clr.w	ILDAFrame2
			clr.b	ForRealFlag
			clr.b	PackCheckFlag

.Next:			lea	StatusProcessing,a0
			bsr	PrintStatus

			movea.l	SeqMemPtr,a1		;Find screens
			movea.l	a1,a2
			adda.l	SeqMemSize,a2

.Loop:			move.b	(a1)+,d0
			cmpi.b	#"S",d0
			beq.s	.Skip
			cmpi.b	#"s",d0
			beq.s	.Skip
			cmpa.l	a1,a2
			bhi.s	.Loop

			tst.b	PackCheckFlag
			bne	.Okay

			tst.b	ForRealFlag
			bne	.Done

			tst.w	PackCount
			beq.s	.None

			move.b	#1,ForRealFlag
			move.w	PackCount,ILDATotal3
			bra.s	.Next

.None:			bsr	FlashScreen
			lea	StatusSave6,a0
			bsr	PrintStatus
			jmp	Scope

.Skip:			lea	PreloadCmd2,a0
			jsr	CmpString
			beq.s	.Loop

			movea.l	a1,a3
			subq.l	#2,a3

			adda.w	#5,a1
			cmpa.l	a1,a2
			bls.l	Error

			cmpi.b	#"2",(a1)
			bne.s	.Skip2

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

.Skip2:			cmpi.b	#" ",(a1)
			bne	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			cmpi.b	#'"',(a1)
			bne	.Loop

			addq.l	#1,a1
			cmpa.l	a1,a2
			bls.l	Error

			lea	ASCIIBuffer,a0

.Loop2:			move.b	(a1)+,d0
			cmpi.b	#'"',d0
			beq.s	.Skip3
			move.b	d0,(a0)+
			cmpa.l	a1,a2
			bls.s	.Skip3
			cmpa.l	#ASCIIBuffer+99,a0
			blo.s	.Loop2

.Skip3:			clr.b	(a0)

			tst.b	PackCheckFlag
			beq.s	.Skip4

			move.l	a1,-(sp)
			move.l	a2,-(sp)
			lea	ASCIIBuffer+100,a0
			lea	ASCIIBuffer,a1
			jsr	CmpString2
			movea.l	(sp)+,a2
			movea.l	(sp)+,a1
			beq	.Loop

			clr.b	PackCheckFlag
			bra	.Skip8

.Skip4:			move.l	a1,PackPtr2
			move.l	a2,PackPtr3

			lea	ASCIIBuffer,a0
			lea	ASCIIBuffer+200,a1
			jsr	MoveString

			lea	ASCIIBuffer,a0
			lea	ASCIIBuffer+100,a1
			jsr	UpperString
			clr.b	(a1)

			move.b	#1,PackCheckFlag
			movea.l	a3,a2
			movea.l	SeqMemPtr,a1
			bra	.Loop

.Okay:			clr.b	PackCheckFlag

			tst.b	ForRealFlag
			bne.s	.Skip5

			addq.w	#1,PackCount
			bra	.Skip8

.Skip5:			lea	StatusLoad2,a0
			bsr	PrintStatus

			lea	ASCIIBuffer+200,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString

			jsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq.l	Error29

			lea	ScreenString,a0		;Screen?
			movea.l	FileMemPtr,a1
			jsr	CmpString
			beq	.Error

			lea	ASCIIBuffer,a0		;Find filename
			movea.l	a0,a1

.Loop3:			tst.b	(a0)+
			bne.s	.Loop3

.Loop4:			move.b	-(a0),d0
			cmpi.b	#"/",d0
			beq.s	.Found
			cmpi.b	#":",d0
			beq.s	.Found
			cmpa.l	a0,a1
			blo.s	.Loop4
			bra.s	.Found2

.Found:			addq.l	#1,a0
.Found2:		lea	ILDAName2,a1
			moveq	#16,d0
			jsr	MoveString6

			movea.l	FileMemPtr,a0
			bsr	MakeScreen
			jsr	FreeFileMem

			tst.b	DrawMode
			beq.l	Scope

			lea	ILDAName2,a0
			lea	Filename4,a1
			jsr	MoveString

			lea	StatusSave3b,a0
			lea	ASCIIBuffer,a1
			jsr	MoveString
			subq.l	#1,a1
			lea	ILDAName2,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			lea	Filename10,a0
			jsr	MakeFileName2

			move.l	#1005,OpenType

			tst.b	FirstTimeFlag
			bne.s	.Skip6

			move.b	#1,FirstTimeFlag
			move.l	#1006,OpenType

.Skip6:			bsr	SaveILDAIt2
			cmpi.b	#1,d0
			beq.s	.Error2
			cmpi.b	#2,d0
			beq.s	.Error3

			addq.w	#1,ILDAFrame2

.Skip8:			move.l	PackPtr2,a1
			move.l	PackPtr3,a2
			bra	.Loop

.Done:			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.Error3:		jsr	FreeFileMem
			jmp	Error3

.Error2:		jsr	FreeFileMem
			jmp	Error5

.Error:			jsr	FreeFileMem
			jmp	Error17

AppendILDAPack:		jsr	SeqStuffOff
			jsr	AllOff

			tst.l	SeqMemSize
			beq.l	Error7

			lea	Filename10,a0
			lea	Dir2,a1
			lea	AppendReqText,a2
			move.l	#$80000028,ReqFRTags+16	;Use flags
			jsr	ReqFile2
			beq.l	Error3

			cmpi.b	#1,d0
			beq.l	Scope

			clr.b	FirstTimeFlag

			lea	Filename10,a0
			jsr	MakeFileName2
			jsr	GetLock
			beq	SaveILDAPack2

			jsr	Unlock
			move.b	#1,FirstTimeFlag
			bra	SaveILDAPack2


;Points menu:

HalfOff:		clr.l	XDataDragPtrTemp
			clr.b	DragMode
			bsr	TextOff
			bsr	LineOff
			bsr	ArcOff
			bsr	BoxOff
			bsr	EllipseOff
			clr.b	MergeMode
			clr.b	LastFlag
			rts

ShiftAll:		tst.b	ShiftFlag
			bne.s	ShiftLast
			bsr.s	HalfOff
			bra.s	Shift

ShiftLast:		move.b	#1,LastFlag

Shift:			jsr	SeqStuffOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			bchg	#0,ShiftMode
			beq.s	.On

			clr.b	ShiftFlag2
			tst.b	ShiftFlag3
			beq.s	.None
			clr.b	ShiftFlag3
			bsr	UndoUpdate

.None:			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2
			clr.b	XShiftPos
			clr.b	YShiftPos
			clr.b	ZShiftPos
			clr.b	XShiftPos2
			clr.b	YShiftPos2
			clr.b	ZShiftPos2

			bsr	ShowPoints
			lea	StatusArrowKeys,a0
			jsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

ShiftOff:		tst.b	ShiftMode
			beq.s	.End
			clr.b	ShiftMode
			clr.b	ShiftFlag2
			tst.b	ShiftFlag3
			beq.s	.End
			clr.b	ShiftFlag3
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	UndoUpdate
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

ShiftPosOff:		bsr	GetMousePos
			move.b	XMousePos,XMousePosTemp
			move.b	YMousePos,YMousePosTemp
			bsr.s	ShiftPos3
			bsr.s	ShiftOff
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

ShiftPos:		bsr	GetMousePos
			move.b	XMousePos,XMousePosTemp
			move.b	YMousePos,YMousePosTemp
			move.b	#1,ShiftFlag2
			jmp	Scope

ShiftPos2:		tst.b	ShiftFlag2
			beq.s	.End
			cmpi.b	#2,MiscCount2
			bhs.s	ShiftPos3
.End:			rts

ShiftPos3:		clr.b	ShiftFlag2

			move.b	XShiftPos2,d0		;X
			ext.w	d0
			move.b	XMousePosTemp,d1
			ext.w	d1
			sub.w	d0,d1

			jsr	GetLastStartPtr
			ext.w	d1

.Loop:			move.b	(a0)+,d2
			ext.w	d2
			add.w	d1,d2
			addi.w	#127,d2
			cmpi.w	#254,d2
			bls.s	.Skip

			sub.l	d1,d1
			bra.s	.YZPos

.Skip:			dbf	d0,.Loop

			jsr	GetLastStartPtr

.Loop2:			add.b	d1,(a0)+
			dbf	d0,.Loop2
			add.b	d1,XShiftPos

.YZPos:			tst.b	DrawScopeFlag
			beq.s	.YPos

			tst.b	D3Flag
			beq.s	.YPos

			tst.b	TopViewFlag
			beq.s	.YPos

			move.b	ZShiftPos2,d0		;Z
			ext.w	d0
			move.b	YMousePosTemp,d2
			ext.w	d2
			sub.w	d0,d2

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			ext.w	d2
			neg.w	d2

.ZLoop3:		move.b	(a0)+,d3
			ext.w	d3
			add.w	d2,d3
			addi.w	#127,d3
			cmpi.w	#254,d3
			bls.s	.ZSkip2

			sub.l	d2,d2
			bra.s	.Check

.ZSkip2:		dbf	d0,.ZLoop3

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0

.ZLoop4:		add.b	d2,(a0)+
			dbf	d0,.ZLoop4
			add.b	d2,ZShiftPos
			bra.s	.Check

.YPos:			move.b	YShiftPos2,d0		;Y
			ext.w	d0
			move.b	YMousePosTemp,d2
			ext.w	d2
			sub.w	d0,d2

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			ext.w	d2

.Loop3:			move.b	(a0)+,d3
			ext.w	d3
			add.w	d2,d3
			addi.w	#127,d3
			cmpi.w	#254,d3
			bls.s	.Skip2

			sub.l	d2,d2
			bra.s	.Check

.Skip2:			dbf	d0,.Loop3

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

.Loop4:			add.b	d2,(a0)+
			dbf	d0,.Loop4
			add.b	d2,YShiftPos

.Check:			move.b	XMousePosTemp,XShiftPos2
			move.b	YMousePosTemp,YShiftPos2
			move.b	YMousePosTemp,ZShiftPos2
			clr.b	MiscCount2

			tst.b	d1
			bne.s	.Skip3

			tst.b	d2
			bne.s	.Skip3
			rts

.Skip3:			move.b	#1,ShiftFlag3
			move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

PrintShiftPos:		bsr	ShowPoints

			lea	ShiftPosText,a0
			bsr	MoveString
			lea	-1(a1),a0
			move.b	XShiftPos,d0
			bsr	ConvertCordinate

			tst.b	DrawScopeFlag
			beq.s	.YPos

			tst.b	D3Flag
			beq.s	.YPos

			tst.b	TopViewFlag
			beq.s	.YPos

			lea	ShiftPosText3,a0
			bsr	MoveString
			lea	-1(a1),a0
			move.b	ZShiftPos,d0
			bsr	ConvertCordinate
			bra.s	.Skip

.YPos:			lea	ShiftPosText2,a0
			bsr	MoveString
			lea	-1(a1),a0
			move.b	YShiftPos,d0
			bsr	ConvertCordinate

.Skip:			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			rts

RollAll:		tst.b	ShiftFlag
			bne.s	RollLast
			bsr	HalfOff
			bra.s	Roll

RollLast:		move.b	#1,LastFlag

Roll:			jsr	SeqStuffOff
			bsr	ShiftOff
			bsr	ResizeOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bchg	#0,RollMode
			beq.s	.On

			tst.b	RollFlag3
			beq.s	.Skip
			clr.b	RollFlag3
			bsr	UndoUpdate

.Skip:			bsr	RollDotOff
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2
			clr.b	RollFlag

			bsr	ShowPoints
			lea	StatusArrowKeys,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			bsr	RollDotOn
			jmp	Scope

RollOff:		tst.b	RollMode
			beq.s	.End
			clr.b	RollMode
			movem.l	d0-d7/a0-a6,-(sp)
			tst.b	RollFlag3
			beq.s	.Skip
			clr.b	RollFlag3
			bsr	UndoUpdate
.Skip:			bsr	RollDotOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

SetRollCount:		tst.b	RollFlag
			bne.s	.End
			move.b	#1,RollFlag
			clr.w	RollCount
			move.w	d0,RollCount2
			addq.w	#1,RollCount2
.End:			rts

PrintRollCount:		move.w	RollCount,d0
			bmi.s	.Skip

			cmp.w	RollCount2,d0
			blo.s	.Skip2
			clr.w	RollCount
			bra.s	.Skip2

.Skip:			move.w	RollCount2,RollCount
			subq.w	#1,RollCount

.Skip2:			bsr	ShowPoints
			lea	StatusRollPoints,a0
			bsr	MoveString

			sub.l	d0,d0
			move.w	RollCount,d0
			lea	-1(a1),a0
			bsr	HEXtoASCII

			movea.l	a1,a0
			move.b	#"/",(a0)+
			sub.l	d0,d0
			move.w	RollCount2,d0
			bsr	HEXtoASCII

			move.b	#$20,(a1)+
			move.b	#"(",(a1)+
			move.l	a1,-(sp)
			jsr	GetLastStartPtr		;Get X
			move.b	(a0),d0
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0

.TSkip:			move.b	(a0),d1			;Get Y/Z
			movea.l	(sp)+,a0
			move.l	d1,-(sp)
			bsr	ConvertCordinate
			movea.l	a1,a0
			move.b	#",",(a0)+
			move.l	(sp)+,d0
			bsr	ConvertCordinate
			move.b	#")",(a1)+
			clr.b	(a1)

			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			rts

RollDotFlash:		tst.b	RollMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount2
			blo.s	.End

			moveq	#2,d0
			bchg	#0,RollFlag2
			beq.s	RollDot
			moveq	#1,d0
			bra.s	RollDot

RollDotOff:		tst.b	RollFlag2
			beq.s	.End
			clr.b	RollFlag2
			moveq	#1,d0
			bra.s	RollDot
.End:			rts

RollDotOn:		move.b	#1,RollFlag2
			moveq	#2,d0

RollDot:		bsr	CheckDrawMode

			jsr	GetLastStartPtr		;Get X
			move.b	(a0),d0
			adda.w	#MaxPoints,a0
			move.b	(a0),d2			;Get Y

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0
			move.b	(a0),d2			;Get Z
			neg.b	d2

.TSkip:			bsr	CheckHiResX
			bsr	CheckHiResY
			move.l	d0,-(sp)
			move.l	d1,-(sp)

			addq.w	#1,d0
			bsr	Pixel

			move.l	(sp),d1
			move.l	4(sp),d0
			subq.w	#1,d0
			bsr	Pixel

			move.l	(sp),d1
			move.l	4(sp),d0
			addq.w	#1,d1
			bsr	Pixel

			move.l	(sp)+,d1
			move.l	(sp)+,d0
			subq.w	#1,d1
			bsr	Pixel

			bsr	CheckDrawMode2
			clr.b	MiscCount2
			rts

ResizeAll:		tst.b	ShiftFlag
			bne.s	ResizeLast
			bsr	HalfOff
			bra.s	Resize

ResizeLast:		move.b	#1,LastFlag

Resize:			clr.b	AttachStatus
			clr.b	TriggerFlag
			clr.b	MorphStatus
			clr.b	DrawStatus
			jsr	RecordUpdate
			clr.b	RecordStatus
			bsr	ShiftOff
			bsr	RollOff
			bsr	RotateItOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bchg	#0,ResizeMode
			beq.s	.On

			bsr	TemplateOff
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2

			jsr	GetLastStartPtr
			bsr.s	FindMaxMin
			move.b	d0,XSizeMin
			move.b	d0,XSizeMinTemp
			move.b	d1,XSizeMax
			move.b	d1,XSizeMaxTemp

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0

.TSkip:			bsr.s	FindMaxMin
			move.b	d0,YSizeMin
			move.b	d0,YSizeMinTemp
			move.b	d1,YSizeMax
			move.b	d1,YSizeMaxTemp

			bsr	ShowPoints
			lea	StatusArrowKeys,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			bsr	TemplateOn
			jmp	Scope

FindMaxMin:		move.l	d0,d3
			move.b	#$ff,d0
			sub.l	d1,d1

.Loop:			move.b	(a0)+,d2
			addi.b	#127,d2
			cmp.b	d2,d0
			bls.s	.Skip
			move.b	d2,d0
.Skip:			cmp.b	d2,d1
			bhs.s	.Skip2
			move.b	d2,d1
.Skip2:			dbf	d3,.Loop
			rts

FindCenter:		bsr.s	FindMaxMin
			andi.l	#$ff,d0
			andi.l	#$ff,d1
			add.w	d0,d1
			addq.w	#1,d1
			lsr.w	#1,d1
			subi.b	#127,d1
			rts

ResizeOff:		tst.b	ResizeMode
			beq.s	.End
			clr.b	ResizeMode
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	TemplateOff
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

ResizePos:		bsr	GetMousePos

			sub.l	d0,d0
			move.b	XMousePos,d0
			addi.b	#127,d0
			sub.l	d1,d1
			move.b	XSizeMaxTemp,d1
			sub.l	d2,d2
			move.b	XSizeMinTemp,d2
			add.w	d1,d2
			addq.w	#1,d2
			lsr.w	#1,d2
			cmp.b	d2,d0
			blo.s	.Skip
			beq.s	.Skip2

			sub.w	d1,d0
			bra.s	.Skip3

.Skip:			move.w	d0,d1
			move.b	XSizeMinTemp,d0
			sub.w	d1,d0
			bra.s	.Skip3

.Skip2:			sub.l	d0,d0

.Skip3:			sub.l	d1,d1
			move.b	YMousePos,d1
			addi.b	#127,d1
			sub.l	d2,d2
			move.b	YSizeMaxTemp,d2
			sub.l	d3,d3
			move.b	YSizeMinTemp,d3
			add.w	d2,d3
			addq.w	#1,d3
			lsr.w	#1,d3
			cmp.b	d3,d1
			blo.s	.Skip4
			beq.s	.Skip5

			sub.w	d2,d1
			bra.s	.Skip6

.Skip4:			move.w	d1,d2
			move.b	YSizeMinTemp,d1
			sub.w	d2,d1
			bra.s	.Skip6

.Skip5:			sub.l	d1,d1

.Skip6:			sub.l	d2,d2
			move.b	XSizeMaxTemp,d2
			sub.l	d3,d3
			move.b	XSizeMinTemp,d3

			tst.w	d0
			bmi.s	.Skip8

			move.w	#254,d4
			sub.w	d2,d4
			cmp.w	d4,d0
			bls.s	.Skip7
			move.w	d4,d0

.Skip7:			cmp.w	d3,d0
			bls.s	.Skip8
			move.w	d3,d0

.Skip8:			add.b	d0,d2
			sub.b	d0,d3
			cmp.b	d2,d3
			bls.s	.Skip9
			sub.l	d0,d0

.Skip9:			sub.l	d2,d2
			move.b	YSizeMaxTemp,d2
			sub.l	d3,d3
			move.b	YSizeMinTemp,d3

			tst.w	d1
			bmi.s	.Skip11

			move.w	#254,d4
			sub.w	d2,d4
			cmp.w	d4,d1
			bls.s	.Skip10
			move.w	d4,d1

.Skip10:		cmp.w	d3,d1
			bls.s	.Skip11
			move.w	d3,d1

.Skip11:		add.b	d1,d2
			sub.b	d1,d3
			cmp.b	d2,d3
			bls.s	.Skip12
			sub.l	d1,d1

.Skip12:		move.l	d0,-(sp)
			move.l	d1,-(sp)
			bsr	TemplateOff
			move.l	(sp)+,d1
			move.l	(sp)+,d0

			add.b	d0,XSizeMaxTemp
			sub.b	d0,XSizeMinTemp
			add.b	d1,YSizeMaxTemp
			sub.b	d1,YSizeMinTemp
			bsr	TemplateOn
			bsr.s	PrintSizeAdjust
			jmp	Scope

PrintSizeAdjust:	bsr	ShowPoints
			lea	SizeAdjustText,a0
			bsr	MoveString

			move.b	XSizeMax,d1
			move.b	XSizeMin,d2
			move.b	XSizeMaxTemp,d3
			bsr.s	.CalcPercent

			lea	-1(a1),a0
			bsr	HEXtoASCII

			move.b	YSizeMax,d1
			move.b	YSizeMin,d2
			move.b	YSizeMaxTemp,d3
			bsr.s	.CalcPercent

			lea	SizeAdjustText2,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			lea	SizeAdjustText3,a0

.TSkip:			bsr	MoveString
			lea	-1(a1),a0
			bsr	HEXtoASCII
			move.b	#"%",(a1)+
			clr.b	(a1)

			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			rts

.CalcPercent:		andi.l	#$ff,d1
			andi.l	#$ff,d2
			andi.l	#$ff,d3

			move.l	d1,d4
			add.w	d2,d4
			addq.w	#1,d4
			lsr.w	#1,d4
			sub.b	d4,d1
			beq.s	.Zero
			sub.b	d4,d3
			beq.s	.Zero
			cmp.w	d1,d3
			beq.s	.Zero

			moveq	#100,d0
			mulu	d3,d0
			divu	d1,d0

			addq.w	#1,d1
			lsr.w	#1,d1
			move.l	d0,d2
			swap	d2
			cmp.w	d1,d2
			blo.s	.RSkip
			addq.w	#1,d0
.RSkip:			andi.l	#$ffff,d0
			rts

.Zero:			moveq	#100,d0
			rts

TemplateFlash:		tst.b	ResizeMode
			bne.s	.Flash
.End:			rts

.Flash:			cmpi.b	#2,MiscCount2
			blo.s	.End

			moveq	#2,d0
			bchg	#0,TemplateFlag
			beq.s	Template
			moveq	#1,d0
			bra.s	Template

TemplateOff:		tst.b	TemplateFlag
			beq.s	.End
			clr.b	TemplateFlag
			moveq	#1,d0
			bra.s	Template
.End:			rts

TemplateOn:		move.b	#1,TemplateFlag
			moveq	#2,d0

Template:		bsr	CheckDrawMode

			bsr.s	.GetXMin
			bsr.s	.GetYMin
			bsr	Move

			bsr.s	.GetXMax
			bsr.s	.GetYMin
			bsr	Draw

			bsr.s	.GetXMax
			bsr.s	.GetYMax
			bsr	Draw

			bsr.s	.GetXMin
			bsr.s	.GetYMax
			bsr	Draw

			bsr.s	.GetXMin
			bsr.s	.GetYMin
			bsr	Draw

			bsr.s	.GetXMax
			bsr.s	.GetYMax
			bsr	Draw

			bsr.s	.GetXMin
			bsr.s	.GetYMax
			bsr	Move

			bsr.s	.GetXMax
			bsr.s	.GetYMin
			bsr	Draw
			bsr	CheckDrawMode2
			clr.b	MiscCount2
			rts

.GetXMin:		move.b	XSizeMinTemp,d0
			bra.s	.CheckHiResX

.GetXMax:		move.b	XSizeMaxTemp,d0
			bra.s	.CheckHiResX

.GetYMin:		move.b	YSizeMinTemp,d2
			bra.s	.CheckHiResY

.GetYMax:		move.b	YSizeMaxTemp,d2
			bra.s	.CheckHiResY

.CheckHiResX:		tst.b	DrawScopeFlag
			bne.s	.Skip
			tst.b	HiResFlag
			beq.s	.Skip
			subi.b	#127,d0
			ext.w	d0
			ext.l	d0
			divs	#2,d0
			addi.b	#127,d0

.Skip:			andi.l	#$ff,d0
			addi.w	#ScopeX+4,d0
			rts

.CheckHiResY:		tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			subi.b	#127,d2
			neg.b	d2
			addi.b	#127,d2

.TSkip:			tst.b	DrawScopeFlag
			bne.s	.Skip2
			tst.b	HiResFlag
			beq.s	.Skip2
			subi.b	#127,d2
			ext.w	d2
			ext.l	d2
			divs	#2,d2
			addi.b	#127,d2

.Skip2:			andi.w	#$ff,d2
			tst.b	BigScreenFlag
			beq.s	.Skip3
			move.w	#ScopeY+129+127,d1
			bra.s	.Skip4

.Skip3:			addq.b	#1,d2
			lsr.b	#1,d2
			move.w	#ScopeY+129,d1

.Skip4:			sub.w	d2,d1
			rts

ResizeIt:		clr.b	RBufferFlag

			tst.b	SBufferFlag
			beq.s	.FirstTime

			jsr	GetLastStartPtr
			cmpa.l	LastStartPtrTemp,a0
			bne.s	.FirstTime

			cmp.l	LastStartSizeTemp,d0
			bne.s	.FirstTime

			bsr	CopyBuffer

			jsr	GetLastStartPtr
			bsr	FindMaxMin
			move.b	d0,XSizeMin
			move.b	d1,XSizeMax

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0

.TSkip:			bsr	FindMaxMin
			move.b	d0,YSizeMin
			move.b	d1,YSizeMax
			bra.s	.SSkip

.FirstTime:		jsr	GetLastStartPtr
			move.l	a0,LastStartPtrTemp
			move.l	d0,LastStartSizeTemp
			move.b	#1,SBufferFlag
			bsr	MakeBuffer

.SSkip:			jsr	GetLastStartPtr
			move.l	d0,d7
			move.b	XSizeMax,d0
			move.b	XSizeMin,d1
			move.b	XSizeMaxTemp,d2
			bsr	.AdjustSize
			move.l	d0,-(sp)

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip2

			tst.b	D3Flag
			beq.s	.TSkip2

			tst.b	TopViewFlag
			beq.s	.TSkip2

			adda.w	#MaxPoints,a0

.TSkip2:		move.l	d0,d7
			move.b	YSizeMax,d0
			move.b	YSizeMin,d1
			move.b	YSizeMaxTemp,d2
			bsr.s	.AdjustSize
			move.l	(sp)+,d1
			bne.s	.Changed
			tst.l	d0
			bne.s	.Changed

			bsr	ResizeOff
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.Changed:		move.l	#$01010101,AD0Update
			bsr	UndoUpdate
			bsr	ResizeOff
			move.b	#1,DrawUpdateFlag

			bsr	ShowPoints
			lea	StatusResize,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.AdjustSize:		andi.l	#$ff,d0
			andi.l	#$ff,d1
			andi.l	#$ff,d2

			move.l	d0,d3
			add.w	d1,d3
			addq.w	#1,d3
			lsr.w	#1,d3
			sub.b	d3,d0
			beq.s	.None
			sub.b	d3,d2
			beq.s	.None
			cmp.w	d0,d2
			beq.s	.None

.Loop:			sub.l	d4,d4
			move.b	(a0)+,d4
			addi.b	#127,d4
			cmp.b	d3,d4
			beq.s	.Skip3
			blo.s	.Skip

			move.w	d4,d5
			sub.b	d3,d5
			bsr.s	.RoundOff

			add.b	d5,d4
			bra.s	.Skip2

.Skip:			move.w	d3,d5
			sub.b	d4,d5
			bsr.s	.RoundOff

			sub.b	d5,d4

.Skip2:			subi.b	#127,d4
			move.b	d4,-1(a0)

.Skip3:			dbf	d7,.Loop
			moveq	#1,d0
			rts

.None:			sub.l	d0,d0
			rts

.RoundOff:		move.b	d5,d6
			mulu	d2,d5
			divu	d0,d5

			move.l	d0,-(sp)
			addq.w	#1,d0
			lsr.w	#1,d0
			move.l	d5,d1
			swap	d1
			cmp.w	d0,d1
			blo.s	.RSkip
			addq.b	#1,d5
.RSkip:			move.l	(sp)+,d0
			sub.b	d6,d5
			rts

RotateAll:		tst.b	ShiftFlag
			bne.s	RotateLast
			bsr	HalfOff
			bra.s	Rotate

RotateLast:		move.b	#1,LastFlag

Rotate:			jsr	SeqStuffOff
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bchg	#0,RotateMode
			beq.s	.On

			clr.b	RBufferFlag
			tst.b	RotateFlag2
			beq.s	.Skip
			clr.b	RotateFlag2
			bsr	UndoUpdate

.Skip:			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2
			clr.w	SpinAngle
			clr.w	RotateAngle
			clr.w	RotateAngleTemp
			clr.b	RotateFlag3

			bsr	ShowPoints
			lea	StatusRotate5,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

RotatePos:		bsr	GetMousePos3D
			move.b	XMousePos3D,XRotatePos
			move.b	YMousePos3D,YRotatePos
			move.b	ZMousePos,ZRotatePos
			move.b	#1,RotateFlag3

			bsr	ShowPoints
			lea	StatusRotate4,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

RotateItOff:		tst.b	RotateMode
			beq.s	.End
			clr.b	RotateMode
			clr.b	RBufferFlag
			tst.b	RotateFlag2
			beq.s	.End
			clr.b	RotateFlag2
			movem.l	d0-d7/a0-a6,-(sp)
			bsr	UndoUpdate
			movem.l	(sp)+,d0-d7/a0-a6
.End:			rts

RotateIt:		clr.b	SBufferFlag

			tst.b	RBufferFlag
			beq.s	.FirstTime

			jsr	GetLastStartPtr
			cmpa.l	LastStartPtrTemp,a0
			bne.s	.FirstTime

			cmp.l	LastStartSizeTemp,d0
			bne.s	.FirstTime

			bsr	CopyBuffer

			tst.w	RotateAngle
			bne.s	.DoIt

			tst.w	SpinAngle
			bne.s	.DoIt

			clr.b	RotateFlag2
			bra	.Skip2

.FirstTime:		jsr	GetLastStartPtr
			move.l	a0,LastStartPtrTemp
			move.l	d0,LastStartSizeTemp
			move.b	#1,RBufferFlag
			bsr	MakeBuffer

.DoIt:			tst.b	RotateFlag3
			beq.s	.GetCenter

			move.b	XRotatePos,RotateDCX
			move.b	YRotatePos,RotateDCY

			tst.b	DrawScopeFlag
			beq.s	.Calc

			tst.b	D3Flag
			beq.s	.Calc

			tst.b	TopViewFlag
			beq.s	.Calc

			move.b	ZRotatePos,RotateDCY
			bra.s	.Calc

.GetCenter:		jsr	GetLastStartPtr
			bsr	FindCenter
			move.b	d1,RotateDCX

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0

.TSkip:			bsr	FindCenter
			move.b	d1,RotateDCY

.Calc:			jsr	GetLastStartPtr
			movea.l	a0,a1
			adda.w	#MaxPoints,a1
			move.l	d0,d1

			tst.b	DrawScopeFlag
			beq.s	.TSkip2

			tst.b	D3Flag
			beq.s	.TSkip2

			tst.b	TopViewFlag
			beq.s	.TSkip2

			adda.w	#MaxPoints,a1

.TSkip2:		move.w	RotateAngle,d0
			beq.s	.Skip
			bsr	RotateXY
			move.b	#1,RotateFlag2

.Skip:			tst.b	RotateFlag3
			beq.s	.GetCenter2

			move.b	YRotatePos,RotateDCX
			move.b	ZRotatePos,RotateDCY
			bra.s	.Calc2

.GetCenter2:		jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			bsr	FindCenter
			move.b	d1,RotateDCX

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			bsr	FindCenter
			move.b	d1,RotateDCY

.Calc2:			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			movea.l	a0,a1
			adda.w	#MaxPoints,a1
			move.l	d0,d1

			move.w	SpinAngle,d0
			beq.s	.Skip2
			bsr	RotateXY
			move.b	#1,RotateFlag2

.Skip2:			move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag

			bsr	ShowPoints

			lea	StatusRotate,a0
			tst.b	DrawScopeFlag
			beq.s	.TSkip3

			tst.b	D3Flag
			beq.s	.TSkip3

			tst.b	TopViewFlag
			beq.s	.TSkip3

			lea	StatusRotate2,a0

.TSkip3:		move.w	RotateAngle,d0
			cmp.w	RotateAngleTemp,d0
			bne.s	.Skip3

			lea	StatusRotate3,a0
			bsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	SpinAngle,d0
			bra.s	.Skip4

.Skip3:			bsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	RotateAngle,d0

.Skip4:			bsr	HEXtoASCII
			move.b	#"°",(a1)+
			clr.b	(a1)
			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			move.w	RotateAngle,RotateAngleTemp
			jmp	Scope

MakeBuffer:		bsr	KillBuffer

			move.l	Len0,d0
			add.l	Len1,d0

			tst.b	D3Flag
			beq.s	.D3Skip

			add.l	Len0,d0

.D3Skip:		move.l	d0,BufferMemSize

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,BufferMemPtr
			beq.s	.Error

			movea.l	d0,a0

			movea.l	DrawMemPtr,a1		;X data
			move.l	Len0,d0
			subq.l	#1,d0

.Loop:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop

			movea.l	DrawMemPtr,a1		;Y data
			adda.w	#MaxPoints,a1
			move.l	Len1,d0
			subq.l	#1,d0

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop2

			tst.b	D3Flag
			beq.s	.End

			movea.l	DrawMemPtr,a1		;Z data
			adda.w	#MaxPoints*2,a1
			move.l	Len0,d0
			subq.l	#1,d0

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop3
.End:			rts

.Error:			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			rts

KillBuffer:		move.l	BufferMemPtr,d0
			beq.s	.End
			movea.l	d0,a1
			move.l	BufferMemSize,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			clr.l	BufferMemPtr
.End:			rts

CopyBuffer:		jsr	GetLastStartPtr
			movea.l	a0,a1
			suba.l	DrawMemPtr,a0
			adda.l	BufferMemPtr,a0
			movea.l	a0,a2
			adda.l	Len0,a2
			movea.l	a2,a4
			adda.l	Len1,a4
			movea.l	a1,a3
			adda.w	#MaxPoints,a3
			movea.l	a3,a5
			adda.w	#MaxPoints,a5
			move.l	d0,d1
			move.l	d0,d2

.Loop:			move.b	(a0)+,(a1)+		;Copy X
			dbf	d0,.Loop

.Loop2:			move.b	(a2)+,(a3)+		;Copy Y
			dbf	d1,.Loop2

			tst.b	D3Flag
			beq.s	.End

.Loop3:			move.b	(a4)+,(a5)+		;Copy Z
			dbf	d2,.Loop3
.End:			rts

RotateXY:		lea	SineData,a2
			lsl.w	#1,d0
			adda.w	d0,a2
			move.w	(a2),d6
			move.w	180(a2),d7

.Loop:			move.b	(a0),d0
			sub.b	RotateDCX,d0
			ext.w	d0
			move.w	d0,d2
			muls	d7,d0
			divs	#32767,d0

			move.l	d0,d5
			swap	d5
			bmi.s	.ROff

			cmpi.w	#16384,d5
			blo.s	.ROff2
			addq.w	#1,d0
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d5
			bhi.s	.ROff2
			tst.w	d5
			beq.s	.ROff2
			subq.w	#1,d0

.ROff2:			move.b	(a1),d4
			sub.b	RotateDCY,d4
			ext.w	d4
			move.w	d4,d3
			muls	d6,d4
			divs	#32767,d4

			move.l	d4,d5
			swap	d5
			bmi.s	.ROff3

			cmpi.w	#16384,d5
			blo.s	.ROff4
			addq.w	#1,d4
			bra.s	.ROff4

.ROff3:			cmpi.w	#-16384,d5
			bhi.s	.ROff4
			tst.w	d5
			beq.s	.ROff4
			subq.w	#1,d4

.ROff4:			sub.w	d4,d0
			add.b	RotateDCX,d0
			move.b	d0,(a0)+

			muls	d7,d3
			divs	#32767,d3

			move.l	d3,d5
			swap	d5
			bmi.s	.ROff5

			cmpi.w	#16384,d5
			blo.s	.ROff6
			addq.w	#1,d3
			bra.s	.ROff6

.ROff5:			cmpi.w	#-16384,d5
			bhi.s	.ROff6
			tst.w	d5
			beq.s	.ROff6
			subq.w	#1,d3

.ROff6:			muls	d6,d2
			divs	#32767,d2

			move.l	d2,d5
			swap	d5
			bmi.s	.ROff7

			cmpi.w	#16384,d5
			blo.s	.ROff8
			addq.w	#1,d2
			bra.s	.ROff8

.ROff7:			cmpi.w	#-16384,d5
			bhi.s	.ROff8
			tst.w	d5
			beq.s	.ROff8
			subq.w	#1,d2

.ROff8:			add.w	d2,d3
			add.b	RotateDCY,d3
			move.b	d3,(a1)+
			dbf	d1,.Loop
			rts

FlipXAll:		tst.b	ShiftFlag
			bne.s	FlipXLast
			bsr	HalfOff
			bra.s	FlipX

FlipXLast:		move.b	#1,LastFlag

FlipX:			jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			jsr	GetLastStartPtr
			bsr	FindCenter

			jsr	GetLastStartPtr
			bsr.s	FlipIt

			move.b	#1,AD0Update
			move.b	#1,AD3Update
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusFlipX,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

FlipIt:			move.b	(a0),d2
			sub.b	d1,d2
			neg.b	d2
			add.b	d1,d2
			move.b	d2,(a0)+
			dbf	d0,FlipIt
			rts

FlipYAll:		tst.b	ShiftFlag
			bne.s	FlipYLast
			bsr	HalfOff
			bra.s	FlipY

FlipYLast:		move.b	#1,LastFlag

FlipY:			jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			bsr	FindCenter

			jsr	GetLastStartPtr
			adda.w	#MaxPoints,a0
			bsr.s	FlipIt

			move.b	#1,AD1Update
			move.b	#1,AD2Update
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusFlipY,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

FlipZAll:		bsr	HalfOff
			bra.s	FlipZ

FlipZLast:		move.b	#1,LastFlag

FlipZ:			jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			tst.b	D3Flag
			beq.s	.Error

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			bsr	FindCenter

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			bsr	FlipIt

			move.l	#$01010101,AD0Update
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusFlipZ,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Error:			bsr	FlashScreen
			lea	Error27Text,a0
			bsr	PrintStatus
			jmp	Scope

AddPointsAll:		bsr	HalfOff
			bra.s	AddPoints

AddPointsLast:		move.b	#1,LastFlag

AddPoints:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			add.l	Len0,d0
			cmpi.l	#MaxPoints,d0
			bhi.l	Error22

			move.l	#MaxPoints*3,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,DrawMemPtr2
			beq.l	Error3

			bsr	TurnItOff2
			bsr	JustDoIt

.Loop:			move.b	(a0)+,d0		;X
			move.b	d0,(a2)+
			ext.w	d0
			move.b	(a0),d1
			ext.w	d1
			add.w	d1,d0
			addq.w	#1,d0
			lsr.w	#1,d0
			move.b	d0,(a2)+

			move.b	(a1)+,d0		;Y
			move.b	d0,(a3)+
			ext.w	d0
			move.b	(a1),d1
			ext.w	d1
			add.w	d1,d0
			addq.w	#1,d0
			lsr.w	#1,d0
			move.b	d0,(a3)+

			tst.b	D3Flag
			beq.s	.D3Skip

			move.b	(a4)+,d0		;Z
			move.b	d0,(a5)+
			ext.w	d0
			move.b	(a4),d1
			ext.w	d1
			add.w	d1,d0
			addq.w	#1,d0
			lsr.w	#1,d0
			move.b	d0,(a5)+

.D3Skip:		dbf	d2,.Loop

			move.l	XDataPtr,d0
			sub.l	a0,d0
			subq.l	#1,d0
			move.l	d0,d1

.Loop2:			move.b	(a0)+,(a2)+
			move.b	(a1)+,(a3)+
			dbf	d0,.Loop2

			move.l	a2,XDataPtr
			move.l	a3,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip2

.Loop3:			move.b	(a4)+,(a5)+
			dbf	d1,.Loop3

			move.l	a5,ZDataPtr

.D3Skip2:		jsr	GetLastStartPtr
			bsr	AdjustLastPtrs2

			move.l	DrawMemPtr2,d0
			move.l	d0,Loc0
			move.l	d0,Loc3
			addi.l	#MaxPoints,d0
			move.l	d0,Loc1
			move.l	d0,Loc2

			bsr	GetDrawLen2
			bsr	CheckDefault
			bsr	CheckFreq
			bsr	RestartSound
			bsr	FreeDrawMem2
			move.l	DrawMemPtr2,DrawMemPtr
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag
			bsr	FreeCharBSMem

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusAddPoints,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

JustDoIt:		jsr	GetLastStartPtr		;X/Y/Z
			movea.l	DrawMemPtr,a1
			move.l	a0,d0
			sub.l	a1,d0
			subq.l	#1,d0
			bmi.s	.Skip

			movea.l	DrawMemPtr2,a0
			movea.l	a0,a2
			adda.w	#MaxPoints,a2
			movea.l	a2,a4
			adda.w	#MaxPoints,a4
			movea.l	a1,a3
			adda.w	#MaxPoints,a3
			movea.l	a3,a5
			adda.w	#MaxPoints,a5
			move.l	d0,d1

.Loop:			move.b	(a1)+,(a0)+
			move.b	(a3)+,(a2)+
			dbf	d0,.Loop

			tst.b	D3Flag
			beq.s	.Skip

.Loop2:			move.b	(a5)+,(a4)+
			dbf	d1,.Loop2

.Skip:			jsr	GetLastStartPtr		;X/Y/Z
			movea.l	a0,a1
			adda.w	#MaxPoints,a1
			movea.l	a1,a4
			adda.w	#MaxPoints,a4

			movea.l	a0,a2
			suba.l	DrawMemPtr,a2
			adda.l	DrawMemPtr2,a2

			movea.l	a2,a3
			adda.w	#MaxPoints,a3
			movea.l	a3,a5
			adda.w	#MaxPoints,a5

			move.l	d0,d2
			subq.l	#1,d2
			rts

AdjustLastPtrs2:	lea	XDataTextPtr,a1
			lea	XDataTextSize,a2
			moveq	#9,d1
			move.l	DrawMemPtr,d2
			move.l	DrawMemPtr2,d3
			move.l	a0,d4
			add.l	d0,d4
			addq.l	#1,d4

.Loop:			tst.l	(a1)
			beq.s	.Skip3

			cmpa.l	(a1),a0
			bhi.s	.Skip2

			cmp.l	(a1),d4
			bhi.s	.Skip
			add.l	d0,(a1)
			bra.s	.Skip2

.Skip:			move.l	(a1),d6
			sub.l	a0,d6
			add.l	d6,d6
			add.l	a0,d6
			move.l	d6,(a1)
			move.l	(a2),d7
			add.l	d7,(a2)
			subq.l	#1,(a2)

.Skip2:			sub.l	d2,(a1)
			add.l	d3,(a1)

.Skip3:			addq.l	#4,a1
			addq.l	#4,a2
			dbf	d1,.Loop
			rts

GetDrawLen2:		move.l	XDataPtr,d0
			sub.l	DrawMemPtr2,d0
			move.l	d0,Len0
			move.l	d0,Len3

			move.l	YDataPtr,d0
			sub.l	DrawMemPtr2,d0
			subi.l	#MaxPoints,d0
			move.l	d0,Len1
			move.l	d0,Len2
			rts

SubPointsAll:		bsr	HalfOff
			bra.s	SubPoints

SubPointsLast:		move.b	#1,LastFlag

SubPoints:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bsr	TurnItOff2

			jsr	GetLastStartPtr
			movea.l	a0,a2
			movea.l	a0,a1
			adda.w	#MaxPoints,a1
			movea.l	a1,a3
			movea.l	a1,a4
			adda.w	#MaxPoints,a4
			movea.l	a4,a5

			move.l	d0,d1
			lsr.l	#1,d0
			move.l	d0,d2

.Loop:			move.b	(a0),(a2)+		;X/Y
			move.b	(a1),(a3)+
			addq.l	#2,a0
			addq.l	#2,a1
			dbf	d0,.Loop

			tst.b	D3Flag
			beq.s	.D3Skip

.Loop2:			move.b	(a4),(a5)+		;Z
			addq.l	#2,a4
			dbf	d2,.Loop2

.D3Skip:		btst	#0,d1
			bne.s	.Skip

			subq.l	#1,a0
			subq.l	#1,a1
			subq.l	#1,a4

.Skip:			move.l	XDataPtr,d0
			sub.l	a0,d0
			subq.l	#1,d0
			bmi.s	.Skip2
			move.l	d0,d1

.Loop3:			move.b	(a0)+,(a2)+		;X/Y
			move.b	(a1)+,(a3)+
			dbf	d0,.Loop3

			tst.b	D3Flag
			beq.s	.Skip2

.Loop4:			move.b	(a4)+,(a5)+		;Z
			dbf	d1,.Loop4

.Skip2:			move.l	a2,XDataPtr
			move.l	a3,YDataPtr
			move.l	a5,ZDataPtr

			jsr	GetLastStartPtr
			bsr.s	AdjustLastPtrs3

			bsr	GetDrawLen
			bsr	CheckFreq
			bsr	RestartSound
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag
			bsr	FreeCharBSMem

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusSubPoints,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

AdjustLastPtrs3:	lea	XDataTextPtr,a1
			lea	XDataTextSize,a2
			moveq	#9,d1
			move.l	a0,d4
			addq.l	#1,d0
			add.l	d0,d4
			lsr.l	#1,d0

.Loop:			tst.l	(a1)
			beq.s	.Skip3

			cmpa.l	(a1),a0
			bhi.s	.Skip3

			cmp.l	(a1),d4
			bhi.s	.Skip
			sub.l	d0,(a1)
			bra.s	.Skip3

.Skip:			move.l	(a1),d6
			sub.l	a0,d6
			move.l	d6,d5
			addq.l	#1,d6
			lsr.l	#1,d6
			add.l	a0,d6
			move.l	d6,(a1)
			move.l	(a2),d7
			btst	#0,d5
			bne.s	.Skip2
			addq.l	#1,d7
.Skip2:			lsr.l	#1,d7
			move.l	d7,(a2)
			bne.s	.Skip3
			clr.l	(a1)

.Skip3:			addq.l	#4,a1
			addq.l	#4,a2
			dbf	d1,.Loop
			rts

SmoothPointsAll:	tst.b	ShiftFlag
			bne.s	SmoothPointsLast
			bsr	HalfOff
			bra.s	SmoothPoints

SmoothPointsLast:	move.b	#1,LastFlag

SmoothPoints:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			move.l	#MaxPoints*3,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,DrawMemPtr2
			beq.l	Error3

			bsr	TurnItOff2
			bsr	CopyLastPtrs

			jsr	GetLastStartPtr		;Find smallest d
			movea.l	a0,a1
			adda.w	#MaxPoints,a1
			subq.l	#1,d0

			moveq	#-1,d6

.Loop:			move.b	(a0)+,d1
			ext.w	d1
			move.b	(a0),d3
			ext.w	d3
			sub.w	d3,d1
			muls	d1,d1

			move.b	(a1)+,d2
			ext.w	d2
			move.b	(a1),d3
			ext.w	d3
			sub.w	d3,d2
			muls	d2,d2

			add.l	d2,d1
			beq.s	.Skip
			cmp.l	d1,d6
			bls.s	.Skip
			move.l	d1,d6
.Skip:			dbf	d0,.Loop

			lsl.l	#2,d6

			bsr	JustDoIt
			movea.l	DrawMemPtr2,a6
			adda.w	#MaxPoints,a6
			move.l	d2,d7

.Loop2:			cmpa.l	a2,a6
			bls	.Overflow

			move.b	(a0)+,d0		;X
			move.b	d0,(a2)+
			ext.w	d0
			move.w	d0,d4
			move.b	(a0),d1
			ext.w	d1
			sub.w	d1,d4
			add.w	d1,d0
			addq.w	#1,d0
			lsr.w	#1,d0

			move.b	(a1)+,d1		;Y
			move.b	d1,(a3)+
			ext.w	d1
			move.w	d1,d5
			move.b	(a1),d2
			ext.w	d2
			sub.w	d2,d5
			add.w	d2,d1
			addq.w	#1,d1
			lsr.w	#1,d1

			tst.b	D3Flag
			beq.s	.D3Skip

			move.b	(a4)+,(a5)+		;Z

.D3Skip:		muls	d4,d4			;d
			muls	d5,d5
			add.l	d5,d4
			cmp.l	d4,d6
			bhi.s	.Skip2

			cmpa.l	a2,a6
			bls	.Overflow

			move.b	d0,(a2)+
			move.b	d1,(a3)+

			tst.b	D3Flag
			beq.s	.D3Skip2

			move.b	-1(a4),d2		;Z
			ext.w	d2
			move.b	(a4),d3
			ext.w	d3
			add.w	d3,d2
			addq.w	#1,d2
			lsr.w	#1,d2
			move.b	d2,(a5)+

.D3Skip2:		bsr	AdjustLastPtrs4

.Skip2:			dbf	d7,.Loop2

			move.l	XDataPtr,d0
			sub.l	a0,d0
			subq.l	#1,d0
			move.l	d0,d1

.Loop3:			cmpa.l	a2,a6
			bls	.Overflow

			move.b	(a0)+,(a2)+
			move.b	(a1)+,(a3)+
			dbf	d0,.Loop3

			tst.b	D3Flag
			beq.s	.D3Skip3

.Loop4:			move.b	(a4)+,(a5)+
			dbf	d1,.Loop4

.D3Skip3:		move.l	a2,d0
			sub.l	DrawMemPtr2,d0
			cmp.l	Len0,d0
			beq	.None

			move.l	a2,XDataPtr
			move.l	a3,YDataPtr
			move.l	a5,ZDataPtr

			bsr	AdjustLastPtrs4a

			move.l	DrawMemPtr2,d0
			move.l	d0,Loc0
			move.l	d0,Loc3
			addi.l	#MaxPoints,d0
			move.l	d0,Loc1
			move.l	d0,Loc2

			bsr	GetDrawLen2
			bsr	CheckDefault
			bsr	CheckFreq
			bsr	RestartSound
			jsr	FreeDrawMem2
			move.l	DrawMemPtr2,DrawMemPtr
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag
			bsr	FreeCharBSMem

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusSmoothPoints,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Overflow:		bsr.s	.FreeMem
			jmp	Error22

.None:			bsr.s	.FreeMem
			bsr	FlashScreen
			lea	StatusCenter2,a0
			bsr	PrintStatus
			jmp	Scope

.FreeMem:		movea.l	DrawMemPtr2,a1
			move.l	#MaxPoints*3,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			rts

AdjustLastPtrs4:	move.l	a5,-(sp)
			move.l	a6,-(sp)

			lea	XDataTextPtr2,a5
			lea	XDataTextSize2,a6
			moveq	#9,d0

.Loop:			tst.l	(a5)
			beq.s	.Skip2

			cmpa.l	(a5),a0
			bhi.s	.Skip

			addq.l	#1,(a5)
			bra.s	.Skip2

.Skip:			move.l	(a5),d1
			add.l	(a6),d1
			cmpa.l	d1,a0
			bhi.s	.Skip2
			addq.l	#1,(a6)

.Skip2:			addq.l	#4,a5
			addq.l	#4,a6
			dbf	d0,.Loop

			movea.l	(sp)+,a6
			movea.l	(sp)+,a5
			rts

AdjustLastPtrs4a:	lea	XDataTextPtr2,a0
			lea	XDataTextPtr,a1
			lea	XDataTextSize2,a2
			lea	XDataTextSize,a3
			moveq	#9,d0
			move.l	DrawMemPtr,d1
			move.l	DrawMemPtr2,d2

.Loop:			move.l	(a2)+,(a3)+
			move.l	(a0)+,(a1)
			beq.s	.Skip
			sub.l	d1,(a1)
			add.l	d2,(a1)
.Skip:			addq.l	#4,a1
			dbf	d0,.Loop
			rts

CopyLastPtrs:		lea	XDataTextPtr,a0
			lea	XDataTextPtr2,a1
			lea	XDataTextSize,a2
			lea	XDataTextSize2,a3
			moveq	#9,d0

.Loop:			move.l	(a0)+,(a1)+
			move.l	(a2)+,(a3)+
			dbf	d0,.Loop
			rts

AddWeightAll:		tst.b	ShiftFlag
			bne.s	AddWeightLast
			bsr	HalfOff
			bra.s	AddWeight

AddWeightLast:		move.b	#1,LastFlag

AddWeight:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			addq.l	#1,d0
			add.l	Len0,d0
			cmpi.l	#MaxPoints,d0
			bhi.l	Error22

			move.l	#MaxPoints*3,d0
			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			move.l	d0,DrawMemPtr2
			beq.l	Error3

			bsr	TurnItOff2
			bsr	JustDoIt
			move.l	d0,d1

.Loop:			move.b	(a0),(a2)+		;X/Y
			move.b	(a0)+,(a2)+
			move.b	(a1),(a3)+
			move.b	(a1)+,(a3)+
			dbf	d0,.Loop

			tst.b	D3Flag
			beq.s	.D3Skip

.Loop2:			move.b	(a4),(a5)+		;Z
			move.b	(a4)+,(a5)+
			dbf	d1,.Loop2

.D3Skip:		move.l	XDataPtr,d0
			sub.l	a0,d0
			subq.l	#1,d0
			bmi.s	.Skip
			move.l	d0,d1

.Loop3:			move.b	(a0)+,(a2)+		;X/Y
			move.b	(a1)+,(a3)+
			dbf	d0,.Loop3

			tst.b	D3Flag
			beq.s	.Skip

.Loop4:			move.b	(a4)+,(a5)+		;Z
			dbf	d1,.Loop4

.Skip:			move.l	a2,XDataPtr
			move.l	a3,YDataPtr
			move.l	a5,ZDataPtr

			jsr	GetLastStartPtr
			bsr.s	AdjustLastPtrs5

			move.l	DrawMemPtr2,d0
			move.l	d0,Loc0
			move.l	d0,Loc3
			addi.l	#MaxPoints,d0
			move.l	d0,Loc1
			move.l	d0,Loc2

			bsr	GetDrawLen2
			bsr	CheckDefault
			bsr	CheckFreq
			bsr	RestartSound
			jsr	FreeDrawMem2
			move.l	DrawMemPtr2,DrawMemPtr
			bsr	UndoUpdate
			bsr	FreeCharBSMem

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bsr	ShowPoints
			lea	StatusWeightPoints,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

AdjustLastPtrs5:	lea	XDataTextPtr,a1
			lea	XDataTextSize,a2
			moveq	#9,d1
			move.l	DrawMemPtr,d2
			move.l	DrawMemPtr2,d3
			move.l	a0,d4
			addq.l	#1,d0
			add.l	d0,d4

.Loop:			tst.l	(a1)
			beq.s	.Skip3

			cmpa.l	(a1),a0
			bhi.s	.Skip2

			cmp.l	(a1),d4
			bhi.s	.Skip
			add.l	d0,(a1)
			bra.s	.Skip2

.Skip:			move.l	(a1),d6
			sub.l	a0,d6
			add.l	d6,d6
			add.l	a0,d6
			move.l	d6,(a1)
			move.l	(a2),d7
			add.l	d7,(a2)

.Skip2:			sub.l	d2,(a1)
			add.l	d3,(a1)

.Skip3:			addq.l	#4,a1
			addq.l	#4,a2
			dbf	d1,.Loop
			rts

RemFirstAll:		bsr	HalfOff
			bra.s	RemFirst

RemFirstLast:		move.b	#1,LastFlag

RemFirst:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bsr	TurnItOff2

			jsr	GetLastStartPtr
			bsr.s	JustDoIt2

			bsr	ShowPoints
			lea	StatusRemFirst,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

JustDoIt2:		lea	1(a0),a1
			movea.l	a0,a2
			adda.w	#MaxPoints,a2
			lea	1(a2),a3
			movea.l	a2,a5
			adda.w	#MaxPoints,a5
			lea	1(a5),a6

			movea.l	a0,a4

			move.l	XDataPtr,d0
			sub.l	a0,d0
			subq.l	#2,d0
			bmi.s	.Skip
			move.l	d0,d1

.Loop:			move.b	(a1)+,(a0)+		;X/Y
			move.b	(a3)+,(a2)+
			dbf	d0,.Loop

			tst.b	D3Flag
			beq.s	.Skip

.Loop2:			move.b	(a6)+,(a5)+		;Z
			dbf	d1,.Loop2

.Skip:			subq.l	#1,XDataPtr
			subq.l	#1,YDataPtr
			subq.l	#1,ZDataPtr

			bsr	AdjustLastPtrs7

			bsr	GetDrawLen
			bsr	CheckFreq
			bsr	RestartSound
			bsr	UndoUpdate
			move.b	#1,DrawUpdateFlag
			bsr	FreeCharBSMem
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			rts

RemLastAll:		bsr	HalfOff
			bra.s	RemLast

RemLastLast:		move.b	#1,LastFlag

RemLast:		jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			beq.l	Error16

			bsr	TurnItOff2

			jsr	GetLastStartPtr
			adda.l	d0,a0
			bsr	JustDoIt2

			jsr	ShowPoints
			lea	StatusRemLast,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

BendAll:		bsr	HalfOff
			bra.s	Bend

BendLast:		move.b	#1,LastFlag

Bend:			jsr	SeqStuffOff
			jsr	OtherHalfOff

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			jsr	GetLastStartPtr
			cmpi.w	#2,d0
			blo.l	Error16

			tst.b	D3Flag
			beq	.Error

			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenBendAmountWindow
			tst.l	d0
			bne	.Done

			movea.l	BendAmountGadgets,a0
			move.w	BendAmount,d0
			bsr	SetGadget

			movea.l	BendAmountGadgets,a0
			movea.l	BendAmountWnd,a1
			jsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	BendAmountWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne	.Abort

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	BendAmountGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			tst.l	d0
			beq.s	.Bad

			cmpi.l	#100,d0
			bls.s	.WSkip

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.WSkip:			move.w	d0,BendAmount

.NoChange:		jsr	CloseBendAmountWindow

.Done:			jsr	OpenMenu

			jsr	GetLastStartPtr
			bsr	FindMaxMin
			move.b	d0,XSizeMinBend
			sub.b	d0,d1
			sub.l	d2,d2
			move.b	d1,d2
			addq.b	#1,d1
			andi.l	#$ff,d1
			lsr.w	#1,d1
			move.b	d1,XCenterBend

			move.l	#32512,d1
			divu	d2,d1
			move.w	d1,ScaleBend

			jsr	GetLastStartPtr
			movea.l	a0,a1
			adda.w	#MaxPoints*2,a1

.Loop:			sub.l	d1,d1
			move.b	(a0)+,d1
			addi.b	#127,d1
			sub.b	XSizeMinBend,d1

			cmp.b	XCenterBend,d1
			bhs.s	.Skip

			move.b	d1,d3
			move.b	XCenterBend,d1
			sub.b	d3,d1
			bra.s	.Skip2

.Skip:			sub.b	XCenterBend,d1
.Skip2:			mulu	ScaleBend,d1
			mulu.l	#32767,d1
			divu	#16256,d1

			mulu	BendAmount,d1
			divu	#100,d1

			cmpi.w	#$7fff,d1
			bls.s	.Skip3
			move.w	#$7fff,d1

.Skip3:			lea	SineData,a2
			sub.l	d2,d2

.Loop2:			cmp.w	(a2)+,d1
			bls.s	.Found
			addq.l	#2,d2
			bra.s	.Loop2

.Found:			lea	SineData+180,a2
			adda.l	d2,a2
			move.w	(a2),d1
			muls	#127,d1
			divs	#32767,d1

			move.l	d1,d4
			swap	d4
			bmi.s	.ROff

			cmpi.w	#16384,d4
			blo.s	.ROff2
			addq.b	#1,d1
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d4
			bhi.s	.ROff2
			tst.w	d4
			beq.s	.ROff2
			subq.b	#1,d1

.ROff2:			move.b	d1,(a1)+
			dbf	d0,.Loop

			move.l	a1,ZDataPtr

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0
			bsr	FindCenter

			jsr	GetLastStartPtr
			adda.w	#MaxPoints*2,a0

.Loop3:			sub.b	d1,(a0)+
			dbf	d0,.Loop3

			move.l	#$01010101,AD0Update
			bsr	UndoUpdate

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			tst.b	TopViewFlag
			beq.s	.Skip4
			move.b	#1,DrawUpdateFlag

.Skip4:			jsr	ShowPoints
			lea	StatusBent,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Error:			bsr	FlashScreen
			lea	Error27Text,a0
			bsr	PrintStatus
			jmp	Scope

.Abort:			jsr	CloseBendAmountWindow
			jsr	OpenMenu
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

InsertPoint:		jsr	SeqStuffOff
			bsr	HalfOff
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			jsr	Mouse3DOff
			clr.b	InsertMode2
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			cmpi.l	#1,Len0
			bls.l	Error16

			bchg	#0,InsertMode
			beq.s	.On

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			clr.b	InsertFlag
			bsr	CheckCenter
			bsr	TurnItOff2

			jsr	ShowPoints
			lea	StatusInsertPoint,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

InsertPos:		jsr	GetMousePos

			tst.b	NoDragFlag
			bne.s	.Skip

			tst.b	MouseFlag
			bne.s	InsertIt2

.Skip:			jsr	ShowPXY
			jmp	Scope

InsertIt:		jsr	GetMousePos
InsertIt2:		jsr	GetMousePos3D2
InsertIt2a:		movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq.l	Error16

			cmpi.l	#1,Len0
			bls.l	Error16

			movea.l	DrawMemPtr,a0
			movea.l	a0,a1
			adda.w	#MaxPoints,a1

			move.l	XDataPtr,d3
			sub.l	a0,d3
			subq.l	#2,d3

			moveq	#-1,d7
			movea.l	a0,a4
			movea.l	a1,a5

			move.b	XMousePos3D,d0
			ext.w	d0
			movea.w	d0,a2

			move.b	YMousePos3D,d0
			ext.w	d0
			movea.w	d0,a3

			tst.b	DrawScopeFlag
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a1
			movea.l	a1,a5

			move.b	ZMousePos,d0
			ext.w	d0
			movea.w	d0,a3

.Loop:			move.l	d3,-(sp)

			move.b	(a0)+,d0
			ext.w	d0
			move.w	d0,d5
			sub.w	a2,d0
			muls	d0,d0

			move.b	(a1)+,d1
			ext.w	d1
			move.w	d1,d6
			sub.w	a3,d1
			muls	d1,d1
			add.l	d1,d0

			bsr	GetSqrRoot
			movea.l	d0,a6

			move.b	(a0),d0
			ext.w	d0
			sub.w	d0,d5
			sub.w	a2,d0
			muls	d0,d0

			move.b	(a1),d1
			ext.w	d1
			sub.w	d1,d6
			sub.w	a3,d1
			muls	d1,d1
			add.l	d1,d0

			bsr	GetSqrRoot
			adda.l	d0,a6

			muls	d5,d5
			muls	d6,d6
			add.l	d6,d5
			move.l	d5,d0

			bsr	GetSqrRoot
			suba.l	d0,a6

			cmp.l	a6,d7
			blo.s	.Skip

			move.l	a6,d7
			movea.l	a0,a4
			movea.l	a1,a5

.Skip:			move.l	(sp)+,d3
			dbf	d3,.Loop

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			suba.w	#MaxPoints,a5

.TSkip:			movea.l	XDataPtr,a0		;X
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			cmpa.l	a0,a1
			bhi.s	.Skip2

			subq.l	#1,a0
			subq.l	#1,XDataPtr

.Skip2:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a4,d0
			subq.l	#1,d0
			bmi.s	.Skip3

.Loop2:			move.b	-(a0),-(a1)
			dbf	d0,.Loop2

.Skip3:			move.b	XMousePos3D,(a0)
			addq.l	#1,XDataPtr

			movea.l	YDataPtr,a0		;Y
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip4

			subq.l	#1,a0
			subq.l	#1,YDataPtr

.Skip4:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a5,d0
			subq.l	#1,d0
			bmi.s	.Skip5

.Loop3:			move.b	-(a0),-(a1)
			dbf	d0,.Loop3

.Skip5:			move.b	YMousePos3D,(a0)
			addq.l	#1,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip

			adda.w	#MaxPoints,a5

			movea.l	ZDataPtr,a0		;Z
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			cmpa.l	a0,a1
			bhi.s	.Skip6

			subq.l	#1,a0
			subq.l	#1,ZDataPtr

.Skip6:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a5,d0
			subq.l	#1,d0
			bmi.s	.Skip7

.Loop4:			move.b	-(a0),-(a1)
			dbf	d0,.Loop4

.Skip7:			move.b	ZMousePos,(a0)
			addq.l	#1,ZDataPtr

.D3Skip:		bsr.s	AdjustLastPtrs6

			jsr	GetDrawLen
			bsr	CheckDefault
			jsr	CheckFreq
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.b	#1,DragFlag
			clr.l	DragCount

			jsr	ShowPoints
			lea	StatusInsertPoint2,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			move.b	#1,InsertFlag
			jmp	Scope

AdjustLastPtrs6:	lea	XDataTextPtr,a1
			lea	XDataTextSize,a2
			moveq	#9,d1
			move.l	XDataPtr,d2

.Loop:			tst.l	(a1)
			beq.s	.Skip3

			cmpa.l	(a1),a4
			bhi.s	.Skip2

			addq.l	#1,(a1)
			cmp.l	(a1),d2
			bhi.s	.Skip
			clr.l	(a1)
			bra.s	.Skip3

.Skip:			move.l	(a1),d3
			add.l	(a2),d3
			cmp.l	d3,d2
			bhs.s	.Skip3
			subq.l	#1,(a2)
			bra.s	.Skip3

.Skip2:			move.l	(a1),d3
			add.l	(a2),d3
			cmpa.l	d3,a4
			bhi.s	.Skip3
			addq.l	#1,(a2)
			bra.s	.Skip

.Skip3:			addq.l	#4,a1
			addq.l	#4,a2
			dbf	d1,.Loop
			rts

InsertPoint2:		jsr	SeqStuffOff
			bsr	HalfOff
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			jsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	DeleteMode
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			cmpi.l	#1,Len0
			bls.l	Error16

			cmpi.b	#2,InsertMode2
			beq.s	.Skip

			bchg	#0,InsertMode2
			beq.s	.On

.Skip:			clr.b	InsertMode2
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			clr.b	InsertFlag2
			bsr	CheckCenter
			bsr	TurnItOff2

			jsr	ShowPoints
			lea	StatusInsertPoint3,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

InsertPos2:		jsr	GetMousePos

			tst.b	NoDragFlag
			bne.s	.Skip

			tst.b	MouseFlag
			bne.s	InsertIt4

.Skip:			jsr	ShowPXY
			jmp	Scope

InsertIt3:		jsr	GetMousePos

InsertIt4:		movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq.l	Error16

			cmpi.l	#1,Len0
			bls.l	Error16

			cmpi.b	#2,InsertMode2
			beq	.Skip

			movea.l	a0,a1
			adda.w	#MaxPoints,a1

			move.b	XMousePos,d0
			move.b	YMousePos,d1
			move.l	Len0,d2
			subq.l	#1,d2
			suba.l	a4,a4

			tst.b	DrawScopeFlag
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a1
			neg.b	d1

.Loop:			cmp.b	(a0)+,d0
			beq.s	.Maybe
			addq.l	#1,a1
.Next:			dbf	d2,.Loop

			tst.l	a4			;Found?
			bne.s	.GotIt

			jsr	ShowPXY
			jmp	Scope

.Maybe:			cmp.b	(a1)+,d1
			bne.s	.Next

			movea.l	a0,a4

			tst.b	MagGlassFlag
			beq.s	.Next

			cmpi.w	#1,StackNumber
			bls.s	.Next

			subq.w	#1,StackNumber2
			bne.s	.Next

.GotIt:			cmpa.l	XDataPtr,a4
			beq.s	.Stupid

			move.l	a4,InsertPtr
			move.b	#2,InsertMode2

			clr.w	StackNumber
			move.w	#1,StackNumber2

			jsr	ShowPoints
			lea	StatusInsertPoint,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Stupid:		clr.w	StackNumber
			move.w	#1,StackNumber2

			clr.b	InsertMode2
			bsr	FlashScreen
			jsr	ShowPoints
			lea	StatusInsertPoint4,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Skip:			jsr	GetMousePos3D2

			movea.l	InsertPtr,a4
			movea.l	a4,a5
			adda.w	#MaxPoints,a5

			movea.l	XDataPtr,a0		;X
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints,a1
			cmpa.l	a0,a1
			bhi.s	.Skip2

			subq.l	#1,a0
			subq.l	#1,XDataPtr

.Skip2:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a4,d0
			subq.l	#1,d0
			bmi.s	.Skip3

.Loop2:			move.b	-(a0),-(a1)
			dbf	d0,.Loop2

.Skip3:			move.b	XMousePos3D,(a0)
			addq.l	#1,XDataPtr

			movea.l	YDataPtr,a0		;Y
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*2,a1
			cmpa.l	a0,a1
			bhi.s	.Skip4

			subq.l	#1,a0
			subq.l	#1,YDataPtr

.Skip4:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a5,d0
			subq.l	#1,d0
			bmi.s	.Skip5

.Loop3:			move.b	-(a0),-(a1)
			dbf	d0,.Loop3

.Skip5:			move.b	YMousePos3D,(a0)
			addq.l	#1,YDataPtr

			tst.b	D3Flag
			beq.s	.D3Skip

			adda.w	#MaxPoints,a5

			movea.l	ZDataPtr,a0		;Z
			movea.l	DrawMemPtr,a1
			adda.w	#MaxPoints*3,a1
			cmpa.l	a0,a1
			bhi.s	.Skip6

			subq.l	#1,a0
			subq.l	#1,ZDataPtr

.Skip6:			lea	1(a0),a1
			move.l	a0,d0
			sub.l	a5,d0
			subq.l	#1,d0
			bmi.s	.Skip7

.Loop4:			move.b	-(a0),-(a1)
			dbf	d0,.Loop4

.Skip7:			move.b	ZMousePos,(a0)
			addq.l	#1,ZDataPtr

.D3Skip:		addq.l	#1,InsertPtr

			bsr	AdjustLastPtrs6

			jsr	GetDrawLen
			bsr	CheckDefault
			jsr	CheckFreq
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.b	#1,DragFlag
			clr.l	DragCount

			jsr	ShowPoints
			lea	StatusInsertPoint2,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			move.b	#1,InsertFlag2
			jmp	Scope

DeletePoint:		jsr	SeqStuffOff
			bsr	HalfOff
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			jsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	MoveMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			bchg	#0,DeleteMode
			beq.s	.On

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			clr.b	DeleteFlag
			bsr	CheckCenter
			bsr	TurnItOff2

			jsr	ShowPoints
			lea	StatusDeletePoint,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

DeletePos:		jsr	GetMousePos

			tst.b	NoDragFlag
			bne.s	.Skip

			tst.b	MouseFlag
			bne.s	DeleteIt2

.Skip:			jsr	ShowPXY
			jmp	Scope

DeleteIt:		jsr	GetMousePos
DeleteIt2:		movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq.l	Error16

			movea.l	a0,a1
			adda.w	#MaxPoints,a1

			move.b	XMousePos,d0
			move.b	YMousePos,d1
			move.l	Len0,d2
			subq.l	#1,d2
			suba.l	a4,a4

			tst.b	DrawScopeFlag
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a1
			neg.b	d1

.Loop:			cmp.b	(a0)+,d0
			beq.s	.Maybe
			addq.l	#1,a1
.Next:			dbf	d2,.Loop

			tst.l	a4			;Found?
			bne.s	.GotIt

			jsr	ShowPXY
			jmp	Scope

.Maybe:			cmp.b	(a1)+,d1
			bne.s	.Next

			movea.l	a0,a4
			movea.l	a1,a5
			move.l	d2,d3

			tst.b	MagGlassFlag
			beq.s	.Next

			cmpi.w	#1,StackNumber
			bls.s	.Next

			subq.w	#1,StackNumber2
			bne.s	.Next

.GotIt:			movea.l	a4,a0
			movea.l	a5,a1

			subq.l	#1,a4

			subq.w	#1,d3
			bmi.s	.Skip

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			suba.w	#MaxPoints,a5
			movea.l	a5,a1

.TSkip:			lea	-1(a0),a2		;X/Y
			lea	-1(a1),a3
			move.l	d3,d2

.Loop2:			move.b	(a0)+,(a2)+
			move.b	(a1)+,(a3)+
			dbf	d3,.Loop2

			tst.b	D3Flag
			beq.s	.Skip

			adda.w	#MaxPoints,a5		;Z
			lea	-1(a5),a3

.Loop3:			move.b	(a5)+,(a3)+
			dbf	d2,.Loop3

.Skip:			subq.l	#1,XDataPtr
			subq.l	#1,YDataPtr
			subq.l	#1,ZDataPtr

			bsr	AdjustLastPtrs7

			jsr	GetDrawLen

			tst.l	Len0
			bne.s	.Skip2

			movea.l	XDataPtr,a0
			move.l	a0,XDrawPtr
			clr.b	(a0)

			movea.l	YDataPtr,a0
			move.l	a0,YDrawPtr
			clr.b	(a0)

			movea.l	ZDataPtr,a0
			move.l	a0,ZDrawPtr
			clr.b	(a0)

			move.l	#1,Len0
			move.l	#1,Len1
			move.l	#1,Len2
			move.l	#1,Len3

			jsr	ClrLastPtrs

.Skip2:			jsr	CheckFreq
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag

			move.b	#1,DragFlag
			clr.l	DragCount

			clr.w	StackNumber
			move.w	#1,StackNumber2

			jsr	ShowPoints
			lea	StatusDeletePoint2,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			move.b	#1,DeleteFlag
			jmp	Scope

AdjustLastPtrs7:	lea	XDataTextPtr,a1
			lea	XDataTextSize,a2
			moveq	#9,d1
			move.l	DrawMemPtr,d4

.Loop:			tst.l	(a1)
			beq.s	.Skip2

			cmpa.l	(a1),a4
			bhs.s	.Skip
			subq.l	#1,(a1)
			cmp.l	(a1),d4
			bls.s	.Skip2
			clr.l	(a1)
			bra.s	.Skip2

.Skip:			move.l	(a1),d2
			add.l	(a2),d2
			cmpa.l	d2,a4
			bhs.s	.Skip2
			subq.l	#1,(a2)
			bne.s	.Skip2
			clr.l	(a1)

.Skip2:			addq.l	#4,a1
			addq.l	#4,a2
			dbf	d1,.Loop
			rts

MovePoint:		jsr	SeqStuffOff
			bsr	HalfOff
			bsr	ShiftOff
			bsr	RollOff
			bsr	ResizeOff
			bsr	RotateItOff
			jsr	Mouse3DOff
			clr.b	InsertMode
			clr.b	InsertMode2
			clr.b	DeleteMode

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.l	Error16

			cmpi.b	#2,MoveMode
			beq.s	.Skip

			bchg	#0,MoveMode
			beq.s	.On

.Skip:			clr.b	MoveMode
			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2

			jsr	ShowPoints
			lea	StatusMovePoint,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

MovePntPos:		jsr	GetMousePos
			cmpi.b	#2,MoveMode
			beq.s	.Skip
			jsr	ShowPXY
			jmp	Scope

.Skip:			movea.l	MovePtr,a0
			move.b	XMousePos,(a0)

			adda.w	#MaxPoints,a0

			tst.b	DrawScopeFlag		;*
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a0
			move.b	YMousePos,(a0)
			neg.b	(a0)
			bra.s	.TSkip2

.TSkip:			move.b	YMousePos,(a0)

.TSkip2:		move.l	#$01010101,AD0Update
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			bsr	PrintMovePntPos
			jmp	Scope

MoveIt:			jsr	GetMousePos

MoveIt2:		movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq.l	Error16

			cmpi.b	#2,MoveMode
			beq	.Skip

			movea.l	a0,a1
			adda.w	#MaxPoints,a1

			move.b	XMousePos,d0
			move.b	YMousePos,d1
			move.l	Len0,d2
			subq.l	#1,d2
			suba.l	a4,a4

			tst.b	DrawScopeFlag		;*
			beq.s	.Loop

			tst.b	D3Flag
			beq.s	.Loop

			tst.b	TopViewFlag
			beq.s	.Loop

			adda.w	#MaxPoints,a1
			neg.b	d1

.Loop:			cmp.b	(a0)+,d0
			beq.s	.Maybe
			addq.l	#1,a1
.Next:			dbf	d2,.Loop

			tst.l	a4			;Found?
			bne.s	.GotIt

			jsr	ShowPXY
			jmp	Scope

.Maybe:			cmp.b	(a1)+,d1
			bne.s	.Next

			movea.l	a0,a4

			tst.b	MagGlassFlag
			beq.s	.Next

			cmpi.w	#1,StackNumber
			bls.s	.Next

			subq.w	#1,StackNumber2
			bne.s	.Next

.GotIt:			subq.l	#1,a4
			move.l	a4,MovePtr
			move.b	#2,MoveMode

			move.b	(a4),MovePntXTemp
			adda.w	#MaxPoints,a4
			move.b	(a4),MovePntYTemp
			adda.w	#MaxPoints,a4
			move.b	(a4),MovePntZTemp

			clr.w	StackNumber
			move.w	#1,StackNumber2

			jsr	ShowPoints
			lea	StatusArrowKeys,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.Skip:			clr.b	MoveMode

			movea.l	MovePtr,a0
			move.b	(a0),d0
			cmp.b	MovePntXTemp,d0
			bne.s	.Skip2

			adda.w	#MaxPoints,a0
			move.b	(a0),d0
			cmp.b	MovePntYTemp,d0
			bne.s	.Skip2

			adda.w	#MaxPoints,a0
			move.b	(a0),d0
			cmp.b	MovePntZTemp,d0
			bne.s	.Skip2

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.Skip2:			jsr	ShowPoints
			lea	StatusMovePoint2,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

PrintMovePntPos:	jsr	ShowPoints

			lea	MovePntPosText,a0
			bsr	MoveString
			lea	-1(a1),a0
			movea.l	MovePtr,a1
			move.b	(a1),d0
			ext.w	d0
			move.b	MovePntXTemp,d1
			ext.w	d1
			sub.w	d1,d0
			jsr	ConvertCordinate2

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			lea	MovePntPosText3,a0
			bsr	MoveString
			lea	-1(a1),a0
			movea.l	MovePtr,a1
			adda.w	#MaxPoints*2,a1
			move.b	(a1),d0
			ext.w	d0
			move.b	MovePntZTemp,d1
			ext.w	d1
			sub.w	d1,d0
			jsr	ConvertCordinate2
			bra.s	.TSkip2

.TSkip:			lea	MovePntPosText2,a0
			bsr	MoveString
			lea	-1(a1),a0
			movea.l	MovePtr,a1
			adda.w	#MaxPoints,a1
			move.b	(a1),d0
			ext.w	d0
			move.b	MovePntYTemp,d1
			ext.w	d1
			sub.w	d1,d0
			jsr	ConvertCordinate2

.TSkip2:		lea	ASCIIBuffer,a0
			bsr	PrintStatus
			rts

ClearPoints:		jsr	SeqStuffOff
			jsr	AllOff

			movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			beq	.None

			movea.l	DrawMemPtr,a0
			move.l	a0,XDataPtr
			move.l	a0,XDrawPtr
			clr.b	(a0)

			adda.w	#MaxPoints,a0
			move.l	a0,YDataPtr
			move.l	a0,YDrawPtr
			clr.b	(a0)

			adda.w	#MaxPoints,a0
			move.l	a0,ZDataPtr
			move.l	a0,ZDrawPtr
			clr.b	(a0)

			move.l	#1,Len0
			move.l	#1,Len1
			move.l	#1,Len2
			move.l	#1,Len3

			jsr	ClrLastPtrs

			jsr	ResetAll
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			lea	DefaultFilename,a0
			lea	Filename4,a1
			bsr	MoveString

			move.b	#1,DefaultFreq

			lea	StatusClear2,a0
			bsr	PrintStatus
			jmp	Scope

.None:			bsr	FlashScreen
			lea	StatusClear3,a0
			bsr	PrintStatus
			jmp	Scope

CheckDefault:		tst.b	DefaultFreq
			beq.s	.End

			move.w	#240,Freq0
			move.w	#240,Freq1
			move.w	#240,Freq2
			move.w	#240,Freq3

			cmpi.l	#3,Len0
			blo.s	.End

			cmpi.l	#3,Len1
			blo.s	.End

			clr.b	DefaultFreq
.End:			rts

Undo:			jsr	SeqStuffOff
			jsr	AllOff

			tst.l	UndoPtr2
			beq.s	.None2

			movea.l	UndoPtr2,a0
			move.l	(a0),d0
			beq.s	.None

			bsr.s	UndoIt
			jsr	ShowPoints
			lea	StatusUndo,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.None:			bsr.s	UndoIt2
			bsr	FlashScreen
			lea	StatusUndo2,a0
			bsr	PrintStatus
			jmp	Scope

.None2:			bsr	FlashScreen
			lea	StatusUndo5,a0
			bsr	PrintStatus
			jmp	Scope

UndoIt:			move.l	d0,UndoPtr2

UndoIt2:		bsr	CheckCenter
			bsr	TurnItOff2

			move.l	DrawMemPtr,d3

			movea.l	UndoPtr2,a0
			adda.w	#12,a0
			move.l	(a0)+,d1
			move.l	(a0)+,d2
			move.l	(a0)+,XDataTextPtr
			add.l	d3,XDataTextPtr
			move.l	(a0),XDataTextSize
			move.l	(a0)+,XDataTextSize+4
			move.l	(a0)+,XDataLinePtr
			add.l	d3,XDataLinePtr
			move.l	(a0)+,XDataLineSize
			move.l	(a0)+,XDataArcPtr
			add.l	d3,XDataArcPtr
			move.l	(a0)+,XDataArcSize
			move.l	(a0)+,XDataBoxPtr
			add.l	d3,XDataBoxPtr
			move.l	(a0)+,XDataBoxSize
			move.l	(a0)+,XDataEllipsePtr
			add.l	d3,XDataEllipsePtr
			move.l	(a0)+,XDataEllipseSize
			move.l	(a0)+,XDataMergePtr
			add.l	d3,XDataMergePtr
			move.l	(a0)+,XDataMergeSize
			move.l	(a0)+,XDataDragPtr
			add.l	d3,XDataDragPtr
			move.l	(a0),XDataDragSize
			move.l	(a0)+,XDataDragSize+4
			move.l	(a0)+,XDataLastPtr
			add.l	d3,XDataLastPtr
			move.l	(a0)+,XDataLastSize
			move.b	(a0)+,D3FlagTemp

			movea.l	DrawMemPtr,a1		;X
			subq.l	#1,d1
			move.l	d1,d3

.Loop:			move.b	(a0)+,(a1)+
			dbf	d1,.Loop
			move.l	a1,XDataPtr

			movea.l	DrawMemPtr,a1		;Y
			adda.w	#MaxPoints,a1
			subq.l	#1,d2

.Loop2:			move.b	(a0)+,(a1)+
			dbf	d2,.Loop2
			move.l	a1,YDataPtr

			tst.b	D3FlagTemp
			beq.s	.D3Skip

			movea.l	DrawMemPtr,a1		;Z
			adda.w	#MaxPoints*2,a1

.Loop3:			move.b	(a0)+,(a1)+
			dbf	d3,.Loop3
			move.l	a1,ZDataPtr

.D3Skip:		jsr	GetDrawLen
			jsr	CheckFreq
			bsr	RestartSound
			move.b	#1,DrawUpdateFlag
			clr.b	RBufferFlag
			clr.b	SBufferFlag
			rts

UndoUpdate:		movem.l	d0-d7/a0-a6,-(sp)

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	.Skip3

			move.w	UndoCount,d0
			cmp.w	MaxUndos,d0
			blo.s	.Skip

			lea	UndoPtr,a0
			movea.l	(a0),a1

.Loop:			tst.l	(a1)
			beq.s	.Last
			movea.l	a1,a0
			movea.l	(a0),a1
			bra.s	.Loop

.Last:			clr.l	(a0)
			move.l	8(a1),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

			subq.w	#1,UndoCount

.Skip:			move.l	Len0,d0
			add.l	Len1,d0

			tst.b	D3Flag
			beq.s	.D3Skip
			add.l	Len0,d0

.D3Skip:		addi.l	#85,d0
			move.l	d0,-(sp)

			sub.l	d1,d1
			movea.l	(4).l,a6
			jsr	_LVOAllocMem(a6)
			tst.l	d0
			beq	.Error

			move.l	DrawMemPtr,d3

			movea.l	d0,a0
			movea.l	UndoPtr,a1
			move.l	a1,(a0)+
			clr.l	(a0)+
			move.l	(sp)+,(a0)+
			move.l	Len0,(a0)+
			move.l	Len1,(a0)+
			move.l	XDataTextPtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataTextSize,(a0)+
			move.l	XDataLinePtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataLineSize,(a0)+
			move.l	XDataArcPtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataArcSize,(a0)+
			move.l	XDataBoxPtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataBoxSize,(a0)+
			move.l	XDataEllipsePtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataEllipseSize,(a0)+
			move.l	XDataMergePtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataMergeSize,(a0)+
			move.l	XDataDragPtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataDragSize,(a0)+
			move.l	XDataLastPtr,(a0)
			sub.l	d3,(a0)+
			move.l	XDataLastSize,(a0)+
			move.b	D3Flag,(a0)+

			move.l	d0,UndoPtr
			move.l	d0,UndoPtr2

			tst.l	a1
			beq.s	.Skip2
			move.l	d0,4(a1)

.Skip2:			movea.l	DrawMemPtr,a1		;X data
			move.l	Len0,d0
			subq.l	#1,d0

.Loop2:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop2

			movea.l	DrawMemPtr,a1		;Y data
			adda.w	#MaxPoints,a1
			move.l	Len1,d0
			subq.l	#1,d0

.Loop3:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop3

			tst.b	D3Flag
			beq.s	.D3Skip2

			movea.l	DrawMemPtr,a1		;Z data
			adda.w	#MaxPoints*2,a1
			move.l	Len0,d0
			subq.l	#1,d0

.Loop4:			move.b	(a1)+,(a0)+
			dbf	d0,.Loop4

.D3Skip2:		addq.w	#1,UndoCount

.Skip3:			movem.l	(sp)+,d0-d7/a0-a6
			rts

.Error:			addq.l	#4,sp
			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			bra.s	.Skip3

Redo:			jsr	SeqStuffOff
			jsr	AllOff

			tst.l	UndoPtr2
			beq.s	.None2

			movea.l	UndoPtr2,a0
			move.l	4(a0),d0
			beq.s	.None

			bsr	UndoIt
			jsr	ShowPoints
			lea	StatusUndo3,a0
			bsr	MoveString
			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			jmp	Scope

.None:			bsr	UndoIt2
			bsr	FlashScreen
			lea	StatusUndo4,a0
			bsr	PrintStatus
			jmp	Scope

.None2:			bsr	FlashScreen
			lea	StatusUndo5,a0
			bsr	PrintStatus
			jmp	Scope


;Special menu:

Attach:			clr.b	TriggerFlag
			clr.b	MorphStatus
			clr.b	DrawStatus
			jsr	RecordUpdate
			clr.b	RecordStatus
			jsr	AllOff

			bchg	#0,AttachStatus
			beq.s	.On

			lea	StatusBlank,a0
			bsr	PrintStatus
			jmp	Scope

.On:			lea	StatusAttach,a0
			bsr	PrintStatus
			jmp	Scope

CheckNewScreen:		lea	Filename4,a1
			lea	DefaultFilename2,a0
			bsr	CmpString2
			beq	.End

			bsr	ClearMenu

			lea	Filename4,a0
			lea	NameString,a1
			bsr	MoveString

			sub.l	d0,d0
			jsr	OpenNameWindow
			tst.l	d0
			bne.s	.Done

			movea.l	NameGadgets,a0
			movea.l	NameWnd,a1
			bsr	ActivateGad

			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	NameWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.Skip

			btst	#6,d2			;Gadget up?
			beq.s	.Next

			movea.l	NameGadgets,a0
			movea.l	34(a0),a0
			movea.l	(a0),a0
			lea	Filename4,a1
			bsr	MoveString

.Skip:			jsr	CloseNameWindow

.Done:			bsr	OpenMenu
.End:			rts

CheckNewSequence:	lea	Filename2,a1
			lea	DefaultFilename2,a0
			bsr	CmpString2
			beq	.End

			bsr	ClearMenu

			lea	Filename2,a0
			lea	NameString,a1
			bsr	MoveString

			sub.l	d0,d0
			jsr	OpenNameWindow
			tst.l	d0
			bne.s	.Done

			movea.l	NameGadgets,a0
			movea.l	NameWnd,a1
			bsr	ActivateGad

			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	NameWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.Skip

			btst	#6,d2			;Gadget up?
			beq.s	.Next

			movea.l	NameGadgets,a0
			movea.l	34(a0),a0
			movea.l	(a0),a0
			lea	Filename2,a1
			bsr	MoveString

.Skip:			jsr	CloseNameWindow

.Done:			bsr	OpenMenu
.End:			rts

Center:			jsr	SeqStuffOff
			jsr	AllOff

			tst.b	SendXYFlag
			beq.s	.Skip

			bsr	SendUnitID

			move.b	#"A",d0
			bsr	Echo

			clr.l	SequenceCountTrigTemp

.Loop:			bsr	GetByte
			bne.s	.GotByte
			bsr	ShortDelay
			cmpi.l	#30,SequenceCountTrigTemp
			blo.s	.Loop
			jmp	Error10

.GotByte:		cmpi.b	#".",d0
			bne.s	.Loop
			bra.s	.Skip3

.Skip:			move.w	XPos,d0
			subi.w	#XMax/2,d0

			move.w	YPos,d1
			subi.w	#YMax/2,d1

			tst.w	d0
			bne.s	.Skip2

			tst.w	d1
			beq.s	.NoChange

.Skip2:			add.w	d0,XCenter
			add.w	d1,YCenter

			move.w	#XMax/2,XPos
			move.w	#YMax/2,YPos

			move.w	XPos,XPosTemp
			move.w	YPos,YPosTemp

.Skip3:			lea	StatusCenter,a0
			bsr	PrintStatus
			jmp	Scope

.NoChange:		bsr	FlashScreen
			lea	StatusCenter2,a0
			bsr	PrintStatus
			jmp	Scope

SendObject:		jsr	SeqStuffOff
			jsr	AllOff

			lea	ObjFilename,a0
			lea	ObjDir,a1
			lea	SendReqText,a2
			bsr	ReqFile
			beq.l	Error3

			cmpi.b	#1,d0
			beq	.Scope

			lea	StatusReset,a0
			bsr	PrintStatus

			move.b	#3,d0			;Cntrl-C
			bsr	Echo

			move.l	#300,d1			;Wait 6 seconds
			movea.l	DosBase,a6
			jsr	_LVODelay(a6)

			jsr	WaitIntroScreen

			move.b	#"W",d0			;Fans off
			bsr	Echo

			lea	StatusRead,a0
			bsr	PrintStatus

			lea	ObjDir,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			subq.l	#1,a1
			lea	ObjFilename,a0
			bsr	MoveString

			bsr	LoadFile
			cmpi.b	#1,d0
			beq.l	Error3

			cmpi.b	#2,d0
			beq.l	Error4

			move.b	#2,d0
			bsr	Echo

			clr.l	SequenceCountTrigTemp

.Loop:			bsr	GetByte
			bne.s	.GotByte
			bsr	ShortDelay
			cmpi.l	#30,SequenceCountTrigTemp
			blo.s	.Loop

			bsr	FreeFileMem
			jmp	Error10

.GotByte:		cmpi.b	#"C",d0
			bne.s	.Loop

			move.b	FileMemSize+3,d0
			bsr	Echo

			move.b	FileMemSize+2,d0
			bsr	Echo

			clr.b	Checksum
			clr.l	Bytes
			move.b	#100,BlockCount
			move.l	FileMemPtr,DataPtr

.Loop2:			movea.l	DataPtr,a0
			move.b	(a0)+,d0
			move.l	a0,DataPtr
			add.b	d0,Checksum
			bsr	Echo

			addq.l	#1,Bytes
			subq.b	#1,BlockCount
			bne.s	.Skip

			move.b	#100,BlockCount
			bsr	.PrintBytes

.Skip:			move.l	Bytes,d0
			cmp.l	FileMemSize,d0
			bne.s	.Loop2

			bsr	.PrintBytes

			move.b	Checksum,d0
			bsr	Echo

			bsr	FreeFileMem

			clr.l	SequenceCountTrigTemp

.Loop3:			bsr	GetByte
			bne.s	.GotByte2
			bsr	ShortDelay
			cmpi.l	#30,SequenceCountTrigTemp
			blo.s	.Loop3
			jmp	Error10

.GotByte2:		cmpi.b	#"?",d0
			beq	.BadChecksum

			cmpi.b	#"C",d0
			bne.s	.Loop3

			lea	FinishedText,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.b	Checksum,d0
			bsr	HEXtoASCII
			move.b	#")",(a1)+
			clr.b	(a1)

			lea	ASCIIBuffer,a0
			bsr	PrintStatus

			move.b	#"Z",d0			;Start program
			bsr	Echo

			move.l	#200,d1			;Wait 4 seconds
			movea.l	DosBase,a6
			jsr	_LVODelay(a6)

			jsr	WaitIntroScreen

			move.b	#"W",d0			;Fans off
			bsr	Echo

			tst.b	SoleniodFlag		;Shutter on/off
			bne.s	.On

			move.b	#"R",d0
			bra.s	.Skip2

.On:			move.b	#"E",d0
.Skip2:			jsr	Echo

			btst	#0,StandbyFlag		;Standby on/off
			bne.s	.On2

			move.b	#"Y",d0
			bra.s	.Skip3

.On2:			move.b	#"T",d0
.Skip3:			bsr	Echo

			lea	CheckLaserOK,a0
			bsr	PrintStatus
.Scope:			jmp	Scope

.BadChecksum:		bsr	FlashScreen
			lea	Error12Text,a0
			bsr	PrintStatus
			jmp	Scope

.PrintBytes:		lea	BytesText,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			lea	-1(a1),a0
			move.l	Bytes,d0
			bsr	HEXtoASCII

			lea	ASCIIBuffer,a0
			bsr	PrintStatus
			rts

SendXYMove:		jsr	SeqStuffOff
			jsr	AllOff

			bchg	#0,SendXYFlag
			jmp	Scope

GetSendXYItem:		jsr	CheckIconify
			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	18(a0),a0		;Item 1
			movea.l	(a0),a0			;Item 2
			movea.l	(a0),a0			;Item 3
			movea.l	(a0),a0			;Item 4
			movea.l	(a0),a0			;Item 5
			movea.l	(a0),a0			;Item 6
			movea.l	(a0),a0			;Item 7
			rts

AllUnits:		jsr	SeqStuffOff
			jsr	AllOff
			clr.b	UnitNumber
			bsr	SetMenus2
			jmp	Scope

Unit5:			jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"5",UnitNumber
			bsr	SetMenus2
			jmp	Scope

Unit6:			jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"6",UnitNumber
			bsr	SetMenus2
			jmp	Scope

Unit7:			jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"7",UnitNumber
			bsr	SetMenus2
			jmp	Scope

Unit8:			jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"8",UnitNumber
			bsr	SetMenus2
			jmp	Scope

Unit9:			jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"9",UnitNumber
			bsr	SetMenus2
			jmp	Scope

Aquarius1:		jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"1",UnitNumber
			clr.b	SendXYFlag
			bsr	GetSendXYItem
			bclr	#0,12(a0)
			bsr.s	SetMenus2
			jmp	Scope

Aquarius2:		jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"2",UnitNumber
			clr.b	SendXYFlag
			bsr	GetSendXYItem
			bclr	#0,12(a0)
			bsr.s	SetMenus2
			jmp	Scope

Aquarius12:		jsr	SeqStuffOff
			jsr	AllOff
			move.b	#"3",UnitNumber
			clr.b	SendXYFlag
			bsr	GetSendXYItem
			bclr	#0,12(a0)
			bsr.s	SetMenus2
			jmp	Scope

SetMenus2:		tst.b	IconifyFlag
			bne	.End

			tst.b	SerialFlag
			bne.s	.SSkip
			bsr	GetSendXYItem
			bset	#4,13(a0)		;No ghost

.SSkip:			movea.l	LaserMenus,a0		;Project
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	18(a0),a0		;Item 1
			movea.l	(a0),a0			;Item 2
			movea.l	(a0),a0			;Item 3
			movea.l	(a0),a0			;Item 4
			movea.l	(a0),a0			;Item 5
			movea.l	(a0),a0			;Item 6

			movea.l	28(a0),a0		;Sub item 1
			bclr	#0,12(a0)
			tst.b	UnitNumber
			bne.s	.Skip
			bset	#0,12(a0)

.Skip:			movea.l	(a0),a0			;Sub item 2
			bclr	#0,12(a0)
			cmpi.b	#"5",UnitNumber
			bne.s	.Skip2
			bset	#0,12(a0)

.Skip2:			movea.l	(a0),a0			;Sub item 3
			bclr	#0,12(a0)
			cmpi.b	#"6",UnitNumber
			bne.s	.Skip3
			bset	#0,12(a0)

.Skip3:			movea.l	(a0),a0			;Sub item 4
			bclr	#0,12(a0)
			cmpi.b	#"7",UnitNumber
			bne.s	.Skip4
			bset	#0,12(a0)

.Skip4:			movea.l	(a0),a0			;Sub item 5
			bclr	#0,12(a0)
			cmpi.b	#"8",UnitNumber
			bne.s	.Skip5
			bset	#0,12(a0)

.Skip5:			movea.l	(a0),a0			;Sub item 6
			bclr	#0,12(a0)
			cmpi.b	#"9",UnitNumber
			bne.s	.Skip6
			bset	#0,12(a0)

.Skip6:			movea.l	(a0),a0			;Sub item 8
			movea.l	(a0),a0
			bclr	#0,12(a0)
			cmpi.b	#"1",UnitNumber
			bne.s	.Skip7
			bset	#0,12(a0)
			bsr.s	.Off

.Skip7:			movea.l	(a0),a0			;Sub item 9
			bclr	#0,12(a0)
			cmpi.b	#"2",UnitNumber
			bne.s	.Skip8
			bset	#0,12(a0)
			bsr.s	.Off

.Skip8:			movea.l	(a0),a0			;Sub item 10
			bclr	#0,12(a0)
			cmpi.b	#"3",UnitNumber
			bne.s	.End
			bset	#0,12(a0)
			bsr.s	.Off
.End:			rts

.Off:			move.l	a0,-(sp)
			bsr	GetSendXYItem
			bclr	#4,13(a0)		;Ghost it
			movea.l (sp)+,a0
			rts

SendUnitID:		move.b	UnitNumber,d0
			beq.s	.End
			cmpi.b	#"4",d0
			bls.s	.End
			bsr	Echo
.End:			rts

Master:			jsr	SeqStuffOff
			jsr	AllOff

			bchg	#0,MasterFlag
			clr.b	SlaveFlag
			bsr.s	SetMenus3
			jmp	Scope

Slave:			jsr	SeqStuffOff
			jsr	AllOff

			bchg	#0,SlaveFlag
			clr.b	MasterFlag
			bsr.s	SetMenus3
			jmp	Scope

SetMenus3:		tst.b	IconifyFlag
			bne.s	.End

			movea.l	LaserMenus,a0		;Porject
			movea.l	(a0),a0			;Draw
			movea.l	(a0),a0			;Points
			movea.l	(a0),a0			;Special
			movea.l	18(a0),a0		;Item 1
			movea.l	(a0),a0			;Item 2
			movea.l	(a0),a0			;Item 3
			movea.l	(a0),a0			;Item 4
			movea.l	(a0),a0			;Item 5
			movea.l	(a0),a0			;Item 6
			movea.l	(a0),a0			;Item 7
			movea.l	(a0),a0			;Item 8
			movea.l	(a0),a0			;Item 9

			movea.l	28(a0),a0		;Sub item 1
			bclr	#0,12(a0)
			tst.b	MasterFlag
			beq.s	.Skip
			bset	#0,12(a0)

.Skip:			movea.l	(a0),a0			;Sub item 2
			bclr	#0,12(a0)
			tst.b	SlaveFlag
			beq.s	.End
			bset	#0,12(a0)
.End:			rts


;Preferences menu:

AutoMan:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoManFlag
			jsr	CheckSpecial
			jmp	Scope

PresetMove:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,PresetMoveFlag
			jsr	CheckSpecial
			jmp	Scope

SeqMove:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,SeqMoveFlag
			jmp	Scope

HiRes:			jsr	MoreOff
			jsr	AllOff

			tst.b	GridFlag
			beq.s	.Off
			bsr	GridOff

.Off:			bchg	#0,HiResFlag

			tst.b	GridFlag
			beq.s	.Off2
			bsr	GridOn

.Off2:			tst.b	DrawMode
			beq.l	Scope

			bsr	CalcDCOffset
			bsr	RestartSound
			clr.l	Freq2Print
			move.l	#-1,Phase2Print
			jmp	Scope

GetHiResItem:		moveq	#4,d0
			bsr	GetPrefsItem
			rts

AutoRetrace:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoRetraceFlag

			tst.b	DrawMode
			beq.s	.End

			clr.l	Freq0Print
			clr.l	Freq2Print

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq.s	.End

			move.l	#$01010101,AD0Update
.End:			jmp	Scope

Filter:			jsr	MoreOff
			jsr	AllOff

			bchg	#0,FilterFlag

			tst.b	DrawMode
			bne.s	.Skip
			bchg	#0,FilterFlag2

.Skip:			bchg	#1,$bfe001
			jmp	Scope

SetFilter:		jsr	GetFilterItem
			bset	#0,12(a0)
			bclr	#1,$bfe001
			tst.b	FilterFlag2
			bne.s	.End
			bset	#1,$bfe001
			bclr	#0,12(a0)
.End:			rts

MagnifyingGlass:	jsr	MoreOff
			jsr	AllOff

			bchg	#0,MagGlassFlag
			beq.s	.On

			jsr	CloseMagnifyGlassWindow
			jmp	Scope

.On:			bsr	CheckCenter
			bsr	TurnItOff2
			bsr.s	OpenMagnifyGlass
			clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			bsr	FreePreloadMem
			jmp	Scope

OpenMagnifyGlass:	tst.b	MagGlassFlag
			beq.s	.End

			clr.w	StackNumber
			move.w	#1,StackNumber2
			clr.b	MagnifyGlassIText0

			sub.l	d0,d0
			jsr	OpenMagnifyGlassWindow
			tst.l	d0
			bne.s	.Error

			movea.l	MagnifyGlassWnd,a0
			move.l	50(a0),RastPortPtr2
			bsr	SetDrawMode3
			bsr	BlankMagnifyGlass
			bsr	DrawCrossHairs
.End:			rts

.Error:			bsr	FlashScreen
			clr.b	MagGlassFlag
			bsr.s	GetMagnifyItem
			bclr	#0,12(a0)
			rts

GetMagnifyItem:		moveq	#7,d0
			bsr	GetPrefsItem
			rts

UpdateMagGlass:		tst.b	IconifyFlag
			bne	.End

			tst.b	MagGlassFlag
			beq	.End

			cmpi.b	#8,MagCount
			blo	.XHairs

			clr.b	MagCount

			tst.b	DrawMode
			beq	.XHairs

			move.l	XDataPtr,d0
			cmp.l	DrawMemPtr,d0
			beq	.XHairs

			bsr	BlankMagnifyGlass

			move.b	XMousePos,MagXMousePos
			move.b	YMousePos,MagYMousePos
			clr.w	StackNumber

			tst.b	RollMode
			beq.s	.RSkip

			jsr	GetLastStartPtr		;Get X
			move.b	(a0),MagXMousePos
			adda.w	#MaxPoints,a0
			move.b	(a0),MagYMousePos	;Get Y

			tst.b	DrawScopeFlag
			beq.s	.RSkip

			tst.b	D3Flag
			beq.s	.RSkip

			tst.b	TopViewFlag
			beq.s	.RSkip

			adda.w	#MaxPoints,a0
			move.b	(a0),MagYMousePos	;Get Z
			neg.b	MagYMousePos

.RSkip:			movea.l	DrawMemPtr,a0
			movea.l	a0,a1
			adda.w	#MaxPoints,a1

			tst.b	DrawScopeFlag
			beq.s	.TSkip

			tst.b	D3Flag
			beq.s	.TSkip

			tst.b	TopViewFlag
			beq.s	.TSkip

			adda.w	#MaxPoints,a1

.TSkip:			move.l	Len0,d2
			subq.l	#1,d2

			move.b	MagXMousePos,d3
			addi.b	#127,d3
			move.b	d3,d4
			cmpi.b	#5,d3
			blo.s	.Skip
			subq.b	#5,d3
			bra.s	.Skip2
.Skip:			sub.l	d3,d3
.Skip2:			cmpi.b	#249,d4
			bhi.s	.Skip3
			addq.b	#5,d4
			bra.s	.Skip4
.Skip3:			move.b	#254,d4

.Skip4:			move.b	MagYMousePos,d5
			addi.b	#127,d5
			move.b	d5,d6
			cmpi.b	#5,d5
			blo.s	.Skip5
			subq.b	#5,d5
			bra.s	.Skip6
.Skip5:			sub.l	d5,d5
.Skip6:			cmpi.b	#249,d6
			bhi.s	.Skip7
			addq.b	#5,d6
			bra.s	.Loop
.Skip7:			move.b	#254,d6

.Loop:			move.b	(a0)+,d0
			move.b	(a1)+,d7

			tst.b	DrawScopeFlag
			beq.s	.TSkip2

			tst.b	D3Flag
			beq.s	.TSkip2

			tst.b	TopViewFlag
			beq.s	.TSkip2

			neg.b	d7

.TSkip2:		addi.b	#127,d0
			cmp.b	d3,d0
			blo	.Miss
			cmp.b	d4,d0
			bhi	.Miss

			addi.b	#127,d7
			cmp.b	d5,d7
			blo	.Miss
			cmp.b	d6,d7
			bhi	.Miss

			movem.l	d2-d6/a0-a1,-(sp)

			sub.l	d3,d3
			move.b	MagXMousePos,d3
			addi.b	#127,d3
			subq.w	#5,d3
			andi.w	#$ff,d0
			sub.w	d3,d0
			mulu	#6,d0
			addi.w	#16,d0

			sub.l	d5,d5
			move.b	MagYMousePos,d5
			addi.b	#127,d5
			subq.w	#5,d5
			andi.w	#$ff,d7
			sub.w	d5,d7

			tst.b	BigScreenFlag
			beq.s	.BSkip
			mulu	#6,d7
			moveq	#75,d1
			bra.s	.BSkip2
.BSkip:			mulu	#3,d7
			moveq	#45,d1
.BSkip2:		sub.w	d7,d1

			cmpi.w	#5*6+16,d0
			bne.s	.NSkip2

			tst.b	BigScreenFlag
			beq.s	.NSkip

			cmpi.w	#75-(5*6),d1
			bne.s	.NSkip2
			bra.s	.NFound

.NSkip:			cmpi.w	#45-(5*3),d1
			bne.s	.NSkip2

.NFound:		addq.w	#1,StackNumber

.NSkip2:		move.l	d0,-(sp)
			move.l	d1,-(sp)

			movea.l	RastPortPtr2,a1
			movea.l	GfxBase,a6
			jsr	_LVOReadPixel(a6)
			cmpi.b	#1,d0
			beq.s	.Green

			cmpi.b	#3,d0
			beq.s	.White

			addq.l	#8,sp
			bra.s	.Miss2

.White:			moveq	#2,d0
			bsr	SetAPen2
			bra.s	.Okay

.Green:			moveq	#3,d0
			bsr	SetAPen2

.Okay:			move.l	(sp)+,d1
			move.l	(sp)+,d0

			movea.l	RastPortPtr2,a1
			move.l	d0,d2
			addq.l	#5,d2
			move.l	d1,d3
			addq.l	#2,d3
			tst.b	BigScreenFlag
			beq.s	.BSkip3
			addq.l	#3,d3
.BSkip3:		movea.l	GfxBase,a6
			jsr	_LVORectFill(a6)

.Miss2:			movem.l	(sp)+,d2-d6/a0-a1

.Miss:			dbf	d2,.Loop
			bsr.s	PrintStack
			clr.b	MagCount
			bra.s	.XHairs2

.XHairs:		cmpi.b	#2,XHairsCount
			blo.s	.End

.XHairs2:		moveq	#2,d0
			bsr	SetDrawMode4
			bsr	DrawCrossHairs
			bsr	SetDrawMode3
			clr.b	XHairsCount
.End:			rts

PrintStack:		lea	MagnifyGlassIText0,a0
			move.l	#$20202020,(a0)
			move.l	#$20202020,4(a0)
			move.b	#$20,8(a0)

			cmpi.w	#1,StackNumber
			bls.s	.Skip

			tst.b	RollMode
			bne.s	.RSkip

			sub.l	d0,d0
			move.w	StackNumber2,d0
			bsr	HEXtoASCII
			move.b	#"/",(a1)+
			movea.l	a1,a0

.RSkip:			sub.l	d0,d0
			move.w	StackNumber,d0
			bsr	HEXtoASCII
			move.b	#$20,(a1)

			lea	MagnifyGlassIText0+9,a0	;Center it
			clr.b	(a0)
			suba.l	a1,a0
			move.l	a0,d0
			beq.s	.Skip
			lsr.l	#1,d0
			beq.s	.Skip
			movea.l	a1,a0
			adda.l	d0,a0
			lea	MagnifyGlassIText0,a2

.Loop:			move.b	-(a1),-(a0)
			cmpa.l	a1,a2
			blo.s	.Loop

.Loop2:			move.b	#$20,-(a0)
			cmpa.l	a0,a2
			blo.s	.Loop2

.Skip:			lea	MagnifyGlassText0,a1
			movea.l	RastPortPtr2,a0
			moveq	#3,d0
			moveq	#11,d1
			tst.b	BigScreenFlag
			beq.s	.Skip2
			addi.l	#33,d1
.Skip2:			movea.l	IntBase,a6
			jsr	_LVOPrintIText(a6)
.End:			rts

Grid:			jsr	MoreOff
			jsr	AllOff

			bchg	#0,GridFlag
			beq.s	.On

			bsr.s	GridOff
			jmp	Scope

.On:			bsr.s	GridOn
			jmp	Scope

GridFlash:		tst.b	GridFlag
			bne.s	.Flash
.End:			rts

.Flash:			tst.b	DrawMode
			beq.s	.Skip
			tst.b	DrawScopeFlag
			beq.s	.Skip

			tst.b	GridFlag2
			bne.s	.End
			bra.s	GridOn

.Skip:			cmpi.b	#2,MiscCount3
			blo.s	.End

			bchg	#0,GridFlag2
			beq.s	GridOn
			moveq	#1,d0
			bra.s	GridGrid

GridOff:		tst.b	GridFlag2
			beq.s	.End
			clr.b	GridFlag2
			moveq	#1,d0
			bra.s	GridGrid
.End:			rts

GridOn:			move.b	#1,GridFlag2
			sub.l	d0,d0

GridGrid:		bsr	CheckDrawMode

			moveq	#-127,d0
			moveq	#8,d1
			sub.l	d2,d2

.Loop:			move.l	d2,-(sp)
			move.l	d1,-(sp)
			move.l	d0,-(sp)

			jsr	CheckHiResX
			move.b	#-127,d2
			jsr	CheckHiResY
			bsr	Move

			move.l	(sp),d0
			jsr	CheckHiResX
			move.b	#127,d2
			jsr	CheckHiResY
			bsr	Draw

			move.b	#-127,d0
			jsr	CheckHiResX
			move.l	(sp),d2
			jsr	CheckHiResY
			bsr	Move

			move.b	#127,d0
			jsr	CheckHiResX
			move.l	(sp),d2
			jsr	CheckHiResY
			bsr	Draw

			move.l	(sp)+,d0
			move.l	(sp)+,d1
			move.l	(sp)+,d2

			addi.b	#31,d0
			addi.b	#6,d2
			cmpi.b	#8,d2
			blo.s	.Skip
			subi.b	#8,d2
			addq.b	#1,d0

.Skip:			dbf	d1,.Loop

			bsr	CheckDrawMode2
			clr.b	MiscCount3
			rts

ZAxis:			jsr	MoreOff
			jsr	AllOff

			bchg	#0,D3Flag
			beq.s	.On

			bsr	GetTopViewItem
			bclr	#4,13(a0)
			bra.s	.Skip

.On:			bsr	GetTopViewItem
			bset	#4,13(a0)

			tst.b	DrawMode
			beq.l	Scope

			bsr.s	ClearZData

.Skip:			tst.b	TopViewFlag
			beq.l	Scope

			move.b	#1,DrawUpdateFlag
			jmp	Scope

ClearZData:		movea.l	DrawMemPtr,a0
			adda.w	#MaxPoints*2,a0
			move.l	Len0,d0
			move.l	a0,ZDataPtr
			add.l	d0,ZDataPtr
			addq.l	#3,d0
			lsr.l	#2,d0
			subq.l	#1,d0

.Loop:			clr.l	(a0)+
			dbf	d0,.Loop

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			movea.l	DrawMemPtr,a0
			cmpa.l	XDataPtr,a0
			bne.s	.End
			adda.w	#MaxPoints*2,a0
			move.l	a0,ZDataPtr
.End:			rts

GetD3Item:		moveq	#9,d0
			bsr	GetPrefsItem
			rts

TopView:		jsr	MoreOff
			jsr	AllOff

			clr.b	RBufferFlag
			clr.b	SBufferFlag

			bchg	#0,TopViewFlag

			tst.b	DrawMode
			beq.l	Scope

			move.b	#1,DrawUpdateFlag
			bsr	PtrDraw2
			jsr	ShowPXY
			jmp	Scope

GetTopViewItem:		moveq	#10,d0
			bsr	GetPrefsItem
			rts

TopViewOff:		tst.b	DrawScopeFlag
			beq.s	.End

			tst.b	D3Flag
			beq.s	.End

			tst.b	TopViewFlag
			beq.s	.End

			clr.b	TopViewFlag
			bsr.s	GetTopViewItem
			bclr	#0,12(a0)

			tst.b	DrawMode
			beq.s	.End

			move.b	#1,DrawUpdateFlag
			bsr	PtrDraw2
			jsr	ShowPXY
.End:			rts


;System preferences

BigScreen:		jsr	MoreOff
			jsr	AllOff

			jsr	CloseMagnifyGlassWindow
			jsr	CloseLaserWindow
			jsr	CloseDownScreen
			move.w	#$ffff,NextSelect
			clr.b	PtrDrawFlag

			bchg	#0,BigScreenFlag
			beq.s	.On

			move.l	#$00029000,ScreenTags+68
			subi.l	#127,ScreenTags+28
			subi.w	#127,LaserHeight
			move.w	#55,MagnifyGlassHeight
			subi.w	#127,BevelBox
			subi.w	#33,BevelBox2
			move.w	#87,LaserCNT

			lea	LaserNGads+(GD_Vol0Dn*30+2),a0
			moveq	#21,d0

.Loop:			subi.w	#127,(a0)
			adda.w	#30,a0
			dbf	d0,.Loop

			lea	LaserNGads+(GD_Shutter*30+2),a0
			moveq	#3,d0

.Loop2:			subi.w	#127,(a0)
			adda.w	#30,a0
			dbf	d0,.Loop2

			lea	LaserText2+6,a0
			moveq	#23,d0

.Loop3:			subi.w	#127,(a0)
			adda.w	#20,a0
			dbf	d0,.Loop3
			bra.s	.Skip

.On:			move.l	#$00029004,ScreenTags+68
			addi.l	#127,ScreenTags+28
			addi.w	#127,LaserHeight
			move.w	#88,MagnifyGlassHeight
			addi.w	#127,BevelBox
			addi.w	#33,BevelBox2
			move.w	#129,LaserCNT

			lea	LaserNGads+(GD_Vol0Dn*30+2),a0
			moveq	#21,d0

.Loop4:			addi.w	#127,(a0)
			adda.w	#30,a0
			dbf	d0,.Loop4

			lea	LaserNGads+(GD_Shutter*30+2),a0
			moveq	#3,d0

.Loop5:			addi.w	#127,(a0)
			adda.w	#30,a0
			dbf	d0,.Loop5

			lea	LaserText2+6,a0
			moveq	#23,d0

.Loop6:			addi.w	#127,(a0)
			adda.w	#20,a0
			dbf	d0,.Loop6

.Skip:			bsr.s	ClearTable
			bsr	OpenDisplay
			beq	Exit9

			jsr	SetGadgets
			bsr	SetMenus2
			bsr	SetMenus3
			jsr	SetMenus
			bsr	OpenMagnifyGlass
			move.b	#1,DrawUpdateFlag
			clr.b	GridFlag2

			tst.b	FromConfig
			beq.l	Scope
			rts

ClearTable:		lea	PixelTable,a0
			moveq	#TableSize-1,d0

.Loop:			clr.l	(a0)+
			dbf	d0,.Loop

			move.l	#ScopeX+131,DrawX
			move.l	#ScopeY+65,DrawY
			move.l	#ScopeX+131,EraseX
			move.l	#ScopeY+65,EraseY
			rts

FastScope:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,FastScopeFlag
			bsr	BlankScope
			move.b	#1,DrawUpdateFlag
			jmp	Scope

DrawScopeOff:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,DrawScopeFlag
			beq.s	.On

			bsr	BlankScope
			jmp	Scope

.On:			move.b	#1,DrawUpdateFlag
			jmp	Scope

CheckDrawMode:		bsr	SetAPen
			tst.b	DrawMode
			beq.s	.End
			tst.b	DrawScopeFlag
			beq.s	.End
			moveq	#2,d0
			bsr	SetDrawMode2
.End:			rts

CheckDrawMode2:		tst.b	DrawMode
			beq.s	.End
			tst.b	DrawScopeFlag
			beq.s	.End
			bsr	SetDrawMode
.End:			rts

DrawBetweenPoints:	jsr	MoreOff
			jsr	AllOff

			bchg	#0,DrawBetweenFlag
			move.b	#1,DrawUpdateFlag
			jmp	Scope

ShowRotateSpin:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,ShowRSFlag
			beq.s	.On

			lea	VolText,a0
			lea	LaserIText2,a1
			bsr	MoveString
			lea	LaserText2,a1
			bsr	PrintWinText

			bsr	SetFreqText

			move.l	#-1,Vol0Print
			move.l	#-1,Vol2Print
			jmp	Scope

.On:			lea	VolText2,a0
			lea	LaserIText2,a1
			bsr	MoveString
			lea	LaserText2,a1
			bsr	PrintWinText

			bsr	SetFreqText

			lea	LaserIText9,a0
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			lea	LaserText9,a1
			bsr	PrintWinText

			lea	LaserIText17,a0
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			lea	LaserText17,a1
			bsr	PrintWinText

			move.l	#-1,RotateAngle01Print
			move.l	#-1,Spin0Print
			move.l	#-1,Spin2Print
			jmp	Scope

ShowPPS:		jsr	MoreOff
			jsr	AllOff

			clr.b	PeriodFlag
			bchg	#0,PPSFlag

			bsr.s	GetPeriodItem
			bclr	#0,12(a0)

			bsr.s	SetFreqText
			jmp	Scope

GetPPSItem:		moveq	#6,d0
			jsr	GetSysPrefsItem
			rts

ShowPeriod:		jsr	MoreOff
			jsr	AllOff

			clr.b	PPSFlag
			bchg	#0,PeriodFlag

			bsr.s	GetPPSItem
			bclr	#0,12(a0)

			bsr.s	SetFreqText
			jmp	Scope

GetPeriodItem:		moveq	#7,d0
			jsr	GetSysPrefsItem
			rts

SetFreqText:		lea	FreqText2,a0
			tst.b	ShowRSFlag
			bne.s	.Skip

			lea	FreqText3,a0
			tst.b	PeriodFlag
			bne.s	.Skip

			lea	FreqText4,a0
			tst.b	PPSFlag
			bne.s	.Skip

			lea	FreqText,a0

.Skip:			lea	LaserIText3,a1
			bsr	MoveString
			lea	LaserText3,a1
			bsr	PrintWinText

			clr.l	Freq0Print
			clr.l	Freq2Print
			rts

DMA:			jsr	MoreOff
			jsr	AllOff

			tst.b	DMAFlag
			beq.s	.Skip5

			move.w	Speed0,d0
			cmp.w	Speed1,d0
			bls.s	.Skip
			move.w	Speed1,d0

.Skip:			tst.b	DrawMode
			beq.s	.Skip2

			tst.b	HiResFlag
			bne.s	.Skip4

.Skip2:			cmp.w	Speed2,d0
			bls.s	.Skip3
			move.w	Speed2,d0

.Skip3:			cmp.w	Speed3,d0
			bls.s	.Skip4
			move.w	Speed3,d0

.Skip4:			cmpi.w	#160,d0
			bhs.s	.Skip5

			bsr	FlashScreen
			lea	SureText2,a1
			lea	DMAText,a2
			bsr	Requester
			bne.s 	.Skip5

			jsr	GetDMAItem
			bset	#0,12(a0)
			jmp	Scope

.Skip5:			jsr	GetAutoDMAItem
			bclr	#0,12(a0)
			clr.b	AutoDMAFlag

DMA2:			bchg	#0,DMAFlag
			beq	.On

			bsr	GetOutputBuff
			beq	.Error

			bsr	CheckSmooth

			move.w	#$f,$dff096		;Stop DMA
			move.w	#$780,$dff09a		;Disable all int
			bsr	StopDelay
			move.b	#1,NoWaitFlag

			moveq	#7,d0			;AD0 Handler
			lea	AD0IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#8,d0			;AD1 Handler
			lea	AD1IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#9,d0			;AD2 Handler
			lea	AD2IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#10,d0			;AD3 Handler
			lea	AD3IntNode,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

.Skip:			bsr	FreeOutputBuff

			move.l	OutputBufferPtrTemp,OutputBufferPtr
			move.l	OutputBufferPtr2Temp,OutputBufferPtr2
			move.l	OutputBufferPtr3Temp,OutputBufferPtr3

			clr.l	AD0Update2
			tst.b	FromConfig
			beq.s	.Skip2
			rts

.Skip2:			bsr	RestartSound2
			jmp	Scope

.Error:			move.b	#1,DMAFlag
			jsr	GetDMAItem
			bset	#0,12(a0)
			jmp	Error3

.Error2:		clr.b	DMAFlag
			jsr	GetDMAItem
			bclr	#0,12(a0)
			jmp	Error3

.On:			moveq	#$2,d1			;Chip mem
			bsr	GetOutputBuff2
			beq.s	.Error2

			bsr	CheckSmooth

			move.w	#$780,$dff09a		;Disable all int
			bsr	StopDelay
			move.b	#1,NoWaitFlag

			moveq	#7,d0			;AD0 Handler
			lea	AD0IntNodeDMA,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#8,d0			;AD1 Handler
			lea	AD1IntNodeDMA,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#9,d0			;AD2 Handler
			lea	AD2IntNodeDMA,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)

			moveq	#10,d0			;AD3 Handler
			lea	AD3IntNodeDMA,a1
			movea.l	(4).l,a6
			jsr	_LVOSetIntVector(a6)
			bra	.Skip

AutoDMA:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoDMAFlag
			jmp	Scope

CheckAutoDMA:		tst.b	AutoDMAFlag
			bne.s	.Skip
			rts

.Skip:			tst.b	DrawMode
			beq.s	.Off

			tst.b	DMAFlag
			bne.s	.End

			move.b	#1,FromConfig
			bsr	DMA2
			clr.b	FromConfig

			tst.b	DMAFlag
			beq.s	.End

			jsr	GetDMAItem
			bset	#0,12(a0)
.End:			rts

.Off:			tst.b	DMAFlag
			beq.s	.End

			move.b	#1,FromConfig
			bsr	DMA2
			clr.b	FromConfig

			tst.b	DMAFlag
			bne.s	.End

			jsr	GetDMAItem
			bclr	#0,12(a0)
			rts

APoints:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoPointsFlag
			jmp	Scope

AutoPreload:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoPreloadFlag
			jmp	Scope

AutoAttach:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,AutoAttachFlag
			jmp	Scope

Swap:			jsr	MoreOff
			jsr	AllOff

			bsr.s	CheckCenter
			bchg	#0,SwapFlag
			jmp	Scope

CheckCenter:		cmpi.w	#XMax/2,XPosTemp
			bne.s	.Move

			cmpi.w	#YMax/2,YPosTemp
			beq.s	.End

.Move:			jsr	MoveToCenter
			bsr	MoveLaser
.End:			rts

InvertX:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,InvertXFlag
			move.b	#1,AD0Update
			move.b	#1,AD3Update
			jmp	Scope

InvertY:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,InvertYFlag
			move.b	#1,AD1Update
			move.b	#1,AD2Update
			jmp	Scope

SmoothChg:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,SmoothChgFlag
			jmp	Scope

NoDrag:			jsr	MoreOff
			jsr	AllOff

			bchg	#0,NoDragFlag
			jmp	Scope

DirectWrite:		jsr	MoreOff
			jsr	AllOff

			bchg	#0,DirectFlag

			bsr	BlankScope
			move.b	#1,DrawUpdateFlag
			jmp	Scope


;Settings menu:

SetAutoPoints:		jsr	MoreOff
			jsr	AllOff

			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenAPointsWindow
			tst.l	d0
			bne	.Done

			movea.l	APointsGadgets,a0
			move.w	AutoPoints,d0
			bsr	SetGadget

			movea.l	APointsGadgets,a0
			movea.l	APointsWnd,a1
			bsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	APointsWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.NoChange

			btst	#6,d2			;Gadget up?
			beq.s	.Next

.Close:			movea.l	APointsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			tst.l	d0
			beq.s	.Bad

			cmpi.l	#100,d0
			bls.s	.Skip

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.Skip:			move.w	d0,AutoPoints

.NoChange:		jsr	CloseAPointsWindow

.Done:			bsr	OpenMenu
			jmp	Scope

SetPattern:		jsr	MoreOff
			jsr	AllOff

			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenPatternWindow
			tst.l	d0
			bne	.Done

			movea.l	PatternGadgets,a0
			move.w	PatSize,d0
			bsr	SetGadget

			movea.l	PatternGadgets,a0
			movea.l	(a0),a0
			move.w	PatPoints,d0
			bsr	SetGadget

			movea.l	PatternGadgets,a0
			movea.l	(a0),a0
			movea.l	PatternWnd,a1
			bsr	RefreshGads2

			movea.l	PatternGadgets,a0

.NextGadget:		movea.l	PatternWnd,a1
			bsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	PatternWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.NoChange2

			btst	#6,d2			;Gadget up?
			beq.s	.Next

			movea.l	d3,a0
			tst.l	(a0)
			beq.s	.Close

			movea.l	(a0),a0
			bra.s	.NextGadget

.Close:			movea.l	PatternGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#127,d0
			bhi.s	.Bad

			cmpi.l	#10,d0
			bhs.s	.Okay

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.Okay:			move.w	d0,PatSize

.NoChange:		movea.l	PatternGadgets,a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			bclr	#0,d0			;Even

			cmpi.l	#360,d0
			bhi.s	.Bad2

			cmpi.l	#4,d0
			bhs.s	.Okay2

.Bad2:			bsr	FlashScreen
			bra.s	.NoChange2

.Okay2:			move.w	d0,PatPoints

.NoChange2:		jsr	ClosePatternWindow

.Done:			bsr	OpenMenu

			tst.b	DrawMode
			bne.l	Scope

			bsr.s	SetSineWave
			bsr	RestartSound
			jmp	Scope

SetSineWave:		lea	SineData,a0
			lea	SineWave,a1

			move.w	PatSize,d2
			move.w	PatPoints,d0
			move.w	d0,d7
			move.l	#360,d3
			divu	d0,d3
			lsl.w	#1,d3
			move.l	d3,d5
			swap	d5
			sub.l	d6,d6
			subq.w	#1,d0

.Loop:			move.w	(a0),d1
			muls	d2,d1
			divs	#32767,d1

			move.l	d1,d4
			swap	d4
			bmi.s	.ROff

			cmpi.w	#16384,d4
			blo.s	.ROff2
			addq.b	#1,d1
			bra.s	.ROff2

.ROff:			cmpi.w	#-16384,d4
			bhi.s	.ROff2
			tst.w	d4
			beq.s	.ROff2
			subq.b	#1,d1

.ROff2:			move.b	d1,(a1)+
			adda.w	d3,a0
			add.w	d5,d6
			cmp.w	d7,d6
			blo.s	.ESkip
			sub.w	d7,d6
			addq.l	#2,a0
.ESkip:			dbf	d0,.Loop

			move.l	#SineWave,Loc0
			move.l	#SineWave,Loc1
			move.l	#SineWave,Loc2
			move.l	#SineWave,Loc3

			sub.l	d0,d0
			move.w	PatPoints,d0
			move.l	d0,Len0
			move.l	d0,Len1
			move.l	d0,Len2
			move.l	d0,Len3

			jsr	CheckFreq
			rts

SetHiResSize:		jsr	MoreOff
			jsr	AllOff

			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenHiResSizeWindow
			tst.l	d0
			bne	.Done

			movea.l	HiResSizeGadgets,a0
			move.w	XHiResSize,d0
			bsr	SetGadget

			movea.l	HiResSizeGadgets,a0
			movea.l	(a0),a0
			move.w	YHiResSize,d0
			bsr	SetGadget

			movea.l	HiResSizeGadgets,a0
			movea.l	(a0),a0
			movea.l	HiResSizeWnd,a1
			bsr	RefreshGads2

			movea.l	HiResSizeGadgets,a0

.NextGadget:		movea.l	HiResSizeWnd,a1
			bsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	HiResSizeWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.NoChange2

			btst	#6,d2			;Gadget up?
			beq.s	.Next

			movea.l	d3,a0
			tst.l	(a0)
			beq.s	.Close

			movea.l	(a0),a0
			bra.s	.NextGadget

.Close:			movea.l	HiResSizeGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad

			cmpi.l	#1,d0
			bhs.s	.Okay

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.Okay:			move.w	d0,XHiResSize

.NoChange:		movea.l	HiResSizeGadgets,a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad2

			cmpi.l	#1,d0
			bhs.s	.Okay2

.Bad2:			bsr	FlashScreen
			bra.s	.NoChange2

.Okay2:			move.w	d0,YHiResSize

.NoChange2:		jsr	CloseHiResSizeWindow

.Done:			bsr	OpenMenu
			jsr	SetSoundVol2
			jmp	Scope

SetOutputSize:		jsr	MoreOff
			jsr	AllOff

			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenOutputSizeWindow
			tst.l	d0
			bne	.Done

			movea.l	OutputSizeGadgets,a0
			move.w	XOutSize,d0
			bsr	SetGadget

			movea.l	OutputSizeGadgets,a0
			movea.l	(a0),a0
			move.w	YOutSize,d0
			bsr	SetGadget

			movea.l	OutputSizeGadgets,a0
			movea.l	(a0),a0
			movea.l	OutputSizeWnd,a1
			bsr	RefreshGads2

			movea.l	OutputSizeGadgets,a0

.NextGadget:		movea.l	OutputSizeWnd,a1
			bsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			movea.l	OutputSizeWnd,a0
			bsr	GetWndMsg
			beq.s	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.NoChange2

			btst	#6,d2			;Gadget up?
			beq.s	.Next

			movea.l	d3,a0
			tst.l	(a0)
			beq.s	.Close

			movea.l	(a0),a0
			bra.s	.NextGadget

.Close:			movea.l	OutputSizeGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad

			cmpi.l	#1,d0
			bhs.s	.Okay

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.Okay:			move.w	d0,XOutSize

.NoChange:		movea.l	OutputSizeGadgets,a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad2

			cmpi.l	#1,d0
			bhs.s	.Okay2

.Bad2:			bsr	FlashScreen
			bra.s	.NoChange2

.Okay2:			move.w	d0,YOutSize

.NoChange2:		jsr	CloseOutputSizeWindow

.Done:			bsr	OpenMenu
			jsr	SetSoundVol2
			jmp	Scope

SetDef1:		jsr	MoreOff2
			jsr	AllOff
			move.b	#"1",d0
			lea	ScrDef1,a0
			bsr.s	GetScrDef
			jmp	Scope

SetDef2:		jsr	MoreOff2
			jsr	AllOff
			move.b	#"2",d0
			lea	ScrDef2,a0
			bsr.s	GetScrDef
			jmp	Scope

SetDef3:		jsr	MoreOff2
			jsr	AllOff
			move.b	#"3",d0
			lea	ScrDef3,a0
			bsr.s	GetScrDef
			jmp	Scope

SetDef4:		jsr	MoreOff2
			jsr	AllOff
			move.b	#"4",d0
			lea	ScrDef4,a0
			bsr.s	GetScrDef
			jmp	Scope

GetScrDef:		tst.b	AttachStatus
			beq.s	.ASkip

			clr.b	AttachStatus

			move.w	XPosTemp,d0
			cmp.w	4(a0),d0
			bne.s	.ASet

			move.w	YPosTemp,d0
			cmp.w	6(a0),d0
			bne.s	.ASet

			bsr	FlashScreen
			lea	StatusCenter2,a0
			jsr	PrintStatus
			rts

.ASet:			move.w	XPosTemp,4(a0)		;Position
			move.w	YPosTemp,6(a0)

			lea	StatusAttach5,a0
			jsr	PrintStatus
			rts

.ASkip:			move.b	d0,ScreenDefaultsWTitle+11
			move.l	a0,ScrDefPtr
			bsr	ClearMenu

			sub.l	d0,d0
			jsr	OpenScreenDefaultsWindow
			tst.l	d0
			bne	.Done

			bsr	.SetGads

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	RefreshGads2

			lea	TestPatternFilename,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString

			bsr	LoadFile
			cmpi.b	#1,d0
			beq	.Error

			cmpi.b	#2,d0
			beq	.Error2

			movea.l	FileMemPtr,a1		;Screen?
			lea	ScreenString,a0
			jsr	CmpString
			beq	.Error3

			movea.l	FileMemPtr,a0
			bsr	MakeScreen

			tst.b	LASERfIREFlag
			beq	.NoLf

			bsr	GetLASERfIREMem
			bne.s	.LfSkip

			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			bra.s	.NoLf

.LfSkip:		movea.l	LASERfIREMemPtr,a0
			move.l	a0,LASERfIRECmdPtr
			clr.l	(a0)			;Clear first Len!
			clr.l	LASERfIRESeqLen
			clr.l	DefTrack

			moveq	#28,d1			;Factory all cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			moveq	#22,d1			;Screen def cmd
			bsr	AddLfCmd
			move.l	DefTrack,d0
			move.w	d0,6(a1)		;Track
			moveq	#20,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			movea.l	FileMemPtr,a0
			moveq	#15,d1			;Load Screen cmd
			bsr	LfAddScreen

			moveq	#26,d1			;Stop cmd
			bsr	AddLfCmd
			moveq	#6,d0			;Len
			move.l	d0,(a1)
			add.l	d0,LASERfIRESeqLen

			sub.l	d1,d1			;Mark last
			bsr	AddLfCmd
			clr.l	(a1)			;Len
			addq.l	#6,LASERfIRESeqLen

.NoLf:			jsr	FreeFileMem

			tst.b	DrawMode
			beq	.Done2

			bsr	.UpdateTestPattern

			movea.l	ScreenDefaultsGadgets,a0

.NextGadget:		movea.l	ScreenDefaultsWnd,a1
			bsr	ActivateGad
			bra.s	.Next

.Wait:			jsr	Clock
			bsr	ShortDelay

.Next:			clr.b	UpdateItFlag

			bsr	.GetPotOne
			move.w	PotOne,d0
			cmp.w	2(a0),d0		;Horizpot
			beq.s	.NextPot

			move.w	2(a0),d0
			move.w	d0,PotOne
			mulu	#63,d0
			divu	#$ffff,d0
			addq.w	#1,d0
			movea.l	ScrDefPtr,a1
			move.w	d0,(a1)
			movea.l	ScreenDefaultsGadgets,a0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	GadChg2
			move.b	#1,UpdateItFlag

.NextPot:		bsr	.GetPotTwo
			move.w	PotTwo,d0
			cmp.w	2(a0),d0		;Horizpot
			beq.s	.NextPot2

			move.w	2(a0),d0
			move.w	d0,PotTwo
			mulu	#63,d0
			divu	#$ffff,d0
			addq.w	#1,d0
			movea.l	ScrDefPtr,a1
			move.w	d0,2(a1)
			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	GadChg2
			move.b	#1,UpdateItFlag

.NextPot2:		bsr	.GetPotThree
			move.w	PotThree,d0
			cmp.w	2(a0),d0		;Horizpot
			beq.s	.NextPot3

			move.w	2(a0),d0
			move.w	d0,PotThree
			mulu	#508,d0
			divu	#$ffff,d0
			movea.l	ScrDefPtr,a1
			move.w	d0,4(a1)
			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	GadChg2
			move.b	#1,UpdateItFlag

.NextPot3:		bsr	.GetPotFour
			move.w	PotFour,d0
			cmp.w	2(a0),d0		;Horizpot
			beq.s	.CheckUpdate

			move.w	2(a0),d0
			move.w	d0,PotFour
			mulu	#508,d0
			divu	#$ffff,d0
			movea.l	ScrDefPtr,a1
			move.w	d0,6(a1)
			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	GadChg2
			move.b	#1,UpdateItFlag

.CheckUpdate:		tst.b	UpdateItFlag
			beq.s	.CheckMsg
			bsr	.UpdateTestPattern

.CheckMsg:		movea.l	ScreenDefaultsWnd,a0
			bsr	GetWndMsg
			beq	.Wait

			movea.l	d0,a1
			move.l	$14(a1),d2		;Class
			move.l	$1c(a1),d3		;Gad address
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

			btst	#9,d2			;Close gad?
			bne.s	.Close

			btst	#6,d2			;Gadget up?
			beq	.Next

			movea.l	d3,a0

.GLoop:			tst.l	(a0)
			beq.s	.GFirst

			movea.l	(a0),a0
			cmpi.w	#$104,16(a0)
			bne.s	.GLoop
			bra.s	.GNext

.GFirst:		movea.l	ScreenDefaultsGadgets,a0

.GNext:			move.l	a0,-(sp)
			bsr.s	.UpdateTestPattern

			tst.b	UpdateItFlag
			bne.s	.USkip

			bsr	.SetGads

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	ScreenDefaultsWnd,a1
			bsr	RefreshGads2

.USkip:			movea.l	(sp)+,a0
			bra	.NextGadget

.Close:			jsr	FactoryIt
			bsr	CheckCenter
			jsr	RestartSound

			lea	StatusScrDefSet,a0
			bsr	PrintStatus

.Done2:			jsr	CloseScreenDefaultsWindow
.Done:			bsr	OpenMenu
			rts

.UpdateTestPattern:	movea.l	ScreenDefaultsGadgets,a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad

			cmpi.l	#1,d0
			bhs.s	.Okay

.Bad:			bsr	FlashScreen
			bra.s	.NoChange

.Okay:			movea.l	ScrDefPtr,a1
			move.w	d0,(a1)

.NoChange:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#64,d0
			bhi.s	.Bad2

			cmpi.l	#1,d0
			bhs.s	.Okay2

.Bad2:			bsr	FlashScreen
			bra.s	.NoChange2

.Okay2:			movea.l	ScrDefPtr,a1
			move.w	d0,2(a1)

.NoChange2:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#XMax,d0
			bls.s	.Okay3

			bsr	FlashScreen
			bra.s	.NoChange3

.Okay3:			movea.l	ScrDefPtr,a1
			move.w	d0,4(a1)

.NoChange3:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			move.l	28(a0),d0

			cmpi.l	#YMax,d0
			bls.s	.Okay4

			bsr	FlashScreen
			bra.s	.Update

.Okay4:			movea.l	ScrDefPtr,a1
			move.w	d0,6(a1)

.Update:		tst.b	LASERfIREFlag
			beq.s	.NoLf2

			move.l	LASERfIREMemPtr,d0
			beq.s	.NoLf2

			movea.l	ScrDefPtr,a0
			movea.l	d0,a1
			addq.l	#6,a1
			move.w	(a0)+,8(a1)		;Size X
			move.w	(a0)+,10(a1)		;Size Y
			move.w	(a0)+,d0
			mulu.w	#32767/(XMax/2),d0
			move.l	d0,12(a1)		;Pos X
			move.w	(a0),d0
			mulu.w	#32767/(YMax/2),d0
			move.l	d0,16(a1)		;Pos Y
			bsr	SendLASERfIRESeq

.NoLf2:			movea.l	ScrDefPtr,a0
			move.w	(a0),DefXSize
			move.w	2(a0),DefYSize
			move.w	4(a0),XPosTemp
			move.w	6(a0),YPosTemp
			sub.l	d2,d2
			bsr	CalcMoveRate
			bsr	MoveLaser

			move.b	#1,UseScrDefFlag
			bsr	RestartSound
			clr.b	UseScrDefFlag
			rts

.SetGads:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	ScrDefPtr,a1
			move.w	(a1),d0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	ScrDefPtr,a1
			move.w	2(a1),d0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	ScrDefPtr,a1
			move.w	4(a1),d0
			bsr	SetGadget

			movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	ScrDefPtr,a1
			move.w	6(a1),d0
			bsr	SetGadget

			bsr	.GetPotOne
			movea.l	ScrDefPtr,a1
			move.l	#$ffff,d0
			move.w	(a1),d1
			subq.w	#1,d1
			mulu.w	d1,d0
			divu	#63,d0
			move.w	d0,2(a0)		;Horizpot
			move.w	d0,PotOne
			move.w	#$ffff/63,6(a0)		;Horizbody

			bsr	.GetPotTwo
			movea.l	ScrDefPtr,a1
			move.l	#$ffff,d0
			move.w	2(a1),d1
			subq.w	#1,d1
			mulu.w	d1,d0
			divu	#63,d0
			move.w	d0,2(a0)		;Horizpot
			move.w	d0,PotTwo
			move.w	#$ffff/63,6(a0)		;Horizbody

			bsr.s	.GetPotThree
			movea.l	ScrDefPtr,a1
			move.l	#$ffff,d0
			mulu.w	4(a1),d0
			divu	#508,d0
			move.w	d0,2(a0)		;Horizpot
			move.w	d0,PotThree
			move.w	#$ffff/508,6(a0)	;Horizbody

			bsr.s	.GetPotFour
			movea.l	ScrDefPtr,a1
			move.l	#$ffff,d0
			mulu.w	6(a1),d0
			divu	#508,d0
			move.w	d0,2(a0)		;Horizpot
			move.w	d0,PotFour
			move.w	#$ffff/508,6(a0)	;Horizbody
			rts

.GetPotOne:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			rts

.GetPotTwo:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			rts

.GetPotThree:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			rts

.GetPotFour:		movea.l	ScreenDefaultsGadgets,a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	(a0),a0
			movea.l	34(a0),a0
			rts

.Error:			jsr	CloseScreenDefaultsWindow
			bsr	OpenMenu
			bsr	FlashScreen
			lea	Error3Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			rts

.Error2:		jsr	CloseScreenDefaultsWindow
			bsr	OpenMenu
			bsr	FlashScreen
			lea	Error30Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			rts

.Error3:		bsr	FreeFileMem
			jsr	CloseScreenDefaultsWindow
			bsr	OpenMenu
			bsr	FlashScreen
			lea	Error17Text,a0
			bsr	PrintStatus
			bsr	LongDelay
			rts

GetNextSelect:		move.w	d4,d0

			movea.l	LaserMenus,a0		;Menu
			move.w	d0,d1
			andi.w	#$1f,d1
			bsr.s	.FindIt

			movea.l	18(a0),a0		;Item
			lsr.w	#5,d0
			move.w	d0,d1
			andi.w	#$3f,d1
			bsr.s	.FindIt

			lsr.w	#6,d0			;Sub item?
			cmpi.b	#$1f,d0
			beq.s	.Done

			movea.l	28(a0),a0
			move.w	d0,d1
			bsr.s	.FindIt

.Done:			move.w	32(a0),NextSelect
			rts

.FindIt:		subq.w	#1,d1
			bmi.s	.End
.Loop:			move.l	(a0),a0
			dbf	d1,.Loop
.End:			rts


;Print value text:

UpdateText:		cmpi.b	#8,TextCount
			blo	.End

			clr.b	TextCount

			tst.b	ShowRSFlag
			beq.s	.Normal

			move.w	RotateAngle01,d0
			cmp.w	RotateAngle01Print,d0
			beq.s	.NSkip
			bsr	PrintRotateAngle01

.NSkip:			move.w	RotateAngle23,d0
			cmp.w	RotateAngle23Print,d0
			beq.s	.NSkip2
			bsr	PrintRotateAngle23

.NSkip2:		move.w	Spin0,d0
			cmp.w	Spin0Print,d0
			beq.s	.NSkip3
			bsr	PrintSpin0

.NSkip3:		move.w	Spin1,d0
			cmp.w	Spin1Print,d0
			beq.s	.NSkip4
			bsr	PrintSpin1

.NSkip4:		move.w	Spin2,d0
			cmp.w	Spin2Print,d0
			beq.s	.NSkip5
			bsr	PrintSpin2

.NSkip5:		move.w	Spin3,d0
			cmp.w	Spin3Print,d0
			beq	.Skip8
			bsr	PrintSpin3
			bra	.Skip8

.Normal:		move.w	Vol0,d0
			cmp.w	Vol0Print,d0
			beq.s	.Skip
			bsr	PrintVol0

.Skip:			move.w	Vol1,d0
			cmp.w	Vol1Print,d0
			beq.s	.Skip2
			bsr	PrintVol1

.Skip2:			move.w	Vol2,d0
			cmp.w	Vol2Print,d0
			beq.s	.Skip3
			bsr	PrintVol2

.Skip3:			move.w	Vol3,d0
			cmp.w	Vol3Print,d0
			beq.s	.Skip4
			bsr	PrintVol3

.Skip4:			move.w	Freq0,d0
			cmp.w	Freq0Print,d0
			beq.s	.Skip5
			bsr	PrintFreq0

.Skip5:			move.w	Freq1,d0
			cmp.w	Freq1Print,d0
			beq.s	.Skip6
			bsr	PrintFreq1

.Skip6:			move.w	Freq2,d0
			cmp.w	Freq2Print,d0
			beq.s	.Skip7
			bsr	PrintFreq2

.Skip7:			move.w	Freq3,d0
			cmp.w	Freq3Print,d0
			beq.s	.Skip8
			bsr	PrintFreq3

.Skip8:			move.w	Phase1,d0
			cmp.w	Phase1Print,d0
			beq.s	.Skip9
			bsr	PrintPhase1

.Skip9:			move.w	Phase2,d0
			cmp.w	Phase2Print,d0
			beq.s	.Skip10
			bsr	PrintPhase2

.Skip10:		move.w	Phase3,d0
			cmp.w	Phase3Print,d0
			beq.s	.Skip11
			bsr	PrintPhase3

.Skip11:		tst.b	PrintPosSig
			beq.s	.End

			clr.b	PrintPosSig

			lea	PosText,a0
			lea	ASCIIBuffer,a1
			bsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	XPosPrint,d0
			bsr	HEXtoASCII

			lea	PosText2,a0
			bsr	MoveString
			lea	-1(a1),a0
			sub.l	d0,d0
			move.w	YPosPrint,d0
			bsr	HEXtoASCII

			lea	ASCIIBuffer,a0
			bsr	PrintStatus2
.End:			rts

PrintVol0:		sub.l	d0,d0
			move.w	Vol0,d0
			move.w	d0,Vol0Print
			lea	LaserIText6,a0
			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

			lea	LaserText6,a1
			bsr	PrintWinText
			rts

PrintVol1:		sub.l	d0,d0
			move.w	Vol1,d0
			move.w	d0,Vol1Print
			lea	LaserIText9,a0
			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

			lea	LaserText9,a1
			bsr	PrintWinText
			rts

PrintVol2:		sub.l	d0,d0
			move.w	Vol2,d0
			move.w	d0,Vol2Print
			lea	LaserIText13,a0

			tst.b	DrawMode
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

.Skip2:			lea	LaserText13,a1
			bsr	PrintWinText
			rts

PrintVol3:		sub.l	d0,d0
			move.w	Vol3,d0
			move.w	d0,Vol3Print
			lea	LaserIText17,a0

			tst.b	DrawMode
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

.Skip2:			lea	LaserText17,a1
			bsr	PrintWinText
			rts

PrintFreq0:		sub.l	d0,d0
			move.w	Freq0,d0
			move.w	d0,Freq0Print

			move.l	Len0,d1

			tst.b	DrawMode
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		tst.b	PeriodFlag
			beq.s	.Skip2

			move.l	#35795465,d0
			mulu	Freq0,d1
			divu.l	d1,d0
			bra.s	.Skip3

.Skip2:			tst.b	PPSFlag
			beq.s	.Skip4

			move.l	d1,d0
			move.l	#35795465,d1
			mulu	Freq0,d0
			divu.l	d0,d1

			move.l	#3579547,d0
			divu	d1,d0
			andi.l	#$ffff,d0

.Skip3:			lea	LaserIText7,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)
			bra.s	.Skip5

.Skip4:			lea	LaserIText7,a0
			bsr	MakeFreq

.Skip5:			lea	LaserText7,a1
			bsr	PrintWinText
			rts

PrintFreq1:		sub.l	d0,d0
			move.w	Freq1,d0
			move.w	d0,Freq1Print

			move.l	Len1,d1

			tst.b	DrawMode
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		tst.b	PeriodFlag
			beq.s	.Skip2

			move.l	#35795465,d0
			mulu	Freq1,d1
			divu.l	d1,d0
			bra.s	.Skip3

.Skip2:			tst.b	PPSFlag
			beq.s	.Skip4

			move.l	d1,d0
			move.l	#35795465,d1
			mulu	Freq1,d0
			divu.l	d0,d1

			move.l	#3579547,d0
			divu	d1,d0
			andi.l	#$ffff,d0

.Skip3:			lea	LaserIText10,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)
			bra.s	.Skip5

.Skip4:			lea	LaserIText10,a0
			bsr	MakeFreq

.Skip5:			lea	LaserText10,a1
			bsr	PrintWinText
			rts

PrintFreq2:		sub.l	d0,d0
			move.w	Freq2,d0
			move.w	d0,Freq2Print

			tst.b	DrawMode2
			beq.s	.Skip

			lea	LaserIText14,a0
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra	.Skip6

.Skip:			move.l	Len2,d1

			tst.b	DrawMode
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		tst.b	PeriodFlag
			beq.s	.Skip3

			move.l	#35795465,d0
			mulu	Freq2,d1
			divu.l	d1,d0
			bra.s	.Skip4

.Skip3:			tst.b	PPSFlag
			beq.s	.Skip5

			move.l	d1,d0
			move.l	#35795465,d1
			mulu	Freq2,d0
			divu.l	d0,d1

			move.l	#3579547,d0
			divu	d1,d0
			andi.l	#$ffff,d0

.Skip4:			lea	LaserIText14,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)
			bra.s	.Skip6

.Skip5:			lea	LaserIText14,a0
			bsr	MakeFreq

.Skip6:			lea	LaserText14,a1
			bsr	PrintWinText
			rts

PrintFreq3:		sub.l	d0,d0
			move.w	Freq3,d0
			move.w	d0,Freq3Print

			tst.b	DrawMode2
			beq.s	.Skip

			lea	LaserIText18,a0
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra	.Skip6

.Skip:			move.l	Len3,d1

			tst.b	DrawMode
			beq.s	.LSkip2

			tst.b	AutoRetraceFlag
			beq.s	.LSkip

			lsl.l	#1,d1

.LSkip:			addq.l	#1,d1
			bclr	#0,d1

.LSkip2:		tst.b	PeriodFlag
			beq.s	.Skip3

			move.l	#35795465,d0
			mulu	Freq3,d1
			divu.l	d1,d0
			bra.s	.Skip4

.Skip3:			tst.b	PPSFlag
			beq.s	.Skip5

			move.l	d1,d0
			move.l	#35795465,d1
			mulu	Freq3,d0
			divu.l	d0,d1

			move.l	#3579547,d0
			divu	d1,d0
			andi.l	#$ffff,d0

.Skip4:			lea	LaserIText18,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)
			bra.s	.Skip6

.Skip5:			lea	LaserIText18,a0
			bsr.s	MakeFreq

.Skip6:			lea	LaserText18,a1
			bsr	PrintWinText
			rts

MakeFreq:		move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)

			divu	#10,d0
			move.l	d0,-(sp)
			andi.l	#$ffff,d0
			bsr	HEXtoASCII
			move.l	(sp)+,d0
			swap.w	d0
			andi.l	#$f,d0
			beq.s	.Skip

			move.b	#".",(a1)+
			addi.b	#"0",d0
			move.b	d0,(a1)+

.Skip:			move.b	#$20,(a1)
			clr.b	5(a0)
			rts

PrintPhase1:		sub.l	d0,d0
			move.w	Phase1,d0
			move.w	d0,Phase1Print

			lea	LaserIText11,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	3(a0)

			lea	LaserText11,a1
			bsr	PrintWinText
			rts

PrintPhase2:		sub.l	d0,d0
			move.w	Phase2,d0
			move.w	d0,Phase2Print

			lea	LaserIText15,a0

			tst.b	DrawMode
			beq.s	.Skip

			tst.b	HiResFlag
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	3(a0)

.Skip2:			lea	LaserText15,a1
			bsr	PrintWinText
			rts

PrintPhase3:		sub.l	d0,d0
			move.w	Phase3,d0
			move.w	d0,Phase3Print

			lea	LaserIText19,a0

			tst.b	DrawMode
			beq.s	.Skip

			tst.b	HiResFlag
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	3(a0)

.Skip2:			lea	LaserText19,a1
			bsr	PrintWinText
			rts

PrintRotateAngle01:	sub.l	d0,d0
			move.w	RotateAngle01,d0
			move.w	d0,RotateAngle01Print
			lea	LaserIText6,a0
			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

			lea	LaserText6,a1
			bsr	PrintWinText
			rts

PrintRotateAngle23:	lea	LaserIText13,a0

			tst.b	DrawMode
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			sub.l	d0,d0
			move.w	RotateAngle23,d0
			move.w	d0,RotateAngle23Print
			bsr	HEXtoASCII
			move.b	#$20,(a1)+
			move.b	#$20,(a1)
			clr.b	3(a0)

.Skip2:			lea	LaserText13,a1
			bsr	PrintWinText
			rts

PrintSpin0:		sub.l	d0,d0
			move.w	Spin0,d0
			move.w	d0,Spin0Print

			lea	LaserIText7,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)

			lea	LaserText7,a1
			bsr	PrintWinText
			rts

PrintSpin1:		sub.l	d0,d0
			move.w	Spin1,d0
			move.w	d0,Spin1Print

			lea	LaserIText10,a0
			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)

			lea	LaserText10,a1
			bsr	PrintWinText
			rts

PrintSpin2:		sub.l	d0,d0
			move.w	Spin2,d0
			move.w	d0,Spin2Print

			lea	LaserIText14,a0

			tst.b	DrawMode
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)

.Skip2:			lea	LaserText14,a1
			bsr	PrintWinText
			rts

PrintSpin3:		sub.l	d0,d0
			move.w	Spin3,d0
			move.w	d0,Spin3Print

			lea	LaserIText18,a0

			tst.b	DrawMode
			beq.s	.Skip

			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			move.b	#"-",(a0)+
			clr.b	(a0)
			bra.s	.Skip2

.Skip:			move.b	#$20,1(a0)
			move.b	#$20,2(a0)
			move.b	#$20,3(a0)
			move.b	#$20,4(a0)
			bsr	HEXtoASCII
			move.b	#$20,(a1)
			clr.b	5(a0)

.Skip2:			lea	LaserText18,a1
			bsr	PrintWinText
			rts

PrintStatus:		clr.b	UseScrDefFlag
			clr.b	SmoothChgFlag2
			clr.b	PlayStatus
			clr.b	PreloadFlag
			bsr	FreePreloadMem

PrintStatus2:		move.l	#25,StatusCount
PrintStatus3:		move.l	a0,-(sp)

			lea	LaserIText1,a0
			movea.l	a0,a1
			moveq	#17,d0

.Loop:			move.w	#$2020,(a0)+
			dbf	d0,.Loop

			lea	RecText,a0
			tst.b	RecordStatus
			bne.s	.Skip

			lea	ManText,a0
			tst.b	PlayStatus
			beq.s	.Skip

			lea	PlayText,a0
			cmpi.b	#3,PlayStatus
			blo.s	.Skip

			lea	PauseText,a0

.Skip:			bsr	MoveString
			subq.l	#1,a1

			movea.l	(sp)+,a0
			moveq	#29,d0
			bsr	MoveString6
			move.b	#$20,-(a5)

			lea	LaserText1,a1
			bsr	PrintWinText
			rts


;Clean up and exit:

Quit:			jsr	SeqStuffOff
			jsr	AllOff

			bsr	FlashScreen
			lea	SureText,a1
			lea	QuitText2,a2
			bsr	Requester
			beq.l	Scope

			jsr	CloseMagnifyGlassWindow
			jsr	CloseLaserWindow
			jsr	CloseDownScreen

Exit9:			jsr	ParShutterOn2
			bsr	ShortDelay
			bsr	ShortDelay

			move.w	#$f,$dff096		;Stop DMA
			move.w	#$780,$dff09a		;Disable all int
			bclr	#1,$bfe001		;Filter on

			clr.w	$dff0a8			;Vols off
			clr.w	$dff0b8
			clr.w	$dff0c8
			clr.w	$dff0d8

			bsr	FreeLASERfIREMem
			bsr	FreeUndoMem
			bsr	FreePreloadMem
			bsr	FreeCharBSMem
			jsr	FreeDrawMem
			jsr	FreeMorphMem
			jsr	FreeFontMem
			bsr	KillBuffer

			lea	Preset1DrawPtr,a0	;Free preset draw mem
			moveq	#39,d0

.Loop:			tst.l	(a0)
			beq.s	.Skip

			move.l	d0,-(sp)
			move.l	a0,-(sp)
			movea.l	(a0),a1
			move.l	4(a0),d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)
			movea.l	(sp)+,a0
			move.l	(sp)+,d0

.Skip:			adda.w	#8,a0
			dbf	d0,.Loop

			bsr	FreeSeqMem		;Free all sequence mem

			lea	SeqMemSize1,a0
			lea	SeqMemPtr1,a1
			move.l	#331,d0

.Loop2:			move.l	d0,-(sp)
			move.l	a1,-(sp)
			bsr	FreeSeqMem2
			movea.l	(sp)+,a1
			move.l	(sp)+,d0
			adda.w	#8,a0
			adda.w	#8,a1
			dbf	d0,.Loop2

Exit8:			tst.b	SerialFlag
			bne.s	.Skip
			jsr	CloseSerial

.Skip:			bsr	FreeOutputBuff

Exit7:			movea.l	ExtrasBufferPtr,a1
			move.l	#MaxPoints*4,d0
			movea.l	(4).l,a6
			jsr	_LVOFreeMem(a6)

Exit6:			moveq	#5,d0
			lea	VBlankIntNode,a1
			movea.l	(4).l,a6
			jsr	_LVORemIntServer(a6)

			move.l	ReqBase,d0
			beq.s	.Skip
			movea.l	d0,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

.Skip:			movea.l	KeyBase,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

Exit5:			movea.l	GadBase,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

Exit4:			movea.l	GfxBase,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

Exit3:			movea.l	IntBase,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

Exit2:			movea.l	DosBase,a1
			movea.l	(4).l,a6
			jsr	_LVOCloseLibrary(a6)

Exit:			move.l	WBMsgPtr,d0
			beq.s	.Skip

			movea.l	d0,a1
			movea.l	(4).l,a6
			jsr	_LVOReplyMsg(a6)

.Skip:			movea.l	StackPtr,sp
			sub.l	d0,d0
			rts


			include	"DH0:Asm/Laser2.asm"

