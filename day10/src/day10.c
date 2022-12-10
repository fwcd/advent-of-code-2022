#include <stdio.h>
#include <stdlib.h>

#define BUFFER_SIZE 255

enum Op {
  NOOP, ADDX
};

struct Inst {
  enum Op op;
  int value;
};

struct Inst parse_inst(const char *raw) {
  switch (raw[0]) {
  case 'n': return (struct Inst) { .op = NOOP, .value = 0 };
  case 'a': return (struct Inst) { .op = ADDX, .value = atoi(raw + 5) };
  }
  fprintf(stderr, "Could not parse instruction '%s'\n", raw);
  exit(1);
}

int main(void) {
  FILE *fp = fopen("resources/demo.txt", "r");

  char buffer[BUFFER_SIZE];
  while (fgets(buffer, BUFFER_SIZE, fp)) {
    struct Inst inst = parse_inst(buffer);
    printf("%d %d\n", inst.op, inst.value);
  }

  fclose(fp);
  return 0;
}
