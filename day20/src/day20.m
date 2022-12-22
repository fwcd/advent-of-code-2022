#import <Foundation/Foundation.h>

NSMutableArray<NSNumber *> *readInput() {
  NSString *raw = [NSString stringWithContentsOfFile:@"resources/demo.txt" encoding:NSUTF8StringEncoding error:nil];
  NSArray<NSString *> *lines = [raw componentsSeparatedByString:@"\n"];
  NSMutableArray<NSNumber *> *input = [[NSMutableArray alloc] init];
  for (NSString *line in lines) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed length] > 0) {
      [input addObject:[NSNumber numberWithInt:[trimmed intValue]]];
    }
  }
  return input;
}

NSMutableArray<NSNumber *> *range(int n) {
  NSMutableArray<NSNumber *> *result = [[NSMutableArray alloc] init];
  for (int i = 0; i < n; i++) {
    [result addObject:[NSNumber numberWithInt:i]];
  }
  return result;
}

void swap(NSMutableArray *array, int i, int j) {
  id tmp = array[i];
  array[i] = array[j];
  array[j] = tmp;
}

NSMutableArray *permuted(NSMutableArray *array, NSArray<NSNumber *> * permutation) {
  NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithArray:array];
  for (int i = 0; i < [permutation count]; i++) {
    result[[permutation[i] intValue]] = array[i];
  }
  return result;
}

NSMutableArray<NSNumber *> *inverse(NSArray<NSNumber *> *permutation) {
  NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithArray:permutation];
  for (int i = 0; i < [permutation count]; i++) {
    result[[permutation[i] intValue]] = [NSNumber numberWithInt:i];
  }
  return result;
}

int mod(int n, int m) {
  return (n % m + m) % m;
}

NSMutableArray<NSNumber *> *mix(NSMutableArray<NSNumber *> *ciphertext) {
  NSMutableArray<NSNumber *> *permutation = range([ciphertext count]);
  int n = [ciphertext count];

  for (int i = 0; i < n; i++) {
    int startIndex = [permutation[i] intValue];
    int move = [ciphertext[i] intValue];
    int endIndex = startIndex + move;

    // Deal with weird boundary wrapping
    if (move < 0) {
      endIndex = mod(endIndex, n - 1);
    } else {
      endIndex = mod(endIndex - 1, n - 1) + 1;
    }

    int delta = endIndex - startIndex;
    int step = delta >= 0 ? 1 : -1;

    // Capture permutation[newIndex], permutation[newIndex + 1], ..., permutation[newIndex + delta]
    // (with indices taken mod n) before rewriting the permutation in-place.
    NSMutableArray<NSNumber *> *previousPermutationWindow = [[NSMutableArray alloc] init];
    for (int i = 0; i <= abs(delta); i++) {
      [previousPermutationWindow addObject:permutation[mod(startIndex + i * step, n)]];
    }

    // DEBUG
    NSArray *before = permuted(ciphertext, permutation);

    // Now apply the move (with mapped indices).
    permutation[[previousPermutationWindow[0] intValue]] = [NSNumber numberWithInt:mod(startIndex + delta, n)];
    // DEBUG
    NSLog(@"delta = %d, endIndex = %d", delta, endIndex);
    NSLog(@"%d + %d = %d (mod %d)", startIndex, delta, mod(startIndex + delta, n), n);
    for (int i = 1; i <= abs(delta); i++) {
      int newI = mod(startIndex + (i - 1) * step, n);
      NSLog(@"%d + (%d - 1) * %d = %d (mod %d)", startIndex, i, step, newI, n);
      permutation[[previousPermutationWindow[i] intValue]] = [NSNumber numberWithInt:newI];
    }

    // DEBUG
    NSArray *current = permuted(ciphertext, permutation);
    NSLog(@"%d moves between %@ and %@ (from %d to %d):\t%@ (window: %@) \t-> permutation: %@", move, before[endIndex], before[endIndex + 1], startIndex, endIndex, [current componentsJoinedByString:@", "], [previousPermutationWindow componentsJoinedByString:@" "], [permutation componentsJoinedByString:@" "]);
    NSLog(@"\n");
  }

  return permuted(ciphertext, permutation);
}

int main(void) {
  @autoreleasepool {
    NSMutableArray<NSNumber *> *ciphertext = readInput();
    NSArray <NSNumber *>* plaintext = mix(ciphertext);
    NSLog(@"%@", [plaintext componentsJoinedByString:@" "]);
    return 0;
  }
}
