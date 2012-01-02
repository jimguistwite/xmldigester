//
// Copyright 2011-2012 James Guistwite
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "XmlDigesterTests.h"
#import "XmlDigester.h"
#import "XmlDigesterRule.h"



@interface Book : NSObject {
}

@property (strong)NSString*title;
@property (strong)NSString*author;
@property (strong)NSDate *publicationDate;
@property (strong)NSDate *purchaseDate;
@property long bookId;
@property (strong)NSMutableDictionary *metadata;

@end

@implementation Book
@synthesize title,author,publicationDate, bookId, purchaseDate, metadata;

- (void)addMeta: (NSMutableDictionary *)dict {
  if (!metadata) {
    metadata = [[NSMutableDictionary alloc] init];
  }
  [metadata setValue:[dict objectForKey:@"value"] forKey:[dict objectForKey:@"key"]];
}



@end


@interface Library : NSObject {
}

@property (strong)NSMutableArray *books;

@end

@implementation Library

@synthesize books;

- (id)init {
  if ((self = [super init])) {
    self.books = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addBook: (Book*)event {
  [books addObject:event];
}


@end




@implementation XmlDigesterTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testObjectCreation
{
  XmlDigester *digester = [[XmlDigester alloc] init];
  [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library$" className:@"Library"]];
  [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library/book$" className:@"Book"parentMethodName:@"addBook:"]];

  NSURL *file = [NSURL fileURLWithPath:@"library.xml"];
  NSXMLParser *p = [[NSXMLParser alloc ] initWithContentsOfURL:file];
  p.delegate = digester;
  BOOL stat = [p parse];
  if (stat) {
    if (!([digester.rootObject isKindOfClass:[Library class]])) {
      STFail(@"Unexpected object returned");
    }
    Library *lib = (Library*)digester.rootObject;
    if (lib.books.count == 0) {
      STFail(@"No Books");
    }
    else {
      Book *b = [lib.books objectAtIndex:0];
      if (!b.author) {
        STFail(@"Book author not assigned.");        
      }
    }
  }
  else {
    STFail(@"XML parse failed.");    
  }
}


- (void)testPropertiesAssignment
{
  XmlDigester *digester = [[XmlDigester alloc] init];
  //digester.enableLogging = true;
  [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library$" className:@"Library"]];
  [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library/book$" className:@"Book"parentMethodName:@"addBook:"]];

  // assign to bookId from xml id.
  [digester appendRule:[[XmlDigesterPropertyAssignmentRule alloc] initWithRegex:@".*/book/id$" propertyName:@"bookId"]];

  //purchase date is yyyy-MM-DD in XML, use "date" converter manually.
  [digester appendRule:[[XmlDigesterPropertyAssignmentRule alloc] initWithRegex:@".*/book/purchaseDate$" propertyName:@"purchaseDate" converter:@"date"]];

  // assign additional metadata.
  [digester appendRule:[[XmlDigesterCallSelectorRule alloc] initWithRegex:@".*/book/meta$" selectorName:                                                                   @"addMeta:"]];
  
  // assign other properties normally.
  [digester appendRule:[[XmlDigesterPropertiesAssignmentRule alloc] initWithRegex:@".*/book/[a-z]*$"]];



  
  NSURL *file = [NSURL fileURLWithPath:@"library2.xml"];
  NSXMLParser *p = [[NSXMLParser alloc ] initWithContentsOfURL:file];
  p.delegate = digester;
  BOOL stat = [p parse];
  if (stat) {
    if (!([digester.rootObject isKindOfClass:[Library class]])) {
      STFail(@"Unexpected object returned");
    }
    Library *lib = (Library*)digester.rootObject;
    if (lib.books.count == 0) {
      STFail(@"No Books");
    }
    else {
      Book *b = [lib.books objectAtIndex:0];
      if (!b.author) {
        STFail(@"Book author not assigned.");        
      }
      if (!b.bookId) {
        STFail(@"Book id not assigned.");        
      }
      NSLog(@"%ld %@ %@ %@ %@ %@", b.bookId, b.title, b.author, b.publicationDate, b.purchaseDate, b.metadata);
    }
  }
  else {
    STFail(@"XML parse failed.");    
  }
}

@end
