# Compiler & linker
ASM           = nasm
LIN           = ld
CC            = gcc

# Directory
SOURCE_FOLDER = src
OUTPUT_FOLDER = bin
ISO_NAME      = os2023

# For compiling all c files
SRC_FILES = $(shell find ${SOURCE_FOLDER} -name '*.c')
OBJ_FILES := $(patsubst $(SOURCE_FOLDER)/%.c,$(OUTPUT_FOLDER)/%.o,$(SRC_FILES))
DIR = $(filter-out src, $(patsubst $(SOURCE_FOLDER)/%, $(OUTPUT_FOLDER)/%, $(shell find $(SOURCE_FOLDER) -type d)))


# Flags
WARNING_CFLAG = -Wall -Wextra -Werror
DEBUG_CFLAG   = -ffreestanding -fshort-wchar -g
STRIP_CFLAG   = -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs
CFLAGS        = $(DEBUG_CFLAG) $(WARNING_CFLAG) $(STRIP_CFLAG) -m32 -c -I$(SOURCE_FOLDER)
AFLAGS        = -f elf32 -g -F dwarf
LFLAGS        = -T $(SOURCE_FOLDER)/linker.ld -melf_i386

# Genisoimage Flags
BOOT_FLAG	  = -b boot/grub/grub1 -no-emul-boot -boot-load-size 4
IO_FLAG		  = -A os -input-charset utf8 -quiet -boot-info-table -o ${OUTPUT_FOLDER}/${ISO_NAME}.iso $(OUTPUT_FOLDER)/iso

DISK_NAME	  = storage

run: all
	@qemu-system-i386 -s -S -drive file=storage.bin,format=raw,if=ide,index=0,media=disk -cdrom $(OUTPUT_FOLDER)/$(ISO_NAME).iso
all: build
build: iso
clean:
	rm -rf *.o *.iso $(OUTPUT_FOLDER)/kernel

disk:
	@qemu-img create -f raw $(OUTPUT_FOLDER)/$(DISK_NAME).bin 4M

${OUTPUT_FOLDER}/%.o: ${SOURCE_FOLDER}/%.c
	@$(CC) $(CFLAGS) -c -o $@ $<

dir:
	@for dir in $(DIR); do \
		if [ ! -d $$dir ]; then mkdir -p $$dir; fi \
	done

kernel: $(OBJ_FILES)
	@$(ASM) $(AFLAGS) $(SOURCE_FOLDER)/interrupt/intsetup.s -o ${OUTPUT_FOLDER}/intsetup.o
	@$(ASM) $(AFLAGS) $(SOURCE_FOLDER)/kernel_loader.s -o $(OUTPUT_FOLDER)/kernel_loader.o
	@$(LIN) $(LFLAGS) ${OBJ_FILES} ${OUTPUT_FOLDER}/intsetup.o $(OUTPUT_FOLDER)/kernel_loader.o -o $(OUTPUT_FOLDER)/kernel
	@echo Linking object files and generate elf32...
	@rm -rf ${DIR}
	@rm -f $(OUTPUT_FOLDER)/*.o

iso: dir kernel
	@mkdir -p $(OUTPUT_FOLDER)/iso/boot/grub
	@cp $(OUTPUT_FOLDER)/kernel     $(OUTPUT_FOLDER)/iso/boot/
	@cp other/grub1                 $(OUTPUT_FOLDER)/iso/boot/grub/
	@cp $(SOURCE_FOLDER)/menu.lst   $(OUTPUT_FOLDER)/iso/boot/grub/
	@genisoimage -R $(BOOT_FLAG) $(IO_FLAG)
	@rm -r $(OUTPUT_FOLDER)/iso/