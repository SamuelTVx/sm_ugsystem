CREATE TABLE IF NOT EXISTS `underground_stats` (
  `identifier` varchar(64) NOT NULL,
  `reputation` int(11) NOT NULL DEFAULT 0,
  `upgrades` longtext NOT NULL DEFAULT '[]',
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;