$(document).ready(function() {
  $('.post-like').show();

  $('.post-like').on('ajax:success', function(event, data) {
    var likeControl = $('#post-' + data.id + ' .post-like');

    $('#post-' + data.id + ' .like-count').text(data.description);
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
});
