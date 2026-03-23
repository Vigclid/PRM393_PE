# Requirements Document: Product Comments & Rating

## Introduction

The Product Comments & Rating system enables users to provide structured feedback on products through a comprehensive rating and commenting system. Users can rate products on a 1-5 star scale, write detailed reviews, engage in discussions through replies (with one level of nesting), and view aggregated rating statistics. The system provides transparency for buyers through visible rating distributions and average ratings, while giving sellers valuable feedback on their products. This feature enhances the marketplace by building trust through authentic user reviews and facilitating informed purchase decisions.

## Glossary

- **System**: The Product Comments & Rating backend and frontend application
- **Comment_Service**: Backend service handling comment business logic and data operations
- **Comment_Controller**: Backend controller managing HTTP requests for comment operations
- **Product_Service**: Backend service managing product data and rating aggregation
- **Rating_Widget**: Frontend component displaying and capturing star ratings
- **Comment_List**: Frontend component displaying all comments for a product
- **Comment_Item**: Frontend component displaying individual comment with user info and rating
- **Reply_Form**: Frontend component for creating replies to comments
- **Distribution_Widget**: Frontend component showing rating distribution statistics
- **Top_Level_Comment**: A comment directly on a product (parentCommentId is null)
- **Reply**: A comment responding to another comment (parentCommentId is not null)
- **Rating_Distribution**: Count of reviews for each star level (1-5)
- **Average_Rating**: Mean of all ratings for a product
- **Authenticated_User**: User with valid JWT token
- **Comment_Owner**: User who created a specific comment
- **Product_Owner**: User who created/owns the product being reviewed

## Requirements

### Requirement 1: Create Product Review

**User Story:** As a buyer, I want to rate and review products I've viewed, so that I can share my experience with other potential buyers.

#### Acceptance Criteria

1. WHEN an authenticated user submits a comment with a rating between 1 and 5, THEN THE System SHALL create a new top-level comment with the provided rating and text
2. WHEN a comment is created, THEN THE System SHALL associate it with the authenticated user's ID from the JWT token
3. WHEN a top-level comment is created, THEN THE System SHALL require a rating value between 1 and 5 inclusive
4. WHEN a comment is created, THEN THE System SHALL validate the comment text is between 1 and 2000 characters
5. WHEN a comment is successfully created, THEN THE System SHALL return the comment with populated user information including username and avatar
6. WHEN a comment is created, THEN THE System SHALL set both createdAt and updatedAt timestamps to the current time

### Requirement 2: Update Product Rating Statistics

**User Story:** As a buyer, I want to see accurate aggregate ratings for products, so that I can make informed purchase decisions.

#### Acceptance Criteria

1. WHEN a new comment with rating is created, THEN THE Product_Service SHALL recalculate the product's average rating
2. WHEN a comment rating is updated, THEN THE Product_Service SHALL recalculate the product's average rating
3. WHEN a comment with rating is deleted, THEN THE Product_Service SHALL recalculate the product's average rating
4. WHEN recalculating ratings, THEN THE Product_Service SHALL use MongoDB aggregation to compute the average from all comment ratings
5. WHEN updating product statistics, THEN THE Product_Service SHALL update the rating distribution counts for each star level (1-5)
6. WHEN updating product statistics, THEN THE Product_Service SHALL update the total review count
7. THE Product_Service SHALL ensure average rating is always between 0 and 5 inclusive

### Requirement 3: View Product Comments and Ratings

**User Story:** As a buyer, I want to view all reviews and ratings for a product, so that I can understand other users' experiences before purchasing.

#### Acceptance Criteria

1. WHEN any user requests comments for a product, THEN THE System SHALL return all top-level comments sorted by creation date descending (newest first)
2. WHEN returning comments, THEN THE System SHALL include all replies nested under their parent comments
3. WHEN returning comments, THEN THE System SHALL populate user information for each comment including username and avatar
4. WHEN returning comments, THEN THE System SHALL include rating distribution statistics showing counts for each star level
5. WHEN returning comments, THEN THE System SHALL include the average rating and total review count
6. WHEN pagination parameters are provided, THEN THE System SHALL return the specified page of comments with the specified limit per page
7. THE System SHALL support sorting options including newest, oldest, highest_rated, and lowest_rated

### Requirement 4: Reply to Comments

**User Story:** As a user, I want to reply to product reviews, so that I can ask questions or share additional insights about the product.

#### Acceptance Criteria

1. WHEN an authenticated user submits a reply to a top-level comment, THEN THE System SHALL create a new comment with parentCommentId set to the parent comment's ID
2. WHEN creating a reply, THEN THE System SHALL validate the parent comment exists and has a null parentCommentId
3. WHEN creating a reply, THEN THE System SHALL reject the request if the parent comment already has a non-null parentCommentId (preventing nesting beyond one level)
4. WHEN creating a reply, THEN THE System SHALL not require or accept a rating value
5. WHEN a reply is created, THEN THE System SHALL validate the comment text is between 1 and 2000 characters
6. WHEN fetching comments, THEN THE System SHALL group replies with their parent comments in the response

### Requirement 5: Update Own Comments

**User Story:** As a user, I want to edit my reviews and ratings, so that I can correct mistakes or update my opinion after further product use.

#### Acceptance Criteria

1. WHEN an authenticated user requests to update a comment, THEN THE System SHALL verify the comment's userId matches the authenticated user's ID
2. WHEN a comment owner updates their comment, THEN THE System SHALL allow modification of the comment text
3. WHEN a comment owner updates a top-level comment, THEN THE System SHALL allow modification of the rating value
4. WHEN a comment is updated, THEN THE System SHALL validate the new rating is between 1 and 5 if provided
5. WHEN a comment is updated, THEN THE System SHALL validate the new comment text is between 1 and 2000 characters if provided
6. WHEN a comment is successfully updated, THEN THE System SHALL update the updatedAt timestamp to the current time
7. WHEN a non-owner attempts to update a comment, THEN THE System SHALL return a 403 Forbidden error

### Requirement 6: Delete Own Comments

**User Story:** As a user, I want to delete my reviews, so that I can remove content I no longer want associated with my account.

#### Acceptance Criteria

1. WHEN an authenticated user requests to delete a comment, THEN THE System SHALL verify the comment's userId matches the authenticated user's ID
2. WHEN a comment owner deletes their comment, THEN THE System SHALL remove the comment from the database
3. WHEN a top-level comment is deleted, THEN THE System SHALL also delete all replies to that comment (cascade delete)
4. WHEN a comment is deleted, THEN THE System SHALL return the count of deleted comments including the parent and all replies
5. WHEN a non-owner attempts to delete a comment, THEN THE System SHALL return a 403 Forbidden error
6. WHEN a comment with rating is deleted, THEN THE System SHALL trigger product rating recalculation

### Requirement 7: Display Rating Distribution

**User Story:** As a buyer, I want to see the distribution of ratings across all star levels, so that I can understand the range of opinions about a product.

#### Acceptance Criteria

1. WHEN any user requests rating distribution for a product, THEN THE System SHALL return counts for each star level from 1 to 5
2. WHEN calculating distribution, THEN THE System SHALL only count top-level comments with ratings (not replies)
3. WHEN returning distribution, THEN THE System SHALL include the total review count
4. WHEN returning distribution, THEN THE System SHALL include the average rating
5. THE Distribution_Widget SHALL display a bar chart showing the percentage and count for each star level
6. THE Distribution_Widget SHALL use the gold theme color (#D4AF37) for the rating bars

### Requirement 8: Interactive Rating Input

**User Story:** As a user, I want to easily select a star rating when writing a review, so that I can quickly express my satisfaction level.

#### Acceptance Criteria

1. WHEN creating a top-level comment, THEN THE Rating_Widget SHALL display 5 interactive stars for rating selection
2. WHEN a user taps on a star, THEN THE Rating_Widget SHALL fill all stars up to and including the tapped star
3. WHEN a user selects a rating, THEN THE Rating_Widget SHALL use the gold theme color (#D4AF37) for filled stars
4. WHEN displaying an existing rating, THEN THE Rating_Widget SHALL show the appropriate number of filled stars in read-only mode
5. WHEN displaying a decimal rating, THEN THE Rating_Widget SHALL show half-filled stars for fractional values
6. WHEN creating a reply, THEN THE System SHALL not display the rating input widget

### Requirement 9: Authentication and Authorization

**User Story:** As a system administrator, I want to ensure only authenticated users can create, update, or delete comments, so that we maintain accountability and prevent abuse.

#### Acceptance Criteria

1. WHEN a user attempts to create a comment without a valid JWT token, THEN THE System SHALL return a 401 Unauthorized error
2. WHEN a user attempts to update a comment without a valid JWT token, THEN THE System SHALL return a 401 Unauthorized error
3. WHEN a user attempts to delete a comment without a valid JWT token, THEN THE System SHALL return a 401 Unauthorized error
4. WHEN a user attempts to create a reply without a valid JWT token, THEN THE System SHALL return a 401 Unauthorized error
5. WHEN processing authenticated requests, THEN THE System SHALL extract the user ID from the JWT token payload
6. WHEN viewing comments, THEN THE System SHALL allow access without authentication (public endpoint)
7. WHEN viewing rating distribution, THEN THE System SHALL allow access without authentication (public endpoint)

### Requirement 10: Input Validation and Sanitization

**User Story:** As a system administrator, I want all user inputs validated and sanitized, so that we prevent security vulnerabilities and maintain data quality.

#### Acceptance Criteria

1. WHEN a comment is submitted, THEN THE System SHALL sanitize HTML and script tags to prevent XSS attacks
2. WHEN a rating is submitted, THEN THE System SHALL validate it is an integer between 1 and 5 inclusive
3. WHEN a comment text is submitted, THEN THE System SHALL validate it is not empty after trimming whitespace
4. WHEN a comment text is submitted, THEN THE System SHALL validate it does not exceed 2000 characters
5. WHEN a productId is provided, THEN THE System SHALL validate it is a valid MongoDB ObjectId format
6. WHEN a commentId is provided, THEN THE System SHALL validate it is a valid MongoDB ObjectId format
7. WHEN validation fails, THEN THE System SHALL return a 400 Bad Request error with a descriptive error message

### Requirement 11: Rate Limiting and Abuse Prevention

**User Story:** As a system administrator, I want to limit the rate of comment creation, so that we prevent spam and abuse of the system.

#### Acceptance Criteria

1. WHEN a user creates comments, THEN THE System SHALL limit them to a maximum of 10 comments per minute
2. WHEN a user creates comments, THEN THE System SHALL limit them to a maximum of 50 comments per hour
3. WHEN a user creates replies, THEN THE System SHALL limit them to a maximum of 20 replies per minute
4. WHEN rate limits are exceeded, THEN THE System SHALL return a 429 Too Many Requests error
5. WHEN tracking rate limits, THEN THE System SHALL identify users by their JWT token user ID
6. THE System SHALL implement IP-based rate limiting for public endpoints to prevent anonymous abuse

### Requirement 12: Performance Optimization

**User Story:** As a user, I want the comment system to load quickly, so that I can efficiently browse product reviews.

#### Acceptance Criteria

1. WHEN fetching comments for a product, THEN THE System SHALL return results in less than 200ms for 20 comments
2. WHEN creating a comment, THEN THE System SHALL complete the operation in less than 150ms
3. WHEN updating a comment, THEN THE System SHALL complete the operation in less than 100ms
4. WHEN deleting a comment, THEN THE System SHALL complete the operation in less than 100ms
5. WHEN fetching rating distribution, THEN THE System SHALL return results in less than 50ms when cached
6. THE System SHALL implement pagination with a default limit of 20 comments per page
7. THE System SHALL use database indexes on productId, parentCommentId, and (productId, createdAt) for query optimization

### Requirement 13: Comment Display and Formatting

**User Story:** As a user, I want comments to be clearly formatted and easy to read, so that I can quickly understand other users' opinions.

#### Acceptance Criteria

1. WHEN displaying a comment, THEN THE Comment_Item SHALL show the user's username and avatar
2. WHEN displaying a comment, THEN THE Comment_Item SHALL show the rating as filled stars if present
3. WHEN displaying a comment, THEN THE Comment_Item SHALL show the comment text
4. WHEN displaying a comment, THEN THE Comment_Item SHALL show the creation timestamp in a human-readable format
5. WHEN displaying a top-level comment with replies, THEN THE Comment_Item SHALL show the reply count
6. WHEN displaying a top-level comment with replies, THEN THE Comment_Item SHALL provide expand/collapse functionality for replies
7. WHEN displaying a comment owned by the current user, THEN THE Comment_Item SHALL show edit and delete action buttons
8. WHEN displaying a reply, THEN THE Comment_Item SHALL visually indent it to indicate nesting level

### Requirement 14: Error Handling and User Feedback

**User Story:** As a user, I want clear error messages when something goes wrong, so that I understand what happened and how to fix it.

#### Acceptance Criteria

1. WHEN a user submits an invalid rating, THEN THE System SHALL return an error message stating "Rating must be an integer between 1 and 5"
2. WHEN a user attempts to modify another user's comment, THEN THE System SHALL return an error message stating "You can only modify your own comments"
3. WHEN a user attempts to reply to a reply, THEN THE System SHALL return an error message stating "Cannot reply to a reply. Please reply to the original comment."
4. WHEN a comment references a non-existent product, THEN THE System SHALL return an error message stating "Product not found"
5. WHEN a comment exceeds the character limit, THEN THE System SHALL return an error message stating "Comment must be 2000 characters or less"
6. WHEN a network error occurs during submission, THEN THE System SHALL display an error message and preserve the user's input for retry
7. WHEN an error occurs, THEN THE System SHALL return appropriate HTTP status codes (400 for validation, 401 for auth, 403 for authorization, 404 for not found, 429 for rate limit, 500 for server errors)

### Requirement 15: Data Consistency and Integrity

**User Story:** As a system administrator, I want rating calculations to remain accurate even under concurrent operations, so that users see reliable product ratings.

#### Acceptance Criteria

1. WHEN multiple users rate a product simultaneously, THEN THE System SHALL use atomic operations to prevent race conditions
2. WHEN calculating average ratings, THEN THE System SHALL use MongoDB aggregation pipelines to ensure accuracy
3. WHEN updating rating statistics, THEN THE System SHALL ensure the sum of rating distribution counts equals the total review count
4. WHEN a comment is created, THEN THE System SHALL verify the referenced product exists before saving
5. WHEN a reply is created, THEN THE System SHALL verify the parent comment exists before saving
6. THE System SHALL ensure updatedAt timestamp is always greater than or equal to createdAt timestamp
7. THE System SHALL ensure average rating is always between 0 and 5 inclusive

### Requirement 16: Frontend State Management

**User Story:** As a user, I want the interface to update immediately when I perform actions, so that the application feels responsive.

#### Acceptance Criteria

1. WHEN a user creates a comment, THEN THE System SHALL optimistically add it to the comment list before server confirmation
2. WHEN a user deletes a comment, THEN THE System SHALL immediately remove it from the UI before server confirmation
3. WHEN a user updates a comment, THEN THE System SHALL immediately show the changes in the UI before server confirmation
4. WHEN a server operation fails, THEN THE System SHALL revert the optimistic update and display an error message
5. WHEN loading comments, THEN THE System SHALL display a loading skeleton animation
6. WHEN the comment list is empty, THEN THE System SHALL display an appropriate empty state message
7. WHEN expanding replies, THEN THE System SHALL use local state to avoid unnecessary API calls

### Requirement 17: Pagination and Infinite Scroll

**User Story:** As a user, I want to load comments progressively as I scroll, so that I don't have to wait for all comments to load at once.

#### Acceptance Criteria

1. WHEN a user opens a product detail page, THEN THE System SHALL load the first 20 comments
2. WHEN a user scrolls to the bottom of the comment list, THEN THE System SHALL automatically load the next 20 comments
3. WHEN loading additional comments, THEN THE System SHALL display a loading indicator at the bottom of the list
4. WHEN all comments have been loaded, THEN THE System SHALL not attempt to load more
5. WHEN pagination metadata is returned, THEN THE System SHALL include currentPage, totalPages, totalComments, and hasMore fields
6. THE System SHALL maintain scroll position when new comments are loaded

### Requirement 18: Character Count and Input Feedback

**User Story:** As a user, I want to see how many characters I have remaining when writing a comment, so that I don't exceed the limit.

#### Acceptance Criteria

1. WHEN a user types in the comment input field, THEN THE System SHALL display the current character count
2. WHEN a user types in the comment input field, THEN THE System SHALL display the remaining characters until the 2000 character limit
3. WHEN the character count exceeds 2000, THEN THE System SHALL disable the submit button
4. WHEN the character count exceeds 2000, THEN THE System SHALL display the counter in a warning color
5. WHEN the comment input is empty, THEN THE System SHALL disable the submit button
6. THE Reply_Form SHALL also display character count and enforce the same 2000 character limit

### Requirement 19: Database Indexing and Query Optimization

**User Story:** As a system administrator, I want efficient database queries, so that the system performs well as data grows.

#### Acceptance Criteria

1. THE System SHALL create an index on the productId field in the comments collection
2. THE System SHALL create an index on the parentCommentId field in the comments collection
3. THE System SHALL create a compound index on (productId, createdAt) fields in the comments collection
4. THE System SHALL create an index on the userId field in the comments collection
5. WHEN populating user data, THEN THE System SHALL only select username and avatar fields (not the entire user document)
6. WHEN fetching comments, THEN THE System SHALL use lean queries when full Mongoose documents are not needed
7. THE System SHALL monitor index usage and query performance metrics

### Requirement 20: Security Headers and CORS

**User Story:** As a system administrator, I want proper security headers and CORS configuration, so that the API is protected from common web vulnerabilities.

#### Acceptance Criteria

1. THE System SHALL implement CORS middleware to control cross-origin requests
2. THE System SHALL use Helmet middleware to set security-related HTTP headers
3. THE System SHALL compress API responses using gzip compression
4. THE System SHALL validate JWT token signatures on all protected endpoints
5. THE System SHALL reject expired JWT tokens with a 401 Unauthorized error
6. THE System SHALL store sensitive configuration (database URLs, JWT secrets) in environment variables
7. THE System SHALL use encrypted connections (TLS/SSL) for database communication

