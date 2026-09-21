# Secure AWS Web Platform Built with Terraform (DEPI Mini Project 1)

مشروع تطبيقي متكامل لبناء منصة ويب آمنة وعالية التوافر على منصة AWS باستخدام أداة **Terraform** كبنية تحتية ككود (Infrastructure as Code)، مع الالتزام بأفضل الممارسات الأمنية (AWS Security Best Practices) والتحكم بالميزانية ($10 Budget Limit).

---

## 📐 Architecture Overview (مخطط البنية التحتية)

تم تصميم البنية التحتية لتكون معزولة ومؤمنة بالكامل على عدة مستويات شبكية وتخزينية:

1. **Network Layer (VPC):**
   - **VPC** بنطاق `10.0.0.0/16` ممتدة عبر منطقتي توافر (us-east-1a & us-east-1b).
   - **Public Subnets:** خاصة بموزع الأحمال (ALB) لتلقي الطلبات الخارجية فقط.
   - **Private Subnets:** معزولة تماماً وتضم خوادم الويب (EC2) وقاعدة البيانات (RDS) ونظام الملفات المشترك (EFS).
   - **VPC Endpoints:** استخدام Interface & Gateway Endpoints للاتصال بخدمات S3 و SSM دون الحاجة لبوابة NAT Gateway أو فتح مسار مباشر للإنترنت.

2. **Compute & Access Layer:**
   - خوادم **EC2 (Amazon Linux 2023)** معزولة داخل Private Subnets بدون Public IP وبدون مفاتيح SSH (`Key-less`).
   - إدارة والاتصال بالخوادم عبر **AWS Systems Manager (Session Manager)** لضمان الأمان والتدقيق.

3. **Storage & Database Layer:**
   - **EBS Encryption:** أقراص النظام مشفرة بالكامل أثناء الراحة (At Rest).
   - **AWS EFS:** نظام ملفات مشترك ومشفر بين الخوادم في مناطق التوافر المختلفة.
   - **AWS S3:** حاوية تخزين مشفرة مع حظر كامل للوصول العام (Block All Public Access) وتفعيل حفظ الإصدارات (Versioning).
   - **AWS RDS (MySQL):** قاعدة بيانات مشفرة ومخبأة داخل Private Subnets لا تقبل الاتصال إلا من خوادم التطبيق عبر Security Group مخصص.

4. **Load Balancing, Edge Security & Logging:**
   - **Application Load Balancer (ALB):** توزيع الحمل عبر بورت 80 مع متابعة دورية لصحة الخوادم (Health Checks).
   - **Amazon CloudFront CDN:** تسريع وتأمين تسليم المحتوى وتوفير حماية إضافية على مستوى الـ Edge.
   - **VPC Flow Logs & CloudWatch:** تسجيل وتتبع حركة المرور الشبكية داخل الـ VPC للأغراض الأمنية والتدقيق.

---

## 📂 Project Directory Structure (هيكل المشروع)

```text
depi-aws-security-mini-project-1/
├── README.md
├── screenshots/
│   ├── 01-budget.png
│   ├── 04-route-tables.png
│   ├── 05-security-groups.png
│   ├── 06-nacl-rules.png
│   ├── 07-vpc-endpoints.png
│   ├── 08-session-manager.png
│   ├── 09-ebs-encrypted.png
│   ├── 09-efs-shared.png
│   ├── 10-s3-block-public.png
│   ├── 11-rds-encrypted.png
│   ├── 12-alb-healthy.png
│   ├── 13-cloudfront-https.png
│   └── 14-vpc-flow-logs.png
└── terraform/
    ├── alb.tf           # Application Load Balancer, Target Group, Listeners
    ├── budget.tf        # AWS Monthly Budget ($10) & Cost Control Policy
    ├── cloudfront.tf    # CloudFront CDN Distribution
    ├── ec2.tf           # EC2 Private Web Servers & Block Devices
    ├── endpoints.tf     # S3 Gateway & SSM Interface Endpoints
    ├── iam.tf           # IAM Roles, Instance Profiles, Pass Policy
    ├── logging.tf       # VPC Flow Logs & CloudWatch Log Group
    ├── outputs.tf       # Infrastructure Outputs (DNS, S3 Name, RDS Endpoint)
    ├── provider.tf      # AWS Provider configuration
    ├── rds.tf           # MySQL Encrypted Database & Subnet Groups
    ├── security.tf      # Tiered Security Groups & Network ACLs
    ├── storage.tf       # Encrypted S3 Bucket & EFS File System
    ├── variables.tf     # Terraform Project Variables
    └── versions.tf      # Terraform Required Providers & Versions


    ## 🚀 Deployment Instructions (خطوات التشغيل التفصيلية)

### 1. المتطلبات الأساسية (Prerequisites)

قبل البدء في تطبيق المشروع، تأكد من توفر الأدوات والإعدادات التالية على جهازك:

* **تثبيت أداة Terraform (الإصدار `>= 1.5.0`):**
  * قم بتنزيل أداة Terraform من [الموقع الرسمي](https://developer.hashicorp.com/terraform/downloads).
  * للتأكد من تثبيت الأداة والتحقق من الإصدار، نفّذ الأمر التالي في Terminal:
    ```bash
    terraform -v
    ```
* **تثبيت وتكوين AWS CLI:**
  * قم بتنزيل وتثبيت أداة [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
  * قم بضبط بيانات الاعتماد (Access Key & Secret Key) الخاصة بالمستخدم `depi-admin`:
    ```bash
    aws configure
    ```
    *سيتطلب منك إدخال البيانات التالية:*
    - **AWS Access Key ID:** مفتاح الوصول الخاص بك.
    - **AWS Secret Access Key:** المفتاح السري.
    - **Default region name:** `us-east-1`
    - **Default output format:** `json`
  * للتحقق من نجاح الاتصال بحسابك على AWS، نفّذ الأمر:
    ```bash
    aws sts get-caller-identity
    ```
* **بيئة التطوير (VS Code & Git):**
  * يُوصى باستخدام محرر VS Code مع إضافة **HashiCorp Terraform Extension** لتسهيل تظليل ومحاذاة الأكواد.

---

### 2. خطوات التطبيق والتنفيذ (Step-by-Step Execution)

#### الخطوة 1: الانتقال إلى مجلد المشروع
افتح الـ Terminal وانتقل إلى المجلد الذي يحتوي على أكواد Terraform:
```bash
cd terraform