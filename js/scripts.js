// Mobile Menu Toggle
const mobileMenuBtn = document.getElementById('mobileMenuBtn');
const mainMenu = document.getElementById('mainMenu');

mobileMenuBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    mainMenu.classList.toggle('show');
});

document.addEventListener('click', (e) => {
    if (mainMenu.classList.contains('show') && !mainMenu.contains(e.target) && e.target !== mobileMenuBtn) {
        mainMenu.classList.remove('show');
    }
});

mainMenu.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        mainMenu.classList.remove('show');
    });
});

// Ensure the Services button in the mobile menu navigates correctly
const servicesLink = document.querySelector('#mainMenu li a[href="services.html"]');

if (servicesLink) {
    servicesLink.addEventListener('click', () => {
        // Close the mobile menu if open
        mainMenu.classList.remove('show');
    });
}

// Smooth Scrolling for Anchor Links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();

        if (this.getAttribute('href') === '#') return;

        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            window.scrollTo({
                top: target.offsetTop - 80,
                behavior: 'smooth'
            });

            // Close mobile menu if open
            mainMenu.classList.remove('show');
        }
    });
});

// FAQ Accordion
const faqQuestions = document.querySelectorAll('.faq-question');

faqQuestions.forEach(question => {
    question.addEventListener('click', () => {
        const parent = question.parentElement;
        parent.classList.toggle('active');
    });
});

// Form Submission
const contactForm = document.getElementById('contactForm');

if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();

        // Simulate form submission
        alert('Thank you for your message! We will contact you soon.');
        this.reset();
    });
}

// Newsletter Form Submission
const newsletterForm = document.getElementById('newsletterForm');

if (newsletterForm) {
    newsletterForm.addEventListener('submit', function(e) {
        e.preventDefault();

        // Simulate newsletter subscription
        alert('Thank you for subscribing to our newsletter!');
        this.reset();
    });
});

// AI Art: Simulate AI image generation
function generateAIImage() {
    const aiImage = document.getElementById('aiImage');
    // For demo, use a random placeholder image. Replace with API call for real AI images.
    const randomNum = Math.floor(Math.random() * 1000);
    aiImage.src = `https://placehold.co/600x400?text=AI+Image+${randomNum}`;
}

// Animation on Scroll
const animateOnScroll = () => {
    const elements = document.querySelectorAll('.services-grid, .about-container, .team-grid, .testimonial-grid');

    elements.forEach(element => {
        const elementPosition = element.getBoundingClientRect().top;
        const screenPosition = window.innerHeight / 1.2;

        if (elementPosition < screenPosition) {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
        }
    });
};

window.addEventListener('scroll', animateOnScroll);
window.addEventListener('load', animateOnScroll);

// Highlight Active Section (improved, single source of truth)
const sections = document.querySelectorAll('section');
const navLinks = document.querySelectorAll('nav ul li a');

function updateActiveNav() {
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop - 120;
        const sectionHeight = section.offsetHeight;
        if (window.scrollY >= sectionTop && window.scrollY < sectionTop + sectionHeight) {
            current = section.getAttribute('id');
        }
    });
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === '#' + current) {
            link.classList.add('active');
        }
    });
}

window.addEventListener('scroll', updateActiveNav);

navLinks.forEach(link => {
    link.addEventListener('click', function() {
        navLinks.forEach(l => l.classList.remove('active'));
        this.classList.add('active');
    });
});

// Testimonial Slider
const testimonials = document.querySelectorAll('.testimonial-item');
let currentTestimonial = 0;

function showTestimonial(index) {
    testimonials.forEach((testimonial, i) => {
        testimonial.style.display = i === index ? 'block' : 'none';
    });
}

function nextTestimonial() {
    currentTestimonial = (currentTestimonial + 1) % testimonials.length;
    showTestimonial(currentTestimonial);
}

setInterval(nextTestimonial, 5000);
showTestimonial(currentTestimonial);

// Scroll-to-Top Button
const scrollToTopBtn = document.createElement('button');
scrollToTopBtn.classList.add('scroll-to-top');
scrollToTopBtn.innerHTML = '&#8679;';
document.body.appendChild(scrollToTopBtn);

window.addEventListener('scroll', () => {
    if (window.scrollY > 300) {
        scrollToTopBtn.classList.add('show');
    } else {
        scrollToTopBtn.classList.remove('show');
    }
});

scrollToTopBtn.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
});

// Sticky Navigation Bar
const navbar = document.querySelector('nav');

window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('sticky');
    } else {
        navbar.classList.remove('sticky');
    }
});
