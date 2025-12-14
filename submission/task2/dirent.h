  #ifndef DIRENT_H
  #define DIRENT_H
  struct linux_dirent {
      unsigned long  d_ino;
      unsigned long  d_off;
      unsigned short d_reclen;
      char           d_name[1];
  };
  #define SYS_EXIT 1
  #define SYS_WRITE 4
  #define SYS_OPEN 5
  #define SYS_CLOSE 6
  #define SYS_GETDENTS 141
  #define STDIN 0
  #define STDOUT 1
  #define STDERR 2
  #define O_RDONLY 0
  #define ERROR_EXIT 0x55
  #endif
  EOF
nasm -f elf32 start.s -o start.o
