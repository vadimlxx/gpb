#!/usr/bin/perl

#  просто http-сервер

use DBI;
use HTTP::Daemon;
use HTTP::Status;

use warnings;
use strict;

# в use utf8 тут нет смысла

# не стал параметры выносить в yaml или переменные окружения
my $dbh = DBI->connect( "DBI:mysql:database=cc;host=127.0.0.1;port=3306", "cc", "cc" )
	or die "no connection to mysql\n";

# Timeout чтобы само не висело
my $d = HTTP::Daemon->new( Timeout => 60, LocalAddr => '127.0.0.1', LocalPort => '8080' )
	or die "no run HTTP Daemon\n";

print "Run on localhost/ ...\n";

my $i = 0;

# общая часть
my $html_top = q|
<html>
<body>
<form action="" method="get">
<label for="name">Enter address:</label>
<input type="text" name="find" required size="30">
</form>
|;

my $html_bottom = q|
</body>
</html>
|;

while ( my $c = $d->accept ) {
	while ( my $r = $c->get_request ) {

		if ( $r  and  $r->method eq 'GET'  and  $r->uri->path eq "/" ) {
			$c->send_basic_header;
			$c->print("Content-Type: text/html; charset=utf-8");
			$c->send_crlf;
			$c->send_crlf;
			my $html = $html_top;

			if ( $r->uri->query ) {
				my %hquery = $r->uri->query_form;

				if ( $hquery{'find'} ) {
					my $qstr = $hquery{'find'};

					if ( $qstr !~ /^[A-Za-z-_.@]+$/ ) {
						$html .= '<h4>Error data in request</h4>';
					}
					else {

						my $sql = q|
SELECT created, str
  FROM (
       SELECT l.created, l.str
         FROM `log` l
        WHERE address = ?
        UNION ALL
       SELECT m.created, m.str
         FROM message m
        WHERE str RLIKE ?
  ) a
 ORDER BY 1
 LIMIT 101
|;
						my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, $qstr, $qstr );

						if ( @$rows == 0 ) {
							$html .= '<h4>No data found</h4>';
						}
						else {
							$html .= '<h4>Answer:</h4>';
							$html .= "<table>\n<thead>\n<tr><th>time</th><th>log string</th></tr>\n</thead><tbody>";

							my $i = 0;
							foreach my $row ( @$rows ) {
								$html .= '<tr><td>' . $row->{'created'} . '</td>';
								$html .= '<td>' . $row->{'str'} . "</td></tr>\n";

								$i++;
								if ( $i == 99 ) {
									last;
								}
							}

							$html .= "</tbody>\n</table>\n";

							if ( @$rows > 100 ) {
								$html .= "<h4>Data is truncated</h>\n";
							}
						}
					}
				}
			}
			$html .= $html_bottom;
			$c->print($html);
		}
		else {
			$c->send_error( RC_FORBIDDEN )
		}
	}

	$c->close;
	undef($c);
}
