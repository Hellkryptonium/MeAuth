// Framer Motion-like animation helpers for MeAuth static site
// Use: add class 'fade-in', 'fade-up', 'scale-in', etc. to elements
// and call animateOnLoad() on DOMContentLoaded
function animateOnLoad() {
  document.querySelectorAll('.fade-in').forEach((el, i) => {
    el.style.opacity = 0;
    el.style.transform = 'translateY(40px)';
    setTimeout(() => {
      el.style.transition = 'all 0.7s cubic-bezier(.4,2,.3,1)';
      el.style.opacity = 1;
      el.style.transform = 'translateY(0)';
    }, 200 + i * 120);
  });
  document.querySelectorAll('.fade-up').forEach((el, i) => {
    el.style.opacity = 0;
    el.style.transform = 'translateY(60px)';
    setTimeout(() => {
      el.style.transition = 'all 0.8s cubic-bezier(.4,2,.3,1)';
      el.style.opacity = 1;
      el.style.transform = 'translateY(0)';
    }, 300 + i * 120);
  });
  document.querySelectorAll('.scale-in').forEach((el, i) => {
    el.style.opacity = 0;
    el.style.transform = 'scale(0.8)';
    setTimeout(() => {
      el.style.transition = 'all 0.7s cubic-bezier(.4,2,.3,1)';
      el.style.opacity = 1;
      el.style.transform = 'scale(1)';
    }, 400 + i * 100);
  });
}
window.addEventListener('DOMContentLoaded', animateOnLoad);
// Back to top button
window.addEventListener('scroll', function() {
  const btn = document.getElementById('backToTop');
  if (!btn) return;
  if (window.scrollY > 200) {
    btn.style.opacity = 1;
    btn.style.pointerEvents = 'auto';
  } else {
    btn.style.opacity = 0;
    btn.style.pointerEvents = 'none';
  }
});
function scrollToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
// Add more animation helpers as needed for new interactive elements.
