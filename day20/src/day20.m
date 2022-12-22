#import <Foundation/Foundation.h>

NSMutableArray<NSNumber *> *readInput(NSString *filePath) {
  NSString *raw = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
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

NSMutableArray *permuted(NSArray *array, NSArray<NSNumber *> * permutation) {
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

long mod(long n, long m) {
  return (n % m + m) % m;
}

struct MixResult {
  NSArray<NSNumber *> *permutation;
  NSArray<NSNumber *> *inversePermutation;
};

struct MixResult mix(NSArray<NSNumber *> *moves, int n) {
  // Track permutation and inverse permutation separately. This is to
  // avoid computing the inverse permutation in every iteration (resulting in O(n^2)).
  // This way we only have O(n * max abs(delta)).
  NSMutableArray<NSNumber *> *permutation = range(n);
  NSMutableArray<NSNumber *> *inversePermutation = range(n);

  for (int i = 0; i < n; i++) {
    int startIndex = [permutation[i] intValue];
    int move = [moves[i] intValue];
    int endIndex = startIndex + move;

    // Deal with weird boundary wrapping
    endIndex = mod(endIndex - 1, n - 1) + 1;

    int delta = endIndex - startIndex;
    int step = delta >= 0 ? 1 : -1;

    // Compose the move onto our permutation.
    permutation[[inversePermutation[startIndex] intValue]] = [NSNumber numberWithInt:mod(endIndex, n)];
    for (int i = 1; i <= abs(delta); i++) {
      permutation[[inversePermutation[mod(startIndex + i * step, n)] intValue]] = [NSNumber numberWithInt:mod(startIndex + (i - 1) * step, n)];
    }

    // Compose the move onto our inverse permutation (this is the easier one since we can perform
    // the move directly on the array rather than needing the extra level of index mapping).
    NSNumber *tmp = inversePermutation[mod(startIndex, n)];
    for (int i = 0; i < abs(delta); i++) {
      inversePermutation[mod(startIndex + i * step, n)] = inversePermutation[mod(startIndex + (i + 1) * step, n)];
    }
    inversePermutation[endIndex] = tmp;
  }

  return (struct MixResult) {
    .permutation = permutation,
    .inversePermutation = inversePermutation
  };
}

int solve(NSArray<NSNumber *> *ciphertext, long factor, int rounds) {
  int n = [ciphertext count];
  int zeroIndex = [ciphertext indexOfObject:[NSNumber numberWithLong:0]];

  // Scale ciphertext by the given factor
  NSMutableArray<NSNumber *> *scaledCiphertext = [NSMutableArray arrayWithArray:ciphertext];
  for (int i = 0; i < n; i++) {
    scaledCiphertext[i] = [NSNumber numberWithLong:[ciphertext[i] longValue] * factor];
  }
  NSLog(@"Ciphertext: %@", [scaledCiphertext componentsJoinedByString:@" "]);

  // Perform the initial mixing to find the permutations
  struct MixResult result = mix(scaledCiphertext, n);
  NSArray<NSNumber *>* plaintext = scaledCiphertext;

  // Apply the permutation for every round
  for (int i = 0; i < rounds; i++) {
    plaintext = permuted(plaintext, result.permutation);
    zeroIndex = [result.permutation[zeroIndex] intValue];
    NSLog(@"Plaintext: %@ (zero index: %d)", [plaintext componentsJoinedByString:@" "], zeroIndex);
  }

  // Find the solution
  long solution = 0;
  for (int i = 1000; i <= 3000; i += 1000) {
    solution += [plaintext[mod(zeroIndex + i, n)] longValue];
  }

  return solution;
}

int main(void) {
  @autoreleasepool {
    NSArray<NSNumber *> *ciphertext = readInput(@"resources/demo.txt");

    NSLog(@"Part 1: %d", solve(ciphertext, 1, 1));
    NSLog(@"Part 2: %d", solve(ciphertext, 811589153, 10));

    return 0;
  }
}
