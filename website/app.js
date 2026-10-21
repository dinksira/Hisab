/* ============================================================
   HISAB WEBSITE — app.js
   ============================================================ */

// NAV: add scrolled class on scroll
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 40);
}, { passive: true });

// REVEAL: IntersectionObserver for .reveal elements
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry, i) => {
    if (entry.isIntersecting) {
      // stagger children slightly
      setTimeout(() => {
        entry.target.classList.add('visible');
      }, i * 60);
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -60px 0px' });

document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

// SMOOTH SCROLL for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', (e) => {
    const target = document.querySelector(anchor.getAttribute('href'));
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});

// BUDGET BARS: animate in when phone section enters view
const phoneEl = document.querySelector('.hero-phone');
if (phoneEl) {
  const budgetFills = phoneEl.querySelectorAll('.budget-fill');
  budgetFills.forEach(fill => {
    const targetWidth = fill.style.width;
    fill.style.width = '0';
    setTimeout(() => { fill.style.width = targetWidth; }, 800);
  });
}

// DOWNLOAD tracking (console log for analytics placeholder)
document.querySelectorAll('[download], [id*="download"]').forEach(btn => {
  btn.addEventListener('click', () => {
    console.log('[Hisab] APK download initiated from:', btn.id || btn.className);
  });
});
