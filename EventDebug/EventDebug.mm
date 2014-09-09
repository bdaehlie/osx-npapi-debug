/* ***** BEGIN LICENSE BLOCK *****
 *
 * THIS FILE IS PART OF THE MOZILLA NPAPI SDK BASIC PLUGIN SAMPLE
 * SOURCE CODE. USE, DISTRIBUTION AND REPRODUCTION OF THIS SOURCE
 * IS GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS 
 * SOURCE IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.
 *
 * THE MOZILLA NPAPI EVENT DEBUG SOURCE CODE IS
 * (C) COPYRIGHT 2009 by the Mozilla Corporation
 * http://www.mozilla.com/
 *
 * Contributors:
 *  Josh Aas <josh@mozilla.com>
 *
 * ***** END LICENSE BLOCK ***** */

#include "EventDebug.h"

#include <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

// structure containing pointers to functions implemented by the browser
static NPNetscapeFuncs* gBrowserFuncs;

static NSString* gModeString = @"Modes: Mouse (Ctrl-M), Key (Ctrl-K), Focus (Ctrl-F), Draw (Ctrl-D), Text (Ctrl-T)";

typedef enum {
  eMouseMode = 1,
  eKeyMode,
  eFocusMode,
  eDrawMode,
  eTextMode
} DisplayMode;

static DisplayMode gDisplayMode = eMouseMode;

NSString* stringForMode(DisplayMode mode) {
  if (mode == eMouseMode)
    return @"eMouseMode";
  else if (mode == eKeyMode)
    return @"eKeyMode";
  else if (mode == eFocusMode)
    return @"eFocusMode";
  else if (mode == eDrawMode)
    return @"eDrawMode";
  else if (mode == eTextMode)
    return @"eTextMode";
  return nil;
}

// data for each instance of this plugin
typedef struct PluginInstance {
  NPP npp;
  NPWindow window;
  NSString* eventInfoString;
} PluginInstance;

void drawPlugin(NPP instance, NPCocoaEvent* event);

void redrawPlugin(NPP instance) {
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  float windowWidth = currentInstance->window.width;
  float windowHeight = currentInstance->window.height;
  NPRect rect;
  rect.top = 0;
  rect.left = 0;
  rect.bottom = (int16_t)windowHeight;
  rect.right = (int16_t)windowWidth;
  gBrowserFuncs->invalidaterect(instance, &rect);
  gBrowserFuncs->forceredraw(instance);
}

NSString* stringForType(NPCocoaEventType type) {
  switch (type) {
    case NPCocoaEventMouseMoved:
      return @"NPCocoaEventMouseMoved";
    case NPCocoaEventDrawRect:
      return @"NPCocoaEventDrawRect";
    case NPCocoaEventMouseDown:
      return @"NPCocoaEventMouseDown";
    case NPCocoaEventMouseUp:
      return @"NPCocoaEventMouseUp";
    case NPCocoaEventMouseEntered:
      return @"NPCocoaEventMouseEntered";
    case NPCocoaEventMouseExited:
      return @"NPCocoaEventMouseExited";
    case NPCocoaEventMouseDragged:
      return @"NPCocoaEventMouseDragged";
    case NPCocoaEventKeyDown:
      return @"NPCocoaEventKeyDown";
    case NPCocoaEventKeyUp:
      return @"NPCocoaEventKeyUp";
    case NPCocoaEventFlagsChanged:
      return @"NPCocoaEventFlagsChanged";
    case NPCocoaEventFocusChanged:
      return @"NPCocoaEventFocusChanged";
    case NPCocoaEventWindowFocusChanged:
      return @"NPCocoaEventWindowFocusChanged";
    case NPCocoaEventScrollWheel:
      return @"NPCocoaEventScrollWheel";
    case NPCocoaEventTextInput:
      return @"NPCocoaEventTextInput";
    default:
      return nil;
  }
  return nil;
}

void handleMouseEvent(NPP instance, void* event) {
  if (gDisplayMode != eMouseMode)
    return;

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  NPCocoaEventType eventType = cocoaEvent->type;

  // left mouse button up will print out convertpoint debug data
  if (eventType == NPCocoaEventMouseUp &&
      cocoaEvent->data.mouse.buttonNumber == 0) {
    [eventInfoString release];
    double x = cocoaEvent->data.mouse.pluginX;
    double y = cocoaEvent->data.mouse.pluginY;
    double xNPCoordinateSpacePlugin;
    double yNPCoordinateSpacePlugin;
    double xNPCoordinateSpaceWindow;
    double yNPCoordinateSpaceWindow;
    double xNPCoordinateSpaceFlippedWindow;
    double yNPCoordinateSpaceFlippedWindow;
    double xNPCoordinateSpaceScreen;
    double yNPCoordinateSpaceScreen;
    double xNPCoordinateSpaceFlippedScreen;
    double yNPCoordinateSpaceFlippedScreen;
    gBrowserFuncs->convertpoint(instance, x, y, NPCoordinateSpacePlugin, &xNPCoordinateSpacePlugin, &yNPCoordinateSpacePlugin, NPCoordinateSpacePlugin);
    gBrowserFuncs->convertpoint(instance, x, y, NPCoordinateSpacePlugin, &xNPCoordinateSpaceWindow, &yNPCoordinateSpaceWindow, NPCoordinateSpaceWindow);
    gBrowserFuncs->convertpoint(instance, x, y, NPCoordinateSpacePlugin, &xNPCoordinateSpaceFlippedWindow, &yNPCoordinateSpaceFlippedWindow, NPCoordinateSpaceFlippedWindow);
    gBrowserFuncs->convertpoint(instance, x, y, NPCoordinateSpacePlugin, &xNPCoordinateSpaceScreen, &yNPCoordinateSpaceScreen, NPCoordinateSpaceScreen);
    gBrowserFuncs->convertpoint(instance, x, y, NPCoordinateSpacePlugin, &xNPCoordinateSpaceFlippedScreen, &yNPCoordinateSpaceFlippedScreen, NPCoordinateSpaceFlippedScreen);
    eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@\npluginX = %f\npluginY= %f\nNPCoordinateSpacePlugin %f,%f\nNPCoordinateSpaceWindow %f,%f\nNPCoordinateSpaceFlippedWindow %f,%f\nNPCoordinateSpaceScreen %f,%f\nNPCoordinateSpaceFlippedScreen %f,%f",
                       stringForType(eventType),
                       x,
                       y,
                       xNPCoordinateSpacePlugin,
                       yNPCoordinateSpacePlugin,
                       xNPCoordinateSpaceWindow,
                       yNPCoordinateSpaceWindow,
                       xNPCoordinateSpaceFlippedWindow,
                       yNPCoordinateSpaceFlippedWindow,
                       xNPCoordinateSpaceScreen,
                       yNPCoordinateSpaceScreen,
                       xNPCoordinateSpaceFlippedScreen,
                       yNPCoordinateSpaceFlippedScreen];
    currentInstance->eventInfoString = eventInfoString;
    redrawPlugin(instance);
    return;
  }
  
  [eventInfoString release];
  eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\nmodifier flags = 0x%x\npluginX = %f\npluginY= %f\nbutton number = %d\nclick count = %d\ndeltaX = %f\ndeltaY = %f\ndeltaZ = %f",
                     stringForType(eventType),
                     eventType,
                     cocoaEvent->data.mouse.modifierFlags,
                     cocoaEvent->data.mouse.pluginX,
                     cocoaEvent->data.mouse.pluginY,
                     cocoaEvent->data.mouse.buttonNumber,
                     cocoaEvent->data.mouse.clickCount,
                     cocoaEvent->data.mouse.deltaX,
                     cocoaEvent->data.mouse.deltaY,
                     cocoaEvent->data.mouse.deltaZ];
  currentInstance->eventInfoString = eventInfoString;
  redrawPlugin(instance);

  // if this is a right click put up a context menu
  if (cocoaEvent->data.mouse.buttonNumber == 1) {
    // leak it, who cares for testing purposes
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:@"Foo" action:nil keyEquivalent:@""];
    [menu addItem:menuItem];
    gBrowserFuncs->popupcontextmenu(instance, (NPMenu*)menu);
  }
}

void handleKeyEvent(NPP instance, void* event) {
  if (gDisplayMode != eKeyMode)
    return;

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  NPCocoaEventType eventType = cocoaEvent->type;

  [eventInfoString release];
  if (eventType == NPCocoaEventFlagsChanged) {
    // don't try to access character data for flags changed events, it is null
    eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\nmodifier flags = 0x%x",
                       stringForType(eventType),
                       eventType,
                       cocoaEvent->data.key.modifierFlags];    
  }
  else {
    eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\nmodifier flags = 0x%x\ncharacters = %@\ncharacters ignoring modifiers = %@\nrepeat = %@\nkey code = %d",
                       stringForType(eventType),
                       eventType,
                       cocoaEvent->data.key.modifierFlags,
                       (NSString*)cocoaEvent->data.key.characters,
                       (NSString*)cocoaEvent->data.key.charactersIgnoringModifiers,
                       cocoaEvent->data.key.isARepeat ? @"yes" : @"no",
                       cocoaEvent->data.key.keyCode];    
  }
  currentInstance->eventInfoString = eventInfoString;
  redrawPlugin(instance);
}

void handleTextEvent(NPP instance, void* event) {
  if (gDisplayMode != eTextMode)
    return;

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  NPCocoaEventType eventType = cocoaEvent->type;
  
  [eventInfoString release];
  eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\ntext = %p",
                     stringForType(eventType),
                     eventType,
                     (NSString*)cocoaEvent->data.text.text];
  currentInstance->eventInfoString = eventInfoString;
  redrawPlugin(instance);
}

void handleDrawEvent(NPP instance, NPCocoaEvent* event) {
  if (gDisplayMode != eDrawMode) {
    drawPlugin(instance, event);
    return;
  }

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  NPCocoaEventType eventType = cocoaEvent->type;

  [eventInfoString release];
  eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\ncontext = %p\nx = %f\ny = %f\nwidth = %f\nheight = %f",
                     stringForType(eventType),
                     eventType,
                     cocoaEvent->data.draw.context,
                     cocoaEvent->data.draw.x,
                     cocoaEvent->data.draw.y,
                     cocoaEvent->data.draw.width,
                     cocoaEvent->data.draw.height];
  currentInstance->eventInfoString = eventInfoString;
  drawPlugin(instance, event);
}

void handleFocusEvent(NPP instance, void* event) {
  if (gDisplayMode != eFocusMode)
    return;

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  NPCocoaEventType eventType = cocoaEvent->type;
  
  [eventInfoString release];
  eventInfoString = [[NSString alloc] initWithFormat:@"Event type: %@ (value = %d)\nhas focus = %@",
                     stringForType(eventType),
                     eventType,
                     cocoaEvent->data.focus.hasFocus ? @"yes" : @"no"];
  currentInstance->eventInfoString = eventInfoString;
  redrawPlugin(instance);
}

// Symbol called once by the browser to initialize the plugin
NPError NP_Initialize(NPNetscapeFuncs* browserFuncs)
{  
  gBrowserFuncs = browserFuncs;

  return NPERR_NO_ERROR;
}

// Symbol called by the browser to get the plugin's function list
NPError NP_GetEntryPoints(NPPluginFuncs* pluginFuncs)
{
  pluginFuncs->version = 11;
  pluginFuncs->size = sizeof(pluginFuncs);
  pluginFuncs->newp = NPP_New;
  pluginFuncs->destroy = NPP_Destroy;
  pluginFuncs->setwindow = NPP_SetWindow;
  pluginFuncs->newstream = NPP_NewStream;
  pluginFuncs->destroystream = NPP_DestroyStream;
  pluginFuncs->asfile = NPP_StreamAsFile;
  pluginFuncs->writeready = NPP_WriteReady;
  pluginFuncs->write = (NPP_WriteProcPtr)NPP_Write;
  pluginFuncs->print = NPP_Print;
  pluginFuncs->event = NPP_HandleEvent;
  pluginFuncs->urlnotify = NPP_URLNotify;
  pluginFuncs->getvalue = NPP_GetValue;
  pluginFuncs->setvalue = NPP_SetValue;

  return NPERR_NO_ERROR;
}

// Symbol called once by the browser to shut down the plugin
void NP_Shutdown(void)
{
}

// Called to create a new instance of the plugin
NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved)
{
  PluginInstance *newInstance = (PluginInstance*)malloc(sizeof(PluginInstance));
  bzero(newInstance, sizeof(PluginInstance));

  newInstance->npp = instance;
  instance->pdata = newInstance;

  newInstance->eventInfoString = @"No events received";

  // select the right drawing model if necessary
  NPBool supportsCoreGraphics = false;
  if (gBrowserFuncs->getvalue(instance, NPNVsupportsCoreGraphicsBool, &supportsCoreGraphics) == NPERR_NO_ERROR && supportsCoreGraphics) {
    gBrowserFuncs->setvalue(instance, NPPVpluginDrawingModel, (void*)NPDrawingModelCoreGraphics);
  } else {
    printf("CoreGraphics drawing model not supported, can't create a plugin instance.\n");
    return NPERR_INCOMPATIBLE_VERSION_ERROR;
  }

  // select the Cocoa event model
  NPBool supportsCocoaEvents = false;
  if (gBrowserFuncs->getvalue(instance, NPNVsupportsCocoaBool, &supportsCocoaEvents) == NPERR_NO_ERROR && supportsCocoaEvents) {
    gBrowserFuncs->setvalue(instance, NPPVpluginEventModel, (void*)NPEventModelCocoa);
  } else {
    printf("Cocoa event model not supported, can't create a plugin instance.\n");
    return NPERR_INCOMPATIBLE_VERSION_ERROR;
  }

  return NPERR_NO_ERROR;
}

// Called to destroy an instance of the plugin
NPError NPP_Destroy(NPP instance, NPSavedData** save)
{
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  NSString* eventInfoString = currentInstance->eventInfoString;
  if (eventInfoString)
    [eventInfoString release];
  free(instance->pdata);

  return NPERR_NO_ERROR;
}

// Called to update a plugin instances's NPWindow
NPError NPP_SetWindow(NPP instance, NPWindow* window)
{
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);

  currentInstance->window = *window;
  
  return NPERR_NO_ERROR;
}

NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype)
{
  *stype = NP_ASFILEONLY;
  return NPERR_NO_ERROR;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason)
{
  return NPERR_NO_ERROR;
}

int32_t NPP_WriteReady(NPP instance, NPStream* stream)
{
  return 0;
}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer)
{
  return 0;
}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{
}

void NPP_Print(NPP instance, NPPrint* platformPrint)
{
}

int16_t NPP_HandleEvent(NPP instance, void* event)
{
  if (!event) {
    printf("NPP_HandleEvent called with NULL event pointer!\n");
    return 0;
  }

  NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;

  switch (cocoaEvent->type) {
    case NPCocoaEventMouseMoved:
      // do nothing, this would obscure useful event data
      // handleMouseEvent(instance, event);
      break;
    case NPCocoaEventDrawRect:
      handleDrawEvent(instance, cocoaEvent);
      break;
    case NPCocoaEventMouseDown:
    case NPCocoaEventMouseUp:
    case NPCocoaEventMouseEntered:
    case NPCocoaEventMouseExited:
    case NPCocoaEventMouseDragged:
    case NPCocoaEventScrollWheel:
      handleMouseEvent(instance, event);
      break;
    case NPCocoaEventFocusChanged:
    case NPCocoaEventWindowFocusChanged:
      handleFocusEvent(instance, event);
      break;    
    case NPCocoaEventTextInput:
      handleTextEvent(instance, event);
      break;
    case NPCocoaEventKeyDown:
      if ((cocoaEvent->data.key.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSControlKeyMask) {
        NSString* characters = (NSString*)cocoaEvent->data.key.charactersIgnoringModifiers;
        if ([characters isEqualToString:@"k"])
          gDisplayMode = eKeyMode;
        else if ([characters isEqualToString:@"m"])
          gDisplayMode = eMouseMode;
        else if ([characters isEqualToString:@"f"])
          gDisplayMode = eFocusMode;
        else if ([characters isEqualToString:@"d"])
          gDisplayMode = eDrawMode;
        else if ([characters isEqualToString:@"t"])
          gDisplayMode = eTextMode;
        // redraw in case display mode changed
        redrawPlugin(instance);
      }
    case NPCocoaEventKeyUp:
    case NPCocoaEventFlagsChanged:
      handleKeyEvent(instance, event);
      break;
    default:
      printf("Unrecognized event type (%d) sent to NPP_HandleEvent!\n", cocoaEvent->type);
  }

  return 1;
}

void NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value)
{
  return NPERR_GENERIC_ERROR;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value)
{
  return NPERR_GENERIC_ERROR;
}

void drawPlugin(NPP instance, NPCocoaEvent* event)
{
  PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
  CGContextRef cgContext = event->data.draw.context;
  NSString* eventInfoString = currentInstance->eventInfoString;
  NSString* modeInfoString = [NSString stringWithFormat:@"Current Mode: %@", stringForMode(gDisplayMode)];
  NSString* displayString = [NSString stringWithFormat:@"%@\n%@\n\n%@", gModeString, modeInfoString, eventInfoString];

  float windowWidth = currentInstance->window.width;
  float windowHeight = currentInstance->window.height;

  // save the cgcontext gstate
  CGContextSaveGState(cgContext);

  // we get a flipped context
  CGContextTranslateCTM(cgContext, 0.0, windowHeight);
  CGContextScaleCTM(cgContext, 1.0, -1.0);

  // draw a gray background for the plugin
  CGContextAddRect(cgContext, CGRectMake(0, 0, windowWidth, windowHeight));
  CGContextSetGrayFillColor(cgContext, 0.5, 1.0);
  CGContextDrawPath(cgContext, kCGPathFill);

  // draw a black frame around the plugin
  CGContextAddRect(cgContext, CGRectMake(0, 0, windowWidth, windowHeight));
  CGContextSetGrayStrokeColor(cgContext, 0.0, 1.0);
  CGContextSetLineWidth(cgContext, 6.0);
  CGContextStrokePath(cgContext);

  // draw the string using Core Text
  CGContextSetTextMatrix(cgContext, CGAffineTransformIdentity);

  // Initialize a rectangular path.
  CGMutablePathRef path = CGPathCreateMutable();
  CGRect bounds = CGRectMake(10.0, 10.0, windowWidth - 20.0, windowHeight - 20.0);
  CGPathAddRect(path, NULL, bounds);

  // Initialize an attributed string.
  CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
  CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), (CFStringRef)displayString);

  // Create a color and add it as an attribute to the string.
  CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat components[] = { 0.0, 0.0, 0.0, 1.0 };
  CGColorRef red = CGColorCreate(rgbColorSpace, components);    
  CGColorSpaceRelease(rgbColorSpace);
  CFAttributedStringSetAttribute(attrString, CFRangeMake(0, 50), kCTForegroundColorAttributeName, red);

  // Create the framesetter with the attributed string.
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
  CFRelease(attrString);

  // Create the frame and draw it into the graphics context
  CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
  CFRelease(framesetter);
  CTFrameDraw(frame, cgContext);
  CFRelease(frame);

  // restore the cgcontext gstate
  CGContextRestoreGState(cgContext);
}
