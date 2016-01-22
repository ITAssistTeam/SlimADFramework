CREATE DATABASE  IF NOT EXISTS `logindb` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `logindb`;
-- MySQL dump 10.13  Distrib 5.7.10, for Win64 (x86_64)
--
-- Host: localhost    Database: logindb
-- ------------------------------------------------------
-- Server version	5.7.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Logins`
--

DROP TABLE IF EXISTS `Logins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Logins` (
  `LoginID` int(11) NOT NULL AUTO_INCREMENT,
  `UserID` int(11) DEFAULT NULL,
  `LoginTime` datetime DEFAULT NULL,
  `UserGroups` text,
  `Extension` varchar(45) DEFAULT NULL,
  `Archived` int(1) DEFAULT '0',
  `LastActive` datetime DEFAULT NULL,
  PRIMARY KEY (`LoginID`)
) ENGINE=InnoDB AUTO_INCREMENT=334 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Users` (
  `UserID` int(11) NOT NULL AUTO_INCREMENT,
  `Username` varchar(45) DEFAULT NULL,
  `FirstName` varchar(45) DEFAULT NULL,
  `LastName` varchar(45) DEFAULT NULL,
  `Archived` bit(1) DEFAULT b'0',
  `SysAdmin` int(1) DEFAULT '0',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'logindb'
--
/*!50003 DROP PROCEDURE IF EXISTS `AddUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `AddUser`(IN UsernameIN varchar(45), IN FirstNameIN varchar(45), IN LastNameIN varchar(45), IN SysAdminIN INT(1))
BEGIN
	CASE WHEN (SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1) > 0 
    THEN SELECT 0 as Success, 'Username exists' AS Message;
    ELSE
    INSERT INTO 
    Users(Username, FirstName, LastName, SysAdmin) 
    VALUES
    (UsernameIN, FirstNameIN, LastNameIN, SysAdminIN);
    INSERT INTO `policiesdb`.`UserRoles` (UserID, RoleID) VALUES (LAST_INSERT_ID(), 2);
    END CASE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckLogin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckLogin`(IN LoginIDIN int)
begin

IF DATE_ADD((SELECT LastActive FROM Logins WHERE LoginID = LoginIDIN  AND Archived != 1 LIMIT 1), INTERVAL 1 HOUR) > NOW() 
THEN 
UPDATE Logins SET LastActive = NOW() WHERE LoginID = LoginIDIN;
SELECT  *  FROM Logins LEFT JOIN (SELECT SysAdmin, UserID, FirstName, LastName FROM Users WHERE Archived != 1) U ON Logins.UserID = U.UserID 
WHERE LoginID = LoginIDIN AND DATE_ADD(LastActive, INTERVAL 1 HOUR) > NOW() AND Archived != 1 LIMIT 1;
END IF;




END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckUser`(IN UsernameIN varchar(45), IN FirstNameIN varchar(45), IN LastNameIN varchar(45), IN UserGroupsIN TEXT, IN ExtensionIN varchar(45))
BEGIN
DECLARE out_param int;
  IF (SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1) > 0
  THEN
    
      INSERT INTO Logins (UserID, LoginTime, UserGroups, Extension, LastActive) VALUES ((SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1), NOW(), UserGroupsIN, ExtensionIN, NOW());
	  SET out_param = LAST_INSERT_ID();
      SELECT *, UserGroupsIN AS UserGroups, ExtensionIN AS Extension, out_param as loginid FROM Users WHERE Username = UsernameIN AND Archived != 1;
  ELSE
	  INSERT INTO Users  (Username, FirstName, LastName) VALUES (UsernameIN, FirstNameIN, LastNameIN);
      INSERT INTO `policiesdb`.`UserRoles` (UserID, RoleID) VALUES ((SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1), 2);
      INSERT INTO `vbox`.UserSettings (UserID) VALUES ((SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1));
      INSERT INTO Logins (UserID, LoginTime, UserGroups, Extension, LastActive) VALUES ((SELECT UserID FROM Users WHERE Username = UsernameIN AND Archived != 1), NOW(), UserGroupsIN, ExtensionIN, NOW());
	  SET out_param = LAST_INSERT_ID();
     
     SELECT *, UserGroupsIN AS UserGroups, ExtensionIN AS Extension, out_param as loginid FROM Users  WHERE Username = UsernameIN AND Archived != 1;
   END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `DeleteUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `DeleteUser`(IN UserIDIN INT)
BEGIN
	UPDATE Users SET Archived = 1 WHERE UserID = UserIDIN;
    UPDATE `policiesdb`.`UserRoles` SET Archived  = 1 WHERE UserID = UserIDIN;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUser`(IN UserIDIN INT)
BEGIN
SELECT UserID, CONCAT(FirstName, ' ', LastName) AS Username, SysAdmin, FirstName, LastName, Username AS AccountName FROM Users WHERE UserID = UserIDIN;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetUsers` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetUsers`()
BEGIN
SELECT UserID, CONCAT(FirstName, ' ', LastName) AS Username, SysAdmin, FirstName, LastName, Username AS AccountName FROM Users WHERE Archived != 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateUser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `UpdateUser`(IN UserIDIN INT, IN UsernameIN varchar(45), IN FirstNameIN varchar(45), IN LastNameIN varchar(45), IN SysAdminIN INT(1))
BEGIN
   UPDATE Users SET Username = UsernameIN, FirstName = FirstNameIN, LastName = LastNameIN, SysAdmin = SysAdminIN WHERE UserID = UserIDIN;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-01-21 15:45:36
