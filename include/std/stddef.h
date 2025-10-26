#pragma once

/* Types from compiler */
typedef __PTRDIFF_TYPE__ ptrdiff_t;
typedef __SIZE_TYPE__ size_t;
typedef __WCHAR_TYPE__ wchar_t;

/* NULL */
#ifdef __cplusplus
#define NULL 0
#else
#define NULL ((void *)0)
#endif
