XmlDigester
===========

Coming from a Java background, I was looking for IOS code that would
parse XML into Objective-C objects similar to functionality available
in Java with JAXB or the Apache Commons Digester.

This is an inital cut at a library to do so.

Usage
-----

Here is a trivial XML document describing a library with one book.

<pre>
    &lt;library&gt;
      &lt;book&gt;
        &lt;id&gt;44144&lt;/id&gt;
        &lt;title&gt;Title&lt;/title&gt;
        &lt;author&gt;Author&lt;/author&gt;
        &lt;publicationDate&gt;1324045046726&lt;/publicationDate&gt;
        &lt;purchaseDate&gt;2012-01-02&lt;/purchaseDate&gt;
        &lt;meta key="foo" value="bar"/&gt;
        &lt;meta key="foo2" value="baz"/&gt;
      &lt;/book&gt;
    &lt;/library&gt;
</pre>

The following classes are used to hold the data parsed from the XML.


    @interface Book : NSObject {
    }

    @property long bookId;
    @property (strong)NSString*title;
    @property (strong)NSString*author;
    @property (strong)NSDate *publicationDate;
    @property (strong)NSDate *purchaseDate;
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
	
Configure the digester to process the XML and construct the object hierarchy
based on the configuration rules.

    XmlDigester *digester = [[XmlDigester alloc] init];

	//create an instance of Library when the library element is encountered.
    [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library$" className:@"Library"]];
	
	// create an instance of Book when the book element is encountered and call the addBook selector on the parent (Library).
    [digester appendRule:[[XmlDigesterObjectCreationRule alloc] initWithRegex:@"library/book$" className:@"Book"parentMethodName:@"addBook:"]];

    // assign to bookId from xml element id.
    [digester appendRule:[[XmlDigesterPropertyAssignmentRule alloc] initWithRegex:@".*/book/id$" propertyName:@"bookId"]];

    //purchase date is yyyy-MM-DD in XML, use "date" converter manually.
    [digester appendRule:[[XmlDigesterPropertyAssignmentRule alloc] initWithRegex:@".*/book/purchaseDate$" propertyName:@"purchaseDate" converter:@"date"]];

    // assign additional metadata.
    [digester appendRule:[[XmlDigesterCallSelectorRule alloc] initWithRegex:@".*/book/meta$" selectorName: @"addMeta:"]];
  
    // assign other properties normally.
    [digester appendRule:[[XmlDigesterPropertiesAssignmentRule alloc] initWithRegex:@".*/book/[a-z]*$"]];
  
    NSURL *file = [NSURL fileURLWithPath:@"library2.xml"];
    NSXMLParser *p = [[NSXMLParser alloc ] initWithContentsOfURL:file];
    p.delegate = digester;
    BOOL stat = [p parse];
    if (stat) {
      if (!([digester.rootObject isKindOfClass:[Library class]])) {
        NSLog(@"Unexpected object returned");
      }
      Library *lib = (Library*)digester.rootObject;
    }


License
-------

Copyright 2011-2012 James Guistwite

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
