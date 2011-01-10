/*
 * Copyright (c) 2010 Mark Liversedge (liversedge@gmail.com)
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "QtMacSegmentedButton.h"

#import <AppKit/NSButton.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSSegmentedControl.h>
#import <AppKit/NSBezierPath.h>

/*----------------------------------------------------------------------
 * Utility functions
 *----------------------------------------------------------------------*/
class CocoaInitializer::Private
{
    public:
        NSAutoreleasePool* autoReleasePool_;
};

CocoaInitializer::CocoaInitializer()
{
    d = new CocoaInitializer::Private();
    NSApplicationLoad();
    d->autoReleasePool_ = [[NSAutoreleasePool alloc] init];
}

CocoaInitializer::~CocoaInitializer()
{
    [d->autoReleasePool_ release];
    delete d;
}


inline NSString *darwinQStringToNSString (const QString &aString)
{
    return [reinterpret_cast<const NSString *> (CFStringCreateWithCharacters (0, reinterpret_cast<const UniChar *> (aString.unicode()), aString.length())) autorelease];
}

/*----------------------------------------------------------------------
 * QtMacSegmented Button
 *----------------------------------------------------------------------*/

/* Define the interface */
@interface NSSegmentedButtonTarget: NSObject
{
    QtMacSegmentedButton *mRealTarget;
}
-(id)initWithObject1:(QtMacSegmentedButton*)object;
-(IBAction)segControlClicked:(id)sender;
@end

@implementation NSSegmentedButtonTarget
-(id)initWithObject1:(QtMacSegmentedButton*)object
{
    self = [super init];
    mRealTarget = object;
    return self;
}

-(IBAction)segControlClicked:(id)sender;
{
    mRealTarget->onClicked([sender selectedSegment]);
}
@end


QtMacSegmentedButton::QtMacSegmentedButton (int aCount, QWidget *aParent /* = 0 */)
  : QMacCocoaViewContainer (0, aParent)
{
    mNativeRef = [[NSSegmentedControl alloc] init];
    [mNativeRef setSegmentCount:aCount];
    [mNativeRef setSegmentStyle:NSSegmentStyleRoundRect];
    [[mNativeRef cell] setTrackingMode: NSSegmentSwitchTrackingSelectOne];
    [mNativeRef setFont: [NSFont controlContentFontOfSize:
        [NSFont systemFontSizeForControlSize: NSSmallControlSize]]];
    [mNativeRef sizeToFit];

    NSSegmentedButtonTarget *bt = [[NSSegmentedButtonTarget alloc] initWithObject1:this];
    [mNativeRef setTarget:bt];
    [mNativeRef setAction:@selector(segControlClicked:)];

    NSRect frame = [mNativeRef frame];
    resize (frame.size.width, frame.size.height);

    setSizePolicy (QSizePolicy::Fixed, QSizePolicy::Fixed);

    setCocoaView (mNativeRef);

}

QSize QtMacSegmentedButton::sizeHint() const
{
    NSRect frame = [mNativeRef frame];
    return QSize (frame.size.width, frame.size.height);
}

void QtMacSegmentedButton::setSelected(int index) const
{
    [mNativeRef setSelected:true forSegment:index];
}

void QtMacSegmentedButton::setTitle (int aSegment, const QString &aTitle)
{
    QString s (aTitle);
    [mNativeRef setLabel: ::darwinQStringToNSString (s.remove ('&')) forSegment: aSegment];
    [mNativeRef sizeToFit];
    NSRect frame = [mNativeRef frame];
    resize (frame.size.width, frame.size.height);
}

void QtMacSegmentedButton::setToolTip (int aSegment, const QString &aTip)
{
    [[mNativeRef cell] setToolTip: ::darwinQStringToNSString (aTip) forSegment: aSegment];
}

void QtMacSegmentedButton::setEnabled (int aSegment, bool fEnabled)
{
    [[mNativeRef cell] setEnabled: fEnabled forSegment: aSegment];
}

void QtMacSegmentedButton::animateClick (int aSegment)
{
    [mNativeRef setSelectedSegment: aSegment];
    [[mNativeRef cell] performClick: mNativeRef];
}

void QtMacSegmentedButton::onClicked (int aSegment)
{
    emit clicked (aSegment, false);
}
