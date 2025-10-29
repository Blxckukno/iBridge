import pandas as pd
import csv
from typing import List, Dict, Optional
from pathlib import Path

class UserManager:
    """
    A class to manage user data for email verification and admin centre checking.
    """
    
    def __init__(self):
        self.users_data = []
        self.verified_emails = []
    
    def load_users_from_csv(self, file_path: str) -> None:
        """
        Load user data from a CSV file.
        
        Args:
            file_path (str): Path to the CSV file containing user data
        """
        try:
            df = pd.read_csv(file_path)
            self.users_data = df.to_dict('records')
            print(f"Loaded {len(self.users_data)} users from {file_path}")
        except FileNotFoundError:
            print(f"File {file_path} not found.")
        except Exception as e:
            print(f"Error loading file: {e}")
    
    def create_users_template(self) -> pd.DataFrame:
        """
        Create a template DataFrame with the user data structure.
        
        Returns:
            pd.DataFrame: Template DataFrame with user columns
        """
        users_data = [
            {"NAME": "Aphiwe", "SURNAME": "Ngcobo", "EMAIL_ADDRESS": "", "TEMPORARY_PASSWORD": "", "VERIFIED": ""},
            {"NAME": "Asanda", "SURNAME": "Sibiya", "EMAIL_ADDRESS": "", "TEMPORARY_PASSWORD": "", "VERIFIED": ""},
            {"NAME": "Ayanda", "SURNAME": "Sibiya", "EMAIL_ADDRESS": "", "TEMPORARY_PASSWORD": "", "VERIFIED": ""},
            # Add more users as needed
        ]
        return pd.DataFrame(users_data)
    
    def check_email_format(self, email: str) -> bool:
        """
        Basic email format validation.
        
        Args:
            email (str): Email address to validate
            
        Returns:
            bool: True if email format is valid, False otherwise
        """
        import re
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    def update_verification_status(self, name: str, surname: str, status: str) -> None:
        """
        Update verification status for a specific user.
        
        Args:
            name (str): User's first name
            surname (str): User's surname
            status (str): Verification status (e.g., 'Verified', 'Not Found', 'Pending')
        """
        for user in self.users_data:
            if user.get('NAME', '').strip().lower() == name.strip().lower() and \
               user.get('SURNAME', '').strip().lower() == surname.strip().lower():
                user['VERIFIED'] = status
                break
    
    def export_to_excel(self, file_path: str) -> None:
        """
        Export user data to an Excel file.
        
        Args:
            file_path (str): Path where the Excel file will be saved
        """
        try:
            df = pd.DataFrame(self.users_data)
            df.to_excel(file_path, index=False)
            print(f"Data exported to {file_path}")
        except Exception as e:
            print(f"Error exporting to Excel: {e}")
    
    def get_unverified_users(self) -> List[Dict]:
        """
        Get list of users who haven't been verified yet.
        
        Returns:
            List[Dict]: List of unverified users
        """
        return [user for user in self.users_data 
                if not user.get('VERIFIED') or user.get('VERIFIED').strip() == '']
    
    def print_summary(self) -> None:
        """
        Print a summary of the current verification status.
        """
        total_users = len(self.users_data)
        verified_users = len([u for u in self.users_data if u.get('VERIFIED') == 'Verified'])
        pending_users = len([u for u in self.users_data if not u.get('VERIFIED') or u.get('VERIFIED').strip() == ''])
        
        print(f"\n=== Verification Summary ===")
        print(f"Total Users: {total_users}")
        print(f"Verified: {verified_users}")
        print(f"Pending Verification: {pending_users}")
        print(f"================================\n")

def main():
    """
    Main function to demonstrate the UserManager functionality.
    """
    manager = UserManager()
    
    # Example usage
    print("Email Management System initialized.")
    print("Use the UserManager class to:")
    print("1. Load user data from CSV")
    print("2. Check email verification status")
    print("3. Update verification results")
    print("4. Export results to Excel")
    
    manager.print_summary()

if __name__ == "__main__":
    main()
