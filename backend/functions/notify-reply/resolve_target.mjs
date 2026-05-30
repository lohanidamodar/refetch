/**
 * Pure logic for deciding who to notify about a new comment, and with what
 * text. Kept dependency-free so it can be unit-tested without Appwrite.
 *
 * @param {object} args
 * @param {{ $id: string, userId: string, userName?: string, content?: string, postId?: string, replyId?: string }} args.comment
 *        The newly created comment.
 * @param {{ userId: string } | null} args.parentComment
 *        The comment being replied to, if `comment.replyId` is set.
 * @param {{ userId: string, title?: string } | null} args.post
 *        The post the comment belongs to.
 * @returns {{ userId: string, title: string, body: string, postId: string } | null}
 *          The notification to send, or null when no one should be notified
 *          (e.g. replying to yourself).
 */
export function resolveNotifyTarget({ comment, parentComment, post }) {
  if (!comment) return null;

  // A reply to a comment notifies that comment's author; a top-level comment
  // notifies the post's author.
  const recipientUserId = comment.replyId
    ? parentComment?.userId
    : post?.userId;

  if (!recipientUserId) return null;

  // Never notify someone about their own comment.
  if (recipientUserId === comment.userId) return null;

  const postId = comment.postId ?? '';
  if (!postId) return null;

  const author = (comment.userName || 'Someone').trim();
  const snippet = excerpt(comment.content || '', 140);

  const title = comment.replyId
    ? `${author} replied to your comment`
    : `${author} commented on your post`;

  return { userId: recipientUserId, title, body: snippet, postId };
}

function excerpt(text, max) {
  const clean = text.replace(/\s+/g, ' ').trim();
  if (clean.length <= max) return clean;
  return `${clean.slice(0, max - 1).trimEnd()}…`;
}
