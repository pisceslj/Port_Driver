        AREA Driver,CODE,READONLY
		ENTRY
;close interupt
        LDR R0, =0x4A000008    						;get the address of INTMSK     			
		LDR R1, =0x3FF         						;close all interupt
		STR R1, [R0]            					;set 0x3FF to 0x4A000008
;close WTD
        LDR R0, =0x53000000    						;get the address of WTCON
		MOV R1, #0             						;the 5th bit disable the WTD 
		STR R1, [R0]           						;set 0 to 0x53000000
;set timer,LOCKTIME => CLKDIVN  => MPLLCON => UPLLCON
        LDR R0, =0x4C000000    						;get the address of LOCKTIME
		LDR R1, =0xFFFFFFFF    						;set lock time
		STR R1, [R0]           
		
		LDR R0, =0x40000014                         ;get the address of CLKDIVN
		MOV R1, #7                                  ;FCLK:HCLK:PCLK  0=1:1:1   1=1:1:2    2=1:2:2  3=1:2:4=0 01 1 
		STR R1, [R0]                                ;                4=1:4:4   5=1:4:8    6=1:3:3  7=1:3:6=0 11 1 
		
;U_MDIV=56 , U_PDIV=2 , U_SDIV=2		
        LDR R0, =0x40000008    						;get the address of UPLLCON	
		LDR R1, =((56<<12)+(2<<4)+2)		        ;Fin=12MHz,UPLL = 48MHz   111000 0000 0010 0010
		STR R1, [R0]                                ;Configure UPLL:48MHz
		nop  ;Caution: After UPLL setting, at least 7-clocks delay must be inserted for setting hardware be completed.  
		nop  
		nop  
		nop  
		nop  
		nop  
		nop 
		
;M_MDIV=68 , M_PDIV=1 , M_SDIV=1
        LDR R0, =0x4C000004   						;get the address of MPLLCON
		LDR R1, =((68<<12)+(1<<4)+1)                ;Fin=10MHz , MPLL = 304MHz  1000100 0000 0001 0001
		STR R1, [R0]
		BL MEMORYINIT                               ;jump to memory initialise
		BL STACKINIT                                ;jump to stack  initialise
		BL UARTINIT                                 ;jump to uart   initialise

;initialise memory
MEMORYINIT
		ADR R0, BUSINIT
		LDR R1, =0x48000000              ;get the address of BWSCON
        LDR R2, =0x48000034 
INITLOOP                                                             
        LDR R3, [R0], #4                                                   
        STR R3, [R1], #4                                                   
        TEQ R2, R1                                                       
        BNE INITLOOP                  
		MOV PC,LR 		
BUSINIT
        DCD 0x22000000                             ;BWSCON                 
        DCD 0x00000700                             ;BANKCON0               
        DCD 0x00000700                             ;BANKCON1    
        DCD 0x00000700                             ;BANKCON2    
        DCD 0x00000700                  		   ;BANKCON3             
        DCD 0x00000700                             ;BANKCON4    
        DCD 0x00000700                             ;BANKCON5    
        DCD 0x00018005                             ;BANKCON6(SDRAM)    
        DCD 0x00018005                             ;BANKCON7(SRAM)    
        DCD 0x008e07a3                             ;REFRESH(SDRAM)                 
        DCD 0x000000b1                             ;BANKSIZE(138MB)                
        DCD 0x00000030                             ;MRSRB6                 
        DCD 0x00000030                             ;MRSRB7  
			
;stack initialise
STACKINIT
_STACKBASEADDR	EQU	0x33ff8000                                    
StackUse    EQU (_STACKBASEADDR-0x3800)
StackSvc	EQU	(_STACKBASEADDR-0x2800)
StackUnd	EQU	(_STACKBASEADDR-0x2400)
StackAbt	EQU	(_STACKBASEADDR-0x2000)
StackIRQ	EQU	(_STACKBASEADDR-0x1000)
StackFIQ	EQU	(_STACKBASEADDR-0x0000)

USERMODE	EQU 0x10                                            
FIQMODE		EQU	0x11
IRQMODE		EQU	0x12
SVCMODE		EQU	0x13
ABORTMODE	EQU	0x17
UNDEFMODE	EQU	0x1B
SYSMODE     EQU 0x1F
	
FIQMSK      EQU	0x40
IRQMSK      EQU 0x80	
;set undefstack	     
		MSR CPSR_c,#(UNDEFMODE+IRQMSK+FIQMSK)
        LDR SP, =StackUnd		
;set abortstack
        MSR CPSR_c,#(ABORTMODE+IRQMSK+FIQMSK)
        LDR SP, =StackAbt
;set irqstack
        MSR CPSR_c,#(IRQMODE+IRQMSK+FIQMSK)
        LDR SP, =StackIRQ
;set fiqstack
        MSR CPSR_c,#(FIQMODE+IRQMSK+FIQMSK)
        LDR SP, =StackFIQ	
;set svcstack
		MSR CPSR_c,#(SVCMODE+IRQMSK+FIQMSK)
        LDR SP, =StackSvc	
;set user and system stack
        MSR CPSR_c,#(SYSMODE+IRQMSK+FIQMSK)
        LDR SP, =StackUse
		
;uart initialise
UARTINIT 			
		LDR R0,=0x56000070	            ;GPHCON				
		LDR R1,[R0]                     ;set GPIO AS UART	
		ORR R1,R1,#0xa0	
		STR R1,[R0]		
		
		LDR R0,=0x56000078				;GPHDAT	
		MOV R1,#0						;initialse GPHDAT	
		STR R1,[R0]	
		
		LDR R0,=0x50000000	            ;ULCON0			    
		MOV R1,#3	                    ;IR_MODE,0x0  @[6] Parity_Mode,0x0 @[5:3] Num_of_stop_bit,0x0  @[2] Word_length,0b11 @[1:0]					
		STR R1,[R0]
		
		LDR R0,=0x50000004				;UCONO	   FCLK_Div,0 @[15:12]  Clk_select,0b00 @[11:10]
		MOV R1,#0x5	                    ;Tx_Int_Type, 1  @[9] Rx_Int_Type,0 @[8]  Rx_Timeout,0 @[7]    Rx_Error_Stat_Int,1 @[6]                                                                        
		STR R1,[R0]	                    ;Loopback_Mode,0 @[5] Break_Sig,0   @[4]  Tx_Mode,0b01 @[3:2]  Rx_Mode,0b01  @[1:0] 						
		
		LDR R0,=0x50000008	            ;UFCON0				
		MOV R1,#0                       ;Tx_FIFO_Trig_Level, 0b00 @[7:6]  Rx_FIFO_Trig_Level, 0b00 @[5:4]  Tx_FIFO_Reset, 0b0 @[2]  
		STR R1,[R0]                     ;Rx_FIFO_Reset,      0b0  @[1]    FIFO_Enable,        0b0  @[0]    NO FIFO MODE

		LDR R0,=0x5000000c		        ;UMCON0			
		MOV R1,#0							
		STR R1,[R0]
		
		LDR R0,=0x50000028	            ;UBRDIV0				
		MOV R1,#26					    ;PCLK=48M   UBRDIV = (int)(48M/115200/16) - 1 = 26 = 0x1A        
		STR R1,[R0]				
;to confirm that whether the UART is working
		LDR R0,=0x50000020                
		MOV R1,#98                        
		STR R1,[R0]
LOOP                                      
		LDR R0,=0x50000010
		LDR R1,[R0]                         		
        AND R1,R1,#1                       
		BEQ LOOP						  
		LDR R0,=0x50000024
		LDR R1,[R0]									
        LDR R0,=0x50000020
		STR R1,[R0]
		B LOOP

		END