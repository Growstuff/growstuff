$(document).ready(function() {
    let url = location.href.replace(/\/$/, "");

    if (location.hash) {
        const hash = url.split("#");
        var triggerEl = document.querySelector('#myTab a[href="#' + hash[1] + '"]');
        var tab = new bootstrap.Tab(triggerEl)
        tab.show()
        url = location.href.replace(/\/#/, "#");
        history.replaceState(null, null, url);
        setTimeout(() => {
            $(window).scrollTop(0);
        }, 20);
    }

    $('a[data-bs-toggle="tab"]').on("click", function() {
        let newUrl;
        const hash = $(this).attr("href");
        newUrl = url.split("#")[0] + hash;
        history.replaceState(null, null, newUrl);
    });
})
