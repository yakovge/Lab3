/* util.h - Helper functions for Lab 3 (no stdlib) */
#ifndef UTIL_H
#define UTIL_H

/* Returns the length of a null-terminated string */
int strlen(const char *s);

/* Compares two strings, returns 0 if equal */
int strcmp(const char *s1, const char *s2);

/* Compares first n characters of two strings */
int strncmp(const char *s1, const char *s2, int n);

/* System call wrapper - defined in start.s */
int system_call(int syscall_num, int arg1, int arg2, int arg3);

/* Assembly functions for virus attachment */
void infection(void);
void infector(const char *filename);

#endif
