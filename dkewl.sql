-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- 主机： localhost
-- 生成日期： 2024-03-19 22:57:23
-- 服务器版本： 5.6.50-log
-- PHP 版本： 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 数据库： `ceshi`
--

DELIMITER $$
--
-- 存储过程
--
CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `addBet` (`_uid` INT, `_amount` FLOAT, `_username` VARCHAR(16) CHARACTER SET utf8)   begin
	declare parentId1 int;      
	declare parentId2 int;      
	declare pname varchar(16) character set utf8;  



	declare CommissionBase float(10,2);                
	declare CommissionParentAmount float(10,2);        
	declare CommissionParentAmount2 float(10,2);       



	declare cur Decimal(12,4);
	declare _commisioned tinyint(1);
	select bet into cur from ssc_member_bet where uid=_uid and date=date_format(now(),'%Y%m%d');
	
	if cur is null THEN
		INSERT into ssc_member_bet(uid, username, date, bet, commisioned) values(_uid, _username, date_format(now(),'%Y%m%d'), _amount, 0);
	end if;
	if cur is not null THEN
		update ssc_member_bet set bet=bet+_amount where uid=_uid and date=date_format(now(),'%Y%m%d');
	end if;

	select bet into cur from ssc_member_bet where uid=_uid and date=date_format(now(),'%Y%m%d');
	select commisioned into _commisioned from ssc_member_bet where uid=_uid and date=date_format(now(),'%Y%m%d');
	select `value` into CommissionBase from ssc_params where name='conCommissionBase' limit 1;

	if cur >= CommissionBase and _commisioned=0 then
		select `value` into CommissionParentAmount from ssc_params where name='conCommissionParentAmount' limit 1;
		select `value` into CommissionParentAmount2 from ssc_params where name='conCommissionParentAmount2' limit 1;

		select `parentId` into parentId1 from ssc_members where uid=_uid;
		if parentId1 is not null and CommissionParentAmount>0 THEN
			call setCoin(CommissionParentAmount, 0, parentId1, 53, 0, concat('[', _username, ']消费佣金'), 0, '', '');
			select `parentId` into parentId2 from ssc_members where uid=parentId1;
			if parentId2 is not null and CommissionParentAmount2>0 THEN
				select `username` into pname from ssc_members where uid=parentId1;
				call setCoin(CommissionParentAmount2, 0, parentId2, 53, 0, concat('[', pname,'->', _username, ']消费佣金'), 0, '', '');
			end if;
			update ssc_member_bet set commisioned=1 where uid=_uid and date=date_format(now(),'%Y%m%d');
		end if;
	end if;
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `addRecharge` (`_uid` INT, `_username` VARCHAR(16) CHARACTER SET utf8)   begin
	declare parentId1 int;      
	declare parentId2 int;      
	declare pname varchar(16) character set utf8;  



	declare _rechargeCommissionAmount float(10,2);                
	declare _rechargeCommission float(10,2);        
	declare _rechargeCommission2 float(10,2);       



	declare _commisioned TINYINT(1);     

	declare cur float(10,2);
	select sum(amount) into cur from ssc_member_recharge where state!=0 and isDelete=0 and uid=_uid and actionTime BETWEEN UNIX_TIMESTAMP(DATE(NOW())) and UNIX_TIMESTAMP(NOW());
	
	select `value` into _rechargeCommissionAmount from ssc_params where name='rechargeCommissionAmount' limit 1;
	select rechargeCommisioned into _commisioned from ssc_member_bet where uid=_uid and date=date_format(now(),'%Y%m%d');

	if cur is not null and cur >=_rechargeCommissionAmount and _commisioned=0 THEN
		select `value` into _rechargeCommission from ssc_params where name='rechargeCommission' limit 1;
		select `value` into _rechargeCommission2 from ssc_params where name='rechargeCommission2' limit 1;

		select `parentId` into parentId1 from ssc_members where uid=_uid;
		if parentId1 is not null and _rechargeCommission>0 THEN
			call setCoin(_rechargeCommission, 0, parentId1, 53, 0, concat('[', _username, ']充值佣金'), 0, '', '');
			select `parentId` into parentId2 from ssc_members where uid=parentId1;
			if parentId2 is not null and _rechargeCommission2>0 THEN
				select `username` into pname from ssc_members where uid=parentId1;
				call setCoin(_rechargeCommission2, 0, parentId2, 53, 0, concat('[', pname,'->', _username, ']充值佣金'), 0, '', '');
			end if;
			update ssc_member_bet set rechargeCommisioned=1 where uid=_uid and date=date_format(now(),'%Y%m%d');
		end if;
	end if;
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `addScore` (`_uid` INT, `_amount` FLOAT)   begin
	
	declare bonus float;
	select `value` into bonus from ssc_params where name='scoreProp' limit 1;
	
	set bonus=bonus*_amount;
	
	if bonus then
		update ssc_members u, ssc_params p set u.score = u.score+bonus, u.scoreTotal=u.scoreTotal+bonus where u.`uid`=_uid;
	end if;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `auto_clearData` ()   begin

	declare endDate int;
	set endDate = UNIX_TIMESTAMP(now())-7*24*3600;

	
	delete from ssc_data where time < endDate;
	
	delete from ssc_member_session where accessTime < endDate;
	
	delete from ssc_bets where kjTime < endDate and lotteryNo <> '';
	

	delete from ssc_admin_log where actionTime < endDate;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `betcount` (`_date` INT(8), `_type` TINYINT(3), `_uid` INT(10))   begin
  
	declare _pri int(11) DEFAULT 0; 
	declare _betCount int(5) DEFAULT 0;
	declare _betAmount double(15,4) DEFAULT 0.0000;
	declare _betAmountb double(15,4) DEFAULT 0.0000;
	declare _zjAmount double(15,4) DEFAULT 0.0000;
	declare _rebateMoney double(15,4) DEFAULT 0.0000;
	declare _username VARCHAR(16) DEFAULT null;
	declare _gudongId int(10) DEFAULT 0; 
	declare _zparentId int(10) DEFAULT 0; 
	declare _parentId int(10) DEFAULT 0; 

	select uid into _uid from ssc_members where isDelete=0 and `uid`=_uid;
	if _uid then

	select id into _pri from ssc_count where `date`=_date and `uid`=_uid and `type`=_type  LIMIT 1;

	if _pri=0 or _pri is null THEN
		insert into ssc_count (`date`, `uid`, `type`) values(_date, _uid, _type);
		select id into _pri from ssc_count where date=_date and `uid`=_uid and `type`=_type LIMIT 1;
	end if;




	select count(*) into _betCount from ssc_bets where isDelete=0 and `uid`=_uid and `lotteryNo` !='' and `type` =_type and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;
	

	select sum(totalMoney) into _betAmount from ssc_bets where isDelete=0 and `uid` =_uid and `lotteryNo` !='' and `type` =_type and `betInfo` !='' and `totalNums` >1 and `totalMoney` >0 and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(money) into _betAmountb from ssc_bets where isDelete=0 and `uid` =_uid and `lotteryNo` !='' and `type` =_type and `totalNums` =1 and `totalMoney` =0 and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;


	select sum(bonus) into _zjAmount from ssc_bets where isDelete=0 and `uid` =_uid and `lotteryNo` !='' and `type` =_type and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(rebateMoney) into _rebateMoney from ssc_bets where isDelete=0 and `uid` =_uid and `lotteryNo` !='' and `type` =_type and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;
	

	select username into _username from ssc_members where isDelete=0 and `uid` =_uid;
	select gudongId into _gudongId from ssc_members where isDelete=0 and `uid` =_uid;
	select zparentId into _zparentId from ssc_members where isDelete=0 and `uid` =_uid;	
	select parentId into _parentId from ssc_members where isDelete=0 and `uid` =_uid;



	if _betCount is null THEN
		set _betCount = 0;
	end if;

	if _betAmount is null THEN
		set _betAmount = 0;
	end if;
	if _betAmountb is null THEN
		set _betAmountb = 0;
	end if;
	if _zjAmount is null THEN
		set _zjAmount = 0;
	end if;
	if _rebateMoney is null THEN
		set _rebateMoney = 0;
	end if;
	
	set _betAmount = _betAmount + _betAmountb;

	update ssc_count set betCount=_betCount, betAmount=_betAmount, zjAmount=_zjAmount, rebateMoney=_rebateMoney, username=_username, uid=_uid, gudongId=_gudongId, zparentId=_zparentId, parentId=_parentId where id=_pri;	

	end if;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `betreport` (`_date` INT(8), `_uid` INT(10))   begin
 
	declare _pri int(11) DEFAULT 0; 
	declare _betCount int(5) DEFAULT 0;
	declare _betAmount double(15,4) DEFAULT 0.0000;
	declare _betAmountb double(15,4) DEFAULT 0.0000;
	declare _zjAmount double(15,4) DEFAULT 0.0000;
	declare _rebateMoney double(15,4) DEFAULT 0.0000;
	declare _username VARCHAR(16) DEFAULT null;
	declare _gudongId int(10) DEFAULT 0; 
	declare _zparentId int(10) DEFAULT 0; 
	declare _parentId int(10) DEFAULT 0; 

	select uid into _uid from ssc_members where isDelete=0 and uid=_uid;
	if _uid then

	select id into _pri from ssc_report where date=_date and uid=_uid LIMIT 1;
	
	if _pri=0 or _pri is null THEN
		insert into ssc_report (date, uid) values(_date, _uid);
		select id into _pri from ssc_report where date=_date and uid=_uid LIMIT 1;
	end if;




	select count(*) into _betCount from ssc_bets where isDelete=0 and uid=_uid and lotteryNo!='' and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(totalMoney) into _betAmount from ssc_bets where isDelete=0 and uid=_uid and lotteryNo!='' and betInfo!='' and totalNums>1 and totalMoney>0 and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(money) into _betAmountb from ssc_bets where isDelete=0 and uid=_uid and lotteryNo!='' and totalNums=1 and totalMoney=0 and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(bonus) into _zjAmount from ssc_bets where isDelete=0 and uid=_uid and lotteryNo!='' and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;

	select sum(rebateMoney) into _rebateMoney from ssc_bets where isDelete=0 and uid=_uid and lotteryNo!='' and FROM_UNIXTIME(kjTime,'%Y%m%d') = _date;
	
	
	select username into _username from ssc_members where isDelete=0 and uid=_uid;
	select gudongId into _gudongId from ssc_members where isDelete=0 and uid=_uid;
	select zparentId into _zparentId from ssc_members where isDelete=0 and uid=_uid;	
	select parentId into _parentId from ssc_members where isDelete=0 and uid=_uid;



	if _betCount is null THEN
		set _betCount = 0;
	end if;

	if _betAmount is null THEN
		set _betAmount = 0;
	end if;
	if _betAmountb is null THEN
		set _betAmountb = 0;
	end if;
	if _zjAmount is null THEN
		set _zjAmount = 0;
	end if;
	if _rebateMoney is null THEN
		set _rebateMoney = 0;
	end if;
	
	set _betAmount = _betAmount + _betAmountb;

	update ssc_report set betCount=_betCount, betAmount=_betAmount, zjAmount=_zjAmount, rebateMoney=_rebateMoney, username=_username, uid=_uid, gudongId=_gudongId, zparentId=_zparentId, parentId=_parentId where id=_pri;
	end if;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `cancelBet` (`_zhuiHao` VARCHAR(255))   begin

	declare amount float;
	declare _uid int;
	declare _id int;
	declare _type int;
	
	declare info varchar(255) character set utf8;
	declare liqType int default 5;
	
	declare done int default 0;
	declare cur cursor for
	select id, money, `uid`, `type` from ssc_bets where serializeId=_zhuiHao and lotteryNo='' and isDelete=0;
	declare continue HANDLER for not found set done=1;
	
	open cur;
		repeat
			fetch cur into _id, amount, _uid, _type;
			if not done then
				update ssc_bets set isDelete=1 where id=_id;
				set info='追号撤单';
				call setCoin(amount, 0, _uid, liqType, _type, info, _id, '', '');
			end if;
		until done end repeat;
	close cur;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	

	
	delete from ssc_bets where kjTime < endDate and lotteryNo <> '';
	
	delete from ssc_coin_log where actionTime < endDate;
	
	delete from ssc_admin_log where actionTime < endDate;
	
	delete from ssc_member_session where accessTime < endDate;
	
	delete from ssc_member_cash where actionTime < endDate and state <> 1;
	
	delete from ssc_member_recharge where actionTime < endDate and state <> 0;
	delete from ssc_member_recharge where actionTime < endDate-24*3600 and state = 0;
		
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData2` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;

	
	delete from ssc_data where time < endDate;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData3` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	
	
	delete from ssc_coin_log where actionTime < endDate;
		
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData4` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	
	

	delete from ssc_admin_log where actionTime < endDate;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData5` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	
	
	delete from ssc_member_session where accessTime < endDate;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData6` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	
	
	delete from ssc_member_cash where actionTime < endDate and state <> 1;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `clearData7` (`dateInt` INT(11))   begin

	declare endDate int;
	set endDate = dateInt;
	
	

	delete from ssc_member_recharge where actionTime < endDate and state <> 0;
	delete from ssc_member_recharge where actionTime < endDate-24*3600 and state = 0;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `conComAll` (`baseAmount` FLOAT, `parentAmount` FLOAT, `parentLevel` INT)   begin

	declare conUid int;
	declare conUserName varchar(255);
	declare tjAmount float;
	declare done int default 0;	
	declare dateTime int default unix_timestamp(curdate());

	declare cur cursor for
	select b.uid, b.username, sum(b.`mode` * b.actionNum * b.beiShu) _tjAmount from ssc_bets b where b.kjTime>=dateTime and b.uid not in(select distinct l.extfield0 from ssc_coin_log l where l.liqType=53 and l.actionTime>=dateTime and l.extfield2=parentLevel) group by b.uid having _tjAmount>=baseAmount;
	declare continue HANDLER for not found set done=1;

	
	
	open cur;
		repeat fetch cur into conUid, conUserName, tjAmount;
		
		if not done then
			call conComSingle(conUid, parentAmount, parentLevel);
		end if;
		until done end repeat;
	close cur;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `conComSingle` (`conUid` INT, `parentAmount` FLOAT, `parentLevel` INT)   begin

	declare parentId int;
	declare superParentId int;
	declare conUserName varchar(255) character set utf8;
	declare p_username varchar(255) character set utf8;

	declare liqType int default 53;
	declare info varchar(255) character set utf8;

	declare done int default 0;
	declare cur cursor for
	select p.uid, p.parentId, p.username, u.username from ssc_members p, ssc_members u where u.parentId=p.uid and u.`uid`=conUid; 
	declare continue HANDLER for not found set done=1;

	open cur;
		repeat fetch cur into parentId, superParentId, p_username, conUserName;
		
		if not done then
			if parentLevel=1 then
				if parentId and parentAmount then
					set info=concat('下级[', conUserName, ']消费佣金');
					call setCoin(parentAmount, 0, parentId, liqType, 0, info, conUid, conUserName, parentLevel);
				end if;
			end if;
			
			if parentLevel=2 then
				if superParentId and parentAmount then
					set info=concat('下级[', conUserName, '<=', p_username, ']消费佣金');
					call setCoin(parentAmount, 0, superParentId, liqType, 0, info, conUid, conUserName, parentLevel);
				end if;
			end if;
		end if;
		until done end repeat;
	close cur;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `consumptionCommission` ()   begin

	declare baseAmount float;
	declare baseAmount2 float;
	declare parentAmount float;
	declare superParentAmount float;

	call readConComSet(baseAmount, baseAmount2, parentAmount, superParentAmount);
	

	if baseAmount>0 then
		call conComAll(baseAmount, parentAmount, 1);
	end if;
	if baseAmount2>0 then
		call conComAll(baseAmount2, superParentAmount, 2);
	end if;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `delUser` (`_uid` INT)   begin
	
	delete from ssc_bets where `uid`=_uid;
	
	delete from ssc_coin_log where `uid`=_uid;
	
	delete from ssc_admin_log where `uid`=_uid;
	
	delete from ssc_member_session where `uid`=_uid;
	
	delete from ssc_member_cash where `uid`=_uid;
	
	delete from ssc_member_recharge where `uid`=_uid;
	
	delete from ssc_member_bank where `uid`=_uid;
	
	delete from ssc_members where `uid`=_uid;
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `delUser2` (`_uid` INT)   begin
	
	delete from ssc_bets where `uid`=_uid;
	
	delete from ssc_coin_log where `uid`=_uid;
	

	delete from ssc_admin_log where `uid`=_uid;
	
	delete from ssc_member_session where `uid`=_uid;
	
	delete from ssc_member_cash where `uid`=_uid;
	

	delete from ssc_member_recharge where `uid`=_uid;
	
	delete from ssc_member_bank where `uid`=_uid;
	
	delete from ssc_members where `uid`=_uid;
	
	delete from ssc_links where `uid`=_uid;
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `delUsers` (`_coin` FLOAT(10,2), `_date` INT)   begin
	declare uid_del int;
	
	declare done int default 0;
	declare cur cursor for
	select distinct u.uid from ssc_members u, ssc_member_session s where u.uid=s.uid and (u.coin+u.fcoin)<_coin and s.accessTime<_date and not exists(select u1.`uid` from ssc_members u1 where u1.parentId=u.`uid`)
union 
select distinct u2.uid from ssc_members u2 where (u2.coin+u2.fcoin)<_coin and u2.regTime<_date and not exists (select s1.uid from ssc_member_session s1 where s1.uid=u2.uid);
	declare continue HANDLER for not found set done = 1;

	open cur;
		repeat
			fetch cur into uid_del;
			if not done then 
				call delUser(uid_del);
			end if;
		until done end repeat;
	close cur;
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `getQzInfo` (`_uid` INT, INOUT `_fanDian` FLOAT, INOUT `_parentId` INT)   begin

	declare done int default 0;
	declare cur cursor for
	select fanDian, parentId from ssc_members where `uid`=_uid;
	declare continue HANDLER for not found set done = 1;

	open cur;
		fetch cur into _fanDian, _parentId;
	close cur;
	
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `guestclear` ()   begin

	declare endDate int;
	set endDate = UNIX_TIMESTAMP(now())-1*24*3600;

	
	delete from ssc_member_session where accessTime < endDate and username like 'guest_%';
	
	delete from ssc_guestbets where kjTime < endDate;
	
	delete from ssc_guestcoin_log where actionTime < endDate;
	
	delete from ssc_guestmembers where regTime < endDate;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `guestkanJiang` (`_betId` INT, `_zjCount` INT, `_kjData` VARCHAR(255) CHARACTER SET utf8, `_kset` VARCHAR(255) CHARACTER SET utf8)   begin
	
	declare `uid` int;									
	declare userid int;
	declare parentId int;								
	declare zparentId int;
	declare gudongId int;
	declare username varchar(32) character set utf8;	

	

	
	declare serializeId varchar(64);
	declare actionData longtext character set utf8;
	declare actionNo varchar(255);
	declare `type` int;
	declare playedId int;
	
	declare isDelete int;
	declare odds float;     
	declare _rebate float default 0;
	declare _rebatemoney float default 0;
	declare fanDian float;		
	
	declare amount float;					
	declare zjAmount float default 0;		
	declare _fanDianAmount float default 0;	

	
	declare liqType int;
	declare info varchar(255) character set utf8;
	
	declare _parentId int;		

	declare _zparentId int;		

	declare _gudongId int;		

	declare _fanDian float;		
	
	declare totalnums SMALLINT default 0;
	declare totalmoney float default 0;
	declare betinfo varchar(64) character set utf8;
	declare Groupname varchar(32) character set utf8;
	
	declare _kjTime int(11) DEFAULT 0;
	
	declare done int default 0;
	declare cur cursor for
	select b.`uid`, u.parentId, u.zparentId, u.gudongId, u.username, b.serializeId, b.actionData, b.actionNo, FROM_UNIXTIME(b.kjTime,'%Y%m%d') _kjTime, b.`type`, b.playedId, b.isDelete, b.fanDian, u.fanDian, b.odds, b.rebate, b.money, b.totalNums, b.totalMoney, b.betInfo, b.Groupname  from ssc_guestbets b, ssc_guestmembers u where b.`uid`=u.`uid` and b.id=_betId;
	declare continue handler for sqlstate '02000' set done = 1;
	
	open cur;
		repeat
			fetch cur into `uid`, parentId, zparentId, gudongId, username, serializeId, actionData, actionNo, _kjTime, `type`, playedId, isDelete, fanDian, _fanDian, odds, _rebate, amount, totalnums, totalmoney, betinfo, Groupname;
		until done end repeat;
	close cur;
	

	start transaction;
	if md5(_kset)='47df5dd3fc251a6115761119c90b964a' then
	
		

		if isDelete=0 then
		
			set userid=`uid`;
			
			set _parentId=parentId;
			set _zparentId=zparentId;
			set _gudongId=gudongId;
			
			set fanDian=_fanDian;
			
			
			if _zjCount then
				
				
				set liqType=6;
				set info='中奖奖金';
				if _zjCount = -1 then
					if totalnums>1 and totalmoney>0 and betinfo<>'' then
						set amount=totalmoney;
					end if;
					set zjAmount= amount; 

				elseif Groupname='三军' then
					set zjAmount= amount * odds + amount * (_zjCount - 1); 
				else
					set zjAmount= _zjCount * amount * odds; 
				end if;
				call guestsetCoin(zjAmount, 0, `uid`, liqType, `type`, info, _betId, serializeId, '');
				
			end if;	
	
			if _zjCount = -1 then
				set _zjCount = 0;
			end if;				
			

			if totalnums>1 and totalmoney>0 and betinfo<>'' then
				set amount=totalmoney;
			end if;

			

			if _rebate>0 and  _rebate<0.5 THEN
			set liqType=105;
			set info='退水资金';
			set _rebatemoney = amount * _rebate;
			call guestsetCoin(_rebatemoney, 0, `uid`, liqType, `type`, info, _betId, serializeId, '');
			end if;

			update ssc_guestbets set lotteryNo=_kjData, zjCount=_zjCount, bonus=zjAmount, rebateMoney=_rebatemoney where id=_betId;

			if CONVERT(DATE_FORMAT(now(),'%H%i'), SIGNED)>=100 and CONVERT(DATE_FORMAT(now(),'%H%i'), SIGNED)<105 then
			call guestclear();
			end if;
		end if;
	end if;
	
	commit;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `guestsetCoin` (`_coin` FLOAT, `_fcoin` FLOAT, `_uid` INT, `_liqType` INT, `_type` INT, `_info` VARCHAR(255) CHARACTER SET utf8, `_extfield0` INT, `_extfield1` VARCHAR(255) CHARACTER SET utf8, `_extfield2` VARCHAR(255) CHARACTER SET utf8)   begin
	
	
	DECLARE currentTime INT DEFAULT UNIX_TIMESTAMP();
	DECLARE _userCoin FLOAT;
	DECLARE _count INT  DEFAULT 0;
	
	IF _coin IS NULL THEN
		SET _coin=0;
	END IF;
	IF _fcoin IS NULL THEN
		SET _fcoin=0;
	END IF;
	

	SELECT COUNT(1) INTO _count FROM ssc_guestcoin_log WHERE  extfield0=_extfield0  AND info='中奖奖金'  AND `uid`=_uid;
	IF  _count<1 THEN
	UPDATE ssc_guestmembers SET coin = coin + _coin, fcoin = fcoin + _fcoin WHERE `uid` = _uid;
	SELECT coin INTO _userCoin FROM ssc_guestmembers WHERE `uid`=_uid;
	
	INSERT INTO ssc_guestcoin_log(coin, fcoin, userCoin, `uid`, actionTime, liqType, `type`, info, extfield0, extfield1, extfield2) VALUES(_coin, _fcoin, _userCoin, _uid, currentTime, _liqType, _type, _info, _extfield0, _extfield1, _extfield2);
	END IF;
	

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `isFirstRechargeCom` (`_uid` INT, OUT `flag` INT)   begin
	
	declare dateTime int default unix_timestamp(curdate());
	select id into flag from ssc_member_recharge where rechargeTime>dateTime and `uid`=_uid;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `kanJiang` (`_betId` INT, `_zjCount` INT, `_kjData` VARCHAR(255) CHARACTER SET utf8, `_kset` VARCHAR(255) CHARACTER SET utf8)   begin
	
	declare `uid` int;									
	declare qz_uid int;									
	declare qz_username varchar(32) character set utf8;	
	declare qz_fcoin varchar(32);						
	
	declare parentId int;								
	declare username varchar(32) character set utf8;	
	
	
	declare actionNum int;
	declare serializeId varchar(64);
	declare actionData longtext character set utf8;
	declare actionNo varchar(255);
	declare `type` int;
	declare playedId int;
	
	declare isDelete int;
	
	declare fanDian float;		
	declare `mode` float;		
	declare beiShu int;			
	declare zhuiHao int;		
	declare zhuiHaoMode int;	
	declare bonusProp float;	
	
	declare amount float;					
	declare zjAmount float default 0;		
	declare _fanDianAmount float default 0;	
	declare chouShuiAmount float default 0;	
	
	declare liqType int;
	declare info varchar(255) character set utf8;
	
	declare _parentId int;		
	declare _fanDian float;		
	declare qz_fanDian float;	

	
	declare done int default 0;
	declare cur cursor for
	select b.`uid`, u.parentId, u.username, b.qz_uid, b.qz_username, b.qz_fcoin, b.actionNum, b.serializeId, b.actionData, b.actionNo, b.`type`, b.playedId, b.isDelete, b.fanDian, u.fanDian, b.`mode`, b.beiShu, b.zhuiHao, b.zhuiHaoMode, b.bonusProp, b.actionNum*b.`mode`*b.beiShu amount from ssc_bets b, ssc_members u where b.`uid`=u.`uid` and b.id=_betId;
	declare continue handler for sqlstate '02000' set done = 1;
	
	open cur;
		repeat
			fetch cur into `uid`, parentId, username, qz_uid, qz_username, qz_fcoin, actionNum, serializeId, actionData, actionNo, `type`, playedId, isDelete, fanDian, _fanDian, `mode`, beiShu, zhuiHao, zhuiHaoMode, bonusProp, amount;
		until done end repeat;
	close cur;
	
	

	
	start transaction;
	if md5(_kset)='47df5dd3fc251a6115761119c90b964a' then
		
		
		if isDelete=0 then
			
			
			
			
			
			
			
			call addScore(`uid`, amount);
		
			
			
			if fanDian then
				set liqType=2;
				set info='返点';
				set _fanDianAmount=amount * fanDian/100;
				call setCoin(_fanDianAmount, 0, `uid`, liqType, `type`, info, _betId, '', '');
			end if;
			
			
			set _parentId=parentId;
			
			set fanDian=_fanDian;
			
			while _parentId do
				call setUpFanDian(amount, _fanDian, _parentId, `type`, _betId, `uid`, username);
			end while;
			set _fanDianAmount = _fanDianAmount + amount * ( _fanDian - fanDian)/100;
			
			
			
			if qz_uid then
				
				
				call getQzInfo(qz_uid, _fanDian, _parentId);
				
				set qz_fanDian=_fanDian;
				
				while _parentId do
					call setUpChouShui(amount, _fanDian, _parentId, `type`, _betId, qz_uid, qz_username);
					
				end while;
				
				
				set chouShuiAmount=amount * ( _fanDian - qz_fanDian + 3) / 100;
				
			end if;
			
			
			
			
			
			if _zjCount then
				
				
				set liqType=6;
				set info='中奖奖金';
				set zjAmount=bonusProp * _zjCount * beiShu * `mode`/2;
				call setCoin(zjAmount, 0, `uid`, liqType, `type`, info, _betId, '', '');
	
			end if;
			
			
			update ssc_bets set lotteryNo=_kjData, zjCount=_zjCount, bonus=zjAmount, fanDianAmount=_fanDianAmount, qz_chouShui=chouShuiAmount where id=_betId;

			
			if _zjCount and zhuiHao=1 and zhuiHaoMode=1 then
				
				
				
				call cancelBet(serializeId);
			end if;
			
			
			if qz_uid then
				set liqType=10;
				set info='解冻抢庄冻结资金';
				call setCoin(qz_fcoin, - qz_fcoin, qz_uid, liqType, `type`, info, _betId, '', '');
				
				set liqType=11;
				set info='收单';
				call setCoin(amount, 0, qz_uid, liqType, `type`, info, _betId, '', '');
				
				if _fanDianAmount then
					set liqType=103;
					set info='支付返点';
					call setCoin(-_fanDianAmount, 0, qz_uid, liqType, `type`, info, _betId, '', '');
				end if;
				
				if chouShuiAmount then
					set liqType=104;
					set info='支付抽水';
					call setCoin(-chouShuiAmount, 0, qz_uid, liqType, `type`, info, _betId, '', '');
				end if;
				
				if zjAmount then
					set liqType=105;
					set info='赔付中奖金额';
					call setCoin(-zjAmount, 0, qz_uid, liqType, `type`, info, _betId, '', '');
				end if;
	
			end if;

		end if;
	end if;

	
	commit;
	
end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `paid` (IN `_item` INT, IN `_type` INT)   begin
update g_crowd_record_28 set paidtask=paidtask+1,paidtype=_type where crowdid=_item and status=0;

end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `paid_details` (IN `_item` INT, IN `_type` INT)   BEGIN

declare _title,_msg,_tmptitle,_editor,_user VARCHAR(800);
declare _valid,done,num,_now,_vid,_cid int(10) default 0;
declare _amt,_amount,_earnratio,_profit,_share,_pay,_target,_selfbuy double(10,2) default 0;

select crowder,amount,cid into _user,_amount,_cid from g_crowd_record_28 where itemid=_item;

select vid,share,buyerpay,target,selfbuy,title into _vid,_share,_pay,_target, _selfbuy,_tmptitle from g_crowd_28 where itemid=_cid;
set _profit=(_pay-_target)*_share/100;
set _editor='system';
set _amt=_amount;

if _type=1 then
    set _amount=(_amt/_target)*_profit+_amt; 
    set _earnratio=(_amount-_amt)*100/_amt; 
else
    
    
    set _earnratio=_selfbuy; 
    set _amount=_amt*(1+_selfbuy/100); 
end if;
if _amount>0 then

    UPDATE g_member SET money=money+_amount,message=message+1 WHERE username=_user;
    select money into _now from g_member where  username=_user;
    INSERT INTO g_finance_record (username,bank,amount,balance,addtime,reason,note,editor,mid,item_id) 
        VALUES (_user,'平台账户获得',_amount,_now,UNIX_TIMESTAMP(now()),'项目回款','','admin',28,_item);
    set _title=concat('项目回款收益-',_tmptitle);
    set _msg=concat(concat('您参与的项目-',_tmptitle,'-已回款，获得收益'),_amount,'元');
    insert into g_message(title,typeid,content,touser,addtime,status) values(_title,4,_msg,_user,UNIX_TIMESTAMP(now()),3);
    insert into g_crowd_share(title,msg,cid,vid,addtime,username,deposit,ratio,earn,earnratio) 
                values(_title,_msg,_item,_vid,UNIX_TIMESTAMP(now()),_user,_amt,_amt/_target,_amount,_earnratio);
end if;
END$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `paid_old` (IN `_item` INT, IN `_type` INT)   BEGIN

declare _title,_msg,_tmptitle,_editor,_user VARCHAR(800);
declare _valid,done,num,_now,_vid,_cid int(10) default 0;
declare _amt,_amount,_earnratio,_profit,_share,_pay,_target,_selfbuy double(10,2) default 0;

declare members cursor for select crowder,sum(amount)as amount from g_crowd_record_28 where crowdid=_item and status=0 GROUP BY crowder;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

select vid,share,buyerpay,target,selfbuy,title into _vid,_share,_pay,_target, _selfbuy,_tmptitle from g_crowd_28 where itemid=_item;
select count(DISTINCT(crowder)),cid into _valid,_cid  from g_crowd_record_28 where crowdid=_item and status=0;
set _profit=(_pay-_target)*_share/100;
set _editor='system';


open members;
REPEAT
    FETCH members into _user,_amt;
    set num=num+1;

    if _type=1 then
    set _amount=(_amt/_target)*_profit+_amt; 
    set _earnratio=(_amount-_amt)*100/_amt; 
    else
    
    
    set _earnratio=_selfbuy; 
    set _amount=_amt*(1+_selfbuy/100); 
    end if;
    if num<=_valid and _amount>0 then

    UPDATE g_member SET money=money+_amt,message=message+1 WHERE username=_user;
    select money into _now from g_member where  username=_user;
    INSERT INTO g_finance_record (username,bank,amount,balance,addtime,reason,note,editor,mid,item_id) 
        VALUES (_user,'平台账户获得',_amount,_now,UNIX_TIMESTAMP(now()),'项目回款','','admin',28,_item);
    set _title=concat('项目回款收益-',_tmptitle);
    set _msg=concat(concat('您参与的项目-',_tmptitle,'-已回款，获得收益'),_amount,'元');
    insert into g_message(title,typeid,content,touser,addtime,status) values(_title,4,_msg,_user,UNIX_TIMESTAMP(now()),3);
    insert into g_crowd_share(title,msg,cid,vid,addtime,username,deposit,ratio,earn,earnratio) 
                values(_title,_msg,_item,_vid,UNIX_TIMESTAMP(now()),_user,_amt,_amt/_target,_amount,_earnratio);
    end if;

UNTIL done END REPEAT;
close members;
update g_crowd_28 set typeid=5 where itemid=_cid;
END$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `pro_count` (`_date` VARCHAR(20))   begin
	
	declare fromTime int;
	declare toTime int;
	
	if not _date then
		set _date=date_add(curdate(), interval -1 day);
	end if;
	
	set toTime=unix_timestamp(_date);
	set fromTime=toTime-24*3600;
	
	insert into ssc_count(`type`, playedId, `date`, betCount, betAmount, zjAmount)
	select `type`, playedId, _date, sum(money), sum(bonus) from ssc_bets where kjTime between fromTime and toTime and isDelete=0 group by type, playedId
	on duplicate key update betCount=values(betCount), betAmount=values(betAmount), zjAmount=values(zjAmount);


end$$

CREATE DEFINER=`ceshi`@`localhost` PROCEDURE `pro_pay` ()   begin

	declare _m_id int;					
	declare _addmoney float(10,2);		

	declare _h_fee float(10,2);		

	declare _rechargeTime varchar(20);	

	declare _rechargeId varchar(64);		

	declare _info varchar(64) character set utf8;	
	
	declare _uid int;
	declare _coin float;
	declare _fcoin float;
	
	declare _r_id int;
	declare _amount float;
	
	declare currentTime int default unix_timestamp();
	declare _liqType int default 1;
	declare info varchar(64) character set utf8 default '自动到账';
	declare done int default 0;
	
	declare isFirstRecharge int;
	
	declare cur cursor for
	select m.id, m.addmoney, m.h_fee, m.o_time, m.u_id, m.memo,		u.`uid`, u.coin, u.fcoin,		r.id, r.amount from ssc_members u, my18_pay m, ssc_member_recharge r where u.`uid`=r.`uid` and r.rechargeId=m.u_id and m.`state`=0 and r.`state`=0 and r.isDelete=0;
	declare continue HANDLER for not found set done = 1;

	start transaction;
		open cur;
			repeat
				fetch cur into _m_id, _addmoney, _h_fee, _rechargeTime, _rechargeId, _info, _uid, _coin, _fcoin, _r_id, _amount;
				
				if not done then
					
					
						call setCoin(_addmoney, 0, _uid, _liqType, 0, info, _r_id, _rechargeId, '');
						if _h_fee>0 then
							call setCoin(_h_fee, 0, _uid, _liqType, 0, '充值手续费', _r_id, _rechargeId, '');
						end if;
						update ssc_member_recharge set rechargeAmount=_addmoney+_h_fee, coin=_coin, fcoin=_fcoin, rechargeTime=currentTime, `state`=2, `info`=info where id=_r_id;
						update my18_pay set `state`=1 where id=_m_id;
						
						

						call isFirstRechargeCom(_uid, isFirstRecharge);
						if isFirstRecharge then
							call setRechargeCom(_addmoney, _uid, _r_id, _rechargeId);
						end if;
					
						
					
				end if;
				
			until done end repeat;
		close cur;
	commit;
	
	
end$$

DELIMITER ;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_chat`
--

CREATE TABLE `ocink_chat` (
  `id` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `qq` varchar(225) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `time` varchar(225) NOT NULL,
  `sendtime` datetime NOT NULL,
  `sendip` varchar(225) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_configs`
--

CREATE TABLE `ocink_configs` (
  `k` varchar(255) NOT NULL DEFAULT '',
  `v` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_configs`
--

INSERT INTO `ocink_configs` (`k`, `v`) VALUES
('webname', '刀客源码网音乐播放器'),
('title', '免费稳定的HTML悬浮播放器'),
('keywords', '刀客源码网音乐播放器,HTML5悬浮音乐播放器,网页音乐播放器,JQ音乐播放器'),
('description', '刀客源码网音乐播放器,HTML5悬浮音乐播放器,网页音乐播放器,JQ音乐播放器'),
('regpie', '1'),
('piemoney', '1'),
('vipmoney', '1'),
('epay_url', 'https://pay.aiyqq.cn/'),
('epay_id', ''),
('epay_key', '');

-- --------------------------------------------------------

--
-- 表的结构 `ocink_links`
--

CREATE TABLE `ocink_links` (
  `id` int(11) NOT NULL,
  `title` varchar(255) DEFAULT NULL COMMENT '网站标题',
  `url` text COMMENT '网站链接'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_order`
--

CREATE TABLE `ocink_order` (
  `trade_no` varchar(64) NOT NULL,
  `type` varchar(20) DEFAULT NULL,
  `orderid` varchar(64) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  `money` decimal(10,2) NOT NULL DEFAULT '0.00',
  `status` int(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_pays`
--

CREATE TABLE `ocink_pays` (
  `id` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `qq` char(20) DEFAULT NULL,
  `orderid` char(64) DEFAULT NULL,
  `addtime` datetime DEFAULT NULL,
  `endtime` datetime DEFAULT NULL,
  `name` char(64) DEFAULT NULL,
  `money` decimal(6,2) NOT NULL DEFAULT '0.00',
  `type` varchar(10) DEFAULT NULL,
  `shop` varchar(225) DEFAULT NULL,
  `shopid` int(11) NOT NULL DEFAULT '0',
  `status` tinyint(3) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_player`
--

CREATE TABLE `ocink_player` (
  `id` varchar(100) DEFAULT NULL,
  `name` varchar(30) DEFAULT NULL COMMENT '播放器名称',
  `user_id` varchar(32) DEFAULT NULL COMMENT '关联用户id',
  `auto_player` int(1) DEFAULT '0' COMMENT '是否自动播放',
  `phone_load` int(1) DEFAULT '0' COMMENT '手机端加载播放器',
  `random_player` int(1) DEFAULT '0' COMMENT '是否随机播放',
  `default_volume` int(3) DEFAULT '75' COMMENT '默认音量',
  `show_lrc` int(1) DEFAULT '1' COMMENT '是否显示歌词',
  `greeting` varchar(30) DEFAULT NULL COMMENT '欢迎语',
  `show_greeting` int(1) DEFAULT '1' COMMENT '是否显示欢迎语',
  `default_album` int(3) DEFAULT '1' COMMENT '默认专辑',
  `background` int(1) DEFAULT '1' COMMENT '模糊背景是否开启',
  `show_notes` int(1) DEFAULT '1' COMMENT '显示音符：0不显示1显示',
  `time` int(11) DEFAULT '1' COMMENT '几秒后弹出播放器',
  `switchopen` int(11) DEFAULT '1' COMMENT '是否弹出播放器',
  `showmsg` int(11) DEFAULT '0' COMMENT '桌面通知开关',
  `voice_msg` varchar(255) DEFAULT '你的域名没有通过授权,无法播放音乐' COMMENT '防盗提示语音文字',
  `plays` varchar(32) DEFAULT NULL COMMENT '总播放次数',
  `endtime` datetime NOT NULL COMMENT '最后播放时间',
  `theme` int(11) DEFAULT '1' COMMENT '播放器皮肤',
  `create_time` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_player`
--

INSERT INTO `ocink_player` (`id`, `name`, `user_id`, `auto_player`, `phone_load`, `random_player`, `default_volume`, `show_lrc`, `greeting`, `show_greeting`, `default_album`, `background`, `show_notes`, `time`, `switchopen`, `showmsg`, `voice_msg`, `plays`, `endtime`, `theme`, `create_time`) VALUES
('64dc3ad87f754', '刀客源码网', '1', 0, 0, 0, 75, 1, '', 1, 1, 1, 1, 1, 1, 0, '你的域名没有通过授权,无法播放音乐', '11', '2024-03-19 22:51:32', 5, '2023-08-16 10:56:24');

-- --------------------------------------------------------

--
-- 表的结构 `ocink_player_auth`
--

CREATE TABLE `ocink_player_auth` (
  `player_id` varchar(32) DEFAULT NULL COMMENT '播放器id',
  `domain` varchar(32) DEFAULT NULL COMMENT '授权域名',
  `remark` varchar(32) DEFAULT NULL COMMENT '网站备注'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- 表的结构 `ocink_player_song_sheet`
--

CREATE TABLE `ocink_player_song_sheet` (
  `player_id` varchar(32) DEFAULT NULL COMMENT '播放器id',
  `song_sheet_id` varchar(32) DEFAULT NULL COMMENT '歌单id',
  `taxis` int(3) DEFAULT NULL COMMENT '排序'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_player_song_sheet`
--

INSERT INTO `ocink_player_song_sheet` (`player_id`, `song_sheet_id`, `taxis`) VALUES
('64dc3ad87f754', '64dc3a94560e6', 0);

-- --------------------------------------------------------

--
-- 表的结构 `ocink_plays`
--

CREATE TABLE `ocink_plays` (
  `id` varchar(100) DEFAULT NULL,
  `player_id` varchar(32) DEFAULT NULL COMMENT '播放器id',
  `user_id` varchar(32) DEFAULT NULL COMMENT '关联用户id',
  `side` varchar(32) DEFAULT NULL COMMENT '播放客户端',
  `create_time` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_plays`
--

INSERT INTO `ocink_plays` (`id`, `player_id`, `user_id`, `side`, `create_time`) VALUES
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 10:56:48'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 10:58:25'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:16:18'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:22:21'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:23:57'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:24:13'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:27:15'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:36:10'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:36:50'),
(NULL, '64dc3ad87f754', '1', 'ios', '2023-08-16 11:40:33'),
(NULL, '64dc3ad87f754', '1', 'ios', '2024-03-19 22:51:32');

-- --------------------------------------------------------

--
-- 表的结构 `ocink_song`
--

CREATE TABLE `ocink_song` (
  `id` varchar(100) DEFAULT NULL,
  `song_id` varchar(32) DEFAULT NULL COMMENT '歌曲id',
  `song_sheet_id` varchar(32) DEFAULT NULL COMMENT '所属歌单',
  `name` varchar(100) DEFAULT NULL COMMENT '歌曲名称',
  `type` varchar(10) DEFAULT NULL COMMENT '歌曲类型',
  `album_name` varchar(100) DEFAULT NULL COMMENT '专辑名称',
  `artist_name` varchar(100) DEFAULT NULL COMMENT '歌手名称',
  `album_cover` varchar(100) DEFAULT NULL COMMENT '专辑图片',
  `location` varchar(150) DEFAULT NULL COMMENT '歌曲地址',
  `lyric` varchar(100) DEFAULT NULL COMMENT '歌词地址',
  `taxis` int(3) DEFAULT NULL COMMENT '排序'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_song`
--

INSERT INTO `ocink_song` (`id`, `song_id`, `song_sheet_id`, `name`, `type`, `album_name`, `artist_name`, `album_cover`, `location`, `lyric`, `taxis`) VALUES
('64dc4021de233', '1893376364', '64dc3a94560e6', '偏爱和例外（女声烟嗓版）', 'netease', '海底', 'Rony丁若依', 'http://p1.music.126.net/qpFv-PBURQm1ly4Fr1VcQg==/109951165108365506.jpg?param=300x300', '', '', 8),
('64dc4021de232', '1856728513', '64dc3a94560e6', '断掉了的爱（DJ版）', 'netease', '断掉了的爱', '1个球', 'http://p1.music.126.net/_oqIP4NuUTNgnmbqz8v71A==/109951165966611296.jpg?param=300x300', '', '', 7),
('64dc4021de231', '1373002251', '64dc3a94560e6', '猪猪女孩', 'netease', '猪猪女孩', '麦小兜', 'http://p1.music.126.net/sqQcRu9ShoFYsZbcst5z2w==/109951164160905370.jpg?param=300x300', '', '', 6),
('64dc4021de22f', '1380720351', '64dc3a94560e6', '悠哉山歌大王', 'netease', '悠哉山歌大王', '穗乃果奶', 'http://p1.music.126.net/v5E8eks4bY1bhxgqcZMY4g==/109951164246864524.jpg?param=300x300', '', '', 5),
('64dc4021de22e', '1491221473', '64dc3a94560e6', '我很好（吉他版）', 'netease', '我很好', '刘大壮', 'http://p1.music.126.net/qGIzwzf05taTVfk9PSnSiw==/109951165424768428.jpg?param=300x300', '', '', 4),
('64dc4021de22d', '1347324287', '64dc3a94560e6', '出山（3d环绕版）', 'netease', '出山', '小可乐', 'http://p1.music.126.net/qx5z84HQ_Y6B3GElBiPE6w==/109951163877937069.jpg?param=300x300', '', '', 3),
('64dc4021de22b', '1438136226', '64dc3a94560e6', '愿你余生漫长（抖音版）', 'netease', '愿你余生漫长（抖音版）', '阿YueYue', 'http://p1.music.126.net/rMdeeHUZZwy_a1EV_v6bRg==/109951164876815438.jpg?param=300x300', '', '', 2),
('64dc4021de22a', '1371780785', '64dc3a94560e6', '暖一杯茶', 'netease', '暖一杯茶', '邵帅', 'http://p1.music.126.net/dAP3RXAs9dA73zNYz_3XSg==/109951164151547523.jpg?param=300x300', '', '', 1),
('64dc4021de225', '1387600570', '64dc3a94560e6', '余香', 'netease', '愿你不用靠失去来懂得', 'HEST,科长', 'http://p1.music.126.net/NTJrUJMgxGSho1t1E4dx_Q==/109951164332917915.jpg?param=300x300', '', '', 0),
('64dc4021de236', '1877225392', '64dc3a94560e6', '棉花糖', 'netease', '伤心', 'zv.r', 'http://p1.music.126.net/A47UxAaRE-DlQBwZQUfseA==/109951166373880457.jpg?param=300x300', '', '', 9);

-- --------------------------------------------------------

--
-- 表的结构 `ocink_song_sheet`
--

CREATE TABLE `ocink_song_sheet` (
  `id` varchar(100) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `sheet_id` varchar(20) DEFAULT NULL,
  `user_id` varchar(32) DEFAULT NULL COMMENT '歌单所属用户',
  `status` int(1) DEFAULT '0' COMMENT '状态 1:开放 0:私密',
  `name` varchar(30) DEFAULT NULL COMMENT '歌单名称',
  `author` varchar(30) DEFAULT NULL COMMENT '歌单作者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_song_sheet`
--

INSERT INTO `ocink_song_sheet` (`id`, `type`, `sheet_id`, `user_id`, `status`, `name`, `author`, `create_time`) VALUES
('64dc3a94560e6', 'sdtj', NULL, '1', 1, '刀客源码', 'admin', '2023-08-16 10:55:16');

-- --------------------------------------------------------

--
-- 表的结构 `ocink_users`
--

CREATE TABLE `ocink_users` (
  `uid` int(11) NOT NULL COMMENT '用户ID',
  `username` varchar(225) DEFAULT NULL COMMENT '用户名',
  `password` varchar(225) DEFAULT NULL COMMENT '登陆密码',
  `qq` varchar(225) DEFAULT NULL COMMENT 'QQ号码',
  `mail` varchar(225) DEFAULT NULL COMMENT '邮箱',
  `power` int(11) DEFAULT NULL COMMENT '用户权限',
  `pie` int(11) DEFAULT '0' COMMENT '播放器额度',
  `skey` text COMMENT '登录验证密钥',
  `sid` text COMMENT '登录令牌',
  `token` text COMMENT 'QQ登录验证密钥',
  `dlip` varchar(20) DEFAULT NULL COMMENT '登录ip',
  `city` varchar(255) DEFAULT NULL COMMENT '城市',
  `time` varchar(255) DEFAULT NULL COMMENT '登录时间戳',
  `regtime` datetime DEFAULT NULL COMMENT '注册时间',
  `regip` varchar(32) DEFAULT NULL COMMENT '注册IP'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ocink_users`
--

INSERT INTO `ocink_users` (`uid`, `username`, `password`, `qq`, `mail`, `power`, `pie`, `skey`, `sid`, `token`, `dlip`, `city`, `time`, `regtime`, `regip`) VALUES
(1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', '123456', '123456@qq.com', 0, 2147483646, '8fe8683e19316e814bf584e206fa54ad', 'b31893461825203c8d7006c4c0f663a5', NULL, '36.161.208.155', '六安市', '1710859611', '2023-08-16 00:00:00', '127.0.0.1');

-- --------------------------------------------------------

--
-- 表的结构 `qqlogin_log`
--

CREATE TABLE `qqlogin_log` (
  `log_id` int(11) NOT NULL,
  `log_token` varchar(100) NOT NULL,
  `log_openid` varchar(150) DEFAULT NULL,
  `log_callback` varchar(200) DEFAULT NULL,
  `log_nickname` varchar(50) DEFAULT NULL,
  `log_data` varchar(500) DEFAULT NULL,
  `log_time` varchar(100) DEFAULT NULL,
  `log_ip` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- 表的结构 `qqlogin_zhan`
--

CREATE TABLE `qqlogin_zhan` (
  `zhan_id` int(11) NOT NULL,
  `zhan_token` varchar(200) DEFAULT NULL,
  `zhan_userid` int(11) DEFAULT NULL,
  `zhan_qq` varchar(20) DEFAULT NULL,
  `zhan_url` varchar(100) DEFAULT NULL,
  `zhan_title` varchar(100) DEFAULT NULL,
  `zhan_callback` varchar(255) DEFAULT NULL,
  `zhan_addtime` datetime DEFAULT NULL,
  `zhan_state` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `qqlogin_zhan`
--

INSERT INTO `qqlogin_zhan` (`zhan_id`, `zhan_token`, `zhan_userid`, `zhan_qq`, `zhan_url`, `zhan_title`, `zhan_callback`, `zhan_addtime`, `zhan_state`) VALUES
(2, '085161FE34CF165C71786BEA73F8FE83', NULL, '24677102', '你的网站首页', '刀客源码播放器', 'http://你的域名/index/index/QqLogin_Callback', '2020-07-12 20:37:22', 1);

--
-- 转储表的索引
--

--
-- 表的索引 `ocink_chat`
--
ALTER TABLE `ocink_chat`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `ocink_configs`
--
ALTER TABLE `ocink_configs`
  ADD PRIMARY KEY (`k`);

--
-- 表的索引 `ocink_links`
--
ALTER TABLE `ocink_links`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `ocink_order`
--
ALTER TABLE `ocink_order`
  ADD PRIMARY KEY (`trade_no`);

--
-- 表的索引 `ocink_pays`
--
ALTER TABLE `ocink_pays`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `ocink_users`
--
ALTER TABLE `ocink_users`
  ADD PRIMARY KEY (`uid`);

--
-- 表的索引 `qqlogin_log`
--
ALTER TABLE `qqlogin_log`
  ADD PRIMARY KEY (`log_id`);

--
-- 表的索引 `qqlogin_zhan`
--
ALTER TABLE `qqlogin_zhan`
  ADD PRIMARY KEY (`zhan_id`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `ocink_chat`
--
ALTER TABLE `ocink_chat`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `ocink_links`
--
ALTER TABLE `ocink_links`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `ocink_pays`
--
ALTER TABLE `ocink_pays`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `ocink_users`
--
ALTER TABLE `ocink_users`
  MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT COMMENT '用户ID', AUTO_INCREMENT=2;

--
-- 使用表AUTO_INCREMENT `qqlogin_log`
--
ALTER TABLE `qqlogin_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2480;

--
-- 使用表AUTO_INCREMENT `qqlogin_zhan`
--
ALTER TABLE `qqlogin_zhan`
  MODIFY `zhan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

DELIMITER $$
--
-- 事件
--
CREATE DEFINER=`root`@`localhost` EVENT `event_auto_clearData` ON SCHEDULE EVERY 1 DAY STARTS '2014-11-29 23:56:00' ON COMPLETION NOT PRESERVE ENABLE DO call auto_clearData()$$

CREATE DEFINER=`root`@`localhost` EVENT `event_conCom` ON SCHEDULE EVERY 1 DAY STARTS '2014-11-01 23:50:00' ON COMPLETION NOT PRESERVE ENABLE DO call consumptionCommission()$$

CREATE DEFINER=`root`@`localhost` EVENT `event_pay` ON SCHEDULE EVERY 90 SECOND STARTS '2015-03-25 14:21:53' ON COMPLETION NOT PRESERVE ENABLE DO begin
	
	call pro_pay();

end$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
