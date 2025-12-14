#ifndef DIRENT_H
#define DIRENT_H

struct linux_dirent64 {
    unsigned long long d_ino;
    unsigned long long d_off;
    unsigned short     d_reclen;
    unsigned char      d_type;
    char               d_name[1];
};

#define linux_dirent linux_dirent64

#define SYS_EXIT 1
#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_GETDENTS 220
#define STDIN 0
#define STDOUT 1
#define STDERR 2
#define O_RDONLY 0
#define ERROR_EXIT 0x55

#endif
