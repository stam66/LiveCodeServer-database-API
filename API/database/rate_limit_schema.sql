-- ============================================================================
-- Rate Limiting Table Schema
-- ============================================================================
-- This table tracks API request attempts per IP address to prevent abuse
-- Run this SQL in your MySQL database to enable rate limiting

CREATE TABLE IF NOT EXISTS `rate_limit` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `ip_address` VARCHAR(45) NOT NULL,
  `endpoint` VARCHAR(50) NOT NULL,
  `attempts` INT DEFAULT 0,
  `last_attempt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `locked_until` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_ip_endpoint` (`ip_address`, `endpoint`),
  KEY `idx_locked_until` (`locked_until`),
  KEY `idx_last_attempt` (`last_attempt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Usage Notes:
-- ============================================================================
-- - ip_address: Client IP (supports IPv4 and IPv6)
-- - endpoint: API endpoint being accessed (e.g., "login", "api")
-- - attempts: Number of attempts in current window
-- - last_attempt: Timestamp of most recent attempt
-- - locked_until: When set, IP is rate limited until this timestamp
-- - Indexes optimize lookups and cleanup queries

-- ============================================================================
-- Maintenance:
-- ============================================================================
-- Old records are automatically cleaned up by the rate limiting functions
-- You can also add a cron job to clean up periodically:
--
-- DELETE FROM rate_limit
-- WHERE last_attempt < DATE_SUB(NOW(), INTERVAL 24 HOUR)
--   AND (locked_until IS NULL OR locked_until < NOW());
