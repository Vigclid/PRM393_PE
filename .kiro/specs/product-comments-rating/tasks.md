# Implementation Plan: Product Comments & Rating

## Overview

This implementation plan breaks down the Product Comments & Rating feature into discrete coding tasks. The feature enables users to rate products (1-5 stars), write reviews, reply to comments (1-level nesting), and view rating statistics. The implementation follows the existing TypeScript/Express/MongoDB backend architecture and Flutter/Dart frontend patterns, maintaining the gold (#D4AF37) theme.

## Tasks

- [ ] 1. Backend - Database models and schema
  - [x] 1.1 Create ProductComment model with schema and validation
    - Create `PE_Backend/src/modules/product-comments/product-comment.model.ts`
    - Define IProductComment interface with fields: productId, userId, rating, comment, parentCommentId, createdAt, updatedAt
    - Implement Mongoose schema with validation rules (rating 1-5, comment 1-2000 chars)
    - Add indexes on productId, parentCommentId, and compound (productId, createdAt)
    - Export model and interface
    - _Requirements: 1.1, 1.3, 1.4, 1.6, 10.2, 10.3, 10.4, 19.1, 19.2, 19.3_
  
  - [ ]* 1.2 Write property test for ProductComment model validation
    - **Property 1: Valid Rating Bounds** - Rating must be 1-5 inclusive
    - **Property 2: Comment Text Length Validation** - Text must be 1-2000 chars after trimming
    - **Validates: Requirements 1.3, 1.4, 5.4, 5.5, 10.2, 10.3, 10.4**
  
  - [x] 1.3 Extend Product model with rating fields
    - Update `PE_Backend/src/modules/products/product.model.ts`
    - Add fields: averageRating (Number, default 0), totalReviews (Number, default 0)
    - Add ratingDistribution object with keys 1-5 (all default 0)
    - Update IProduct interface
    - _Requirements: 2.1, 2.2, 2.3, 2.5, 2.6_
  
  - [ ]* 1.4 Write property test for Product rating fields
    - **Property 7: Average Rating Bounds Invariant** - averageRating must be 0-5
    - **Property 8: Rating Distribution Consistency** - Sum of distribution must equal totalReviews
    - **Validates: Requirements 2.7, 15.3, 15.7**

- [ ] 2. Backend - Service layer for comment operations
  - [x] 2.1 Create CommentService with CRUD methods
    - Create `PE_Backend/src/modules/product-comments/product-comment.service.ts`
    - Implement createComment(data) - validates and saves comment with rating
    - Implement getCommentsByProductId(productId, options) - fetches with pagination and sorting
    - Implement updateComment(commentId, userId, data) - validates ownership and updates
    - Implement deleteComment(commentId, userId) - validates ownership and cascade deletes replies
    - Implement createReply(parentId, data) - validates nesting depth and creates reply
    - _Requirements: 1.1, 1.2, 3.1, 3.2, 4.1, 4.2, 5.1, 5.2, 6.1, 6.2_
  
  - [ ]* 2.2 Write property tests for comment CRUD operations
    - **Property 3: User Association Correctness** - userId must match JWT token
    - **Property 4: Timestamp Initialization** - createdAt equals updatedAt at creation
    - **Property 5: Timestamp Ordering Invariant** - updatedAt >= createdAt always
    - **Property 6: Update Timestamp Modification** - updatedAt changes on update
    - **Validates: Requirements 1.2, 1.6, 5.6, 15.6**
  
  - [x] 2.3 Implement reply nesting validation and grouping
    - Add validateReplyDepth(parentId) method to check parent has null parentCommentId
    - Add groupRepliesWithParents(comments) method to nest replies under parents
    - Reject replies to replies with appropriate error
    - _Requirements: 4.2, 4.3, 3.2, 4.6_
  
  - [ ]* 2.4 Write property tests for reply nesting
    - **Property 12: Reply Nesting Depth Constraint** - Max 1-level nesting
    - **Property 13: Reply Rating Prohibition** - Replies cannot have ratings
    - **Property 17: Reply Grouping Completeness** - All replies nested under parents
    - **Validates: Requirements 4.2, 4.3, 4.4, 3.2, 4.6**
  
  - [x] 2.5 Implement cascade delete for replies
    - Add deleteCommentWithReplies(commentId) method
    - Find and delete all comments with parentCommentId matching deleted comment
    - Return count of deleted comments (parent + replies)
    - _Requirements: 6.3, 6.4_
  
  - [ ]* 2.6 Write property test for cascade delete
    - **Property 14: Cascade Delete Completeness** - All replies deleted with parent
    - **Property 15: Delete Count Accuracy** - deletedCount = 1 + reply count
    - **Validates: Requirements 6.3, 6.4**

- [ ] 3. Backend - Rating calculation and product updates
  - [x] 3.1 Implement rating calculation service methods
    - Add calculateAverageRating(productId) method using MongoDB aggregation
    - Add calculateRatingDistribution(productId) method to count each star level
    - Add updateProductRating(productId) method to recalculate and save to Product
    - Ensure atomic updates to prevent race conditions
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_
  
  - [ ]* 3.2 Write property tests for rating calculations
    - **Property 9: Rating Recalculation on Create** - Rating updates when comment created
    - **Property 10: Rating Recalculation on Update** - Rating updates when comment updated
    - **Property 11: Rating Recalculation on Delete** - Rating updates when comment deleted
    - **Validates: Requirements 2.1, 2.2, 2.3, 6.6**
  
  - [x] 3.3 Integrate rating updates with comment operations
    - Call updateProductRating after createComment (if rating provided)
    - Call updateProductRating after updateComment (if rating changed)
    - Call updateProductRating after deleteComment (if comment had rating)
    - Handle errors gracefully without blocking comment operations
    - _Requirements: 2.1, 2.2, 2.3, 6.6_

- [x] 4. Checkpoint - Ensure backend service layer tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Backend - Controller layer and request handling
  - [x] 5.1 Create CommentController with endpoint handlers
    - Create `PE_Backend/src/modules/product-comments/product-comment.controller.ts`
    - Implement createComment(req, res) - extracts userId from JWT, validates input, calls service
    - Implement getCommentsByProduct(req, res) - handles query params, calls service, formats response
    - Implement updateComment(req, res) - validates ownership, calls service
    - Implement deleteComment(req, res) - validates ownership, calls service
    - Implement replyToComment(req, res) - validates parent exists, calls service
    - Implement getRatingDistribution(req, res) - calls service, returns stats
    - Use ApiResponseWrapper for consistent responses
    - _Requirements: 1.1, 1.2, 3.1, 3.6, 3.7, 5.1, 6.1, 7.1_
  
  - [ ]* 5.2 Write unit tests for controller methods
    - Test successful comment creation with valid data
    - Test error handling for invalid rating values
    - Test ownership verification for updates and deletes
    - Test reply nesting depth validation
    - _Requirements: 1.3, 5.1, 5.7, 6.1, 6.5, 4.3_
  
  - [x] 5.3 Implement input validation middleware
    - Create validation rules for createComment (productId, rating 1-5, comment 1-2000 chars)
    - Create validation rules for updateComment (optional rating 1-5, optional comment 1-2000 chars)
    - Create validation rules for createReply (comment 1-2000 chars, no rating)
    - Sanitize HTML/script tags to prevent XSS
    - Validate MongoDB ObjectId format for IDs
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_
  
  - [ ]* 5.4 Write property tests for input validation
    - **Property 26: XSS Prevention through Sanitization** - HTML/script tags sanitized
    - **Property 27: ObjectId Format Validation** - IDs must be valid ObjectId format
    - **Property 28: Validation Error Response Format** - 400 with descriptive message
    - **Validates: Requirements 10.1, 10.5, 10.6, 10.7**

- [ ] 6. Backend - Routes and middleware
  - [x] 6.1 Create comment routes
    - Create `PE_Backend/src/modules/product-comments/product-comment.routes.ts`
    - POST /api/comments - create comment (auth required)
    - GET /api/comments/product/:productId - get comments (public)
    - PUT /api/comments/:id - update comment (auth required)
    - DELETE /api/comments/:id - delete comment (auth required)
    - POST /api/comments/:id/reply - create reply (auth required)
    - GET /api/comments/product/:productId/distribution - get rating stats (public)
    - Apply authMiddleware to protected routes
    - Apply validation middleware to all routes
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6, 9.7_
  
  - [x] 6.2 Implement rate limiting for comment endpoints
    - Add rate limit: 10 comments per minute per user for POST /api/comments
    - Add rate limit: 50 comments per hour per user for POST /api/comments
    - Add rate limit: 20 replies per minute per user for POST /api/comments/:id/reply
    - Return 429 Too Many Requests when exceeded
    - Use existing rateLimitMiddleware pattern
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [x] 6.3 Register routes in main application
    - Import product-comment.routes in main routes file
    - Mount routes at /api/comments path
    - Ensure proper middleware order (auth, validation, rate limit)
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 7. Backend - Integration tests
  - [ ]* 7.1 Write end-to-end comment flow integration tests
    - Test complete flow: create user/product → create comment → verify rating updated → fetch comments → update comment → delete comment
    - Test reply flow: create parent → create reply → verify nesting → delete parent → verify cascade
    - Test authentication flow: create without token (fail) → create with token (success) → update other's comment (fail)
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 9.1, 9.2_
  
  - [ ]* 7.2 Write pagination and sorting integration tests
    - Create 50 comments and test pagination with limit 20
    - Test different sort options (newest, oldest, highest_rated, lowest_rated)
    - Verify pagination metadata correctness
    - _Requirements: 3.6, 3.7, 17.1, 17.2, 17.5_

- [x] 8. Checkpoint - Ensure all backend tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Frontend - Data models and API client
  - [x] 9.1 Create Comment model class
    - Create `pe_frontend/lib/models/comment.dart`
    - Define Comment class with fields: id, productId, user, rating, comment, parentCommentId, createdAt, updatedAt, replies
    - Implement fromJson factory constructor
    - Implement toJson method
    - Add helper getters: isReply, hasRating
    - _Requirements: 3.2, 3.3, 4.1_
  
  - [x] 9.2 Create RatingDistribution model class
    - Create `pe_frontend/lib/models/rating_distribution.dart`
    - Define RatingDistribution class with fields: distribution (Map<int, int>), totalReviews, averageRating
    - Implement fromJson factory constructor
    - Add helper methods: getCount(stars), getPercentage(stars)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [x] 9.3 Create CommentApi service
    - Create `pe_frontend/lib/api/comment_api.dart`
    - Implement createComment(productId, rating, comment) - POST /api/comments
    - Implement getCommentsByProduct(productId, page, limit, sort) - GET /api/comments/product/:productId
    - Implement updateComment(commentId, rating, comment) - PUT /api/comments/:id
    - Implement deleteComment(commentId) - DELETE /api/comments/:id
    - Implement replyToComment(parentId, comment) - POST /api/comments/:id/reply
    - Implement getRatingDistribution(productId) - GET /api/comments/product/:productId/distribution
    - Handle authentication headers (JWT token)
    - Parse responses and handle errors
    - _Requirements: 1.1, 3.1, 4.1, 5.1, 6.1, 7.1, 9.1, 9.2, 9.3, 9.4_

- [ ] 10. Frontend - Rating widget
  - [ ] 10.1 Create RatingWidget for display and input
    - Create `pe_frontend/lib/widgets/rating_widget.dart`
    - Accept parameters: rating (double), interactive (bool), onRatingChanged callback, size, color
    - Display 5 stars with appropriate fill (full, half, empty) based on rating value
    - In interactive mode, handle tap events to select rating
    - Use gold theme color (#D4AF37) for filled stars
    - In read-only mode, disable interaction
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [ ]* 10.2 Write widget tests for RatingWidget
    - Test correct star display for integer ratings (1-5)
    - Test half-star display for decimal ratings (e.g., 3.5)
    - Test interactive mode tap handling
    - Test read-only mode disables interaction
    - Test gold color applied to filled stars
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 11. Frontend - Comment display widgets
  - [ ] 11.1 Create CommentItemWidget
    - Create `pe_frontend/lib/widgets/comment_item_widget.dart`
    - Accept parameters: comment, replies, isReply, onReply, onDelete, onEdit callbacks
    - Display user avatar and username
    - Display rating stars if comment has rating (using RatingWidget)
    - Display comment text
    - Display timestamp in human-readable format (using intl package)
    - Show reply count and expand/collapse button for top-level comments with replies
    - Show edit/delete buttons only if comment belongs to current user
    - Apply visual indentation for replies
    - Use gold theme for interactive elements
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8_
  
  - [ ]* 11.2 Write widget tests for CommentItemWidget
    - Test user info display (username, avatar)
    - Test rating display for comments with ratings
    - Test no rating display for replies
    - Test edit/delete button visibility based on ownership
    - Test reply count display
    - Test visual indentation for replies
    - _Requirements: 13.1, 13.2, 13.3, 13.7, 13.8_
  
  - [ ] 11.3 Create CommentListWidget
    - Create `pe_frontend/lib/widgets/comment_list_widget.dart`
    - Accept parameters: productId, comments, onReply, onDelete, onEdit, onLoadMore callbacks
    - Render list of CommentItemWidget components
    - Implement infinite scroll with loading indicator at bottom
    - Handle empty state with appropriate message
    - Handle loading state with skeleton animation
    - Handle error state with retry button
    - Sort comments by newest first
    - _Requirements: 3.1, 16.5, 16.6, 17.1, 17.2, 17.3_
  
  - [ ]* 11.4 Write widget tests for CommentListWidget
    - Test comment list rendering
    - Test empty state display
    - Test loading state display
    - Test error state display
    - Test infinite scroll trigger
    - _Requirements: 16.5, 16.6, 17.1, 17.2_

- [ ] 12. Frontend - Reply form widget
  - [ ] 12.1 Create ReplyFormWidget
    - Create `pe_frontend/lib/widgets/reply_form_widget.dart`
    - Accept parameters: parentCommentId, onSubmit, onCancel callbacks
    - Provide text input field for reply text
    - Display character counter (current / 2000)
    - Validate minimum length (1 char) and maximum length (2000 chars)
    - Disable submit button when empty or exceeds limit
    - Show warning color when approaching/exceeding limit
    - Display loading indicator during submission
    - Clear form after successful submission
    - Show cancel button to close form
    - _Requirements: 4.5, 18.1, 18.2, 18.3, 18.4, 18.5, 18.6_
  
  - [ ]* 12.2 Write widget tests for ReplyFormWidget
    - Test character counter display
    - Test submit button disabled when empty
    - Test submit button disabled when exceeds 2000 chars
    - Test warning color when limit exceeded
    - Test form clears after submission
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

- [ ] 13. Frontend - Rating distribution widget
  - [ ] 13.1 Create RatingDistributionWidget
    - Create `pe_frontend/lib/widgets/rating_distribution_widget.dart`
    - Accept parameters: distribution (Map<int, int>), totalReviews, averageRating
    - Display average rating prominently with RatingWidget
    - Display total review count
    - Display horizontal bar chart for each star level (5 to 1)
    - Show percentage and count for each star level
    - Use gold theme color (#D4AF37) for bars
    - Handle zero reviews case gracefully
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_
  
  - [ ]* 13.2 Write widget tests for RatingDistributionWidget
    - Test average rating display
    - Test total review count display
    - Test bar chart rendering for each star level
    - Test percentage calculation correctness
    - Test zero reviews case handling
    - Test gold theme color applied
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ] 14. Checkpoint - Ensure frontend widget tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Frontend - Comment creation form
  - [ ] 15.1 Create CommentFormWidget for new comments
    - Create `pe_frontend/lib/widgets/comment_form_widget.dart`
    - Accept parameters: productId, onSubmit callback
    - Display interactive RatingWidget for rating selection (required)
    - Provide text input field for comment text
    - Display character counter (current / 2000)
    - Validate rating selected (1-5) and comment text (1-2000 chars)
    - Disable submit button when validation fails
    - Show loading indicator during submission
    - Clear form after successful submission
    - Display error messages for validation failures
    - _Requirements: 1.1, 1.3, 1.4, 8.1, 8.2, 18.1, 18.2, 18.3, 18.4, 18.5_
  
  - [ ]* 15.2 Write widget tests for CommentFormWidget
    - Test rating selection required
    - Test comment text validation (min/max length)
    - Test character counter display
    - Test submit button disabled when invalid
    - Test form clears after submission
    - _Requirements: 1.3, 1.4, 18.1, 18.2, 18.3, 18.4_

- [ ] 16. Frontend - State management for comments
  - [ ] 16.1 Create CommentProvider for state management
    - Create `pe_frontend/lib/providers/comment_provider.dart`
    - Use ChangeNotifier for state management
    - Maintain state: comments list, loading, error, hasMore, currentPage
    - Implement loadComments(productId) method
    - Implement loadMoreComments() method for pagination
    - Implement createComment(productId, rating, comment) with optimistic update
    - Implement updateComment(commentId, rating, comment) with optimistic update
    - Implement deleteComment(commentId) with optimistic update
    - Implement createReply(parentId, comment) with optimistic update
    - Revert optimistic updates on error
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 17.1, 17.2_
  
  - [ ]* 16.2 Write unit tests for CommentProvider
    - Test loadComments updates state correctly
    - Test optimistic update for createComment
    - Test optimistic update rollback on error
    - Test pagination state management
    - _Requirements: 16.1, 16.2, 16.3, 16.4_

- [ ] 17. Frontend - Extend ProductDetailScreen
  - [ ] 17.1 Add comments section to ProductDetailScreen
    - Locate existing `pe_frontend/lib/screens/product_detail_screen.dart`
    - Add CommentProvider to screen
    - Display RatingDistributionWidget at top of comments section
    - Display CommentFormWidget for creating new comments (if authenticated)
    - Display CommentListWidget with all comments
    - Load comments when screen opens
    - Handle reply button tap to show ReplyFormWidget
    - Handle edit button tap to show edit dialog
    - Handle delete button tap with confirmation dialog
    - Show loading state while fetching comments
    - Show error state with retry button
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.1, 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_
  
  - [ ] 17.2 Implement comment edit functionality
    - Create edit dialog with pre-filled rating and comment text
    - Allow editing rating and comment text
    - Validate input same as create
    - Call updateComment API on submit
    - Update UI optimistically
    - Show error message on failure
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  
  - [ ] 17.3 Implement comment delete functionality
    - Show confirmation dialog before delete
    - Call deleteComment API on confirm
    - Remove comment from UI optimistically
    - Show error message on failure
    - Display count of deleted items (parent + replies)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ] 17.4 Implement reply functionality
    - Show ReplyFormWidget inline when reply button tapped
    - Call createReply API on submit
    - Add reply to parent comment's replies list optimistically
    - Increment reply count
    - Show error message on failure
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 18. Frontend - Error handling and user feedback
  - [ ] 18.1 Implement error message display
    - Show snackbar/toast for API errors
    - Display specific error messages for validation failures
    - Show "Rating must be between 1 and 5" for invalid rating
    - Show "You can only modify your own comments" for ownership errors
    - Show "Cannot reply to a reply" for nesting errors
    - Show "Product not found" for missing product
    - Show "Comment must be 2000 characters or less" for length errors
    - Show "Network error. Please check your connection." for network failures
    - Preserve user input on error for retry
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_
  
  - [ ]* 18.2 Write integration tests for error handling
    - Test error message display for each error type
    - Test input preservation on error
    - Test retry functionality after network error
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [ ] 19. Frontend - Integration tests
  - [ ]* 19.1 Write end-to-end comment flow integration tests
    - Test complete flow: open product → view comments → create comment → verify appears in list → edit comment → delete comment
    - Test reply flow: create comment → tap reply → submit reply → verify nested under parent
    - Test authentication: attempt to create without login → verify redirected/error
    - _Requirements: 1.1, 3.1, 4.1, 5.1, 6.1, 9.1_
  
  - [ ]* 19.2 Write pagination integration tests
    - Test initial load of 20 comments
    - Test scroll to bottom triggers load more
    - Test loading indicator display
    - Test hasMore flag prevents unnecessary loads
    - _Requirements: 17.1, 17.2, 17.3, 17.4_

- [ ] 20. Final checkpoint - Ensure all tests pass and feature is complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Backend uses TypeScript/Express/MongoDB with existing patterns
- Frontend uses Flutter/Dart with provider for state management
- Gold theme color (#D4AF37) used throughout for consistency
- Property-based tests validate universal correctness properties
- Unit and integration tests validate specific examples and flows
- Checkpoints ensure incremental validation at key milestones
