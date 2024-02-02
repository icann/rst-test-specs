window.addEventListener('beforeprint', (event) => {
    var els = document.getElementsByTagName('details');
    for (var i = 0 ; i < els.length ; i++) {
        els.item(i).setAttribute('open', true);
    }
});
