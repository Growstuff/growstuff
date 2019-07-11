$(document).ready(function() {
  $('.like-btn').show();

  $('.post-like').on('ajax:success', function(event, data) {
    var likeControl = $('#post-' + data.id + ' .post-like');

    $('#post-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      likeControl.data('method', 'delete');
      likeControl.attr('href', data.url);
      likeControl.text('Unlike');
    } else {
      likeControl.data('method', 'post');
      likeControl.attr('href', '/likes.json?post_id=' + data.id);
      likeControl.text('Like');
    }
  });


  $('.photo-like').on('ajax:success', function(event, data) {
    var like_badge = $('#photo-'+ data.id + ' .like-badge');
    var like_count = $('#photo-'+ data.id + ' .like-count');
    var like_button = $('#photo-'+ data.id + ' .like-btn');

    $('#photo-' + data.id + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      like_badge.addClass('liked');
      // Turn the button into an unlike button
      like_button.data('method', 'delete');
      like_button.attr('href', data.url);
      like_button.text('Unlike');
    } else {
      like_badge.removeClass('liked');
      // Turn the button into an *like* button
      like_button.data('method', 'post');
      like_button.attr('href', '/likes.json?photo_id=' + data.id);
      like_button.text('Like');
    }
  });
});
