$(document).ready(function() {
  $('.like-btn').show();

  /**
   * Handles the result of an ajax call and updates UI
   *
   * @param {object} data JSON data from ajax response
   * @param {string} type object type (ie: post, activity, etc)
   */
  var likeableSuccess = function(data, type) {
    var target = '.' + type + '-' + data.id;
    var objectClass = type.charAt(0).toUpperCase() + type.slice(1);
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
      likeButton.attr('href', '/likes.json?type=' + objectClass + '&id=' + data.id);
      likeButton.text('Like');
    }
  };

  $('.post-like').on('ajax:success', function(event, data) {
    likeableSuccess(data, 'post');
  });

  $('.activity-like').on('ajax:success', function(event, data) {
    likeableSuccess(data, 'activity');
  });

  $('.planting-like').on('ajax:success', function(event, data) {
    likeableSuccess(data, 'planting');
  });

  $('.harvest-like').on('ajax:success', function(event, data) {
    likeableSuccess(data, 'harvest');
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
