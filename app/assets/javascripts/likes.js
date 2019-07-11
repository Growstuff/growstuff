$(document).ready(function() {
  $('.like-btn').show();

  $('.post-like').on('ajax:success', function(event, data) {
    var like_button = $('#post-' + data.id + ' .post-like');
    var like_badge = $('#post-'+ data.id + ' .like-badge');

    $('#post-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      like_badge.addClass('liked');
      like_button.data('method', 'delete');
      like_button.attr('href', data.url);
      like_button.text('Unlike');
    } else {
      like_badge.removeClass('liked');
      like_button.data('method', 'post');
      like_button.attr('href', '/likes.json?post_id=' + data.id);
      like_button.text('Like');
    }
  });


  $('.photo-like').on('ajax:success', function(event, data) {
    var like_badge = $('#photo-'+ data.id + ' .like-badge');
    var like_button = $('#photo-'+ data.id + ' .like-btn');

    $('#photo-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      like_badge.addClass('liked');
      // Turn the button into an unlike button
      like_button.data('method', 'delete');
      like_button.attr('href', data.url);
    } else {
      like_badge.removeClass('liked');
      // Turn the button into an *like* button
      like_button.data('method', 'post');
      like_button.attr('href', '/likes.json?photo_id=' + data.id);
    }
  });
});
