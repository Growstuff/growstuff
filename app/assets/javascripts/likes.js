$(document).ready(function() {
  $('.like-btn').show();

  $('.post-like').on('ajax:success', function(event, data) {
    var likeButton = $('#post-' + data.id + ' .post-like');
    var likeBadge = $('#post-'+ data.id + ' .like-badge');

    $('#post-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      likeBadge.addClass('liked');
      likeButton.data('method', 'delete');
      likeButton.attr('href', data.url);
      likeButton.text('Unlike');
    } else {
      likeBadge.removeClass('liked');
      likeButton.data('method', 'post');
      likeButton.attr('href', '/likes.json?type=Post&id=' + data.id);
      likeButton.text('Like');
    }
  });


  $('.photo-like').on('ajax:success', function(event, data) {
    var likeBadge = $('#photo-'+ data.id + ' .like-badge');
    var likeButton = $('#photo-'+ data.id + ' .like-btn');

    $('#photo-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      likeBadge.addClass('liked');
      // Turn the button into an unlike button
      likeButton.data('method', 'delete');
      likeButton.attr('href', data.url);
    } else {
      likeBadge.removeClass('liked');
      // Turn the button into an *like* button
      likeButton.data('method', 'post');
      likeButton.attr('href', '/likes.json?type=Photo&id=' + data.id);
    }
  });
});
