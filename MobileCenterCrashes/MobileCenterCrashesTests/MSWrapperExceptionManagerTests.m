#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MSCrashes.h"
#import "MSErrorReport.h"
#import "MSException.h"
#import "MSWrapperException.h"
#import "MSWrapperExceptionManagerInternal.h"

@interface MSWrapperExceptionManagerTests : XCTestCase
@end

@implementation MSWrapperExceptionManagerTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  [MSWrapperExceptionManager deleteAllWrapperExceptions];
}

#pragma mark - Helper

- (MSException*) getModelException {
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData*) getData {
  NSString *string = @"some string";
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  return data;
}

- (MSWrapperException*) getWrapperException {
  MSWrapperException *wrapperException = [[MSWrapperException alloc] init];
  wrapperException.modelException = [self getModelException];
  wrapperException.exceptionData = [self getData];
  return wrapperException;
}

- (NSString*)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString*)uuidStringRef;
}

#pragma mark - Test

- (void) testSaveCorrelateAndLoadWrapperExceptionWorks {
  MSWrapperException *wrapperException = [self getWrapperException];
  NSUInteger crashProcessId = 3;
  wrapperException.processId = [NSNumber numberWithUnsignedInteger:crashProcessId];
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  NSMutableArray *mockReports = [NSMutableArray new];
  for (int i = 0; i < 5; ++i) {
    id reportMock = OCMPartialMock([MSErrorReport new]);
    OCMStub([reportMock appProcessIdentifier]).andReturn(i);
    NSString* fakeUUIDString = [NSString stringWithFormat:@"%i", i];
    OCMStub([reportMock incidentIdentifier]).andReturn(fakeUUIDString);
    [mockReports addObject:reportMock];
  }
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithUUID:[NSString stringWithFormat:@"%i", (int)crashProcessId]];

  // Test that the loaded exception is not nil.
  XCTAssertNotNil(loadedException);

  // Test that the exceptions are the same.
  assertThat(loadedException.processId, equalTo(wrapperException.processId));
  assertThat(loadedException.exceptionData, equalTo(wrapperException.exceptionData));
  assertThat(loadedException.modelException, equalTo(wrapperException.modelException));

  // The exception field.
  assertThat(loadedException.modelException.type, equalTo(wrapperException.modelException.type));
  assertThat(loadedException.modelException.message, equalTo(wrapperException.modelException.message));
  assertThat(loadedException.modelException.wrapperSdkName, equalTo(wrapperException.modelException.wrapperSdkName));
}

@end
