// Run with: node --test
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { resolveNotifyTarget } from './resolve_target.mjs';

test('top-level comment notifies the post author', () => {
  const target = resolveNotifyTarget({
    comment: { $id: 'c1', userId: 'commenter', userName: 'Ann', content: 'Nice', postId: 'p1' },
    parentComment: null,
    post: { userId: 'author' },
  });
  assert.equal(target.userId, 'author');
  assert.equal(target.postId, 'p1');
  assert.match(target.title, /commented on your post/);
});

test('reply notifies the parent comment author', () => {
  const target = resolveNotifyTarget({
    comment: { $id: 'c2', userId: 'commenter', userName: 'Bo', content: 'Agreed', postId: 'p1', replyId: 'c1' },
    parentComment: { userId: 'parentAuthor' },
    post: { userId: 'author' },
  });
  assert.equal(target.userId, 'parentAuthor');
  assert.match(target.title, /replied to your comment/);
});

test('self-comment on own post is skipped', () => {
  const target = resolveNotifyTarget({
    comment: { $id: 'c3', userId: 'author', postId: 'p1' },
    parentComment: null,
    post: { userId: 'author' },
  });
  assert.equal(target, null);
});

test('self-reply is skipped', () => {
  const target = resolveNotifyTarget({
    comment: { $id: 'c4', userId: 'me', postId: 'p1', replyId: 'c1' },
    parentComment: { userId: 'me' },
    post: { userId: 'author' },
  });
  assert.equal(target, null);
});

test('missing recipient yields null', () => {
  assert.equal(
    resolveNotifyTarget({ comment: { $id: 'c5', userId: 'x', postId: 'p1' }, parentComment: null, post: null }),
    null,
  );
});

test('long bodies are truncated with an ellipsis', () => {
  const long = 'x'.repeat(300);
  const target = resolveNotifyTarget({
    comment: { $id: 'c6', userId: 'commenter', content: long, postId: 'p1' },
    parentComment: null,
    post: { userId: 'author' },
  });
  assert.ok(target.body.length <= 140);
  assert.ok(target.body.endsWith('…'));
});
