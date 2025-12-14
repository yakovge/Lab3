/* main.c - Task 2: Directory listing and virus attachment */
#include "util.h"
#include "dirent.h"

#define BUF_SIZE 8192

/* Buffer for directory entries */
char buf[BUF_SIZE];

/* Messages */
char virus_msg[] = " VIRUS ATTACHED\n";
char newline[] = "\n";
char dot_dir[] = ".";
char err_open[] = "Error opening directory\n";
char err_getdents[] = "Error reading directory\n";

int main(int argc, char **argv) {
    int fd;
    int nread;
    int pos;
    struct linux_dirent *d;
    char *prefix;
    int prefix_len;
    int attach_mode;
    int i;

    prefix = 0;
    prefix_len = 0;
    attach_mode = 0;

    /* Parse arguments for -a{prefix} */
    for (i = 1; i < argc; i++) {
        if (argv[i][0] == '-' && argv[i][1] == 'a') {
            prefix = argv[i] + 2;
            prefix_len = strlen(prefix);
            attach_mode = 1;
        }
    }

    /* Open current directory */
    fd = system_call(SYS_OPEN, (int)dot_dir, O_RDONLY, 0);
    if (fd < 0) {
        system_call(SYS_WRITE, STDERR, (int)err_open, strlen(err_open));
        system_call(SYS_EXIT, ERROR_EXIT, 0, 0);
    }

    /* Read directory entries */
    nread = system_call(SYS_GETDENTS, fd, (int)buf, BUF_SIZE);
    if (nread < 0) {
        system_call(SYS_WRITE, STDERR, (int)err_getdents, strlen(err_getdents));
        system_call(SYS_CLOSE, fd, 0, 0);
        system_call(SYS_EXIT, ERROR_EXIT, 0, 0);
    }

    /* Close directory */
    system_call(SYS_CLOSE, fd, 0, 0);

    /* Process each directory entry */
    pos = 0;
    while (pos < nread) {
        d = (struct linux_dirent *)(buf + pos);

        /* Check if prefix matches (if -a flag given) */
        if (attach_mode) {
            /* Only process files matching prefix */
            if (strncmp(d->d_name, prefix, prefix_len) == 0) {
                /* Print filename */
                system_call(SYS_WRITE, STDOUT, (int)d->d_name, strlen(d->d_name));

                /* Call infection and infector */
                infection();
                infector(d->d_name);

                /* Print VIRUS ATTACHED message */
                system_call(SYS_WRITE, STDOUT, (int)virus_msg, strlen(virus_msg));
            } else {
                /* Print filename without virus message */
                system_call(SYS_WRITE, STDOUT, (int)d->d_name, strlen(d->d_name));
                system_call(SYS_WRITE, STDOUT, (int)newline, 1);
            }
        } else {
            /* No -a flag: just print all filenames */
            system_call(SYS_WRITE, STDOUT, (int)d->d_name, strlen(d->d_name));
            system_call(SYS_WRITE, STDOUT, (int)newline, 1);
        }

        pos += d->d_reclen;
    }

    return 0;
}
