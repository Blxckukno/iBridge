# Email Management System

This Python project helps you manage and track email address verification for a list of users in your admin centre.

## Features

- **User Data Management**: Load and manage user data from CSV files
- **Interactive Verification**: Step-by-step email verification process
- **Batch Updates**: Update multiple users quickly
- **Progress Tracking**: Save and resume verification progress
- **Export Options**: Export results to Excel and CSV formats
- **Email Validation**: Basic email format validation

## Files Structure

- `user_manager.py` - Core UserManager class for data handling
- `email_checker.py` - Interactive script for email verification
- `users_data.csv` - User data file with all names and verification status
- `requirements.txt` - Python dependencies

## Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the Email Checker**:
   ```bash
   python email_checker.py
   ```

## Usage

### Interactive Mode
1. Run the script and choose "Interactive Verification Mode"
2. The system will show you each unverified user
3. Check your admin centre for the user's email
4. Mark as:
   - **V** - Verified (enter the email address)
   - **N** - Not found
   - **S** - Skip for now
   - **Q** - Quit and save progress

### Batch Mode
1. Choose "Batch Update Mode"
2. Enter user information in format: `FirstName LastName email@domain.com`
3. For users without emails, use: `FirstName LastName notfound`
4. Type 'done' when finished

## Output Files

- `verification_results.xlsx` - Excel file with complete results
- `users_data_updated.csv` - Updated CSV file with verification status

## Data Structure

Each user record contains:
- **NAME**: First name
- **SURNAME**: Last name  
- **EMAIL_ADDRESS**: Email found in admin centre (if any)
- **TEMPORARY_PASSWORD**: Password field (for future use)
- **VERIFIED**: Status (Verified/Not Found/blank)

## Security Notes

- This tool doesn't connect to external systems automatically
- Manual verification through your admin centre is required
- Handle exported files securely as they may contain sensitive data
- Consider using environment variables for any sensitive configuration

## Getting Started

1. Your user data is already loaded in `users_data.csv`
2. Run `python email_checker.py` to start the verification process
3. Follow the prompts to check each user in your admin centre
4. Export results when complete

The system will track your progress so you can stop and resume anytime.
