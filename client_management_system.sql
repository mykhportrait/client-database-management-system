-- =============================================================================
-- CLIENT MANAGEMENT SYSTEM - MySQL Database Script
-- Version: 1.0 | Compatible: MySQL 8.0+
-- =============================================================================
-- HOW TO IMPORT:
--   phpMyAdmin : Import > Choose File > Run
--   MySQL CLI  : mysql -u root -p < client_management_system.sql
--   Workbench  : File > Run SQL Script
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS client_mgmt;
CREATE DATABASE client_mgmt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE client_mgmt;

-- =============================================================================
-- 1. LOOKUP TABLES
-- =============================================================================

CREATE TABLE client_types (
    client_type_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL,
    description VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (client_type_id),
    UNIQUE KEY uq_client_type_name (type_name)
) ENGINE=InnoDB;

CREATE TABLE regions (
    region_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    region_name VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL DEFAULT 'Ghana',
    PRIMARY KEY (region_id),
    UNIQUE KEY uq_region_name (region_name)
) ENGINE=InnoDB;

CREATE TABLE service_types (
    service_type_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_name VARCHAR(80) NOT NULL,
    bandwidth VARCHAR(50) DEFAULT NULL,
    sla_target VARCHAR(20) DEFAULT NULL,
    description VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (service_type_id),
    UNIQUE KEY uq_service_name (service_name)
) ENGINE=InnoDB;

CREATE TABLE branches (
    branch_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    region_id SMALLINT UNSIGNED NOT NULL,
    location VARCHAR(150) NOT NULL,
    manager_name VARCHAR(100) DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    established_date DATE DEFAULT NULL,
    PRIMARY KEY (branch_id),
    KEY idx_branch_region (region_id),
    CONSTRAINT fk_branch_region FOREIGN KEY (region_id) REFERENCES regions(region_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =============================================================================
-- 2. CORE CLIENT DATA
-- =============================================================================

CREATE TABLE clients (
    client_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_no VARCHAR(30) NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    client_type_id TINYINT UNSIGNED NOT NULL,
    region_id SMALLINT UNSIGNED NOT NULL,
    address VARCHAR(255) DEFAULT NULL,
    contact_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) NOT NULL,
    status ENUM('Active','Pending','Suspended','Inactive') NOT NULL DEFAULT 'Active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (client_id),
    UNIQUE KEY uq_account_no (account_no),
    UNIQUE KEY uq_client_email (email),
    KEY idx_client_region (region_id),
    KEY idx_client_status (status),
    CONSTRAINT fk_client_type FOREIGN KEY (client_type_id) REFERENCES client_types(client_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_client_region FOREIGN KEY (region_id) REFERENCES regions(region_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE client_contacts (
    contact_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(80) DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (contact_id),
    KEY idx_contact_client (client_id),
    CONSTRAINT fk_contact_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE client_services (
    client_service_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    service_type_id TINYINT UNSIGNED NOT NULL,
    service_name VARCHAR(120) NOT NULL,
    bandwidth VARCHAR(50) DEFAULT NULL,
    monthly_fee DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    setup_fee DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    contract_start DATE NOT NULL,
    contract_end DATE DEFAULT NULL,
    status ENUM('Active','Pending','Suspended','Expired') NOT NULL DEFAULT 'Active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (client_service_id),
    KEY idx_client_service_client (client_id),
    KEY idx_service_type (service_type_id),
    CONSTRAINT fk_client_service_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_client_service_type FOREIGN KEY (service_type_id) REFERENCES service_types(service_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE sites (
    site_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    site_code VARCHAR(20) NOT NULL,
    site_name VARCHAR(120) NOT NULL,
    region_id SMALLINT UNSIGNED NOT NULL,
    physical_address VARCHAR(255) NOT NULL,
    gps_location VARCHAR(80) DEFAULT NULL,
    equipment VARCHAR(120) DEFAULT NULL,
    install_date DATE DEFAULT NULL,
    bandwidth VARCHAR(50) DEFAULT NULL,
    uptime_percent DECIMAL(5,2) DEFAULT 0.00,
    status ENUM('Online','Offline','Degraded','Pending') NOT NULL DEFAULT 'Online',
    PRIMARY KEY (site_id),
    UNIQUE KEY uq_site_code (site_code),
    KEY idx_site_client (client_id),
    KEY idx_site_region (region_id),
    CONSTRAINT fk_site_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_site_region FOREIGN KEY (region_id) REFERENCES regions(region_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE service_alerts (
    alert_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    site_id INT UNSIGNED DEFAULT NULL,
    alert_title VARCHAR(120) NOT NULL,
    alert_message TEXT NOT NULL,
    severity ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    status ENUM('Open','In Progress','Resolved') NOT NULL DEFAULT 'Open',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (alert_id),
    KEY idx_alert_client (client_id),
    KEY idx_alert_site (site_id),
    CONSTRAINT fk_alert_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_alert_site FOREIGN KEY (site_id) REFERENCES sites(site_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE invoices (
    invoice_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    invoice_no VARCHAR(40) NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status ENUM('Paid','Pending','Overdue') NOT NULL DEFAULT 'Pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (invoice_id),
    UNIQUE KEY uq_invoice_no (invoice_no),
    KEY idx_invoice_client (client_id),
    CONSTRAINT fk_invoice_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================================
-- 3. SAMPLE DATA
-- =============================================================================

INSERT INTO client_types (type_name, description) VALUES
('Enterprise', 'Large corporate and business clients'),
('Government', 'Public sector and agency clients'),
('Commercial', 'Retail and commercial organizations'),
('Education', 'Academic and training institutions'),
('Mining', 'Mining and industrial operations');

INSERT INTO regions (region_name, country) VALUES
('Greater Accra', 'Ghana'),
('Ashanti', 'Ghana'),
('Western', 'Ghana'),
('Northern', 'Ghana'),
('Eastern', 'Ghana'),
('Bono', 'Ghana');

INSERT INTO service_types (service_name, bandwidth, sla_target, description) VALUES
('Internet', '100 Mbps', '99.5%', 'Business internet access'),
('WAN', '500 Mbps', '99.7%', 'Wide area network connectivity'),
('Leased Line', '1 Gbps', '99.9%', 'Dedicated point-to-point connectivity'),
('Fiber', '500 Mbps', '99.8%', 'Fiber broadband service'),
('VSAT', '100 Mbps', '98.5%', 'Satellite-backed connectivity'),
('Web Hosting', '2 Gbps', '99.99%', 'Hosting and remote managed services');

INSERT INTO branches (branch_name, region_id, location, manager_name, phone, email, established_date) VALUES
('Accra HQ', 1, 'Airport City, Accra', 'Kwabena Koomson', '0302-812000', 'accra@comsysghana.com', '2008-03-01'),
('Kumasi Branch', 2, 'Adum, Kumasi', 'Adwoa Mensah', '0322-241500', 'kumasi@comsysghana.com', '2012-06-01'),
('Takoradi Branch', 3, 'Harbour Road, Takoradi', 'Kofi Adjei', '0312-023100', 'takoradi@comsysghana.com', '2015-01-01');

INSERT INTO clients (account_no, company_name, client_type_id, region_id, address, contact_name, phone, email, status) VALUES
('CGH-001', 'Ghana Commercial Bank', 1, 1, 'Thorpe Road, High Street, Accra', 'Kwame Asante', '0302-740200', 'kwame.asante@gcb.com.gh', 'Active'),
('CGH-002', 'Stanbic Bank Ghana', 1, 1, 'Stanbic Heights, Airport City, Accra', 'Abena Owusu', '0302-610220', 'a.owusu@stanbicbank.com.gh', 'Active'),
('CGH-004', 'University of Ghana', 4, 1, 'Commonwealth Hall, Legon, Accra', 'Prof. Ama Sarpong', '0302-500381', 'ict@ug.edu.gh', 'Active'),
('CGH-006', 'Volta River Authority', 2, 5, 'Electro Volta House, Accra', 'Yaw Darko', '0302-664941', 'yaw.darko@vra.com', 'Active'),
('CGH-008', 'Newmont Ghana Gold', 5, 2, 'Ahafo Mine Complex, Brong Ahafo', 'Prince Nkrumah', '0322-180000', 'p.nkrumah@newmont.com', 'Active'),
('CGH-011', 'KNUST', 4, 2, 'University Post Office, Kumasi', 'Dr. Isaac Asiedu', '0322-060351', 'ict@knust.edu.gh', 'Active');

INSERT INTO client_contacts (client_id, full_name, position, phone, email, is_primary) VALUES
(1, 'Kwame Asante', 'IT Manager', '0302-740200', 'kwame.asante@gcb.com.gh', 1),
(2, 'Abena Owusu', 'Operations Manager', '0302-610220', 'a.owusu@stanbicbank.com.gh', 1),
(3, 'Prof. Ama Sarpong', 'IT Director', '0302-500381', 'ict@ug.edu.gh', 1),
(4, 'Yaw Darko', 'Network Manager', '0302-664941', 'yaw.darko@vra.com', 1),
(5, 'Prince Nkrumah', 'Head of Infrastructure', '0322-180000', 'p.nkrumah@newmont.com', 1),
(6, 'Dr. Isaac Asiedu', 'ICT Lead', '0322-060351', 'ict@knust.edu.gh', 1);

INSERT INTO client_services (client_id, service_type_id, service_name, bandwidth, monthly_fee, setup_fee, contract_start, contract_end, status) VALUES
(1, 3, 'Leased Line', '1 Gbps', 45000.00, 15000.00, '2023-01-01', '2025-12-31', 'Active'),
(2, 2, 'MPLS', '500 Mbps', 32000.00, 8000.00, '2022-06-15', '2025-06-14', 'Active'),
(3, 4, 'Fiber', '2 Gbps', 55000.00, 25000.00, '2020-09-01', '2025-08-31', 'Active'),
(4, 5, 'VSAT', '100 Mbps', 22000.00, 6000.00, '2022-01-01', '2024-12-31', 'Active'),
(5, 5, 'VSAT', '50 Mbps', 14500.00, 5000.00, '2023-07-01', '2026-06-30', 'Active'),
(6, 4, 'Fiber', '1 Gbps', 32000.00, 12000.00, '2020-01-01', '2024-12-31', 'Active');

INSERT INTO sites (client_id, site_code, site_name, region_id, physical_address, gps_location, equipment, install_date, bandwidth, uptime_percent, status) VALUES
(1, 'AC-01', 'Accra', 1, 'Thorpe Road, Accra', '5.5563, -0.1965', 'Cisco ASR 1001', '2023-01-15', '1 Gbps', 99.97, 'Online'),
(1, 'KU-01', 'Kumasi', 2, 'Prempeh II St, Kumasi', '6.6885, -1.6244', 'Cisco ISR 4331', '2023-02-01', '100 Mbps', 99.82, 'Online'),
(3, 'LE-01', 'Legon', 1, 'Legon Campus, Accra', '5.6500, -0.1943', 'Juniper MX204', '2020-09-15', '2 Gbps', 99.91, 'Online'),
(4, 'AK-01', 'Akosombo', 5, 'Akosombo Dam, Eastern', '6.3048, 0.0529', 'iDirect 950mp', '2022-03-20', '100 Mbps', 98.50, 'Online'),
(5, 'AH-01', 'Ahafo', 6, 'Ahafo Mine Complex, Brong Ahafo', '7.0515, -2.6247', 'iDirect 950mp', '2023-07-15', '50 Mbps', 99.20, 'Online'),
(6, 'KE-01', 'Kumasi East', 2, 'University Ave, Kumasi', '6.6752, -1.5635', 'Cisco Nexus 9508', '2020-01-20', '1 Gbps', 99.85, 'Online');

INSERT INTO service_alerts (client_id, site_id, alert_title, alert_message, severity, status) VALUES
(4, 4, 'Network Degradation', 'Connection performance fell below expected threshold at Akosombo site.', 'Medium', 'In Progress'),
(5, 5, 'Planned Maintenance', 'Scheduled maintenance is required for the Ahafo site.', 'Low', 'Open');

INSERT INTO invoices (client_id, invoice_no, invoice_date, due_date, amount, status) VALUES
(1, 'INV-2025-001', '2025-01-01', '2025-01-15', 45000.00, 'Paid'),
(2, 'INV-2025-002', '2025-01-02', '2025-01-16', 32000.00, 'Pending'),
(3, 'INV-2025-003', '2025-01-03', '2025-01-17', 55000.00, 'Paid'),
(4, 'INV-2025-004', '2025-01-04', '2025-01-18', 22000.00, 'Pending');

-- =============================================================================
-- 4. OPTIONAL REPORTING VIEWS
-- =============================================================================

CREATE OR REPLACE VIEW vw_client_overview AS
SELECT
    c.client_id,
    c.account_no,
    c.company_name,
    ct.type_name AS client_type,
    r.region_name,
    c.contact_name,
    c.email,
    c.status,
    COUNT(DISTINCT cs.client_service_id) AS service_count,
    ROUND(COALESCE(SUM(cs.monthly_fee), 0), 2) AS monthly_revenue,
    COUNT(DISTINCT s.site_id) AS site_count
FROM clients c
LEFT JOIN client_types ct ON ct.client_type_id = c.client_type_id
LEFT JOIN regions r ON r.region_id = c.region_id
LEFT JOIN client_services cs ON cs.client_id = c.client_id AND cs.status = 'Active'
LEFT JOIN sites s ON s.client_id = c.client_id
GROUP BY c.client_id, c.account_no, c.company_name, ct.type_name, r.region_name, c.contact_name, c.email, c.status;

SET FOREIGN_KEY_CHECKS = 1;
