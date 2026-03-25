# Chat List Screen Documentation

## Overview
The Chat List Screen serves as the home screen of the application, providing immediate access to recent conversations with zero cognitive load. It implements a responsive design with different layouts for mobile, tablet, and desktop viewports.

## Architecture

### Widget Hierarchy
```
RoomListScreen (ConsumerStatefulWidget)
└── _RoomListScreenState (ConsumerState)
    ├── Scaffold
    │   ├── SliverAppBar (floating: true, snap: true, pinned: true)
    │   │   ├── Title: "Chats"
    │   │   ├── Actions: Search/Back button, More options menu
    │   │   └── Search field (when searching)
    │   ├── CustomScrollView
    │   │   ├── SliverAppBar
    │   │   ├── SliverToBoxAdapter (IncomingCallBanner)
    │   │   └── SliverList
    │   │       └── Dismissible (swipe gestures)
    │   │           └── RepaintBoundary
    │   │               └── ChatListItem
    │   └── FloatingActionButton (bottom-right)
    └── ResponsiveLayout (mobile/tablet/desktop)
```

## Features

### 1. App Bar Implementation

#### SliverAppBar Configuration
- **Type**: `SliverAppBar` with `floating: true, snap: true, pinned: true`
- **Title**: "Chats" with theme-aware styling
- **Actions**: Dynamic based on search state
  - Search mode: Back button + expanded search field
  - Normal mode: Search button + more options menu

#### Search Functionality
- **Toggle**: Search/back button switches between modes
- **Search Field**: 
  - Auto-focus when activated
  - Real-time filtering as user types
  - Theme-aware text colors
  - Hint text: "Search conversations..."
- **Filter Logic**: Searches room names and last message text (case-insensitive)

#### Menu Actions
- **Settings**: Navigates to `/settings`
- **Select Multiple**: Enters multi-select mode
- **Mark All Read**: Marks all unread conversations as read using repository

### 2. List Area Implementation

#### CustomScrollView + SliverList
- **Performance**: Uses `SliverChildBuilderDelegate` for efficient rendering
- **Data Source**: Riverpod `roomListWithMessagesProvider` with local database (Drift)
- **Filtering**: Real-time search filtering with proper index handling

#### Chat List Items
Each item is wrapped in multiple layers:

##### Dismissible Widget (Swipe Gestures)
- **Swipe Right-to-Left**: 
  - Background: Blue with white archive icon
  - Action: Calls `_archiveRoom(room)`
  - Visual: `Container(color: Colors.blue, alignment: Alignment.centerLeft)`
- **Swipe Left-to-Right**:
  - Background: Grey with white more options icon  
  - Action: Calls `_showMoreOptions(room)`
  - Visual: `Container(color: Colors.grey, alignment: Alignment.centerRight)`

##### RepaintBoundary
- **Purpose**: Prevents whole list repainting when individual items update
- **Key**: `ValueKey(room.id)` for efficient widget identification
- **Child**: `ChatListItem` with all interaction callbacks

### 3. Chat List Item Layout

#### Avatar Section (Left - 50dp Circle)
- **Container**: Circular container with `AppTheme.primaryGreen` background
- **Initial**: First character of room name (uppercase) or "?"
- **Online Indicator**: Green dot (12dp) overlaid on border when `lastMessageTimestamp != null`
- **Multi-select Checkbox**: 20dp circle in bottom-right corner (visible in multi-select mode)
  - Selected: Green background with white checkmark
  - Unselected: White background with grey border

#### Content Area (Center)
- **Name Row**: 
  - Room name (bold, theme-aware color)
  - Timestamp (right-aligned, relative formatting)
  - Max 1 line with ellipsis overflow
- **Last Message Section**:
  - "Typing..." indicator (green, italic) when `isTyping == true`
  - Last message text (grey, 14pt) when available
  - Max 1 line with ellipsis overflow

#### Right Section
- **Unread Badge**:
  - Green circular badge with white text
  - Shows count (or "99+" for >99)
  - Hidden when `unreadCount == 0`
  - Positioned with proper spacing from content

### 4. Floating Action Button (FAB)

#### Positioning & Styling
- **Location**: Bottom-right of screen using `Scaffold.floatingActionButton`
- **Icon**: `Icons.chat_bubble_outline` (white)
- **Background**: `AppTheme.primaryGreen`
- **Action**: Calls `_navigateToNewChat()` to open new chat screen
- **Behavior**: Fixed position, doesn't scroll with content

### 5. Interaction Flow

#### Tap Interaction
- **Normal Mode**: Navigates to chat screen via `context.go('/chat/${room.id}?name=${Uri.encodeComponent(room.name)}')`
- **Multi-select Mode**: Toggles item selection in `_selectedRoomIds` set
- **Navigation**: Slide transition to chat screen

#### Long Press Interaction
- **Action**: Enters multi-select mode via `_toggleMultiSelectMode()`
- **State**: Automatically selects current item
- **Visual**: AppBar shows multi-select actions

#### Multi-select Mode
- **Entry**: Long press on any item or "Select Multiple" menu action
- **Exit**: Back button in search or toggle multi-select mode again
- **Selection**: Visual checkboxes on all items
- **Actions**: Batch operations (archive, delete, etc.) - placeholders implemented

#### Swipe Gestures
- **Implementation**: `Dismissible` widget with directional backgrounds
- **Right-to-Left Swipe**: Blue background → Archive action
- **Left-to-Right Swipe**: Grey background → More options action
- **Feedback**: SnackBar messages for user confirmation
- **Animation**: Smooth swipe-to-reveal with proper visual feedback

### 6. Responsive Layouts

#### Mobile Layout (< 768px)
- **Structure**: Single-pane with stack navigation
- **Navigation**: Full-screen chat screens with back navigation
- **App Bar**: SliverAppBar for scroll performance
- **FAB**: Fixed bottom-right positioning

#### Tablet Layout (768px - 1024px)
- **Structure**: 2-panel layout (Rooms | Chat)
- **Components**: `ThreePanelLayout` for consistent panel management
- **Room List**: Left panel with search and filtering
- **Chat Panel**: Right panel for conversation view

#### Desktop Layout (> 1024px)
- **Structure**: 3-panel layout (Rooms | Chat | Details)
- **Components**: `ThreePanelLayout` with optional detail panel
- **Detail Panel**: Room information, participants, settings
- **Breakpoints**: `AppBreakpoints.showDetailPanel(width)` for responsive behavior

### 7. Performance Optimizations

#### Rendering Strategy
- **RepaintBoundary**: Each `ChatListItem` wrapped to isolate repaints
- **ValueKey**: Proper key implementation for list diffing
- **Lazy Loading**: `SliverChildBuilderDelegate` for on-demand rendering
- **Database**: Local-first with Drift ORM for offline capability
- **Caching**: Repository-level caching for instant data access

#### Memory Management
- **State**: Minimal state variables with proper disposal
- **Controllers**: `TextEditingController` disposed in `dispose()` method
- **Listeners**: Proper cleanup to prevent memory leaks

### 8. Theme Integration

#### Color System
- **App Bar**: Uses `Theme.of(context).appBarTheme` for automatic light/dark adaptation
- **Text Colors**: `Theme.of(context).appBarTheme.foregroundColor` for consistency
- **Backgrounds**: Theme-aware surfaces for all components
- **Icons**: Theme-compatible coloring throughout

#### Typography
- **Headers**: `AppTheme.headerText` for consistent styling
- **Body**: `AppTheme.bodyText` for content text
- **Metadata**: `AppTheme.metadataText` for timestamps and secondary info

### 9. Data Management

#### State Management (Riverpod)
- **Provider**: `roomListWithMessagesProvider` for reactive data
- **Repository**: `RoomRepository` with Drift database backend
- **Updates**: Automatic UI refresh when data changes
- **Caching**: Built-in repository caching for performance

#### Data Flow
1. **Local Database**: Drift ORM for offline-first storage
2. **Repository Layer**: Abstracted data access with caching
3. **Provider Layer**: Riverpod for state management
4. **UI Layer**: Reactive widgets that respond to data changes

### 10. Error Handling

#### Network Errors
- **Display**: Error banners with retry functionality
- **Recovery**: Automatic refresh mechanisms
- **Fallback**: Empty states with clear user guidance

#### Data Validation
- **Null Safety**: Proper null checking throughout the implementation
- **Type Safety**: Strong typing with Dart's type system
- **Bounds Checking**: Array index validation in list rendering

### 11. Accessibility

#### Semantic Labels
- **Button Actions**: Proper tooltips for all interactive elements
- **Navigation**: Clear semantic relationships between screens
- **Content Structure**: Logical heading hierarchy for screen readers

#### Visual Accessibility
- **Color Contrast**: Theme-aware colors meeting WCAG standards
- **Touch Targets**: 48dp minimum touch targets for mobile
- **Text Scaling**: Respect system font size preferences

### 12. Future Enhancements

#### Planned Features
- **Archive Implementation**: Actual repository integration for swipe actions
- **Batch Operations**: Multi-select actions (delete, mute, etc.)
- **Search Enhancement**: Recent searches, search history
- **Pull-to-Refresh**: Manual refresh capability
- **Offline Indicators**: Visual sync status for all operations

## Usage Examples

### Basic Navigation
```dart
// User taps on chat item
context.go('/chat/room-id?name=Room%20Name');

// User searches for conversation
_searchController.text = 'search query';
// Results filter automatically
```

### Multi-select Operations
```dart
// Enter multi-select mode
_toggleMultiSelectMode();

// Select multiple items
// (automatic via checkboxes or long press)

// Exit multi-select mode
_toggleMultiSelectMode(); // or back button in search
```

### Swipe Actions
```dart
// Swipe right-to-left to archive
// Shows blue background with archive icon
// Calls _archiveRoom(room)

// Swipe left-to-right for more options  
// Shows grey background with more icon
// Calls _showMoreOptions(room)
```

## Conclusion

The Chat List Screen provides a comprehensive, production-ready implementation that follows modern Flutter best practices and material design guidelines. It delivers immediate access to conversations with intuitive interactions, smooth performance, and responsive behavior across all device types.

The architecture supports offline-first operation, efficient rendering, and maintainable code that can easily accommodate future requirements and feature enhancements.
