-- Add Personal Information Fields to tbl_workers
-- Run this SQL to add the new personal information fields
-- This script is safe to run multiple times (uses IF NOT EXISTS logic)

-- Personal Information Fields
ALTER TABLE tbl_workers
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS gender ENUM('male', 'female', 'other', 'prefer_not_to_say') DEFAULT 'prefer_not_to_say',
ADD COLUMN IF NOT EXISTS nationality VARCHAR(50) DEFAULT 'Malaysian',

-- Emergency Contact Information
ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS emergency_contact_relationship VARCHAR(50),

-- Additional Address Fields (to make address more structured)
ADD COLUMN IF NOT EXISTS city VARCHAR(50),
ADD COLUMN IF NOT EXISTS state VARCHAR(50),
ADD COLUMN IF NOT EXISTS postal_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS country VARCHAR(50) DEFAULT 'Malaysia',

-- System tracking fields
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Create indexes for better performance (safe to run multiple times)
CREATE INDEX IF NOT EXISTS idx_date_of_birth ON tbl_workers(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_gender ON tbl_workers(gender);
CREATE INDEX IF NOT EXISTS idx_nationality ON tbl_workers(nationality);
CREATE INDEX IF NOT EXISTS idx_city ON tbl_workers(city);
CREATE INDEX IF NOT EXISTS idx_state ON tbl_workers(state);

-- Sample data update (optional - for testing)
-- UPDATE tbl_workers SET 
--     nationality = 'Malaysian',
--     country = 'Malaysia',
--     gender = 'prefer_not_to_say'
-- WHERE nationality IS NULL OR nationality = '';
