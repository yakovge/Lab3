/* util.h - Helper functions for Lab 3 (no stdlib) */
#ifndef UTIL_H
#define UTIL_H

/* Returns the length of a null-terminated string */
int strlen(const char *s);

/* Compares two strings, returns 0 if equal */
int strcmp(const char *s1, const char *s2);

/* System call wrapper - defined in start.s */
int system_call(int syscall_num, int arg1, int arg2, int arg3);

#endif
