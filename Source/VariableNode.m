/*
 * MacGDBp
 * Copyright (c) 2011, Blue Static <http://www.bluestatic.org>
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU 
 * General Public License as published by the Free Software Foundation; either version 2 of the 
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not, 
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
 */

#import "VariableNode.h"

#import "AppDelegate.h"
#include "NSXMLElementAdditions.h"

// Private Properties //////////////////////////////////////////////////////////

@interface VariableNode ()

@property (copy) NSString* name;
@property (copy) NSString* fullName;
@property (copy) NSString* className;
@property (copy) NSString* type;
@property (copy) NSString* value;
@property (retain) NSArray* children;
@property (copy) NSString* address;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation VariableNode

@synthesize name = name_;
@synthesize fullName = fullName_;
@synthesize className = className_;
@synthesize type = type_;
@synthesize value = value_;
@synthesize children = children_;
@synthesize childCount = childCount_;
@synthesize address = address_;

- (id)initWithXMLNode:(NSXMLElement*)node
{
  if (self = [super init]) {
    self.name       = [[node attributeForName:@"name"] stringValue];
    self.fullName   = [[node attributeForName:@"fullname"] stringValue];
    self.className  = [[node attributeForName:@"classname"] stringValue];
    self.type       = [[node attributeForName:@"type"] stringValue];
    self.value      = [node base64DecodedValue];
    self.children   = [NSMutableArray array];
    if ([node children]) {
      [self setChildrenFromXMLChildren:[node children]];
    }
    childCount_     = [[[node attributeForName:@"numchildren"] stringValue] integerValue];
    self.address    = [[node attributeForName:@"address"] stringValue];
  }
  return self;
}

- (void)dealloc
{
  self.name = nil;
  self.fullName = nil;
  self.className = nil;
  self.type = nil;
  self.value = nil;
  self.children = nil;
  self.address = nil;
  [super dealloc];
}

- (void)setChildrenFromXMLChildren:(NSArray*)children
{
  for (NSXMLNode* child in children) {
    // Other child nodes may be the string value.
    if ([child isKindOfClass:[NSXMLElement class]]) {
      VariableNode* node = [[VariableNode alloc] initWithXMLNode:(NSXMLElement*)child];
      // Don't include the CLASSNAME property as that information is retreeived
      // elsewhere.
      if (![node.name isEqualToString:@"CLASSNAME"])
        [children_ addObject:node];
      [node release];
    }
  }
}

- (NSArray*)dynamicChildren
{
  NSArray* children = self.children;
  if (![self isLeaf] && (NSInteger)[children count] < self.childCount) {
    // If this node has children but they haven't been loaded from the backend,
    // request them asynchronously.
    [[AppDelegate instance].debugger fetchChildProperties:self];
  }
  return children;
}

- (BOOL)isLeaf
{
  return (self.childCount == 0);
}

- (NSString*)displayType
{
  if (self.className != nil) {
    return [NSString stringWithFormat:@"%@ (%@)", self.className, self.type];
  }
  return self.type;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<VariableNode %p : %@>", self, self.fullName];
}

@end
