$(document).ready(function() {
  $('.like-btn').show();

  /** Handles the result of an ajax call and updates UI */
  var likeable_success = function(data, type) {
    var target = '.' + type + '-' + data.id;
    var object_class = type.charAt(0).toUpperCase() + type.slice(1);
    var likeButton = $(target + ' .' + type + '-like');
    var likeBadge = $(target + ' .like-badge');

    $(target + ' .like-count').text(data.like_count);
    if (data.liked_by_member) {
      likeBadge.addClass('liked');
      likeButton.data('method', 'delete');
      likeButton.attr('href', data.url);
      likeButton.text('Unlike');
    } else {
      likeBadge.removeClass('liked');
      likeButton.data('method', 'post');
      likeButton.attr('href', '/likes.json?type=' + object_class + '&id=' + data.id);
      likeButton.text('Like');
    }
  }

  // TODO: Refactor the common ajax behaviours
  $('.post-like').on('ajax:success', function(event, data) {
    likeable_success(data, 'post')
  });

  $('.activity-like').on('ajax:success', function(event, data) {
    likeable_success(data, 'activity')
  });

  $('.planting-like').on('ajax:success', function(event, data) {
    likeable_success(data, 'planting')
  });

  $('.harvest-like').on('ajax:success', function(event, data) {
    likeable_success(data, 'harvest')
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
