# GitHub Account Merge Guide

## Understanding Account Merging

GitHub does not provide a direct way to merge two GitHub accounts. However, there are several approaches you can take to consolidate your work and identity across accounts.

## Options for Consolidating GitHub Accounts

### 1. Transfer Repositories

You can transfer repositories from one account to another:

1. Go to the repository you want to transfer
2. Click **Settings** in the repository menu
3. Scroll down to the **Danger Zone**
4. Click **Transfer ownership**
5. Enter the username of your target account
6. Confirm the transfer

**Note**: This preserves all issues, pull requests, and repository history.

### 2. Manage Multiple Email Addresses

You can add multiple email addresses to a single GitHub account:

1. Go to your GitHub Settings
2. Click **Emails** in the left sidebar
3. Click **Add email address**
4. Enter your other email address
5. Verify the email through the confirmation link sent to that address
6. Optionally set one as your primary email

**Benefits**:
- All commits from different email addresses will be associated with one account
- You can receive notifications at multiple addresses
- You maintain history across email addresses

### 3. Migrate Your Activity

While you can't merge accounts directly, you can:

- **Transfer repositories** to your primary account
- **Add collaborators** from your other account as needed
- **Update email associations** for commits
- **Archive or delete** the secondary account when done

### 4. Configure Git to Use Your Primary Account

Update your local Git configuration to use your primary account:

```bash
# Set your primary email globally
git config --global user.email "your-primary-email@example.com"
git config --global user.name "Your Name"

# Or set it per repository
cd /path/to/repo
git config user.email "your-primary-email@example.com"
git config user.name "Your Name"
```

## Important Considerations

### What You Can Migrate
- ✅ Repositories (via transfer)
- ✅ Stars (manually re-star repositories)
- ✅ Gists (copy/paste to new gists)
- ✅ SSH keys (add to primary account)

### What Cannot Be Migrated
- ❌ Contribution history (commits remain tied to the email used)
- ❌ Issue/PR comments (remain under the original account)
- ❌ Organizations you've created (must transfer separately)
- ❌ Discussions and comments

## Step-by-Step Process

### Step 1: Add Email Addresses
1. Add all email addresses from your secondary account to your primary account
2. Verify all email addresses

### Step 2: Transfer Repositories
1. Transfer important repositories to your primary account
2. Update any webhooks or integrations
3. Update CI/CD configurations if needed

### Step 3: Update Local Git Configuration
```bash
git config --global user.email "primary-email@example.com"
```

### Step 4: Clean Up
1. Remove sensitive data from the secondary account
2. Consider deleting or archiving the secondary account
3. Update any external services pointing to the old account

## GitHub Account Deletion

If you decide to delete your secondary account after migration:

1. Go to GitHub Settings
2. Click **Account** in the left sidebar
3. Scroll to the bottom
4. Click **Delete your account**
5. Follow the confirmation steps

**Warning**: This action is irreversible!

## Resources

- [GitHub Documentation: Managing Multiple Accounts](https://docs.github.com/en/account-and-profile)
- [GitHub Documentation: Transferring a Repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository)
- [GitHub Documentation: Adding an Email Address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/adding-an-email-address-to-your-github-account)

## Contact GitHub Support

For complex account merging scenarios, consider contacting GitHub Support:
- Visit: https://support.github.com
- Explain your situation
- They may be able to assist with specific cases

---

**Note**: This repository serves as a reference guide. The actual account merging process must be performed through GitHub's web interface and account settings.
