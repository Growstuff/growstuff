$(document).ready(function () {
  $('.post-like').show();

  $('.post-like').on('ajax:success', function(event, data) {
    var like_control = $('#post-' + data.id + ' .post-like');

    $('#post-' + data.id + ' .like-count').text(data.description);
    if (data.liked_by_member) {
      like_control.data("method", "delete");
      like_control.attr("href", data.url);
      like_control.text("Unlike");
    } else {
      like_control.data("method", "post");
      like_control.attr("href", '/likes.json?post_id=' + data.id);
      like_control.text("Like");
    }
  });
});