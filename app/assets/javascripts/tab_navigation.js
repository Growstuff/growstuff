$(document).ready(function() {
    var url = location.href.replace(/\/$/, '');

    if (location.hash) {
        var hash = url.split('#');
        var triggerEl = document.querySelector('#myTab a[href="#' + hash[1] + '"]');
        var tab = new bootstrap.Tab(triggerEl);
        tab.show();
        url = location.href.replace(/\/#/, '#');
        history.replaceState(null, null, url);
        setTimeout(function() {
            $(window).scrollTop(0);
        }, 20);
    }

    $('a[data-bs-toggle="tab"]').on('click', function() {
        var newUrl;
        var hash = $(this).attr('href');
        newUrl = url.split('#')[0] + hash;
        history.replaceState(null, null, newUrl);
    });
});
