-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 22, 2020 at 02:01 PM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.4.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `testdb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_permission` (IN `to_acc` VARCHAR(20), IN `permit` INT(1))  NO SQL
BEGIN
DECLARE CURRENT_acc varchar(20) DEFAULT'0';
SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));

INSERT INTO accessing_exceptions VALUES(CURRENT_acc,to_acc,permit);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_account` ()  NO SQL
BEGIN
DELETE FROM account 
WHERE account.username in (
    SELECT L.username FROM logged_in_users L
    WHERE L.time = (SELECT MAX(logged_in_users.time) FROM logged_in_users));


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_mail` (IN `ID` INT)  NO SQL
BEGIN
DECLARE CURRENT_acc varchar(20) DEFAULT'0';
SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));

UPDATE email_sender
SET email_sender.is_deleted =1
WHERE email_sender.sender=CURRENT_acc AND email_sender.email_ID=ID;
UPDATE email_receiver 
SET email_receiver.is_deleted=1
WHERE email_receiver.receiver=CURRENT_acc AND email_receiver.email_ID=ID ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_information` ()  NO SQL
BEGIN

SELECT account.* 
FROM account JOIN logged_in_users ON
account.username = logged_in_users.username

WHERE logged_in_users.time = (SELECT MAX(U.time) FROM logged_in_users U);





END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_notifications` ()  NO SQL
BEGIN

SELECT notification.text,notification.creation_time
FROM notification JOIN logged_in_users ON notification.username = logged_in_users.username
WHERE logged_in_users.time = (SELECT MAX(U.time)
FROM logged_in_users U)
ORDER BY notification.creation_time DESC;




END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_personal_info` (IN `p_user` VARCHAR(20))  NO SQL
BEGIN
DECLARE CURRENT_acc varchar(20) DEFAULT'0';
DECLARE flag int(1) DEFAULT 2;
DECLARE def_permit int(1) DEFAULT 2;
    
CREATE TEMPORARY TABLE info
SELECT A.first_name,A.last_name,A.nickname,A.phone_number,
A.birthdate,A.personal_ID,A.address
FROM account A
WHERE A.username = p_user;

SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));
SET def_permit = (SELECT MAX(A.access_mode)
                  FROM account A
                  WHERE A.username=p_user);

SET flag = (SELECT MAX(E.permition) 
            FROM accessing_exceptions E
            WHERE E.from_user=p_user and E.to_user=CURRENT_acc);
          
IF flag = 0 or (flag=3 and def_permit=0) THEN
UPDATE info
SET info.first_name='*' ,info.last_name='*',info.nickname='*',info.phone_number='*',
info.birthdate='*',info.personal_ID='*',info.address = '*';

INSERT INTO notification VALUES(p_user,CURRENT_TIMESTAMP,(SELECT concat(CURRENT_acc," tried to get your personal information but he/she didnt have the permition")));
ELSEIF EXISTS(SELECT 1 FROM info) THEN
INSERT INTO notification VALUES(p_user,CURRENT_TIMESTAMP,(SELECT concat(CURRENT_acc," got access to your personal information")));

END if;
SELECT info.* from info;
drop TEMPORARY TABLE info;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_in` (IN `p_username` VARCHAR(20), IN `p_password` VARCHAR(20), OUT `state` TEXT)  NO SQL
BEGIN
SET `p_password` = MD5(`p_password`);
    IF EXISTS
        (
        SELECT
            A.username
        FROM
            `account` A
        WHERE
            A.username = p_username
    ) THEN IF EXISTS(
    SELECT
        A.password
    FROM
        account A
    WHERE
        A.username = `p_username` AND A.password =`p_password`
) THEN
INSERT INTO `logged_in_users`(`username`, `time`)
VALUES(`p_username`, CURRENT_TIMESTAMP);
SET
    state = 'logged in'; ELSE
SET
    state = 'wrong password';
END IF; ELSE
SET
    state = 'wrong username';
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `notify` (IN `p_username` VARCHAR(20), IN `p_text` TEXT, OUT `state` TEXT)  NO SQL
BEGIN
INSERT INTO `notification`(`username`, `creation_time`, `text`) VALUES (p_username,CURRENT_TIMESTAMP,p_text);
SET state = 'done';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `read_mail` (IN `ID` INT, OUT `state` TEXT)  NO SQL
BEGIN
DECLARE CURRENT_acc varchar(20) DEFAULT'0';
SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));
IF EXISTS ( SELECT * FROM email_sender S,email_receiver R WHERE
           S.email_ID=ID and R.email_ID=ID AND
           (S.sender = CURRENT_acc 
            or R.receiver=CURRENT_acc)) THEN
           SET state = "email successfully read";
ELSE
           set state = " you cant read the email";
           END IF;
           
UPDATE email_sender
SET email_sender.is_read =1
WHERE email_sender.sender=CURRENT_acc AND email_sender.email_ID=ID;
UPDATE email_receiver 
SET email_receiver.is_read=1
WHERE email_receiver.receiver = CURRENT_acc AND email_receiver.email_ID = ID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `send_mail` (IN `p_subject` TEXT, IN `p_context` TEXT, IN `receiver1` VARCHAR(20), IN `receiver2` VARCHAR(20), IN `receiver3` VARCHAR(20), IN `cc_receiver1` VARCHAR(20), IN `cc_receiver2` VARCHAR(20), IN `cc_receiver3` VARCHAR(20), OUT `send_state` TEXT)  NO SQL
BEGIN
DECLARE CURRENT_acc varchar(20) DEFAULT'0';
DECLARE LAST_email INT DEFAULT 0;


SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));

create temporary table receivers
select account.username
from account
where account.username in (receiver1,receiver2,receiver3,cc_receiver1,cc_receiver2,cc_receiver3);
if (SELECT count(*) FROM receivers) = 0 THEN
SET send_state = "unknown receiver";
ELSE
INSERT INTO `email`( `subject`, `sent_time`, `context`) VALUES (p_subject,CURRENT_TIMESTAMP,p_context);
SET LAST_email=(SELECT MAX(email.email_ID) FROM email);
INSERT INTO `email_sender`(`email_ID`, `sender`, `is_read`, `is_deleted`) VALUES (LAST_email,CURRENT_acc,0,0);

INSERT into email_receiver
SELECT LAST_email,receivers.username,0,0,0
FROM receivers;
UPDATE email_receiver
SET is_cc = 1
WHERE email_receiver.email_ID = LAST_email and email_receiver.receiver in (cc_receiver1,cc_receiver2,cc_receiver3);

SET send_state = "email sent successfully";
END IF;
DROP TEMPORARY TABLE receivers;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sent_emails` (IN `page` INT, IN `item_per_page` INT)  NO SQL
BEGIN
DECLARE OFFSET_page INT DEFAULT 0;
DECLARE CURRENT_acc varchar(20) DEFAULT'0';

SET OFFSET_page = page*item_per_page;
SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));
SELECT
email.*,email_sender.sender,email_sender.is_read
FROM email,email_sender
WHERE email.email_ID = email_sender.email_ID and email_sender.is_deleted=0 AND email_sender.sender = CURRENT_acc
ORDER BY email.email_ID DESC
LIMIT OFFSET_page,item_per_page;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `show_received_emails` (IN `page` INT, IN `item_per_page` INT)  NO SQL
BEGIN
DECLARE OFFSET_page INT DEFAULT 0;
DECLARE CURRENT_acc varchar(20) DEFAULT'0';

SET OFFSET_page = page*item_per_page;
SET CURRENT_acc = (SELECT MAX(logged_in_users.username) FROM logged_in_users
    WHERE logged_in_users.time=(SELECT MAX(U.time) FROM logged_in_users U));
SELECT
email.*,email_receiver.receiver,email_receiver.is_cc,email_receiver.is_read
FROM email,email_receiver,email_sender
WHERE email.email_ID = email_sender.email_ID and email.email_ID=email_receiver.email_ID AND email_receiver.is_deleted=0 AND email_receiver.receiver = CURRENT_acc
ORDER BY email.email_ID DESC
LIMIT OFFSET_page,item_per_page;




END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sign_in` (IN `p_username` VARCHAR(20), IN `p_password` VARCHAR(20), IN `p_birthdate` TIMESTAMP, IN `p_phone_number` VARCHAR(20), IN `p_account_phone_number` VARCHAR(20), IN `p_address` TEXT, IN `p_first_name` VARCHAR(20), IN `p_last_name` VARCHAR(20), IN `p_nickname` VARCHAR(20), IN `p_personal_ID` VARCHAR(10), IN `access` INT(1), OUT `state` TEXT)  BEGIN
        IF CHAR_LENGTH(`p_username`) < 6 THEN
    SET
        `state` = "BAD USERNAME"; ELSEIF CHAR_LENGTH(`p_password`) < 6 THEN
    SET
        state = "BAD PASSWORD"; ELSE
    SET
        `p_password` = MD5(`p_password`);
    INSERT INTO `account`(
        `username`,
        `PASSWORD`,
        `create_time`,
        `birthdate`,
        `phone_number`,
        `account_phone_number`,
        `address`,
        `first_name`,
        `last_name`,
        `nickname`,
        `personal_ID`,
        `access_mode`
    )
VALUES(
    p_username,
    p_password,
    CURRENT_TIMESTAMP,
    p_birthdate,
    p_phone_number,
    p_account_phone_number,
    p_address,
    p_first_name,
    p_last_name,
    p_nickname,
    p_personal_ID,
    access
);
SET state = "SIGNED IN";
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_information` (IN `p_password` VARCHAR(20), IN `p_birthdate` TIMESTAMP, IN `p_phone_number` VARCHAR(20), IN `p_account_phone_number` VARCHAR(20), IN `p_address` TEXT, IN `p_first_name` VARCHAR(20), IN `p_last_name` VARCHAR(20), IN `p_nickname` VARCHAR(20), IN `p_personal_ID` VARCHAR(10), IN `p_access` INT, OUT `update_state` TEXT)  NO SQL
BEGIN
       IF CHAR_LENGTH(`p_password`) < 6 THEN
    SET
        update_state = "Bad password"; ELSE
    SET
        `p_password` = MD5(`p_password`);
    UPDATE `account`
    SET
    `password`=p_password,
    `birthdate`=p_birthdate,
    `phone_number` = p_phone_number,
    `account_phone_number`=p_account_phone_number,
    `address`=p_address,
    `first_name`=p_first_name,
    `last_name`=p_last_name,
    `nickname`=p_nickname,
    `personal_ID`=p_personal_ID,
    `access_mode`=p_access
    WHERE account.username IN (SELECT L.username FROM logged_in_users L WHERE L.time = (SELECT MAX(U.time) FROM logged_in_users U));
    SET update_state = "information updated";
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `accessing_exceptions`
--

CREATE TABLE `accessing_exceptions` (
  `from_user` varchar(20) NOT NULL,
  `to_user` varchar(20) NOT NULL,
  `permition` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `accessing_exceptions`
--

INSERT INTO `accessing_exceptions` (`from_user`, `to_user`, `permition`) VALUES
('Alireza', 'Usere2', 0),
('Alireza', 'usere3', 1),
('mohamad', 'Alireza', 1),
('Usere3', 'Alireza', 0);

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE `account` (
  `username` varchar(20) NOT NULL,
  `password` varchar(20) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `birthdate` timestamp NULL DEFAULT NULL,
  `phone_number` varchar(20) NOT NULL,
  `account_phone_number` varchar(20) NOT NULL,
  `address` text NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `nickname` varchar(20) NOT NULL,
  `personal_ID` varchar(10) NOT NULL,
  `access_mode` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `account`
--

INSERT INTO `account` (`username`, `password`, `create_time`, `birthdate`, `phone_number`, `account_phone_number`, `address`, `first_name`, `last_name`, `nickname`, `personal_ID`, `access_mode`) VALUES
('Alireza', 'ef73781effc5774100f8', '2020-05-25 15:07:32', '2038-01-18 23:44:07', '0011233', '12', 'add', 'ali', 'abed', 'az', '123123', 1),
('Amirali', 'e10adc3949ba59abbe56', '2020-06-22 12:00:13', '1999-12-12 08:42:12', '123', '412', 'address', 'amirali', 'amiri', 'alal', '123', 1),
('mohamad', 'e10adc3949ba59abbe56', '2020-05-29 22:27:24', '2008-01-18 23:44:07', '12312', '1111', 'addresse mamad', 'mohammad', 'mohammadi', 'mamd', '123222', 0),
('Usere2', 'e10adc3949ba59abbe56', '2020-05-29 12:47:20', '2018-01-18 23:44:07', '0203020', '123', 'addresssee', 'mamad', 'ahmadi', 'ma', '12312', 1),
('Usere3', 'e10adc3949ba59abbe56', '2020-05-29 12:48:02', '1999-12-12 09:43:13', '1231', '123', 'address', 'ali', 'ahmadi', 'all', '123', 1);

--
-- Triggers `account`
--
DELIMITER $$
CREATE TRIGGER `sign_in_notify` AFTER INSERT ON `account` FOR EACH ROW BEGIN
INSERT INTO notification VALUES(new.username,CURRENT_TIMESTAMP,"You have signed in successfully");


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_notify` AFTER UPDATE ON `account` FOR EACH ROW BEGIN
INSERT INTO notification
VALUES(new.username,CURRENT_TIMESTAMP,"Your information updated successfully");

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `email`
--

CREATE TABLE `email` (
  `email_ID` int(11) NOT NULL,
  `subject` text NOT NULL,
  `sent_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `context` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `email`
--

INSERT INTO `email` (`email_ID`, `subject`, `sent_time`, `context`) VALUES
(18, 'my new subject', '2020-05-29 19:38:56', 'second email'),
(19, 'my new subject', '2020-05-29 19:39:20', 'second email'),
(23, 'my fifth subject', '2020-05-29 20:55:05', 'fifth email'),
(24, 'my third subject', '2020-05-29 20:55:33', 'third email'),
(25, 'its new subject', '2020-06-06 17:49:03', 'email conteext'),
(26, 'python firs email', '2020-06-13 21:16:06', 'its first python email'),
(27, 'second python email', '2020-06-13 21:23:40', 'its second email added from python'),
(28, 'trigger test email', '2020-06-22 11:41:41', 'email context');

-- --------------------------------------------------------

--
-- Table structure for table `email_receiver`
--

CREATE TABLE `email_receiver` (
  `email_ID` int(11) NOT NULL,
  `receiver` varchar(20) NOT NULL,
  `is_read` int(1) NOT NULL,
  `is_cc` int(11) NOT NULL,
  `is_deleted` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `email_receiver`
--

INSERT INTO `email_receiver` (`email_ID`, `receiver`, `is_read`, `is_cc`, `is_deleted`) VALUES
(23, 'Alireza', 0, 0, 1),
(23, 'Usere3', 0, 1, 0),
(24, 'Usere3', 0, 0, 0),
(25, 'mohamad', 0, 0, 0),
(25, 'Usere2', 0, 0, 0),
(25, 'Usere3', 0, 1, 0),
(26, 'mohamad', 0, 0, 0),
(26, 'Usere3', 0, 1, 0),
(27, 'mohamad', 0, 1, 0),
(27, 'Usere2', 0, 1, 0),
(27, 'Usere3', 0, 0, 0),
(28, 'Alireza', 0, 0, 1),
(28, 'Usere2', 0, 1, 0);

--
-- Triggers `email_receiver`
--
DELIMITER $$
CREATE TRIGGER `email_received_notify` AFTER INSERT ON `email_receiver` FOR EACH ROW BEGIN

INSERT INTO notification
VALUES(new.receiver,CURRENT_TIMESTAMP,"You received a new email");

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `receiver_delete_email_notify` AFTER UPDATE ON `email_receiver` FOR EACH ROW BEGIN
IF new.is_deleted = 1 and old.is_deleted = 0
THEN
INSERT INTO notification VALUES(new.receiver,CURRENT_TIMESTAMP,"the email is deleted for you successfully as receiver");
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `email_sender`
--

CREATE TABLE `email_sender` (
  `email_ID` int(11) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `is_read` int(1) NOT NULL,
  `is_deleted` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `email_sender`
--

INSERT INTO `email_sender` (`email_ID`, `sender`, `is_read`, `is_deleted`) VALUES
(23, 'Alireza', 0, 1),
(24, 'Alireza', 1, 1),
(25, 'Alireza', 1, 1),
(26, 'Alireza', 0, 0),
(27, 'Alireza', 0, 1),
(28, 'Usere3', 0, 1);

--
-- Triggers `email_sender`
--
DELIMITER $$
CREATE TRIGGER `delete_email_notify` AFTER UPDATE ON `email_sender` FOR EACH ROW BEGIN
IF new.is_deleted = 1 and old.is_deleted = 0
THEN
INSERT INTO notification VALUES(new.sender,CURRENT_TIMESTAMP,"the email is deleted for you successfully as sender");
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `logged_in_users`
--

CREATE TABLE `logged_in_users` (
  `username` varchar(20) NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `logged_in_users`
--

INSERT INTO `logged_in_users` (`username`, `time`) VALUES
('Alireza', '2020-05-25 15:25:45'),
('Alireza', '2020-05-28 12:07:21'),
('Alireza', '2020-05-29 12:48:53'),
('usere2', '2020-05-29 14:08:37'),
('usere2', '2020-05-29 14:17:29'),
('Alireza', '2020-05-29 18:27:06'),
('Alireza', '2020-05-29 18:35:48'),
('Alireza', '2020-05-29 18:39:01'),
('Alireza', '2020-05-29 18:52:54'),
('mohamad', '2020-05-29 22:28:21'),
('Alireza', '2020-06-06 16:21:47'),
('Alireza', '2020-06-13 19:53:21'),
('Alireza', '2020-06-13 19:54:00'),
('Usere3', '2020-06-22 09:08:30'),
('alireza', '2020-06-22 11:29:46'),
('Usere3', '2020-06-22 11:32:31'),
('alireza', '2020-06-22 11:50:46'),
('amirali', '2020-06-22 12:00:29');

--
-- Triggers `logged_in_users`
--
DELIMITER $$
CREATE TRIGGER `login_notify` AFTER INSERT ON `logged_in_users` FOR EACH ROW BEGIN

INSERT INTO notification VALUES(new.username,CURRENT_TIMESTAMP,
                                "logged in successfully");

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notification`
--

CREATE TABLE `notification` (
  `username` varchar(20) NOT NULL,
  `creation_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `text` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `notification`
--

INSERT INTO `notification` (`username`, `creation_time`, `text`) VALUES
('Alireza', '2020-05-27 23:54:11', 'hey alireza'),
('Usere3', '2020-06-06 21:50:17', 'Alirezatried to get your personal information but he didnt have the permition'),
('Usere3', '2020-06-06 21:58:08', 'Alireza tried to get your personal information but he/she didnt have the permition'),
('Usere2', '2020-06-06 21:58:32', 'Alireza got access to your personal information'),
('mohamad', '2020-06-13 19:18:17', 'Alireza got access to your personal information'),
('alireza', '2020-06-22 11:29:46', 'logged in successfully'),
('Usere3', '2020-06-22 11:32:31', 'logged in successfully'),
('Usere3', '2020-06-22 11:33:15', 'Your information updated successfully'),
('Alireza', '2020-06-22 11:41:41', 'You received a new email'),
('Usere2', '2020-06-22 11:41:41', 'You received a new email'),
('Usere3', '2020-06-22 11:47:18', 'the email is deleted for you successfully'),
('alireza', '2020-06-22 11:50:46', 'logged in successfully'),
('Alireza', '2020-06-22 11:50:57', 'the email is deleted for you successfully as sender'),
('Alireza', '2020-06-22 11:54:13', 'the email is deleted for you successfully as receiver'),
('Amirali', '2020-06-22 12:00:13', 'You have signed in successfully'),
('amirali', '2020-06-22 12:00:29', 'logged in successfully');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accessing_exceptions`
--
ALTER TABLE `accessing_exceptions`
  ADD PRIMARY KEY (`from_user`,`to_user`),
  ADD KEY `to_user` (`to_user`);

--
-- Indexes for table `account`
--
ALTER TABLE `account`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `email`
--
ALTER TABLE `email`
  ADD PRIMARY KEY (`email_ID`),
  ADD KEY `sent_time` (`sent_time`);

--
-- Indexes for table `email_receiver`
--
ALTER TABLE `email_receiver`
  ADD PRIMARY KEY (`email_ID`,`receiver`),
  ADD KEY `receiver` (`receiver`),
  ADD KEY `email_ID` (`email_ID`,`receiver`);

--
-- Indexes for table `email_sender`
--
ALTER TABLE `email_sender`
  ADD PRIMARY KEY (`email_ID`),
  ADD KEY `sender` (`sender`);

--
-- Indexes for table `logged_in_users`
--
ALTER TABLE `logged_in_users`
  ADD KEY `logged_in_users_ibfk_1` (`username`);

--
-- Indexes for table `notification`
--
ALTER TABLE `notification`
  ADD KEY `notification_ibfk_1` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `email`
--
ALTER TABLE `email`
  MODIFY `email_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `accessing_exceptions`
--
ALTER TABLE `accessing_exceptions`
  ADD CONSTRAINT `accessing_exceptions_ibfk_1` FOREIGN KEY (`from_user`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `accessing_exceptions_ibfk_2` FOREIGN KEY (`to_user`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `email_receiver`
--
ALTER TABLE `email_receiver`
  ADD CONSTRAINT `email_receiver_ibfk_2` FOREIGN KEY (`receiver`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `email_receiver_ibfk_3` FOREIGN KEY (`email_ID`) REFERENCES `email` (`email_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `email_sender`
--
ALTER TABLE `email_sender`
  ADD CONSTRAINT `email_sender_ibfk_1` FOREIGN KEY (`email_ID`) REFERENCES `email` (`email_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `email_sender_ibfk_2` FOREIGN KEY (`sender`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `logged_in_users`
--
ALTER TABLE `logged_in_users`
  ADD CONSTRAINT `logged_in_users_ibfk_1` FOREIGN KEY (`username`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notification`
--
ALTER TABLE `notification`
  ADD CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`username`) REFERENCES `account` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
