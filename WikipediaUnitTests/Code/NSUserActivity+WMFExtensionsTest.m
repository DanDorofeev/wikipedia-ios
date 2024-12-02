#import <XCTest/XCTest.h>
#import "NSUserActivity+WMFExtensions.h"

@interface NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test : XCTestCase
@end

@implementation NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test

- (void)testURLWithoutWikipediaSchemeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testInvalidArticleURLReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testArticleURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/wiki/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString, @"https://en.wikipedia.org/wiki/Foo");
}

- (void)testExploreURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://explore"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeExplore);
}

- (void)testHistoryURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://history"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeHistory);
}

- (void)testSavedURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://saved"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeSavedPages);
}

- (void)testSearchURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/w/index.php?search=dog"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString,
                          @"https://en.wikipedia.org/w/index.php?search=dog&title=Special:Search&fulltext=1");
}

- (void)testNamedPlaceURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace?locationName=Amsterdam&latitude=52.3547498&longitude=4.8339215"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeNamedPlace);
    XCTAssertEqualObjects(activity.userInfo, (@{@"WMFPage": @"NamedPlace",
                                                @"WMFLatitude": @"52.3547498",
                                                @"WMFLongitude": @"4.8339215",
                                                @"WMFLocationName": @"Amsterdam"}));
}

- (void)testNamedPlaceURLWithoutLatitudeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace?locationName=Amsterdam&longitude=12.523785"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testNamedPlaceURLWithoutLongitudeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace?locationName=Amsterdam&latitude=52.3547498"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testNamedPlaceURLWithoutLatitudeAndLongitudeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace?locationName=Amsterdam"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testNamedPlaceURLWithoutNameAndLatitudeAndLongitudeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testNamedPlaceURLWithoutNameReturnsActivityWithoutLocationName {
    NSURL *url = [NSURL URLWithString:@"wikipedia://namedPlace?latitude=52.3547498&longitude=4.8339215"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeNamedPlace);
    XCTAssertEqualObjects(activity.userInfo, (@{@"WMFPage": @"NamedPlace",
                                                @"WMFLatitude": @"52.3547498",
                                                @"WMFLongitude": @"4.8339215"}));
}

@end
