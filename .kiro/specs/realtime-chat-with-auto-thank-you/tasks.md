# Implementation Plan: Realtime Chat with Auto Thank You

## Overview

This implementation plan covers the development of a realtime chat system with automatic thank you messaging. The system leverages existing Socket.IO infrastructure (socketHandler.ts, clientManager.ts) and models (Chat, Message) to enable direct user-to-user communication with realtime updates. The auto thank you feature triggers after successful checkout, automatically creating chats with product owners and sending appreciation messages.

The implementation is divided into backend enhancements (Socket.IO event handling, message endpoints, auto message logic), frontend development (Flutter UI screens, Socket.IO service, models), and comprehensive testing (property-based tests, integration tests, unit tests).

## Tasks

- [ ] 1. Backend: Enhance Socket.IO message handling
  - [x] 1.1 Add CHAT event handler in socketHandler.ts
    - Implement handleChatMessage function to process incoming CHAT events
    - Extract from, to, message from event data
    - Validate that from, to, and message are non-null and non-empty
    - _Requirements: 1.1, 8.1_
  
  - [x] 1.2 Save messages to database in CHAT handler
    - Call messageService.create with senderId, receiverId, message, dateSent, isRead=0
    - Handle database errors gracefully
    - Return saved message object
    - _Requirements: 1.1, 1.2_
  
  - [x] 1.3 Emit messages to receiver via Socket.IO
    - Use clientManager.sendToUser to emit MESSAGE event to receiver
    - Include message object and timestamp in event payload
    - Handle case when receiver is offline (message queued in DB)
    - _Requirements: 1.2, 1.3, 1.5_
  
  - [x] 1.4 Update chat status on message send
    - Call chatService to find chat between sender and receiver
    - Update chat.status to 0 (unread) for receiver
    - Save updated chat to database
    - _Requirements: 1.4_
  
  - [ ]* 1.5 Write property test for message delivery guarantee
    - **Property 1: Message Delivery Guarantee**
    - **Validates: Requirements 1.1, 1.2, 1.3**
    - Test that messages sent to online users are delivered via Socket.IO
    - Test that messages are persisted in database regardless of receiver status
  
  - [ ]* 1.6 Write property test for no duplicate messages
    - **Property 2: No Duplicate Messages**
    - **Validates: Requirements 1.1**
    - Test that sending same message multiple times creates separate DB records
    - Test that receiver gets correct number of notifications

- [ ] 2. Backend: Implement message controller endpoints
  - [x] 2.1 Add getMessagesByChatId endpoint
    - Implement GET /api/messages/chat/:chatId
    - Fetch messages where (senderId=user1 AND receiverId=user2) OR (senderId=user2 AND receiverId=user1)
    - Sort by dateSent ascending
    - Support pagination with limit and offset query params
    - _Requirements: 4.1, 12.1, 12.3_
  
  - [x] 2.2 Add markAsRead endpoint
    - Implement PUT /api/messages/:messageId/read
    - Update message.isRead to 1
    - Check if all messages in chat are read, update chat.status to 1
    - Emit UPDATE_CHAT event to both users
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [x] 2.3 Add getUnreadCount endpoint
    - Implement GET /api/messages/unread-count
    - Count messages where receiverId=currentUser AND isRead=0
    - Return count in JSON response
    - _Requirements: 3.4_
  
  - [ ]* 2.4 Write unit tests for message controller
    - Test getMessagesByChatId with valid chatId
    - Test markAsRead updates message and chat status
    - Test getUnreadCount returns correct count
    - Test error handling for invalid inputs

- [ ] 3. Backend: Enhance bill controller for auto thank you
  - [x] 3.1 Verify autoSentMessage implementation in bill.controller.ts
    - Check if autoSentMessage method exists and is called in checkout
    - Extract unique product owners from cart items
    - Exclude buyer from product owner list
    - _Requirements: 5.1, 5.2_
  
  - [x] 3.2 Implement chat creation/update logic in autoSentMessage
    - For each product owner, call chatService.checkExistChatUser1AndUser2
    - If chat doesn't exist, create new chat with createChatSelf
    - If chat exists, update status to 0 (unread)
    - Emit NEW_CHAT event to buyer if chat is newly created
    - _Requirements: 5.3, 5.4, 7.2, 7.3_
  
  - [x] 3.3 Implement auto message creation in autoSentMessage
    - For each product owner, create message with predefined thank you text
    - Set senderId=ownerId, receiverId=buyerId
    - Set message text: "Xin chào, Cám ơn vì đã mua sản phẩm của tôi! Hãy liên hệ với tôi khi có vấn đề nhé."
    - Emit MESSAGE event to buyer via Socket.IO
    - _Requirements: 5.5, 5.6_
  
  - [x] 3.4 Add error handling for auto message failures
    - Wrap auto message logic in try-catch
    - Log errors but don't block checkout process
    - Return success response even if auto messages fail
    - _Requirements: 5.7, 9.4_
  
  - [ ]* 3.5 Write property test for auto thank you uniqueness
    - **Property 3: Auto Thank You Uniqueness**
    - **Validates: Requirements 5.1, 5.2, 5.5**
    - Test that exactly one message is sent per product owner
    - Test that no message is sent if buyer equals owner
  
  - [ ]* 3.6 Write property test for no self-messaging
    - **Property 13: No Self-Messaging in Auto Thank You**
    - **Validates: Requirements 5.2**
    - Test that buyer never receives auto message from themselves

- [ ] 4. Backend: Add message routes and validation
  - [-] 4.1 Create message.routes.ts if not exists
    - Define routes for getMessagesByChatId, markAsRead, getUnreadCount
    - Apply authMiddleware to all routes
    - Mount routes in main router
    - _Requirements: 8.3_
  
  - [x] 4.2 Add message validation middleware
    - Validate message content is non-empty and <= 2000 characters
    - Sanitize HTML and script tags to prevent XSS
    - Validate user IDs are valid MongoDB ObjectIds
    - _Requirements: 8.1, 8.2_
  
  - [x] 4.3 Implement rate limiting for messages
    - Add rate limiter: 10 messages per minute per user
    - Add rate limiter: 100 Socket.IO events per minute per connection
    - Return 429 Too Many Requests when limit exceeded
    - _Requirements: 8.4, 8.5_
  
  - [ ]* 4.4 Write unit tests for validation and rate limiting
    - Test message length validation
    - Test XSS sanitization
    - Test rate limiting enforcement

- [ ] 5. Backend: Create database indexes for performance
  - [x] 5.1 Add indexes to chat collection
    - Create compound unique index on (user1Id, user2Id)
    - Create index on user1Id
    - Create index on user2Id
    - _Requirements: 7.4, 10.2_
  
  - [x] 5.2 Add indexes to message collection
    - Create compound index on (senderId, receiverId, dateSent)
    - Create index on (receiverId, isRead) for unread queries
    - Create index on dateSent for chronological ordering
    - _Requirements: 10.1, 12.3_
  
  - [ ]* 5.3 Write performance tests for indexed queries
    - Test chat lookup performance with large dataset
    - Test message query performance with pagination
    - Verify O(log n) query time with indexes

- [ ] 6. Checkpoint - Backend implementation complete
  - Ensure all backend tests pass
  - Verify Socket.IO events are emitted correctly
  - Test auto thank you flow with Postman
  - Ask the user if questions arise

- [ ] 7. Frontend: Setup Socket.IO and dependencies
  - [x] 7.1 Add socket_io_client dependency to pubspec.yaml
    - Add socket_io_client: ^2.0.3
    - Add provider: ^6.1.1 for state management
    - Add intl: ^0.18.1 for date formatting
    - Run flutter pub get
    - _Requirements: 2.1_
  
  - [x] 7.2 Create SocketService class
    - Create lib/services/socket_service.dart
    - Implement connect method with userId parameter
    - Implement disconnect method
    - Implement sendMessage method for CHAT events
    - Implement markAsRead method for MESSAGE_READ events
    - Create StreamController for incoming messages
    - _Requirements: 2.1, 2.2, 2.3, 4.3_
  
  - [x] 7.3 Setup Socket.IO event listeners in SocketService
    - Listen for 'connect' event and emit INIT with userId
    - Listen for 'MESSAGE' event and add to message stream
    - Listen for 'NEW_CHAT' event and add to message stream
    - Listen for 'UPDATE_CHAT' event and add to message stream
    - Listen for 'disconnect' event and handle reconnection
    - _Requirements: 2.2, 2.5, 3.6_
  
  - [x] 7.4 Implement reconnection logic with exponential backoff
    - Retry connection on disconnect with delays: 1s, 2s, 4s, 8s
    - Max 5 reconnection attempts
    - Show "Connecting..." indicator during reconnection
    - _Requirements: 2.4, 9.1_
  
  - [ ]* 7.5 Write unit tests for SocketService
    - Test connect establishes connection and emits INIT
    - Test sendMessage emits CHAT event
    - Test event listeners add to message stream
    - Mock Socket.IO for isolated testing

- [ ] 8. Frontend: Create data models
  - [x] 8.1 Create Chat model
    - Create lib/models/chat.dart
    - Define Chat class with id, user1, user2, status, lastMessage
    - Implement fromJson factory constructor
    - Implement toJson method
    - _Requirements: 3.1, 3.2_
  
  - [x] 8.2 Create Message model
    - Create lib/models/message.dart
    - Define Message class with id, senderId, receiverId, message, dateSent, isRead
    - Implement fromJson factory constructor
    - Implement toJson method
    - _Requirements: 4.1_
  
  - [ ]* 8.3 Write unit tests for models
    - Test Chat.fromJson parses correctly
    - Test Message.fromJson parses correctly
    - Test toJson serializes correctly

- [ ] 9. Frontend: Create ChatApi service
  - [x] 9.1 Create ChatApi service class
    - Create lib/services/chat_api.dart
    - Implement fetchChats method for GET /api/chats/self
    - Implement createChat method for POST /api/chats/self
    - Implement getChatWith method for GET /api/chats/with/:userId
    - _Requirements: 3.1_
  
  - [x] 9.2 Create MessageApi service class
    - Create lib/services/message_api.dart
    - Implement fetchMessages method for GET /api/messages/chat/:chatId
    - Implement markAsRead method for PUT /api/messages/:messageId/read
    - Implement getUnreadCount method for GET /api/messages/unread-count
    - _Requirements: 4.1, 6.1_
  
  - [ ]* 9.3 Write unit tests for API services
    - Test fetchChats returns list of chats
    - Test fetchMessages returns list of messages
    - Test error handling for failed requests

- [ ] 10. Frontend: Build ChatListScreen UI
  - [x] 10.1 Create ChatListScreen widget
    - Create lib/screens/chat_list_screen.dart
    - Implement StatefulWidget with AppBar titled "Messages"
    - Use AppColors.background for screen background
    - Add pull-to-refresh functionality
    - _Requirements: 3.1, 11.1_
  
  - [x] 10.2 Implement chat list loading and display
    - Call ChatApi.fetchChats in initState
    - Display chats in ListView.builder with Card widgets
    - Show loading indicator while fetching
    - Show empty state with "No conversations yet" if list is empty
    - _Requirements: 3.1, 3.2, 11.1_
  
  - [x] 10.3 Design chat list item UI
    - Display user avatar with CircleAvatar (gold background)
    - Display user name in gold color, bold
    - Display last message text in goldMuted, truncated
    - Display timestamp in goldMuted, 12px
    - Show gold dot indicator if chat.status = 0 (unread)
    - _Requirements: 3.3, 3.4, 11.2, 11.3, 11.4_
  
  - [x] 10.4 Setup realtime updates for chat list
    - Listen to SocketService.messageStream in initState
    - Handle NEW_CHAT event: insert new chat at top of list
    - Handle MESSAGE event: update chat's lastMessage and move to top
    - Handle UPDATE_CHAT event: update chat status
    - _Requirements: 3.5, 3.6_
  
  - [x] 10.5 Implement navigation to ChatDetailScreen
    - Add onTap handler to chat list items
    - Navigate to ChatDetailScreen with chat object as parameter
    - Use MaterialPageRoute for navigation
    - _Requirements: 4.1_
  
  - [ ]* 10.6 Write widget tests for ChatListScreen
    - Test chat list displays correctly
    - Test empty state shows when no chats
    - Test navigation to ChatDetailScreen on tap

- [ ] 11. Frontend: Build ChatDetailScreen UI
  - [x] 11.1 Create ChatDetailScreen widget
    - Create lib/screens/chat_detail_screen.dart
    - Implement StatefulWidget with chat parameter
    - Add AppBar with back button and other user's name
    - Use AppColors.background for screen background
    - _Requirements: 4.1, 11.1_
  
  - [x] 11.2 Implement message loading and display
    - Call MessageApi.fetchMessages in initState
    - Display messages in ListView with reverse scroll
    - Show loading indicator while fetching
    - Group messages by date (optional)
    - _Requirements: 4.1, 12.1_
  
  - [ ] 11.3 Design message bubble UI
    - Sent messages: right-aligned, gold background, onGold text
    - Received messages: left-aligned, surface background, gold text with border
    - Display timestamp below message text
    - Use rounded corners for bubbles
    - _Requirements: 4.2, 11.2_
  
  - [ ] 11.4 Implement message input area
    - Add TextField at bottom with surface background and gold text
    - Add send button (FilledButton with Icons.send_rounded)
    - Disable send button when TextField is empty
    - Clear TextField after sending message
    - _Requirements: 4.3, 4.6_
  
  - [ ] 11.5 Implement message sending via Socket.IO
    - Get current user ID from AuthService
    - Determine other user ID from chat object
    - Call SocketService.sendMessage with from, to, message
    - Add sent message to local state immediately (optimistic update)
    - _Requirements: 4.3_
  
  - [ ] 11.6 Setup realtime message receiving
    - Listen to SocketService.messageStream in initState
    - Handle MESSAGE event: check if message belongs to current chat
    - Append received message to message list
    - Auto-scroll to bottom when new message arrives
    - _Requirements: 4.4_
  
  - [ ] 11.7 Implement mark as read functionality
    - Call MessageApi.markAsRead when screen opens
    - Mark all unread messages in current chat as read
    - Update local message state to reflect read status
    - _Requirements: 4.5, 6.1_
  
  - [ ]* 11.8 Write widget tests for ChatDetailScreen
    - Test messages display correctly
    - Test message bubbles have correct alignment and colors
    - Test send button is disabled when input is empty
    - Test message sending updates UI

- [ ] 12. Frontend: Add navigation from home screen
  - [ ] 12.1 Add chat icon button to home screen AppBar
    - Add IconButton with Icons.message icon
    - Use gold color for icon
    - Add onPressed handler to navigate to ChatListScreen
    - _Requirements: 3.1_
  
  - [ ] 12.2 Initialize SocketService on app start
    - Connect SocketService when user logs in
    - Pass authenticated user ID to connect method
    - Disconnect SocketService when user logs out
    - _Requirements: 2.1, 2.2_
  
  - [ ]* 12.3 Write integration test for navigation flow
    - Test navigation from home to ChatListScreen
    - Test navigation from ChatListScreen to ChatDetailScreen
    - Test back navigation works correctly

- [ ] 13. Checkpoint - Frontend implementation complete
  - Ensure all frontend tests pass
  - Test realtime messaging between two users
  - Verify UI matches design specifications
  - Ask the user if questions arise

- [ ] 14. Integration testing and end-to-end flows
  - [ ]* 14.1 Write integration test for realtime chat flow
    - User A connects via Socket.IO
    - User B connects via Socket.IO
    - User A sends message to User B
    - Verify User B receives message realtime
    - Verify message saved in database
    - Verify chat status updated
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [ ]* 14.2 Write integration test for checkout auto message flow
    - User creates cart with products from multiple sellers
    - User calls checkout API
    - Verify chats created with all sellers
    - Verify auto messages sent to user
    - Verify Socket.IO events emitted
    - Verify bill created successfully
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  
  - [ ]* 14.3 Write integration test for offline/online sync
    - User goes offline (disconnect Socket.IO)
    - Messages sent to user while offline
    - User comes back online (reconnect Socket.IO)
    - Verify all missed messages loaded
    - Verify chat list updated correctly
    - _Requirements: 1.5, 2.5_
  
  - [ ]* 14.4 Write property test for chat bidirectional lookup
    - **Property 4: Chat Bidirectional Lookup**
    - **Validates: Requirements 7.1**
    - Test that checkExistChatUser1AndUser2(u1, u2) returns same chat as checkExistChatUser1AndUser2(u2, u1)
  
  - [ ]* 14.5 Write property test for message chronological ordering
    - **Property 5: Message Chronological Ordering**
    - **Validates: Requirements 12.1, 12.2, 12.3, 12.4**
    - Test that messages are always displayed in chronological order
    - Test that database queries return messages sorted by dateSent
  
  - [ ]* 14.6 Write property test for read status consistency
    - **Property 6: Read Status Consistency**
    - **Validates: Requirements 6.1, 6.2, 6.3**
    - Test that markAsRead updates message.isRead to 1
    - Test that chat.status updates to 1 when all messages are read

- [ ] 15. Error handling and edge cases
  - [ ] 15.1 Implement Socket connection failure handling
    - Show "Connecting..." indicator in ChatListScreen
    - Retry connection with exponential backoff
    - Show error message if max retries exceeded
    - _Requirements: 9.1_
  
  - [ ] 15.2 Implement message send failure handling
    - Show error indicator on failed message (red exclamation icon)
    - Add retry button to failed messages
    - Keep failed message in UI with "Failed to send" status
    - _Requirements: 9.2_
  
  - [ ] 15.3 Implement chat list load failure handling
    - Show error message with retry button
    - Display cached chats if available (offline mode)
    - Show "Failed to load chats" with gold error icon
    - _Requirements: 9.3_
  
  - [x] 15.4 Handle invalid user ID in Socket events
    - Server logs warning for invalid user IDs
    - Ignore invalid events without crashing
    - Don't emit to any client for invalid events
    - _Requirements: 9.4_
  
  - [ ]* 15.5 Write unit tests for error handling
    - Test Socket connection failure shows error
    - Test message send failure shows retry button
    - Test chat list load failure shows error message

- [ ] 16. Final checkpoint and polish
  - [ ] 16.1 Verify all requirements are met
    - Review requirements document and check each acceptance criterion
    - Test all user stories end-to-end
    - Verify all correctness properties hold
  
  - [ ] 16.2 Performance optimization
    - Verify database indexes are created
    - Test message pagination works correctly
    - Verify lazy loading in chat list
    - Test with large datasets (100+ chats, 1000+ messages)
  
  - [ ] 16.3 Security audit
    - Verify JWT authentication on all endpoints
    - Test rate limiting enforcement
    - Verify XSS sanitization works
    - Test that sender ID cannot be spoofed
  
  - [ ] 16.4 UI/UX polish
    - Verify all colors match gold/dark theme
    - Test on different screen sizes
    - Verify loading states and empty states
    - Test accessibility (screen reader support)
  
  - [ ] 16.5 Documentation and cleanup
    - Add code comments for complex logic
    - Update API documentation
    - Remove debug logs and console.log statements
    - Ensure all tests pass

- [ ] 17. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Backend uses TypeScript, frontend uses Dart/Flutter
- Existing Socket.IO infrastructure (socketHandler.ts, clientManager.ts) is leveraged
- Existing models (Chat, Message) are used without modifications
- Property tests validate universal correctness properties
- Integration tests validate end-to-end flows
- Checkpoints ensure incremental validation and user feedback
