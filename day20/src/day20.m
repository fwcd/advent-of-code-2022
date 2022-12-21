#import <Foundation/Foundation.h>

NSMutableArray *readInput() {
  NSString *raw = [NSString stringWithContentsOfFile:@"resources/demo.txt" encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [raw componentsSeparatedByString:@"\n"];
  NSMutableArray *input = [[NSMutableArray alloc] init];
  for (NSString *line in lines) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed length] > 0) {
      [input addObject:[NSNumber numberWithInt:[trimmed intValue]]];
    }
  }
  return input;
}

int main(void) {
  @autoreleasepool {
    NSMutableArray *input = readInput();
    NSLog(@"%@", input);
    return 0;
  }
}
