#!/usr/bin/env python3
"""
Email Verification Checker Script

This script helps you manage the process of checking email addresses
in your admin centre and tracking verification status.
"""

from user_manager import UserManager
import sys

def interactive_verification():
    """
    Interactive mode for checking email verification status.
    """
    manager = UserManager()
    
    # Load user data
    manager.load_users_from_csv('users_data.csv')
    
    print("\n=== Email Verification Checker ===")
    print("This tool will help you track email verification status.")
    print("You'll need to manually check your admin centre for each user.\n")
    
    unverified_users = manager.get_unverified_users()
    
    if not unverified_users:
        print("All users have been processed!")
        return
    
    print(f"Found {len(unverified_users)} users to verify.\n")
    
    for i, user in enumerate(unverified_users, 1):
        name = user.get('NAME', '')
        surname = user.get('SURNAME', '')
        
        print(f"\n[{i}/{len(unverified_users)}] Checking: {name} {surname}")
        print("Please check your admin centre for this user.")
        
        while True:
            choice = input("Status (V=Verified/Email found, N=Not found, S=Skip, Q=Quit): ").strip().upper()
            
            if choice == 'V':
                email = input("Enter the email address found: ").strip()
                if manager.check_email_format(email):
                    user['EMAIL_ADDRESS'] = email
                    user['VERIFIED'] = 'Verified'
                    print(f"✓ Marked as verified with email: {email}")
                    break
                else:
                    print("Invalid email format. Please try again.")
            
            elif choice == 'N':
                user['VERIFIED'] = 'Not Found'
                print("✗ Marked as not found")
                break
            
            elif choice == 'S':
                print("⏭ Skipped")
                break
            
            elif choice == 'Q':
                print("Quitting...")
                save_progress(manager)
                return
            
            else:
                print("Invalid choice. Please enter V, N, S, or Q.")
    
    save_progress(manager)

def save_progress(manager):
    """
    Save the current progress to files.
    """
    try:
        # Save to Excel
        manager.export_to_excel('verification_results.xlsx')
        
        # Save to CSV
        import pandas as pd
        df = pd.DataFrame(manager.users_data)
        df.to_csv('users_data_updated.csv', index=False)
        
        print("\n✓ Progress saved to:")
        print("  - verification_results.xlsx")
        print("  - users_data_updated.csv")
        
        manager.print_summary()
        
    except Exception as e:
        print(f"Error saving progress: {e}")

def batch_update_mode():
    """
    Batch mode for updating multiple users at once.
    """
    manager = UserManager()
    manager.load_users_from_csv('users_data.csv')
    
    print("\n=== Batch Update Mode ===")
    print("Format: FirstName LastName email@domain.com")
    print("Enter 'done' when finished, 'notfound' for users without emails")
    print("Example: John Doe john.doe@company.com")
    print("Example: Jane Smith notfound\n")
    
    while True:
        user_input = input("Enter user info: ").strip()
        
        if user_input.lower() == 'done':
            break
        
        parts = user_input.split()
        if len(parts) < 3:
            print("Invalid format. Please use: FirstName LastName email@domain.com")
            continue
        
        name = parts[0]
        surname = parts[1]
        email_or_status = ' '.join(parts[2:])
        
        if email_or_status.lower() == 'notfound':
            manager.update_verification_status(name, surname, 'Not Found')
            print(f"✗ {name} {surname} marked as not found")
        elif manager.check_email_format(email_or_status):
            # Find and update the user
            for user in manager.users_data:
                if (user.get('NAME', '').strip().lower() == name.lower() and 
                    user.get('SURNAME', '').strip().lower() == surname.lower()):
                    user['EMAIL_ADDRESS'] = email_or_status
                    user['VERIFIED'] = 'Verified'
                    print(f"✓ {name} {surname} updated with email: {email_or_status}")
                    break
            else:
                print(f"⚠ User {name} {surname} not found in database")
        else:
            print("Invalid email format or command")
    
    save_progress(manager)

def main():
    """
    Main function with menu system.
    """
    while True:
        print("\n=== Email Management System ===")
        print("1. Interactive Verification Mode")
        print("2. Batch Update Mode")
        print("3. View Summary")
        print("4. Export Current Data")
        print("5. Exit")
        
        choice = input("\nSelect an option (1-5): ").strip()
        
        if choice == '1':
            interactive_verification()
        elif choice == '2':
            batch_update_mode()
        elif choice == '3':
            manager = UserManager()
            manager.load_users_from_csv('users_data.csv')
            manager.print_summary()
        elif choice == '4':
            manager = UserManager()
            manager.load_users_from_csv('users_data.csv')
            save_progress(manager)
        elif choice == '5':
            print("Goodbye!")
            break
        else:
            print("Invalid choice. Please select 1-5.")

if __name__ == "__main__":
    main()
