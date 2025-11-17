/**
 * Gallery Functionality
 * Handles filtering, loading, and image enhancement
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize variables
    const gallery = document.querySelector('.gallery-grid');
    const filters = document.querySelectorAll('.gallery-filters button');
    const loadMoreBtn = document.getElementById('loadMoreBtn');
    let currentPage = 1;
    const itemsPerPage = 9;

    // Initialize Intersection Observer for lazy loading
    const observerOptions = {
        root: null,
        rootMargin: '50px',
        threshold: 0.1
    };

    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                    enhanceImage(img);
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    observer.unobserve(img);
                }
            }
        });
    }, observerOptions);

    // Observe all gallery images
    document.querySelectorAll('.gallery-card img').forEach(img => {
        imageObserver.observe(img);
    });

    // Filter functionality
    filters.forEach(filter => {
        filter.addEventListener('click', function() {
            // Update active state
            filters.forEach(f => f.classList.remove('active'));
            this.classList.add('active');

            const category = this.dataset.filter;
            filterGallery(category);
        });
    });

    // Load more functionality
    if (loadMoreBtn) {
        loadMoreBtn.addEventListener('click', loadMoreItems);
    }

    /**
     * Filter gallery items by category
     * @param {string} category - The category to filter by
     */
    function filterGallery(category) {
        const items = document.querySelectorAll('.gallery-item');
        
        items.forEach(item => {
            if (category === 'all' || item.dataset.category === category) {
                item.style.display = 'block';
                item.classList.add('animate-fadeInUp');
            } else {
                item.style.display = 'none';
                item.classList.remove('animate-fadeInUp');
            }
        });
    }

    /**
     * Enhance image quality and appearance
     * @param {HTMLImageElement} img - The image element to enhance
     */
    function enhanceImage(img) {
        const category = img.closest('.gallery-item').dataset.category;
        
        // Apply different enhancements based on category
        switch(category) {
            case 'team':
                img.classList.add('enhance-clarity', 'enhance-warmth');
                break;
            case 'events':
                img.classList.add('enhance-vibrance', 'enhance-contrast');
                break;
            case 'workspace':
                img.classList.add('enhance-cool', 'enhance-clarity');
                break;
            case 'culture':
                img.classList.add('enhance-warmth', 'enhance-vibrance');
                break;
            default:
                img.classList.add('enhance-clarity');
        }
    }

    /**
     * Load more gallery items
     */
    async function loadMoreItems() {
        try {
            // Show loading state
            loadMoreBtn.disabled = true;
            loadMoreBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Loading...';

            // Simulate API call to get more items
            const response = await fetch(`/api/gallery?page=${currentPage + 1}&limit=${itemsPerPage}`);
            const newItems = await response.json();

            if (newItems.length > 0) {
                // Add new items to gallery
                newItems.forEach(item => {
                    const element = createGalleryItem(item);
                    gallery.appendChild(element);
                    
                    // Observe new images
                    const img = element.querySelector('img');
                    if (img) {
                        imageObserver.observe(img);
                    }
                });

                currentPage++;
            } else {
                // No more items to load
                loadMoreBtn.style.display = 'none';
            }
        } catch (error) {
            console.error('Error loading more items:', error);
            loadMoreBtn.innerHTML = 'Error loading items. Try again.';
        } finally {
            loadMoreBtn.disabled = false;
        }
    }

    /**
     * Create a gallery item element
     * @param {Object} item - The gallery item data
     * @returns {HTMLElement} The created gallery item element
     */
    function createGalleryItem(item) {
        const div = document.createElement('div');
        div.className = 'col-md-4 gallery-item animate-fadeInUp';
        div.dataset.category = item.category;

        div.innerHTML = `
            <div class="gallery-card">
                <img src="images/placeholder.jpg"
                     data-src="${item.imagePath}"
                     alt="${item.title}"
                     class="img-fluid"
                     loading="lazy">
                <div class="gallery-overlay">
                    <h5>${item.title}</h5>
                    <p>${item.description}</p>
                </div>
            </div>
        `;

        return div;
    }

    // Initialize lightbox for gallery images
    const galleryImages = document.querySelectorAll('.gallery-card img');
    galleryImages.forEach(img => {
        img.addEventListener('click', function() {
            openLightbox(this.src, this.alt);
        });
    });

    /**
     * Open lightbox with image
     * @param {string} src - Image source URL
     * @param {string} alt - Image alt text
     */
    function openLightbox(src, alt) {
        const lightbox = document.createElement('div');
        lightbox.className = 'lightbox';
        lightbox.innerHTML = `
            <div class="lightbox-content">
                <img src="${src}" alt="${alt}">
                <button class="close-lightbox">&times;</button>
            </div>
        `;

        document.body.appendChild(lightbox);
        document.body.style.overflow = 'hidden';

        // Close lightbox on click
        lightbox.addEventListener('click', function(e) {
            if (e.target === lightbox || e.target.className === 'close-lightbox') {
                document.body.removeChild(lightbox);
                document.body.style.overflow = '';
            }
        });
    }

    // Slideshow functionality
    let currentSlideIndex = 0;
    let slides = [];
    let isSlideShowPlaying = false;
    let slideShowInterval;

    function initSlideshow() {
        const slideshowContainer = document.createElement('div');
        slideshowContainer.className = 'slideshow-container';
        slideshowContainer.innerHTML = `
            <div class="slideshow-content">
                <img src="" alt="" class="slideshow-image">
                <div class="slideshow-caption"></div>
            </div>
            <button class="slideshow-prev">&lt;</button>
            <button class="slideshow-next">&gt;</button>
            <button class="slideshow-play-pause">
                <i class="fas fa-play"></i>
            </button>
            <button class="slideshow-close">&times;</button>
        `;
        document.body.appendChild(slideshowContainer);

        // Add event listeners
        document.querySelector('.slideshow-prev').addEventListener('click', () => showSlide(currentSlideIndex - 1));
        document.querySelector('.slideshow-next').addEventListener('click', () => showSlide(currentSlideIndex + 1));
        document.querySelector('.slideshow-play-pause').addEventListener('click', toggleSlideshow);
        document.querySelector('.slideshow-close').addEventListener('click', closeSlideshow);

        // Add keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (slideshowContainer.style.display === 'flex') {
                switch(e.key) {
                    case 'ArrowLeft': showSlide(currentSlideIndex - 1); break;
                    case 'ArrowRight': showSlide(currentSlideIndex + 1); break;
                    case 'Escape': closeSlideshow(); break;
                    case ' ': toggleSlideshow(); break;
                }
            }
        });
    }

    function showSlide(index) {
        if (slides.length === 0) return;
        
        currentSlideIndex = (index + slides.length) % slides.length;
        const slideshowImage = document.querySelector('.slideshow-image');
        const slideshowCaption = document.querySelector('.slideshow-caption');
        
        slideshowImage.src = slides[currentSlideIndex].src;
        slideshowImage.alt = slides[currentSlideIndex].alt;
        slideshowCaption.textContent = slides[currentSlideIndex].caption;
    }

    function toggleSlideshow() {
        const playPauseBtn = document.querySelector('.slideshow-play-pause i');
        isSlideShowPlaying = !isSlideShowPlaying;
        
        if (isSlideShowPlaying) {
            playPauseBtn.className = 'fas fa-pause';
            slideShowInterval = setInterval(() => showSlide(currentSlideIndex + 1), 3000);
        } else {
            playPauseBtn.className = 'fas fa-play';
            clearInterval(slideShowInterval);
        }
    }

    function closeSlideshow() {
        const slideshowContainer = document.querySelector('.slideshow-container');
        slideshowContainer.style.display = 'none';
        isSlideShowPlaying = false;
        clearInterval(slideShowInterval);
    }

    function openSlideshow(startIndex = 0) {
        slides = Array.from(document.querySelectorAll('.gallery-item:not([style*="display: none"]) img'))
            .map(img => ({
                src: img.src,
                alt: img.alt,
                caption: img.closest('.gallery-card').querySelector('.gallery-overlay h5').textContent
            }));
        
        if (slides.length === 0) return;
        
        const slideshowContainer = document.querySelector('.slideshow-container');
        slideshowContainer.style.display = 'flex';
        currentSlideIndex = startIndex;
        showSlide(currentSlideIndex);
    }

    // Initialize slideshow on page load
    initSlideshow();

    // Add click event to gallery items to open slideshow
    document.querySelectorAll('.gallery-card').forEach((card, index) => {
        card.addEventListener('click', () => openSlideshow(index));
    });
});
