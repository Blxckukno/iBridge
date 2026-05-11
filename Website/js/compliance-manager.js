(function () {
    class ComplianceManager {
        constructor() {
            this.storageKey = 'ibridge_consent_preferences';
            this.legacyKey = 'analytics_consent';
            this.version = '2026-03-10';
            this.durationDays = 365;
            this.publicPathBlocklist = /(ticketingsystem|professional-dashboard|staff-portal|lms-platform|security-dashboard|performance-dashboard|intranet)/i;
            this.defaultPreferences = {
                essential: true,
                analytics: false,
                externalMedia: false,
                marketing: false,
                choiceMade: false,
                version: this.version
            };

            if (!this.isPublicPage()) {
                return;
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.init(), { once: true });
            } else {
                this.init();
            }
        }

        isPublicPage() {
            const path = (window.location.pathname || '').toLowerCase();
            return !this.publicPathBlocklist.test(path);
        }

        init() {
            this.preferences = this.loadPreferences();
            this.injectFooterLegalLinks();
            this.bindGlobalActions();
            this.applyPreferences(false);
            this.prepareExternalEmbeds();
            this.initializeRightsRequestForm();

            if (!this.preferences.choiceMade) {
                this.showBanner();
            }
        }

        loadPreferences() {
            try {
                const raw = localStorage.getItem(this.storageKey);
                if (raw) {
                    const parsed = JSON.parse(raw);
                    if (parsed.expiresAt && new Date(parsed.expiresAt) < new Date()) {
                        localStorage.removeItem(this.storageKey);
                    } else {
                        return { ...this.defaultPreferences, ...parsed, choiceMade: true };
                    }
                }
            } catch (error) {
                console.warn('Compliance preferences could not be read:', error);
            }

            const legacyConsent = localStorage.getItem(this.legacyKey);
            if (legacyConsent === 'granted' || legacyConsent === 'denied') {
                return {
                    ...this.defaultPreferences,
                    analytics: legacyConsent === 'granted',
                    choiceMade: true,
                    updatedAt: new Date().toISOString(),
                    expiresAt: this.buildExpiryDate(),
                    version: this.version
                };
            }

            return { ...this.defaultPreferences };
        }

        buildExpiryDate() {
            const expires = new Date();
            expires.setDate(expires.getDate() + this.durationDays);
            return expires.toISOString();
        }

        setTrustedMarkup(node, html) {
            if (!node) {
                return;
            }
            node.replaceChildren();
            node.insertAdjacentHTML('afterbegin', html.trim());
        }

        persistPreferences(nextPreferences, source) {
            this.preferences = {
                ...this.defaultPreferences,
                ...this.preferences,
                ...nextPreferences,
                essential: true,
                choiceMade: true,
                source,
                updatedAt: new Date().toISOString(),
                expiresAt: this.buildExpiryDate(),
                version: this.version
            };

            localStorage.setItem(this.storageKey, JSON.stringify(this.preferences));
            localStorage.setItem(this.legacyKey, this.preferences.analytics ? 'granted' : 'denied');

            this.hideBanner();
            this.closePreferencesModal();
            this.applyPreferences();
            this.logConsentPreferences();
        }

        applyPreferences(notify = true) {
            window.iBridgeConsentPreferences = { ...this.preferences };
            document.documentElement.dataset.analyticsConsent = this.preferences.analytics ? 'granted' : 'denied';
            document.documentElement.dataset.externalMediaConsent = this.preferences.externalMedia ? 'granted' : 'denied';
            document.documentElement.dataset.marketingConsent = this.preferences.marketing ? 'granted' : 'denied';

            if (this.preferences.externalMedia) {
                this.activateExternalEmbeds();
            }

            if (notify) {
                document.dispatchEvent(new CustomEvent('ibridge:consent-updated', {
                    detail: { ...this.preferences }
                }));
            }
        }

        showBanner() {
            if (document.querySelector('.cookie-consent-banner')) {
                return;
            }

            const banner = document.createElement('aside');
            banner.className = 'cookie-consent-banner';
            this.setTrustedMarkup(banner, `
                <h4>Privacy choices for this site</h4>
                <p>
                    We use essential storage to keep the site secure and working. Analytics and third-party content such as
                    interactive maps stay off until you choose them. See our <a href="privacy.html">Privacy Notice</a> and
                    <a href="cookie-notice.html">Cookie Notice</a>.
                </p>
                <div class="cookie-consent-actions">
                    <button type="button" class="cookie-consent-btn primary" data-cookie-action="accept-all">Accept all</button>
                    <button type="button" class="cookie-consent-btn secondary" data-cookie-action="essential-only">Essential only</button>
                    <button type="button" class="cookie-consent-btn ghost" data-cookie-action="manage">Manage choices</button>
                </div>
            `);

            document.body.appendChild(banner);
        }

        hideBanner() {
            document.querySelector('.cookie-consent-banner')?.remove();
        }

        bindGlobalActions() {
            document.addEventListener('click', (event) => {
                const action = event.target.closest('[data-cookie-action], .open-cookie-preferences, [data-consent-action]');
                if (!action) {
                    return;
                }

                if (action.matches('.open-cookie-preferences') || action.dataset.cookieAction === 'manage') {
                    event.preventDefault();
                    this.openPreferencesModal();
                    return;
                }

                if (action.dataset.cookieAction === 'accept-all') {
                    this.persistPreferences({
                        analytics: true,
                        externalMedia: true,
                        marketing: false
                    }, 'accept_all');
                    return;
                }

                if (action.dataset.cookieAction === 'essential-only') {
                    this.persistPreferences({
                        analytics: false,
                        externalMedia: false,
                        marketing: false
                    }, 'essential_only');
                    return;
                }

                if (action.dataset.consentAction === 'external-media') {
                    const updated = {
                        analytics: this.preferences.analytics,
                        externalMedia: true,
                        marketing: this.preferences.marketing
                    };
                    this.persistPreferences(updated, 'external_media');
                    return;
                }

                if (action.dataset.cookieAction === 'save-preferences') {
                    const overlay = document.querySelector('.cookie-consent-backdrop');
                    if (!overlay) return;

                    this.persistPreferences({
                        analytics: overlay.querySelector('#consent-analytics')?.checked || false,
                        externalMedia: overlay.querySelector('#consent-external-media')?.checked || false,
                        marketing: overlay.querySelector('#consent-marketing')?.checked || false
                    }, 'preferences');
                    return;
                }

                if (action.dataset.cookieAction === 'close-modal') {
                    this.closePreferencesModal();
                }
            });
        }

        openPreferencesModal() {
            const existing = document.querySelector('.cookie-consent-backdrop');
            if (existing) {
                return;
            }

            const overlay = document.createElement('div');
            overlay.className = 'cookie-consent-backdrop';
            this.setTrustedMarkup(overlay, `
                <div class="cookie-consent-modal" role="dialog" aria-modal="true" aria-labelledby="cookie-modal-title">
                    <h3 id="cookie-modal-title">Cookie and privacy preferences</h3>
                    <p>
                        Choose which optional technologies you want us to use. Essential storage remains on because it is required
                        for security, accessibility, and your saved privacy choices.
                    </p>
                    <div class="cookie-consent-grid">
                        <div class="cookie-consent-card">
                            <div class="cookie-consent-card-header">
                                <div>
                                    <h4>Essential storage</h4>
                                    <small>Required for site security, form handling, accessibility features, and saving your choices.</small>
                                </div>
                                <label class="cookie-switch">
                                    <input type="checkbox" checked disabled>
                                    <span class="cookie-slider"></span>
                                </label>
                            </div>
                        </div>
                        <div class="cookie-consent-card">
                            <div class="cookie-consent-card-header">
                                <div>
                                    <h4>Analytics</h4>
                                    <small>Helps us measure traffic and improve performance. Off by default until you consent.</small>
                                </div>
                                <label class="cookie-switch">
                                    <input type="checkbox" id="consent-analytics" ${this.preferences.analytics ? 'checked' : ''}>
                                    <span class="cookie-slider"></span>
                                </label>
                            </div>
                        </div>
                        <div class="cookie-consent-card">
                            <div class="cookie-consent-card-header">
                                <div>
                                    <h4>External media</h4>
                                    <small>Allows third-party services such as Google Maps embeds, which may process IP address and device data.</small>
                                </div>
                                <label class="cookie-switch">
                                    <input type="checkbox" id="consent-external-media" ${this.preferences.externalMedia ? 'checked' : ''}>
                                    <span class="cookie-slider"></span>
                                </label>
                            </div>
                        </div>
                        <div class="cookie-consent-card">
                            <div class="cookie-consent-card-header">
                                <div>
                                    <h4>Direct marketing</h4>
                                    <small>Reserved for future optional marketing communications. It stays off unless you expressly choose it.</small>
                                </div>
                                <label class="cookie-switch">
                                    <input type="checkbox" id="consent-marketing" ${this.preferences.marketing ? 'checked' : ''}>
                                    <span class="cookie-slider"></span>
                                </label>
                            </div>
                        </div>
                    </div>
                    <div class="cookie-consent-footer">
                        <p><a href="privacy.html">Privacy Notice</a> | <a href="cookie-notice.html">Cookie Notice</a> | <a href="compliance.html">POPIA, PAIA & ECTA</a></p>
                        <div class="cookie-consent-actions">
                            <button type="button" class="cookie-consent-btn secondary" data-cookie-action="close-modal">Cancel</button>
                            <button type="button" class="cookie-consent-btn primary" data-cookie-action="save-preferences">Save choices</button>
                        </div>
                    </div>
                </div>
            `);

            overlay.addEventListener('click', (event) => {
                if (event.target === overlay) {
                    this.closePreferencesModal();
                }
            });

            document.body.appendChild(overlay);
        }

        closePreferencesModal() {
            document.querySelector('.cookie-consent-backdrop')?.remove();
        }

        injectFooterLegalLinks() {
            document.querySelectorAll('.footer-bottom').forEach((footerBottom) => {
                if (footerBottom.querySelector('.footer-legal-links')) {
                    return;
                }

                const links = document.createElement('div');
                links.className = 'footer-legal-links';
                this.setTrustedMarkup(links, `
                    <a href="privacy.html">Privacy Notice</a>
                    <a href="cookie-notice.html">Cookie Notice</a>
                    <a href="compliance.html">POPIA, PAIA & ECTA</a>
                    <a href="terms.html">Terms of Use</a>
                    <a href="accessibility.html">Accessibility</a>
                    <button type="button" class="open-cookie-preferences">Cookie Preferences</button>
                `);

                footerBottom.appendChild(links);
            });
        }

        apiCandidates(path) {
            const relativePath = String(path || '');
            const urls = [relativePath];
            try {
                const hostname = String(window.location.hostname || '').toLowerCase();
                const isLocalHost = hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1';
                const isPrivateHost = /^10\./.test(hostname)
                    || /^192\.168\./.test(hostname)
                    || /^172\.(1[6-9]|2\d|3[0-1])\./.test(hostname);

                if ((isLocalHost || isPrivateHost) && window.location.port !== '5000') {
                    urls.push(`${window.location.protocol}//${window.location.hostname}:5000${relativePath}`);
                }
            } catch (error) {
                console.warn('API host resolution failed:', error);
            }
            return [...new Set(urls)];
        }

        async postJsonWithFallback(path, payload) {
            let lastError = null;
            for (const url of this.apiCandidates(path)) {
                try {
                    const response = await fetch(url, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(payload)
                    });
                    if (!response.ok) {
                        const message = await response.text();
                        throw new Error(message || `HTTP ${response.status}`);
                    }
                    return await response.json().catch(() => ({}));
                } catch (error) {
                    lastError = error;
                }
            }
            throw lastError || new Error('API unavailable');
        }

        initializeRightsRequestForm() {
            const form = document.querySelector('#complianceRequestForm');
            if (!form || form.dataset.initialized === 'true') {
                return;
            }

            form.dataset.initialized = 'true';
            const status = document.querySelector('#complianceRequestStatus');
            const submitButton = form.querySelector('[type="submit"]');
            const defaultButtonLabel = submitButton ? submitButton.textContent : '';
            const pageField = form.querySelector('#requestPageUrl');
            const timestampField = form.querySelector('#requestOccurredAt');

            if (pageField) {
                pageField.value = window.location.href;
            }
            if (timestampField) {
                timestampField.value = new Date().toISOString();
            }

            form.addEventListener('submit', async (event) => {
                event.preventDefault();

                const consentCheckbox = form.querySelector('#requestConsent');
                if (consentCheckbox && !consentCheckbox.checked) {
                    this.setRightsRequestStatus(status, 'Please confirm the privacy acknowledgement before submitting your request.', 'error');
                    return;
                }

                const payload = {
                    full_name: form.querySelector('#requestFullName')?.value.trim() || '',
                    email: form.querySelector('#requestEmail')?.value.trim() || '',
                    phone: form.querySelector('#requestPhone')?.value.trim() || '',
                    request_type: form.querySelector('#requestType')?.value || '',
                    reference_context: form.querySelector('#requestReference')?.value.trim() || '',
                    details: form.querySelector('#requestDetails')?.value.trim() || '',
                    page_url: pageField?.value || window.location.href,
                    occurred_at: timestampField?.value || new Date().toISOString(),
                    consent_acknowledged: !!consentCheckbox?.checked
                };

                if (!payload.full_name || !payload.email || !payload.request_type || !payload.details) {
                    this.setRightsRequestStatus(status, 'Complete all required fields before submitting your request.', 'error');
                    return;
                }

                try {
                    if (submitButton) {
                        submitButton.disabled = true;
                        submitButton.textContent = 'Submitting request...';
                    }

                    const response = await this.postJsonWithFallback('/api/compliance/requests', payload);
                    form.reset();
                    if (pageField) {
                        pageField.value = window.location.href;
                    }
                    if (timestampField) {
                        timestampField.value = new Date().toISOString();
                    }

                    const reference = response.reference_id ? ` Reference: ${response.reference_id}.` : '';
                    this.setRightsRequestStatus(
                        status,
                        `Your request has been recorded and queued for review.${reference}`,
                        'success'
                    );
                } catch (error) {
                    console.warn('Compliance request submission failed:', error);
                    this.setRightsRequestStatus(
                        status,
                        'The request could not be submitted right now. Please use the Information Officer or Deputy Information Officer contacts published on this page if the issue persists.',
                        'error'
                    );
                } finally {
                    if (submitButton) {
                        submitButton.disabled = false;
                        submitButton.textContent = defaultButtonLabel;
                    }
                }
            });
        }

        setRightsRequestStatus(node, message, state) {
            if (!node) {
                return;
            }
            node.hidden = false;
            node.textContent = message;
            node.dataset.state = state;
        }

        logConsentPreferences() {
            if (!window.fetch) {
                return;
            }

            const payload = {
                analytics: !!this.preferences.analytics,
                external_media: !!this.preferences.externalMedia,
                marketing: !!this.preferences.marketing,
                source: this.preferences.source || 'preferences',
                policy_version: this.preferences.version || this.version,
                page_url: window.location.href,
                occurred_at: new Date().toISOString()
            };

            const body = JSON.stringify(payload);
            (async () => {
                for (const url of this.apiCandidates('/api/compliance/consent')) {
                    try {
                        const response = await fetch(url, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body,
                            keepalive: true
                        });
                        if (response.ok) {
                            break;
                        }
                    } catch (error) {
                        continue;
                    }
                }
            })();
        }

        prepareExternalEmbeds() {
            document.querySelectorAll('[data-consent-embed="external-media"]').forEach((container) => {
                const iframe = container.querySelector('iframe[data-src]');
                if (!iframe) {
                    return;
                }

                let gate = container.querySelector('.embedded-consent-gate');
                if (!gate) {
                    gate = document.createElement('div');
                    gate.className = 'embedded-consent-gate';
                    this.setTrustedMarkup(gate, `
                        <h3>Load interactive map</h3>
                        <p>
                            Google Maps is provided by a third party and may process your IP address and device information.
                            You can load the map if you want interactive directions, or continue using the direct directions link.
                        </p>
                        <div class="cookie-consent-actions">
                            <button type="button" class="embedded-consent-btn" data-consent-action="external-media">Load map</button>
                            <button type="button" class="cookie-consent-btn secondary open-cookie-preferences">Manage choices</button>
                        </div>
                    `);
                    container.insertBefore(gate, iframe);
                }

                if (this.preferences.externalMedia) {
                    gate.hidden = true;
                    iframe.hidden = false;
                    if (!iframe.src) {
                        iframe.src = iframe.dataset.src;
                    }
                } else {
                    gate.hidden = false;
                    iframe.hidden = true;
                    iframe.removeAttribute('src');
                }
            });
        }

        activateExternalEmbeds() {
            document.querySelectorAll('[data-consent-embed="external-media"]').forEach((container) => {
                const iframe = container.querySelector('iframe[data-src]');
                if (!iframe) {
                    return;
                }

                iframe.hidden = false;
                if (!iframe.src) {
                    iframe.src = iframe.dataset.src;
                }

                const gate = container.querySelector('.embedded-consent-gate');
                if (gate) {
                    gate.hidden = true;
                }
            });
        }
    }

    window.iBridgeComplianceManager = new ComplianceManager();
    window.openCookiePreferences = function () {
        window.iBridgeComplianceManager?.openPreferencesModal();
    };
})();
