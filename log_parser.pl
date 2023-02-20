#!/usr/bin/perl

# парсер лога

use DBI;

use strict;
use warnings;
# про use Modern::Perl знаю, но тут ничего нужного нет

# в use utf8 тут нет смысла

# поскольку в задании всё в latin1, то я стал ни тут ставить use utf8, ни включать это в коннекте к базе

# т.к. тест, то не стал прописывать получение параметров коннекта к базе и имени файла логов из конфига
my $dbh = DBI->connect( "DBI:mysql:database=cc;host=127.0.0.1;port=3306", "cc", "cc" )
	or die "no connection to mysql\n";

my $fname = "out";

open(my $fh, "<", $fname) or die "Can't open $fname : $!\n";

while( <$fh> ) {
	chomp;

	my @str = /^(\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d) ([0-9A-Za-z\-]{16}\s)?([=<>*\-]{2}\s)?(.+)$/;

	if ( $str[1] ) {
		chop $str[1]; # пробел, так удобнее
	}
	else {
		# есть и без id:
		# SMTP connection from mail.somehost.com [84.154.134.45] closed by QUIT
		$str[1] = ""
	}

	# разные причины, но обычно time out или Completed,
	# с любом случае это не для "<="
	$str[2] = "" if !$str[2];

	my ( $adr, $id ) = ( '', '' );
	# считаем, что время лога тут в UTC, т.к. не оговорено иного
	if ( $str[2] eq '<= ' ) {
		( $id ) = $str[3] =~ /\bid=(\S+)\b/;
	} else {
		( $adr ) = $str[3] =~ /^([0-9A-Za-z-_.]+@[0-9A-Za-z-_.]+\b)/;
	}

	# для
	# <> R=1RwtmW-000MsX-CK U=mailnull P=local S=2919
	# :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router - такие, как я понимаю, тоже не нужны,
	# но если нужны, то достаточно чуть поправить regexp
	$adr = "" if !$adr;


	# вообще, можно было собрать списки и заливать как INSERT ... VALUES (?,?,?,?),(?,?,?,?),....
	# mysql позволяет одним запросом влить до 1000 записей
	# у pg лимит не знаю,
	# ноу обеих баз  можно упереться в буфер для 1 запроса,
	# а вот у clickhouse есть особая ф-я AsyncInsert -- сервер сам собирает записи и раз в 0,2 сек пишет из в базу

	# в условии сказано, что запись попадает только в одну из таблиц
	# если в строке с "<=" нет записи в id, то там был сбой и значит письмо не было доставлено,
	# поэтому запись пишется в таблицу log
	if ( $id ) {
		$dbh->do(
			"INSERT INTO `message` ( `id`, created, int_id, str ) VALUES ( ?, ?, ?, ? )",
			undef,
			$id, $str[0], $str[1], $str[1].' '.$str[2].$str[3]
		)
		or print $DBI::errstr;
	}
	else {
		$dbh->do(
			"INSERT INTO `log` ( int_id, created, str, address ) VALUES ( ?, ?, ?, ? )",
			undef,
			$str[1], $str[0], $str[1].' '.$str[2]. ' '.$str[3], $adr
		)
		or print $DBI::errstr;
	}

}

close($fh);
$dbh->disconnect;



