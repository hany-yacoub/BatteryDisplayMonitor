.text
.global  set_batt_from_ports
        
set_batt_from_ports: 

        #*batt is in %rdi, returns %rax
        #used regs: rsi/si, rdx/dl, rdi(arg1), r8/r8w/r8b, rax(ret) 

        movw    BATT_VOLTAGE_PORT(%rip), %si # %rsi/si = BATT_VOLTAGE_PORT 
        movb    BATT_STATUS_PORT(%rip), %dl # %rdx/dl = BATT_STATUS_PORT   
        
        cmpw    $0, %si #if BATT_VOLTAGE_PORT is less than 0, jumps to .ERROR
        jl      .ERROR
        sarw    $1, %si #divides BATT_VOLTAGE_PORT / 2, still in %si
        movw    %si, 0(%rdi) #moves BATT_VOLTAGE_PORT / 2 to batt->mlvolts

        cmpw    $3000, 0(%rdi) #if batt->mlvolts < 3000 jumps to .ZEROP
        jl      .ZEROP

        cmpw    $3800, 0(%rdi) #if batt->mlvolts > 3800 jumps to .100P
        jg      .100P

        #Else
        movw    0(%rdi), %r8w #copies batt->mlvolts to %r8w
        subw    $3000, %r8w #batt->mlvolts - 3000
        sarw    $3, %r8w #batt->mlvolts / 8
        movb    %r8b, 2(%rdi) #batt->percent = adjusted batt->mlvolts (only first byte)
        jmp     .CONTSNDBIT #Finishes if-else
        
    .ZEROP:
        movb    $0, 2(%rdi) #batt->percent = 0
        jmp     .CONTSNDBIT #Finishes if-else
    
    .100P:
        movb    $100, 2(%rdi) #batt->percent = 100

    .CONTSNDBIT: #2nd bit if else
        andb    $0b0100, %dl    #If BATT_STATUS_PORT twoth bit is set jump to PMODE
        jnz     .PMODE
        movb    $1, 3(%rdi) #Else batt->mode = 1, volt mode
        jmp     .ENDPORTS #Don't pmode

    .PMODE:
        movb    $2, 3(%rdi) #batt->mode = 2, percent mode

    .ENDPORTS:
        movq    $0, %rax #return 0
        ret

    .ERROR:
        movq    $1, %rax #return 1
        ret     

#Ints used for set_display_from_batt
.data
	
fstD:                        
        .int    0
sndD:                        
        .int    0
thdD:                        
        .int    0
fthD:                        
        .int    0
        
#masks array used for set_display_from_batt        
masks:                       
        .int 0b0111111            
        .int 0b0000110             
        .int 0b1011011            
        .int 0b1001111
        .int 0b1100110
        .int 0b1101101
        .int 0b1111101
        .int 0b0000111
        .int 0b1111111
        .int 0b1101111 

#data done, back to functions 
.text
.global  set_display_from_batt

set_display_from_batt:  #%rdi = (packed struct) batt, %rsi = *display
    
    movl    $0, (%rsi) # %rsi/display = 0

    movq    %rdi, %r8 #extract struct to r8
    sarq    $24, %r8  #access batt.mode in struct
    andq    $0xFF, %r8 #mask low bits
    cmpb    $1, %r8b #if batt.mode == 1
    je      .VOLT
    cmpb    $2, %r8b #if batt.mode == 2
    je      .PERCENT
    jmp     .DISPERROR #if batt.mode != 1 && batt.mode != 2

.PERCENT:
    movl    $1, %r9d # %r9d = mask (1<<22)
    sall    $22, %r9d 
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 22);

    movl    $1, %r9d # %r9d = mask (1<<21)
    sall    $21, %r9d 
    orl     %r9d, (%rsi) # *display = *display | (1 << 21);

    movl    $1, %r9d # %r9d = mask (1<<23)
    sall    $23, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 23);

    movq    %rdi, %r11 #extracts struct to r11
    sarq    $16, %r11 #access batt.percent
    andq    $0xFF, %r11 #mask low bits
    
    #fstD
    movl    %r11d, %eax #copies to eax for div
    movl    $100, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx
    movl    %eax, fstD(%rip) #fstD = batt.percent / 100

    #sndD
    movl    %r11d, %eax #copies to eax for div
    movl    $10, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx (/10)
    movl    $10, %r10d
    cqto
    idivl   %r10d # (/10)
    movl    %edx, sndD(%rip) #sndD = batt.percent / 10 % 10

   #thdD
    movl    %r11d, %eax #copies to eax for div
    movl    $10, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx (/10)
    movl    %edx, thdD(%rip) #thdD = batt.percent % 10

    jmp     .DIGITSTODISP

.VOLT:
    movl    $1, %r9d # %r9d = mask (1<<22)
    sall    $22, %r9d
    orl     %r9d, (%rsi) # *display = *display | (1 << 22);

    movl    $1, %r9d # %r9d = mask (1<<21)
    sall    $21, %r9d
    not     %r9d     
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 21);

    movl    $1, %r9d # %r9d = mask (1<<23)
    sall    $23, %r9d
    orl     %r9d, (%rsi) # *display = *display | (1 << 23);

    movq    %rdi, %r11 #extracts struct to r11, access mlvolts, no shift needed
    andq    $0xFFFF, %r11 #mask low 2 bytes (mlvolts)
    
    #fstD
    movl    %r11d, %eax #copies to eax for div
    movl    $1000, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx
    movl    %eax, fstD(%rip) #fstD = batt.mlvolts / 1000

    #sndD
    movl    %r11d, %eax #copies to eax for div
    movl    $100, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx (/100)
    movl    $10, %r10d
    cqto
    idivl   %r10d # (/10)
    movl    %edx, sndD(%rip) #sndD = batt.mlvolts / 100 % 10

    #thdD
    movl    %r11d, %eax #copies to eax for div
    movl    $10, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx (/10)
    movl    $10, %r10d
    cqto
    idivl   %r10d # (/10)
    movl    %edx, thdD(%rip) #thdD = batt.mlvolts / 10 % 10

    #fthD
    movl    %r11d, %eax #copies to eax for div
    movl    $10, %r10d
    cqto
    idivl   %r10d # %eax/ %r10d = %rax, rem in %edx (/10)
    movl    %edx, fthD(%rip) #fthD = batt.mlvolts % 10

    cmpl    $5, fthD(%rip) #If fthD >= 5, thdD++
    jge     .INCTHD
    jmp     .DIGITSTODISP #Else
    
    .INCTHD:
        incl     thdD(%rip)

.DIGITSTODISP: #batt.mode If-Else done

    #First digit if-else
    cmpb    $2, %r8b #if batt.mode != 2
    jnz     .NONZEROFST
    cmpl    $0, fstD(%rip)
    jnz     .NONZEROFST #if fstD != 0
    
    #ZEROFST
    movl    $0b0000000, %r9d # %r9d = mask (0b000000 << 14)
    sall    $14, %r9d
    orl     %r9d, (%rsi) # *display = *display | (0b000000 << 14);

    jmp     .DTD2 #Digits to disp 2nd digit

    .NONZEROFST: #Else
        movl    fstD(%rip), %eax
        leaq    masks(%rip), %r9 # %r9 = masks
        
        imull   $4, %eax #r10d = r9[fstD]
        addq    %rax, %r9
        movl    (%r9), %r10d

        sall    $14, %r10d
        orl     %r10d, (%rsi) # *display = *display | (masks[fstD] << 14);

.DTD2: #First digit if-else done, Second digit now

    #Second digit if-else
    cmpb    $2, %r8b #if batt.mode != 2
    jnz     .NONZEROSND
    cmpl    $0, fstD(%rip)
    jnz     .NONZEROSND #if fstD != 0
    cmpl    $0, sndD(%rip)
    jnz     .NONZEROSND #if sndD != 0
    
    #ZEROSND
    movl    $0b0000000, %r9d # %r9d = mask (0b000000 << 7)
    sall    $7, %r9d
    orl     %r9d, (%rsi) # *display = *display | (0b000000 << 7);

    jmp     .DTD3 #Digits to disp 2nd digit

    .NONZEROSND: #Else
        movl    sndD(%rip), %eax
        leaq    masks(%rip), %r9 # %r9 = masks
    
        imull   $4, %eax #r10d = r9[sndD]
        addq    %rax, %r9
        movl    (%r9), %r10d

        sall    $7, %r10d
        orl     %r10d, (%rsi) # *display = *display | (masks[sndD] << 7);
    

.DTD3: #Second digit if-else done

    #Third digit
    movl    thdD(%rip), %eax
    leaq    masks(%rip), %r9 # %r9 = masks
    
    imull   $4, %eax #r10d = r9[thdD]
    addq    %rax, %r9
    movl    (%r9), %r10d
   
    orl     %r10d, (%rsi) # *display = *display | (masks[thdD]);

#Battery icon if-elses
    movq    %rdi, %r11 #extracts struct to r11
    sarq    $16, %r11 #access batt.percent
    andq    $0xFF, %r11 #mask low bits, %r11 = batt.percent

    #If >= 5
    cmpb    $5, %r11b
    jge     .FIVE 
    #Else
    movl    $1, %r9d # %r9d = mask
    sall    $24, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 24);
    jmp     .FIVEDONE
    .FIVE:
        movl    $1, %r9d # %r9d
        sall    $24, %r9d
        orl     %r9d, (%rsi) # *display = *display | (1 << 24);
    .FIVEDONE:

    #If >= 30
    cmpb    $30, %r11b
    jge     .THIRTY
    #Else
    movl    $1, %r9d # %r9d = mask
    sall    $25, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 25);
    jmp     .THIRTYDONE
    .THIRTY:
        movl    $1, %r9d # %r9d
        sall    $25, %r9d
        orl     %r9d, (%rsi) # *display = *display | (1 << 25);
    .THIRTYDONE:

    #If >= 50
    cmpb    $50, %r11b
    jge     .FIFTY
    #Else
    movl    $1, %r9d # %r9d = mask
    sall    $26, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 26);
    jmp     .FIFTYDONE
    .FIFTY:
        movl    $1, %r9d # %r9d
        sall    $26, %r9d
        orl     %r9d, (%rsi) # *display = *display | (1 << 26);
    .FIFTYDONE:

    #If >= 70
    cmpb    $70, %r11b
    jge     .SEVENTY
    #Else
    movl    $1, %r9d # %r9d = mask
    sall    $27, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 27);
    jmp     .SEVENTYDONE
    .SEVENTY:
        movl    $1, %r9d # %r9d
        sall    $27, %r9d
        orl     %r9d, (%rsi) # *display = *display | (1 << 27);
    .SEVENTYDONE:

    #If >= 90
    cmpb    $90, %r11b
    jge     .NINETY  
    #Else
    movl    $1, %r9d # %r9d = mask
    sall    $28, %r9d
    not     %r9d
    andl    %r9d, (%rsi) # *display = *display & ~(1 << 28);
    jmp     .NINETYDONE
    .NINETY:
        movl    $1, %r9d # %r9d
        sall    $28, %r9d
        orl     %r9d, (%rsi) # *display = *display | (1 << 28);
    .NINETYDONE:              
        movq    $0, %rax #return 0
        ret 
    #Func done

.DISPERROR:
    movq    $1, %rax #return 1
    ret

.text
.global batt_update
        
batt_update: #no args
	subq    $8, %rsp #resize stack for func calls
    
    pushq   $0 #space for struct in memory
    movq    %rsp, %rdi #rdi = &batt1

    call    set_batt_from_ports #func returns in rax
    cmpq    $1, %rax
    popq    %rax
    je      .MAINERROR #if returns 1 error

    #Else
    movl    (%rdi), %edi #&batt1 to batt1
    pushq   $0 #created space for BATT_DISPLAY_PORT
    movq    %rsp, %rsi #%rsi = &BATT_DISPLAY_PORT
    call    set_display_from_batt #args set earlier -> (%rdi, $rsi)
    movl    (%rsi), %eax 
    movl    %eax, BATT_DISPLAY_PORT(%rip) #adjusted BATT_DISPLAY_PORT moved to global variable
    popq    %rax
    jmp     .END
     
    .MAINERROR:
       addq    $8, %rsp #resizes stack back to ret ptr
       movq    $1, %rax
       ret     
 
    .END:
        addq    $8, %rsp #resizes stack back to ret ptr
        movq    $0, %rax
        ret     
