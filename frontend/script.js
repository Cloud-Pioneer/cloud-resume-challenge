const API_URL = 'https://xh1qa6rgff.execute-api.eu-west-1.amazonaws.com/visitor';

async function updateVisitorCount() {
  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await response.json();
    const counter = document.getElementById('visitor-count');
    if (counter && data.visitor_count) {
      counter.textContent = data.visitor_count.toLocaleString();
    }
  } catch (err) {
    const counter = document.getElementById('visitor-count');
    if (counter) counter.textContent = '-';
  }
}

updateVisitorCount();

document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) target.scrollIntoView({ behavior: 'smooth' });
  });
});

window.addEventListener('scroll', () => {
  let current = '';
  document.querySelectorAll('section[id]').forEach(section => {
    if (window.scrollY >= section.offsetTop - 100) current = section.id;
  });
  document.querySelectorAll('.nav-links a').forEach(link => {
    link.style.color = link.getAttribute('href') === '#' + current ? 'var(--blue)' : '';
  });
});