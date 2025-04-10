CREATE TABLE IF NOT EXISTS `weapon_bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `end_time` int(11) NOT NULL,
  `ban_duration` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `weapon_ban_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_identifier` varchar(60) NOT NULL,
  `target_identifier` varchar(60) NOT NULL,
  `action` varchar(20) NOT NULL,
  `duration` int(11) NOT NULL,
  `reason` text,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; 