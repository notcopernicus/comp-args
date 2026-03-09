.MODEL SMALL
.STACK 100h
.386

.DATA

totalCost        DW  0
itemCount        DW  0
discountApplied  DB  0

PRICE_CHIPS      DW  150
PRICE_SODA       DW  200
PRICE_CANDY      DW  100
PRICE_COOKIE     DW  125

msgTitle         DB  "CAMPUS SNACK SHOP", 0Dh, 0Ah, "$"
msgMenu          DB  "1) Add Items     2) Apply Discount", 0Dh, 0Ah
                 DB  "3) Print Receipt 4) Clear Cart", 0Dh, 0Ah
                 DB  "5) Exit", 0Dh, 0Ah
                 DB  "Choice: $"
msgBadChoice     DB  0Dh, 0Ah, "Invalid choice (1-5 only).", 0Dh, 0Ah, "$"

msgSnackMenu     DB  0Dh, 0Ah, "Select snack:", 0Dh, 0Ah
                 DB  "1) Chips   $1.50", 0Dh, 0Ah
                 DB  "2) Soda    $2.00", 0Dh, 0Ah
                 DB  "3) Candy   $1.00  (Buy 2 Get 1 Free!)", 0Dh, 0Ah
                 DB  "4) Cookie  $1.25", 0Dh, 0Ah
                 DB  "Choice: $"
msgQtyPrompt     DB  0Dh, 0Ah, "Quantity (1-9): $"
msgAdded         DB  0Dh, 0Ah, "Item(s) added.", 0Dh, 0Ah, "$"
msgBadSnack      DB  0Dh, 0Ah, "Invalid snack (1-4). Try again.", 0Dh, 0Ah, "$"
msgBadQty        DB  0Dh, 0Ah, "Quantity 1-9 only. Try again.", 0Dh, 0Ah, "$"

msgDiscApplied   DB  0Dh, 0Ah, "10% discount applied!", 0Dh, 0Ah, "$"
msgDiscAlready   DB  0Dh, 0Ah, "Discount already applied.", 0Dh, 0Ah, "$"
msgDiscTooLow    DB  0Dh, 0Ah, "Need at least 1000 cents ($10) to discount.", 0Dh, 0Ah, "$"

msgReceiptHdr    DB  0Dh, 0Ah, "--- RECEIPT ---", 0Dh, 0Ah, "$"
msgItems         DB  "Total items: $"
msgDiscYes       DB  "Discount: YES", 0Dh, 0Ah, "$"
msgDiscNo        DB  "Discount: NO", 0Dh, 0Ah, "$"
msgTotal         DB  "Final total: $"
msgCents         DB  " cents", 0Dh, 0Ah, "$"
msgCleared       DB  0Dh, 0Ah, "Cart cleared.", 0Dh, 0Ah, "$"

.CODE

MAIN PROC
    MOV  AX, @DATA
    MOV  DS, AX

MainLoop:
    CALL ShowMenu
    CALL ReadInt

    CMP  AX, 1
    JE   DoAdd          
    CMP  AX, 2
    JE   DoDiscount
    CMP  AX, 3
    JE   DoReceipt
    CMP  AX, 4
    JE   DoClear
    CMP  AX, 5
    JE   DoExit

    MOV  DX, OFFSET msgBadChoice
    CALL PrintString
    JMP  MainLoop

DoAdd:
    CALL AddItems
    JMP  MainLoop

DoDiscount:
    CALL ApplyDiscount
    JMP  MainLoop

DoReceipt:
    CALL PrintReceipt
    JMP  MainLoop

DoClear:
    CALL ClearCart
    JMP  MainLoop

DoExit:
    MOV  AH, 4Ch
    INT  21h

MAIN ENDP

; ---------------------------------------------------
PrintString PROC
    MOV  AH, 09h
    INT  21h
    RET
PrintString ENDP

; ---------------------------------------------------
ReadInt PROC
ReadLoop:
    MOV  AH, 01h
    INT  21h
    SUB  AL, '0'
    MOV  AH, 0
    CMP  AL, 0
    JB   ReadLoop
    CMP  AL, 9
    JA   ReadLoop
    RET
ReadInt ENDP

; ---------------------------------------------------
ShowMenu PROC
    MOV  DX, OFFSET msgTitle
    CALL PrintString
    MOV  DX, OFFSET msgMenu
    CALL PrintString
    RET
ShowMenu ENDP

; ---------------------------------------------------
AddItems PROC
SnackLoop:
    MOV  DX, OFFSET msgSnackMenu
    CALL PrintString
    CALL ReadInt
    MOV  BX, AX

    CMP  BX, 1
    JB   BadSnack
    CMP  BX, 4
    JA   BadSnack

QtyLoop:
    MOV  DX, OFFSET msgQtyPrompt
    CALL PrintString
    CALL ReadInt
    MOV  CX, AX

    CMP  CX, 1
    JB   BadQty
    CMP  CX, 9
    JA   BadQty

    ; FIX 2: Each Price label on its own line (TASM forbids code after label on same line)
    CMP  BX, 1
    JE   Price1
    CMP  BX, 2
    JE   Price2
    CMP  BX, 3
    JE   Price3
    MOV  SI, PRICE_COOKIE
    JMP  CalcCost

Price1:
    MOV  SI, PRICE_CHIPS
    JMP  CalcCost

Price2:
    MOV  SI, PRICE_SODA
    JMP  CalcCost

Price3:
    MOV  SI, PRICE_CANDY

CalcCost:
    PUSH BX             ; SAVE snack choice - DIV will destroy BX
    MOV  DI, CX         ; DI = quantity (safe register, untouched by DIV)

    CMP  BX, 3
    JNE  NoPromo
    ; Buy 2 Get 1 Free: subtract (qty DIV 3) free items from qty
    MOV  AX, CX
    MOV  BX, 3
    XOR  DX, DX
    DIV  BX             ; AX = qty/3 (free items) - BX destroyed here, but saved on stack
    MOV  DI, CX
    SUB  DI, AX         ; DI = qty - free items (items to charge for)

NoPromo:
    POP  BX             ; RESTORE snack choice
    ; Cost = price (SI) * charged qty (DI)
    MOV  AX, SI
    MOV  DX, DI         ; move qty into DX for MUL (MUL cannot use DI directly in 16-bit)
    MUL  DX             ; AX = price * qty
    ADD  AX, totalCost
    MOV  totalCost, AX

    ADD  CX, itemCount
    MOV  itemCount, CX

    MOV  DX, OFFSET msgAdded
    CALL PrintString
    RET

BadSnack:
    MOV  DX, OFFSET msgBadSnack
    CALL PrintString
    JMP  SnackLoop

BadQty:
    MOV  DX, OFFSET msgBadQty
    CALL PrintString
    JMP  QtyLoop

AddItems ENDP

; ---------------------------------------------------
ApplyDiscount PROC
    CMP  discountApplied, 1
    JE   Already
    CMP  totalCost, 1000
    JB   TooLow
    MOV  AX, totalCost
    MOV  BX, 10
    XOR  DX, DX
    DIV  BX
    SUB  totalCost, AX
    MOV  discountApplied, 1
    MOV  DX, OFFSET msgDiscApplied
    CALL PrintString
    RET

Already:
    MOV  DX, OFFSET msgDiscAlready
    CALL PrintString
    RET

TooLow:
    MOV  DX, OFFSET msgDiscTooLow
    CALL PrintString
    RET

ApplyDiscount ENDP      ; FIX 4: This ENDP was completely missing

; ---------------------------------------------------
PrintReceipt PROC
    MOV  DX, OFFSET msgReceiptHdr
    CALL PrintString

    MOV  DX, OFFSET msgItems
    CALL PrintString
    MOV  AX, itemCount
    CALL PrintNum

    CMP  discountApplied, 1
    JE   ShowYes
    MOV  DX, OFFSET msgDiscNo
    CALL PrintString
    JMP  ShowTotal
ShowYes:
    MOV  DX, OFFSET msgDiscYes
    CALL PrintString

ShowTotal:
    MOV  DX, OFFSET msgTotal
    CALL PrintString
    MOV  AX, totalCost
    CALL PrintNum
    MOV  DX, OFFSET msgCents
    CALL PrintString
    RET
PrintReceipt ENDP

; ---------------------------------------------------
ClearCart PROC
    MOV  totalCost, 0
    MOV  itemCount, 0
    MOV  discountApplied, 0
    MOV  DX, OFFSET msgCleared
    CALL PrintString
    RET
ClearCart ENDP

; ---------------------------------------------------
; PrintNum: prints value in AX as decimal digits
PrintNum PROC
    MOV  BX, 10
    MOV  CX, 0
DivLoop:
    XOR  DX, DX
    DIV  BX
    PUSH DX
    INC  CX
    CMP  AX, 0
    JNE  DivLoop
PrintLoop:
    POP  DX
    ADD  DL, '0'
    MOV  AH, 02h
    INT  21h
    LOOP PrintLoop
    RET
PrintNum ENDP

END MAIN