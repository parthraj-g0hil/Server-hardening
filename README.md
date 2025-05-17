
# Ubuntu Server Hardening Guide

> **Disclaimer**: All hardening steps are applicable only for **Ubuntu** servers.

If you're looking to harden your new or existing Ubuntu server, you're in the right place!

---

## Prerequisites

1. A valid EC2 **key pair** for SSH access.
2. **Ansible** installed on your local machine.

---

## 🔧 For a New Server Setup (with EBS Attached)

### Step 1: Create a New EC2 Instance via CloudFormation

- Navigate to the `AWS-Cloud-Formation` folder.
- Copy or download `new-instance.yml`.
- Go to the AWS Console > **CloudFormation** > **Create Stack** > **Upload a template file**.
- Upload the `new-instance.yml` file.
- Provide parameters as per your infrastructure requirements.

🎉 **Congratulations!** You've created a new EC2 instance with an EBS volume attached.

---

### Step 2: Run the Hardening Ansible Playbook

- Clone this repository:

  ```bash
  git clone <your-repo-url>
  cd <repo-name>/ansible
  ```

- Update the `inventory.ini` file with your instance's **public IP** and **path to the PEM key**.
- Review and verify the `ansible.cfg` settings.
- Run the playbook:

  ```bash
  ansible-playbook hardening.yml
  ```

---

## 🛠️ For an Already Existing Ubuntu Server

### Step 1: Attach EBS Volume via CloudFormation

- Copy the **Instance ID** of your existing Ubuntu server.
- Navigate to the `AWS-Cloud-Formation` folder.
- Copy or download `already-existed-instance.yml`.
- Go to the AWS Console > **CloudFormation** > **Create Stack** > **Upload a template file**.
- Upload the `already-existed-instance.yml` file.
- Provide parameters accordingly.

🎉 **Congratulations!** You've attached an EBS volume to your existing EC2 server.

---

### Step 2: Run the Hardening Ansible Playbook

- Clone this repository:

  ```bash
  git clone <your-repo-url>
  cd <repo-name>/ansible
  ```

- Update the `inventory.ini` file with your instance's **public IP** and **path to the PEM key**.
- Review and verify the `ansible.cfg` settings.
- Run the playbook:

  ```bash
  ansible-playbook hardening.yml
  ```

---

> **Reminder**: This hardening setup is **Ubuntu-specific**. Make sure you're working with an Ubuntu server.

---

## 📂 Directory Structure

```
├── ansible/
│   ├── inventory.ini
│   ├── ansible.cfg
│   └── hardening.yml
├── AWS-Cloud-Formation/
│   ├── new-instance.yml
│   └── already-existed-instance.yml
└── README.md
```


## 📬 Feedback

Go through my medium blog for more detailed info
https://parth-raj.medium.com/ubuntu-server-hardening-guide-automated-with-ansible-aws-cloud-formation-c0f7570998e7
