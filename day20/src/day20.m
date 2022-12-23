#import <Foundation/Foundation.h>

NSMutableArray<NSNumber *> *readInput(NSString *filePath) {
  NSString *raw = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
  NSArray<NSString *> *lines = [raw componentsSeparatedByString:@"\n"];
  NSMutableArray<NSNumber *> *input = [[NSMutableArray alloc] init];
  for (NSString *line in lines) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed length] > 0) {
      [input addObject:[NSNumber numberWithLong:[trimmed intValue]]];
    }
  }
  return input;
}

NSMutableArray<NSNumber *> *range(long n) {
  NSMutableArray<NSNumber *> *result = [[NSMutableArray alloc] init];
  for (long i = 0; i < n; i++) {
    [result addObject:[NSNumber numberWithLong:i]];
  }
  return result;
}

void swap(NSMutableArray *array, long i, long j) {
  id tmp = array[i];
  array[i] = array[j];
  array[j] = tmp;
}

NSMutableArray *permuted(NSArray *array, NSArray<NSNumber *> * permutation) {
  NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithArray:array];
  for (long i = 0; i < [permutation count]; i++) {
    result[[permutation[i] longValue]] = array[i];
  }
  return result;
}

long mod(long n, long m) {
  return (n % m + m) % m;
}

struct MixState {
  NSMutableArray<NSNumber *> *permutation;
  NSMutableArray<NSNumber *> *inversePermutation;
};

void mix(NSArray<NSNumber *> *moves, long n, struct MixState *state) {
  // We track permutation and inverse permutation separately. This is to
  // avoid computing the inverse permutation in every iteration (resulting in O(n^2)).
  // This way we only have O(n * max abs(delta)).

  for (long i = 0; i < n; i++) {
    long startIndex = [state->permutation[i] longValue];
    long move = [moves[i] longValue];
    long endIndex = mod(startIndex + move, n - 1);

    long delta = endIndex - startIndex;
    long absDelta = labs(delta);
    long step = delta >= 0 ? 1 : -1;

    // Compose the move onto our permutation.
    state->permutation[[state->inversePermutation[startIndex] longValue]] = [NSNumber numberWithLong:mod(endIndex, n)];
    for (long i = 1; i <= absDelta; i++) {
      state->permutation[[state->inversePermutation[mod(startIndex + i * step, n)] longValue]] = [NSNumber numberWithLong:mod(startIndex + (i - 1) * step, n)];
    }

    // Compose the move onto our inverse permutation (this is the easier one since we can perform
    // the move directly on the array rather than needing the extra level of index mapping).
    NSNumber *tmp = state->inversePermutation[mod(startIndex, n)];
    for (long i = 0; i < absDelta; i++) {
      state->inversePermutation[mod(startIndex + i * step, n)] = state->inversePermutation[mod(startIndex + (i + 1) * step, n)];
    }
    state->inversePermutation[endIndex] = tmp;
  }
}

long solve(NSArray<NSNumber *> *ciphertext, long key, long rounds) {
  long n = [ciphertext count];
  long zeroIndex = [ciphertext indexOfObject:[NSNumber numberWithLong:0]];

  // Scale ciphertext by the key
  NSMutableArray<NSNumber *> *moves = [NSMutableArray arrayWithArray:ciphertext];
  for (long i = 0; i < n; i++) {
    moves[i] = [NSNumber numberWithLong:[ciphertext[i] longValue] * key];
  }

  // Set up mix state
  struct MixState state = { .permutation = range(n), .inversePermutation = range(n) };
  NSArray<NSNumber *>* plaintext = moves;

  // Apply the permutation for every round
  for (long i = 0; i < rounds; i++) {
    mix(moves, n, &state);
  }

  // Find the solution
  long solution = 0;
  long zeroOffset = [state.permutation[zeroIndex] longValue];
  plaintext = permuted(moves, state.permutation);
  for (long i = 1000; i <= 3000; i += 1000) {
    solution += [plaintext[mod(zeroOffset + i, n)] longValue];
  }

  return solution;
}

int main(void) {
  @autoreleasepool {
    NSArray<NSNumber *> *ciphertext = readInput(@"resources/input.txt");

    NSLog(@"Part 1: %ld", solve(ciphertext, 1, 1));
    NSLog(@"Part 2: %ld", solve(ciphertext, 811589153, 10));

    return 0;
  }
}
