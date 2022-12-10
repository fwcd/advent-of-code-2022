#include <stdio.h>

#define BUFFER_SIZE 255

int main(void) {
  FILE *fp = fopen("resources/demo.txt", "r");

  char buffer[BUFFER_SIZE];
  while (fgets(buffer, BUFFER_SIZE, fp)) {
    printf("%s", buffer);
  }

  fclose(fp);
  return 0;
}
