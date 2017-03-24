drop table if exists `account`;
create table `account`(
	`accountid` bigint(20) unsigned not null auto_increment,
	`account` char(64) not null,
	`createtime` datetime,
	primary key(`account`),
	unique key(`accountid`)
) engine=innodb default charset=utf8 auto_increment=10001;

delimiter $$
drop procedure if exists `pr_select_account`$$
create procedure `pr_select_account`(v_account char(64))
begin
	declare v_accountid bigint default null;
	declare v_errcode int default null;
	declare v_isnewaccount int default 0;

	declare continue handler for sqlexception set v_errcode = 1;

	select `accountid` into v_accountid from `account` where `account` = v_account;
	if v_accountid is null then
		insert into `account`(`account`,`createtime`) values(v_account, now());
		select `accountid` into v_accountid from `account` where `account` = v_account;
		set v_isnewaccount = 1;
	end if;

	select v_errcode, v_accountid, v_isnewaccount;
end$$
delimiter ;
;
