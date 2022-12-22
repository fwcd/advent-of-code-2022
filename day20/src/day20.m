#import <Foundation/Foundation.h>
#include <assert.h>

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

NSMutableArray<NSNumber *> *inverted(NSArray<NSNumber *> *permutation) {
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
  // Track permutation and inverse permutation separately. This is to
  // avoid computing the inverse permutation in every iteration (resulting in O(n^2)).
  // This way we only have O(n * max abs(delta)).
  NSMutableArray<NSNumber *> *permutation = range([ciphertext count]);
  NSMutableArray<NSNumber *> *inversePermutation = range([ciphertext count]);

  int n = [ciphertext count];

  for (int i = 0; i < n; i++) {
    int startIndex = [permutation[i] intValue];
    int move = [ciphertext[i] intValue];
    int endIndex = startIndex + move;

    // Deal with weird boundary wrapping
    endIndex = mod(endIndex - 1, n - 1) + 1;

    int delta = endIndex - startIndex;
    int step = delta >= 0 ? 1 : -1;

    // DEBUG
    NSArray *before = permuted(ciphertext, permutation);

    // Compose the move onto our permutation.
    permutation[[inversePermutation[startIndex] intValue]] = [NSNumber numberWithInt:mod(endIndex, n)];
    // DEBUG
    NSLog(@"delta = %d, endIndex = %d", delta, endIndex);
    NSLog(@"%d + %d = %d (mod %d)", startIndex, delta, mod(startIndex + delta, n), n);
    for (int i = 1; i <= abs(delta); i++) {
      int newI = mod(startIndex + (i - 1) * step, n);
      // DEBUG
      NSLog(@"%d + (%d - 1) * %d = %d (mod %d)", startIndex, i, step, newI, n);
      permutation[[inversePermutation[mod(startIndex + i * step, n)] intValue]] = [NSNumber numberWithInt:newI];
    }

    // Compose the move onto our inverse permutation (this is the easier one since we can perform
    // the move directly on the array rather than needing the extra level of index mapping).
    NSNumber *tmp = inversePermutation[mod(startIndex, n)];
    for (int i = 0; i < abs(delta); i++) {
      inversePermutation[mod(startIndex + i * step, n)] = inversePermutation[mod(startIndex + (i + 1) * step, n)];
    }
    inversePermutation[endIndex] = tmp;

    // DEBUG
    NSArray *current = permuted(ciphertext, permutation);
    NSLog(@"%d moves between %@ and %@ (from %d to %d):\t%@\t-> permutation: %@, inv: %@", move, before[mod(endIndex, n)], before[mod(endIndex + 1, n)], startIndex, endIndex, [current componentsJoinedByString:@", "], [permutation componentsJoinedByString:@" "], [inversePermutation componentsJoinedByString:@" "]);
    NSLog(@"\n");

    assert([inversePermutation isEqualToArray:inverted(permutation)]);
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
