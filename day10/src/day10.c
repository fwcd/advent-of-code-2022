#include <stdio.h>
#include <stdlib.h>

#define BUFFER_SIZE 255
#define CRT_WIDTH 40

enum Op {
  NOOP, ADDX
};

struct Inst {
  enum Op op;
  int value;
};

struct State {
  int x;
  int cycle;
  int score;
  int col;
};

void perform_cycle(struct State *state) {
  state->cycle += 1;
  if ((state->cycle - 20) % 40 == 0) {
    state->score += state->cycle * state->x;
  }
  if (abs(state->x - state->col) <= 1) {
    printf("#");
  } else {
    printf(" ");
  }
  state->col++;
  if (state->col >= CRT_WIDTH) {
    state->col = 0;
    printf("\n");
  }
}

void perform_inst(struct Inst inst, struct State *state) {
  switch (inst.op) {
  case NOOP:
    perform_cycle(state);
    break;
  case ADDX:
    for (int i = 0; i < 2; i++) {
      perform_cycle(state);
    }
    state->x += inst.value;
    break;
  }
}

struct Inst parse_inst(const char *raw) {
  switch (raw[0]) {
  case 'n': return (struct Inst) { .op = NOOP, .value = 0 };
  case 'a': return (struct Inst) { .op = ADDX, .value = atoi(raw + 5) };
  }
  fprintf(stderr, "Could not parse instruction '%s'\n", raw);
  exit(1);
}

int main(void) {
  FILE *fp = fopen("resources/input.txt", "r");
  char buffer[BUFFER_SIZE];
  struct State state = { .x = 1, .cycle = 0, .score = 0, .col = 0 };

  while (fgets(buffer, BUFFER_SIZE, fp)) {
    struct Inst inst = parse_inst(buffer);
    perform_inst(inst, &state);
  }

  fclose(fp);
  printf("Part 1: %d\n", state.score);
  return 0;
}
