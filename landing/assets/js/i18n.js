(function () {
  var body = document.body;
  var activeLang = body.getAttribute('data-lang');
  var altUrl = body.getAttribute('data-alt-url');
  var stored = localStorage.getItem('agenda-lang');

  if (!stored) {
    stored = 'en';
    localStorage.setItem('agenda-lang', 'en');
  }

  if (stored !== activeLang && altUrl) {
    window.location.replace(altUrl);
    return;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var btn = document.getElementById('lang-btn');
    if (btn) {
      btn.addEventListener('click', function () {
        localStorage.setItem('agenda-lang', activeLang === 'pt' ? 'en' : 'pt');
      });
    }
  });
})();
