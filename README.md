# iBridge LMS Platform 🚀

[![Deploy to GitHub Pages](https://github.com/Blxckukno/iBridgeLMS/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/Blxckukno/iBridgeLMS/actions/workflows/deploy-pages.yml)

**iBridge Contact Solutions** - Complete Learning Management System and Business Process Outsourcing Platform

## 🌐 Live Demo
**Visit the live site:** [https://blxckukno.github.io/iBridgeLMS/](https://blxckukno.github.io/iBridgeLMS/)

## ✨ Features

### 🏗️ **Frontend Platform**
- **Modern Responsive Design** - Mobile-first approach with dark/light mode
- **Progressive Web App** - Offline capabilities and mobile optimization
- **Interactive Dashboards** - Real-time analytics and reporting
- **Multi-page Architecture** - Professional business pages and portfolios
- **Advanced Security** - XSS protection, CSP headers, and secure forms

### 🔧 **Backend Infrastructure**
- **Flask-based APIs** - RESTful endpoints for data management
- **User Authentication** - Role-based access control system
- **Database Management** - SQLite with migration support
- **LMS Functionality** - Course management and progress tracking
- **Ticketing System** - Professional support ticket management

### 🛡️ **Security & IT Toolkit**
- **PowerShell Security Scripts** - Automated security scanning and monitoring
- **Network Administration Tools** - System monitoring and management utilities
- **Malware Protection** - Comprehensive security analysis and reporting
- **Emergency Response** - Incident response and recovery procedures

## 📁 Project Structure

```
iBridge/
├── 🌐 Frontend Files
│   ├── index.html              # Main landing page
│   ├── about.html, services.html, contact.html
│   ├── css/                    # Stylesheets and themes
│   ├── js/                     # Interactive JavaScript modules
│   └── images/                 # Brand assets and media
│
├── 🔧 Backend System
│   ├── backend/
│   │   ├── app.py             # Main Flask application
│   │   ├── lms_app.py         # Learning Management System
│   │   ├── models.py          # Database models
│   │   └── requirements.txt   # Python dependencies
│   │
├── 🎫 Ticketing System
│   └── TicketingSystem/       # Professional support portal
│
├── 🛡️ Security Tools
│   ├── ITtoolkit/             # Network and system utilities
│   ├── SecurityMeasures/      # Incident response tools
│   └── Scripts/               # Deployment and automation
│
└── 📚 Documentation
    ├── DEPLOYMENT_INSTRUCTIONS.md
    ├── SECURITY_DEPLOYMENT_GUIDE.md
    └── Various setup guides
```

## 🚀 Quick Start

### View Online
Simply visit: **[https://blxckukno.github.io/iBridgeLMS/](https://blxckukno.github.io/iBridgeLMS/)**

### Local Development
```bash
# Clone the repository
git clone https://github.com/Blxckukno/iBridgeLMS.git
cd iBridgeLMS

# For static files - just open in browser
open index.html

# For full backend functionality
cd backend
pip install -r requirements.txt
python app.py
# Visit http://localhost:5000
```

### Backend Setup
```bash
# Set up Python virtual environment
python -m venv .venv
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r backend/requirements.txt

# Initialize database
python backend/init_db.py

# Start the server
python backend/app.py
```

## 🎯 Available Pages

- **🏠 Home** - `/index.html` - Main landing page with company overview
- **👥 About** - `/about.html` - Company information and team
- **🔧 Services** - `/services.html` - BPO and BPaaS service offerings
- **📞 Contact** - `/contact.html` - Contact forms and information
- **🎓 LMS Platform** - `/lms-platform.html` - Learning management system
- **🏢 Intranet** - `/intranet.html` - Employee portal and resources
- **🎫 Support** - `/TicketingSystem/frontend/` - Professional ticketing system

## 🔐 Security Features

- **Input Validation** - Comprehensive form validation and sanitization
- **XSS Protection** - Content Security Policy implementation
- **Authentication** - Secure user login and session management
- **Audit Logging** - Complete activity tracking and monitoring
- **Emergency Response** - Automated incident detection and response

## 📈 Deployment

The site automatically deploys to GitHub Pages when changes are pushed to the `master` branch using GitHub Actions.

**Deployment workflow:**
1. Code changes pushed to repository
2. GitHub Actions builds and optimizes assets
3. Static files deployed to GitHub Pages
4. Live site updated at [https://blxckukno.github.io/iBridgeLMS/](https://blxckukno.github.io/iBridgeLMS/)

## 🛠️ Technologies Used

- **Frontend:** HTML5, CSS3, JavaScript ES6+, PWA
- **Backend:** Python Flask, SQLite, RESTful APIs
- **Security:** PowerShell, Windows Security APIs
- **Deployment:** GitHub Actions, GitHub Pages
- **Version Control:** Git with submodules

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📞 Support

For technical support or business inquiries:
- **Website:** [iBridge Contact Solutions](https://blxckukno.github.io/iBridgeLMS/)
- **Issues:** [GitHub Issues](https://github.com/Blxckukno/iBridgeLMS/issues)

---

**iBridge Contact Solutions** - Empowering businesses through technology and exceptional service delivery.
