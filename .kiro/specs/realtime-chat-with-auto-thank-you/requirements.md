# Requirements Document

## Introduction

This document specifies the requirements for a realtime chat system with automatic thank you messaging functionality. The system enables direct communication between users through Socket.IO-based realtime messaging, combined with an automated feature that sends thank you messages from sellers to buyers after successful checkout. The system integrates with existing chat and message models, Socket.IO infrastructure, and the checkout flow to provide seamless communication and post-purchase engagement.

## Glossary

- **System**: The realtime chat with auto thank you feature
- **User**: Any authenticated person using the application
- **Buyer**: A user who purchases products through checkout
- **Seller**: A user who owns products being purchased
- **Chat**: A conversation between two users
- **Message**: A text communication sent from one user to another
- **Socket_Handler**: Backend component managing Socket.IO connections and events
- **Message_Controller**: Backend component handling message operations
- **Bill_Controller**: Backend component processing checkout and triggering auto messages
- **Chat_List_Screen**: Flutter UI displaying all user conversations
- **Chat_Detail_Screen**: Flutter UI showing messages within a specific conversation
- **Socket_Service**: Flutter service managing Socket.IO connection and events
- **Auto_Thank_You_Message**: Automated message sent from seller to buyer after checkout
- **Product_Owner**: The user who created/owns a product in the cart

## Requirements

### Requirement 1: Realtime Message Delivery

**User Story:** As a user, I want to send and receive messages in realtime, so that I can have immediate conversations with other users.

#### Acceptance Criteria

1. WHEN a user sends a message to another user, THE System SHALL save the message to the database with sender ID, receiver ID, message content, timestamp, and unread status
2. WHEN a message is saved successfully, THE System SHALL emit the message to the receiver via Socket.IO if the receiver is online
3. WHEN a user receives a message, THE Chat_Detail_Screen SHALL display the message immediately without requiring page refresh
4. WHEN a message is sent, THE System SHALL update the chat status to unread for the receiver
5. WHEN the receiver is offline, THE System SHALL queue the message for delivery when the receiver reconnects

### Requirement 2: Socket Connection Management

**User Story:** As a user, I want my chat connection to be maintained reliably, so that I don't miss messages or experience interruptions.

#### Acceptance Criteria

1. WHEN a user opens the chat feature, THE Socket_Service SHALL establish a Socket.IO connection with the backend
2. WHEN the connection is established, THE Socket_Service SHALL emit an INIT event with the user's ID
3. WHEN the Socket_Handler receives an INIT event, THE System SHALL register the user's connection in the Client_Manager
4. WHEN the connection is lost, THE Socket_Service SHALL attempt reconnection with exponential backoff up to 5 attempts
5. WHEN reconnection succeeds, THE System SHALL sync any missed messages to the user
6. WHEN a user has multiple active sessions, THE System SHALL maintain separate Socket.IO connections for each session

### Requirement 3: Chat List Display

**User Story:** As a user, I want to see all my conversations in one place, so that I can easily access and manage my chats.

#### Acceptance Criteria

1. WHEN a user opens the Chat_List_Screen, THE System SHALL fetch and display all chats where the user is either user1 or user2
2. WHEN displaying chats, THE System SHALL populate each chat with both users' information including name and avatar
3. WHEN a chat has messages, THE System SHALL display the most recent message text and timestamp
4. WHEN a chat has unread messages, THE System SHALL display a visual indicator (gold dot)
5. WHEN a new message arrives for any chat, THE Chat_List_Screen SHALL update the chat's last message and move it to the top of the list
6. WHEN a new chat is created, THE Chat_List_Screen SHALL add it to the top of the list immediately via Socket.IO event

### Requirement 4: Chat Detail and Messaging

**User Story:** As a user, I want to view message history and send new messages in a conversation, so that I can communicate effectively with another user.

#### Acceptance Criteria

1. WHEN a user opens a chat, THE Chat_Detail_Screen SHALL fetch and display all messages between the two users ordered by timestamp
2. WHEN displaying messages, THE System SHALL show sent messages right-aligned with gold background and received messages left-aligned with surface background
3. WHEN a user types a message and presses send, THE Socket_Service SHALL emit a CHAT event with sender ID, receiver ID, and message content
4. WHEN a new message arrives via Socket.IO, THE Chat_Detail_Screen SHALL append it to the message list and scroll to the bottom
5. WHEN a user opens a chat with unread messages, THE System SHALL mark all messages in that chat as read
6. WHEN the message input field is empty, THE System SHALL disable the send button

### Requirement 5: Auto Thank You Message on Checkout

**User Story:** As a buyer, I want to receive thank you messages from sellers after checkout, so that I feel appreciated and can easily contact sellers if needed.

#### Acceptance Criteria

1. WHEN a user completes checkout successfully, THE Bill_Controller SHALL identify all unique product owners from the cart items
2. WHEN processing product owners, THE System SHALL exclude the buyer from the list of recipients
3. FOR each product owner, WHEN a chat does not exist between buyer and seller, THE System SHALL create a new chat and emit a NEW_CHAT event to the buyer
4. FOR each product owner, WHEN a chat already exists, THE System SHALL update the chat status to unread
5. FOR each product owner, THE System SHALL create an auto thank you message with predefined text from the seller to the buyer
6. WHEN auto messages are created, THE System SHALL emit MESSAGE events to the buyer via Socket.IO
7. WHEN auto message processing fails, THE System SHALL log the error but continue with the checkout process

### Requirement 6: Message Read Status

**User Story:** As a user, I want to know when my messages have been read, so that I understand if the other person has seen my communication.

#### Acceptance Criteria

1. WHEN a user opens a chat, THE System SHALL mark all unread messages in that chat as read
2. WHEN messages are marked as read, THE System SHALL update the isRead field to 1 in the database
3. WHEN all messages in a chat are read, THE System SHALL update the chat status to 1
4. WHEN a chat status changes to read, THE System SHALL emit an UPDATE_CHAT event to both users

### Requirement 7: Chat Uniqueness and Bidirectional Lookup

**User Story:** As a system, I want to ensure only one chat exists between any two users, so that conversations are not fragmented across multiple chats.

#### Acceptance Criteria

1. WHEN checking if a chat exists between user1 and user2, THE System SHALL return the same chat as when checking between user2 and user1
2. WHEN creating a new chat, THE System SHALL first check if a chat already exists between the two users in either direction
3. WHEN a chat already exists, THE System SHALL return the existing chat instead of creating a duplicate
4. THE System SHALL enforce a unique constraint on the combination of user1Id and user2Id in the database

### Requirement 8: Message Validation and Security

**User Story:** As a system administrator, I want messages to be validated and secured, so that the system is protected from abuse and malicious content.

#### Acceptance Criteria

1. WHEN a message is sent, THE System SHALL validate that the message content is non-empty and does not exceed 2000 characters
2. WHEN a message is sent, THE System SHALL sanitize HTML and script tags to prevent XSS attacks
3. WHEN a Socket.IO event is received, THE System SHALL validate the user ID from the JWT token, not from client input
4. WHEN a user sends more than 10 messages per minute, THE System SHALL reject additional messages and return a rate limit error
5. WHEN a Socket.IO connection emits more than 100 events per minute, THE System SHALL block the connection

### Requirement 9: Error Handling and Recovery

**User Story:** As a user, I want the system to handle errors gracefully, so that I can continue using the chat feature even when issues occur.

#### Acceptance Criteria

1. WHEN the Socket.IO connection fails, THE Socket_Service SHALL display a "Connecting..." indicator and retry with exponential backoff
2. WHEN a message fails to send, THE Chat_Detail_Screen SHALL display an error indicator on the message with a retry button
3. WHEN the chat list fails to load, THE Chat_List_Screen SHALL display an error message with a retry button
4. WHEN an invalid user ID is received in a Socket.IO event, THE Socket_Handler SHALL log a warning and ignore the event without crashing
5. IF a duplicate chat creation is attempted simultaneously, THEN THE System SHALL use the database unique constraint to prevent duplicates and return the existing chat

### Requirement 10: Performance and Scalability

**User Story:** As a system administrator, I want the chat system to perform efficiently at scale, so that users have a responsive experience even with high usage.

#### Acceptance Criteria

1. WHEN querying messages for a chat, THE System SHALL use database indexes on senderId, receiverId, and dateSent to achieve O(log n) query time
2. WHEN looking up a chat between two users, THE System SHALL use a compound index on user1Id and user2Id to achieve O(log n) lookup time
3. WHEN loading messages in the Chat_Detail_Screen, THE System SHALL fetch messages in batches of 50 using pagination
4. WHEN processing auto thank you messages, THE System SHALL complete within 500ms to avoid blocking the checkout response
5. WHEN displaying the chat list, THE Chat_List_Screen SHALL use lazy loading to render only visible items

### Requirement 11: UI/UX Consistency

**User Story:** As a user, I want the chat interface to match the application's design theme, so that I have a consistent and familiar experience.

#### Acceptance Criteria

1. WHEN displaying the Chat_List_Screen, THE System SHALL use the gold/dark theme with AppColors.surface for cards and AppColors.background for the screen
2. WHEN displaying message bubbles, THE System SHALL use gold background for sent messages and surface background with border for received messages
3. WHEN displaying user names and titles, THE System SHALL use gold color with bold font weight
4. WHEN displaying timestamps and secondary text, THE System SHALL use goldMuted color
5. WHEN showing loading states, THE System SHALL use a gold-colored CircularProgressIndicator

### Requirement 12: Message Ordering and Chronology

**User Story:** As a user, I want messages to appear in chronological order, so that I can follow the conversation flow naturally.

#### Acceptance Criteria

1. WHEN displaying messages in Chat_Detail_Screen, THE System SHALL sort messages by dateSent in ascending order
2. WHEN a new message arrives, THE System SHALL insert it at the correct chronological position based on its timestamp
3. WHEN messages are fetched from the database, THE System SHALL order them by dateSent ascending
4. WHEN displaying the chat list, THE System SHALL order chats by the timestamp of their most recent message in descending order
