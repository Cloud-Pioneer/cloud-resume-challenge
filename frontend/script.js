// Visitor Counter
// This calls the API Gateway endpoint which triggers Lambda → DynamoDB
// The API_URL below will be replaced with your real URL after Terraform deploys

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
    // Silently fail — visitor count is a nice-to-have, not critical
    const counter = document.getElementById('visitor-count');
    if (counter) counter.textContent = '—';
    console.log('Visitor counter not yet connected to backend.');
  }
}

// Run on page load
updateVisitorCount();

// Smooth scroll for nav links
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) target.scrollIntoView({ behavior: 'smooth' });
  });
});

// Highlight nav links on scroll
const sections = document.querySelectorAll('section[id]');
window.addEventListener('scroll', () => {
  let current = '';
  sections.forEach(section => {
    if (window.scrollY >= section.offsetTop - 100) current = section.id;
  });
  document.querySelectorAll('.nav-links a').forEach(link => {
    link.style.color = link.getAttribute('href') === `#${current}`
      ? 'var(--blue)'
      : '';
  });
});