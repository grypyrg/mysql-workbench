/*
 * Copyright (c) 2008, 2014, Oracle and/or its affiliates. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */
#import "MTogglePane.h"


@implementation MTogglePane

- (instancetype)initWithFrame: (NSRect)frame includeHeader: (BOOL)hasHeader
{
  self = [super initWithFrame:frame];
  if (self != nil)
  {
    _initializing= YES;
    if (hasHeader)
    {
      _header= [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(frame), 23)] autorelease];
      [self addSubview:_header];
      [_header setAutoresizingMask:NSViewWidthSizable];
      [_header setImageScaling:NSImageScaleAxesIndependently];
      [_header setImage:[NSImage imageNamed:@"collapsing_panel_header_bg_flat.png"]];
  
      _toggleButton= [[[NSButton alloc] initWithFrame:NSMakeRect(5, 5, 13, 13)] autorelease];
      [_toggleButton setBezelStyle:NSDisclosureBezelStyle];
      [_toggleButton setButtonType:NSOnOffButton];
      [_toggleButton setTitle:@""];
      [_toggleButton setAction:@selector(toggle:)];
      [_toggleButton setTarget:self];
      [_toggleButton setState: NSOnState]; // expanded by default
      [self addSubview:_toggleButton];
    
      _label= [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 3, 20, 20)] autorelease];
      [_label setBordered:NO];
      [_label setEditable:NO];
      [_label setFont:[NSFont boldSystemFontOfSize:12]];
      [_label setDrawsBackground:NO];
      [self addSubview:_label];
    }
    _buttons= [[NSMutableArray array] retain];
    
    _initializing = NO;
    _relayouting = NO;
  }
  return self;
}

- (instancetype)initWithFrame: (NSRect)frame
{
  return [self initWithFrame: frame includeHeader: YES];
}

-(instancetype)initWithCoder: (NSCoder *)coder
{
  return [self initWithFrame: NSMakeRect(0, 0, 100, 100) includeHeader: YES];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [_buttons release];
  [super dealloc];
}

- (BOOL)isFlipped
{
  return YES;
}

- (IBAction)toggle:(id)sender
{
  [self relayout];
}


- (void)setExpanded:(BOOL)flag
{
  [_toggleButton setState:flag ? NSOnState : NSOffState];
  [self relayout];
}


- (void)setLabel:(NSString*)label
{
  [_label setStringValue:label];
  [_label sizeToFit];
}

- (void)contentFrameDidChange:(NSNotification*)notif
{
  [self relayout];
}


- (void)didAddSubview:(NSView *)subview
{
  // for working with IB
  if (!_initializing)
  {
    _content= subview;
    [_content setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(contentFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:_content];
    [subview setFrameOrigin:NSMakePoint(0, _header ? NSHeight([_header frame]) : 0)];
    [subview setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];
    [self relayout];
  }
}


- (void)setContentView:(NSView*)view
{
  if (_content)
  {
    [_content removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_content];
  }

  [self addSubview:view];
}


- (NSView*)contentView
{
  return _content;
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
  [self relayout];
  [super resizeSubviewsWithOldSize:oldBoundsSize];
}


- (void)relayout
{
  NSRect contentRect= [_content frame];
  NSRect newContentRect;
  NSRect buttonRect;
  NSRect rect= [self frame];
  CGFloat headerHeight= _header ? NSHeight([_header frame]) : 0;
  
  if (_relayouting)
    return;
  _relayouting= YES;
  
  if (!_toggleButton || [_toggleButton state] == NSOnState)
  {
    rect.size.height= headerHeight + NSHeight(contentRect);

    [_content setHidden:NO];
  }
  else
  {
    rect.size.height= headerHeight - 1;
    
    [_content setHidden:YES];
  }
  
  buttonRect.origin.x= rect.size.width - [_buttons count] * headerHeight;
  buttonRect.origin.y= 0;
  buttonRect.size.width= headerHeight;
  buttonRect.size.height= headerHeight;
  for (NSButton *btn in _buttons)
  {
    [btn setFrame:buttonRect];
    buttonRect.origin.x+= headerHeight;
  }
  
  newContentRect= NSMakeRect(0, headerHeight, NSWidth(rect), NSHeight(contentRect));
  
  if (!NSEqualRects(newContentRect, contentRect))
    [_content setFrame:newContentRect];
  
  if (!NSEqualRects([self frame], rect))
    [self setFrame:rect];
  
  _relayouting= NO;
}


- (NSButton*)addButton:(NSImage*)icon
            withAction:(SEL)selector
                target:(id)target
{
  CGFloat headerHeight= NSHeight([_header frame]);
  NSButton *button= [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, headerHeight, headerHeight)] autorelease];

  _initializing= YES;
  
  [_buttons addObject:button];
  
  [button setBordered:NO];
  [button setImage:icon];
  [button setImagePosition:NSImageOnly];
  [button setAction:selector];
  [button setTarget:target];
  [button setEnabled: (selector != nil) && (target != nil)];
  
  [self addSubview:button];
  
  [self relayout];
  
  _initializing= NO;
  
  return button;
}


@end
