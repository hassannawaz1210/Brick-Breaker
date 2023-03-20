;=========Team Members===========
;	Hassan nawaz - i21-2993
;	Haris Sohail - i21-0531
;	Minhaaj Saqib -i21-0719
;================================
.model small
.stack 100h
.data
;================================
filename db '1MM.bmp', 0

filename_main_menu      db '1MM.bmp', 0
                        db '2MM.bmp', 0
                        db '3MM.bmp', 0
                        db '4MM.bmp', 0
                        db '5MM.bmp', 0
;--- variables for stats reading and writing
statsFile db "stats.txt", 0
statsHandle dw 0
tempStr db '$$$$'
buffer db 500 dup('$')
bufferLen dw 0
mode db 0

;---FILE NAMES MUST BE 3 LETTERS LONG
instructions db 'ins.bmp', 0
winFile db 'win.bmp',0
loseFile db 'los.bmp',0
logoFile db 'lgo.bmp',0

eight db 8
handle_file dw ?
bmp_header db 54 dup (0) 
color_palette db 256*4 dup (0) 
Output_lines db 320 dup (0) ; 
error_prompt db 'Error', 13, 10,'$'
;================================

;----------bar's variables
BarStruct struct
	CoordX dw 130
	CoordY dw 190
	Length_ dw 60
	Width_ dw 5
	Speed dw 20
BarStruct ends
;bar variable
bar BarStruct 1 dup(<>)

;----------ball's variables
BallStruct struct
	CoordX dw 0
	CoordY dw 0
	SpeedX dw 5
	SpeedY dw 5
BallStruct ends
;ball variables
ball BallStruct 1 dup(<>)
isBallLaunched db 0
;constants
ballSize = 5
;----------- bricks
BrickStruct struct
	CoordX dw 0
	CoordY dw 0
	Color db 0
	Health dw 1
BrickStruct ends
brickWidth = 20
brickLength = 40
bricksCount dw 0

brick BrickStruct    <40,20,9>, <90,20,10>, <140,20,11>, <190,20,12>, <240,20,13>, 
					 <40,50,9>, <90,50,10>, <140,50,11>, <190,50,12>, <240,50,13>,
					 <40,80,9>, <90,80,10>, <140,80,11>, <190,80,12>, <240,80,13>
					 
fixedBricks BrickStruct <40,20,9>, <240,20,13>, <140,50,11>,  <40,80,9>, <240,80,13>

						
;------------ player
PlayerStruct struct
	Score dw 0
	Lives dw 3
	igName db 30 dup(0)
	nameLen dw 0
PlayerStruct ends
;player variable
player PlayerStruct <>

;------------ misc vars
leaderBoardMsg db "Leader Board", '$'

scoreMsg db "Score: ",'$'
nameMsg_1 db "Player Name: ", '$'
nameMsg_2 db "Name: ",'$'
livesMsg db "Lives: ",'$'
levelMsg db "Level: ", '$'
pauseMsg db "Game is paused.", 10,9, "  Press esc to resume.", '$' ;10 for linefeed, 9 for tab

gameLevel dw 0
timeRemaining dw 0
timeVar_1 db 0
timeVar_2 db 0
windowsWidth = 200
windowsLength = 320
statsVar dw 0
count dw 0
isGamePaused dw 0
currentImage dw 0
beepFreq dw 400

;-------
.code
;------------- MACROs
	makeBall MACRO
		mov al, 0fh; white colour ball
		call drawBall
	ENDM

	clearBall MACRO
		mov al, 00h; black colour ball
		call drawBall
	ENDM
	
	attachBallToBar MACRO
	clearBall
		mov ax, bar.CoordX
		mov ball.CoordX, ax
		mov bx, bar.Length_; 	getting the midpoint of the paddle
		shr bx, 1
		add ball.CoordX, bx
		mov ax, bar.CoordY
		sub ax, 10
		mov ball.CoordY, ax
		mov isBallLaunched, 0
		
		
		or ball.SpeedY,0
		js directionSkip1
		neg ball.SpeedY
		directionSkip1:
		
	ENDM

	makeBar MACRO
		mov al, 0fh; white colour bar
		call drawBar
	ENDM

	clearBar MACRO
		mov al, 00h; black colour bar
		call drawBar
	ENDM
	
	setVideoMode MACRO
		mov ah, 0;	setting video mode
		mov al, 13h
		int 10h
	ENDM
	
	addBrokenBrick MACRO
		mov di, -1
		brokenBrickLoop:
			inc di
			cmp brokenBricks[di], -1
		jne brokenBrickLoop
		mov brokenBricks[di], ax ;(ax has the value of si)
	ENDM
	
	clearBrick MACRO si
		
		mov bh, 0; page number
		mov al, 0
		
		mov cx, brick[si].CoordX ;inital x
		mov dx, brick[si].CoordY ;inital y
		mov brickLoopVar, 20
		clearBrickLoop_2:
			mov di, brickLength
			mov cx, brick[si].CoordX
			clearBrickLoop_3:
				call drawPixel
				inc cx
					
			dec di
			cmp di, 0
			jne clearBrickLoop_3
			
			inc dx
		dec brickLoopVar
		cmp brickLoopVar, 0
		jne clearBrickLoop_2
	ENDM
	
	displayPauseMsg MACRO
		setCursorAt 18, 13
		displayMsg pauseMsg
	ENDM
	
	updateTime MACRO
		;----------- 4 mins of game time
		;if
		cmp timeVar_2, dh
		je timeSkip
		;else
		inc timeRemaining
		mov timeVar_2, dh
		;-setting the cursor position
		setCursorAt 1, 17
		
		mov ax, timeRemaining
		mov statsVar, ax
		call updateStats
		;---
		cmp timeRemaining, 1000
		je exitGame
		
		timeSkip:
	ENDM

	nextLineMacro MACRO
		mov ah, 02h
		mov dl, 10
		int 21h
	ENDM
	
	fiveSpaceMacro MACRO
		mov si, 0
		.while(si != 5)
			mov ah, 02h
			mov dl, 32
			int 21h
		inc si
		.endw
	ENDM
	
	singleSpaceMacro MACRO
		mov ah, 02h
		mov dl, 32
		int 21h
	ENDM
	
	displayMsg MACRO source
		mov dx, offset source
		mov ah, 09h
		int 21h
	endm
	
	setCursorAt MACRO row, col
		mov ah, 02h
		mov bh, 0
		mov dh, row
		mov dl, col
		int 10h
	ENDM
	
	
	copyFileName MACRO
	 ; ------ push the source string
			mov bx, offset filename_main_menu 
			mov ax, currentImage
			mul eight
			add bx, ax
			push bx
			; ------ push the destination string
			mov bx, offset filename 
			push bx
			call copyString
	ENDM
	
	writeToFile MACRO len, source
		mov ah, 40h ; service to write to a file
		mov bx, statsHandle
		mov cx, len ;length of string
		mov dx, offset source
		int 21h
	ENDM
	
	winLoseMacro MACRO source
		mov timeRemaining, 0
		mov bx, offset source
		push bx
		mov bx, offset filename
		push bx
		call copyString
		call displayImage
	ENDM
	

;------- Attaching the data segment
mov ax, @data
mov ds, ax
mov ax, 0

;---------- Main Procedure
main proc
	
	setVideoMode
	call displayLogo
	call delay
	call mainMenu
	call game

mov ah, 4ch
int 21h
main endp

;---------------------------------------------------------------------------------------------
game PROC uses ax bx cx dx si di

	attachBallToBar
	
gameLoop:
	mov ah, 2ch	;getting system time
	int 21h
	
	;updating game time
	.if(isGamePaused == 0)
		updateTime
		call updateGameLevel
	.endif
	
	;constantly checking if the player has either lost or won
	call youLose
	call youWin

	;if 1/100 second hasnt passed, repeat loop
	cmp dl, timeVar_1
	je gameLoop
	
	;displaying the score
	call displayStats
	
	;moving the ball
	clearBall
	call moveBall
	makeBall
	
	;check collision with brick
	call brickCollision
	
	;moving the barfe
	clearBar
	call keyboardInput
	makeBar
	

	;Now that 1/100 sec has passed, store the prev second in time var and repeat the loop again
	mov timeVar_1, dl
	jmp gameLoop
	
	exitGame:
ret
game endp
;-----------
displayLogo proc
	mov bx, offset logoFile
	push bx
	mov bx, offset filename
	push bx
	call copyString
	call displayImage
ret
displayLogo endp
;------------
delay Proc
mov si, 0
.while(si != 150)
  mov cx,1 
  mov dx,3dah
  delayLoop_1:
    push cx
    delayLoop_2:
      in al,dx
      and al,08h
      jnz delayLoop_2
    delayLoop_3:
      in al,dx
      and al,08h
      jz delayLoop_3
   pop cx
   loop delayLoop_1
inc si
.endw
  ret
delay ENDP
;--------------------- 
youLose Proc uses ax bx cx dx si di
	.if(player.Lives == 0) || (timeRemaining == 240)
		;displaying losing screen
			winLoseMacro loseFile
			;---- waiting for a key to be pressed
			mov ah, 00
			int 16h
			;----save stats
			call saveStats
			;-----showing back the menu
			call mainMenu	
	.endif	
ret
youLose endp

;---------------------
youWin Proc uses ax bx cx dx si di
	.if(gameLevel == 3) && (bricksCount == 10)
		;displaying losing screen
			winLoseMacro winFile
			;---- waiting for a key to be pressed
			mov ah, 00
			int 16h 
			;----save stats
			call saveStats
			;-----showing back the menu
			call mainMenu
	.endif
ret
youWin endp

;------------------------------
mainMenu proc uses bx
    setVideoMode
	mov currentImage, 0
	copyFileName
	call displayImage
menuLoop:

	mov ah, 1
	int 16h
	jnz menuLoop
    ;getting keyboard input
    mov ah, 0
    int 16h

	cmp ah, 50H
	je downKey
	cmp ah, 48H
	je upKey
	cmp ah, 28 
	je enterKey
	cmp ah, 1
	je escapeKey
	
	jmp menuLoop
	
	downKey:
		.if(currentImage != 4)
			inc currentImage			
			copyFileName
			setVideoMode
			call displayImage
			mov ax, currentImage
			mov statsVar, ax
			call updateStats

		.endif
	jmp menuLoop 
       
    upKey:
		.if(currentImage != 0)
			dec currentImage
			copyFileName
			setVideoMode
			call displayImage
			mov ax, currentImage
			mov statsVar, ax
			call updateStats
		.endif
    jmp menuLoop 
	
	enterKey:
	;========= new game
	.if(currentImage == 0)	
		setVideoMode
		mov player.Lives, 3
		mov player.Score, 0
		mov gameLevel, 1
		mov bricksCount, 0
		mov isGamePaused, 0
		
		mov bar.CoordX, 130
		mov bar.CoordY, 190
		mov bar.Length_, 60
		
		mov ball.SpeedX, 5
		mov ball.SpeedY, 5
		
		call resetBricks
		mov timeRemaining, 0
		
		attachBallToBar
		call inputName
		call drawBricks
		ret
		
	;========= resume game
	.elseif (currentImage == 1)
		.if(timeRemaining>0)
		setVideoMode
		call drawBricks
		mov isGamePaused, 0
		mov isBallLaunched, 1
		ret
		.endif
		jmp menuLoop
		
	;========= instructions
	.elseif (currentImage == 2)
		mov bx, offset instructions
		push bx
		mov bx, offset filename
		push bx
		call copyString
		call displayImage
		;---- waiting for a key to be pressed
		mov ah, 00
		int 16h
		;---- 
		mov currentImage, 0
		mov bx, offset filename_main_menu
		push bx
		mov bx, offset filename
		push bx
		call copyString
		call displayImage
		jmp menuLoop
	
	;========= highscore 
	.elseif (currentImage == 3)
		setVideoMode
		call fetchStats
		call orderLeaderBoard
		
		setCursorAt 1, 13
		displayMsg leaderBoardMsg	
		nextLineMacro		
		setCursorAt 3, 0
		SingleSpaceMacro
		displayMsg nameMsg_2		
		fiveSpaceMacro	
		displayMsg levelMsg		
		fiveSpaceMacro		
		displayMsg scoreMsg		
		nextLineMacro	
		setCursorAt 5, 0	
		displayMsg buffer
		
		;---- waiting for a key to be pressed
		mov ah, 0
		int 16h
		
		setVideoMode
		call displayImage
		jmp menuLoop
		
	; ========= exit game
	.elseif (currentImage == 4)
		setVideoMode
		mov ah, 4ch
		int 21h
		ret
	.endif
    jmp menuLoop
	
	;resume the game
	escapeKey:	
		.if(timeRemaining >0)
			setVideoMode
			call drawBricks
			mov isGamePaused, 0
			mov isBallLaunched,  1
			ret
		.endif
    jmp menuLoop
	
	
	
mainMenu endp
;-----------
orderLeaderBoard proc
	mov si, 0
	.while(si < bufferLen)
		.if(buffer[si] == ',')
			mov buffer[si], 10
		.endif
	inc si
	.endw
ret
orderLeaderBoard endp
;-----------
copyString proc
    pop si ; contains the return address
    pop bx ; destination
    pop di ; source
    mov cx, 8 ; length of source

    ; copies destination to source string
    ; uses indirect addressing
    copyingLoop: 
        mov al, [di]
        mov [bx], al

        inc bx
        inc di
    Loop copyingLoop

    push si
ret
copyString endp

;------------------------------

displayImage proc
	mov dx, offset filename
	call openFile
    call getHeader
    call getPalette
    call copyPallete
    call copyBitmapImage
	call closeFile
ret
displayImage endp


;---------------------------------------------------
updateGameLevel Proc uses si ax
	
	;this will run only when game level is changed
	.if(bricksCount == 15) 
		inc	gameLevel
		mov bricksCount, 0
		
		; Condition for game level 2
		.if(gameLevel == 2)
			clearBar
			sub bar.Length_, 20
			call updateBallSpeed
			mov si, 0
			.while(si < (BrickStruct * 15))
				mov brick[si].Health, 2
			add si, type BrickStruct
			.endw
			
		; Conditions for game level 3
		.else 
			call updateBallSpeed
			mov si, 0
			.while(si < (BrickStruct * 15))
				mov brick[si].Health, 3
			add si, type BrickStruct
			.endw
		.endif
		
		; reverting the bricks to their original coordinates and displaying them
		attachBallToBar
		call resetBricks
		call drawBricks
		
	.endif
ret
updateGameLevel endp
;-----------
updateBallSpeed proc 
		cmp ball.SpeedX, 0
		jl updateBallSpeedSkip_1
		add ball.SpeedX, 3
		updateBallSpeedSkip_1:
		add ball.SpeedX, -3
		
		cmp ball.SpeedY, 0
		jl updateBallSpeedSkip_2
		add ball.SpeedY, 3
		updateBallSpeedSkip_2:
		add ball.SpeedY, -3
ret
updateBallSpeed endp
;----------
resetBricks proc uses si ax di
	local columnsColorTracker:word
	mov columnsColorTracker, 0
	mov si, 0
	mov al, 9
		.while(si < BrickStruct * 15)	
			;---------resetting color
			mov brick[si].Color, al
			.if(columnsColorTracker == 4)
				mov columnsColorTracker, 0
				mov al, 9
			.else
				inc columnsColorTracker
				inc al
			.endif
			;----------------------
			;resetting condition for bricks when a new game starts
			.if(gameLevel == 1) ; 
					mov brick[si].Health, 1
					
					cmp brick[si].CoordX, 0
					jg resetBricksSkip
						neg brick[si].CoordX
						neg brick[si].CoordY
					resetBricksSkip:
			;resetting condition for the bricks when the game level changes
			.else	
				neg brick[si].CoordX 
				neg brick[si].CoordY
			.endif
			
		add si, type BrickStruct
		.endw
ret
resetBricks endp
;--------------------------------------------------
inputName proc uses ax bx cx dx

	;setting the cursor position
	setCursorAt 12, 8
	displayMsg nameMsg_1

	mov ah, 03fh ;string input function
	mov bx, 0; keyboard handle 
	mov cx, 30 ; max bytes to read
	mov dx, offset player.igName
	int 21h ;(****character count is stored in ax****)
	
	;putting a dollar sign at the end
	mov si, 0
inputLoop:
	inc si
	cmp player.igName[si], 10
jne inputLoop
	mov player.nameLen, si
	dec si
	mov player.igName[si], '$'
	;mov bx, ax 
	;mov player.igName[bx], '$'
	
	setVideoMode
	
	
ret
inputName endp
;--------------------------
displayStats proc uses ax bx dx
;----------------	Score
	;setting the cursor position
	setCursorAt 1, 1
	displayMsg scoreMsg
	
	;updating the cursor position for numeric value of score
	setCursorAt 1, 8
	mov ax, player.Score
	mov statsVar, ax
	call updateStats
	
;------------ Player Name

	setCursorAt 1, 25
	displayMsg nameMsg_2
	setCursorAt 1, 30
	displayMsg player.igName
	
	;------------ Lives
	call clearHearts	
	setCursorAt 24, 1
	displayMsg livesMsg
	setCursorAt 24, 7
	
mov cx, player.Lives
displayHearts:
	mov dl, 3;	displaying hearts
	mov ah, 02h
	int 21h
loop displayHearts
	
	;------------- levelMsg
	setCursorAt 24, 30
	displayMsg levelMsg
	setCursorAt 24, 38
	mov ax, gameLevel
	mov statsVar, ax
	call updateStats

	;------------ 
	
ret
displayStats endp
;-------------------
clearPausedMsg Proc uses ax bx cx dx
	local parentLoopCount:word, childLoopCount: word
	mov parentLoopCount, 25
	mov childLoopCount, 160
	mov cx, 80 ;x coord
	mov dx, 140 ;y- coord
	
	.while(parentLoopCount>0)
		mov cx, 80
		mov childLoopCount, 160
		.while(childLoopCount>0)
		mov ah, 0ch	;write pixel
		mov al, 0	;black color
		mov bh, 0
		int 10h
		inc cx
		dec childLoopCount
		.endw
	inc dx
	dec parentLoopCount
	.endw
ret
clearPausedMsg endp
;-------------------
clearHearts Proc uses ax bx cx dx
	mov ah, 06h
	mov bh, 0 ; black colour
	mov al, 2
	mov ch, 23
	mov dh, 24
	mov cl, 1
	mov dl, 9
	int 10h
ret
clearHearts endp
;---------------------------------------------------------------------------------------------
keyboardInput PROC uses ax bx cx dx
keyboardInput_Loop:

	mov ah, 01;checking for button input
	int 16h
	jz keyboardInputExit

	mov ah, 00;saving the pressed button
	int 16h
	cmp ah, 4Bh; left key
	je leftKey
	cmp ah, 4Dh; right key
	je rightKey
	cmp ah, 57 ; space key
	je launchBall
	cmp ah, 01 ; escape key
	je pauseGame
	jmp keyboardInputExit
	
	
	launchBall:
		;if game is paused
			.if(isGamePaused == 1)
			jmp keyboardInputExit
			.endif
		;else
		mov isBallLaunched, 1
	jmp keyboardInputExit
	
	pauseGame:
		.if(isGamePaused == 0)
			;displayPauseMsg
			mov isGamePaused, 1
			mov isBallLaunched,  0
			call mainMenu
		.endif
	jmp keyboardInputExit


	leftKey:
		;if game is paused
		.if(isGamePaused == 1)
		jmp keyboardInputExit
		.endif
	
		;boundaryCheckLeft
		cmp bar.CoordX, 0
		jle keyboardInput_Loop
		mov ax, bar.Speed
		sub bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne keyboardInput_Loop
		clearBall
		mov ax, bar.Speed
		sub ball.CoordX, ax
		
	jmp keyboardInput_Loop
	

	rightKey:
		;if game is paused
		.if(isGamePaused == 1)
		jmp keyboardInputExit
		.endif
	
		;boundaryCheckRight
		mov ax, bar.CoordX
		add ax, bar.Length_
		cmp ax, windowsLength
		jge keyboardInput_Loop
		mov ax, bar.Speed
		add bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne keyboardInput_Loop
		clearBall
		mov ax, bar.Speed
		add ball.CoordX, ax
		
	jmp keyboardInput_Loop
	
	keyboardInputExit:
ret
keyboardInput endp
;---------------------------------------------------------------------------------------------
drawBar proc uses ax bx cx dx si di
mov cx, bar.CoordX ;inital x
mov dx, bar.CoordY ;inital y
mov bh, 0; page number

mov si, bar.Width_

barLoop:
	mov di, bar.Length_
	mov cx, bar.CoordX
	barNestedLoop:
		call drawPixel
		inc cx
		
	dec di
	cmp di, 0
	jne barNestedLoop
	
	inc dx
dec si
cmp si, 0
jne barLoop
ret
drawBar endp

;---------------------------------------------------------------------------------------------
drawPixel PROC
	mov ah, 0ch
	int 10h
ret
drawPixel endp
;---------------------------------------------------------------------------------------------
moveBall PROC uses ax 
	cmp isBallLaunched, 0
	je moveBallExit
	
	;moving the ball in x-axis
	mov ax, ball.SpeedX
	add ball.CoordX, ax
	
		;moving the ball in y-axis
	mov ax, ball.SpeedY
	add ball.CoordY, ax
	
	;if hit the left wall
	cmp ball.CoordX, 0
	jle reverseSpeedX
	
	;if hit the right wall
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, windowsLength
	jge reverseSpeedX
	

	
	;if hit the upper wall
	cmp ball.CoordY, 0
	jle reverseSpeedY
	
	;if hit the lower wall
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, windowsWidth
	jge youDied
	
	;checking ball's collision with bar
	
	mov ax, bar.CoordX
	add ax, bar.Length_
	cmp ball.CoordX, ax
	jg moveBallExit
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, bar.CoordX
	jl moveBallExit
	
	mov ax, bar.CoordY
	add ax, bar.Width_
	cmp ball.CoordY, ax
	jg moveBallExit
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, bar.CoordY
	jl moveBallExit
	; if collides, reverseSpeedY
	mov beepFreq, 400
	call beepSound
	jmp reverseSpeedY
	
	;if no collision occurs, simply return
	moveBallExit:
	ret 
	
	;reversing direction after collision
	reverseSpeedY:
	neg ball.SpeedY
	ret
	
	reverseSpeedX:
	neg ball.SpeedX
	ret
	
	youDied:
	dec player.Lives
	attachBallToBar
	ret
	
	
moveBall endp

;---------------------------------------------------------------------------------------------
drawBricks proc uses ax bx cx dx si di
	local brickLoopVar:word

	mov brickLoopVar, 20
	mov bh, 0; page number
	mov si, 0
brickLoop_1:
		
		mov al, brick[si].Color
		mov cx, brick[si].CoordX ;inital x
		mov dx, brick[si].CoordY ;inital y
		mov brickLoopVar, 20
		brickLoop_2:
			mov di, brickLength
			mov cx, brick[si].CoordX
			brickLoop_3:
				call drawPixel
				inc cx
				
			dec di
			cmp di, 0
			jne brickLoop_3
			
			inc dx
		dec brickLoopVar
		cmp brickLoopVar, 0
		jne brickLoop_2

add si, type BrickStruct
cmp si, type BrickStruct * 15
jb brickLoop_1
ret
drawBricks ENDP

;---------------------------------------------------------------------------------------------
brickCollision proc uses ax bx cx dx di si
	; ball.x < brick.x +brickLength
	; ball.x + ballLength > brick.x
	; ball.y < brick.y +brickWidth
	; ball.y + ballWidth > brick.y 
	local collisionVar:word, brickLoopVar:word
	
	mov si, 0
	mov di, 0
	mov collisionVar, 0
	.while(collisionVar < 15)
	
	mov ax, brick[si].CoordX
	add ax, brickLength
	cmp ball.CoordX, ax
	jg collisionSkip
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, brick[si].CoordX
	jl collisionSkip
	
	mov ax, brick[si].CoordY
	add ax, brickWidth
	cmp ball.CoordY, ax
	jg collisionSkip
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, brick[si].CoordY
	jl collisionSkip
	
	;if all above 4 conditions are passed, it means the ball has collided
	;checking if the block has already been cleared
	
	;checking if the collided brick is a fixed brick
	.if(gameLevel == 3)
		mov ax, brick[si].CoordX
		mov bx, brick[si].CoordY
		mov di, 0
		.while(di < type BrickStruct * 5)
			.if(ax == fixedBricks[di].CoordX) && (bx == fixedBricks[di].CoordY) 
				jmp fixedBrickSkip
			.endif
		add di, type BrickStruct
		.endw
	.endif
	
	;stuff that happens after collision
	dec brick[si].Health
	.if(brick[si].Health == 0)
		clearBrick si
		inc bricksCount
		
		;changing the bricks coordinates so the ball wont collide with them once they've been broken
		neg brick[si].CoordX
		neg brick[si].CoordY
		mov brick[si].Color, 0
	.endif
	
	;generating beepsound
	mov beepFreq, 0e1fh
	call beepSound
	; increasing the player score
	inc player.Score
	;---
	fixedBrickSkip:
	;---------reflection off of a brick
	neg ball.SpeedY
	ret
	
	collisionSkip:
add si, type BrickStruct
inc collisionVar
.endw

ret
brickCollision endp
;--------------
beepSound proc uses ax bx cx dx
	mov al, 182        
	out 43h, al        
	mov ax, beepFreq        
						   
	out 42h, al        
	mov al, ah         
	out 42h, al 
	in al, 61h        
						   
	or al, 00000011b  
	out 61h, al        
	mov bx, 2          
delay_1:
	mov cx, 65535
delay_2:
	dec cx
	jne delay_2
	dec bx
	jne delay_1
	in al, 61h        
						   
	and al, 11111100b  
	out 61h, al        
ret
beepSound endp
;--------------------
specialBrick proc
	
ret
specialBrick endp
;---------------------------------------------------------------------------------------------
drawBall proc uses ax bx cx dx si di
	mov cx, ball.CoordX ;inital x
	mov dx, ball.CoordY ;inital y
	mov bh, 0; page number

	mov si, ballSize

	ballLoop:
		mov di, ballSize
		mov cx, ball.CoordX
		ballNestedLoop:
			call drawPixel
			inc cx
			
		dec di
		cmp di, 0
		jne ballNestedLoop
		
		inc dx
	dec si
	cmp si, 0
	jne ballLoop
ret
drawBall endp
;------------------------
updateStats Proc uses ax bx cx dx
	OUTP:
	MOV AX, statsVar
	MOV DX,0

	HERE:
	CMP AX,0
	JE DISP

	MOV BL,10
	DIV BL

	MOV DL,AH
	MOV DH,0
	PUSH DX
	MOV CL,AL
	MOV CH,0
	MOV AX,CX
	INC COUNT
	JMP HERE

	DISP:
	CMP COUNT,0
	JBE EX2
	POP DX
	ADD DL,48
	MOV AH,02H
	INT 21H
	DEC COUNT
	JMP DISP
	Ex2:
ret
updateStats endp
;------

include img.inc

;------------ file functions
fetchStats proc
	mov mode, 0
	call openStatsFile
	
	mov ah,	3fh
	mov cx, 500 ; getting 500 chars from file
	mov dx,	offset buffer
	mov bx,	statsHandle
	int 21h
	mov bufferLen, ax
	mov bx, ax
	mov buffer[bx], '$'
	
	call closeStatsFile
ret
fetchStats endp
;---------------------------------------------------------------
saveStats PROC
	mov mode, 1
	call openStatsFile
	
	mov cx,0
	mov dx, 0
	mov ah,42h ; reaching end of file function
	mov al,2
	int 21h
	
	call savePlayerName
	call space
	call saveGameLevel
	call space
	call saveScore
	call comma
	
	call closeStatsFile
ret
saveStats endp
;---------------------------------------------------------------
openStatsFile proc
	mov ah,3dh 
	mov al, mode
	mov dx,offset statsFile 
	int 21h 
	mov statsHandle,ax 
ret
openStatsFile endp
;---------------------------------------------------------------
closeStatsFile proc
	mov ah, 3eh ;service to close file.
	mov bx, statsHandle
	int 21h
ret
closeStatsFile endp
;---------------------------------------------------------------
space PROC
	mov tempStr[0], 32;asci for space
	
	mov si, 0
	.while(si!=10)
		writeToFile 1, tempStr ; len and source
	inc si
	.endw
ret
space ENDP
;---------------------------------------------------------------
comma PROC
	mov tempStr[0], 44;asci for comma
	writeToFile 1, tempStr ; len and source
ret
comma ENDP
;---------------------------------------------------------------
saveScore proc
	local digits:word
	.if(player.Score<10)
		mov digits, 1
	.elseif (player.Score<100)
		mov digits, 2
	.else
		mov digits, 3
	.endif
	
	mov tempStr[0], '$'
	mov tempStr[1], '$'
	mov tempStr[2], '$'
	call numToString
	
	writeToFile digits, tempStr ; len and source
	
ret
saveScore endp
;---------------------------------------------------------------
saveGameLevel PROC
	mov ax, gameLevel
	add ax, 48
	mov tempStr[0], al

	writeToFile 1, tempStr ; len and source
ret
saveGameLevel ENDP
;---------------------------------------------------------------
savePlayerName PROC
	writeToFile player.nameLen, [player.igName]-1 ; len and source
ret
savePlayerName ENDP
;---------------------------------------------------------------
numToString proc uses ax bx 
	;local ten: word
	;mov ten, 10
	mov bx, 10
	
	;if score is below 10
	.if(player.Score<10)
		mov ax, player.Score
		add ax, 48
		mov tempStr[0], al
		ret
	.elseif (player.Score<100)
		mov ax, player.Score
		div bl
		add al, 48
		add ah, 48
		mov tempStr[0], al
		mov tempStr[1], ah
		ret
	.else
		mov ax, player.Score
		div bl
		add ah, 48
		mov tempStr[2],ah 
		mov ah, 0
		div bl
		add al, 48
		add ah, 48
		mov tempStr[0], al
		mov tempStr[1], ah
		ret
	.endif
ret
numToString endp
;---------------------------------------------------------------
end