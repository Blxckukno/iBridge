document.addEventListener('DOMContentLoaded', () => {
    // Scroll reveal functionality
    const revealElements = document.querySelectorAll('.reveal-on-scroll');
    const revealOptions = {
        threshold: 0.15,
        rootMargin: '0px'
    };

    const revealCallback = (entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                observer.unobserve(entry.target);
            }
        });
    };

    const revealObserver = new IntersectionObserver(revealCallback, revealOptions);
    revealElements.forEach(element => revealObserver.observe(element));

    // Parallax effect
    const parallaxElements = document.querySelectorAll('.parallax');
    let scrollTimeout;

    window.addEventListener('scroll', () => {
        if (scrollTimeout) {
            window.cancelAnimationFrame(scrollTimeout);
        }

        scrollTimeout = window.requestAnimationFrame(() => {
            const scrolled = window.pageYOffset;
            parallaxElements.forEach(element => {
                const speed = element.dataset.speed || 0.5;
                const yPos = -(scrolled * speed);
                element.style.transform = `translateY(${yPos}px)`;
            });
        });
    });

    // Page progress bar
    const progressBar = document.querySelector('.progress-bar');
    if (progressBar) {
        window.addEventListener('scroll', () => {
            const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
            const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
            const scrolled = (winScroll / height) * 100;
            progressBar.style.setProperty('--scroll', `${scrolled}%`);
        });
    }

    // Text reveal animation
    const textElements = document.querySelectorAll('.text-reveal');
    textElements.forEach(element => {
        const text = element.textContent;
        element.textContent = '';
        text.split('').forEach((char, i) => {
            const span = document.createElement('span');
            span.textContent = char;
            span.style.animationDelay = `${i * 0.05}s`;
            element.appendChild(span);
        });
    });

    // Page transition
    const pageTransition = document.querySelector('.page-transition');
    if (pageTransition) {
        document.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', e => {
                if (link.target !== '_blank' && !link.hasAttribute('download')) {
                    e.preventDefault();
                    const href = link.href;
                    pageTransition.classList.add('active');
                    setTimeout(() => {
                        window.location = href;
                    }, 600);
                }
            });
        });
    }

    // Initialize stagger animations
    const staggerContainers = document.querySelectorAll('.stagger-children');
    staggerContainers.forEach(container => {
        const children = container.children;
        Array.from(children).forEach((child, index) => {
            child.style.animationDelay = `${index * 0.1}s`;
        });
    });

    // Image reveal animation
    const imageRevealElements = document.querySelectorAll('.image-reveal');
    const imageRevealOptions = {
        threshold: 0.15,
        rootMargin: '0px'
    };

    const imageRevealCallback = (entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                observer.unobserve(entry.target);
            }
        });
    };

    const imageRevealObserver = new IntersectionObserver(imageRevealCallback, imageRevealOptions);
    imageRevealElements.forEach(element => imageRevealObserver.observe(element));
});
