# Lab 6
## Setup SCM with Branching Workflow

---

## Objective

Learn how to set up Git version control for your Terraform project and follow a professional branching workflow with Pull Requests.

---

## Time Estimate

**30-35 minutes**

---

## What You'll Learn

- Initialize a Git repository for Terraform projects
- Create and configure a proper `.gitignore` file for Terraform
- Work with Git branches (main, develop, feature)
- Push code to a remote repository (GitHub)
- Create and merge Pull Requests following a branching workflow

---

## High-Level Instructions

1. Create a GitHub account
2. Create a new GitHub repository
3. Set up your working directory with Terraform files
4. Install GitHub CLI (gh) and authenticate to GitHub
5. Initialize Git in your Terraform project directory
6. Create a `.gitignore` file to exclude Terraform temporary files
7. Make initial commit to main branch
8. Create and switch to develop branch
9. Create a feature branch for new changes
10. Make changes, commit, and push to remote
11. Create a Pull Request from feature branch to develop
12. Review and merge the Pull Request

---

## Documentation Links

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Docs - Creating a Repository](https://docs.github.com/en/repositories/creating-and-managing-repositories)
- [Terraform .gitignore Template](https://github.com/github/gitignore/blob/main/Terraform.gitignore)

---

## Detailed Instructions

### Step 1: Create GitHub Account

1. Go to [github.com](https://github.com)
2. Click **Sign up**
3. Follow the registration process

---

### Step 2: Create a Remote Repository

**On GitHub:**
1. Go to https://github.com
2. Click the **+** icon → **New repository**
3. Repository name: `terraform-aws-project-UserX` (replace UserX with your identifier)
4. Description: "Terraform project"
5. Select **Private** (recommended for infrastructure code)
6. Click **Create repository**

---

### Step 3: Set Up Your Working Directory

Create a new lab6 directory in your home directory and copy the lab4 solution files:

```bash
# Go to home directory
cd

# Create lab6 directory
mkdir lab6

# Copy the lab4 solution files
cp ~/day2/labs/lab4/lab4-solution/* ~/lab6/

# Navigate to lab6 directory
cd ~/lab6
```

**Verify you have Terraform files:**
```bash
ls -la
```

You should see files like `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf`, `terraform.tfvars`, and `staging.tfvars`.

---

### Step 4: Install GitHub CLI (gh)

The GitHub CLI (`gh`) makes it easier to authenticate and work with GitHub from the command line.

**Copy and run the installation script:**

```bash
# Copy the install script to your lab6 directory
cp ~/day2/labs/lab6/lab6-solution/install-gh.sh ~/lab6/

# Run the installation script
cd ~/lab6
bash install-gh.sh
```

**Authenticate with GitHub:**

```bash
gh auth login
```

Follow the prompts:
1. Select **GitHub.com**
2. Select **HTTPS** as preferred protocol
3. When asked to authenticate, select **Login with a web browser**
4. Copy the one-time code shown in the terminal
5. Press Enter to open the browser and paste the code
6. Authorize the GitHub CLI

**Verify authentication:**
```bash
gh auth status
```

You should see a message confirming you are logged in to github.com.

---

### Step 5: Initialize Git Repository

Initialize Git in your project directory:

```bash
cd ~/lab6
git init
git config --global init.defaultBranch main
```

**Verify Git initialization:**
```bash
git status
```

You should see all your files listed as "Untracked files".

---

### Step 6: Copy .gitignore File

Copy the `.gitignore` file from the lab6 solution:

```bash
cp ~/day2/labs/lab6/lab6-solution/.gitignore .
```

**Note:** In this lab, we are including `.tfvars` files in the repository since they don't contain sensitive data in our training environment. However, in production environments, you should **always verify** that your `.tfvars` files don't contain sensitive information (passwords, API keys, etc.) before committing them.

---

### Step 7: Check Git Status

Verify that .gitignore is working:

```bash
git status
```
---

### Step 8: Initial Commit to Main Branch

Add all files and create your first commit:

```bash
# Stage all files
git add .

# Verify what will be committed
git status

# Create initial commit
git commit -m "Initial commit: Add Terraform AWS infrastructure code"
```

**Verify your commit:**
```bash
git log --oneline
```

You should see your commit with the message.

---

### Step 9: Link to Remote Repository

Copy the remote repository URL from GitHub and add it:

**For GitHub (HTTPS):**
```bash
git remote add origin https://github.com/your-username/terraform-aws-project-UserX.git
```

**Verify remote:**
```bash
git remote -v
```

---

### Step 10: Push to Main Branch

Switch to the main branch and push your initial commit to the remote repository:

```bash
git branch -M main
git push -u origin main
```

**Note:** Since you authenticated with GitHub CLI in Step 4, the push should complete without additional prompts.

**Verify on GitHub:**
Open your repository in the web browser and verify your files are there.

---

### Step 11: Create Develop Branch

Create a develop branch for ongoing development:

```bash
# Create and switch to develop branch
git checkout -b develop

# Push develop branch to remote
git push -u origin develop
```

**Verify branches:**
```bash
git branch -a
```

You should see:
- `main`
- `develop` (with asterisk showing it's current)
- Remote tracking branches

---

### Step 12: Create Feature Branch

Create a feature branch for adding new functionality:

```bash
# Create and switch to feature branch
git checkout -b feature/add-tags

# Verify current branch
git branch
```

**Branch naming conventions:**
- `feature/description` - for new features
- `bugfix/description` - for bug fixes
- `hotfix/description` - for urgent production fixes

---

### Step 13: Make Changes to Your Code

Add tags to your infrastructure. Edit your `main.tf` file and add or modify Lab tag to an existing EC2 instance:

```hcl
resource "aws_instance" "web_server" {

  # AMI (Amazon Machine Image) - Amazon Linux 2023 for ap-south-1
  ami = "ami-067ec7f9e54a67559"

  instance_type = "t3.micro"

  tags = {
    Name = "userX"
    Lab = "lab6"
  }
}
```
---

### Step 14: Commit Your Changes

Stage and commit your changes:

```bash
# Check what changed
git status
git diff

# Stage changes
git add .

# Commit with descriptive message
git commit -m "feature: Add Lab tag to an instance for better resource management"
```

**Good commit message practices:**
- Start with type: `feature:`, `bugfix:`, `docs:`, `refactor:`
- Use present tense: "Add" not "Added"
- Be descriptive but concise
- Explain WHY, not just WHAT

---

### Step 15: Push Feature Branch

Push your feature branch to the remote repository:

```bash
git push -u origin feature/add-tags
```

**Expected output:**
```
Enumerating objects: X, done.
...
remote: Create a pull request for 'feature/add-tags' on GitHub by visiting:
remote:   https://github.com/your-username/terraform-aws-project-UserX/pull/new/feature/add-tags
```

---

### Step 16: Create Pull Request (GitHub)

**On GitHub:**
1. Go to your repository on GitHub
2. You'll see a banner: "feature/add-tags had recent pushes"
3. Click **Compare & pull request**
4. **Base branch:** `develop` (NOT main!)
5. **Compare branch:** `feature/add-tags`
6. **Title:** "Add common tags to resources"
7. **Description:**
   ```
   ## Changes
   - Added common tags to all resources
   - Created locals block for tag standardization

   ## Purpose
   Improve resource management and cost tracking through consistent tagging

   ## Testing
   - Validated Terraform syntax
   - Planned changes show tags will be added
   ```
8. Click **Create pull request**

---

### Step 17: Review the Pull Request

**In the PR interface:**

1. **Review the "Files changed" tab**
   - Check the diff to see what's being added/removed
   - Verify no sensitive data is being committed
   - Ensure changes are intentional

2. **Check for conflicts**
   - GitHub will show if there are merge conflicts
   - If conflicts exist, you must resolve them

3. **Add comments** (practice)
   - Click on a line of code
   - Add a comment: "Looks good! Tags will help with cost allocation."
   - Submit review

---

### Step 18: Merge the Pull Request

**On GitHub:**
1. In your Pull Request, click **Merge pull request**
2. Select merge method: **Create a merge commit** (recommended for learning)
3. Click **Confirm merge**
4. Optionally: **Delete branch** (feature/add-tags)

**Success!** Your changes are now in the develop branch.

---

### Step 19: Update Local Repository

Switch back to develop and pull the merged changes:

```bash
# Switch to develop branch
git checkout develop

# Pull the latest changes from remote
git pull origin develop

# Verify your changes are there
git log --oneline --graph --all --decorate
```

**Clean up local feature branch:**
```bash
# Delete local feature branch (now merged)
git branch -d feature/add-tags
```

---

### Step 20: Verify the Workflow

View your branch history:

```bash
git log --oneline --graph --all
```

**You should see:**
```
*   abc1234 (HEAD -> develop, origin/develop) Merge pull request #1 from feature/add-tags
|\
| * def5678 feature: Add common tags to resources for better resource management
|/
* 9876543 (origin/main, main) Initial commit: Add Terraform AWS infrastructure code
```

---

## Understanding the Branching Strategy

### Branch Purposes:

- **main** - Production-ready code only
  - Always stable and deployable
  - Protected branch (no direct commits)
  - Merges come only from develop via PR

- **develop** - Integration branch for features
  - Latest development changes
  - Features merge here first
  - Tested before merging to main

- **feature/** - Individual feature development
  - Created from develop
  - One feature per branch
  - Deleted after merge

---

## Real-World Workflow Summary

```
main (production)
  ↑
  | PR & merge when ready for release
  |
develop (integration)
  ↑
  | PR & merge when feature complete
  |
feature/add-tags (your work)
```

**Best practices:**
1. Never commit directly to main
2. Create feature branches from develop
3. Make small, focused commits
4. Write descriptive commit messages
5. Always use Pull Requests for merging
6. Review code before merging
7. Delete branches after merging

---

## Success Validation

**You've successfully completed this lab if:**

1. Git repository initialized with `.gitignore`
2. Code pushed to remote (GitHub)
3. Three branches created: main, develop, feature/add-tags
4. Pull Request created and merged
5. Local develop branch updated with merged changes
6. Can view commit history with `git log --graph`

---

## Common Issues & Troubleshooting

**Issue: "fatal: remote origin already exists"**
```bash
# Remove and re-add the remote
git remote remove origin
git remote add origin <your-repo-url>
```

**Issue: "src refspec main does not match any"**
```bash
# Make sure you have commits
git log

# Rename branch to main if needed
git branch -M main
```

**Issue: Merge conflicts in PR**
```bash
# Update your feature branch with develop
git checkout feature/add-tags
git merge develop
# Resolve conflicts in files
git add .
git commit -m "Resolve merge conflicts"
git push
```

---

## Optional Challenge

**Challenge 1: Create a Hotfix Workflow**

1. Create a hotfix branch from main:
   ```bash
   git checkout main
   git checkout -b hotfix/fix-security-group
   ```
2. Make a critical fix (e.g., fix security group rules)
3. Commit and push
4. Create PR to merge into BOTH main and develop
5. Merge and verify

**Challenge 2: Protect Your Branches**

On GitHub:
- Enable branch protection for `main` branch
- Require PR reviews before merging
- Require status checks to pass

---

## Clean Up

**Keep your repository** - you'll use it in future labs!

**Optional: Clean up old feature branches**
```bash
# List all branches
git branch -a

# Delete merged local branches
git branch -d feature/add-tags

# Delete remote branches (if not auto-deleted)
git push origin --delete feature/add-tags
```

---

## Key Takeaways

**Git + Terraform = Version Control for Infrastructure**

- `.gitignore` prevents committing sensitive Terraform files
- Branching strategies enable safe, collaborative development
- Pull Requests provide code review and quality control
- Version control gives you history and rollback capability

**Next Lab:** You'll integrate this Git workflow with CI/CD pipelines!

---

## Additional Resources

- [Git Branching - Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Terraform .gitignore Best Practices](https://github.com/github/gitignore/blob/main/Terraform.gitignore)

