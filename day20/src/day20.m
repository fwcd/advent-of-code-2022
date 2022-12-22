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
    int newIndex = [permutation[i] intValue];
    int delta = [ciphertext[i] intValue];
    int step = delta >= 0 ? 1 : -1;

    // Capture permutation[newIndex], permutation[newIndex + 1], ..., permutation[newIndex + delta]
    // (with indices taken mod n) before rewriting the permutation in-place.
    NSMutableArray<NSNumber *> *previousPermutationWindow = [[NSMutableArray alloc] init];
    for (int i = 0; i <= abs(delta); i++) {
      [previousPermutationWindow addObject:permutation[mod(newIndex + i * step, n)]];
    }

    // Now apply the move (with mapped indices).
    for (int i = abs(delta); i > 0; i--) {
      permutation[[previousPermutationWindow[i] intValue]] = [NSNumber numberWithInt:mod(newIndex + (i - 1) * step, n)];
    }
    permutation[[previousPermutationWindow[0] intValue]] = [NSNumber numberWithInt:mod(newIndex + delta, n)];

    NSLog(@"%d moves from new index %d:\t%@ (window: %@)", delta, newIndex, [permuted(ciphertext, permutation) componentsJoinedByString:@", "], [previousPermutationWindow componentsJoinedByString:@" "]);
  }

  // FIXME: Negative deltas behave strangely

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
