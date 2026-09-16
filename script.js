// Echo Paintworks — shared behavior

document.addEventListener('DOMContentLoaded', function () {
  var toggle = document.querySelector('.nav-toggle');
  var links = document.querySelector('nav.links');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      links.classList.toggle('open');
    });
    links.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () { links.classList.remove('open'); });
    });
  }

  // Quote form: basic client-side confirmation.
  // Replace the form's "action" attribute (see quote.html) with your own
  // Formspree endpoint (or similar) to receive submissions by email.
  var form = document.querySelector('.quote-form');
  if (form) {
    form.addEventListener('submit', function (e) {
      var action = form.getAttribute('action') || '';
      if (action.indexOf('YOUR-FORM-ID') !== -1) {
        e.preventDefault();
        alert('Almost there! This form needs to be connected to an email service before it can send. See the setup note in quote.html.');
      }
      // Otherwise let it submit normally to the configured endpoint.
    });
  }
});
