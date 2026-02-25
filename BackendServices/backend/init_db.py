"""
Initialize iBridge backend database.
"""

import os
from datetime import datetime

from app import app
from models import Course, User, db


def initialize():
    with app.app_context():
        db.create_all()

        admin_username = os.environ.get("IBRIDGE_ADMIN_USERNAME", "admin")
        admin_email = os.environ.get("IBRIDGE_ADMIN_EMAIL", "admin@ibridge-solutions.com")
        admin_password = os.environ.get("IBRIDGE_ADMIN_PASSWORD")

        if admin_password and not User.query.filter_by(username=admin_username).first():
            admin = User(
                username=admin_username,
                email=admin_email,
                role="admin",
                department="Administration",
                created_at=datetime.utcnow(),
                password_changed_at=datetime.utcnow(),
            )
            admin.set_password(admin_password)
            db.session.add(admin)

        if not Course.query.first():
            db.session.add(
                Course(
                    title="Cybersecurity Essentials",
                    description="Learn essential cybersecurity concepts and best practices.",
                    category="Security",
                    instructor="Security Team",
                    duration_hours=8,
                    difficulty="intermediate",
                    created_at=datetime.utcnow(),
                )
            )
            db.session.add(
                Course(
                    title="Customer Service Excellence",
                    description="Master practical customer support and communication skills.",
                    category="Customer Service",
                    instructor="Training Department",
                    duration_hours=6,
                    difficulty="beginner",
                    created_at=datetime.utcnow(),
                )
            )

        db.session.commit()
        print("Database initialization complete.")


if __name__ == "__main__":
    initialize()
