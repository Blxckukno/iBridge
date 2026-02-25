// Gallery Filter JavaScript
// iBridge Contact Solutions - Gallery filtering functionality

class GalleryFilter {
    constructor() {
        this.filterButtons = document.querySelectorAll('.filter-btn');
        this.galleryItems = document.querySelectorAll('.gallery-item');
        this.currentFilter = 'all';

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.initializeGallery();
    }

    setupEventListeners() {
        this.filterButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                const filter = button.dataset.filter;
                this.filterGallery(filter);
                this.updateActiveButton(button);
            });

            // Keyboard support
            button.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    button.click();
                }
            });
        });

        // Add keyboard navigation between filter buttons
        this.setupKeyboardNavigation();
    }

    setupKeyboardNavigation() {
        this.filterButtons.forEach((button, index) => {
            button.addEventListener('keydown', (e) => {
                if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                    e.preventDefault();
                    const nextButton = this.filterButtons[index + 1] || this.filterButtons[0];
                    nextButton.focus();
                } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                    e.preventDefault();
                    const prevButton = this.filterButtons[index - 1] || this.filterButtons[this.filterButtons.length - 1];
                    prevButton.focus();
                }
            });
        });
    }

    initializeGallery() {
        // Show all items initially with animation
        this.galleryItems.forEach((item, index) => {
            item.style.opacity = '0';
            item.style.transform = 'translateY(20px)';

            setTimeout(() => {
                item.style.transition = 'all 0.6s ease';
                item.style.opacity = '1';
                item.style.transform = 'translateY(0)';
            }, index * 100);
        });
    }

    filterGallery(filter) {
        this.currentFilter = filter;

        this.galleryItems.forEach((item, index) => {
            const category = item.dataset.category;
            const shouldShow = filter === 'all' || category === filter;

            if (shouldShow) {
                this.showItem(item, index);
            } else {
                this.hideItem(item);
            }
        });

        // Update URL without page reload (for better UX)
        this.updateURL(filter);

        // Announce change to screen readers
        this.announceFilterChange(filter);
    }

    showItem(item, index) {
        item.style.display = 'block';

        // Add stagger animation for showing items
        setTimeout(() => {
            item.style.opacity = '1';
            item.style.transform = 'translateY(0) scale(1)';
        }, index * 50);
    }

    hideItem(item) {
        item.style.opacity = '0';
        item.style.transform = 'translateY(-20px) scale(0.95)';

        setTimeout(() => {
            item.style.display = 'none';
        }, 300);
    }

    updateActiveButton(activeButton) {
        this.filterButtons.forEach(button => {
            button.classList.remove('active');
            button.setAttribute('aria-pressed', 'false');
        });

        activeButton.classList.add('active');
        activeButton.setAttribute('aria-pressed', 'true');
    }

    updateURL(filter) {
        const url = new URL(window.location);
        if (filter === 'all') {
            url.searchParams.delete('filter');
        } else {
            url.searchParams.set('filter', filter);
        }
        window.history.replaceState({}, '', url);
    }

    announceFilterChange(filter) {
        const announcement = document.createElement('div');
        announcement.setAttribute('aria-live', 'polite');
        announcement.setAttribute('aria-atomic', 'true');
        announcement.className = 'sr-only';

        const filterText = filter === 'all' ? 'all items' : `${filter} items`;
        announcement.textContent = `Showing ${filterText}`;

        document.body.appendChild(announcement);

        setTimeout(() => {
            document.body.removeChild(announcement);
        }, 1000);
    }

    // Method to get current filter from URL
    getInitialFilter() {
        const urlParams = new URLSearchParams(window.location.search);
        const filter = urlParams.get('filter');
        return filter && ['team', 'workspace', 'culture'].includes(filter) ? filter : 'all';
    }

    // Method to initialize with URL filter
    initializeWithURLFilter() {
        const initialFilter = this.getInitialFilter();
        if (initialFilter !== 'all') {
            const filterButton = document.querySelector(`[data-filter="${initialFilter}"]`);
            if (filterButton) {
                this.filterGallery(initialFilter);
                this.updateActiveButton(filterButton);
            }
        }
    }
}

// Enhanced Gallery Item Interaction
class GalleryItemInteraction {
    constructor() {
        this.galleryItems = document.querySelectorAll('.gallery-item');
        this.modal = null;

        this.init();
    }

    init() {
        this.setupImageClickHandlers();
        this.createModal();
        this.setupKeyboardHandlers();
    }

    setupImageClickHandlers() {
        this.galleryItems.forEach(item => {
            const img = item.querySelector('.gallery-img');
            const overlay = item.querySelector('.gallery-overlay');

            if (img) {
                // Make gallery items focusable
                item.setAttribute('tabindex', '0');
                item.setAttribute('role', 'button');
                item.setAttribute('aria-label', `View ${overlay?.querySelector('h3')?.textContent || 'gallery image'}`);

                // Click handler
                item.addEventListener('click', (e) => {
                    e.preventDefault();
                    this.openImageModal(img, overlay);
                });

                // Keyboard handler
                item.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        this.openImageModal(img, overlay);
                    }
                });
            }
        });
    }

    createModal() {
        this.modal = document.createElement('div');
        this.modal.className = 'gallery-modal';
        this.modal.innerHTML = `
            <div class="modal-overlay">
                <div class="modal-content">
                    <button class="modal-close" aria-label="Close modal">&times;</button>
                    <img class="modal-image" src="" alt="">
                    <div class="modal-caption"></div>
                    <div class="modal-nav">
                        <button class="modal-prev" aria-label="Previous image">&#8249;</button>
                        <button class="modal-next" aria-label="Next image">&#8250;</button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(this.modal);
        this.setupModalEventListeners();
    }

    setupModalEventListeners() {
        const closeBtn = this.modal.querySelector('.modal-close');
        const overlay = this.modal.querySelector('.modal-overlay');
        const prevBtn = this.modal.querySelector('.modal-prev');
        const nextBtn = this.modal.querySelector('.modal-next');

        // Close modal
        closeBtn.addEventListener('click', () => this.closeModal());
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) this.closeModal();
        });

        // Navigation
        prevBtn.addEventListener('click', () => this.showPreviousImage());
        nextBtn.addEventListener('click', () => this.showNextImage());

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (this.modal.classList.contains('active')) {
                switch (e.key) {
                    case 'Escape':
                        this.closeModal();
                        break;
                    case 'ArrowLeft':
                        this.showPreviousImage();
                        break;
                    case 'ArrowRight':
                        this.showNextImage();
                        break;
                }
            }
        });
    }

    openImageModal(img, overlay) {
        const modalImg = this.modal.querySelector('.modal-image');
        const modalCaption = this.modal.querySelector('.modal-caption');

        modalImg.src = img.src;
        modalImg.alt = img.alt;
        modalCaption.textContent = overlay?.querySelector('h3')?.textContent || '';

        this.modal.classList.add('active');
        document.body.style.overflow = 'hidden';

        // Focus management
        const closeBtn = this.modal.querySelector('.modal-close');
        setTimeout(() => closeBtn.focus(), 100);

        // Store current image for navigation
        this.currentImageIndex = Array.from(this.galleryItems).indexOf(img.closest('.gallery-item'));
    }

    closeModal() {
        this.modal.classList.remove('active');
        document.body.style.overflow = '';

        // Return focus to the gallery item that opened the modal
        if (this.currentImageIndex !== undefined) {
            this.galleryItems[this.currentImageIndex].focus();
        }
    }

    showPreviousImage() {
        if (this.currentImageIndex > 0) {
            this.currentImageIndex--;
        } else {
            this.currentImageIndex = this.galleryItems.length - 1;
        }
        this.updateModalImage();
    }

    showNextImage() {
        if (this.currentImageIndex < this.galleryItems.length - 1) {
            this.currentImageIndex++;
        } else {
            this.currentImageIndex = 0;
        }
        this.updateModalImage();
    }

    updateModalImage() {
        const currentItem = this.galleryItems[this.currentImageIndex];
        const img = currentItem.querySelector('.gallery-img');
        const overlay = currentItem.querySelector('.gallery-overlay');

        const modalImg = this.modal.querySelector('.modal-image');
        const modalCaption = this.modal.querySelector('.modal-caption');

        modalImg.src = img.src;
        modalImg.alt = img.alt;
        modalCaption.textContent = overlay?.querySelector('h3')?.textContent || '';
    }

    setupKeyboardHandlers() {
        // Add proper focus indicators
        this.galleryItems.forEach(item => {
            item.addEventListener('focus', () => {
                item.style.outline = '3px solid var(--primary-color)';
                item.style.outlineOffset = '2px';
            });

            item.addEventListener('blur', () => {
                item.style.outline = 'none';
            });
        });
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const galleryFilter = new GalleryFilter();
    const galleryInteraction = new GalleryItemInteraction();

    // Initialize with URL filter if present
    galleryFilter.initializeWithURLFilter();
});

// Add modal styles
const modalStyles = `
    .gallery-modal {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.9);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s ease;
    }
    
    .gallery-modal.active {
        opacity: 1;
        visibility: visible;
    }
    
    .modal-content {
        position: relative;
        max-width: 90%;
        max-height: 90%;
        background: white;
        border-radius: 15px;
        overflow: hidden;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
    }
    
    .modal-image {
        width: 100%;
        height: auto;
        max-height: 70vh;
        object-fit: contain;
    }
    
    .modal-caption {
        padding: 1rem 2rem;
        font-size: 1.25rem;
        font-weight: 600;
        color: var(--text-dark);
        text-align: center;
    }
    
    .modal-close {
        position: absolute;
        top: 1rem;
        right: 1rem;
        background: rgba(0, 0, 0, 0.5);
        color: white;
        border: none;
        width: 40px;
        height: 40px;
        border-radius: 50%;
        font-size: 1.5rem;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.3s ease;
        z-index: 1;
    }
    
    .modal-close:hover {
        background: rgba(0, 0, 0, 0.8);
        transform: scale(1.1);
    }
    
    .modal-nav {
        position: absolute;
        top: 50%;
        transform: translateY(-50%);
        width: 100%;
        display: flex;
        justify-content: space-between;
        padding: 0 1rem;
        pointer-events: none;
    }
    
    .modal-prev,
    .modal-next {
        background: rgba(0, 0, 0, 0.5);
        color: white;
        border: none;
        width: 50px;
        height: 50px;
        border-radius: 50%;
        font-size: 2rem;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.3s ease;
        pointer-events: all;
    }
    
    .modal-prev:hover,
    .modal-next:hover {
        background: rgba(0, 0, 0, 0.8);
        transform: scale(1.1);
    }
    
    .sr-only {
        position: absolute;
        width: 1px;
        height: 1px;
        padding: 0;
        margin: -1px;
        overflow: hidden;
        clip: rect(0, 0, 0, 0);
        white-space: nowrap;
        border: 0;
    }
    
    @media (max-width: 768px) {
        .modal-content {
            max-width: 95%;
            max-height: 95%;
        }
        
        .modal-close {
            top: 0.5rem;
            right: 0.5rem;
            width: 35px;
            height: 35px;
            font-size: 1.25rem;
        }
        
        .modal-prev,
        .modal-next {
            width: 40px;
            height: 40px;
            font-size: 1.5rem;
        }
        
        .modal-caption {
            padding: 0.75rem 1rem;
            font-size: 1.1rem;
        }
    }
`;

// Inject modal styles
const modalStyleSheet = document.createElement('style');
modalStyleSheet.textContent = modalStyles;
document.head.appendChild(modalStyleSheet);
