#define _XOPEN_SOURCE 700

#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>

#define INBUF_SIZE 8192

int main(void) {
  setlocale(LC_ALL, "C.UTF-8");

  static char in[INBUF_SIZE];
  size_t len = fread(in, 1, sizeof(in), stdin);

  mbstate_t st;
  memset(&st, 0, sizeof(st));

  size_t i = 0;
  while (i < len) {
    wchar_t wc;
    size_t n = mbrtowc(&wc, in + i, len - i, &st);

    if (n == (size_t)-1 || n == (size_t)-2) {
      /* invalid or incomplete UTF-8 byte: treat as one column, skip a byte */
      putchar(' ');
      i += 1;
      memset(&st, 0, sizeof(st));
      continue;
    }
    if (n == 0) {
      /* decoded NUL */
      i += 1;
      continue;
    }

    int w = wcwidth(wc);
    if (w == 2) {
      fputs("  ", stdout);
    } else if (w != 0) {
      /* width 1, or -1 (control/unprintable) -- perl's fallback rule
       * replaces any remaining character with exactly one space */
      putchar(' ');
    }
    /* w == 0 (combining marks and other zero-width codepoints): emit nothing */

    i += n;
  }

  return 0;
}
