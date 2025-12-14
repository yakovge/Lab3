/* dirent.h - Directory entry structure for Linux */
#ifndef DIRENT_H
#define DIRENT_H

/* Linux directory entry structure */
struct linux_dirent {
    unsigned long  d_ino;      /* Inode number */
    unsigned long  d_off;      /* Offset to next entry */
    unsigned short d_reclen;   /* Length of this entry */
    char           d_name[1];  /* Filename (variable length) */
};

/* System call numbers */
#define SYS_EXIT      1
#define SYS_READ      3
#define SYS_WRITE     4
#define SYS_OPEN      5
#define SYS_CLOSE     6
#define SYS_GETDENTS  141

/* File descriptor constants */
#define STDIN   0
#define STDOUT  1
#define STDERR  2

/* Open flags */
#define O_RDONLY  0
#define O_WRONLY  1
#define O_RDWR    2
#define O_CREAT   0x40
#define O_TRUNC   0x200
#define O_APPEND  0x400

/* Error exit code */
#define ERROR_EXIT 0x55

#endif
