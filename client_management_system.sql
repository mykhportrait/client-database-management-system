-- =============================================================================
-- CLIENT MANAGEMENT SYSTEM - MySQL Database Script
-- Version: 1.0 | Compatible: MySQL 8.0+
-- Normalization: Up to Third Normal Form (3NF)
-- =============================================================================
-- HOW TO IMPORT:
--   phpMyAdmin : Import > Choose File > Run
--   MySQL CLI  : mysql -u root -p < client_management_system.sql
--   Workbench  : File > Run SQL Script
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- =============================================================================
-- 1. DATABASE CREATION
-- =============================================================================

DROP DATABASE IF EXISTS client_mgmt;
CREATE DATABASE client_mgmt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE client_mgmt;

-- =============================================================================
-- 2. TABLE CREATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.01  user_roles  (lookup table — no FK dependencies)
--       Stores role definitions: Admin, HR, Manager, Employee
-- -----------------------------------------------------------------------------
CREATE TABLE user_roles (
    role_id      TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_name    VARCHAR(50)      NOT NULL,
    description  VARCHAR(255)     DEFAULT NULL,
    created_at   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB COMMENT='Application-level roles for access control';

-- -----------------------------------------------------------------------------
-- 2.02  departments  (lookup table)
--       Each department belongs to the same organisation; no circular FKs yet.
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    dept_id      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    dept_name    VARCHAR(100)      NOT NULL,
    dept_code    VARCHAR(10)       NOT NULL,
    location     VARCHAR(100)      DEFAULT NULL,
    budget       DECIMAL(15,2)     DEFAULT 0.00,
    is_active    TINYINT(1)        NOT NULL DEFAULT 1,
    created_at   DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (dept_id),
    UNIQUE KEY uq_dept_code (dept_code)
) ENGINE=InnoDB COMMENT='Organisational departments';

-- -----------------------------------------------------------------------------
-- 2.03  designations  (lookup table)
-- -----------------------------------------------------------------------------
CREATE TABLE designations (
    desig_id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title        VARCHAR(100)      NOT NULL,
    grade        VARCHAR(10)       DEFAULT NULL,
    min_salary   DECIMAL(12,2)     DEFAULT 0.00,
    max_salary   DECIMAL(12,2)     DEFAULT 0.00,
    dept_id      SMALLINT UNSIGNED NOT NULL,
    created_at   DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (desig_id),
    CONSTRAINT fk_desig_dept FOREIGN KEY (dept_id)
        REFERENCES departments (dept_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Job titles/designations per department';

-- -----------------------------------------------------------------------------
-- 2.04  employees  (core table)
--       Personal info, contact, address, credentials, employment details.
--       dept_id / desig_id are set here; manager_id is a self-referencing FK.
-- -----------------------------------------------------------------------------
CREATE TABLE employees (
    emp_id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    emp_code         VARCHAR(20)     NOT NULL,
    -- Personal information
    first_name       VARCHAR(50)     NOT NULL,
    last_name        VARCHAR(50)     NOT NULL,
    gender           ENUM('Male','Female','Other') NOT NULL,
    date_of_birth    DATE            NOT NULL,
    national_id      VARCHAR(30)     DEFAULT NULL,
    -- Contact details
    email            VARCHAR(100)    NOT NULL,
    phone            VARCHAR(20)     DEFAULT NULL,
    alt_phone        VARCHAR(20)     DEFAULT NULL,
    -- Address (decomposed to 3NF — city/state/country are separate lookups
    --          but kept inline here for practical project scope)
    address_line1    VARCHAR(150)    DEFAULT NULL,
    address_line2    VARCHAR(150)    DEFAULT NULL,
    city             VARCHAR(60)     DEFAULT NULL,
    state            VARCHAR(60)     DEFAULT NULL,
    postal_code      VARCHAR(20)     DEFAULT NULL,
    country          VARCHAR(60)     DEFAULT 'India',
    -- Employment details
    joining_date     DATE            NOT NULL,
    termination_date DATE            DEFAULT NULL,
    employment_type  ENUM('Full-Time','Part-Time','Contract','Intern') NOT NULL DEFAULT 'Full-Time',
    employment_status ENUM('Active','Inactive','Resigned','Terminated','On-Leave') NOT NULL DEFAULT 'Active',
    dept_id          SMALLINT UNSIGNED NOT NULL,
    desig_id         SMALLINT UNSIGNED NOT NULL,
    manager_id       INT UNSIGNED    DEFAULT NULL,          -- self-referencing
    base_salary      DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    -- Emergency contact
    emergency_name   VARCHAR(100)    DEFAULT NULL,
    emergency_phone  VARCHAR(20)     DEFAULT NULL,
    emergency_rel    VARCHAR(30)     DEFAULT NULL,
    -- Profile
    profile_photo    VARCHAR(255)    DEFAULT 'default.png',
    bio              TEXT            DEFAULT NULL,
    -- Login credentials
    username         VARCHAR(50)     NOT NULL,
    password_hash    VARCHAR(255)    NOT NULL,
    role_id          TINYINT UNSIGNED NOT NULL DEFAULT 4,   -- 4 = Employee
    last_login       DATETIME        DEFAULT NULL,
    is_active        TINYINT(1)      NOT NULL DEFAULT 1,
    -- Audit timestamps
    created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (emp_id),
    UNIQUE KEY uq_emp_code    (emp_code),
    UNIQUE KEY uq_email       (email),
    UNIQUE KEY uq_username    (username),
    UNIQUE KEY uq_national_id (national_id),
    -- Indexes for frequent lookups
    INDEX idx_dept        (dept_id),
    INDEX idx_desig       (desig_id),
    INDEX idx_manager     (manager_id),
    INDEX idx_status      (employment_status),
    INDEX idx_joining     (joining_date),
    CONSTRAINT fk_emp_dept    FOREIGN KEY (dept_id)    REFERENCES departments  (dept_id)    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_emp_desig   FOREIGN KEY (desig_id)   REFERENCES designations (desig_id)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_emp_role    FOREIGN KEY (role_id)    REFERENCES user_roles   (role_id)    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) REFERENCES employees    (emp_id)     ON DELETE SET NULL  ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Core employee master table';

-- -----------------------------------------------------------------------------
-- 2.05  administrators  (extends employees for admin-specific metadata)
-- -----------------------------------------------------------------------------
CREATE TABLE administrators (
    admin_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    emp_id          INT UNSIGNED NOT NULL,
    access_level    TINYINT      NOT NULL DEFAULT 1  COMMENT '1=Full,2=Restricted',
    can_manage_payroll  TINYINT(1) NOT NULL DEFAULT 1,
    can_manage_leaves   TINYINT(1) NOT NULL DEFAULT 1,
    can_view_reports    TINYINT(1) NOT NULL DEFAULT 1,
    assigned_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (admin_id),
    UNIQUE KEY uq_admin_emp (emp_id),
    CONSTRAINT fk_admin_emp FOREIGN KEY (emp_id) REFERENCES employees (emp_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Admin-specific permissions and access levels';

-- -----------------------------------------------------------------------------
-- 2.06  leave_types  (lookup)
-- -----------------------------------------------------------------------------
CREATE TABLE leave_types (
    leave_type_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    type_name       VARCHAR(50)      NOT NULL,
    annual_quota    TINYINT          NOT NULL DEFAULT 12,
    is_paid         TINYINT(1)       NOT NULL DEFAULT 1,
    carry_forward   TINYINT(1)       NOT NULL DEFAULT 0,
    PRIMARY KEY (leave_type_id),
    UNIQUE KEY uq_leave_type_name (type_name)
) ENGINE=InnoDB COMMENT='Types of leave available in the organisation';

-- -----------------------------------------------------------------------------
-- 2.07  leave_balances  (per employee per leave type per year)
-- -----------------------------------------------------------------------------
CREATE TABLE leave_balances (
    balance_id      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    emp_id          INT UNSIGNED     NOT NULL,
    leave_type_id   TINYINT UNSIGNED NOT NULL,
    year            YEAR             NOT NULL,
    total_days      DECIMAL(5,1)     NOT NULL DEFAULT 0,
    used_days       DECIMAL(5,1)     NOT NULL DEFAULT 0,
    pending_days    DECIMAL(5,1)     NOT NULL DEFAULT 0,
    remaining_days  DECIMAL(5,1)     GENERATED ALWAYS AS (total_days - used_days - pending_days) STORED,
    PRIMARY KEY (balance_id),
    UNIQUE KEY uq_balance (emp_id, leave_type_id, year),
    INDEX idx_lb_emp  (emp_id),
    CONSTRAINT fk_lb_emp        FOREIGN KEY (emp_id)        REFERENCES employees   (emp_id)        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_lb_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types (leave_type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Per-employee annual leave balance tracking';

-- -----------------------------------------------------------------------------
-- 2.08  leave_requests
-- -----------------------------------------------------------------------------
CREATE TABLE leave_requests (
    request_id      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    emp_id          INT UNSIGNED     NOT NULL,
    leave_type_id   TINYINT UNSIGNED NOT NULL,
    start_date      DATE             NOT NULL,
    end_date        DATE             NOT NULL,
    total_days      DECIMAL(5,1)     NOT NULL DEFAULT 1,
    reason          TEXT             DEFAULT NULL,
    status          ENUM('Pending','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
    approved_by     INT UNSIGNED     DEFAULT NULL,
    approved_at     DATETIME         DEFAULT NULL,
    rejection_note  TEXT             DEFAULT NULL,
    applied_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (request_id),
    INDEX idx_lr_emp    (emp_id),
    INDEX idx_lr_status (status),
    CONSTRAINT fk_lr_emp        FOREIGN KEY (emp_id)        REFERENCES employees   (emp_id)        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_lr_leave_type FOREIGN KEY (leave_type_id) REFERENCES leave_types (leave_type_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_lr_approver   FOREIGN KEY (approved_by)   REFERENCES employees   (emp_id)        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Employee leave applications and approvals';

-- -----------------------------------------------------------------------------
-- 2.09  attendance
-- -----------------------------------------------------------------------------
CREATE TABLE attendance (
    attendance_id   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    emp_id          INT UNSIGNED     NOT NULL,
    attendance_date DATE             NOT NULL,
    check_in        TIME             DEFAULT NULL,
    check_out       TIME             DEFAULT NULL,
    work_hours      DECIMAL(4,2)     GENERATED ALWAYS AS (
                        CASE WHEN check_in IS NOT NULL AND check_out IS NOT NULL
                             THEN ROUND(TIME_TO_SEC(TIMEDIFF(check_out, check_in)) / 3600, 2)
                             ELSE 0 END
                    ) STORED,
    status          ENUM('Present','Absent','Half-Day','Late','WFH','Holiday','Leave') NOT NULL DEFAULT 'Present',
    overtime_hours  DECIMAL(4,2)     NOT NULL DEFAULT 0.00,
    remarks         VARCHAR(255)     DEFAULT NULL,
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (attendance_id),
    UNIQUE KEY uq_att_emp_date (emp_id, attendance_date),
    INDEX idx_att_date   (attendance_date),
    INDEX idx_att_status (status),
    CONSTRAINT fk_att_emp FOREIGN KEY (emp_id) REFERENCES employees (emp_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Daily attendance records with computed work hours';

-- -----------------------------------------------------------------------------
-- 2.10  holidays  (company calendar)
-- -----------------------------------------------------------------------------
CREATE TABLE holidays (
    holiday_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    holiday_name  VARCHAR(100)      NOT NULL,
    holiday_date  DATE              NOT NULL,
    holiday_type  ENUM('National','Regional','Optional','Company') NOT NULL DEFAULT 'National',
    is_paid       TINYINT(1)        NOT NULL DEFAULT 1,
    description   VARCHAR(255)      DEFAULT NULL,
    PRIMARY KEY (holiday_id),
    UNIQUE KEY uq_holiday_date_name (holiday_date, holiday_name),
    INDEX idx_holiday_date (holiday_date)
) ENGINE=InnoDB COMMENT='Company holiday calendar';

-- -----------------------------------------------------------------------------
-- 2.11  payroll_periods  (month-year master to avoid repeating dates)
-- -----------------------------------------------------------------------------
CREATE TABLE payroll_periods (
    period_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    period_month TINYINT           NOT NULL COMMENT '1-12',
    period_year  YEAR              NOT NULL,
    start_date   DATE              NOT NULL,
    end_date     DATE              NOT NULL,
    status       ENUM('Open','Processed','Closed') NOT NULL DEFAULT 'Open',
    processed_by INT UNSIGNED      DEFAULT NULL,
    processed_at DATETIME          DEFAULT NULL,
    PRIMARY KEY (period_id),
    UNIQUE KEY uq_period (period_month, period_year),
    CONSTRAINT fk_pp_emp FOREIGN KEY (processed_by) REFERENCES employees (emp_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Payroll run periods';

-- -----------------------------------------------------------------------------
-- 2.12  payroll  (one record per employee per payroll period)
-- -----------------------------------------------------------------------------
CREATE TABLE payroll (
    payroll_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    emp_id           INT UNSIGNED     NOT NULL,
    period_id        SMALLINT UNSIGNED NOT NULL,
    basic_salary     DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    hra              DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    conveyance       DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    medical          DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    other_allowance  DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    gross_salary     DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    pf_deduction     DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    tax_deduction    DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    loan_deduction   DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    other_deduction  DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    total_deduction  DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    net_salary       DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    overtime_pay     DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    bonus            DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    working_days     TINYINT          NOT NULL DEFAULT 0,
    present_days     TINYINT          NOT NULL DEFAULT 0,
    absent_days      TINYINT          NOT NULL DEFAULT 0,
    leave_days       TINYINT          NOT NULL DEFAULT 0,
    payment_status   ENUM('Pending','Paid','On-Hold') NOT NULL DEFAULT 'Pending',
    payment_date     DATE             DEFAULT NULL,
    payment_mode     ENUM('Bank Transfer','Cash','Cheque') DEFAULT 'Bank Transfer',
    bank_ref         VARCHAR(50)      DEFAULT NULL,
    remarks          TEXT             DEFAULT NULL,
    created_at       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (payroll_id),
    UNIQUE KEY uq_payroll_emp_period (emp_id, period_id),
    INDEX idx_pay_period  (period_id),
    INDEX idx_pay_status  (payment_status),
    CONSTRAINT fk_pay_emp    FOREIGN KEY (emp_id)    REFERENCES employees       (emp_id)    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pay_period FOREIGN KEY (period_id) REFERENCES payroll_periods (period_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Monthly payroll calculations per employee';

-- -----------------------------------------------------------------------------
-- 2.13  salary_slips  (generated PDF/record per payroll entry)
-- -----------------------------------------------------------------------------
CREATE TABLE salary_slips (
    slip_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    payroll_id     INT UNSIGNED NOT NULL,
    emp_id         INT UNSIGNED NOT NULL,
    slip_number    VARCHAR(30)  NOT NULL,
    generated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    file_path      VARCHAR(255) DEFAULT NULL,
    is_sent        TINYINT(1)   NOT NULL DEFAULT 0,
    sent_at        DATETIME     DEFAULT NULL,
    PRIMARY KEY (slip_id),
    UNIQUE KEY uq_slip_number (slip_number),
    UNIQUE KEY uq_slip_payroll (payroll_id),
    CONSTRAINT fk_slip_payroll FOREIGN KEY (payroll_id) REFERENCES payroll   (payroll_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_slip_emp     FOREIGN KEY (emp_id)     REFERENCES employees (emp_id)     ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Salary slip records linked to payroll entries';

-- -----------------------------------------------------------------------------
-- 2.14  projects
-- -----------------------------------------------------------------------------
CREATE TABLE projects (
    project_id    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    project_code  VARCHAR(20)   NOT NULL,
    project_name  VARCHAR(150)  NOT NULL,
    description   TEXT          DEFAULT NULL,
    dept_id       SMALLINT UNSIGNED NOT NULL,
    client_name   VARCHAR(100)  DEFAULT NULL,
    start_date    DATE          NOT NULL,
    end_date      DATE          DEFAULT NULL,
    budget        DECIMAL(15,2) DEFAULT 0.00,
    status        ENUM('Planning','Active','On-Hold','Completed','Cancelled') NOT NULL DEFAULT 'Planning',
    priority      ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    manager_id    INT UNSIGNED  DEFAULT NULL,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id),
    UNIQUE KEY uq_project_code (project_code),
    INDEX idx_proj_dept   (dept_id),
    INDEX idx_proj_status (status),
    CONSTRAINT fk_proj_dept    FOREIGN KEY (dept_id)    REFERENCES departments (dept_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_proj_manager FOREIGN KEY (manager_id) REFERENCES employees  (emp_id)  ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Projects undertaken by the organisation';

-- -----------------------------------------------------------------------------
-- 2.15  project_assignments  (M:N — employees <-> projects)
-- -----------------------------------------------------------------------------
CREATE TABLE project_assignments (
    assignment_id  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    project_id     INT UNSIGNED  NOT NULL,
    emp_id         INT UNSIGNED  NOT NULL,
    role_in_project VARCHAR(80)  DEFAULT 'Member',
    assigned_date  DATE          NOT NULL DEFAULT (CURRENT_DATE),
    released_date  DATE          DEFAULT NULL,
    allocation_pct TINYINT       NOT NULL DEFAULT 100  COMMENT 'Percentage of time allocated',
    is_active      TINYINT(1)    NOT NULL DEFAULT 1,
    remarks        VARCHAR(255)  DEFAULT NULL,
    PRIMARY KEY (assignment_id),
    UNIQUE KEY uq_assign (project_id, emp_id),
    INDEX idx_pa_emp (emp_id),
    CONSTRAINT fk_pa_project FOREIGN KEY (project_id) REFERENCES projects  (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pa_emp     FOREIGN KEY (emp_id)     REFERENCES employees (emp_id)     ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Employee-project assignment mapping';

-- -----------------------------------------------------------------------------
-- 2.16  performance_evaluations
-- -----------------------------------------------------------------------------
CREATE TABLE performance_evaluations (
    eval_id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    emp_id          INT UNSIGNED NOT NULL,
    evaluator_id    INT UNSIGNED NOT NULL,
    eval_period     VARCHAR(20)  NOT NULL COMMENT 'e.g. Q1-2025',
    eval_date       DATE         NOT NULL,
    -- KPI scores (1–10)
    quality_score   TINYINT      NOT NULL DEFAULT 5,
    productivity    TINYINT      NOT NULL DEFAULT 5,
    teamwork        TINYINT      NOT NULL DEFAULT 5,
    communication   TINYINT      NOT NULL DEFAULT 5,
    leadership      TINYINT      NOT NULL DEFAULT 5,
    overall_score   DECIMAL(4,2) NOT NULL DEFAULT 5.00,
    rating          ENUM('Exceptional','Exceeds Expectations','Meets Expectations','Below Expectations','Unsatisfactory') NOT NULL DEFAULT 'Meets Expectations',
    strengths       TEXT         DEFAULT NULL,
    improvements    TEXT         DEFAULT NULL,
    goals_next      TEXT         DEFAULT NULL,
    comments        TEXT         DEFAULT NULL,
    status          ENUM('Draft','Submitted','Acknowledged') NOT NULL DEFAULT 'Draft',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (eval_id),
    INDEX idx_pe_emp      (emp_id),
    INDEX idx_pe_period   (eval_period),
    CONSTRAINT fk_pe_emp       FOREIGN KEY (emp_id)      REFERENCES employees (emp_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pe_evaluator FOREIGN KEY (evaluator_id) REFERENCES employees (emp_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Periodic employee performance evaluations';

-- -----------------------------------------------------------------------------
-- 2.17  announcements
-- -----------------------------------------------------------------------------
CREATE TABLE announcements (
    announcement_id INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    title           VARCHAR(200)  NOT NULL,
    body            TEXT          NOT NULL,
    published_by    INT UNSIGNED  NOT NULL,
    target_dept_id  SMALLINT UNSIGNED DEFAULT NULL  COMMENT 'NULL = all departments',
    priority        ENUM('Normal','Important','Urgent') NOT NULL DEFAULT 'Normal',
    publish_date    DATE          NOT NULL DEFAULT (CURRENT_DATE),
    expiry_date     DATE          DEFAULT NULL,
    is_active       TINYINT(1)    NOT NULL DEFAULT 1,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (announcement_id),
    INDEX idx_ann_dept (target_dept_id),
    INDEX idx_ann_date (publish_date),
    CONSTRAINT fk_ann_author FOREIGN KEY (published_by)   REFERENCES employees  (emp_id)  ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ann_dept   FOREIGN KEY (target_dept_id) REFERENCES departments (dept_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Organisation-wide or department-specific announcements';

-- -----------------------------------------------------------------------------
-- 2.18  notifications
-- -----------------------------------------------------------------------------
CREATE TABLE notifications (
    notif_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    emp_id       INT UNSIGNED    NOT NULL,
    title        VARCHAR(150)    NOT NULL,
    message      TEXT            NOT NULL,
    type         ENUM('Info','Warning','Alert','Leave','Payroll','Attendance') NOT NULL DEFAULT 'Info',
    is_read      TINYINT(1)      NOT NULL DEFAULT 0,
    read_at      DATETIME        DEFAULT NULL,
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (notif_id),
    INDEX idx_notif_emp  (emp_id),
    INDEX idx_notif_read (is_read),
    CONSTRAINT fk_notif_emp FOREIGN KEY (emp_id) REFERENCES employees (emp_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='In-app notifications per employee';

-- -----------------------------------------------------------------------------
-- 2.19  login_history
-- -----------------------------------------------------------------------------
CREATE TABLE login_history (
    log_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    emp_id       INT UNSIGNED    NOT NULL,
    login_time   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_time  DATETIME        DEFAULT NULL,
    ip_address   VARCHAR(45)     DEFAULT NULL,
    user_agent   VARCHAR(255)    DEFAULT NULL,
    status       ENUM('Success','Failed','Locked') NOT NULL DEFAULT 'Success',
    PRIMARY KEY (log_id),
    INDEX idx_lh_emp  (emp_id),
    INDEX idx_lh_time (login_time),
    CONSTRAINT fk_lh_emp FOREIGN KEY (emp_id) REFERENCES employees (emp_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Employee login/logout history for security auditing';

-- -----------------------------------------------------------------------------
-- 2.20  audit_logs  (immutable change tracking across all tables)
-- -----------------------------------------------------------------------------
CREATE TABLE audit_logs (
    audit_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    table_name   VARCHAR(60)     NOT NULL,
    record_id    VARCHAR(20)     NOT NULL,
    action       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    changed_by   INT UNSIGNED    DEFAULT NULL,
    old_values   JSON            DEFAULT NULL,
    new_values   JSON            DEFAULT NULL,
    changed_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address   VARCHAR(45)     DEFAULT NULL,
    PRIMARY KEY (audit_id),
    INDEX idx_al_table  (table_name),
    INDEX idx_al_record (record_id),
    INDEX idx_al_time   (changed_at),
    CONSTRAINT fk_al_emp FOREIGN KEY (changed_by) REFERENCES employees (emp_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Immutable audit trail for all data changes';

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 3. ADDITIONAL CONSTRAINTS VIA ALTER TABLE
-- =============================================================================

-- Ensure check_out > check_in
ALTER TABLE attendance
    ADD CONSTRAINT chk_checkout CHECK (check_out IS NULL OR check_out > check_in);

-- Salary range sanity
ALTER TABLE designations
    ADD CONSTRAINT chk_salary_range CHECK (max_salary >= min_salary);

-- Leave end >= start
ALTER TABLE leave_requests
    ADD CONSTRAINT chk_leave_dates CHECK (end_date >= start_date);

-- Project end >= start
ALTER TABLE projects
    ADD CONSTRAINT chk_proj_dates CHECK (end_date IS NULL OR end_date >= start_date);

-- Allocation percentage 1–100
ALTER TABLE project_assignments
    ADD CONSTRAINT chk_allocation CHECK (allocation_pct BETWEEN 1 AND 100);

-- Performance scores 1–10
ALTER TABLE performance_evaluations
    ADD CONSTRAINT chk_scores CHECK (
        quality_score BETWEEN 1 AND 10 AND
        productivity  BETWEEN 1 AND 10 AND
        teamwork      BETWEEN 1 AND 10 AND
        communication BETWEEN 1 AND 10 AND
        leadership    BETWEEN 1 AND 10
    );

-- =============================================================================
-- 4. SAMPLE DATA
-- =============================================================================

-- 4.01  user_roles
INSERT INTO user_roles (role_name, description) VALUES
('Super Admin', 'Full system access including user management'),
('HR Admin',    'Manages employee records, payroll, leave'),
('Manager',     'Approves leave, reviews performance of team'),
('Employee',    'Standard employee — self-service access only');

-- 4.02  departments
INSERT INTO departments (dept_name, dept_code, location, budget) VALUES
('Human Resources',        'HR',   'Floor 1, Block A', 2500000.00),
('Information Technology', 'IT',   'Floor 2, Block B', 8000000.00),
('Finance & Accounts',     'FIN',  'Floor 1, Block C', 3500000.00),
('Marketing & Sales',      'MKT',  'Floor 3, Block A', 4000000.00),
('Operations',             'OPS',  'Ground Floor',     5000000.00),
('Research & Development', 'R&D',  'Floor 4, Block B', 6500000.00),
('Customer Support',       'CS',   'Floor 2, Block A', 2000000.00),
('Administration',         'ADM',  'Floor 1, Block D', 1500000.00);

-- 4.03  designations
INSERT INTO designations (title, grade, min_salary, max_salary, dept_id) VALUES
-- HR
('HR Director',          'L7', 180000, 260000, 1),
('HR Manager',           'L5', 100000, 160000, 1),
('HR Executive',         'L3',  45000,  80000, 1),
-- IT
('Chief Technology Officer','L8', 250000, 400000, 2),
('Engineering Manager',  'L6', 150000, 230000, 2),
('Senior Software Engineer','L5',100000, 160000, 2),
('Software Engineer',    'L4',  65000, 110000, 2),
('Junior Developer',     'L2',  35000,  65000, 2),
('QA Engineer',          'L4',  60000, 100000, 2),
('DevOps Engineer',      'L5',  90000, 140000, 2),
-- Finance
('CFO',                  'L8', 240000, 380000, 3),
('Finance Manager',      'L6', 130000, 200000, 3),
('Accountant',           'L4',  55000,  90000, 3),
('Financial Analyst',    'L5',  80000, 130000, 3),
-- Marketing
('Marketing Director',   'L7', 170000, 250000, 4),
('Marketing Manager',    'L5',  95000, 150000, 4),
('Content Strategist',   'L4',  55000,  90000, 4),
('SEO Specialist',       'L3',  40000,  70000, 4),
-- Operations
('Operations Head',      'L7', 180000, 260000, 5),
('Operations Manager',   'L5', 100000, 155000, 5),
('Logistics Coordinator','L3',  40000,  65000, 5),
-- R&D
('R&D Director',         'L7', 200000, 300000, 6),
('Research Scientist',   'L6', 130000, 200000, 6),
('Data Scientist',       'L5',  95000, 155000, 6),
-- Customer Support
('CS Manager',           'L5',  90000, 140000, 7),
('Support Lead',         'L4',  60000,  95000, 7),
('Support Agent',        'L2',  30000,  55000, 7),
-- Admin
('Admin Manager',        'L5',  85000, 130000, 8),
('Office Coordinator',   'L3',  38000,  60000, 8);

-- 4.04  leave_types
INSERT INTO leave_types (type_name, annual_quota, is_paid, carry_forward) VALUES
('Casual Leave',        12, 1, 0),
('Sick Leave',          12, 1, 0),
('Earned Leave',        15, 1, 1),
('Maternity Leave',    180, 1, 0),
('Paternity Leave',      5, 1, 0),
('Compensatory Leave',   5, 1, 0),
('Unpaid Leave',         0, 0, 0);

-- 4.05  employees  (25 records)
-- NOTE: password_hash values below are bcrypt hashes of 'Password@123'
--       In production, ALWAYS hash server-side before storing.
INSERT INTO employees
  (emp_code, first_name, last_name, gender, date_of_birth, national_id,
   email, phone, alt_phone,
   address_line1, city, state, postal_code, country,
   joining_date, employment_type, employment_status,
   dept_id, desig_id, manager_id, base_salary,
   emergency_name, emergency_phone, emergency_rel,
   username, password_hash, role_id)
VALUES
-- HR Department
('EMP001','Priya',       'Sharma',      'Female','1985-03-12','UID100001',
 'priya.sharma@acmecorp.in',    '9876543210',NULL,
 '12 MG Road','Bengaluru','Karnataka','560001','India',
 '2018-01-15','Full-Time','Active', 1,2,NULL, 130000,
 'Raj Sharma','9876500001','Spouse',
 'priya.sharma','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000001',2),

('EMP002','Anika',       'Verma',       'Female','1992-07-22','UID100002',
 'anika.verma@acmecorp.in',     '9876543211',NULL,
 '5 Park Lane','Mumbai','Maharashtra','400001','India',
 '2020-03-01','Full-Time','Active', 1,3,1, 65000,
 'Sunil Verma','9876500002','Father',
 'anika.verma','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000002',4),

('EMP003','Kiran',       'Nair',        'Male',  '1990-11-05','UID100003',
 'kiran.nair@acmecorp.in',      '9876543212',NULL,
 '8 Brigade Road','Bengaluru','Karnataka','560025','India',
 '2019-06-10','Full-Time','Active', 1,3,1, 70000,
 'Meena Nair','9876500003','Mother',
 'kiran.nair','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000003',4),

-- IT Department
('EMP004','Arjun',       'Mehta',       'Male',  '1982-05-18','UID100004',
 'arjun.mehta@acmecorp.in',     '9876543213',NULL,
 '22 Tech Park','Hyderabad','Telangana','500081','India',
 '2016-07-01','Full-Time','Active', 2,5,NULL, 195000,
 'Neha Mehta','9876500004','Spouse',
 'arjun.mehta','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000004',3),

('EMP005','Sneha',       'Kulkarni',    'Female','1994-02-28','UID100005',
 'sneha.kulkarni@acmecorp.in',  '9876543214',NULL,
 '34 Indiranagar','Bengaluru','Karnataka','560038','India',
 '2021-01-10','Full-Time','Active', 2,6,4, 125000,
 'Anand Kulkarni','9876500005','Father',
 'sneha.kulkarni','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000005',4),

('EMP006','Rahul',       'Gupta',       'Male',  '1996-09-14','UID100006',
 'rahul.gupta@acmecorp.in',     '9876543215',NULL,
 '9 Whitefield','Bengaluru','Karnataka','560066','India',
 '2022-04-01','Full-Time','Active', 2,7,4, 85000,
 'Sunita Gupta','9876500006','Mother',
 'rahul.gupta','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000006',4),

('EMP007','Divya',       'Iyer',        'Female','1998-12-03','UID100007',
 'divya.iyer@acmecorp.in',      '9876543216',NULL,
 '17 Anna Nagar','Chennai','Tamil Nadu','600040','India',
 '2023-06-15','Full-Time','Active', 2,8,4, 50000,
 'Ravi Iyer','9876500007','Father',
 'divya.iyer','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000007',4),

('EMP008','Vikram',      'Bose',        'Male',  '1993-04-20','UID100008',
 'vikram.bose@acmecorp.in',     '9876543217',NULL,
 '44 Salt Lake','Kolkata','West Bengal','700064','India',
 '2020-08-01','Full-Time','Active', 2,9,4, 92000,
 'Mita Bose','9876500008','Spouse',
 'vikram.bose','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000008',4),

('EMP009','Rohan',       'Joshi',       'Male',  '1991-06-30','UID100009',
 'rohan.joshi@acmecorp.in',     '9876543218',NULL,
 '3 Koregaon Park','Pune','Maharashtra','411001','India',
 '2019-03-15','Full-Time','Active', 2,10,4, 115000,
 'Kavita Joshi','9876500009','Spouse',
 'rohan.joshi','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000009',4),

-- Finance Department
('EMP010','Meera',       'Patel',       'Female','1984-08-25','UID100010',
 'meera.patel@acmecorp.in',     '9876543219',NULL,
 '67 CG Road','Ahmedabad','Gujarat','380006','India',
 '2017-11-01','Full-Time','Active', 3,12,NULL, 165000,
 'Dinesh Patel','9876500010','Spouse',
 'meera.patel','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000010',3),

('EMP011','Suresh',      'Rao',         'Male',  '1989-01-17','UID100011',
 'suresh.rao@acmecorp.in',      '9876543220',NULL,
 '12 Jubilee Hills','Hyderabad','Telangana','500033','India',
 '2018-05-01','Full-Time','Active', 3,13,10, 75000,
 'Lakshmi Rao','9876500011','Spouse',
 'suresh.rao','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000011',4),

('EMP012','Ananya',      'Singh',       'Female','1995-10-08','UID100012',
 'ananya.singh@acmecorp.in',    '9876543221',NULL,
 '29 Lajpat Nagar','New Delhi','Delhi','110024','India',
 '2021-09-01','Full-Time','Active', 3,14,10, 100000,
 'Amit Singh','9876500012','Father',
 'ananya.singh','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000012',4),

-- Marketing Department
('EMP013','Kavya',       'Reddy',       'Female','1987-03-30','UID100013',
 'kavya.reddy@acmecorp.in',     '9876543222',NULL,
 '55 Jubilee Hills','Hyderabad','Telangana','500096','India',
 '2017-04-01','Full-Time','Active', 4,16,NULL, 145000,
 'Ramesh Reddy','9876500013','Spouse',
 'kavya.reddy','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000013',3),

('EMP014','Aditya',      'Khanna',      'Male',  '1993-07-15','UID100014',
 'aditya.khanna@acmecorp.in',   '9876543223',NULL,
 '7 GK-II','New Delhi','Delhi','110048','India',
 '2020-02-01','Full-Time','Active', 4,17,13, 72000,
 'Sonia Khanna','9876500014','Mother',
 'aditya.khanna','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000014',4),

('EMP015','Ishaan',      'Malhotra',    'Male',  '1997-05-22','UID100015',
 'ishaan.malhotra@acmecorp.in', '9876543224',NULL,
 '15 Model Town','Ludhiana','Punjab','141001','India',
 '2022-07-01','Full-Time','Active', 4,18,13, 55000,
 'Pooja Malhotra','9876500015','Spouse',
 'ishaan.malhotra','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000015',4),

-- Operations Department
('EMP016','Sanjay',      'Desai',       'Male',  '1983-12-10','UID100016',
 'sanjay.desai@acmecorp.in',    '9876543225',NULL,
 '88 FC Road','Pune','Maharashtra','411004','India',
 '2016-01-01','Full-Time','Active', 5,20,NULL, 135000,
 'Rekha Desai','9876500016','Spouse',
 'sanjay.desai','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000016',3),

('EMP017','Pooja',       'Mishra',      'Female','1995-04-18','UID100017',
 'pooja.mishra@acmecorp.in',    '9876543226',NULL,
 '23 Hazratganj','Lucknow','Uttar Pradesh','226001','India',
 '2021-11-01','Full-Time','Active', 5,21,16, 48000,
 'Ajay Mishra','9876500017','Father',
 'pooja.mishra','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000017',4),

-- R&D Department
('EMP018','Dr. Aman',    'Tiwari',      'Male',  '1980-09-04','UID100018',
 'aman.tiwari@acmecorp.in',     '9876543227',NULL,
 '6 IIT Campus','Chennai','Tamil Nadu','600036','India',
 '2015-06-01','Full-Time','Active', 6,23,NULL, 190000,
 'Priti Tiwari','9876500018','Spouse',
 'aman.tiwari','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000018',3),

('EMP019','Nisha',       'Agarwal',     'Female','1991-02-14','UID100019',
 'nisha.agarwal@acmecorp.in',   '9876543228',NULL,
 '14 Sector 62','Noida','Uttar Pradesh','201301','India',
 '2019-08-01','Full-Time','Active', 6,24,18, 120000,
 'Vikas Agarwal','9876500019','Spouse',
 'nisha.agarwal','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000019',4),

-- Customer Support
('EMP020','Ravi',        'Kumar',       'Male',  '1988-06-25','UID100020',
 'ravi.kumar@acmecorp.in',      '9876543229',NULL,
 '2 Himayat Nagar','Hyderabad','Telangana','500029','India',
 '2018-09-01','Full-Time','Active', 7,25,NULL, 110000,
 'Sunita Kumar','9876500020','Spouse',
 'ravi.kumar','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000020',3),

('EMP021','Tanya',       'Shetty',      'Female','1996-11-30','UID100021',
 'tanya.shetty@acmecorp.in',    '9876543230',NULL,
 '9 Bandra West','Mumbai','Maharashtra','400050','India',
 '2022-01-03','Full-Time','Active', 7,26,20, 62000,
 'Mohan Shetty','9876500021','Father',
 'tanya.shetty','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000021',4),

('EMP022','Rohit',       'Chandra',     'Male',  '1999-03-07','UID100022',
 'rohit.chandra@acmecorp.in',   '9876543231',NULL,
 '31 Indira Nagar','Bengaluru','Karnataka','560038','India',
 '2023-01-16','Full-Time','Active', 7,27,20, 38000,
 'Anita Chandra','9876500022','Mother',
 'rohit.chandra','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000022',4),

-- Administration
('EMP023','Geeta',       'Pillai',      'Female','1986-08-19','UID100023',
 'geeta.pillai@acmecorp.in',    '9876543232',NULL,
 '19 Trivandrum Road','Thrissur','Kerala','680001','India',
 '2017-03-01','Full-Time','Active', 8,28,NULL, 105000,
 'Sunil Pillai','9876500023','Spouse',
 'geeta.pillai','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000023',3),

('EMP024','Manoj',       'Chauhan',     'Male',  '1994-09-25','UID100024',
 'manoj.chauhan@acmecorp.in',   '9876543233',NULL,
 '44 Rajpur Road','Dehradun','Uttarakhand','248001','India',
 '2021-05-17','Full-Time','Active', 8,29,23, 45000,
 'Asha Chauhan','9876500024','Spouse',
 'manoj.chauhan','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000024',4),

-- Super Admin (CEO / Founder acting as super admin)
('EMP025','Vikrant',     'Sharma',      'Male',  '1978-01-01','UID100000',
 'vikrant.sharma@acmecorp.in',  '9876543200','9876543201',
 '1 Corporate Tower','Bengaluru','Karnataka','560001','India',
 '2010-01-01','Full-Time','Active', 8,28,NULL, 400000,
 'Priya Sharma','9876500000','Spouse',
 'admin','$2b$12$abcdefghijklmnopqrstuuSampleHashForDemoOnly000025',1);

-- 4.06  administrators
INSERT INTO administrators (emp_id, access_level, can_manage_payroll, can_manage_leaves, can_view_reports) VALUES
(25, 1, 1, 1, 1),  -- Super admin
(1,  2, 1, 1, 1);  -- HR Director

-- 4.07  leave_balances (year 2025, 2026 for all employees)
INSERT INTO leave_balances (emp_id, leave_type_id, year, total_days, used_days, pending_days)
SELECT e.emp_id, lt.leave_type_id, 2025,
       lt.annual_quota,
       FLOOR(RAND() * (lt.annual_quota / 2)),
       0
FROM employees e
CROSS JOIN leave_types lt
WHERE e.employment_status = 'Active';

-- 4.08  leave_requests (20 realistic requests)
INSERT INTO leave_requests (emp_id, leave_type_id, start_date, end_date, total_days, reason, status, approved_by, approved_at) VALUES
(2,  1, '2025-01-13', '2025-01-15', 3,  'Personal work at hometown',        'Approved', 1, '2025-01-10 09:30:00'),
(6,  2, '2025-02-05', '2025-02-07', 3,  'Fever and flu',                    'Approved', 4, '2025-02-04 11:00:00'),
(7,  1, '2025-02-20', '2025-02-21', 2,  'Family function',                  'Approved', 4, '2025-02-18 10:00:00'),
(11, 3, '2025-03-10', '2025-03-14', 5,  'Planned vacation',                 'Approved',10, '2025-03-07 14:00:00'),
(14, 2, '2025-03-20', '2025-03-21', 2,  'Medical checkup',                  'Approved',13, '2025-03-19 09:00:00'),
(17, 1, '2025-04-01', '2025-04-02', 2,  'Personal errands',                 'Approved',16, '2025-03-28 10:00:00'),
(19, 3, '2025-04-14', '2025-04-18', 5,  'Annual family trip',               'Approved',18, '2025-04-10 09:30:00'),
(22, 2, '2025-04-25', '2025-04-26', 2,  'Cold and headache',                'Approved',20, '2025-04-24 08:00:00'),
(5,  1, '2025-05-05', '2025-05-07', 3,  'Wedding anniversary travel',       'Approved', 4, '2025-05-02 15:00:00'),
(8,  6, '2025-05-15', '2025-05-16', 2,  'Comp off for weekend work',        'Approved', 4, '2025-05-14 11:00:00'),
(12, 1, '2025-06-09', '2025-06-10', 2,  'Sibling graduation ceremony',      'Approved',10, '2025-06-06 10:00:00'),
(15, 2, '2025-06-18', '2025-06-19', 2,  'Back pain treatment',              'Approved',13, '2025-06-17 09:00:00'),
(3,  3, '2025-07-07', '2025-07-11', 5,  'Yearly vacation',                  'Approved', 1, '2025-07-04 09:00:00'),
(21, 1, '2025-07-21', '2025-07-22', 2,  'Home relocation assistance',       'Approved',20, '2025-07-18 10:00:00'),
(24, 2, '2025-08-04', '2025-08-05', 2,  'Dental procedure recovery',        'Approved',23, '2025-08-01 09:30:00'),
(6,  3, '2025-08-18', '2025-08-22', 5,  'International trip',               'Approved', 4, '2025-08-13 14:00:00'),
(9,  1, '2025-09-01', '2025-09-03', 3,  'Family emergency',                 'Approved', 4, '2025-08-30 16:00:00'),
(2,  2, '2025-10-06', '2025-10-08', 3,  'Viral fever',                      'Approved', 1, '2025-10-05 09:00:00'),
(16, 3, '2025-11-03', '2025-11-07', 5,  'Planned leave',                    'Pending', NULL, NULL),
(19, 1, '2025-12-22', '2025-12-26', 5,  'Christmas holidays with family',   'Pending', NULL, NULL);

-- 4.09  holidays
INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_paid) VALUES
('New Year Day',        '2025-01-01', 'National',  1),
('Republic Day',        '2025-01-26', 'National',  1),
('Holi',                '2025-03-14', 'National',  1),
('Good Friday',         '2025-04-18', 'National',  1),
('Eid ul-Fitr',         '2025-03-31', 'National',  1),
('Ambedkar Jayanti',    '2025-04-14', 'National',  1),
('Labour Day',          '2025-05-01', 'National',  1),
('Independence Day',    '2025-08-15', 'National',  1),
('Gandhi Jayanti',      '2025-10-02', 'National',  1),
('Dussehra',            '2025-10-02', 'National',  1),
('Diwali',              '2025-10-20', 'National',  1),
('Diwali Holiday',      '2025-10-21', 'Company',   1),
('Christmas',           '2025-12-25', 'National',  1),
('Company Foundation',  '2025-02-14', 'Company',   1),
('New Year Day',        '2026-01-01', 'National',  1),
('Republic Day',        '2026-01-26', 'National',  1);

-- 4.10  attendance (last 30 days sample — June 2025)
INSERT INTO attendance (emp_id, attendance_date, check_in, check_out, status, overtime_hours) VALUES
-- EMP001
(1,'2025-06-02','09:05:00','18:10:00','Present',0),(1,'2025-06-03','09:00:00','18:00:00','Present',0),
(1,'2025-06-04','09:15:00','18:05:00','Present',0),(1,'2025-06-05','08:58:00','18:30:00','Present',0.5),
(1,'2025-06-06','09:00:00','18:00:00','Present',0),
-- EMP004
(4,'2025-06-02','08:45:00','20:00:00','Present',2),(4,'2025-06-03','09:00:00','19:30:00','Present',1.5),
(4,'2025-06-04','09:00:00','18:00:00','Present',0),(4,'2025-06-05','09:00:00','20:30:00','Present',2.5),
(4,'2025-06-06','09:00:00','18:00:00','Present',0),
-- EMP005
(5,'2025-06-02','09:30:00','18:00:00','Late',0),(5,'2025-06-03','09:00:00','18:00:00','Present',0),
(5,'2025-06-04','09:00:00','18:00:00','Present',0),(5,'2025-06-05','09:00:00','18:30:00','Present',0.5),
(5,'2025-06-06','09:00:00','18:00:00','Present',0),
-- EMP006
(6,'2025-06-02','09:00:00','18:00:00','Present',0),(6,'2025-06-03',NULL,NULL,'Absent',0),
(6,'2025-06-04','09:00:00','18:00:00','Present',0),(6,'2025-06-05','09:00:00','18:00:00','WFH',0),
(6,'2025-06-06','09:00:00','18:00:00','Present',0),
-- EMP010
(10,'2025-06-02','09:00:00','18:00:00','Present',0),(10,'2025-06-03','09:00:00','18:30:00','Present',0.5),
(10,'2025-06-04','09:00:00','18:00:00','Present',0),(10,'2025-06-05','08:45:00','18:00:00','Present',0),
(10,'2025-06-06','09:00:00','18:00:00','Present',0),
-- EMP019
(19,'2025-06-02','09:00:00','18:00:00','Present',0),(19,'2025-06-03','09:00:00','18:00:00','WFH',0),
(19,'2025-06-04',NULL,NULL,'Leave',0),(19,'2025-06-05',NULL,NULL,'Leave',0),
(19,'2025-06-06','09:00:00','18:00:00','Present',0);

-- 4.11  payroll_periods
INSERT INTO payroll_periods (period_month, period_year, start_date, end_date, status, processed_by, processed_at) VALUES
(1,  2025, '2025-01-01','2025-01-31','Closed',25,'2025-02-01 10:00:00'),
(2,  2025, '2025-02-01','2025-02-28','Closed',25,'2025-03-01 10:00:00'),
(3,  2025, '2025-03-01','2025-03-31','Closed',25,'2025-04-01 10:00:00'),
(4,  2025, '2025-04-01','2025-04-30','Closed',25,'2025-05-01 10:00:00'),
(5,  2025, '2025-05-01','2025-05-31','Closed',25,'2025-06-01 10:00:00'),
(6,  2025, '2025-06-01','2025-06-30','Processed',25,'2025-07-01 10:00:00'),
(7,  2025, '2025-07-01','2025-07-31','Open',NULL,NULL);

-- 4.12  payroll  (June 2025 for 10 employees)
INSERT INTO payroll
  (emp_id, period_id, basic_salary, hra, conveyance, medical, other_allowance,
   gross_salary, pf_deduction, tax_deduction, loan_deduction, other_deduction,
   total_deduction, net_salary, overtime_pay, bonus, working_days, present_days,
   absent_days, leave_days, payment_status, payment_date, payment_mode, bank_ref)
VALUES
(1,  6, 130000,52000,3000,2000,5000,192000,15600,18200,0,0,33800,158200,0,0,      26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100001'),
(4,  6, 195000,78000,3000,2000,8000,286000,23400,35000,0,0,58400,227600,12000,0,  26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100002'),
(5,  6, 125000,50000,3000,2000,5000,185000,15000,17500,0,0,32500,152500,3000,0,   26,25,0,1,'Paid','2025-07-01','Bank Transfer','TXN00100003'),
(6,  6,  85000,34000,2000,1500,3000,125500,10200, 8500,0,0,18700,106800,0,0,      26,24,1,1,'Paid','2025-07-01','Bank Transfer','TXN00100004'),
(8,  6,  92000,36800,2000,1500,3500,135800,11040, 9800,0,0,20840,114960,0,0,      26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100005'),
(9,  6, 115000,46000,2000,2000,4000,169000,13800,13500,0,0,27300,141700,0,0,      26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100006'),
(10, 6, 165000,66000,3000,2000,6000,242000,19800,28500,0,0,48300,193700,3000,0,   26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100007'),
(13, 6, 145000,58000,3000,2000,5500,213500,17400,21000,0,0,38400,175100,0,0,      26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100008'),
(18, 6, 190000,76000,3000,2000,8000,279000,22800,34000,0,0,56800,222200,0,5000,   26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100009'),
(25, 6, 400000,160000,5000,5000,20000,590000,48000,120000,0,0,168000,422000,0,50000,26,26,0,0,'Paid','2025-07-01','Bank Transfer','TXN00100010');

-- 4.13  salary_slips
INSERT INTO salary_slips (payroll_id, emp_id, slip_number, file_path, is_sent, sent_at) VALUES
(1,  1,  'SLIP-2025-06-001','slips/2025/06/EMP001_Jun25.pdf',1,'2025-07-02 08:30:00'),
(2,  4,  'SLIP-2025-06-002','slips/2025/06/EMP004_Jun25.pdf',1,'2025-07-02 08:30:00'),
(3,  5,  'SLIP-2025-06-003','slips/2025/06/EMP005_Jun25.pdf',1,'2025-07-02 08:30:00'),
(4,  6,  'SLIP-2025-06-004','slips/2025/06/EMP006_Jun25.pdf',1,'2025-07-02 08:30:00'),
(5,  8,  'SLIP-2025-06-005','slips/2025/06/EMP008_Jun25.pdf',1,'2025-07-02 08:30:00'),
(6,  9,  'SLIP-2025-06-006','slips/2025/06/EMP009_Jun25.pdf',1,'2025-07-02 08:30:00'),
(7,  10, 'SLIP-2025-06-007','slips/2025/06/EMP010_Jun25.pdf',1,'2025-07-02 08:30:00'),
(8,  13, 'SLIP-2025-06-008','slips/2025/06/EMP013_Jun25.pdf',1,'2025-07-02 08:30:00'),
(9,  18, 'SLIP-2025-06-009','slips/2025/06/EMP018_Jun25.pdf',1,'2025-07-02 08:30:00'),
(10, 25, 'SLIP-2025-06-010','slips/2025/06/EMP025_Jun25.pdf',1,'2025-07-02 08:30:00');

-- 4.14  projects
INSERT INTO projects (project_code, project_name, description, dept_id, client_name, start_date, end_date, budget, status, priority, manager_id) VALUES
('PRJ001','ERP Integration','Integrate legacy ERP with new cloud platform',              2,'InternalIT', '2025-01-01','2025-09-30', 5000000,'Active',   'High',    4),
('PRJ002','Mobile App v2',  'Rebuild customer-facing mobile app in Flutter',              2,'RetailCo',   '2025-02-01','2025-12-31', 3500000,'Active',   'High',    4),
('PRJ003','AI Chatbot',     'Customer support AI assistant using LLM',                   6,'AcmeCorp',   '2025-03-01','2025-11-30', 2800000,'Active',   'Critical', 18),
('PRJ004','Brand Refresh',  'Redesign corporate branding and marketing collateral',       4,'InternalMKT','2025-01-15','2025-06-30', 1200000,'Completed','Medium',  13),
('PRJ005','Data Warehouse', 'Build enterprise data warehouse on Snowflake',              2,'InternalFIN','2025-04-01','2026-03-31', 6000000,'Active',   'High',    4),
('PRJ006','Compliance Audit','Annual security and compliance review',                    3,'Regulatory', '2025-05-01','2025-07-31', 800000, 'Completed','Medium',  10),
('PRJ007','HR Portal',      'Self-service HR portal for employee management',             1,'InternalHR', '2025-06-01','2025-12-31', 1500000,'Active',   'High',    1),
('PRJ008','Supply Chain',   'Optimise supply chain logistics using IoT sensors',          5,'ManufactCo', '2025-03-15','2026-06-30', 9000000,'Active',   'Critical', 16);

-- 4.15  project_assignments
INSERT INTO project_assignments (project_id, emp_id, role_in_project, assigned_date, allocation_pct) VALUES
(1,4,'Project Manager',  '2025-01-01',30),(1,5,'Tech Lead',       '2025-01-01',100),
(1,6,'Backend Dev',      '2025-01-01',80),(1,9,'DevOps',          '2025-01-01',60),
(2,4,'Sponsor',          '2025-02-01',10),(2,6,'Full Stack Dev',  '2025-02-01',80),
(2,7,'Junior Dev',       '2025-02-01',100),(2,8,'QA Lead',        '2025-02-01',100),
(3,18,'Project Lead',    '2025-03-01',50),(3,19,'Data Scientist', '2025-03-01',100),
(3,5,'ML Engineer',      '2025-03-01',40),
(4,13,'Sponsor',         '2025-01-15',10),(4,14,'Content Lead',   '2025-01-15',100),
(4,15,'SEO',             '2025-01-15',100),
(5,4,'Architect',        '2025-04-01',20),(5,9,'DevOps',         '2025-04-01',40),
(5,19,'Data Engineer',   '2025-04-01',60),
(6,10,'Finance Lead',    '2025-05-01',30),(6,11,'Accountant',     '2025-05-01',50),
(7,1,'PM',               '2025-06-01',50),(7,2,'HR Analyst',     '2025-06-01',100),
(7,6,'Dev',              '2025-06-01',20),
(8,16,'Project Head',    '2025-03-15',40),(8,17,'Coordinator',   '2025-03-15',100);

-- 4.16  performance_evaluations
INSERT INTO performance_evaluations
  (emp_id, evaluator_id, eval_period, eval_date, quality_score, productivity, teamwork, communication, leadership, overall_score, rating, strengths, improvements, status)
VALUES
(2,  1, 'Q1-2025','2025-04-05',8,7,9,8,5,7.40,'Meets Expectations',    'Strong team player',        'Public speaking',       'Submitted'),
(6,  4, 'Q1-2025','2025-04-06',7,8,7,7,5,6.80,'Meets Expectations',    'Quick learner',             'Documentation habits',  'Submitted'),
(5,  4, 'Q1-2025','2025-04-07',9,9,8,8,7,8.20,'Exceeds Expectations',  'Excellent technical skills','Leadership development', 'Submitted'),
(11,10, 'Q1-2025','2025-04-08',8,7,8,7,5,7.00,'Meets Expectations',    'Detail-oriented',           'Speed of delivery',     'Submitted'),
(14,13, 'Q1-2025','2025-04-09',7,8,8,8,6,7.40,'Meets Expectations',    'Creative campaigns',        'Data-driven decisions', 'Submitted'),
(19,18, 'Q1-2025','2025-04-10',9,9,8,9,7,8.40,'Exceeds Expectations',  'Strong ML skills',          'Stakeholder updates',   'Submitted'),
(7,  4, 'Q1-2025','2025-04-11',6,7,8,7,4,6.40,'Meets Expectations',    'Eager to learn',            'Code review practices', 'Submitted'),
(17,16, 'Q1-2025','2025-04-12',8,7,9,8,5,7.40,'Meets Expectations',    'Reliable',                  'Initiative taking',     'Submitted');

-- 4.17  announcements
INSERT INTO announcements (title, body, published_by, target_dept_id, priority, publish_date, expiry_date) VALUES
('Annual Performance Review – FY 2025',     'All managers must submit performance reviews by April 30.',                          1, NULL, 'Important','2025-04-01','2025-04-30'),
('New Work-From-Home Policy',               'Effective May 1, employees may WFH up to 2 days per week with manager approval.',   25, NULL, 'Normal',   '2025-04-20','2025-12-31'),
('IT Security Awareness Training',          'Mandatory cybersecurity training scheduled for all IT staff on April 15.',          25, 2,   'Urgent',   '2025-04-08','2025-04-15'),
('Office Renovation – Ground Floor',        'The Ground Floor will be under renovation from May 5–10. Use alternate entrance.',  23, NULL, 'Important','2025-04-30','2025-05-10'),
('Q2 Town Hall Meeting',                    'Join us on July 1 at 11 AM for the quarterly all-hands meeting.',                   25, NULL, 'Important','2025-06-15','2025-07-01'),
('Diwali Celebration Party',               'Company Diwali party on October 22 at 4 PM in the cafeteria.',                      23, NULL, 'Normal',   '2025-10-10','2025-10-22'),
('New Finance System Go-Live',              'SAP upgrade goes live on August 1. Finance team mandatory training on July 25.',    10, 3,   'Urgent',   '2025-07-10','2025-08-01'),
('Employee Referral Programme – Expanded', 'Earn ₹25,000 per successful referral. See HR for details.',                         1,  NULL, 'Normal',   '2025-05-01','2025-12-31');

-- 4.18  notifications
INSERT INTO notifications (emp_id, title, message, type, is_read) VALUES
(2, 'Leave Approved',       'Your Casual Leave from Jan 13–15 has been approved.',          'Leave',     1),
(6, 'Leave Approved',       'Your Sick Leave from Feb 5–7 has been approved.',              'Leave',     1),
(1, 'Payroll Processed',    'June 2025 payroll has been processed. Salary will be credited.','Payroll',  0),
(4, 'Payroll Processed',    'June 2025 payroll has been processed. Salary will be credited.','Payroll',  0),
(5, 'Salary Slip Ready',    'Your salary slip for June 2025 is available for download.',    'Payroll',   0),
(6, 'Attendance Alert',     'You were marked Absent on June 3. Please regularise.',         'Attendance',0),
(16,'Leave Pending',        'Your Earned Leave request is pending approval.',                'Leave',     0),
(19,'Leave Pending',        'Your Casual Leave request is pending approval.',                'Leave',     0),
(25,'New Announcement',     'Annual Performance Review announcement has been published.',    'Info',      1),
(18,'Performance Review',   'Your Q1-2025 performance evaluation has been submitted.',      'Info',      0);

-- 4.19  login_history
INSERT INTO login_history (emp_id, login_time, logout_time, ip_address, status) VALUES
(25,'2025-06-29 09:00:00','2025-06-29 18:30:00','192.168.1.1',  'Success'),
(1, '2025-06-29 09:05:00','2025-06-29 18:00:00','192.168.1.10', 'Success'),
(4, '2025-06-29 08:45:00','2025-06-29 20:00:00','192.168.1.20', 'Success'),
(5, '2025-06-29 09:30:00','2025-06-29 18:00:00','192.168.1.21', 'Success'),
(6, '2025-06-29 09:00:00','2025-06-29 18:00:00','192.168.1.22', 'Success'),
(10,'2025-06-28 09:00:00','2025-06-28 18:30:00','192.168.1.30', 'Success'),
(13,'2025-06-28 09:00:00','2025-06-28 18:00:00','192.168.1.40', 'Success'),
(18,'2025-06-27 09:00:00','2025-06-27 18:30:00','192.168.1.50', 'Success'),
(6, '2025-06-26 09:00:00',NULL,                 '10.0.0.5',     'Failed'),
(2, '2025-06-29 09:10:00','2025-06-29 17:45:00','192.168.1.11', 'Success');

-- =============================================================================
-- 5. VIEWS
-- =============================================================================

-- 5.01  View: Active employee profiles with department and designation
CREATE OR REPLACE VIEW vw_active_employees AS
SELECT
    e.emp_id,
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS full_name,
    e.gender,
    e.date_of_birth,
    e.email,
    e.phone,
    d.dept_name,
    des.title       AS designation,
    des.grade,
    e.employment_type,
    e.employment_status,
    e.joining_date,
    TIMESTAMPDIFF(YEAR, e.joining_date, CURDATE()) AS years_of_service,
    e.base_salary,
    r.role_name,
    CONCAT(m.first_name,' ',m.last_name) AS manager_name
FROM employees e
INNER JOIN departments  d   ON e.dept_id  = d.dept_id
INNER JOIN designations des ON e.desig_id = des.desig_id
INNER JOIN user_roles   r   ON e.role_id  = r.role_id
LEFT  JOIN employees    m   ON e.manager_id = m.emp_id
WHERE e.employment_status = 'Active';

-- 5.02  View: Payroll summary
CREATE OR REPLACE VIEW vw_payroll_summary AS
SELECT
    p.payroll_id,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    e.emp_code,
    d.dept_name,
    pp.period_month,
    pp.period_year,
    p.gross_salary,
    p.total_deduction,
    p.net_salary,
    p.bonus,
    p.overtime_pay,
    p.payment_status,
    p.payment_date
FROM payroll p
INNER JOIN employees       e  ON p.emp_id    = e.emp_id
INNER JOIN departments     d  ON e.dept_id   = d.dept_id
INNER JOIN payroll_periods pp ON p.period_id = pp.period_id;

-- 5.03  View: Attendance report
CREATE OR REPLACE VIEW vw_attendance_report AS
SELECT
    a.attendance_date,
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    d.dept_name,
    a.check_in,
    a.check_out,
    a.work_hours,
    a.status,
    a.overtime_hours
FROM attendance a
INNER JOIN employees   e ON a.emp_id  = e.emp_id
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 5.04  View: Leave status report
CREATE OR REPLACE VIEW vw_leave_status AS
SELECT
    lr.request_id,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    e.emp_code,
    d.dept_name,
    lt.type_name        AS leave_type,
    lr.start_date,
    lr.end_date,
    lr.total_days,
    lr.reason,
    lr.status,
    CONCAT(m.first_name,' ',m.last_name) AS approved_by_name,
    lr.applied_at
FROM leave_requests lr
INNER JOIN employees   e  ON lr.emp_id        = e.emp_id
INNER JOIN departments d  ON e.dept_id        = d.dept_id
INNER JOIN leave_types lt ON lr.leave_type_id = lt.leave_type_id
LEFT  JOIN employees   m  ON lr.approved_by   = m.emp_id;

-- 5.05  View: Department statistics
CREATE OR REPLACE VIEW vw_department_stats AS
SELECT
    d.dept_id,
    d.dept_name,
    d.dept_code,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END)      AS active_count,
    COUNT(CASE WHEN e.employment_status != 'Active' THEN 1 END)     AS inactive_count,
    COUNT(e.emp_id)                                                  AS total_count,
    AVG(CASE WHEN e.employment_status='Active' THEN e.base_salary END) AS avg_salary,
    MAX(e.base_salary)                                               AS max_salary,
    MIN(CASE WHEN e.employment_status='Active' THEN e.base_salary END) AS min_salary,
    SUM(CASE WHEN e.employment_status='Active' THEN e.base_salary END) AS total_salary_cost
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name, d.dept_code;

-- 5.06  View: Project allocation overview
CREATE OR REPLACE VIEW vw_project_allocation AS
SELECT
    p.project_code,
    p.project_name,
    p.status AS project_status,
    p.priority,
    d.dept_name,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    e.emp_code,
    des.title           AS designation,
    pa.role_in_project,
    pa.allocation_pct,
    pa.assigned_date,
    pa.released_date
FROM project_assignments pa
INNER JOIN projects     p   ON pa.project_id = p.project_id
INNER JOIN employees    e   ON pa.emp_id     = e.emp_id
INNER JOIN departments  d   ON p.dept_id     = d.dept_id
INNER JOIN designations des ON e.desig_id    = des.desig_id;

-- =============================================================================
-- 6. USER-DEFINED FUNCTIONS
-- =============================================================================

DELIMITER $$

-- 6.01  fn_employee_experience — years of service
CREATE FUNCTION fn_employee_experience(p_joining_date DATE)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(DATEDIFF(CURDATE(), p_joining_date) / 365.25, 2);
END$$

-- 6.02  fn_monthly_salary — prorated salary for partial month
CREATE FUNCTION fn_monthly_salary(p_base_salary DECIMAL(12,2), p_present_days INT, p_working_days INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    IF p_working_days = 0 THEN RETURN 0; END IF;
    RETURN ROUND((p_base_salary / p_working_days) * p_present_days, 2);
END$$

-- 6.03  fn_tax_deduction — simplified Indian income tax slab (annual → monthly)
CREATE FUNCTION fn_tax_deduction(p_annual_gross DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_annual_tax DECIMAL(12,2) DEFAULT 0;
    IF    p_annual_gross <= 250000  THEN SET v_annual_tax = 0;
    ELSEIF p_annual_gross <= 500000 THEN SET v_annual_tax = (p_annual_gross - 250000) * 0.05;
    ELSEIF p_annual_gross <= 1000000 THEN SET v_annual_tax = 12500 + (p_annual_gross - 500000) * 0.20;
    ELSE                                  SET v_annual_tax = 112500 + (p_annual_gross - 1000000) * 0.30;
    END IF;
    RETURN ROUND(v_annual_tax / 12, 2);
END$$

-- 6.04  fn_pf_deduction — Employee PF @ 12% of Basic (capped at ₹1800)
CREATE FUNCTION fn_pf_deduction(p_basic_salary DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    RETURN LEAST(ROUND(p_basic_salary * 0.12, 2), 1800.00);
END$$

-- 6.05  fn_net_salary
CREATE FUNCTION fn_net_salary(p_gross DECIMAL(12,2), p_pf DECIMAL(12,2), p_tax DECIMAL(12,2), p_other DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_gross - p_pf - p_tax - p_other, 2);
END$$

-- 6.06  fn_leave_balance
CREATE FUNCTION fn_leave_balance(p_emp_id INT, p_leave_type_id TINYINT, p_year YEAR)
RETURNS DECIMAL(5,1)
READS SQL DATA
BEGIN
    DECLARE v_bal DECIMAL(5,1) DEFAULT 0;
    SELECT COALESCE(remaining_days, 0) INTO v_bal
    FROM leave_balances
    WHERE emp_id = p_emp_id AND leave_type_id = p_leave_type_id AND year = p_year;
    RETURN v_bal;
END$$

-- 6.07  fn_attendance_percentage
CREATE FUNCTION fn_attendance_percentage(p_emp_id INT, p_year INT, p_month INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_present   INT DEFAULT 0;
    DECLARE v_working   INT DEFAULT 0;
    SELECT
        COUNT(CASE WHEN status IN ('Present','Late','WFH','Half-Day') THEN 1 END),
        COUNT(*)
    INTO v_present, v_working
    FROM attendance
    WHERE emp_id = p_emp_id
      AND YEAR(attendance_date)  = p_year
      AND MONTH(attendance_date) = p_month
      AND status NOT IN ('Holiday');
    IF v_working = 0 THEN RETURN 0; END IF;
    RETURN ROUND((v_present / v_working) * 100, 2);
END$$

DELIMITER ;

-- =============================================================================
-- 7. STORED PROCEDURES
-- =============================================================================

DELIMITER $$

-- 7.01  sp_add_employee — adds employee inside a transaction
CREATE PROCEDURE sp_add_employee(
    IN  p_emp_code        VARCHAR(20),
    IN  p_first_name      VARCHAR(50),
    IN  p_last_name       VARCHAR(50),
    IN  p_gender          ENUM('Male','Female','Other'),
    IN  p_dob             DATE,
    IN  p_email           VARCHAR(100),
    IN  p_phone           VARCHAR(20),
    IN  p_joining_date    DATE,
    IN  p_dept_id         SMALLINT,
    IN  p_desig_id        SMALLINT,
    IN  p_base_salary     DECIMAL(12,2),
    IN  p_username        VARCHAR(50),
    IN  p_password_hash   VARCHAR(255),
    OUT p_new_emp_id      INT,
    OUT p_status_msg      VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_msg = 'ERROR: Employee creation failed. Transaction rolled back.';
        SET p_new_emp_id = 0;
    END;

    START TRANSACTION;

    INSERT INTO employees
        (emp_code, first_name, last_name, gender, date_of_birth, email, phone,
         joining_date, dept_id, desig_id, base_salary, username, password_hash, role_id)
    VALUES
        (p_emp_code, p_first_name, p_last_name, p_gender, p_dob, p_email, p_phone,
         p_joining_date, p_dept_id, p_desig_id, p_base_salary, p_username, p_password_hash, 4);

    SET p_new_emp_id = LAST_INSERT_ID();

    -- Seed leave balances for current year
    INSERT INTO leave_balances (emp_id, leave_type_id, year, total_days, used_days, pending_days)
    SELECT p_new_emp_id, leave_type_id, YEAR(CURDATE()), annual_quota, 0, 0
    FROM leave_types;

    COMMIT;
    SET p_status_msg = CONCAT('SUCCESS: Employee created with ID ', p_new_emp_id);
END$$

-- 7.02  sp_update_employee — update basic employee fields
CREATE PROCEDURE sp_update_employee(
    IN p_emp_id        INT,
    IN p_phone         VARCHAR(20),
    IN p_address       VARCHAR(150),
    IN p_city          VARCHAR(60),
    IN p_dept_id       SMALLINT,
    IN p_desig_id      SMALLINT,
    IN p_base_salary   DECIMAL(12,2),
    IN p_status        ENUM('Active','Inactive','Resigned','Terminated','On-Leave'),
    OUT p_status_msg   VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_msg = 'ERROR: Update failed.';
    END;

    START TRANSACTION;

    UPDATE employees SET
        phone             = COALESCE(p_phone,       phone),
        address_line1     = COALESCE(p_address,     address_line1),
        city              = COALESCE(p_city,        city),
        dept_id           = COALESCE(p_dept_id,     dept_id),
        desig_id          = COALESCE(p_desig_id,    desig_id),
        base_salary       = COALESCE(p_base_salary, base_salary),
        employment_status = COALESCE(p_status,      employment_status)
    WHERE emp_id = p_emp_id;

    COMMIT;
    SET p_status_msg = 'SUCCESS: Employee updated.';
END$$

-- 7.03  sp_approve_leave — approve or reject a leave request
CREATE PROCEDURE sp_approve_leave(
    IN  p_request_id    INT,
    IN  p_approver_id   INT,
    IN  p_action        ENUM('Approved','Rejected'),
    IN  p_note          TEXT,
    OUT p_status_msg    VARCHAR(200)
)
BEGIN
    DECLARE v_emp_id        INT;
    DECLARE v_leave_type_id TINYINT;
    DECLARE v_total_days    DECIMAL(5,1);
    DECLARE v_year          YEAR;
    DECLARE v_current_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_msg = 'ERROR: Leave action failed.';
    END;

    SELECT emp_id, leave_type_id, total_days, YEAR(start_date), status
    INTO   v_emp_id, v_leave_type_id, v_total_days, v_year, v_current_status
    FROM   leave_requests WHERE request_id = p_request_id;

    IF v_current_status != 'Pending' THEN
        SET p_status_msg = 'ERROR: Request is not in Pending status.';
        LEAVE sp_approve_leave;
    END IF;

    START TRANSACTION;

    UPDATE leave_requests SET
        status          = p_action,
        approved_by     = p_approver_id,
        approved_at     = NOW(),
        rejection_note  = IF(p_action = 'Rejected', p_note, NULL)
    WHERE request_id = p_request_id;

    IF p_action = 'Approved' THEN
        UPDATE leave_balances SET
            used_days    = used_days    + v_total_days,
            pending_days = GREATEST(pending_days - v_total_days, 0)
        WHERE emp_id = v_emp_id AND leave_type_id = v_leave_type_id AND year = v_year;
    ELSEIF p_action = 'Rejected' THEN
        UPDATE leave_balances SET
            pending_days = GREATEST(pending_days - v_total_days, 0)
        WHERE emp_id = v_emp_id AND leave_type_id = v_leave_type_id AND year = v_year;
    END IF;

    COMMIT;
    SET p_status_msg = CONCAT('SUCCESS: Leave request ', p_action, '.');
END$$

-- 7.04  sp_generate_payroll — generates payroll for all active employees for a period
CREATE PROCEDURE sp_generate_payroll(
    IN  p_period_id    SMALLINT,
    IN  p_processed_by INT,
    OUT p_status_msg   VARCHAR(200)
)
BEGIN
    DECLARE v_done    INT DEFAULT 0;
    DECLARE v_emp_id  INT;
    DECLARE v_basic   DECIMAL(12,2);
    DECLARE v_hra     DECIMAL(12,2);
    DECLARE v_gross   DECIMAL(12,2);
    DECLARE v_pf      DECIMAL(12,2);
    DECLARE v_tax     DECIMAL(12,2);
    DECLARE v_net     DECIMAL(12,2);
    DECLARE v_ot_hrs  DECIMAL(5,2);
    DECLARE v_ot_pay  DECIMAL(12,2);

    DECLARE cur_emp CURSOR FOR
        SELECT emp_id, base_salary FROM employees WHERE employment_status = 'Active';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_msg = 'ERROR: Payroll generation failed.';
    END;

    START TRANSACTION;

    OPEN cur_emp;
    loop_emp: LOOP
        FETCH cur_emp INTO v_emp_id, v_basic;
        IF v_done THEN LEAVE loop_emp; END IF;

        SET v_hra   = v_basic * 0.40;
        SET v_gross = v_basic + v_hra + 3000 + 2000 + 5000;  -- conv+medical+other
        SET v_pf    = fn_pf_deduction(v_basic);
        SET v_tax   = fn_tax_deduction(v_gross * 12);

        -- Overtime: fetch from attendance for this period's month/year
        SELECT COALESCE(SUM(overtime_hours), 0) INTO v_ot_hrs
        FROM   attendance a
        JOIN   payroll_periods pp ON pp.period_id = p_period_id
        WHERE  a.emp_id = v_emp_id
          AND  MONTH(a.attendance_date) = pp.period_month
          AND  YEAR(a.attendance_date)  = pp.period_year;

        SET v_ot_pay = ROUND((v_basic / (26 * 8)) * 1.5 * v_ot_hrs, 2);
        SET v_net    = fn_net_salary(v_gross + v_ot_pay, v_pf, v_tax, 0);

        INSERT IGNORE INTO payroll
            (emp_id, period_id, basic_salary, hra, conveyance, medical, other_allowance,
             gross_salary, pf_deduction, tax_deduction, total_deduction, net_salary,
             overtime_pay, working_days, present_days)
        VALUES
            (v_emp_id, p_period_id, v_basic, v_hra, 3000, 2000, 5000,
             v_gross, v_pf, v_tax, v_pf + v_tax, v_net,
             v_ot_pay, 26, 26);

    END LOOP;
    CLOSE cur_emp;

    UPDATE payroll_periods SET
        status       = 'Processed',
        processed_by = p_processed_by,
        processed_at = NOW()
    WHERE period_id = p_period_id;

    COMMIT;
    SET p_status_msg = 'SUCCESS: Payroll generated.';
END$$

-- 7.05  sp_assign_project
CREATE PROCEDURE sp_assign_project(
    IN  p_project_id   INT,
    IN  p_emp_id       INT,
    IN  p_role         VARCHAR(80),
    IN  p_allocation   TINYINT,
    OUT p_status_msg   VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_msg = 'ERROR: Assignment failed.';
    END;

    START TRANSACTION;

    INSERT INTO project_assignments (project_id, emp_id, role_in_project, assigned_date, allocation_pct)
    VALUES (p_project_id, p_emp_id, p_role, CURDATE(), p_allocation)
    ON DUPLICATE KEY UPDATE
        role_in_project = p_role,
        allocation_pct  = p_allocation,
        is_active       = 1;

    COMMIT;
    SET p_status_msg = 'SUCCESS: Project assignment saved.';
END$$

-- 7.06  sp_attendance_summary — returns monthly summary for an employee
CREATE PROCEDURE sp_attendance_summary(IN p_emp_id INT, IN p_year INT, IN p_month INT)
BEGIN
    SELECT
        p_emp_id                                                           AS emp_id,
        COUNT(*)                                                           AS total_records,
        SUM(status = 'Present')                                            AS present,
        SUM(status = 'Absent')                                             AS absent,
        SUM(status = 'Late')                                               AS late,
        SUM(status = 'Half-Day')                                           AS half_day,
        SUM(status = 'WFH')                                                AS wfh,
        SUM(status = 'Leave')                                              AS on_leave,
        SUM(status = 'Holiday')                                            AS holidays,
        ROUND(SUM(work_hours), 2)                                          AS total_work_hours,
        ROUND(SUM(overtime_hours), 2)                                      AS total_overtime,
        fn_attendance_percentage(p_emp_id, p_year, p_month)               AS attendance_pct
    FROM attendance
    WHERE emp_id = p_emp_id
      AND YEAR(attendance_date)  = p_year
      AND MONTH(attendance_date) = p_month;
END$$

DELIMITER ;

-- =============================================================================
-- 8. TRIGGERS
-- =============================================================================

DELIMITER $$

-- 8.01  trg_audit_employee_insert — log new employee creation
CREATE TRIGGER trg_audit_employee_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_values)
    VALUES (
        'employees',
        NEW.emp_id,
        'INSERT',
        JSON_OBJECT(
            'emp_code', NEW.emp_code,
            'email',    NEW.email,
            'dept_id',  NEW.dept_id,
            'role_id',  NEW.role_id
        )
    );
END$$

-- 8.02  trg_audit_employee_update — log employee updates
CREATE TRIGGER trg_audit_employee_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values)
    VALUES (
        'employees',
        OLD.emp_id,
        'UPDATE',
        JSON_OBJECT(
            'employment_status', OLD.employment_status,
            'dept_id',           OLD.dept_id,
            'base_salary',       OLD.base_salary
        ),
        JSON_OBJECT(
            'employment_status', NEW.employment_status,
            'dept_id',           NEW.dept_id,
            'base_salary',       NEW.base_salary
        )
    );
END$$

-- 8.03  trg_audit_employee_delete — log employee deletion
CREATE TRIGGER trg_audit_employee_delete
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, old_values)
    VALUES (
        'employees',
        OLD.emp_id,
        'DELETE',
        JSON_OBJECT('emp_code', OLD.emp_code, 'email', OLD.email)
    );
END$$

-- 8.04  trg_leave_request_insert — deduct pending_days on new leave request
CREATE TRIGGER trg_leave_request_insert
AFTER INSERT ON leave_requests
FOR EACH ROW
BEGIN
    IF NEW.status = 'Pending' THEN
        UPDATE leave_balances SET
            pending_days = pending_days + NEW.total_days
        WHERE emp_id       = NEW.emp_id
          AND leave_type_id = NEW.leave_type_id
          AND year          = YEAR(NEW.start_date);
    END IF;
END$$

-- 8.05  trg_attendance_late_notify — send notification if employee is Late
CREATE TRIGGER trg_attendance_late_notify
AFTER INSERT ON attendance
FOR EACH ROW
BEGIN
    IF NEW.status = 'Late' THEN
        INSERT INTO notifications (emp_id, title, message, type)
        VALUES (
            NEW.emp_id,
            'Late Attendance Recorded',
            CONCAT('You were marked Late on ', DATE_FORMAT(NEW.attendance_date,'%d-%b-%Y'),
                   '. Please ensure punctuality.'),
            'Attendance'
        );
    END IF;
END$$

-- 8.06  trg_payroll_audit — log every payroll record creation
CREATE TRIGGER trg_payroll_audit
AFTER INSERT ON payroll
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_values)
    VALUES (
        'payroll',
        NEW.payroll_id,
        'INSERT',
        JSON_OBJECT(
            'emp_id',      NEW.emp_id,
            'period_id',   NEW.period_id,
            'net_salary',  NEW.net_salary
        )
    );
END$$

-- 8.07  trg_leave_approve_notify — notify employee on leave decision
CREATE TRIGGER trg_leave_approve_notify
AFTER UPDATE ON leave_requests
FOR EACH ROW
BEGIN
    IF OLD.status = 'Pending' AND NEW.status IN ('Approved','Rejected') THEN
        INSERT INTO notifications (emp_id, title, message, type)
        VALUES (
            NEW.emp_id,
            CONCAT('Leave Request ', NEW.status),
            CONCAT('Your ', (SELECT type_name FROM leave_types WHERE leave_type_id = NEW.leave_type_id),
                   ' from ', DATE_FORMAT(NEW.start_date,'%d-%b'), ' to ',
                   DATE_FORMAT(NEW.end_date,'%d-%b-%Y'), ' has been ', NEW.status, '.'),
            'Leave'
        );
    END IF;
END$$

DELIMITER ;

-- =============================================================================
-- 9. SECURITY — DATABASE USERS & ROLES
-- =============================================================================
-- NOTE: Run these as the MySQL root user AFTER importing the schema.
--       Adjust host as needed ('%' for any host, '127.0.0.1' for local).
-- =============================================================================

-- Application admin account (full DML, no schema changes)
CREATE USER IF NOT EXISTS 'emp_admin'@'%' IDENTIFIED BY 'StrongPass@2025!';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON employee_mgmt.* TO 'emp_admin'@'%';

-- Read-only reporting account
CREATE USER IF NOT EXISTS 'emp_report'@'%' IDENTIFIED BY 'ReportPass@2025!';
GRANT SELECT ON employee_mgmt.* TO 'emp_report'@'%';

-- Employee self-service account (can read own data, update limited fields)
CREATE USER IF NOT EXISTS 'emp_user'@'%' IDENTIFIED BY 'UserPass@2025!';
GRANT SELECT ON employee_mgmt.vw_active_employees  TO 'emp_user'@'%';
GRANT SELECT ON employee_mgmt.vw_attendance_report TO 'emp_user'@'%';
GRANT SELECT ON employee_mgmt.vw_leave_status      TO 'emp_user'@'%';
GRANT SELECT ON employee_mgmt.vw_payroll_summary   TO 'emp_user'@'%';
GRANT INSERT ON employee_mgmt.leave_requests       TO 'emp_user'@'%';
GRANT INSERT ON employee_mgmt.notifications        TO 'emp_user'@'%';

FLUSH PRIVILEGES;

-- =============================================================================
-- 10. CRUD OPERATIONS
-- =============================================================================

-- -------  EMPLOYEES  -------

-- CREATE  (use stored procedure sp_add_employee in production)
-- INSERT INTO employees (...) VALUES (...);

-- READ — all active employees
SELECT * FROM vw_active_employees ORDER BY dept_name, full_name;

-- READ — single employee by ID
SELECT * FROM vw_active_employees WHERE emp_id = 5;

-- UPDATE — change department
UPDATE employees SET dept_id = 3 WHERE emp_id = 7;

-- UPDATE — deactivate employee (soft delete)
UPDATE employees SET employment_status = 'Resigned', termination_date = CURDATE()
WHERE emp_id = 22;

-- DELETE — hard delete (cascade will handle child rows)
-- DELETE FROM employees WHERE emp_id = 99;  -- use carefully!

-- -------  LEAVE REQUESTS  -------

-- CREATE
INSERT INTO leave_requests (emp_id, leave_type_id, start_date, end_date, total_days, reason)
VALUES (3, 1, '2025-08-11', '2025-08-13', 3, 'Personal work');

-- READ
SELECT * FROM vw_leave_status WHERE emp_id = 3 ORDER BY applied_at DESC;

-- UPDATE — cancel
UPDATE leave_requests SET status = 'Cancelled' WHERE request_id = 20 AND emp_id = 19;

-- -------  ATTENDANCE  -------

-- CREATE — mark today's check-in
INSERT INTO attendance (emp_id, attendance_date, check_in, status)
VALUES (6, CURDATE(), CURTIME(), 'Present')
ON DUPLICATE KEY UPDATE check_in = CURTIME();

-- UPDATE — add check-out
UPDATE attendance SET check_out = CURTIME()
WHERE emp_id = 6 AND attendance_date = CURDATE();

-- READ — weekly report for an employee
SELECT * FROM vw_attendance_report
WHERE emp_code = 'EMP006'
  AND attendance_date BETWEEN '2025-06-02' AND '2025-06-08'
ORDER BY attendance_date;

-- -------  PAYROLL  -------

-- READ — payroll for a period
SELECT * FROM vw_payroll_summary WHERE period_month = 6 AND period_year = 2025;

-- UPDATE — mark as paid
UPDATE payroll SET payment_status = 'Paid', payment_date = CURDATE()
WHERE period_id = 7 AND payment_status = 'Pending';

-- -------  PROJECTS  -------

-- CREATE
INSERT INTO projects (project_code, project_name, dept_id, start_date, status, priority, manager_id)
VALUES ('PRJ009','Cloud Migration',2,'2025-08-01','Planning','High',4);

-- UPDATE
UPDATE projects SET status = 'Active' WHERE project_code = 'PRJ009';

-- DELETE (soft via status)
UPDATE projects SET status = 'Cancelled' WHERE project_id = 9;

-- -------  ANNOUNCEMENTS  -------

-- CREATE
INSERT INTO announcements (title, body, published_by, priority, publish_date)
VALUES ('Holiday Notice','Office closed on August 15 for Independence Day.',25,'Important',CURDATE());

-- UPDATE — deactivate expired
UPDATE announcements SET is_active = 0 WHERE expiry_date < CURDATE();

-- -------  AUDIT LOGS  -------

-- READ — latest 50 changes
SELECT * FROM audit_logs ORDER BY changed_at DESC LIMIT 50;

-- -------  NOTIFICATIONS  -------

-- Mark notification as read
UPDATE notifications SET is_read = 1, read_at = NOW()
WHERE notif_id = 3 AND emp_id = 1;

-- =============================================================================
-- 11. ADVANCED SELECT QUERIES / REPORTS
-- =============================================================================

-- R01: Employee list with department, designation, and experience
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name)             AS full_name,
    d.dept_name,
    des.title                                         AS designation,
    e.employment_type,
    e.joining_date,
    fn_employee_experience(e.joining_date)            AS experience_yrs,
    e.base_salary,
    CONCAT(m.first_name,' ',m.last_name)              AS reports_to
FROM employees e
INNER JOIN departments  d   ON e.dept_id    = d.dept_id
INNER JOIN designations des ON e.desig_id   = des.desig_id
LEFT  JOIN employees    m   ON e.manager_id = m.emp_id
WHERE e.employment_status = 'Active'
ORDER BY d.dept_name, e.last_name;

-- R02: Department-wise employee count and average salary (GROUP BY + HAVING)
SELECT
    d.dept_name,
    COUNT(e.emp_id)       AS total_employees,
    ROUND(AVG(e.base_salary), 2) AS avg_salary,
    SUM(e.base_salary)    AS total_payroll
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.employment_status = 'Active'
GROUP BY d.dept_id, d.dept_name
HAVING total_employees > 0
ORDER BY total_employees DESC;

-- R03: Monthly payroll report (June 2025) with tax and net
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee,
    d.dept_name,
    p.basic_salary,
    p.gross_salary,
    p.pf_deduction,
    p.tax_deduction,
    p.bonus,
    p.overtime_pay,
    p.net_salary,
    p.payment_status
FROM payroll p
INNER JOIN employees       e  ON p.emp_id    = e.emp_id
INNER JOIN departments     d  ON e.dept_id   = d.dept_id
INNER JOIN payroll_periods pp ON p.period_id = pp.period_id
WHERE pp.period_month = 6 AND pp.period_year = 2025
ORDER BY p.net_salary DESC;

-- R04: Leave summary per employee (current year) — INNER JOIN + aggregate
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee,
    lt.type_name AS leave_type,
    lb.total_days,
    lb.used_days,
    lb.pending_days,
    lb.remaining_days
FROM leave_balances lb
INNER JOIN employees   e  ON lb.emp_id        = e.emp_id
INNER JOIN leave_types lt ON lb.leave_type_id = lt.leave_type_id
WHERE lb.year = YEAR(CURDATE())
  AND e.employment_status = 'Active'
ORDER BY e.last_name, lt.type_name;

-- R05: Attendance percentage per employee — June 2025
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name)           AS employee,
    d.dept_name,
    COUNT(a.attendance_id)                          AS total_days,
    SUM(a.status IN ('Present','Late','WFH'))       AS present_days,
    SUM(a.status = 'Absent')                        AS absent_days,
    ROUND(SUM(a.work_hours), 1)                     AS total_hours,
    fn_attendance_percentage(e.emp_id, 2025, 6)    AS attendance_pct
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
LEFT  JOIN attendance  a ON e.emp_id  = a.emp_id
                         AND YEAR(a.attendance_date)  = 2025
                         AND MONTH(a.attendance_date) = 6
WHERE e.employment_status = 'Active'
GROUP BY e.emp_id, e.emp_code, e.first_name, e.last_name, d.dept_name
ORDER BY attendance_pct DESC;

-- R06: Project allocation report — who is assigned to what
SELECT
    p.project_name,
    p.status,
    COUNT(pa.emp_id)           AS team_size,
    SUM(pa.allocation_pct)     AS total_allocation_pct,
    GROUP_CONCAT(DISTINCT CONCAT(e.first_name,' ',e.last_name) ORDER BY e.first_name SEPARATOR ', ') AS members
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id AND pa.is_active = 1
LEFT JOIN employees           e  ON pa.emp_id    = e.emp_id
GROUP BY p.project_id, p.project_name, p.status
ORDER BY p.priority DESC, p.project_name;

-- R07: Subquery — employees earning above department average
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee,
    d.dept_name,
    e.base_salary,
    dept_avg.avg_sal AS dept_avg_salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN (
    SELECT dept_id, ROUND(AVG(base_salary),2) AS avg_sal
    FROM employees WHERE employment_status = 'Active'
    GROUP BY dept_id
) dept_avg ON e.dept_id = dept_avg.dept_id
WHERE e.base_salary > dept_avg.avg_sal
  AND e.employment_status = 'Active'
ORDER BY d.dept_name, e.base_salary DESC;

-- R08: CTE — Top 3 earners per department
WITH ranked_employees AS (
    SELECT
        e.emp_id,
        CONCAT(e.first_name,' ',e.last_name) AS full_name,
        d.dept_name,
        e.base_salary,
        des.title AS designation,
        ROW_NUMBER() OVER (PARTITION BY e.dept_id ORDER BY e.base_salary DESC) AS salary_rank
    FROM employees e
    INNER JOIN departments  d   ON e.dept_id  = d.dept_id
    INNER JOIN designations des ON e.desig_id = des.desig_id
    WHERE e.employment_status = 'Active'
)
SELECT dept_name, full_name, designation, base_salary, salary_rank
FROM   ranked_employees
WHERE  salary_rank <= 3
ORDER BY dept_name, salary_rank;

-- R09: LEFT JOIN — employees with no attendance recorded in June 2025
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee,
    d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
LEFT  JOIN attendance  a ON e.emp_id  = a.emp_id
                         AND YEAR(a.attendance_date)  = 2025
                         AND MONTH(a.attendance_date) = 6
WHERE e.employment_status = 'Active'
  AND a.attendance_id IS NULL
ORDER BY d.dept_name;

-- R10: Performance report — all evaluations Q1-2025 with rating
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS employee,
    d.dept_name,
    pe.eval_period,
    pe.overall_score,
    pe.rating,
    CONCAT(ev.first_name,' ',ev.last_name) AS evaluated_by
FROM performance_evaluations pe
INNER JOIN employees   e  ON pe.emp_id      = e.emp_id
INNER JOIN departments d  ON e.dept_id      = d.dept_id
INNER JOIN employees   ev ON pe.evaluator_id = ev.emp_id
WHERE pe.eval_period = 'Q1-2025'
ORDER BY pe.overall_score DESC;

-- R11: RIGHT JOIN — departments and their project count (include depts with no projects)
SELECT
    d.dept_name,
    COUNT(p.project_id) AS project_count,
    SUM(p.budget)        AS total_budget
FROM projects    p
RIGHT JOIN departments d ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY project_count DESC;

-- R12: Pagination — employee list page 2 (10 per page)
SELECT
    e.emp_code,
    CONCAT(e.first_name,' ',e.last_name) AS full_name,
    d.dept_name,
    e.base_salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.employment_status = 'Active'
ORDER BY e.emp_id
LIMIT 10 OFFSET 10;

-- R13: Leave requests pending approval
SELECT * FROM vw_leave_status WHERE status = 'Pending' ORDER BY applied_at;

-- R14: Salary band analysis (CASE)
SELECT
    CASE
        WHEN base_salary < 50000                   THEN 'Under 50K'
        WHEN base_salary BETWEEN 50000 AND 100000  THEN '50K–1L'
        WHEN base_salary BETWEEN 100001 AND 200000 THEN '1L–2L'
        ELSE 'Above 2L'
    END AS salary_band,
    COUNT(*) AS employee_count
FROM employees
WHERE employment_status = 'Active'
GROUP BY salary_band
ORDER BY MIN(base_salary);

-- R15: CTE — cumulative payroll spend per month in 2025
WITH monthly_spend AS (
    SELECT
        pp.period_month,
        pp.period_year,
        SUM(p.net_salary) AS monthly_net
    FROM payroll p
    JOIN payroll_periods pp ON p.period_id = pp.period_id
    WHERE pp.period_year = 2025
    GROUP BY pp.period_month, pp.period_year
)
SELECT
    period_month,
    period_year,
    monthly_net,
    SUM(monthly_net) OVER (ORDER BY period_month) AS cumulative_spend
FROM monthly_spend
ORDER BY period_month;

-- =============================================================================
-- 12. TRANSACTION EXAMPLES
-- =============================================================================

-- T01: Safely transfer an employee between departments
START TRANSACTION;

    UPDATE employees SET dept_id = 4, desig_id = 16 WHERE emp_id = 12;

    INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values)
    VALUES ('employees', 12, 'UPDATE',
            '{"dept_id":3,"desig_id":14}',
            '{"dept_id":4,"desig_id":16}');

COMMIT;

-- T02: Rollback example — if any step fails, nothing is saved
START TRANSACTION;

    UPDATE leave_balances SET used_days = used_days + 2
    WHERE emp_id = 3 AND leave_type_id = 1 AND year = 2025;

    UPDATE leave_requests SET status = 'Approved', approved_by = 1, approved_at = NOW()
    WHERE request_id = 100;  -- this will affect 0 rows if ID doesn't exist

    -- Simulate conditional rollback
    -- IF @@ROWCOUNT = 0 THEN ROLLBACK; END IF;
ROLLBACK;  -- rolling back for demo safety

-- =============================================================================
-- 13. INDEX DOCUMENTATION
-- =============================================================================
-- The following indexes exist and their purpose:
--
-- employees.idx_dept       — speeds dept-based employee queries (dept reports)
-- employees.idx_desig      — speeds designation-based filters
-- employees.idx_manager    — speeds org chart / reporting hierarchy queries
-- employees.idx_status     — speeds WHERE employment_status = 'Active'
-- employees.idx_joining    — speeds date-range queries (new joinees this month)
-- attendance.uq_att_emp_date — enforces one record per employee per day + lookup
-- attendance.idx_att_date  — speeds date-range attendance queries
-- attendance.idx_att_status— speeds status-based aggregation (absent count)
-- leave_requests.idx_lr_emp— speeds per-employee leave history queries
-- leave_requests.idx_lr_status — speeds pending approval dashboard
-- payroll.idx_pay_period   — speeds payroll-period joins
-- payroll.idx_pay_status   — speeds pending payment queries
-- audit_logs.idx_al_table  — speeds table-specific audit lookups
-- audit_logs.idx_al_time   — speeds time-range audit queries
-- login_history.idx_lh_emp — speeds per-employee login history
-- login_history.idx_lh_time— speeds time-range security queries
-- =============================================================================

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
-- Import this file with:
--   mysql -u root -p < employee_management_system.sql
-- or via phpMyAdmin: Import > Choose File
-- =============================================================================
