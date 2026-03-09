# comp-args

Assembler used

MASM/TASM style 16-bit x86 assembly (.MODEL SMALL, INT 21h). Assemble with MASM or TASM and link with LINK/TLINK inside a DOS environment.

How to run (macOS)

1. Install DOSBox (https://www.dosbox.com/).
2. Put snack_shop.asm and assembler/linker tools into a folder, e.g. ~/dosproj/snackshop.
3. Start DOSBox and mount the folder:
4. Assemble and link (inside DOSBox):
  TASM/TLINK: tasm snack_shop.asm tlink snack_shop.obj snack_shop.exe
  MASM/LINK: masm snack_shop.asm link snack_shop.obj snack_shop.exe
5.Run:
snack_shop.exe
